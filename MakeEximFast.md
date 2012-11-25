The original article which spawned this Wiki entry is
[here](http://wiki.junkemailfilter.com/index.php/How_to_make_Exim_run_a_lot_Faster).

Spool to RAM Disk
=================

In some comparisons Exim is rated as running slower than other email
systems. One way of speeding up Exim is to spool to ram disk; however,
the major drawback of doing this is that power loss or other major
system failure can cause messages to be lost (unless the RAM disk is
battery backed). If that trade-off is acceptable to you, read on.

Introduction
------------

The biggest performance bottleneck in Exim is the message spool. Keeping
the message spool in ram makes Exim faster. But you have to do a lot
more than just create a ram disk since ram is limited and it loses what
is stored if the server is shut down. So beside just creating a ram disk
there are a number of other things you have to deal with to prevent
email loss and overflowing your memory.

Overview
--------

To get really fast performance you'll need to use several servers. The
main Exim server will run Exim and very little else. Email comes in, is
quickly processed, and forwarded to a destination server. Exim has a
feature where you can specify a "fallback\_host", so if the delivery
fails then it will try a different host (here called "retryhost").
Example router:

    process_and_forward_outscan:
      driver = dnslookup
      transport = outscan_smtp
    .ifndef FALLBACKHOST
      fallback_hosts = retryhost.example.com
    .endif 
      no_more

With this configuration the main Exim server makes one and only one try
to deliver the email. If that try fails then the message is transferred
to the retry server. The retry server does NOT spool to ram disk and it
will retry delivery for several days until the message is either
delivered or times out. This takes the load off of the main Exim server
and reduces the amount of messages in the queue to a minimum, keeping
the main server fast.

Preserving the RAM disk through a Reboot
----------------------------------------

Sometimes a server has to be shut down for servicing and you don't want
to lose the email in the ram disk spool. Here's a simple (Red Hat
Linux-flavoured) script, "exim-save", that I install as a service that
backs up the queue to hard disk and restores it upon reboot.

    #
    # exim-save    This shell script takes care of starting and stopping exim
    #
    # chkconfig: 2345 79 31
    # description: Exim Save Data

    # Source function library.
    . /etc/init.d/functions

    [ -f /usr/sbin/exim ] || exit 0

    start() {
            touch /var/lock/subsys/exim-save
            if [ -d /var/spool/exim-backup ]
            then
               cp -a /var/spool/exim-backup/* /var/spool/exim/
               rm -Rf /var/spool/exim-backup
            fi
    }

    stop() {
            rm -f /var/lock/subsys/exim-save
            if ! [ -d /var/spool/exim-backup ]
            then
               rm -Rf /var/spool/exim/db
               rm -Rf /var/spool/exim/scan
               rm /var/spool/exim/*.pid
               cp -a /var/spool/exim /var/spool/exim-backup
               rm -Rf /var/spool/exim/input
            fi
    }

    restart() {
            stop
            start
    }

    # See how we were called.
    case "$1" in
      start)
            start
            ;;
      stop)
            stop
            ;;
      restart)
            restart
            ;;
      *)
            echo $"Usage: $0 {start|stop|restart}"
            exit 1
    esac

    exit $RETVAL

I install it in the /etc/init.d directory as a service and activate it
by running:

    chkconfig exim-save on

Thus when you shut down the server it saves the queue and restores it
upon reboot.

Drawbacks
---------

Using this method has two significant drawbacks. First, if the server
crashes or loses power or is shut down in some other unclean manner
**you will lose the email in the queue**. So only use this method if
this risk is acceptable to you.

The second issue is that if something happens due to a misconfiguration,
the retry server goes offline, or some other unusual circumstance you
haven't though of, email could accumulate in the spool and fill up the
ram disk. The first defense to this is to have a lot of ram. Memory is
cheap these days. (Though having a larger ram disk spool also means
that, if the system fails, you now have the potential to lose even more
mail: see above).

If your ram drive fills then Exim will respond to incoming email with a
4xx error, which should tell incoming servers to try a higher-numbered
MX record. (Qmail servers generally get this wrong other email servers
are generally OK.) So in addition to a retry server you want a backup MX
server. That way if the main server is down or full then the backup
server (the one not using a RAM disk) will pick up the load.

Other Servers
-------------

For a high performance system you want to split up the load and use
other servers for other operations. Here we have outlined using a main
Exim server for the bulk processing of email at high speed, and using a
retry server to assist in the delivery if the first attempt fails. We
also specified a backup MX server to get your email if there is a
problem with the main server (there are free backup MX services out
there if you want to save on servers).

If you are running [Spam Assassin](http://spamassassin.org), you might
want to run that on a separate dedicated server, or in some cases
several separate dedicated servers. I also have a dedicated DNS server
just to do lookups and cache the results. I would also recommend having
a separate server where incoming email is stored, after spam filtering,
that runs your IMAP, POP, and Webmail services.
