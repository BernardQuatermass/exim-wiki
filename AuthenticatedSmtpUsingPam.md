Authenticated SMTP using PAM
============================

Introduction
------------

For those of you who wanted to know what the solution was here is a
detailed note for your info. This will allow you to do authenticated
smtp over ssl with the standard exim just using pam. Pam is an acronym
for Pluggable Authentication Modules. You can use pam with a standard
linux distribution for example which means that you can have smtp
authentication with pam without downloading more software.

Required Software:
------------------
-   Exim 4.x

Compiling exim
--------------

To have smtp authentication available in exim, you need to make sure
that it is compiled into the exim binary before you configure it. The
following settings need to be set in the Makefile before you compile
exim.

    AUTH_PLAINTEXT=yes
    SUPPORT_TLS=yes
    TLS_LIBS=-lssl -lcrypto
    TLS_LIBS=-L/usr/local/openssl/lib -lssl
    TLS_INCLUDE=-I/usr/local/openssl/include/
    SUPPORT_PAM=yes
    EXTRALIBS=-lpam

Configuring exim
----------------

Make sure you have the following in the exim config file

    tls_advertise_hosts = *
    tls_certificate = /usr/lib/courier-imap/share/imapd.pem

(note: I am using the certificate that courier installs for itself, you
will probably wish to point to your own certificate)

    auth_advertise_hosts = ${if def:tls_in_cipher {*}{}}

(This means only connections over ssl will be offered authentication,
you do not need this but we do not want users sending their password
over unencrypted connections so we use it)

    begin authenticators

    PLAIN:
       driver = plaintext
       server_prompts = :
       server_condition = "${if pam{$auth2:$auth3}{yes}{no}}"
       server_set_id = $auth2

    LOGIN:
       driver = plaintext
       server_prompts = "Username:: : Password::"
       server_condition = "${if pam{$auth1:$auth2}{yes}{no}}"
       server_set_id = $auth1

Also I have exim run as group exim this group needs read access on

    /etc/shadow
    /usr/lib/courier-imap/share/imapd.pem
    /etc/pam.d/exim

Contents of /etc/pam.d/exim
---------------------------

    auth        required      /lib/security/$ISA/pam_env.so
    auth        sufficient    /lib/security/$ISA/pam_unix.so likeauth nullok
    auth        required      /lib/security/$ISA/pam_deny.so
    account     required      /lib/security/$ISA/pam_unix.so
    password    required      /lib/security/$ISA/pam_cracklib.so retry=3 type=
    password    sufficient    /lib/security/$ISA/pam_unix.so nullok use_authtok md5shadow
    password    required      /lib/security/$ISA/pam_deny.so
    session     required      /lib/security/$ISA/pam_limits.so
    session     required      /lib/security/$ISA/pam_unix.so

This file **must** be readable by the `exim` group (the group your exim
daemon runs as) otherwise you will get the error

    535 Incorrect authentication data (set_id='userid')

Conclusion
----------

With the above we are able to do authenticated smtp using standard out
of the box exim and the standard pam modules that come with linux. So no
need for sassl authd or pam\_exim or anything else, it all just works.

Hope this is cluefull to those of you trying to do the same.

Ron

### Points for consideration

I found this helpful, but suggest that other readers should consider two
points re /etc/pam.d/exim file above:

Is null\_ok right for your system (Do you want to allow accounts with no
password to relay mail)?

Is password change processing appropriate for exim on your system?

Ken

FreeBSD
-------

Under FreeBSD the /etc/master.password file (containing encrypted
passwords, like Linux's /etc/shadow) is unreadable for Exim when
authentication occurs; to make master.password readable for the mail
group is considered a security risk. If you run a POP3 server (I run
popa3d from inetd), you can authenticate using the security/pam\_pop3
port. Exim's configuration is same as above. Example of /etc/pam.d/exim
(two lines):

    auth required /usr/local/lib/pam_pop3.so hostname=localhost info pwprompt=Password: timeout=5
    account required pam_permit.so

The second line isn't mentioned in the pam\_pop3 documentation, but
without it you'd get an obscure "PAM error: error in service module".

* * * * *

> [CategoryHowTo](CategoryHowTo) [HowTo](../HowTo)
