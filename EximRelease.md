Exim Release Process
====================

An aide-memoire etc - currently just trying to ensure we have all of this
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
-   If a 4.next branch was running during the RC stages of the just-done release,
    merge it back to the mainline and drop it from the buildfarm

When starting run-up to a release
---------------------------------
-   Reset the 4.next branch to the current master checkin
-   Add 4.next to the buildfarm (exim-build-farm-server git tree; htdocs/branches_of_interest.txt).
    Check that krot (buildfarm server) is up to date
-   (ongoing) commits you want to record but not have in this release go to 4.next
    (for example, new features once you've declared feature-freeze for the release)

Release Steps
-------------
-   Checkout the "master" git branch
-   Ensure test suite runs
-   For sanity doing RCs, set shell variables eg. "maj=79 rc=4"
    + For full release, "maj=78 oldmaj=79"
-   For a full release:
    - Check version number in source and version number in documentation match new release version
    - Update the **copyyear** date (2 instances near version number) in doc/doc-docbook/spec.xfpt and doc/doc-docbook/filter.xfpt
    - Update the **version_copyright** string in src/src/globals.c if needed.
    - Check for modify dates on all source files, and update copyright year in the file header comment: `vi $(git log --name-status exim-4.${oldmaj}..master | awk '/^M/{print $2}' | grep -v '^test/' | sort -u)`
-   Check that the `NewStuff` and `ChangeLog` and `doc-txt/OptionLists.txt` files are up-to-date
-   Check if test/configure needs commit (run `autoreconf` in `test/`)
-   Tag git for new release - tag format is `exim` hyphen *version
    number with dots* - eg `exim-4.92`. You must also have git
    sign the tag with your exim PGP id - ie `git tag -u you@exim.org` for
    the tarball to be built correctly.
    + u/s for me; used `git tag -s -m "Exim 4.${maj}" exim-4.${maj}`
    + For an RC: `git tag -s -m "Exim 4.${maj} RC${rc}" exim-4.${maj}-RC${rc}`
-   Build documentation and packages:-
    -   ensure `exim-website` is checked out to a known location, ideally into the same directory where `exim` is located.
    -   if not first RC for this release, clean the previous website docbook files out: `rm -f ../exim-website/docbook/4.${maj}/*`
    -   `cd exim`
    -   `release-process/scripts/mk_exim_release 4.${maj}-RC${rc} /tmp/exim-pkgs` - use
        appropriate version number
    -   files produced into `/tmp/exim-pkgs` directory
    -   also writes website documentation sources into `exim-website/docbook/4.${maj}/` - for a full release this should be
        git add/commit: `git -C ../exim-website add docbook/4.${maj} && git -C ../exim-website commit -m "Add Exim 4,${maj}" docbook/4.${maj}`
-   Ideally have limited final test before full distribution
-   (should be already done, by mk_exim_release) Sign the tarballs: `release-process/scripts/sign_exim_packages /tmp/exim-pkgs`
    (If git configuration `user.signingkey` does not identify the PGP key to
    use, then you must specify `EXIM_KEY` in environ).
-   put tarballs and signatures up for distribution
    -   for RCs in `/srv/ftp/pub/exim/exim4/test/`
        - for the initial RC, clear that dir first
        - for subsequent ones, clear the '00' files first
    -   for full release
        - Move last release files in the `old` subdirectory
        - new files to `/srv/ftp/pub/exim/exim4/`
        - Unpack PDF documentation from distro tarball into the website area :- `cd /srv/www/vhosts/www.exim.org && tar xvf /srv/ftp/pub/exim/exim4/exim-pdf-4.${maj}.tar.gz`
        - Don't do the HTML docs and the exim-pdf-current link; done during (auto) update of the website
        - Unpack ChangeLog and NewStuff to `/srv/ftp/pub/exim/exim4/` and make `.gz` versions **This needs automating** :-
~~~
cd; f=/srv/ftp/pub/exim/exim4;
tar -x -f $f/exim-4.${maj}.tar.xz exim-4.${maj}/doc/ChangeLog;
tar -x -f $f/exim-4.${maj}.tar.xz exim-4.${maj}/doc/NewStuff;
mv exim-4.${maj}/doc/* $f/;
rm -fr exim-4.${maj};
cd $f;
gzip <ChangeLog >ChangeLog.gz. && mv -f ChangeLog.gz. ChangeLog.gz;
gzip <NewStuff >NewStuff.gz. && mv -f NewStuff.gz. NewStuff.gz;
~~~

-   Ensure git tree (with tags) is pushed to central repo: `git push --follow-tags`
-   Push the exim-website git also
-   Write announcement including changes and cryptographic checksums
    - to `exim-announce@lists.exim.org` and `exim-users@lists.exim.org`
    -   SHA256 checksums only for now; 4.80 was the last to use both
        SHA1 and SHA256. We'll add SHA-3 when it's available.
        `./release-process/scripts/stats_for_email /tmp/exim-pkgs`
    -   mail should be signed by a key with an @exim.org uid, that has
        been signed by the other Exim Maintainers.
    -   note that hummus requires authentication for any mail sent with
        a sender in the @exim.org domain
-   Pimp the release or RC on social media
    -   *Especially* for Release Candidates: we don't want to spam the
        announce list with these, but there are many folks who don't
        follow `exim-users` because of the volume but who are interested
        in trying out Release Candidates to help out
    -   Tweet it. Try using an `#Exim` hashtag.
    -   Consider other social media; bias towards our audience, which is
        computer-literate folks who run systems for themselves or employers in
        a federated communication system.  Eg, Mastodon?
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
    -   update the Topic on the #exim IRC channel on Libera Chat
    -   if a Security release, then update [[EximSecurity]] with details.


RC Steps
--------
-   This should be inline above
-   Basically same as for release, except no update of website and
    ChangeLog/NewStuff distro on ftp site
-   Tag has form exim-4.92-RC3
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
