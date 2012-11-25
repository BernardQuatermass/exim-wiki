Meet Up Proposed Agenda
=======================

Nearly all of this was originally from an email by Phil Pennock. I have
edited in some responses from other people (prefixed by their names). If
you want to add bits please do, but add rather than replace and tag with
your monika.

Discussion Points
-----------------

### Direction

Direction, plans. Major changes? Major experimental features? My
inclination is not major changes, because that would involve a lot of
work for a lot of administrators and I can't commit the time to keep up
"our" side of that social contract. So not a 5.x release. But there are
some experimental features I'd very much like to work on, such as XLMTP
/ EXDATA support, and things that amuse me, such as embedded Python. As
long as there's no re-architecting and no final removal of
long-deprecated features/aliases, we should be okay?

Should aim for either rough consensus or "agree to disagree", with an
understanding of what the more ambitious might commit to, if they're
dragging others along.

### Release procedures

Release procedures, steps involved, can we have 3+ people who fully
understand what needs to happen and have the access to place files
wherever (FTP, etc)

Nigel is dumping information in [EximRelease](EximRelease) and
scripts into CVS

### Code review

Code review: I've gotten so used to sending code for review to other
people that it feels shamefully risky every time I CVS commit code to
Exim which others haven't reviewed. zsh uses post-to-dev-list-first,
with posts getting reference X-Seq numbers and commit a little after.
These days, there are web-based tools available, such as Review Board or
Rietveld. Is anyone other than me interested in using these? Is there
any chance of them being successful, given the geographic dispersion and
turn-around times?

*John Jetmore:* I'm not opposed to more tooling, but with such tenuous
maintainer support right now I definitely worry about spending more time
worried about tooling than the project itself. Especially with code
review, I certainly welcome it but we really need to develop the group
of people who have enough understanding of the code to be able to judge
a code change (I certainly don't have it right now but I'm making an
effort to try).

### VCS

git. IMO, this is irrelevant to the success of the Exim project and
"switch VCS!" is the sort of thing people try, to get support, without
fixing the fundamental issues. That said, I'm not opposed to a switch, I
just don't care. If we do switch, one of the proponents needs to come up
with a detailed plan of how things fit together, what we build official
releases from, etc. For "git" read "Mercurial" if that's your fancy.

Can we *please* not have a VCS pi\#\#ing-contest on-list in this thread,
though? If people care strongly, put together a rationale and we can
take votes or whatever is politically correct these days.

*Nigel comments:* Ideally would like commit sanity checking (space/tab
policy maybe) and ideally an automated testing setup - ie commit leads
to a test run on tahini with mail spam.

Probably therefore need a repo reorg - standard checkout should
include:-
-   source
-   main doc sources
-   test suite

Other stuff may be in separate repos - the website and mirror listing is
= not closely related.

### PGP

PGP keysigning: we should all sign each others keys, so that we can have
a decent trust set for having releases be signed. Do we have any kind of
policy on using @exim.org uids on existing PGP keys? My personal thought
is that everyone attending should put their @exim.org address on as a
uid to their key, and we all sign those, and declare that any official
release will be signed by a key with an @exim.org uid on it. PGP trust
paths will have to take care of the rest of the trust model (and the OS
packagers on this list, who know who to trust anyway).

I'm a PGP bigot and go for email verification and other stuff. We could
probably steal the Debian PGP rules as the least amount of fuss and
bother, giving us something that appears to work? (nb, I haven't
actually read the Debian rules)

### Website

There was an surge of interest in website stuff recently but not much
seems to have come of it. What issues got in the way, what do we want to
do about it? What are the invariants we want to preserve in the existing
site, what's up for change?

### Test harness

Test harness: make sure all attendees have it set up, know how to invoke
it and can make it routine for normal dev work. I freely confess that I
haven't put the time into doing this myself. I get the distinct
impression that I'm not alone. This might be a useful jam session to get
people working together?

*John Jetmore:* I'm working to own this. I actually spent a lot of time
working with PH in 2006 tryig to get this cross platform so I might be
uniquely positioned to work on it. My goals right now are:

1.  get it back to running cleanly on a baseline linux system

2.  begin running it manually once a week or so to catch needed changes
    closer to when they happen

3.  implement the ability to run headless and mail results. I don't
    think on-commit is right, but nightly would be good.

4.  begin implementing new tests as new features come in

5.  work on cross-platform testing.

### Documentation Toolchain

Documentation build tools: what to do about them; are there any doc
lovers available, who can expand Phil Hazel's working reliable tools to
replace the stupidity that seems to be common in the modern document
preparation workflows, as ph10 did for the PDF?

I'm a grumpy troll who wonders WTF was wrong with troff anyway?

I don't want to redo all the docs into someone's latest pet project
markup language. We should just focus on the tools.

I suspect that dynamic content generation is a poor idea, since we still
have a whole bunch of website mirrors, which seems reasonable.

Study material: doc-docbook/HowItWorks.txt (IIRC, it explained things
pretty well, and it's time for me to re-read).

### Version Numbering

Version numbering; if we really have lots of time, do we want to talk
about this, or leave it until we hit 4.91? What follows 4.99?

### Supporting Services

*Added by Nigel* We currently run our own infrastructure on hardware
donated by Cambridge Uni. We have issues maintaining this due to
volunteer availability etc. The hardware is 3 years old, so at some
point replacement will be an issue.

Should we look at moving services to a hosted environment?

Services we currently run are:-
-   mailing lists
-   version control
-   web site
-   wiki
-   issue tracking
-   software distribution

Many of these services could be run by relocating to (one or a =
combination of several) services such as:-
-   google code
-   github
-   sourceforge
-   savannah

Subsequently dwmw2 has offered a platform for these services as he
already supports this type of environment.

Organisation
------------

That's probably more than enough for one day. How much remains for the
day depends on how much is sorted out ahead of time though. We can
certainly discuss most of the points here and now. I'm just hoping to
avoid a VCS flamewar.

I'm thinking of something like a 9.30am to 4pm range, with lunch in
there?

Assuming not much discussion happens before the day: I think that
(1/direction) is going to prove that yes, everyone has limited resources
and we can all agree within 10 minutes as people drink coffee and get
going. (2/release) is going to depend on how complex it is and what
people need to learn and be walked through. If the people who've done
past releases can write up the instructions, we could have this over and
done with in 15 minutes? I don't know what sort of systems access is
needed beyond a tahini account.

(3/code-review) and (4/vcs-change) depend on whether or not people just
say "no" immediately, or there's consensus. A proposal to migrate VCS
really should be more than a technical merits discussion though, and
include "this is what software we need to run, these are the tools we
need to have to support it, here's a project we can steal most of them
from, here's what a release process looks like, here's a proposed model
for what trees to maintain", etc. The options for (3), if we go for code
review, would depend on what VCS is used?

(5/pgp) is easy, if everyone understands PGP already. Experience
suggests (wet finger in air from a few keysignings I've run or attended)
that 4 people can be done in 10 minutes, even if not, and 50 people can
take about an hour.

(6/website) might go on forever, let's try to keep it short. Depending
on how things have gone, this and (9/versionning) are probably
lunch-debate topics, assuming we're not all wanting to kill each other
and using lunch as breathing space to calm down.

(7/test-harness) is definitely a laptops-out get-everyone-going hacking
session type thing. (8/doc-toolchain) might turn out to be too, if
anyone has bright ideas for immediate action.
