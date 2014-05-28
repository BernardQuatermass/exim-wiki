Exim Security Release Process
=============================

First, familiarize yourself with these pages:

 * [EximReleasePolicy](EximReleasePolicy) -- we'll throw out all the timeline
   and so forth, but the issues around PGP remain germane.
 * [EximRelease](EximRelease) -- we're not going to duplicate here how to
   prepare patches, etc.

Somehow, you become aware of a previously unknown security vulnerability in
Exim.  The first step is assessment -- how bad is it, do we need to put out a
security release?  There's no guidance on that here.  The rest of this page
assumes that we do.

Writing a patch runs somewhere in the middle of this list and might not happen
by the person coordinating the rest of the process.  That's fine.  **DO NOT
PUSH A SECURITY CRITICAL PATCH TO PUBLIC GIT.**

We assume that the person sending notifications has a PGP key in the strong
set, so can communicate via email such that arbitrary recipients stand a
reasonable chance of being able to verify identity.

1. Keep good notes of every step and timeline, we'll need them afterwards for
   writing things up for explaining ourselves to the community.
2. If reported to you, establish if the reporter has a timeline for public
   verification and what their preferences are around acknowledgement.  Note
   though that we prefer to move quickly enough that we far exceed any normal
   timeline requirements.  If professional researchers, ask if they've already
   obtained a CVE.
3. Request a CVE from a CVE numbering authority if still needed; the precise
   steps for this are somewhat in flux right now, a lot of their documentation
   is aimed at security researchers rather than product maintainers.  The turn
   around for CVEs can have a little lag, so it's good to fire this off in
   parallel to subsequent work.
4. For anything involving remote code execution, assume that we'll release a
   patch-level release (X.Y.patchlevel) with just the backported fix.  For
   other impacts, unless the scope of an issue is very minor, or fixing it
   requires architectural changes, we may also use a patchlevel backport.  The
   key is to make it very easy for others to apply.  However, there is a
   degree of judgement call here.  For some issues we'll just bundle it into
   the next release, which might be expedited, and provide heads-up to the OS
   packagers so that they can handle any backporting required.
5. Sketch out a timeline for disclosure.
  1. We strongly prefer to not disclose on Fridays but for issues where there
     is reason to believe that active exploit is happening, imminent or highly
     likely then we will make an exception.
  2. Exim is deployed globally, there is no good time of day, but we prefer to
     release when "middle of the night" is over the Pacific ocean.  Within
     local time, loosely assume 6am West Coast USA, 9am East Coast USA, 2pm
     UK, 3pm Western Europe, 5pm Western Russia, 10pm Japan.
  3. Allow at least a day for OS packagers to push through emergency updates,
     preferably two.
6. Send advance notice to the private Exim maintainers mailing-list and to the
   OpenWall "distros" mailing-list.
  * If we don't yet have a patch and are really being "advance", be a little
    vague; we pessimistically semi-expect information to leak from these lists
    (but as far as we _know_ have not yet experienced a leak).  It's
    sufficient to just say “we have a security flaw, impact is X, expecting to
    start OS packaging on date Y and release on date Z”.
  * Exim-Maintainers is private and includes people with commit bit and people
    with a history of working with us when packaging for OSes
  * <http://oss-security.openwall.org/wiki/mailing-lists/distros>
    + There's "distros" and "linux-distros", the latter is just a subset.  For
      Exim, we'll almost always want "distros".
    + It's a PGP-encrypting remailer with tightly vetted subscription; do read
      the list page for current details on getting past spam filters (and for
      the PGP key to encrypt to).
7. Ensure you have a patch by this point.  **DO NOT PUSH TO PUBLIC GIT**
8. Figure out how to test the patch without disclosing to public git; the
   extent of this problem depends upon how much of the code is
   platform-specific.  Get testing coordinated via direct email/XMPP with
   other Exim Maintainers.
9. Prepare a release tarball from local git; prepare a standalone patch.  Also
   sign the standalone patch, not just the tarball.  These should be
   considered "embargoed resources".
10. Put these embargoed resources behind a web-server with HTTP Basic/Digest
    authentication in front of them.  Create a couple of dedicated usercodes
    with decent passwords, one for each list.
11. Send notice of fix availability to the two mailing-lists.
12. Be available to answer questions.  Start drafting the release announcement
    email ahead of time.
  * Use previous announcements as a template
  * Remember to credit the reporter, if they want that
  * Be very clear up front about what the impact is and which versions are
    affected (and any build constraints).
  * Consider reporting mitigations which can be taken -- for some people, it's
    still easier to deploy configuration than new binaries, so if the feature
    can be disabled via configuration, note how and the impact.
13. Try to get some sleep.  The day of the release might be a little tense.
14. Release: push the pre-built tarball to be publicly available, send the
    email to exim-announce and exim-users, update the website; send email to
    the Openwall oss-security list.  Update other places which are on the
    release process wiki page (wikis, etc).
15. Push fixes to public git.
16. Deal with list fallout.  See if others can take lead on that, while you
    get sleep.

