Many ISPs block port 25 outbound.  For mail-clients, you just configure them to use port 587 Submission to your mail server (Exim).  But sometimes you may want to do things with a local MTA on your laptop.

This is when Exim's SOCKS5 support combines nicely with OpenSSH's `DynamicForward` support.  Mail will build up in your mail-spool, until you bring up the SSH link, at which point it will flow out.

This works both with manualroute and with dnslookup.  With dnslookup, it works even with functionality such as DANE.

### OpenSSH configuration

In `~/.ssh/config` something like this works well; this is a little more flexible than strictly needed, to show how you can set up patterns for multiple hosts and restrict options accordingly.

```ssh
Host *-socksonly
        ControlMaster no
        ControlPath none
        ControlPersist no
        ForwardAgent no
        ForwardX11 no

Host hermes-socks hermes-socksonly
        DynamicForward 4211

Host hermes hermes-*
        Hostname hermes.example.org

#...
Host *
        ControlPath ~/.ssh/cp/%h-%p-%r
```

This control-path location does require: `mkdir -m 0700 ~/.ssh/cp`

You can bring up a normal link and reclaim use of your terminal with:

```console
$ ssh -Nf hermes-socksonly
```

To bring up a link which you can easily stop, without `ps` digging:

```console
$ ssh -M -Nf hermes-socks
$ do_other_stuff, sending email
$ ssh -O stop hermes-socks
```

From this you can see how you might construct variants to handle auto-master for you, etc.

Be sure to pick a different value of `DynamicForward` for each remote host which you might be connected to at the same time.  Remember the value: you will need it for MTA configuration

### Exim

You need a Router and a Transport; here we show _three_ routers

1. The first is **dnslookup** and handles all normal routing; it is used when the `DNSLOOKUP` key exists in the `outbound-settings` file
2. The second handles all SOCKS cases
3. The third handles other cases

The reason for the split between 2 and 3 is that if you have shell login on the smarthost itself, you might set `host=localhost` which Exim would normally balk at.  Instead, we set `self = send` when, and only when, the `socks` key exists in the data.  If the value of `self` were expanded, we could collapse these two into just one.

If `DNSLOOKUP` exists, then only DNS-based routing will be used; to fallback to the smarthost, remove the `no_more` from that Router below.

After that, you need an SMTP Transport.

Remember that in Exim, Transports are an unordered collection which are used by being referred to from a Router, whereas Routers are an ordered list.

```exim
# macros before main settings:
TLS_CLIENT_DEFAULT_CIPHERSPEC=DEFAULT:!SSLv2:!LOW:aNULL:!eNULL
TLS_CLIENT_HIGHSEC_CIPHERSPEC=ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:HIGH:!MD5:!RC4:!aNULL:!ADH:!DES:!EXP:!NULL
TLS_SERVER_SUBMISSION_CIPHERSPEC=ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:HIGH:!MD5:!RC4:!aNULL:!ADH:!DES:!EXP:!NULL

begin routers

dnslookup:
  driver = dnslookup
  domains = ! +local_domains
  transport = remote_smtp
  address_data = ${lookup {DNSLOOKUP}lsearch*@{/etc/exim/outbound-settings}}
  condition = ${extract{socks}{${lookup {DNSLOOKUP}lsearch*@{/etc/exim/outbound-settings}}}{yes}{no}}
  self = send
  ignore_target_hosts = <; 0.0.0.0 ; 127.0.0.0/8 ; ::1
  dnssec_request_domains = *
  no_more

# note: self is not expanded; else we could use one smarthost router with:
#   self = ${extract{socks}{${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}}{send}{freeze}}

smarthost_socks:
  driver = manualroute
  domains = ! +local_domains
  transport = remote_smtp
  route_data = ${extract{host}{${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}}{$value}fail}
  dnssec_request_domains = *
  address_data = ${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}
  condition = ${extract{socks}{${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}}{yes}{no}}
  self = send

smarthost:
  driver = manualroute
  domains = ! +local_domains
  transport = remote_smtp
  route_data = ${extract{host}{${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}}{$value}fail}
  dnssec_request_domains = *
  address_data = ${lookup {$sender_address}lsearch*@{/etc/exim/outbound-settings}}
  no_more

# local mail handling goes here

begin transports

remote_smtp:
  driver = smtp
  port = ${extract{port}{$address_data}{$value}{25}}
  hosts_require_auth = ${extract{authreq}{$address_data}{${if eq{$value}{yes}{*}{$value}}}{}}
  hosts_require_tls = ${extract{tls}{$address_data}{${if eq{$value}{yes}{*}{$value}}}{}}
  hosts_avoid_tls = ${extract{tls}{$address_data}{${if eq{$value}{no}{*}{}}}{}}
  tls_sni = ${extract{tlssni}{$address_data}{$value}{}}
  tls_require_ciphers = ${extract{tlshigh}{$address_data}{${if eq{$value}{yes}{TLS_CLIENT_HIGHSEC_CIPHERSPEC}{TLS_CLIENT_DEFAULT_CIPHERSPEC}}}{TLS_CLIENT_DEFAULT_CIPHERSPEC}}
  tls_verify_certificates = ${extract{tlsverify}{$address_data}{/usr/local/etc/openssl/certs}fail}
  hosts_try_dane = *
  no_multi_domain
  no_delay_after_cutoff
  helo_data = ${extract{helo}{$address_data}{$value}{$primary_hostname}}
  hide socks_proxy = ${extract{socks}{$address_data}{<; </ $value}fail}
```

Then the file `/etc/exim/outbound-settings` looks something like this:

```
me@example.org:   host=localhost  port=26   socks=127.0.0.1/port=4221  helo=laptop.socks.proxy  tls=no
*@example.com:    host=localhost  port=587  socks=127.0.0.1/port=4222  helo=laptop.socks.proxy  tls=no
*:                host=localhost  socks=127.0.0.1/port=4229  helo=laptop.socks.proxy  tls=no

# Only enable this if you have DKIM signing with a published key on your laptop
#DNSLOOKUP:     socks=127.0.0.1/port=4211
```

### Comments

This relies upon you having a local user who can ssh; you could also have this linkage as a system service using a passphraseless SSH key which has restrictions upon it on the remote server.

If you kill the SSH session, the SOCKS proxy will disappear and mail will build up in the queue.  When you bring back the SSH link, tickle the Exim queue and the mail will flow out.

The logging of SOCKS details is currently (4.89) a little hidden.  Use `-d+transport` to turn on debugging, including the `transport` area, to see connections fail, etc.

### Bonus: authentication

The above hints at `authreq` being an allowed key in the `outbound-settings` file, to require authentication before sending.  Here are the Exim authenticators used with this setup:

```exim

begin authenticators

auth_cram:
  driver            = cram_md5
  public_name       = CRAM-MD5
  client_condition  = ${if !eq{$tls_out_cipher}{}}
  client_name       = ${extract{user}{$address_data}{$value}fail}
  client_secret     = ${extract{password}{$address_data}{$value}fail}

auth_plain:
  driver             = plaintext
  public_name        = PLAIN
  client_condition   = ${if !eq{$tls_out_cipher}{}}
  client_send        = ^${extract{user}{$address_data}{$value}fail}^${sg{${extract{password}{$address_data}{$value}fail}}{\N\^\N}{^^}}
```

Depending upon your views of the security of CRAM-MD5, you might remove the requirement that TLS be established for that authenticator.