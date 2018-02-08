
Exim Release Policy
===================

**This is a policy put forward by one maintainer, and after a few
releases by him has not received any objections. We reserve the right to
adjust it, but this makes clear what he believes "reasonable
expectations" are. (He has also been the release coordinator for the
last several releases, so until that changes, this is the de facto
policy).**

Who decides; enforceability
---------------------------

Exim is a volunteer project, with contributions from many people and
coordination from The Exim Maintainers, the people with commit access to
the main git repository. None of the maintainers are paid to provide
public Exim support, so nobody can commit to any form of "SLA" or
guarantee. If we fail to release according to this policy, that's just
life.

If, in the best discretion of the people putting together a release, it
is necessary to diverge from this policy, even completely contradicting
it, that is entirely acceptable.

This policy lays down the expectations of what we plan to do in the
normal or predictable cases, if there is someone available with
sufficient time to shepherd a release. It is nothing more and is not a
binding commitment.

Release triggers
----------------
-   There is no fixed schedule for release.
-   We aim for at least one release every six months, and if we have
    been idle then we just release with what we have.
-   If there is a bug-fix for a security-impacting problem, then:
    -   We will obtain a CVE number: https://cveform.mitre.org/
    -   We will discuss with OS packagers the severity of the issue
    -   If the problem permits privilege escalation from untrusted local
        users to any user, it will warrant urgent release
    -   If the problem permits remote code execution, this is considered
        Critical and it will warrant urgent release and possibly the
        creation of a branch, so that a release can be put out which
        contains *only* this fix.
    -   If the problem permits privilege escalation from the Exim
        run-time user, then this is serious and will act as a trigger
        for a hurried release, but will not on its own trigger a
        fire-drill. If there is also a problem permitting untrusted
        local users to escalate privileges to the Exim run-time user, or
        for remote code execution as the Exim run-time user, then this
        becomes Critical.
-   The "Release Engineer" or "Release Coordinator" shall simply be
    "whoever steps forward".

Release numbering
-----------------
-   We will preserve lexical comparison of version numbers, so there
    will not be a "4.9901" release or a "4.100" release. If we make it
    up to 4.99, then the release following "4.99" will be "5.00".
-   We may jump version numbers at our discretion, when considering the
    features included.
-   If we introduce *significant* backwards-incompatible changes, then
    the major number will be increased. Eg, "5.23" followed by "6.00".
    But if we just reached 5.99, then 6.00 will not be significant in
    this manner.
-   There are backwards-incompatible changes which we feel do not
    warrant a major version bump. These are typically security
    improvements and few people with secure configurations should be
    accepted. Administrators should *always* read `README.UPDATING`
    before starting an update.
-   There are no current plans for a grand rewrite.

Release verification
--------------------
-   All releases will be PGP signed. This includes all "tarballs" (code,
    documentation) and the release announcement.
-   The release announcement will include, within its text,
    cryptographic checksums using algorithms of our choosing. We reserve
    the right to switch algorithm.
-   These releases will be performed by a PGP key belonging to an
    individual maintainer. A shared, group, PGP key is deliberately not
    part of our trust model.
-   The PGP key will contain an identity ("uid") which includes the
    maintainer's real name and an email address which is `@exim.org`
-   PGP keys are identified by the uids and each has its own signatures
    in the "Web of Trust". To be valid, the `@exim.org` uid will have
    been signed by a group of the other Exim maintainers. In PGP speak,
    multiple maintainers have keys "in the strong set", although the
    binding of the `@exim.org` might not be. If another uid is more
    trusted by your client's trust paths, then it is up to your
    discretion to decide whether or not you accept that name as an Exim
    Maintainer.

Release Candidates & Buggy Releases
-----------------------------------
-   Except in the most Critical emergencies, a release shall be preceded
    by at least one "Release Candidate".
-   Except when prompted by security issues, the intention to cut the
    first RC shall have been announced ahead of time on the Exim Users
    mailing-list.
-   More RCs are a matter of judgement for the person coordinating the
    release.
-   Unless pushed by a security problem, there will be at least one week
    between the first RC and the final release, with sufficient time to
    bake.
-   People with commit on the master repository **should not** be
    committing new features or major reworkings in the time between the
    first RC and the actual release, to provide as stable and simple a
    set-up for the volunteer performing a release.
-   Problems to be addressed in this period shall include bugs of code
    or of documentation, build issues, portability concerns and the
    like.
    -   It's probably too late to address missing features
    -   Uncommitted bug-fixes from Bugzilla are fair game for complaint
    -   Sub-system maintainers whose bug-fixes have been overlooked
        should be able to get those added ASAP and the Release Engineer
        should consider then merging overlooked feature changes to the
        tree after the release.
-   A Critical security problem may be issued as a minimal change
    against the last stable release, as a "branch" in the code tree and
    the Release Engineer may choose to entirely skip a public RC process
    in that scenario.
-   We are dependent upon people testing the RCs to ensure platform
    compatibility of the final release, across both OSes and component
    versions.
    -   Those who test RCs get to ensure that their platform is a
        first-class supported platform for a release, and the final
        release should be cleanly buildable and working on their
        platform.
    -   We make no demands upon our users and do not expect RCs to be
        tested in a production environment, but we do ask that people at
        least try to compile and build the RC and send a test mail with
        it.
        -   This shouldn't be more than 30 minutes work total
        -   If you have a structured environment, with configurations in
            revision history, the time consists of reading the release
            notes (`README.UPDATING`, `NewStuff` and `ChangeLog`),
            adjusting your `Local/Makefile` as needed and kicking off a
            build, then testing sending mail with the new release.
        -   We greatly appreciate assistance from those with an
            environment that lets them "canary" a change in production,
            and any feedback from such testing is likely to receive the
            greatest attention from the Release Engineer. But we do not
            consider this the typical approach to testing RCs and accept
            this as a Very Nice Bonus, should it happen.
    -   Those who wait until a release is issued before testing will get
        such support as we can offer; typically, patches will be
        written. We will not rush to build a new release. OS packagers
        are experienced at maintaining an extra patch for compatibility,
        and others with significant issues should be attempting to track
        an RC.
    -   If we push new releases as fast as possible to fix issues
        post-release, that just encourages people to wait for a release
        before testing and creates a burden for everyone else on every
        other platform, as a common approach is to stay "up-to-date with
        releases, additional patches only as needed" and multiple
        releases per month create undue burden.
    -   The Release Engineer, as a volunteer, is not subject to demands
        that they immediately do more work to satisfy people who did not
        themselves put forward any effort until it was too late to help
        a release.
    -   In the event of a release being problematic on some platform, we
        expect to provide patches to those issues; we expect OS
        packagers are likely to just use those patches; we will wait
        long enough for all the OS/platform variants to shake loose any
        issues, before we get around to cutting another release. This
        might be a couple of weeks. Since it is expected that a security
        fix not thus be dependent upon the new release happening, there
        **should** be a Release Candidate process on a normal schedule
        for this follow-up release, to avoid cascading problems.
    -   The follow-up release will not be constrained to be bug-fixes
        only (unless the Release Engineer so chooses). Other committers
        shall be free to commit feature patches or re-workings to the
        code-base at any time after a release. A reward for trying RCs
        is that your feedback is addressed in a stable environment where
        only bug-fixes are being applied and you do not need to contend
        with some other new feature causing headaches come the next
        release.

Conclusion
----------

This policy tries to balance the volunteer effort, against the breadth
of usage and dependency upon Exim and the impact of releases. It
provides incentives to test Release Candidates and disincentives to
leave testing until after a Release. It establishes baseline
expectations of what is "reasonable behaviour" but does not establish
any enforceable right.

While constructive, well-argued feedback is appreciated, if you are
neither an active contributor to the Exim community nor a packager for a
major OS variant, we shall not necessarily address your concerns. This
policy is for us the maintainers, to keep us from burn-out, to better
serve the community of Exim users.

Thank you for using Exim. Please work with us to improve it.
