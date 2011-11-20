# Exim Release Process

An aide memoir etc - currently just trying to ensure we have all of this stuff captured...

## Each Feature/Bug Fix

* Ideally work with complete git working directory -- including the `src` and `doc` subdirectories -- to ensure a single checkin includes both the code and the documentation changes - even better if test suite changes can also be integrated.
* If appropriate update `NewStuff` (in the `exim-doc/doc-txt` subdirectory).
* Always update `ChangeLog` after each change (also in the `exim-doc/doc-txt` subdirectory).
* Put the [[BugZilla]] reference into `ChangeLog`
* Use the [[BugZilla]] reference in the checkin message (updates bugzilla with the checkin details) - see [[BugZilla]] for details

## Start of Development Cycle

* Update documentation with version number of next release
* Remove all changebars from documentation _except the sample_ (around `SECID1`) - basically strip all `.new` and `.wen` tags and remove `&new()` enclosures

## Release Steps

* Ensure test suite runs
* Check version number in source and version number in documentation match new release version
* Update the documentation date (2 instances near version number) in both spec and filter doc sources, update copyright year if needed.
* Check that the `NewStuff` and `ChangeLog` and `doc-txt/OptionLists.txt` files are up-to-date
* Tag git for new release - tag format is `exim` hyphen ''version number with underscores'' - ie `exim-4_77`
* Ensure git tree (with tags) is pushed to central repo
* Build documentation and packages:-
    * ensure `exim-website` and `exim` git repos checked out within same directory
    * `cd exim`
    * `release-process/scripts/mk_exim_release.pl 4.77` - use appropriate version number
    * files produced into `exim-packaging-4.77/pkgs` directory
    * also writes website documentation sources into `exim-website/docbook/4.77/` - for a full release this should be git add/commit
* ideally have limited final test before full distribution
* sign tarballs - script in `release-process/scripts/sign_exim_packages.sh`
* write announcement including changes and SHA
    * to date, SHA1 and SHA256 checksums; we can consider changing this
    * mail should be signed by a key with an `@exim.org` uid, that has been signed by the other Exim Maintainers.
    * mail *must* be sent PGP/inline, as PGP/MIME will be rejected by the mailing-list software.
    * note that tahini requires authentication for any mail sent with a sender in the @exim.org domain
* pimp the release or RC on social media
    * _Especially_ for Release Candidates: we don't want to spam the announce list with these, but there are many folks who don't follow `exim-users` because of the volume but who are interested in trying out Release Candidates to help out
    * Tweet it. Try using an `#Exim` hashtag.
    * Try the [[Google+ Exim|https://plus.google.com/b/101257968735428844827/]] page -- hopefully Google have shared admin rights by the time someone other than Phil does a release
* put tarballs and signatures up for distribution - in `/home/services/ftp/pub/exim/exim4/`
* move last release files in the `old` subdirectory.
* update website - now done automatically (hourly) if you have git add/commit/push the doc sources above
 * docs website - needs links to new docs - in `/srv/www/vhosts/docs.exim.org/`
   * symlink to html docs as per other versions
   * update current symlink too
 * !ChangeLog/NewStuff distro on ftp site - in `/home/services/ftp/pub/exim/ChangeLogs/`
* update wiki - at least the ObtainingExim page (link others here too)
* Update [[Wikipedia's Exim entry's|http://en.wikipedia.org/wiki/Exim]] version information, because we're nice like that
* add released version to list of [[BugZilla]] versions
* add next expected version to [[BugZilla]] milestones, and make that default

## RC Steps

* We are probably not using EximVersionRCVerificationTemplate any more: the experiment never gained traction
* Basically same as for release, except no update of website and ChangeLog/NewStuff distro on ftp site
* Files should be placed in `test` subdirectory rather than in main distribution directory

## Things to do

* Clean up the release package scripting and make it generally usable
* Script the above steps from _put tarballs_ to _ChangeLog_ - the file moving part can all be automated.
* Can we script the old change bar removal and new change bar generation in the documentation?
* Sort out filesystem permissions so that anyone in group `eximdev` can make updates?  _This should work now._
* Sort out website to auto-update from git -- _This should work now_.
