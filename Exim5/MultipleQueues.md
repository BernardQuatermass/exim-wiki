Extending Exim to Handle Multiple Queues
========================================

There have been several requests for multiple queue support. This page
contains some notes about this.
-   An incoming message could be directed to an alternate queue by
    something like

        control queue=somename

    A problem with this is that it applies to all recipients because it
    affects the whole message. In some cases this may be what is wanted,
    but there is probably also a requirement to split a message into
    different queues according to its recipients.
-   Another possibility is to write a new transport that transports a
    message from one queue to another. That would be per-address and of
    course could handle several addresses in a batch if necessary. The
    downside of this approach is that the message would have to be
    copied, thus increasing disk usage if it ended up on several
    different queues.
-   There is no reason why both of the above could not be implemented as
    complementary approaches.
-   The implementation of other queues would be to put messages under
    `somename/input` instead of just `input` in the spool directory, so
    you might end up with (for example)
    `/var/spool/exim/nightdelivery/input`.
-   There would have to be a new command line option to tell a queue
    runner which queue to work on. Other command line options that look
    for specific messages would have to search all the queues, as
    happens now when the directory is split.
-   There may need to be options for the daemon so that it can start
    queue runners for different queues at different times.
    Alternatively, this could be left to the sysadmin to arrange, using
    cron or whatever.
-   A change of queue in effect changes the spool directory, but only
    for message-related operations. We don't want to change where the
    log is written, for example (if it's being written to the spool
    directory). A new variable with a name something like
    `$spool_queue_directory` might be needed.
-   When a message is received into a non-default queue, this should be
    logged somehow.

RuthIvimey\_ adds: Perhaps exim could be arranged as follows:
-   A given instance of Exim (identified by listening port, or
    explicitly for non-IP exims) reads all message Bodies into a single
    message store.
-   Processing during message input causes untagged messages to be
    tagged with one or more queue identifiers along with (perhaps a
    subset of) the Header information for the message. The queue
    identifiers should permit one id per recipient. It might be sensible
    to separate queue id from recipients in the future, but this seems
    best to start with.
-   The fact of a given message body having several queue ids does not
    mean that it all has to be copied; instead, the message store
    refcounts the queues (or, if you prefer, some other mechanism) so as
    to share bodies.
-   Transports and Routers can both limit their actions to a (sub)set of
    queues, and transports can cause a message to change queue.
-   It should probably be possible for one exim to tell another exim
    which queue to use for an incoming message, but this should be
    out-of-band (so as to stop malicious internet usage of this) and so
    not in the headers or using ESMTP commands. How then?
-   It should be possible for a queue to require its own storage of
    message bodies. I think the cleanest implementation would be for a
    transport to do this: message recipients tagged with Q1 are routed
    to a transport whose action is to change the queue tag *and* to copy
    the message body to a Q2-local message store. Once in Q2, it behaves
    normally as far as other actions are concerned (?because the queue
    info contains info about where the bodies are too?).
-   Normal message logging indicates the source queue (if exim was
    passed one from outside) on the message receipt line, and the final
    queue used for delivery of the recipient. If intermediate queues
    were used additional logging would have to be used to see it.
-   Queue names should probably be short strings.

Marc Perkel adds:
-   A first attempt queue that is different than a message to be
    retried. In some instances speed is important and the first attempt
    queue could be a ram disk and the retry queue could be a hard drive.
    This would make Exim lightning fast ut at the risk of losing some
    email in case of a sudden crash. Exim would transfer the first
    attempt queue to the retry queue on normal shutdown.
