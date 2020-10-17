
This is a very old list that hasn't been updated for some time. Some
items may no longer make sense.
-   Convert os.c into a directory of separate functions, with the macro
    switches defined elsewhere. Then make it into a library.
-   Use a pointer to an address structure for expanding \$domain etc, to
    make it easier to save/restore this collection of variables. But
    note that \$domain and \$local\_part aren't always in an address.
    Check out when these are set. Note also the new \$address\_data
    possibility.
-   Spool\_in and spool\_out - speed up by using a table?
-   Find a more compact way of encoding the options interpretation, and
    also of checking for incompatible options.
-   Find a more compact way of passing an open SMTP channel without
    having to use options. What about the TLS state information? Could
    use a pipe to pass more data.
-   Some people have suggested separately loadable modules. But do all
    systems have them? Is this going too far for just a few specialist
    users? In particular, people want to be able to replace the logging
    with his own code. Can we arrange this without going for the
    separately loaded modules? (cf the incoming checking code.)
-   SIGHUP the daemon - don't close the sockets; instead pass a list of
    them somewhere for the new daemon to pick up. Iff started by exim or
    root, of course. There might be quite a long list of them - argv
    might not be the best idea. If this were done, then a non-setuid
    exim daemon could be SIGHUPped.
-   Parallel deliveries. Currently dead host information doesn't get
    propagated between them very well. Is there anyway this could be
    improved?
-   In some environments the use of gethostbyname() seems to cause
    problems. Check out its use, and see if having a "force DNS" option
    could be helpful. But people would have to know what they were
    doing.
-   accept\_max\_per\_host is a slow, linear search. If
    smtp\_accept\_max is large, this can be very slow. Is there some way
    we can speed this up? Some kind of index based on the IP address?
    Remember, this is in the daemon, so it must not consume store.
-   Look at code in pidentd for running Exim in wait mode from inetd and
    re-using the socket. This would allow it to run more tidily as
    non-root.
-   Think up some scheme for checking for orphan files in the spool
    directories. Perhaps -bp should always do it, but it would be nice
    to have it done automatically now and again. Maybe we just leave
    this for a cron job? Perhaps a new -bx, e.g. -bpck or something.
    Better, perhaps, is a separate Perl script. Orphan = a file that is
    over 24h old (or 1s when test harness) and either doesn't end in -D
    or -H, or is a -D without a matching -H (or vice versa).
-   Swamping with delays in checking for reserved hosts - the
    connections are counted in the total allowed. Can we improve on this
    somehow? Maybe shared memory can help here. Think about different
    states and different limits.
-   Lists that must use colons: can we check for other cases, and fix
    them up before passing them on? Is it worth it?
-   Process receiving error message fails - can we get more info, such
    as the stdout/stderr?
-   dbmbuild - if renaming one of .dir/.pag fails, reinstate the other.
    Should there be a lock?
-   Write a script to check for format problems in the source - formats
    that are not fixed strings and are built from outside code.
-   freeze\_tell: Don't if message is a bounce message containing From:
    the local machine - even if the bounce comes from another host.
-   Add additional data into the "frozen" log message at end of
    delivery, e.g. if remote host was the local host or whatever. At
    least some cross referencing.
-   Someone had a requirement to install the Exim binary in a different
    place to the utilities, etc. Also, for different builds on the same
    host and architecture.
-   Include (part of?) the ppid in the message id? Or a random number?
-   Re-implement the code in readconf that reads error names for retry
    rules. Make it use a table for most of the error types. Then see if
    we can usefully add any additional error types.
-   Should there be "exim -bP acls" etc? It would mean inventing some
    kind of "hide" facility within the ACL syntax.
-   VERY LONG TERM: the message ID is too small now, with the recent
    changes to cram in the sub-second time. It would be a big project to
    extend it; Exim would have to recognize both forms for a while, and
    become stable, before generating the new form. Probably a runtime
    switch needed. The new form [reparacion de camaras frigorificas madrid](http://madridindustriales.es/camaras-frigorificas) needs at least microsecond time (or
    more?) and should probably cope with 64-bit pids, just to be safe
    (or leave expansion space that could be used for that). It should
    also be able to hold big enough things in base 36.
-   Take a look at libexec.
-   Sort out the stcncpy/strlcpy issue once and for all. Time things.
-   OpenSSL - can we pass an opened file for certificate? Repeatedly?
    Otherwise pre-initialize while root? There do seem to be functions
    for manipulating certificates, but documentation is scarce. Can we
    just load the certificate in as root in the server?
-   Consider using poll() to close unwanted fds. Is this efficient?
    Perhaps it doesn't matter for the daemon.
-   On a 64-bit system there are some cast warnings for casting
    addresses to ints. Either we must find a way of not warning, or
    we'll have to use unions to get round it.
-   Run splint on the source?
-   It has been suggested that rejection because not authenticated
    should use 530 and not 550, but this is hard to detect because of
    the way ACLs work.
-   When there is a sender verify failure, \$acl\_verify\_message
    contains "sender verify failed", not the details of the failure.
    Should this change? Some of the waffly details are added later in
    smtp\_in.c. In the ACL that text is in
    sender\_verified\_failed-\>user\_message.
-   An empty string for a transport filter currently causes an error.
    Should it ignore? Tricky because of special expansion rules for
    commands.
-   GFDL for documentation (www.gnu.org/licenses/fdl.html)? The 1.2
    version of this licence is still quite new (it is dated November
    2002) so I think waiting for reaction/opinion is the best plan.
    There are Debian concerns about this licence. At very least, no
    Invariant Sections and no Cover Texts can be used.
-   Allow \$recipients in other places. Not clear what this value should
    be if, say, the system filter has overridden them. Default would be
    envelope recipients, as now.
-   Error in transport filter. See test 407. All 3 processes see errors
    - which one should be noticed? Transport\_filter\_temp\_errors may
    be needed.
-   Think about 5xx thresholds -- too many and you're out. What about
    4xx?
-   autoreply - should it call /usr/sbin/sendmail? Provide a way of not
    passing -C and -D when creating the message ('cause it won't be
    privileged).
-   Strings containing 000 - anything we can do?
-   Make set\_process\_info buffer bigger, and put the overflowed
    message at the end, thereby leaving the start.
