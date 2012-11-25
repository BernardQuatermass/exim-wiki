Contributed by Viraj

here we can provide subheadings, such as wacky problems for things that
might be hard to search for. just a proposal...

There's certainly a need for some description of debugging procedures -
'have you tried exim -bh' etc.

Useful Exim command-line options
================================

You may like to add some of these to Exim command lines:

<form action="/TroubleShooting" method="GET" name="dbw.form">

optiondescription-v more verbose-d general debugging-d+all maximum
debugging-d+all-memory max debugging less some tedious memory stuff-bV
Always run this after making changes to the config file and before
restarting Exim. It will check the syntax for you-bhc &lt;ip\_addr&gt;
fake smtp session as though you are at ip\_addr. Use this to do a full
test before committing changes[Table not converted]

</form>

Examples of using -bhc
----------------------

This is very useful indeed, the "c" adds callout processing. If you
don't use them then drop the c from the command line. You will have to
be careful about how you use this to test all the cases you are
interested in.

Suppose that my Exim box acts as a relay for my nasty expensive
commercial internal mail system called "mail" and its address is
192.168.0.100. You make changes to the config file (say added callouts)
but don't restart Exim yet - you need to check it out first.

Here I only show what you might type, there will be quite a lot of
output from Exim about what it is doing.

### Check you can send from internal to external

    # exim -bhc 192.168.0.100
    helo mail
    mail from:<user in my domain>
    rcpt to:<random external address>
    data
    .

### Check that mail is relayed from external to internal

    # exim -bhc <random external valid IP address>
    helo <real name of above address>
    mail from:<external user>
    rcpt to:<valid internal user>
    data
    .

Having checked out the configuration you can then fairly confidently
restart/reload Exim to put the new config into action.

### A connect ACL uses zen.spamhaus.org in a dnslist check

`# exim -bhc 1.1.1.1`

If the ACL looks something like this, then you will get dropped early
on:

    acl_check_connect:

      drop    message               = $sender_host_address is listed by $dnslist_domain
              log_message           = Remote host $sender_host_address is listed by $dnslist_domain ###002
              dnslists              = zen.spamhaus.org

* * * * *

> See also the tools listed at [ManagingExim](ManagingExim).

SMTP testing tools
==================
-   [http://www-uxsup.csx.cam.ac.uk/\~fanf2/hermes/src/smtpc](http://www-uxsup.csx.cam.ac.uk/~fanf2/hermes/src/smtpc)/
    - written in C, supports STARTTLS, TLS on connect, AUTHs PLAIN and
    LOGIN, and PIPELINING. Relies on libraries usually installed on most
    modern operating environments, fulfilling the tool's primary goal of
    being able to be run on many systems "without requiring half of
    CPAN."
-   [http://www.jetmore.org/john/code/swaks](http://www.jetmore.org/john/code/swaks)/
    - written in perl. Basic functionality (sending a plain SMTP
    message) works with a standard perl install. Features include AUTHs
    PLAIN, LOGIN, CRAM-MD5, DIGEST-MD5, CRAM-SHA1, and SPA/MSN/NTLM;
    PIPELINING; DATA modifications including default data, default
    headers with custom body, and attaching files using MIME; ability to
    bind to a specific local interface for outgoing mail, ability to
    quit following specific parts of the SMTP transaction; STARTTLS and
    TLS on connect; option show timing delays on portions of
    transaction; ability to speak SMTP to a UNIX domain socket and a
    pipe (subprocess) in addition to internet domain sockets.
-   telnet - telnet to port 25 and start experimenting.
-   openssl - if you want to test a server at a fine level, as you would
    with telnet, but want to use TLS, try the openssl client:
    `openssl s_client -connect SERVER:PORT -starttls smtp`. Note the
    `-starttls` option is not supported in all version of the tool

SMTP Benchmarking
=================
-   [Postal](http://www.coker.com.au/postal/)
-   [SLAMD Distributed Load Generation Engine](http://www.slamd.com/)
-   [smtp-source (an smtp/lmtp message
    generator)](http://www.postfix.org/smtp-source.1.html) and
    [smtp-sink (a message
    dump)](http://www.postfix.org/smtp-sink.1.html) from Wietse Venema
    (see
    [http://www.postfix.org/TUNING\_README.html](http://www.postfix.org/TUNING_README.html))
