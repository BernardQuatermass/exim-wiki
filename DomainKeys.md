Yahoo DomainKeys support
========================

DomainKeys support is **gone**. [Experimental](ExperimentalSpec)

**This support existed for one release, 4.69**

The 4.69 release of Exim contained experimental support for DomainKeys.
In the 4.70 release, this was replaced with non-experimental DKIM
support. This documentation is left as a reference for those using
systems still based around 4.69.

DomainKeys (DK) support is built into Exim using the `libdomainkeys`
reference library implementation. It is available at
[http://domainkeys.sf.net](http://domainkeys.sf.net) - this library is
licensed with a licence that is incompatible with the
[GPL](http://www.wikipedia.com/wiki/GPL) which means that you may not distribute
copies of Exim linked against `libdomainkeys` (and you will also not be
able to obtain pre-compiled packages for this reason).

You must build this library on your system and compile Exim against it.
To build Exim with DK support, add these lines to your Local/Makefile:

    EXPERIMENTAL_DOMAINKEYS=yes
    CFLAGS  += -I/home/tom/exim-cvs/extra/libdomainkeys
    LDFLAGS += -ldomainkeys -L/home/tom/exim-cvs/extra/libdomainkeys

Remember to tweak the CFLAGS and LDFLAGS lines to match the location of
the libdomainkeys includes and lib on your system.

The current experimental implementation supports two independent
functions:
-   Validate incoming DK-signed email.
-   Sign outgoing email with DK.

The former is implemented in the ACLs for SMTP, the latter as an
extension to the SMTP transport. That means both facilities are limited
to SMTP I/O.

1. Validate incoming email
--------------------------

Incoming messages are fed to the DK validation process as they are
received "on the wire". This happens synchronously to Exim's buffering
of the message in the spool.

You must set "control = dk\_verify" in one of the ACLs preceding DATA
(you will typically use acl\_smtp\_rcpt), at a point where non-local,
non-relay, non-submission mail is processed. If that control flag is not
set, the message will NOT be verified.

Example:

    warn log_message = Feeding message to DK validator.
         control = dk_verify

You can check for the outcome of the DK check in the ACL after data
(acl\_smtp\_data), using a number of ACL conditions and/or expansion
variables.

### 1.1.) DK ACL conditions

> dk\_sender\_domains = \<domain list\>
>
> > This condition takes a domainlist as argument and succeeds if the
> > domain that DK has been verifying for is found in the list.
>
> dk\_senders = \<address list\>
>
> > This condition takes an addresslist as argument and succeeds if the
> > address that DK has been verifying for is found in the list.
>
> dk\_sender\_local\_parts = \<local part list\>
>
> > This condition takes a local\_part list as argument and succeeds if
> > the domain that DK has been verifying for is found in the list.
>
> dk\_status = \<colon separated list of keywords\>
>
> > This condition takes a list of keywords as argument, and succeeds if
> > one of the listed keywords matches the outcome of the DK check. The
> > available keywords are:

[Table not converted]

[Table not converted]

> [Table not converted]
>
> dk\_policy = \<colon separated list of keywords\>
>
> > This condition takes a list of keywords as argument, and succeeds if
> > one of the listed keywords matches the policy announced by the
> > target domain. The available keywords are: signsall The target
> > domain signs all outgoing email. testing The target domain is
> > currently testing DK.
>
> dk\_domain\_source = \<colon separated list of keywords\>
>
> > This condition takes a list of keywords as argument, and succeeds if
> > one of the listed keywords matches the location where DK found the
> > sender domain it verified for. The available keywords are: from The
> > domain came from the "From:" header. sender The domain came from the
> > "Sender:" header. none DK was unable to find the responsible domain.

### 1.2.) DK verification expansion variables

> \$dk\_sender\_domain
>
> > Contains the domain that DK has verified for.
>
> \$dk\_sender
>
> > Contains the address that DK has verified for.
>
> \$dk\_sender\_local\_part
>
> > Contains the local part that DK has verified for.
>
> \$dk\_sender\_source
>
> > Contains the "source" of the above three variables, one of
> >
> > > "from" The address came from the "From:" header. "sender" The
> > > address came from the "Sender:" header.
> >
> > When DK was unable to find a valid address, this variable is "0".
>
> \$dk\_signsall
>
> > Is "1" if the target domain signs all outgoing email, "0" otherwise.
>
> \$dk\_testing
>
> > Is "1" if the target domain is testing DK, "0" otherwise.
>
> \$dk\_is\_signed
>
> > Is "1" if the message is signed, "0" otherwise.
>
> \$dk\_status
>
> > Contains the outcome of the DK check as a string, commonly used to
> > add a "[DomainKey](DomainKey)-Status:" header to messages. Will
> > contain one of:

[Table not converted]

[Table not converted]

> [Table not converted]
>
> \$dk\_result
>
> > Contains a human-readable result of the DK check, more verbose than
> > \$dk\_status. Useful for logging purposes.

2.) Sign outgoing email with DK
-------------------------------

Outgoing messages are signed just before Exim puts them "on the wire".
The only thing that happens after DK signing is eventual TLS encryption.

Signing is implemented by setting private options on the SMTP transport.
These options take (expandable) strings as arguments. The most important
variable to use in these expansions is \$dk\_domain. It contains the
domain that DK wants to sign for.

> dk\_selector = \<expanded string\> [MANDATORY]
>
> > This sets the key selector string. You can use the \$dk\_domain
> > expansion variable to look up a matching selector. The result is put
> > in the expansion variable \$dk\_selector which should be used in the
> > dk\_private\_key option along with \$dk\_domain.
>
> dk\_private\_key = \<expanded string\> [MANDATORY]
>
> > This sets the private key to use. You SHOULD use the \$dk\_domain
> > and \$dk\_selector expansion variables to determine the private key
> > to use. The result can either
> >
> > -   be a valid RSA private key in ASCII armor, including line
> >     breaks.
> >
> > -   start with a slash, in which case it is treated as a file that
> >     contains the private key.
> >
> > -   be "0", "false" or the empty string, in which case the message
> >     will not be signed. This case will not result in an error, even
> >     if dk\_strict is set.
> >
> dk\_canon = \<expanded string\> [OPTIONAL]
>
> > This option sets the canonicalization method used when signing a
> > message. The DK draft currently supports two methods: "simple" and
> > "nofws". The option defaults to "simple" when unset.
>
> dk\_strict = \<expanded string\> [OPTIONAL]
>
> > This option defines how Exim behaves when signing a message that
> > should be signed fails for some reason. When the expansion evaluates
> > to either "1" or "true", Exim will defer. Otherwise Exim will send
> > the message unsigned. You can and should use the \$dk\_domain and
> > \$dk\_selector expansion variables here.
>
> dk\_domain = \<expanded string\> [NOT RECOMMENDED]
>
> > This option overrides DKs autodetection of the signing domain. You
> > should only use this option if you know what you are doing. The
> > result of the string expansion is also put in \$dk\_domain.

Yahoo DomainKeys for Exim + FreeBSD + bind name server howto
============================================================

This is a quick tutorial on how to enable domainkeys
([http://domainkeys.sourceforge.net/](http://domainkeys.sourceforge.net/))
on Exim on a FreeBSD server.

First, if you have not installed yet Exim, you have to install it. If
you have installed it already, you have to recompile it.

The way to do it:

    cd /usr/ports/mail/exim
    ee Makefile    (or use joe / vi /whatever you like)

Search for the following lines:

    # Enable DomainKeys support
    #WITH_DOMAINKEYS=       yes

..and uncomment the "\#WITH\_DOMAINKEYS= yes".

Now you will have:

    # Enable DomainKeys support
    WITH_DOMAINKEYS=       yes

Save and exit the text editor.

Do the following:

    make clean
    make rmconfig
    make
    make FORCE_PKG_REGISTER=1 install  <-- if you already have exim installed.

    make install                       <-- if you don't have yet exim installed.

Copy & paste in your console:

    cd /usr/local/etc/exim
    mkdir dk
    cd dk
    openssl genrsa -out rsa.private 768
    openssl rsa -in rsa.private -out rsa.public -pubout -outform PEM
    cat rsa.public

After all this you will have a result which will look something like
that:

    -----BEGIN PUBLIC KEY-----
    MHwwDQYJKoZIhvcNAQEBBQADawAwaAJhAKJ2lzDLZ8XlVambQfMXn3LRGKOD5o6l
    MIgulclWjZwP56LRqdg5ZX15bhc/GsvW8xW/R5Sh1NnkJNyL/cqY1a+GzzL47t7E
    XzVc+nRLWT1kwTvFNGIoAUsFUq+J6+OprwIDAQAB
    -----END PUBLIC KEY-----

Save whats between ---BEGIN PUBLIC KEY--- and ---END PUBLIC KEY--- for
later use.

Edit with your favorite text editor /usr/local/etc/exim/configure

find the line which starts with "remote\_smtp:" . This should be under
the "begin transports" section of the file.

It looks like that:

    remote_smtp:
      driver = smtp

Edit there and make it look like that:

    remote_smtp:
      driver = smtp
      dk_selector = myselector    # you will need this later when you will alter your dns config
      dk_private_key = /usr/local/etc/exim/dk/rsa.private
      dk_canon = nofws

Save the file, exit and start/restart exim :

    sh /usr/local/etc/rc.d/exim.sh restart

Login to the server that serves as DNS server for the domain name for
which you are configuring this domainkey thing.

Go to /etc/namedb/

Find the file corresponding to your domain (look for it in named.conf
and you will find the path to it).

Let's presume is /etc/namedb/pri/com/yourdomain.com. Edit this file, and
just after/below the IN MX statement, add the following things:

    _domainkey.yourdomain.com.       IN      TXT     "t=y; o=-"

    myselector._domainkey.yourdomain.com.  IN      TXT     "k=rsa; t=y; p=MHwwDQYJKoZIhvcNAQEBBQADawAwaAJhAKJ2lzDLZ8XlVambQfMXn3LRGKOD5o6lMIgulclWjZwP56LRqdg5ZX15bhc/GsvW8xW/R5Sh1NnkJNyL/cqY1a+GzzL47t7EXzVc+nRLWT1kwTvFNGIoAUsFUq+J6+OprwIDAQAB"

Alter the serial (for example, if today is 28-aug-2007, make your serial
look like 2007082800 or 2007082801, etc), save the file and reload
named.

if your domain is something like customer.yourdomain.com, then the
records will look like that:

    _domainkey.customer.yourdomain.com.       IN      TXT     "t=y; o=-"

    myselector._domainkey.customer.yourdomain.com.  IN      TXT     "k=rsa; t=y; p=MHwwDQYJKoZIhvcNAQEBBQADawAwaAJhAKJ2lzDLZ8XlVambQfMXn3LRGKOD5o6lMIgulclWjZwP56LRqdg5ZX15bhc/GsvW8xW/R5Sh1NnkJNyL/cqY1a+GzzL47t7EXzVc+nRLWT1kwTvFNGIoAUsFUq+J6+OprwIDAQAB"

Remember to also modify /etc/namedb/named.conf:

Add the following to your options { ... } section of named.conf

    check-names master ignore;

This will allow you to use \_ (underscore).

You will have to edit and add that "check-names master ignore;" thing if
you get the following error in your logs:

    Aug 28 15:02:33 noc1 named[83277]: pri/com/yourdomain.com:15: myselector._domainkey.yourdomain.com: bad owner name (check-names)
    Aug 28 15:02:33 noc1 named[83277]: zone yourdomain.com/IN: loading master file pri/com/yourdomain.com: bad owner name (check-names)

The long string after ....."k=rsa; t=y; p= is your public key which i
said you should keep for later use.

To test send an e-mail to dk at dk.crynwr.com . You will receive about 5
messages back from different addresses with test results.

If any of them says test passed you should be ok. Send an e-mail to a
yahoo.com e-mail address and check the headers.They should look like
this:

    From Dan Caescu Tue Aug 28 06:20:08 2007
    Return-Path: <test@yourdomain.com>
    Authentication-Results: mta233.mail.mud.yahoo.com  from=yourdomain.com; domainkeys=pass (ok)
    Received: from x.x.x.x  (EHLO relay.yourdomain.com) (x.x.x.y)
      by mta233.mail.mud.yahoo.com with SMTP; Tue, 28 Aug 2007 08:16:56 -0700
    DomainKey-Signature: a=rsa-sha1; q=dns; c=nofws; s=myselector; d=yourdomain.com;

That should be all.

Good luck!

* * * * *

> [CategoryHowTo](CategoryHowTo)
