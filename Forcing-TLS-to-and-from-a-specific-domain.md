There is sometimes a requirement to force TLS to and from a specific list of domains, even though it may optionally be set up globally.

The assumption here is that you have already got an opportunistic TLS implementation working.

Note that nothing here affects verification of TLS certificates, so you remain subject to Man-in-the-Middle attacks.

In your "domainlist" section add e.g.:

```
domainlist tls_force_domains = example.com : *.example.com : forcetls.com : *.forcetls.com
```

In acl_check_rcpt (just before require verify = sender):

```
deny  message        = This domain ($sender_address_domain) requires a TLS connection which is not present
      sender_domains = +tls_force_domains
      ! encrypted    = *
```

In routers:

```
tls_router:
  driver = dnslookup
  domains = +tls_force_domains
  transport = tls_smtp
```

In transports:

```
tls_smtp:
  driver = smtp
  hosts_require_tls = *
```

In retry (optional)

```
*                      tls_required F,2h,15m;
```





