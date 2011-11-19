# Using Exim BugZilla

The Exim BugZilla front page can be found at: http://bugs.exim.org/

There are some URL shortcuts:-

* http://bugs.exim.org/123 -- to go to bug 123
* http://bugs.exim.org/patches -- to see all bugs with patches attached
* http://bugs.exim.org/votes -- to see all bugs with at least one vote
* Email to 123@bugs.exim.org is appended to (pre-existing) bug 123. It's still not possible to add attachments to bugs by mail.

Wishlist items are filed as bugs with severity set to wishlist.

You do need to set yourself up an account within BugZilla before you can create or change a bug report (including by email). You can view reports without requiring an account.

Bug reports and changes are generally copied to the exim-dev [[mailing list|Exim Mailing Lists]].

(Our bug tracking system is shared with PCRE).

## Categories In BugZilla

We have 2 products:

* *Exim* -- the main package
* *Infrastructure* - support services such as the website, the mailing lists, bugzilla etc

### Infrastructure Components

* Sesame
* Web
* FTP
* Mailing lists
* Mirrors

Please can all requests for alterations or whatever related to infrastructure be logged as a BugZilla issue -- our volunteer "staff" appreciate your assistance in not overtaxing our memories.

### Exim Components

* Documentation
* Test harness
* Release process
* Packaging (ie support for RPMs etc)
* Lookups
* Mail Receipt
* Queues
* ACLs
* Routing
* Transports
* SMTP Authentication
* TLS (Encryption)
* Filters - Exim
* Filters - Sieve
* Content Scanning
* Address Rewriting
* Logging
* Networking
* Utilities - Monitor
* Utilities - Eximstats
* Utilities - Exigrep
* Utilities - Exipick
* Utilities - db
* Utilities - other
* Experimental
* Unfiled (Entries created by email come here, and we recommend it if you are unsure of a more precise choice).

## Closing bugs via Git commits

People with Git master repository commit access can automatically close (or more accurately, resolve as fixed) bugs by listing the bugs in the commit log entry using a special format:

* `fixes bug 123`
* `closes bug 123`
* `bug 123`

In addition to closing the bug(s) and adding the log entry as a comment, a list of the files committed will be added, showing their previous and new version numbers, and the number of lines added and removed, with links to ViewVC.

Keywords "`closes`" and "`fixes`" cause a status change to the bug, otherwise the bug is left in the same state.
Capitalization is insignificant.
