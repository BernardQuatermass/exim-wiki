Obtaining Exim
==============

Source Distributions
--------------------

The primary source distribution is from the main *exim.org* site. See
[https://downloads.exim.org/exim4/](https://downloads.exim.org/exim4/) for the
source packages, which are always accompanied by detached OpenPGP (aka "PGP", "GPG")
Signatures.

You can find a list of all the current [www mirror
sites](http://www.exim.org/mirmon/www_mirrors.html), and the [ftp mirror
sites](http://www.exim.org/mirmon/ftp_mirrors.html) and their status

There are a number of [EximMirrorSites](EximMirrorSites) which also
carry source packages. Please ensure that the packages are correctly signed and
are for the current version.

All releases are PGP-signed by an OpenPGP key with a uid in the `@exim.org` domain.  All valid keys can be retrieved via WKD from `exim.org`:  `gpg --auto-key-locate clear,nodefault,wkd --locate-keys PERSON@exim.org`  
or from [the Maintainers Keyring](https://downloads.exim.org/Exim-Maintainers-Keyring.asc)

Once you've downloaded the source code, see
[InstallingExim](InstallingExim) for help on building and installing
Exim.

SCM Access
----------

There are [Git repositories](EximDevelopment#SourceAccess).

Latest Version
--------------

From 2019-09-29, the latest version of Exim is 4.92.3.

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
[here](http://software.opensuse.org/download/server:/mail/).

### Debian GNU/Linux

Debian GNU/Linux ships packages for Exim 4 (called exim4).

There are two variations:
[exim4-daemon-light](https://packages.debian.org/exim4-daemon-light), or
[exim4-daemon-heavy](https://packages.debian.org/exim4-daemon-heavy)
which differ in the compiled-in feature set.

Information about the Exim 4 Package, including update hints, can be
found in /usr/share/doc/exim4-base/README.Debian.html, or on the Web in
[https://salsa.debian.org/exim-team/exim4/tree/master/debian](https://salsa.debian.org/exim-team/exim4/tree/master/debian).

There is a dedicated mailing list for exim on Debian. You can subscribe
via
[https://alioth-lists.debian.net/cgi-bin/mailman/listinfo/pkg-exim4-users](https://alioth-lists.debian.net/cgi-bin/mailman/listinfo/pkg-exim4-users)

#### stable

Exim4 (version 4.92) is the default MTA for the current stable release
of Debian GNU/Linux, Version 10.x, codenamed "buster".

To install the backported version, consult the
[Debian documentation](https://backports.debian.org/Instructions) about integrating backports.


#### testing/unstable

Exim4 is the default MTA for Debian GNU/Linux, testing and unstable.
Just apt the packages from the repository.

#### experimental

The very latest Release of Exim4 is frequently available from the
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

### Arch Linux

    pacman -S exim

See [https://wiki.archlinux.org/index.php/Exim](https://wiki.archlinux.org/index.php/Exim)

Documentation
-------------

Documentation source packages are available from the same place as the
source distributions. The main documentation is also available as
browsable HTML on [http://www.exim.org](http://www.exim.org)/