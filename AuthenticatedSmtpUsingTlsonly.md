You want enable authentication only for clients using secure TLS connection?
:   Just put into your config:

<!-- -->

    auth_advertise_hosts = ${if eq{$tls_cipher}{}{*}{localhost}}

Note: That this will also enable auth for clients connecting from
localhost (for example webmails).
