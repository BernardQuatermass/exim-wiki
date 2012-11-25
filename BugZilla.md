Using Exim Bugzilla
===================

The Exim Bugzilla front page can be found at
[http://bugs.exim.org](http://bugs.exim.org)/

There are some URL shortcuts:-
-   `http://bugs.exim.org/`123 - to go to bug *123*
-   [http://bugs.exim.org/patches](http://bugs.exim.org/patches) - to
    see all bugs with patches attached
-   [http://bugs.exim.org/votes](http://bugs.exim.org/votes) - to see
    all bugs with at least one vote

Email to *123*`@bugs.exim.org` is appended to (pre-existing) bug *123*.
It's still not possible to add attachments to bugs by mail.

Wishlist items are filed as bugs with severity set to *wishlist*.

You do need to set yourself up an account within Bugzilla before you can
create or change a bug report (including by email). You can view reports
without requiring an account.

Bug reports and changes are generally copied to the exim-dev
[EximMailingLists](EximMailingLists).

Categories In Bugzilla
----------------------

We have 2 *products*:-
-   Exim - the main package
-   Infrastructure - support stuff like the website, the mailing lists,
    bugzilla etc

### Infrastructure Components
-   Sesame
-   Web
-   Ftp
-   Mailing lists
-   Mirrors

Please can all requests for alterations or whatever related to
infrastructure be logged as a Bugzilla issue - otherwise I tend to
lose/forget stuff.

### Exim Components
-   Documentation
-   Test harness
-   Release process
-   Packaging (ie support for RPMs etc)
-   Lookups
-   Mail Receipt
-   Queues
-   ACLs
-   Routing
-   Transports
-   SMTP Authentication
-   TLS (Encryption)
-   Filters - Exim
-   Filters - Sieve
-   Content Scanning
-   Address Rewriting
-   Logging
-   Networking
-   Utilities - Monitor
-   Utilities - Eximstats
-   Utilities - Exigrep
-   Utilities - Exipick
-   Utilities - db
-   Utilities - other
-   Experimental
-   Unfiled (Email files into here as do people that are unsure)

* * * * *

Closing bugs via CVS commits
----------------------------

People with CVS commit access can automatically close (or more
accurately, resolve as fixed) bugs by listing the bugs in the commit log
entry using a special format:
-   fixes bug 123
-   closes bug 123
-   bug 123

In addition to closing the bug(s) and adding the log entry as a comment,
a list of the files committed will be added, showing their previous and
new version numbers, and the number of lines added and removed, with
links to ViewVC.
-   "closes" or "fixes" causes a status change to the bug, otherwise the
    bug is left in the same state
-   Capitalization is insignificant.
