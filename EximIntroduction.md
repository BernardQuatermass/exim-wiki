Exim Introduction
=================

**Exim** is a
[mail transfer agent](http://www.wikipedia.com/wiki/mail_transfer_agent) (MTA) used
in [Unixllike](http://www.wikipedia.com/wiki/Unix-like) operating systems. The first
version was written in 1995 by Philip Hazel for use in the University of
Cambridge Computing Service's [e-mail](http://www.wikipedia.com/wiki/e-mail)
systems. Exim is distributed under the [GPL](http://www.wikipedia.com/wiki/GPL), and
therefore is [free](http://www.wikipedia.com/wiki/Free_software) to download, use
and modify.

Exim somewhat resembles [Smail](http://www.wikipedia.com/wiki/Smail) 3, but it has
diverged and now surpasses it in user friendliness and flexibility. They
both follow the [Sendmail](http://www.wikipedia.com/wiki/Sendmail) design model
where a single main binary controls all the facilities of the MTA. This
monolithic design is considered by some to be inherently less secure and
slower, but despite this, Exim's security record is much better than
Sendmail and comparable with [Qmail](http://www.wikipedia.com/wiki/Qmail) and
[Postfix](http://www.wikipedia.com/wiki/Postfix), as is its speed. In advanced areas
such as queue handling, address routing and testing, it exhibits
excellent performance. -- [Wikipedia](http://www.wikipedia.com/wiki/Main_Page)
[Exim](http://www.wikipedia.com/wiki/Exim)

Features
--------

### You don't get ...

Some people come here looking to get a complete email server package.
Exim isn't that, it's a Mail Transport Agent and a Mail Submission
Agent. Here are some of the things that you won't get with Exim:

No POP, No IMAP. Exim is not a mailstore. It does not support IMAP or
POP protocols, though it can deliver messages to mailstores that do,
either using SMTP or LMTP message delivery, or in some cases by saving
messages directly into mailboxes.

No GUI. Exim doesn't have a Graphical User Interface (GUI) to help you
configure it, but some Linux distributions add one. Various tools are
available to give you graphical views of Exim's mail queues, traffic,
and logs.

### You do get ...

RFC 2821 SMTP and RFC 2033 LMTP email message transport.

Incoming (as SMTP server):
-   SMTP over TCP/IP (Exim daemon or inetd);
-   SMTP over the standard input and output (the -bs option);
-   Batched SMTP on the standard input (the -bS option).

Exim also supports RFC 5068 Message Submission, as an SMTP server with
(for example, encrypted and authenticated connections on port 587).

Outgoing email (as SMTP or LMTP client):
-   SMTP over TCP/IP (the smtp transport);
-   LMTP over TCP/IP (the smtp transport with the protocol option set to
    “lmtp”);
-   LMTP over a pipe to a process running in the local host (the lmtp
    transport);
-   Batched SMTP to a file or pipe (the appendfile and pipetransports
    with the use\_bsmtp option set).

Configuration
-   Access Control Lists - flexible policy controls.
-   Content scanning, including easy integration with and other spam and
    virus scanners like [SpamAssassin](../SpamAssassin) and
    [ClamAV](../ClamAV).
-   Encrypted SMTP connections using TLS/SSL.
-   Authentication with a variety of front end and back end methods,
    including PLAIN, LOGIN, sasl, dovecot, spa, cram\_md5.
-   Rewrite - rewrite envelope and/or header addresses using regular
    expressions.
-   Routing controls - use routers to redirect, quarantine, or deliver
    messages.
-   Transports - use transports to deliver messages by smtp, lmtp, or to
    files, directories, or other programs.
-   Flexible retry rules for temporary delivery problems.

Support

Exim includes excellent documentation, including a comprehensive
online manual available in several formats including a 476 page pdf,
this wiki, and a book. There's an email support list populated with
helpful (if sometimes excitable) users and even with Exim developers
who actually understand email. Exim - probably the best documented
mail server in the world!

Some Linux distributions include Exim, and add on GUI configuration
tools. Documentation for those tools is best obtained from the Linux
distributors.

Exim Utilities

A number of utilities are also included in the distribution, to aid
with log file inspection, queue management, reporting, configuration
testing, and so on. See chapter 50 of the documentation.

### Lemonade

[Lemonade](http://www.standardstrack.com/ietf/lemonade/) is a collection
of extensions to IMAP and SMTP that support mobile messaging. Of the
SMTP extensions, Exim supports the following. References are to sections
of the manual, or to configuration options.
-   SUBMIT. "Message Submission for Mail" (RFC 4409) - [section 7.1]
-   PIPELINING. "SMTP Extension for Command Pipelining" (RFC 2197) -
    [pipelining\_advertise\_hosts]. Pipelining is advertised to all
    hosts by default.
-   SIZE. "SMTP Service Extension for Message Size Declaration" (RFC
    1870) - on by default.
-   SMTP AUTH. "SMTP Service Extension for Authentication" (RFC 2554) -
    [auth\_advertise\_hosts
-   START-TLS. “SMTP Service Extension for Secure SMTP over TLS” (RFC
    3207) - [tls\_advertise\_hosts]
-   8BITMIME. "SMTP Service Extension for 8bit MIME Transport" (RFC
    1652) - [accept\_8bitmime]. Setting accept\_8bitmime allows Exim to
    accept 8 bit messages, and is on by default, since version 4.80. Exim doesn't do
    anything special with such messages. You might want to switch this off if you know that you're sending messages to systems that can't handle 8bitmime, but these appear to be rare.
-   DSN. "Simple Mail Transfer Protocol (SMTP) Service Extension for
    Delivery Status Notifications" (RFC 3461). Note that Exim will issue
    delivery delay and failure notifications normally; this extension allows 
    clients to say when and how notifications should be issued.

But does not support:
-   BURL. "Message Submission BURL Extension" (RFC 4468)
-   CHUNKING. "“SMTP Service Extensions for Transmission of Large and
    Binary Messages" (RFC 3030)  [up until release 4.87.  If all goes
    well, CHUNKING support will appear in the next release]
-   BINARYMIME. "SMTP Service Extensions for Transmission of Large and
    Binary Messages" (RFC 3030)
-   ENHANCEDSTATUSCODES. "SMTP Extension for Returning Enhanced Error
    Codes" (RFC 2034) - [section 40.16] note that Exim allows you to
    construct smtp replies with rfc1893 enhanced error codes, but it
    doesn't have any way of automatically generating them, and it won't
    advertise ENHANCEDSTATUSCODES in the reply to EHLO.

### Other SMTP extensions supported
-   SMTPUTF8
-   PRDR

Availability
------------

Exim is available from many places - see
[ObtainingExim](ObtainingExim).