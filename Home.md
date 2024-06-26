Welcome!
========
Welcome to the Exim Wiki. This wiki covers extra information not in the
official documentation. It allows users of Exim to supplement the
documentation by adding examples and interfaces to other software and other
how to information.  For finding resources, try [[What Lives Where On The Web]]
which describes where the website is, why there are currently two wikis,
where to find mailing-lists, source code, bug-tracking, etc.


On this wiki ...
================
-   [[Frequently asked questions|FAQ]] (Location of suggestions, tricks and shortcuts)
-   Exim [[Introduction and feature list|EximIntroduction]]
-   How to [[download and install|ObtainingExim]] Exim
-   [[What's new|ChangeLog]] and change logs.
-   [[Configuring Exim|ConfiguringExim]]
    -   [[HowTos|HowTo]] for all sorts of situations
    -   Debian users should check the [[Debian-specific documentation|DebianExim4]]
-   [[Exim Security|EximSecurity]]
-   [[DNSSEC|DNSSEC]]: DANE, DNSSEC, Exim, Resolvers, exim.org and so forth
-   [[Testing an Exim installation|TestingExim]]
-   [[Exim Development|EximDevelopment]]
-   [[Release Policy|EximReleasePolicy]]
-   [[Upgrading from Exim 3|Exim3Status]]
-   [[Commercial Support for Exim|Commercial]]

See also
========
-   [[Exim Home|http://www.exim.org/]]
-   [[Exim Documentation|http://www.exim.org/docs.html]]
-   [[Download Exim|http://www.exim.org/mirrors.html]]
-   [[Exim Mailing Lists|EximMailingLists]]
    -   the lists have [searchable archives](http://lists.exim.org/)
    -   before posting, be sure to read the [[Mailing List Policies|MailingListPolicies]]
        and [[Mailing List Etiquette|MailingListEtiquette]] - be nice on the support
        lists!
-   IRC channel on irc.libera.chat (SSL, port 6697) #exim

* * * * *

Wiki Conversion
===============
This wiki was converted from the old one hosted on exim.org.  There may be
some issues with the conversion - please fix up any formatting or linking problems you discover.

Participate - Learning about Wikis
==================================
You too can be part of the documentation process. Do you have a trick
that you would like to contribute? You can edit these pages and create
new pages as long as you have a [GitHub](http://github.com/) login. This allows you to share your tricks with everyone else just
like they shared their tricks with you.

Some tricks for Exim
==================================
Removing Bad Mail

    # remove mail from nobody
    exiqgrep -i -f nobody | xargs exim -Mrm

    # remove mails older than 3 days
    exiqgrep -i -o 259200 | xargs exim -Mrm

    # remove mail with weird characters (spam)
    exiqgrep -i -f “^<>$” | xargs exim -Mrm

    # delete mails from a particular domain
    exiqgrep -i -f domain.com | xargs exim -Mrm

    # delete mails to a particular domain
    exiqgrep -i -r domain.com | xargs exim -Mrm

    # flush (purge) the entire Mail queue
    exiqgrep -i -f | xargs exim -Mrm
    exim -bp | exiqgrep -i | xargs exim -Mrm

Run Mail queue

    runq -qqff

Who is having large number of emails?

    exim -bp | exiqsumm

To check message header

    exim -Mvh messageid

To check message content

    exim -Mvb messageid

Exim Pros

Many plugins available.

Exim Cons

Cryptic templates.