## Environment

Exim is written in C, assuming a POSIX/ANSI-C environment and a single-threaded forking process model. In the lifetime of a handling a message, Exim will likely `exec()` itself. The model used is to cache lookups and talk to external daemons and datastores. Exim has good broad support for a variety of datastores, authenticators, SSL providers and such, plu we're always willing to accept contributions (GPL'd), subject to quality vetting.

Exim runs on a wide variety of platforms, including those where `/bin/sh` does not reliably provide a POSIX shell. At this point, we regard ANSI C89 as a base minimum, are not opposed to the use of C99 for sub-projects (but not the main binary), and we are increasingly likely to require those building binaries to take extra steps on non-POSIX platforms (such as adjusting $PATH).

A number of utilities are written in Perl; we have no current guidelines on minimum versions of interpreters to expect, nor do we require that contributed tools be written in shell or Perl.  We're happy to accept scripts written in, for instance, Python, and platform-specific languages for a "contrib" status.

## Source Access

We use _git_ for source code management.  The [master copy](http://git.exim.org/exim.git) and developer public trees are available at [git.exim.org](http://git.exim.org/):

* Checkout: git://git.exim.org/exim.git
* Web UI: http://git.exim.org/exim.git (for browsing)

Exim developers may push trees into their own workspace on tahini - these can be seen with the web interface at http://git.exim.org/

We are setting up GitHub as a public backup, so that in the event of failure of the master site, an existing site with established reputation as a &ldquo;_legitimate_&rdquo; copy of the Exim code will be available for people to trust.

Further information on using Git for Exim Development can be found in [[Exim Git]].

## Bug Tracking

There is an actively used bugzilla instance at http://bugs.exim.org/ -- see [[BugZilla]].

## Mailing List

Development issues are normally discussed on the `exim-dev` [mailing-list](http://www.exim.org/maillist.html). For tracking particular problems or feature requests, we do tend to prefer the use of [[BugZilla]].

## Release Process

We follow a documented process for releases, and at any given time at least two developers should be experienced in performing a release.  See [[Exim Release]] for the details of what we do.