Exim's string expansion gives you the ability to use authenticators that
are currently not built in. One (and currently the only) example is
CRAM-SHA1:

First, we need a pseudo-random challenge string. Exim has (as of version
4.60) no support for random numbers, so we use the PID and the unix time
(seconds since 1970-01-01):

    # main config
    acl_smtp_auth = acl_check_auth

    # acl config
    acl_check_auth:
       warn  set acl_c0 = <$pid.$tod_epoch@$primary_hostname>
       accept

Change "c0" if you already use this ACL variable to a free one.

The authenticator:

    # authentication config

    cram_sha1:
      driver = plaintext
      public_name = CRAM-SHA1
      server_prompts = $acl_c0
      server_set_id = ${sg {${extract {1}{ }{$1} }} {[^a-zA-Z0-9.-_]} {?}}
      server_condition = ${if eq \
          {${extract {2}{ }{$1} }} \
          {${hmac{sha1} \
            {${lookup {${extract {1}{ }{$1} }} lsearch {/etc/exim/passwd} {$value}fail}} \
            {$acl_c0} }} }

Here we use a lsearch lookup the get the password, you can replace it
with the password lookup that suits your setup. However, we need the
password in plaintext, not crypted or hashed.

Notes:
-   The only hash methods supported (as of 4.60) are md5 and sha1. Exim
    has a builtin CRAM-MD5 authenticator, so using md5 make no sense.
-   The challenge string might look too simple to be secure, but the
    only requirement is that it must be unique over time, which is very
    unlikely to be violated on real world systems. If you are concerned
    about that, add `delay = 1s` to the `warn` ACL stanza.
