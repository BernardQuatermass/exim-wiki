Introduction
============

Security Enhanced Linux is starting to appear in standard distributions;
it is now part of Fedora and Debian. For each daemon or service, it is
necessary to describe security policy. This is the beginning of a
discussion of selinux policy configuration for exim, starting with
Nigel's exim rpms and fedora core 2.

Background
==========

selinux is best thought of as a supplement to traditional linux/unix security. it sits in the background and is triggered when traditional access controls permit an operation. it double checks this permission decision against a policy database.
:   the policy database is a detailed description of programs, files,
    and roles on the computer system. selinux uses this database to
    decide if the access desired is truly permitted. in permissive mode,
    it merely logs the deny it wanted to do in the dmesg log. in
    enforcing mode it prevents the requested access from taking place.
    normal practice is to run a system in permissive mode, monitoring
    dmesg and fixing up policy until the avc messages go away, and then
    switching to enforcing mode. Our purpose is to define the policy
    relating to the various pieces of a functioning exim installation,
    which will be summed up in three files, exim.fc (file context),

    > exim.te (the 'te' stands for Type Enforcement), and exim.if (the
    > interface to other policy modules).

    The Debian policy for Lenny will hopefully have Exim support (it has
    just been uploaded to unstable). If this gets in it will mean that
    the potential damage from a compromised Exim instance will be
    reduced, and it will be possible to run Exim on a machine running
    the "strict" SE Linux configuration. It basically works but needs
    some tweaking. Due to the way SE Linux works, having a single
    program that does everything doesn't work very well. The design of
    SE Linux is based on "domain transitions" when executing files of
    different type (similar to SETUID in the Unix permission model but
    the access is not necessarily greater). To support fine grained
    access controls we need to have programs performing smaller tasks.
    For the Exim design to work I believe that some wrappers are needed
    to trigger the domain transitions. I have been meaning to write the
    code to do this for a few years. (Russell Coker)

Links
=====

NSA site on selinux:
[http://www.nsa.gov/selinux](http://www.nsa.gov/selinux)/
