Cyrus Imap
==========

Introduction
------------

[The Cyrus Electronic Mail
Project](..%20_Cyrus%20Project:%20http://asg.web.cmu.edu/cyrus/) is
continuing to build a highly scalable enterprise mail system designed
for use in a small to large enterprise environments using standards
based technologies. The Cyrus technologies will scale from independent
use in small departments to a system centrally managed in a large
enterprise.

The major item of interest to Exim users is [the Cyrus Imap
server](..%20_Cyrus%20Imap%20Server:%20http://asg.web.cmu.edu/cyrus/imapd/),
which can be integrated with an [exim](http://www.exim.org/) MTA.

Links
-----
-   \`Cyrus Project\`\_
-   \`Cyrus Imap Server\`\_
-   [Cyrus Wiki](http://cyruswiki.andrew.cmu.edu/)
-   [Cyrus-IMAP virtual
    domains](http://asg.web.cmu.edu/cyrus/download/imapd/install-virtdomains.html)

Making Real Time LMTP Callouts to a Cyrus IMAP
----------------------------------------------

Based on information provided by [Andrzej
Filip](http://anfi.homeunix.org/) in ["Real Time Cyrus and Exim
Integration"](http://anfi.homeunix.org/exim/rtvcyrus.html) and copied
into here.

Original e-mail
[announcement](http://www.exim.org/mailman/htdig/exim-users/Week-of-Mon-20040816/037424.html)
to exim-users mailing list.

### Cyrus Configuration

Make cyrus wait for unauthenticated lmtp connections over TCP on local
interface. In cyrus.conf add:-

    SERVICES {
      ...
      lmtp          cmd="lmtpd -a" listen="127.0.0.1:lmtp" prefork=0
    }

Without "-a" lmtp requires authentication for LMTP over TCP (Exim does
not support callouts over UNIX sockets). If your /etc/services files
does not define lmtp service (2003/tcp) then use
`listen="127.0.0.1:2003"`

### Exim Configuration

Define cyrus\_domains domainlist to list all virtual domains handled by
your cyrus.

    domainlist cyrus_domains = example.net : example.com : example.org

The best place is just before (or just after) "domainlist local\_domains
=" line.

Define cyrus\_ltcp (cyrus local tcp) transport in transports section.

    cyrus_ltcp:
      driver = smtp
      protocol = lmtp
      hosts = localhost
      allow_localhost

It will deliver messages to lmtp port at localhost using lmtp protocol.
If your /etc/services files does not define lmtp service (2003/tcp) then
add the following line to the file

    port = 2003

Insert cyrus\_vdom router as first routers section

    cyrus_vdom:
      driver = accept
      domains = +cyrus_domains
      transport = cyrus_ltcp
      no_more

It will select cyrus\_lmtp transport for all addresses in cyrus\_domains
domains.

Add checking validity of addresses in cyrus virtual domain in
acl\_check\_rcpt section. I have added the lines just after "accept
hosts = :" line [skipping tests for SMTP not over TCP/IP (local)].

    # Reject "faked" envelope sender addresses in cyrus domains

    deny sender_domains = +cyrus_domains
         message        = Sender unknown/invalid
         !verify        = sender/callout=defer_ok,5s

    # Accept valid (and reject invalid) envelope recipient adresses in cyrus domains

    accept domains      = +cyrus_domains
         endpass
         message        = ${if match{$acl_verify_message}\
                          {\N(?m)^\d{3} (\d\.\d\.\d .{0,120})\Z\N} \
                          {IMAP said: $1}{Recipient unknown/invalid}}
         verify         = recipient/callout=random,5s

defer\_ok makes exim accpet messages when cyrus in unavailable. 30s
defines timeout for callout connection attempts. The strange looking
message is supposed to provide Cyrus-IMAP's reply to failed "RCPT TO:"
in Exim's reply to "RCPT TO:".

Troubleshooting
---------------

If you are getting the message (in `exim4/mainlog`)

    Could not complete recipient verify callout

use `hosts = your.host.name` instead of `hosts = localhost` in the
transport. You might also have to adjust the hostname in the
`cyrus.conf` accordingly. Try `telnet your.host.name lmtp` to see if you
can still connect to it.

Exim Wishlist for better Cyrus-IMAP integration
-----------------------------------------------
-   making Exim capable to do LMTP callouts via UNIX socket
-   making Exim support "socket map" protocol supported by Cyrus-IMAP
    (and [sendmail](http://www.sendmail.org/)).

* * * * *

> [CategoryHowTo](CategoryHowTo)
