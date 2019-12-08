
Exim Development
================

Source Access
-------------

Exim source is no longer kept within CVS, and has been transitioned to
Git. The CVS section of this page has been deleted.

GIT
---

Exim has a git repository at:
-   git://git.exim.org/exim.git

There is a web interface to this, giving change and source visibility
at:
-   [https://git.exim.org/exim.git](https://git.exim.org/exim.git)

Exim developers may push trees into their own workspace on hummus -
these can be seen with the web interface at
-   [https://git.exim.org](https://git.exim.org)/

Individual developer repos will start with `users/`*username*/

There is a mirror at
[https://github.com/Exim/exim](https://github.com/Exim/exim) however
this may sometimes be out of sync with the master until we refine the
processes.

Further information on using Git for Exim Development can be found in
[EximGit](EximGit)

Coding style [here](Exim-coding-style)

Bug Tracking
------------

There is a bugzilla instance at
[https://bugs.exim.org](https://bugs.exim.org)/ - see
[BugZilla](BugZilla)

Mailing List
------------

Development issues are normally discussed on the exim-dev
[EximMailingLists](EximMailingLists)

Build Farm
----------

If you want to support the developers in spotting regressions introduced during development,
especially on less-common platforms. please consider operating a
[buildfarm](https://buildfarm.exim.org/cgi-bin/show_status.pl) animal.

Exim Release Process
--------------------

See [EximRelease](EximRelease)

New Committers
--------------

The commit-bit is inflicted after nomination by an existing committer
and no objections raised.

See [EximNewCommitter](EximNewCommitter) for steps you might want to
follow.