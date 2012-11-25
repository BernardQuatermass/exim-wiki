
Exim 5 Discussion
=================

Please add proposed features for Exim 5 to this page. If the description
(or discussion) is substantial then make the item a subpage - ie
`Exim5/MyFeature` and link to it from here. Links to mailing list
discussion are also appropriate.

Major Architectural Changes
---------------------------
-   Storage revamp - use a storage API allowing different storage
    systems to be attached
    -   SQL Email Storage and expanded SQL support
-   Configuration revamp - this could cover all sorts of things...
-   Simplification of the string expansion language
-   Pluggable lookup API
-   Pluggable content scanner API
    -   [RuthIvimey](RuthIvimey) asks: forgive me if I've missed an
        existing ability, but I'd like to be able to do ACL-time content
        scanning using several different programs on the same message.
-   Pluggable router API
-   Pluggable transport API
-   Reduce the number of different concepts
    -   Eliminate the system filter
    -   Have local\_scan modules explicitly called from ACL
    -   Make routers more like ACLs in that conditions are checked in
        the order they appear and can appear multiple times
-   Improve header handling
    -   In what way? To fix what problems?
    -   MIME-encoded headers are confusing
-   The aim for Exim \#5 ought to be to modularise significantly, so
    that several different designs are possible within the same overall
    architecture. That's already the way things have gone with spam
    filtering schemes.
-   [RichardClayton](RichardClayton) is surprised that no-one has
    mentioned queues yet. Quite clearly a key design aim for \#5 should
    be to revisit the assumption that the majority of email can be
    quickly shuffled off to somewhere else. There is now a page about
    this [here](MultipleQueues).
-   Other major subsystems should become modules so that multiple
    parallel implementations can replace the existing design. Maildrop
    style is one (where the code for several schemes is already
    present), what else? The big plus is that Exim is mature enough to
    see what the grand overall architecture should be : building from
    scratch something with a selectable modules style of design can lead
    to significant inefficiency as one goes through "we'll give them a
    choice here" interfaces to no practical purpose.
-   The code for callouts is entirely separate from the smtp transport.
    This causes a number of problems, including the lack of availability
    of AUTH and LMTP for callouts. Bugzilla \#321 and \#345 mention
    this. A better design would be to redesign the transport so that it
    can function either as a message deliverer or as a callout
    mechanism.
-   Exim's handling of resent-headers should be revisited. I think there
    are now more guidelines about as to how they can be grouped and how
    multiple sets of resent-headers should be handled. fanf suggests
    sections 6-8 of
    [http://www-uxsup.csx.cam.ac.uk/\~fanf2/hermes/doc/qsmtp/draft-fanf-smtp-rcpthdr.html](http://www-uxsup.csx.cam.ac.uk/~fanf2/hermes/doc/qsmtp/draft-fanf-smtp-rcpthdr.html)
-   with an python API, exim could be more powerfull and flexible,
    possibly we can use somethink like this
    [http://freshmeat.net/projects/exim-python](http://freshmeat.net/projects/exim-python)/

Other Aspects
-------------
-   [Configuration file improvements](ConfigurationImprovements)
-   The ability to pipe mail into some process (exists today), *and use
    the output as the new mail* (does not exist yet). The current way of
    having to call /usr/sbin/sendmail again to feed a modified mail back
    into the mail system after, say, getting it through spam- or
    virusscanning is a kludge, at best.
    -   [RuthIvimey](RuthIvimey): seconded... and to be able to do so
        from an (appropriate) ACL as well as a router?
-   [Possible use of "autoconf"](autoconf)
-   Make it possible to link Eximon with something other than the Athena
    widgets -- or indeed, rewrite the whole thing.
-   In the same vein, add a GUI configuration tool that can create at
    least modestly complex configurations. Perhaps integrated into the
    reworked eximon? I always liked the interface of "mailtraq",
    although that was a while ago |:)|
-   [Philip Hazel's old ''future ideas'' list](oldPHlist)
-   [Ideas for string expansion changes](expansion)
-   XML file lookup, which would allow to process and fetch data from a
    XML file. I don't see how XML hierarchy would make benefit for us,
    but surely we can search and extract data from tags of a given type.
