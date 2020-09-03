## Letsencrypt certificate usage based on SNI

This configuration makes Exim search for a certificate based on the SNI.

First, it ensures that _$tls_sni_ is a valid domain name by constructing an arbitrary email address and getting the domain name from it.

Then, it strips the SNI down to its 2nd level domain (e.g. smtp.example.com to example.com) and uses this value to search for a certificate.


```j
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

**Alternative Method**
LetsEncrypt also provides for hook routine in which certificate files can be copied into a subdirectory owned by exim user (and group) and can be written in a language of your choice.

Hook directory of LetsEncrypt is located in `/etc/letsencrypt/renewal-hooks/deploy/<your-script-name>`

Two environment variable names are provided:
* `RENEWAL_LINEAGE`
* `RENEWAL_DOMAINS`

Hook script basically can copy certificate and key PEM files from LetsEncrypt live directory into your Exim private subdirectory. Ideally, your script will also do `chmod`, `chown` and `chgrp`.  Maybe optionally create any needed directory or log any error using directory or file access tests. 

`RENEWL_LINEAGE` contains the full path to where the LetsEncrypt certificates are located (typically in /etc/letsencrypt/live/<domain-name>`.

`RENEWED_DOMAIN` environment variable containing one or more domain names (comma-separated) which will works for multiple domain names (SNI) per certificate. 