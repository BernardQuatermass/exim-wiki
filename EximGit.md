Exim Development Using Git
==========================

The definitive exim git tree can be found at
`git://git.exim.org/exim.git` with a web view available at
[http://git.exim.org/exim.git](http://git.exim.org/exim.git)

The main developers may push into this tree using their ssh access to
the development machine - the appropriate path is
`ssh://git.exim.org/home/git/exim.git` - the developer will need to be a
member of the `eximdev` group.

Repository Scope
----------------

The single development repository contains:-
-   The exim source including bundled utilities
-   The exim documentation source
-   The test suite
-   Scripts required as part of the release process

The web site and other ancillary data is not contained in the main
repository, but will normally be in other repositories under
[http://git.exim.org](http://git.exim.org)/

Enforcement and Checking Hooks
------------------------------

These hooks have not been implemented at this point, however it is
intended that the following policies will be enforced on pushes to the
repository - and we will also have an appropriate script so this can be
added to your local repositories.
-   No tabs (only spaces) other than where necessary (ie `Makefiles` )
-   No trailing spaces ([local fix you can use](TrailingSpaces))
-   No version tags from other VCS systems - ie `$Id$` or `$Cambridge$`

A hook which triggers on push to the main repo will also parse
[BugZilla](BugZilla) related state commands in commit comments.

Other Repositories
------------------

Those with access to the development system can push repositories into
the public\_git subdirectory of their home directory - these directories
will become visible on [http://git.exim.org](http://git.exim.org)/ after
a short interval, and may be accessed by others.

Those without access to the development system can use alternative git
hosting solutions (such as [github](http://github.com/) or
[Indefero](http://indefero.net/)) or their own hosting.

Github
------

There is also a repository at github in the [Exim
Organisation](https://github.com/Exim) - the repository is at
[https://github.com/Exim/exim](https://github.com/Exim/exim)

At present the canonical repository is on `git.exim.org` -
synchronisation with the github repo is a manual process. We will refine
the github integration as we get time.

Development Process
-------------------
-   Development branches are kept local and not pushed into the main
    repository, however they may be pushed into publicly available
    repositories for others to inspect
-   Those with commit access to the main repository may push directly
    onto the master branch
-   Others will need to make their changes visible to one of the
    committers and convince them to merge and push their changes. It may
    be appropriate to use a hosted git environment such as
    [github](http://github.com/) or [Indefero](http://indefero.net/) to
    make changes available to others, although requests on the exim-dev
    mailing list and/or [BugZilla](BugZilla) entries can be used to
    make developers aware of changes.
-   Reviewing changes before pushing to the main repository is very very
    strongly encouraged
-   Changes should include relevant documentation changes, and it is
    strongly suggested that code changes are checked using the test
    suite.

Technical Setup
---------------

Others may disagree on this - this is my suggested setup as someone who
has full commit access....

1.  Initially set your repository up using
    `git clone git://git.exim.org/exim.git`

2.  Ensure that your name and email address are set correctly
    (especially if the exim development email address you use is
    different to your default one - use `git config` command with keys
    `user.name` and `user.email`

3.  Ensure that the development machine has a `public_git` subdirectory
    of your home directory. Create an empty git repository within that
    directory - `cd ~/public_git; git init --bare myrepo.git`

4.  Set a new remote pointing to a new repo into your `public_git`
    subdirectory - ie
    `git add mydef ssh://git.exim.org/home/nm4/public_git/myrepo.git`

5.  Set up a second remote pointing to the main repository - ie
    `git add mainline ssh://git.exim.org/home/git/exim.git`

This allows you to pull easily from the mainline using a `git pull`
command. You can push either to your own visible respository, or to the
main repository as appropriate.

Sample Workflows
----------------

There are always various ways to use git with regard to workflow, but
[here are examples](SampleWorkFlow) of common tasks.
