Athenticated SMTP using either PAM and/or Passwords
===================================================

Introduction
------------

You may be faced with a situation in which you would like to use PAM for
SMTP authentication, but with the possibility of passwords in a local
file, say /etc/exim4/passwd, overriding those in PAM. In other words,
the goal is to have the following:
-   Check if the user ID exists, along with a password, in
    /etc/exim4/passwd
-   If so, use the password in /etc/exim4/passwd to authenticate
-   If not (or if /etc/exim4/passwd does not exist), use PAM to
    authenticate.

This document shows you how to do this.

Configuring Exim
----------------

You need to configure and build Exim 4 to support PAM for this
configuration to work. See the page on [Authenticated SMTP using
PAM](AuthenticatedSmtpUsingPam) for more details. On Debian
GNU/Linux, this is as simple as installing Exim 4; you most likely need
the `exim4-daemon-heavy` package. You also need to add the `Debian-exim`
user into the `shadow` group, so as to give Exim access to /etc/shadow
via PAM.

In the configuration file, typically /etc/exim4/exim4.conf or similar,
make sure authentication is only enabled on an encrypted connection.
This is due to the fact that passwords would otherwise be sent in clear
text:

    auth_advertise_hosts = ${if eq{$tls_cipher}{}{false}{true}}

Naturally, you will need to set up an appropriate encryption
certificate. For example:

    tls_advertise_hosts = *
    tls_certificate     = /etc/letsencrypt/live/example.com/fullchain.pem
    tls_privatekey      = /etc/letsencrypt/live/example.com/privkey.pem

In this case, /etc/letsencrypt/live/example.com/fullchain.pem contains the certificate
for SMTP, signed by LetsEncrypt, including the full chain of certificates as needed. The file
/etc/letsencrypt/live/example.com/privkey.pem contains the private key; it must be
readable by Exim (typically by making it group-readable by the
`Debian-exim` group, on Debian systems).  You should also investigate using the tls_dhparam
configuration option to avoid using common primes.

Finally, add the following authenticators:

    begin authenticators

    #########################################################################
    plain_server:

      # This authenticator implements the PLAIN authentication mechanism
      # (RFC2595).  Since the password is transmitted essentially as clear
      # text, a user can only authenticate if the session is encrypted using
      # TLS.  The user name and password is first checked against
      # /etc/exim4/passwd, then against the system database using PAM (in
      # that order).

      driver                     = plaintext
      public_name                = PLAIN
      server_advertise_condition = ${if eq{$tls_cipher}{}{false}{true}}
      server_prompts             = :
      server_set_id              = $auth2

      server_condition           = "\
            ${if exists{CONFDIR/passwd}\
              {${lookup{$auth2}lsearch{CONFDIR/passwd}\
                {${if crypteq{$auth3}{${extract{1}{:}{$value}{$value}fail}}\
                  {true}{false} }}\
                {${if pam{$auth2:${sg{$auth3}{:}{::}} }\
                  {true}{false}} } }}\
              {${if pam{$auth2:${sg{$auth3}{:}{::}} }\
                {true}{false}} }}"

    #########################################################################
    login_server:

      # This authenticator implements the LOGIN authentication mechanism.
      # Since the password is transmitted essentially as clear text, a user
      # can only authenticate if the session is encrypted using TLS.  The
      # user name and password is first checked against /etc/exim4/passwd,
      # then against the system database using PAM (in that order).

      driver                     = plaintext
      public_name                = LOGIN
      server_advertise_condition = ${if eq{$tls_cipher}{}{false}{true}}
      server_prompts             = Username:: : Password::
      server_set_id              = $auth1
      server_condition           = "\
            ${if exists{CONFDIR/passwd}\
              {${lookup{$1}lsearch{CONFDIR/passwd}\
                {${if crypteq{$auth2}{${extract{1}{:}{$value}{$value}fail}}\
                  {true}{false} }}\
                {${if pam{$auth1:${sg{$auth2}{:}{::}} }\
                  {true}{false}} } }}\
              {${if pam{$auth1:${sg{$auth2}{:}{::}} }\
                {true}{false}} }}"

`CONFDIR` is assumed to be a macro pointing to the configuration
directory. In other words, something like the following should appear in
the Exim configuration file:

    CONFDIR = /etc/exim4

Configuring /etc/exim4/passwd
-----------------------------

You need to create an appropriate password file to use with these
authenticators. You might like to use the following as a template:

    #########################################################################
    #    /etc/exim4/passwd: Client Passwords for Mail Submission to Exim    #
    #########################################################################

    # This file allows a user to authenticate a mail submission to the Exim
    # MTA without using their system password (found in /etc/shadow).
    #
    # Each line of this file should contain a "user:password:comment" field,
    # where the password is encrypted and encoded using standard crypt(3)
    # functions--the same format as is used in /etc/shadow.  You can disable
    # a user from ever sending (authenticated) messages by using "*" as the
    # password.
    #
    # You can use the following command line to generate the password:
    #
    #  mkpasswd -m sha-512 'password'
    #
    # (replace "password" with your password, of course).

    ####################
    #   System users   #
    ####################

    root:*:

    ###################
    #   Local users   #
    ###################

    #test:$6$VyTxt8CLk28oO576$.Og/ufsD5YLa57tpSS5Bm6y/brXLzt7mTXMP3mGmRpGgFs/MDfRhG7CIZlqoQ8aThkAV.ZfsFgYrjL1xvizgA/:Test#Password#01a

The easiest way to generate a password is to use the standard `mkpasswd` program
available on most Linux systems:

    mkpasswd -m sha-512 'password'

Simply replace *password* with your password.


Conclusion
----------

This document showed you how to consult both a password file *and* the
PAM system password databases, in that order, for authenticated SMTP.
The main reason for writing this document is the number of hours the
author spent debugging the authenticators before discovering (a) the
`-d+expand` command line argument and (b) the need for `\\\{md5\\\}`
instead of `\{md5\}` in the `crypteq` function (as used in a previous
version of this document)! -- [JohnZaitseff](JohnZaitseff)

* * * * *

> [CategoryHowTo](CategoryHowTo)
