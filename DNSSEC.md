### Background

Verifying the identity of a remote server means having a "trusted" name which any [PKIX][] certificate can be compared to.  For federated services which use common servers, as in email delivery to MX, this is not simple.  Furthermore, using Certificate Authorities means that you can't filter out "Bad Actor" CAs, because some important business partner might be using certificates from that CA and "the mail must flow".  Thus CA selection becomes a race to the bottom where postmasters _must_ trust the known-to-be-untrustworthy.

Your choices boil down to:

1. Manually manage trust identities, mapping domains to hosts and CAs to be used
2. Put that data into DNS where it's under the control of the recipient domain, but have some way to trust DNS.

Only approach 2 scales.  To achieve this, [DNSSEC][] is used.


### Exim and DNSSEC

Exim understands the concept of DNSSEC but does not include DNSSEC validation logic itself; the developers feel that's too large an attack surface to be parsed from UDP inside a setuid root program, and that aspects such as algorithm support would just become stale.  So Exim defers validation to your DNS Resolver.  This is safe provided you have a sufficiently secure network between Exim and the DNS resolver.  Running a local DNSSEC-validating caching resolver on the mail server itself is the most secure option, with `127.0.0.1` and/or `::1` as the only nameservers listed in `/etc/resolv.conf`.  Use of remote nameservers, especially on distant networks is liable to make DNSSEC validation subject to man-in-the-middle attack.

For the "Exim as receiving server-side" setup, no integration with Exim is necessary.  You publish DNS records.

For the "Exim as client-side" setup, you need to tell Exim to try DANE.  Any DNS resolvers listed in `/etc/resolv.conf` need to be DNSSEC validating.

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
  + Check the CAVEATS section of the `asr_run(3)` manual page to see if this is still true when you read this


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

We currently sign using `ECDSAP256SHA256`; our sense of public DNS administrator consensus seems to be that this is a reasonable short-term transition choice.  Cloudflare use it for their domains, so any resolver which breaks on it will cut off DNS resolution of large chunks of Internet.

[DNSSEC]: https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions "DNS Security Extensions"
[PKIX]: https://en.wikipedia.org/wiki/X.509
[Unbound]: https://www.unbound.net/
[NLnet Labs]: https://www.nlnetlabs.nl/
[Knot-Resolver]: https://www.knot-resolver.cz/
[CZ-NIC Labs]: https://labs.nic.cz/en/
[Bind]: https://www.isc.org/downloads/bind/
[ISC]: https://www.isc.org/ "Internet Systems Consortium"
[PowerDNS Recursor]: https://www.powerdns.com/recursor.html
[PowerDNS]: https://www.powerdns.com/whatwedo.html
[Let's Encrypt]: https://letsencrypt.org/ "Let’s Encrypt is a free, automated, and open Certificate Authority"