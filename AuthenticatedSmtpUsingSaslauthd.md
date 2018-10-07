Authenticated SMTP using SASLAuthd
==================================

Introduction
------------

One of the options Exim has for authentication without root access is by
using SASLAuthd from the Cyrus suite. This is the preferred method from
the deprecated pwcheck authenticator. It is recommended you follow the
instructions in the
[AuthenticatedSmtpUsingPam](AuthenticatedSmtpUsingPam) tutorial
regarding encryption (TLS) as they won't be discussed here. This is
based on a Gentoo install.

Required Software
-----------------
-   Exim 4.x
-   Cyrus-SASL 2.x

Compiling Exim
--------------

Ensure that authentication by saslauthd is enabled in Exim. This is done
in Local/Makefile:

    AUTH_PLAINTEXT=yes
    CYRUS_SASLAUTHD_SOCKET=/var/lib/sasl2/mux

Configuring SASLAuthd
---------------------

The default arguments for SASLAuthd are contained in
/etc/conf.d/saslauthd for Gentoo. Instead of using the PAM module, we'll
directly access the shadow file:

    SASLAUTHD_OPTS="-a shadow"

You should add that argument to where ever your distribution requires
it.

Sometimes the permissions are wrong on the socket file (unknown as to
why). Verify that your socket's directory (default is /var/lib/sasl2 for
this ebuild) is executable by all:

    chmod o+x /var/lib/sasl2

Configuring Exim
----------------

If you're using encryption (and I'm sure you are) then you'll already
have an auth\_advertise\_hosts line that tests for such. If not, this
must go in your config file to allow all hosts to authenticate:

    auth_advertise_hosts = *

Now you'll want to add your authenticators:

    begin authenticators

    plain:
      driver = plaintext
      public_name = PLAIN
      server_prompts = :
      server_set_id = $2
      server_condition = ${if saslauthd{{$2}{$3}}{1}{0}}
      server_advertise_condition = true

    login:
      driver = plaintext
      public_name = LOGIN
      server_prompts = "Username:: : Password::"
      server_condition = ${if saslauthd{{$1}{$2}}{1}{0}}
      server_set_id = $1
      server_advertise_condition = true

Conclusion
----------

You'll now be able to authenticate without rooting up or messing with
PAM modules.

Common Errors
-------------

### 435 Unable to authenticate at present

Your saslauthd socket is probably set wrong in your Local/Makefile
before compiling Exim.

    CYRUS_SASLAUTHD_SOCKET=/var/lib/sasl2/mux

### openpam\_read\_chain(): /etc/pam.d/(1): invalid facility '\^\^\_\^S' (ignored)

If the saslauthd PAM mech is used with OpenPAM (netBSD, FreeBSD) this
error occurs in some cases.

You have to provide a service name (like "smtp" in this case points to
"/etc/pam.d/smtp") to saslauthd in your config by using:

    server_condition = ${if saslauthd{{$1}{$2}{smtp}}{1}{0}}

instead of

    server_condition = ${if saslauthd{{$1}{$2}}{1}{0}}

For virtual mailbox hosting with /etc/default/saslauthd:MECHANISMS="sasldb", with the LOGIN authenticator, and your login names are of the format username@example.com, you will need to extract the domain part and pass it in as the "realm" parameter as follows:

    server_condition = ${if saslauthd{{${local_part:$auth1}}{$auth2}{}{${domain:$auth1}}}{1}{0}}

This comes from a comment in the source code:

    // From the source code comment in expand.c
    ${if saslauthd {{username}{password}{service}{realm}}  {yes}{no}}

You can test the username and password on the server shell with e.g.

    testsaslauthd -u username -r example.com -p secret

*(May be this is a good idea in other situations too or should be
generally added to the upper Exim config?)*

### 535 Incorrect authentication data

SASLAuthd was unable to authenticate that user/pass combo. If you're
certain it's correct, make sure the permissions are correct on your
socket file's directory:

    chmod o+x /var/lib/sasl2

...and that saslauthd is running:

    ps aux | grep saslauthd

* * * * *

> [CategoryHowTo](CategoryHowTo) [HowTo](../HowTo)
