Exim Release Process
====================

An aide memoir etc - currently just trying to ensure we have all of this
stuff captured...

We follow [EximReleasePolicy](EximReleasePolicy) for releases.

Except for the [Security Release Process](SecurityReleaseProcess).


Each Feature/Bug Fix
--------------------
-   Ideally work with complete git working directory -- including the
    `src` and `doc` subdirectories -- to ensure a single checkin
    includes both the code and the documentation changes - even better
    if test suite changes can also be integrated.
-   Update the main documentation in `exim-doc/doc-docbook/spec.xfpt`
-   Add regression testcases for bugfixes, feature testcase for features
-   If appropriate update `NewStuff` (in the `exim-doc/doc-txt`
    subdirectory).
-   Always update `ChangeLog` after each change (also in the
    `exim-doc/doc-txt` subdirectory).
-   Put the bugzilla reference into `ChangeLog`
-   Use the bugzilla reference in the checkin message (updates bugzilla
    with the checkin details) - see [BugZilla](BugZilla) for details

Start of Development Cycle
--------------------------
-   Update documentation with version number of next release
-   Remove all changebars from documentation *except the sample* (around
    `SECID1`) - basically strip all `.new` and `.wen` tags and remove
    `&new()` enclosures

Release Steps
-------------
-   Ensure test suite runs
-   Check version number in source and version number in documentation
    match new release version
-   Update the documentation date (2 instances near version number) in
    both spec and filter doc sources, update copyright year in
    src/src/globals.c if needed.
-   Check that the `NewStuff` and `ChangeLog` and
    `doc-txt/OptionLists.txt` files are up-to-date
-   Check if test/configure needs commit
-   For sanity doing RCs, set shell variables eg. "maj=79 rc=4"
-   Tag git for new release - tag format is `exim` hyphen *version
    number with underscores* - eg `exim-4_79`. You must also have git
    sign the tag with your exim PGP id - ie `git tag -u you@exim.org` for
    the tarball to be built correctly.
    + For an RC: `git tag -s -m "Exim 4.${maj} RC${rc}" exim-4_${maj}_RC${rc}`
-   Ensure git tree (with tags) is pushed to central repo: `git push --follow-tags`
-   Build documentation and packages:-
    -   ensure `exim-website` and `exim` git repos checked out within
        same directory; if not first RC for this release, clean the previous website docbook files out
    -   `cd exim`
    -   `release-process/scripts/mk_exim_release 4.${maj}_RC${rc}` - use
        appropriate version number
    -   files produced into `exim-packaging-4.${maj}_RC${rc}/pkgs` directory
    -   also writes website documentation sources into
        `exim-website/docbook/4.${maj}/` - for a full release this should be
        git add/commit
-   Ideally have limited final test before full distribution
-   Sign the tarballs: `release-process/scripts/sign_exim_packages`
    (If git configuration `user.signingkey` does not identify the PGP key to
    use, then you must specify `EXIM_KEY` in environ).
-   put tarballs and signatures up for distribution
    -   for RCs in `/srv/ftp/pub/exim/exim4/test/`
    -   for full release
        - Move last release files in the `old` subdirectory
        - new files to `/srv/ftp/pub/exim/exim4/`
        - also unpack ChangeLog and NewStuff to `/srv/ftp/pub/exim/exim4/` and make `.gz` versions **This needs automating**
        -   unpack PDF documentation from distro tarball into `/srv/www/vhosts/www.exim.org`; the HTML docs and the exim-pdf-current link is done during (auto) update of the website
-   Write announcement including changes and cryptographic checksums
    -   SHA256 checksums only for now; 4.80 was the last to use both
        SHA1 and SHA256. We'll add SHA-3 when it's available.
        `./release-process/scripts/stats_for_email`
    -   mail should be signed by a key with an @exim.org uid, that has
        been signed by the other Exim Maintainers.
    -   mail **must** be sent PGP/inline, as PGP/MIME will be rejected
        by the mailing-list software (is this still true?).
    -   note that hummus requires authentication for any mail sent with
        a sender in the @exim.org domain
-   Pimp the release or RC on social media
    -   *Especially* for Release Candidates: we don't want to spam the
        announce list with these, but there are many folks who don't
        follow `exim-users` because of the volume but who are interested
        in trying out Release Candidates to help out
    -   Tweet it. Try using an `#Exim` hashtag.
    -   Try the [Google+ Exim](https://plus.google.com/b/101257968735428844827/) page --
        hopefully Google have shared admin rights by the time someone
        other than Phil does a release
-   ChangeLog/NewStuff distro on ftp site - in
    `/srv/ftp/pub/exim/exim4/`
    -   `.gz` files too, but not `.bz2`; `gzip -9k`
-   _Remaining steps only for full releases_
    -   Update wiki - at least the [ObtainingExim](ObtainingExim) page
        (link others here too)
    -   Update [Wikipedia](http://en.wikipedia.org/wiki/Exim) version
        information, because we're nice like that
    -   add released version to list of bugzilla versions (Edit:Products/Exim/Edit_Versions/Add)
    -   add next expected version to bugzilla milestones (Edit:Products/Exim/Edit_Milestones/Add),
    and make that default (button on Edit:Products/Exim page)
    -   update the Topic on the #exim IRC channel on freenode
    -   if a Security release, then update [[EximSecurity]] with details.


RC Steps
--------
-   This should be inline above
-   Basically same as for release, except no update of website and
    ChangeLog/NewStuff distro on ftp site
-   Tag has form exim-4_79_RC3
-   Files should be placed in `test` subdirectory rather than in main
    distribution directory


Things to do
------------
-   Clean up the release package scripting and make it generally usable
-   Script the above steps from *put tarballs* to *ChangeLog* - the file
    moving part can all be automated.
-   Can we script the old change bar removal and new change bar
    generation in the documentation?
-   Sort out website to auto-update from git (this is done via nm4's cronjob)
