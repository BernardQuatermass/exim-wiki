## Letsencrypt certificate usage based on SNI

This configuration makes Exim search for a certificate based on the SNI.

First, it ensures that _$tls_sni_ is a valid domain name by constructing an arbitrary email address and getting the domain name from it.

Then, it strips the SNI down to its 2nd level domain (e.g. smtp.example.com to example.com) and uses this value to search for a certificate.


```
tls_certificate = \
        ${if and {\
                     { eq {${domain:foo@$tls_in_sni}} {$tls_in_sni}}\
                     { exists{/etc/letsencrypt/live/${sg{FOO.$tls_in_sni}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/fullchain.pem} }\
                 }\
                 {/etc/letsencrypt/live/${sg{FOO.$tls_in_sni}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/fullchain.pem}\
                 {/etc/letsencrypt/live/${sg{FOO.$primary_hostname}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/fullchain.pem}\
         }

tls_privatekey = \
        ${if and {\
                     { eq {${domain:foo@$tls_in_sni}} {$tls_in_sni}}\
                     { exists{/etc/letsencrypt/live/${sg{FOO.$tls_in_sni}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/privkey.pem} }\
                 }\
                 {/etc/letsencrypt/live/${sg{FOO.$tls_in_sni}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/privkey.pem}\
                 {/etc/letsencrypt/live/${sg{FOO.$primary_hostname}{.*?([a-z0-9-]+)\.([a-z0-9-]+)\.([a-z0-9-]+)\$}{\$2.\$3}}/privkey.pem}\
         }
```

**Attention:**

For this to work, _exim_ needs to be allowed to read the certificate files. Make sure that this really is what you want.

This could be achieved by
`chgrp -R ssl-cert /etc/letsencrypt; chmod -R g+r /etc/letsencrypt`

The _exim_ process user has to be in group _ssl-cert_ (`usermod -a -G ssl-cert Debian-exim`).