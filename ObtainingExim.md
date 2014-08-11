Obtaining Exim
==============

Source Distributions
--------------------

The primary source distribution is from the main *exim.org* site. See
[ftp://ftp.exim.org/pub/exim](ftp://ftp.exim.org/pub/exim)/ for the
source packages, which are always accompanied by detached GPG
Signatures.

You can find a list of all the current [www mirror
sites](http://www.exim.org/mirmon/www_mirrors.html), and the [ftp mirror
sites](http://www.exim.org/mirmon/ftp_mirrors.html) and their status

There are a number of [EximMirrorSites](EximMirrorSites) which also
carry source packages. Please ensure that the packages are signed and
are for the current version.

Once you've downloaded the source code, see
[InstallingExim](InstallingExim) for help on building and installing
Exim.

SCM Access
----------

There are [Git repositories](EximDevelopment#SourceAccess).

Latest Version
--------------

From 2014-08-1, the latest version of Exim is 4.84.

The popular exiscan-acl patch code has been incorporated into Exim from
version 4.50 onwards. The distributors' patch for dynamically loadable
lookups has been incorporated into Exim from version 4.74 onwards.

[[What's new and change logs|ChangeLog]]

Binary Packages
---------------

Binary packages are all built by third parties, and not the
[EximDevelopers](EximDevelopers). Packaging issues should be reported
to the packagers. In general binary packages include the *exiscan*
extensions, however the build configuration is a decision made by the
packager.

### Red Hat / Fedora Linux Distributions

For [Fedora](http://fedora.redhat.com/), exim packages are distributed
as follows:
-   Fedora Core 3 (now EOL): as part of the base OS
-   Fedora Core 4+: as part of the Fedora Extras repository, maintained
    by [DavidWoodhouse](DavidWoodhouse)

Earlier releases were also built for FC2 and old RHL releases.

For Red Hat Enterprise, Exim packages are distributed as follows:
-   RHEL4: Exim 4.43 is available

In general, due to the similarities between Fedora and Red Hat
Enterprise, the latest Exim packages from Fedora Extras can usually be
rebuilt fairly easily (i.e. with minimal or no modifications) on modern
versions of Red Hat Enterprise (i.e. RHEL3, RHEL4) and variants such as
[CentOS](http://www.centos.org/), [White Box Enterprise
Linux](http://www.whiteboxlinux.org) etc.

#### Other sources
-   Some older packages are also built for FC1 and several RHL varients
    by [TimJackson](TimJackson) - those RPMs can be found
    [here](ftp://ftp.exim.org/pub/rpms-for-exim/) but are not currently
    being maintained.
-   The [ATrpms RPM repository](http://atrpms.net/) carries [current
    Exim rpms](http://atrpms.net/name/exim) for many Red Hat and Fedora
    distributions.

### SuSE/Novell SUSE Distributions

Binary packages (unsupported by Novell/SuSE) can be found
[here](http://software.opensuse.org/download/server:/mail/)\_.

### Debian GNU/Linux

Debian GNU/Linux ships packages for Exim 3 (called exim), and Exim 4
(called exim4). However, using Exim 3 for new installs is deprecated.

There are two variations:
[exim4ddaemonllight](http://packages.debian.org/exim4-daemon-light), or
[exim4ddaemonhheavy](http://packages.debian.org/exim4-daemon-heavy)
which differ in the compiled-in feature set.

Information about the Exim 4 Package, including update hints, can be
found in /usr/share/doc/exim4-base/README.Debian.html, or on the Web in
[http://pkg-exim4.alioth.debian.org/README/README.Debian.etch.html](http://pkg-exim4.alioth.debian.org/README/README.Debian.etch.html).

There is a dedicated mailing list for exim on Debian. You can subscribe
via
[http://lists.alioth.debian.org/mailman/listinfo/pkg-exim4-users](http://lists.alioth.debian.org/mailman/listinfo/pkg-exim4-users)

#### stable

Exim4 (version 4.63) is the default MTA for the current stable release
of Debian GNU/Linux, Version 4.0, codenamed "etch".

[Backports of Exim4](http://www.backports.org/debian/pool/main/e/exim4/)
for the old stable release, sarge, are available.

To install the backported version, add the following line to your apt
sources.list:

deb [http://www.backports.org/debian](http://www.backports.org/debian)
sarge-backports main

You can read more information about [installing
backports](http://www.backports.org/dokuwiki/doku.php?id=instructions).

#### testing/unstable

Exim4 is the default MTA for Debian GNU/Linux, testing and unstable.
Just apt the packages from the repository.

#### experimental

The very latest Release of Exim4 is freqently available from the
experimental distribution.

### Gentoo

    emerge exim

See
[http://gentoo-wiki.com/Mail\_Server\_based\_on\_Exim\_and\_Courier-imap](http://gentoo-wiki.com/Mail_Server_based_on_Exim_and_Courier-imap)

### FreeBSD

Exim4 is in the FreeBSD ports tree:

    # cd /usr/ports/mail/exim
    # make install clean

### PLD GNU/Linux

Just install with poldek -i exim

### Mandrakelinux

You can use urpmi to install it ( for mandrake 10.2 and higher ) urpmi
exim

Documentation
-------------

Documentation source packages are available from the same place as the
source distributions. The main documentation is also available as
browsable HTML on [http://www.exim.org](http://www.exim.org)/