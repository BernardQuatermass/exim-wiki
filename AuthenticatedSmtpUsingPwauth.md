Authenticated SMTP using pwauth
===============================

Introduction
------------

One of the options Exim has for authentication without root access is by
using [SASLAuthd](http://wiki.exim.org/AuthenticatedSmtpUsingSaslauthd)
from the Cyrus suite. However, there is another option: pwauth, which is
probably more easy to setup and which can be used by multiple daemons
(like Apache AND Exim). It is recommended you follow the instructions in
the [AuthenticatedSmtpUsingPam](AuthenticatedSmtpUsingPam) tutorial
regarding encryption (TLS) as they won't be discussed here. This is
based on a Debian 5.0/Lenny install.

Required Software
-----------------
-   Exim 4.x
-   pwauth
    ([[http://code.google.com/p/pwauth/](http://code.google.com/p/pwauth/)](http://unixpapa.com/pwauth/))
    - Current stable version is 2.3.8

Compiling Exim
--------------

Since I run Debian 5.0/Lenny which has a package system, I did not need
to compile Exim. Issueing `apt-get install exim4` as root is enough (and
most Debian users would not have to do that either because Exim4 is the
standard MTA on Debian).

Since I only use plaintext as authenticator driver, I don't think
there's much hocus-pocus in compiling Exim. If anyone has instructions
on compiling, please edit this page.

Configuring and compiling pwauth
--------------------------------

Download pwauth, extract the package and cd into the new directory:

    wget 'http://unixpapa.com/software/pwauth-2.3.8.tar.gz'
    tar xzf ./pwauth-2.3.8.tar.gz
    cd pwauth-2.3.8/

As with any piece of software you compile yourself, you should read the
README and the INSTALL file. They contain all the information you'll
need to configure pwauth. Next, edit config.h and set it up to reflect
your system. The settings I used are the following:

    #define SHADOW_SUN
    #define UNIX_LASTLOG
    #define HAVE_LASTLOG_H
    #define NOLOGIN_FILE "/etc/nologin"
    #define MIN_NOLOGIN_UID 1
    #define CHECK_LOGIN_EXPIRATION
    #define CHECK_PASSWORD_EXPIRATION
    #define SERVER_UIDS 33,101
    #define MIN_UNIX_UID 500
    #define SLEEP_LOCK "/var/run/pwauth.lock"

You need to give special attention to the line **SERVER\_UIDS**, as that
can differ for your system. It needs a list of UID (user ids) that can
run pwauth. This list obviously needs to include the user that runs
Debian-exim. On my system, Exim is run as user Debian-exim. To retrieve
the UID for this user, I give the following command:
`grep Debian-exim /etc/passwd` It gives the following output on my
system: `Debian-exim:x:101:105::/var/spool/exim4:/bin/false` The UID is
the number after the second ':' (so the UID is 101).

In case your wondering why I have two UIDs in the line SERVER\_UIDS: UID
33 is the user Apache is running under.

When config.h is all set up, we can compile pwauth:

    make

If compilation did not issue errors, we can install pwauth. Note that
you need to run the following commands *as root*.

    cp ./pwauth /usr/local/bin/
    chown root:staff /usr/local/bin/pwauth
    chmod 4755 /usr/local/bin/pwauth

### Testing pwauth

Next, we should test to see if pwauth works. As root, type the following
commands:

    su -s /bin/bash Debian-exim
    /usr/local/bin/pwauth ; echo $?

Then type the name of a user, hit enter, and type the password of a
user. If the password is valid, the last command should display 0. If
the password is invalid, the last command should display 1 or 2. For
other numbers, refer to the INSTALL file in the pwauth directory.

If you are here, pwauth is set up correctly for Exim!

Configuring Exim
----------------

We need to tell Exim how to use pwauth. This is done using an
authenticator. For my Debian system, I edited the file
etc/exim4/exim4.conf.template. I added this:

    plain_server:
     driver = plaintext
     public_name = PLAIN
     server_condition = ${and {\
       {!match{$auth2$auth3}{[\x27\r\n]}}\
       {bool{${run{/bin/bash -c "echo -e '$auth2\n$auth3' | /usr/local/bin/pwauth"}{1}{0}}}}\
                         }}
     server_set_id = $auth2
     server_prompts = :
     .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
     server_advertise_condition = ${if eq{$tls_cipher}{}{}{*}}
     .endif

    login_server:
     driver = plaintext
     public_name = LOGIN
     server_condition = ${and {\
       {!match{$auth1$auth2}{[\x27\r\n]}}\
       {bool{${run{/bin/bash -c "echo -e '$auth1\n$auth2' | /usr/local/bin/pwauth"}{1}{0}}}}\
                         }}
     server_set_id = $auth1
     server_prompts = <| Username: | Password:
     .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
     server_advertise_condition = ${if eq{$tls_cipher}{}{}{*}}
     .endif

What this does is tell Exim4 to enable authentication using plain-text
passwords only if we use a TLS connection. A TLS connection is an
encrypted connection using SSL certificates, and this makes sure no-one
can see our passwords. This also tells Exim to run pwauth to check if
the given username and password are valid.

Conclusion
----------

You'll now be able to authenticate without rooting up or messing with
PAM modules.

Common Errors
-------------

Check the logfiles (/var/log/exim4/mainlog on my system) for errors.

### 535 Incorrect authentication data

A generic error that could mean one of serveral things:
-   The given username was wrong
-   The given password was wrong
-   Exim was unable to find pwauth
-   Exim was unable to start pwauth

You can check the last case by doing the steps described in 'Testing
pwauth' above. If that succeeds, check you Exim configuration files
again.

### 435 Unable to authenticate at present

I only got this error when I made a typo in the configuration files.
This typo is described on the same logline as the error, so read the
line carefully.

### relay not permitted

The user did not authenticate to Exim, and therefor Exim only allows
mail for THIS machine. Keep in mind that in the example authenticator
above, Exim will only allow authentication when using a TLS connection!
For info on how to set up TLS, see
[AuthenticatedSmtpUsingPam](AuthenticatedSmtpUsingPam).

Other errors
------------

If you can not get this to work, try posting to the
[Eximuusers](http://lists.exim.org/mailman/listinfo/exim-users) mailing
list. I more or less read that list. Be sure to say 'pwauth' in the
subject.

* * * * *

> [CategoryHowTo](CategoryHowTo) [HowTo](../HowTo)
