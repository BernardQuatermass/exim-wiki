New Committers to Exim
======================

Congratulations/Commiserations, you have a commit bit.

We'll probably include a welcome note in the next Exim release.

What next?
----------

The person who nominated you should get in contact, asking for your
consent (post nomination) and, if you agree, you'll be asked for some
information, to set up your systems access.

1.  A usercode, *xyz*, used for your shell account on tahini (the main
    box) and for your email address,
    [[xyz@exim.org](mailto:xyz@exim.org)](mailto:xyz@exim.org).

2.  Initial SSH public keys, to be granted access to the system. You can
    update the `~/.ssh/authorized_keys` file yourself with any changes.

3.  An email address to be subscribed to the private
    maintainers/packagers mailing-list.

4.  A Github account-name, if you have one, to be linked to the Exim
    group.

5.  Any social media account-names you want associated with Exim
    and shared to other developers; any communication preferences for
    off-list contact.

What's not covered above:

I.  A forwarding address: as an Exim committer, we assume that you can
    create a `.forward` file in your home directory to forward mail
    appropriately.

II. PGP: cross-signatures happen face-to-face.

PGP
---

Exim releases can only be performed by someone with a PGP key with a
reasonable degree of public linkage, ideally in the strong set. Our
software is installed by professionals on sensitive systems and many of
them like to be able to have strong confidence in the origin and
integrity of a purported release. Both release tarballs and announcement
mails have PGP signatures.

If you don't use PGP, please consider changing that. A reasonable
starting point is
[http://www.phildev.net/pgp](http://www.phildev.net/pgp)/ (no, not
either of the Exim Phils)

Consider adding an `xyz@exim.org` uid to your PGP key and start getting
signatures on that. Each individual uid on a PGP key has its own web of
trust; in practice, folks may trust a name they can verify, if they know
it's someone related to Exim, but the stronger the proof we can provide,
the happier everyone will be.

You have some time: new committers don't immediately produce the next
release, but the sooner you start, the more cross-signatures you'll
have. Technical conferences will probably be closely aligned with the
demographics of our userbase and help here.

Other notes
-----------

`ChangeLog` entries start at 01 for each committer, for each release;
thus a sequence of "AB/01 AB/02 CD/01 AB/03 CD/02" is reasonable. If
your initials conflict with an existing committer, we'll figure out a
solution at that time. No conflicts in 999+ days.

[EximGit](EximGit) is probably helpful reading.

Don't be afraid to ask for guidance, whether on list or directly to the
person who nominated you.
