Exim4 Configuration For A SSL Certificate
=========================================

This page show you how to configure Exim4 to use a SSL Server
Certficate. This example was used on a Debian System, but should be
similar for most other systems.

The examples show how to get a certificate from \`CAcert.org\`\_ - a
free certificate provider[^1]

Generate Local Server-side Certificate
--------------------------------------

Run the command:

    /usr/share/doc/exim4-base/examples/exim-gencert

(adding the '--force' option if you have already done this once. *This
is a debian specific operation, and there is no analogous step needed on
other systems*

Then execute:

    openssl req -new -key /etc/exim4/exim.key -out /etc/exim4/exim.csr

supplying values at the prompt.

Further advice on generating a certificate can be found in the [CACert
Help](http://www.cacert.org/help.php?id=4).

Generate CACert Certificate
---------------------------

Create a new server certificate using the web menues within the
CAcert.org pages and paste the contents of the file
`/etc/exim4/exim.csr` where prompted.

Then copy what is generated to the file `/etc/exim4/exim.crt`
(over-writing its existing contents).

OR: Import a certificate from a pfx file e.g. exported from a Windows server
----------------------------------------------------------------------------
`
root@me:~# openssl pkcs12 -in ExportWithPrivate.pfx -clcerts -nokeys -out servername.crt
`

IMPORTANT - These files are to be kept SECRET.

`
root@me:~# openssl pkcs12 -in ExportWithPrivate.pfx -out servername.pem
`

`
root@me:~# openssl rsa -in servername.pem -out exim.key
`

Now concatenate the certificates:

`
root@me:~# cat servername.crt COMODOSSLCA.crt AddTrustExternalCARoot.crt > exim.crt
`

Copy the files `exim.key` and `exim.crt` to `/etc/exim`

IMPORTANT: Backup the files to a secure location and delete the remaining files.

Update Exim configuration files
-------------------------------

For split-file configuration *(debian only)*, edit the file
/etc/exim4/conf.d/main/03\_exim4-config\_tlsoptions and uncomment:

    # log_selector = +tls_cipher +tls_peerdn
    # tls_advertise_hosts = *
    # tls_certificate = CONFDIR/exim.crt
    # tls_privatekey = CONFDIR/exim.key

Then, activate the exim4 changes by:

    update-exim4.conf

Alternatively *(or if you are not a debian user)* edit your exim config
file and add the following options to the first section of your
configuration file :

    log_selector = +tls_cipher +tls_peerdn
    tls_advertise_hosts = *
    tls_certificate = /etc/exim/exim.crt
    tls_privatekey = /etc/exim/exim.key

Change the file security so that only exim can read them (if you are running as exim):

`
root@myserver:~# chmod 600 exim.*
`

`
root@myserver:~# chown exim exim.*
`https://github.com/Exim/exim/wiki/_preview


In either case you need to restart exim:-

    /etc/init.d/exim4 restart

or your appropriate similar command.

Reference
---------

Following help file taken from Debian Exim4 package:
[http://cvs.alioth.debian.org/cgi-bin/cvsweb.cgi/\~checkout\~/exim/exim/debian/README.TLS?rev=1.12&content-type=text/plain&cvsroot=pkg-exim4](http://cvs.alioth.debian.org/cgi-bin/cvsweb.cgi/~checkout~/exim/exim/debian/README.TLS?rev=1.12&content-type=text/plain&cvsroot=pkg-exim4)

This document was lifted from the CAcert.org wiki and modified to make a
little more general. The original source is at
[http://wiki.cacert.org/wiki/Exim4Configuration](http://wiki.cacert.org/wiki/Exim4Configuration)

* * * * *

[^1]: You will however had to previously set up a login with CAcert.org
    - a process that includes email verification - and have demonstrated
    an administrator or owner link to the domain you are requesting
    certificates for
