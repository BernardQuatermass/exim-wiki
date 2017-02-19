### Background

Verifying the identity of a remote server means having a "trusted" name which any [PKIX][] certificate can be compared to.  For services which employ DNS indirection via e.g. MX or SRV records, this is not simple.  Furthermore, using Certificate Authorities means that you can't filter out "Bad Actor" CAs, because some important business partner might be using certificates from that CA and "the mail must flow".  Thus CA selection becomes a race to the bottom where postmasters _must_ trust the known-to-be-untrustworthy.  See [SMTP Channel Security][] for more detail.

Your choices boil down to:

1. Manually manage trust identities, mapping domains to hosts and CAs to be used
2. Put that data into DNS where it's under the control of the recipient domain, but have some way to trust DNS.

Only approach 2 scales.  To achieve this, [DNSSEC][] is used in conjunction with [Opportunistic DANE TLS][].


### Exim and DNSSEC

Exim understands the concept of DNSSEC but does not include DNSSEC validation logic itself; the developers feel that's too large an attack surface to be parsed from UDP inside a setuid root program, and that aspects such as algorithm support would just become stale.
So Exim defers validation to your DNS Resolver (but see the next section).

For the "Exim as receiving server-side" setup, no integration with Exim is necessary.  You publish DNS records.

For the "Exim as client-side" setup, you need to tell Exim to try DANE.
Any DNS resolvers listed in `/etc/resolv.conf` need to be DNSSEC validating.

The `remote_smtp` Transport should include:

```
  dnssec_request_domains = *
  hosts_try_dane = *
```

Ideally your Routers which use `driver = dnslookup` will also include:

```
  dnssec_request_domains = *
```

**If**, and _only_ if, the DNS resolver does not validate by default, then you need to ensure that your queries are marked as requiring DNSSEC.  On some platforms, this can be done with an option in `/etc/resolv.conf` but in all cases, in Exim's _main_ configuration section, you can add the directive:

```
dns_dnssec_ok = 1
```

This will tell Exim to initialise the resolver library with the option saying to request DNSSEC.


### DNSSEC and Resolvers

Deferring DNSSEC validation to a resolver is safe provided you have a sufficiently secure network between Exim and the DNS resolver.
Running a local DNSSEC-validating caching resolver on the mail server itself is the most secure option, with `127.0.0.1` and/or `::1` as the only nameservers listed in `/etc/resolv.conf`.
Use of remote nameservers, especially on distant networks, is liable to make DNSSEC validation subject to man-in-the-middle attack.

_Warning: opinions may follow._  Some open source resolvers which are known to work.

* [Unbound][] is a DNSSEC-validating resolver which should work out of the box
  + from [NLnet Labs][]
  + written in C, can embed Python
* [Knot-Resolver][] is a DNSSEC-validating resolver which should work out of the box
  + from [CZ-NIC Labs][]
  + the minimum version to use is `1.2.0`; earlier versions are known to have resolution problems which will break DANE for `@exim.org`
  + written in C and Lua
* [PowerDNS Recursor][]
  + from [PowerDNS.COM BV][PowerDNS], a Dutch company
  + written in C, can embed Lua
  + "As of 4.0.0, the PowerDNS Recursor has support for DNSSEC processing and experimental support for DNSSEC validation"
* [Bind][] is the classic DNS platform, authoritative and recursive, but requires some configuration expertise to get DNSSEC working as a resolver-only platform
  + from [ISC][]
  + written in C

If you already have expertise in Bind, it's a fair choice, but for simplicity and maintenance by a postmaster who isn't a DNS admin already, we will nudge you towards [Unbound][] or [Knot-Resolver][].  As of early 2017 [Unbound][] has more history in solid production deployments with reliable DNSSEC, so is the safer choice.  [PowerDNS][] [documents that](https://doc.powerdns.com/md/recursor/dnssec/) validation is still experimental, as of 4.0.0.


### Known Platform Issues

* On OpenBSD, DNS resolution has been replaced with a very clean library ("asr"), which unfortunately does not handle EDNS and so can't handle DNSSEC (at this time).
  + Check the CAVEATS section of the
    [`asr_run(3)`](http://man.openbsd.org/OpenBSD-current/man3/asr_run.3)
    manual page to see if this is still true when you read this.
  + The caveat has been removed from "-current" but is still present in the
    man-page for OpenBSD 6.0, which is the latest release (at time of writing)
    so it seems that this may be resolved in the next release.


### `exim.org` Domain

The `exim.org` domain is DNSSEC-signed and the mail-server uses a validating resolver for DNS.

TLSA records are published, enabling DANE for the primary MX.

MX Certificates are currently from [Let's Encrypt][] and we use public-key pinning of the CA in DNS.  By using the public key, not the certificate, we are immune from CA reissuance such as when LE's "X1" authority became their "X3" authority.  We publish the public keys for "X3" and "X4" (the standby).  We also publish a couple of other CA records.  There is no need to use a public CA, with DANE, but doing so allows some validation by those not using DNSSEC and avoids our needing to run a CA ourselves.  All our web-services need PKIX CA-issued certs anyway, so it's just one more.

There are two MX records:

* At the current time, our backup MX's domain is not DNSSEC-signed, so interception attacks by those able to carry out active on-path attacks are possible; this is not ideal, but acceptable as a transition strategy.  (This written in early 2017; if this is still the case years later, then we need to change the setup.)
* The primary MX is `hummus.csx.cam.ac.uk`; this is DNSSEC-signed.
  + We leave this in `cam.ac.uk` instead of taking it in-zone for `exim.org` because in some parts of the world, geo-IP blocking of email is common and some of us are tired of having to explain that the `exim.org` mail-server is in the UK and so the problems are the other party's fault.  Leaving the `.uk` clearly visible helps keep this to a minimum.  It's also nice to acknowledge Cambridge University for the hosting.
  + A `DNAME` record for `_tcp.hummus.csx.cam.ac.uk` points resolution back to be under `_hummus_tcp.exim.org` so that it's under our administrative control; we can switch CAs without having to bother the Cambridge DNS admins
  + If a resolver can't handle DNAME (and CNAME record synthesis from that) then it probably can't handle DNSSEC either, so won't be able to use DANE anyway.  If it can handle most DNSSEC but not DNAME, then that's a bug to be fixed

All `TLSA` RR-names under `exim.org` end up being CNAMEs pointing to the common RR-set of `TLSA` records used for all services.  There's only one `TLSA` RR-set.

```
% dig +noall +answer -t tlsa _25._tcp.hummus.csx.cam.ac.uk
_tcp.hummus.csx.cam.ac.uk. 3600 IN      DNAME   _hummus_tcp.exim.org.
_25._tcp.hummus.csx.cam.ac.uk. 0 IN     CNAME   _25._hummus_tcp.exim.org.
_25._hummus_tcp.exim.org. 900   IN      CNAME   _letsencrypt-tlsa.exim.org.
_letsencrypt-tlsa.exim.org. 900 IN      TLSA    2 1 1 B111DD8A1C2091A89BD4FD60C57F0716CCE50FEEFF8137CDBEE0326E 02CF362B
_letsencrypt-tlsa.exim.org. 900 IN      TLSA    2 1 1 0B9FA5A59EED715C26C1020C711B4F6EC42D58B0015E14337A39DAD3 01C5AFC3
_letsencrypt-tlsa.exim.org. 900 IN      TLSA    2 1 1 60B87575447DCBA2A36B7D11AC09FB24A9DB406FEE12D2CC90180517 616E8A18
```

We currently sign using `ECDSAP256SHA256`; our sense of public DNS administrator consensus seems to be that this is a reasonable short-term transition choice.
Cloudflare use it for their domains, so any resolver which breaks on it will cut off DNS resolution of large chunks of the Internet.


### Monitoring

If you publish TLSA records for one or more MX hosts, monitoring that the TLSA
records match the actual certificate chain of presented by the server is
essential.
This should be integrated into your regular monitoring, which is beyond the
scope of this Wiki page, but we can point towards tooling which might help if
your monitoring does not natively support DANE-based TLS monitoring.

#### smtpdane

The [SMTP DANE testing tool][smtpdane-golang] is a Golang tool which can
connect to an SMTP server and confirm that the certificate chain validates
with DANE.
It is written by one of the Exim maintainers and at time of writing is
bare-bones functional and being actively maintained to become more useful.
It is too early to have great confidence in this tool.

#### OpenSSL

The OpenSSL 1.1.0 (or later) `s_client` command can be used to check the correctness of the MX host's TLSA records.
For example, to check that `hummus.csx.cam.ac.uk` matches at least one of its `2 1 1` records, run the below:

```
(sleep 5; printf "quit\r\n") |
  openssl s_client -verify 9 -verify_return_error -brief -starttls smtp \
    -connect hummus.csx.cam.ac.uk:25 \
    -dane_tlsa_domain hummus.csx.cam.ac.uk \
    -dane_tlsa_rrdata "2 1 1
      0B9FA5A59EED715C26C1020C711B4F6EC42D58B0015E14337A39DAD3 01C5AFC3" \
    -dane_tlsa_rrdata "2 1 1
      60B87575447DCBA2A36B7D11AC09FB24A9DB406FEE12D2CC90180517 616E8A18" \
    -dane_tlsa_rrdata "2 1 1
      B111DD8A1C2091A89BD4FD60C57F0716CCE50FEEFF8137CDBEE0326E 02CF362B"
echo "Exit Status: $?"
```

If all is well, the output will look like:

```
verify depth is 9
CONNECTION ESTABLISHED
Protocol version: TLSv1.2
Ciphersuite: ECDHE-RSA-AES256-GCM-SHA384
Peer certificate: CN = mx.exim.org
Hash used: SHA512
Verification: OK
Verified peername: hummus.csx.cam.ac.uk
DANE TLSA 2 1 1 ...ee12d2cc90180517616e8a18 matched TA certificate at depth 1
Supported Elliptic Curve Point Formats: uncompressed:ansiX962_compressed_prime:ansiX962_compressed_char2
Server Temp Key: ECDH, P-256, 256 bits
250 HELP
DONE
Exit Status: 0
```

If we introduce errors into the TLSA records by changing the last hex digit of all three:

```
(sleep 5; printf "quit\r\n") |
  openssl s_client -verify 9 -verify_return_error -brief -starttls smtp \
    -connect hummus.csx.cam.ac.uk:25 \
    -dane_tlsa_domain hummus.csx.cam.ac.uk \
    -dane_tlsa_rrdata "2 1 1
      0B9FA5A59EED715C26C1020C711B4F6EC42D58B0015E14337A39DAD3 01C5AFC4" \
    -dane_tlsa_rrdata "2 1 1
      60B87575447DCBA2A36B7D11AC09FB24A9DB406FEE12D2CC90180517 616E8A19" \
    -dane_tlsa_rrdata "2 1 1
      B111DD8A1C2091A89BD4FD60C57F0716CCE50FEEFF8137CDBEE0326E 02CF362C"
echo "Exit Status: $?"
```

then the output we get is instead:

```
verify depth is 9
depth=1 C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
verify error:num=65:No matching DANE TLSA records
140736473150400:error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed:../openssl/ssl/statem/statem_clnt.c:1245:
Exit Status: 1
```

Note, OpenSSL will not do the DNS lookups to find the TLSA records.
For `hummus.csx.cam.ac.uk` these can, for example, be found via:

```
$ dig -t tlsa +noall +ans +nocl +nottl _25._tcp.hummus.csx.cam.ac.uk. |
     sed -ne 's/.*TLSA //p'
2 1 1 0B9FA5A59EED715C26C1020C711B4F6EC42D58B0015E14337A39DAD3 01C5AFC3
2 1 1 60B87575447DCBA2A36B7D11AC09FB24A9DB406FEE12D2CC90180517 616E8A18
2 1 1 B111DD8A1C2091A89BD4FD60C57F0716CCE50FEEFF8137CDBEE0326E 02CF362B
```

A complete script to put it all together is an exercise for the reader.


### External References

1. [Common Mistakes to avoid](https://dane.sys4.de/common_mistakes)
2. [TLSA "3 1 1" + "2 1 1" recommendation](https://www.ietf.org/mail-archive/web/uta/current/msg01498.html)
3. [DYI DANE CA notes](http://postfix.1071664.n5.nabble.com/WoSign-StartCom-CA-in-the-news-td86436.html#a86444)
4. [TLSA RRs and key rotation (RFC 7671)](http://tools.ietf.org/html/rfc7671#section-8.1)
5. [TLSA monitoring with OpenSSL 1.1.0 or later `s_client`](https://www.ietf.org/mail-archive/web/dane/current/msg08206.html)
6. [OpenSSL 1.1.0 `s_client` manpage](https://www.openssl.org/docs/man1.1.0/apps/s_client.html)
7. [Shumon Huque's DANE tools](https://www.huque.com/dane/)


[Bind]: https://www.isc.org/downloads/bind/
[CZ-NIC Labs]: https://labs.nic.cz/en/
[DNSSEC]: https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions "DNS Security Extensions"
[ISC]: https://www.isc.org/ "Internet Systems Consortium"
[Knot-Resolver]: https://www.knot-resolver.cz/
[Let's Encrypt]: https://letsencrypt.org/ "Let’s Encrypt is a free, automated, and open Certificate Authority"
[NLnet Labs]: https://www.nlnetlabs.nl/
[Opportunistic DANE TLS]: https://tools.ietf.org/html/rfc7672
[PKIX]: https://en.wikipedia.org/wiki/X.509
[PowerDNS Recursor]: https://www.powerdns.com/recursor.html
[PowerDNS]: https://www.powerdns.com/whatwedo.html
[SMTP Channel Security]: https://tools.ietf.org/html/rfc7672#section-1.3
[smtpdane-golang]: https://github.com/PennockTech/smtpdane "SMTP DANE testing tool"
[Unbound]: https://www.unbound.net/
