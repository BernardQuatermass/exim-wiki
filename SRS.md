Sender Rewriting Scheme (SRS)
=============================

SRS support is [Experimental](ExperimentalSpec)

Exiscan currently includes SRS support via Miles Wilton's libsrs\_alt
library. The current version of the supported library is 1.0.

In order to use SRS, you must get a copy of libsrs\_alt from

[http://opsec.eu/src/srs/](http://opsec.eu/src/srs/)

(The old site [http://srs.mirtol.com](http://srs.mirtol.com/) no longer exists)

Unpack the tarball, then refer to MTAs/README.EXIM to proceed. You need
to set

    EXPERIMENTAL_SRS=yes

in your `Local/Makefile`.

Additional Documentation from
[http://opsec.eu/src/srs/exim.html](http://opsec.eu/src/srs/exim.html):

Configuring Exim
----------------

As of libsrs\_alt 1.0, there have been a few changes to the
configuration of Exim. In the interest of ease, any previous
configurations will be completely compatible.

**IMPORTANT**: The default exim ACL prevents the use of the / character
in email address, with a standard install of libsrs\_alt, this character
must be permitted due to its use in BASE64 encoding.

**HOWEVER**: libsrs\_alt 1.0 contains a compatibility switch that
changes its behaviour so that the '/' and '+' characters are not used
('\_' and '.' replace them). This mode is backward compatible, in that
it will recognise '/' and '+' when doing reverse SRS. The merits of this
are obvious although this switch makes libsrs\_alt "non-SRS compliant".

See the example configurations at the end of this file to get some idea
of how to use SRS with exim.

### Global Variables

These variables should be placed in the global section of your exim
configuration file. They set the secret key and, optionally, the hash
length and timestamp age using a standard exim list, as follows:

    srs_config       = <secret>:<max age>:<hash length>:<use timetamp flag>:<use hash flag>
    srs_secrets      = <secret 1>:<secret 2>:...:<secret n>
    srs_maxage       = <max age>
    srs_hashlength   = <hash length>
    srs_hashmin      = <hash min>
    srs_usetimestamp = <use timestamp flag>
    srs_usehash      = <use hash flag>

The original srs\_config variable overrides the others.

It is **STRONGLY** recommended to prefix the `srs_config` and
`srs_secrets` variables with the `hide` keyword to keep your secret keys
as secure as possible.
-   The `<secret>` should be at least 20 characters long and may contain
    any character except `\x00` (see the Exim documentation on how to
    specify unusual characters). The secret used for creating hashes is
    either the one specified in `srs_config`, or, if absent, the first
    secret listed in `srs_secrets`. Hash validation is tested against
    all secrets.

    It is a good idea to change your primary secret once a year.
-   *(OPTIONAL)* `<max age>` is the maximium age of the SRS timestamp in
    days. A generally good figure is 30 days (around a month), although
    a figure as small as 14 days is probably acceptable in today's
    world. (default: 31)
-   *(OPTIONAL)* `<hash length>` is the number of characters of the
    BASE64 encoded hash to use (and require when validating). A good
    minimum to stick to is 6 characters. As an idea of security, the
    number of combinations is worked out at 38 \^ \<hash length\> - so
    for a hash length of 6 that gives 3 billion combinations. (default:
    6)
-   *(OPTIONAL)* `<hash min>` is the minimum length of hash accepted
    when validating SRS addresses. This is useful if you up the length
    of your hash but need old SRS addresses to still be valid. (default:
    `<hash length>`)
-   *(OPTIONAL)* `<use timetamp flag>` should be either 1 or 0 and turns
    on or off, respectively, whether a timestamp is included (and
    required) in SRS addresses. (default: 1)
-   *(OPTIONAL)* `<use hash flag>` should be either 1 or 0 and turns on
    or off, respectively, whether a hash is included (and required) in
    SRS addresses. (default: 1)

(`srs_usetimestamp` and `srs_usehash` will accept any Exim boolean type,
`srs_config` requires 1 or 0)

### Redirect Router

(These config variables are for the redirect router)

`srs = <forward|reverse|reverseandforward>`

[Table not converted]

`srs_condition = <expanded string>`

Expanded by Exim and if the result is false or fail, the redirect router
processes the email as if no srs variable was set (behaves normally). An
example of its use might be a test to see whether the domain is local or
on your relay list.

`srs_db_insert = <expanded string>`

If set and the address being processed will result in a SRS0 address
then the string is expanded. The return value is ignored, but the
expansion should result in the key-data pair \$srs\_db\_key and
\$srs\_db\_address being saved.

If the expansion fails, the message is DEFERed.

`srs_db_select = <expanded string>`

If set and the address being processed is a SRS0 address then the string
is expanded. The return value should be the address to forward the mail
to. \$srs\_db\_key is set to the unique key for the address.

If the expansion fails, the message is DEFERed.

`srs_alias = <domain name>`

Specifies a domain name which is then used for the domain part of the
return address, normally domain in the original recipient address is
used.

Example Configurations
----------------------

These are extracts from an Exim config file to give readers an idea of
how to confgiure their servers. Two examples follow:

### Basic SRS Configuration

    #
    #  Exim configure
    #

    hide srs_config = mysecret:60:5     # Uses mysecret as SHA1
                                        #   secret
                                        # 60 days for timestamps
    #   to expire and
                                        # 5 characters of hash
                                        #   (default is 6)

    #
    # ... other config settings ...
    #

    begin routers

    #
    # ... routers that deliver local addresses and aliases ...
    #

    forwarding_router:
      driver = redirect
      srs = forward
      data = ${lookup ...}              # You can't use data and
      file = ...                        # file together - they
                                        # are shown as an
                                        # example.

    srs_router:
      driver = redirect
      srs = reverseandforward
      data = ${srs_recipient}
      condition = ...                   # You may wish to place
                                        # an extra condition on
                                        # the router

    #
    # ... catch all routers ...
    #

    #
    # Rest of config file
    #

### SRS configuration using MySQL

    #
    #  Exim configure
    #

    hide srs_secrets = mysecret         # Uses mysecret as SHA1
                                        #   secret
    srs_maxage = 60                     # 60 days for timestamps
                                        #   to expire and
    srs_hashlength = 5                  # 5 characters of hash
                                        #   (default is 6)

    #
    # ... other config settings ...
    #

    begin routers

    #
    # ... routers that deliver local addresses and aliases ...
    #

    forwarding_router:
      driver = redirect
      srs = forward
      srs_dbinsert = ${lookup mysql{INSERT INTO `SRS`
            (`Key`, `Address`, `Time`) VALUES
            ('${srs_db_key}', '${srs_db_address}', NOW())}}
      data = ${lookup ...}

    srs_router:
      driver = redirect
      srs = reverseandforward
      srs_dbinsert = ${lookup mysql{INSERT INTO `SRS`
            (`Key`, `Address`, `Time`) VALUES
            ('${srs_db_key}', '${srs_db_address}', NOW())}}
      srs_dbselect = ${lookup mysql{SELECT FROM `SRS` WHERE
            `Key` = '${srs_db_key}' AND
            `Time` > SUBDATE(NOW(), INTERVAL 30 day) LIMIT 1}}
      data = ${srs_recipient}

    #
    # ... catch all routers ...
    #

    #
    # Rest of config file
    #
