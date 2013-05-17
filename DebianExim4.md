Exim 4 Packages on Debian
=========================

This page contains pointers to documentation available for the Debian
exim4 packages. Debian has "official" exim 4 packages, and exim 4 is
Debian's default MTA. The configuration scheme that is used by the
Debian exim 4 packages by default is quite different from what you might
expect.
-   [Debian exim 4 users mailing
    list](http://lists.alioth.debian.org/mailman/listinfo/pkg-exim4-users)
-   [Debian exim 4 home page.](http://pkg-exim4.alioth.debian.org)
-   There is `/usr/share/doc/exim4-base/README.Debian` on your system
    (in text and/or html form depending on your package version), giving
    a short introduction to the specialities of the Debian exim 4
    packages. This documentation also includes information about how to
    get rid of the elaborate configuration scheme if you want to
    configure your exim in a more conservative way.
-   The README is also available [on the
    web.](http://pkg-exim4.alioth.debian.org/README/README.Debian.html)
-   The packages contain Debian-specific man pages, which are also
    available [on the
    web.](http://pkg-exim4.alioth.debian.org/README/)\_
-   The web copies of README and man pages are generated daily from the
    latest development version of the exim4 packages, so they might have
    been improved when compared to the documentation from your package,
    but the information contained might not match the behavior of your
    package.

Please try to determine whether you have an issue with exim itself or
with Debian's packaging and do not ask Debian specific questions on
exim-users. If in doubt, ask on pkg-exim4-users\_. People will point you
towards exim-users if you have a problem with the exim 4 upstream.

Note carefully that the package name for the current version is *exim4*
-- if you install the *exim* package, you will get Exim version 3. This
is required to cleanly support upgrades from older versions of Debian
GNU/Linux.

Debian offers two flavours of the exim4 Daemon: exim4-daemon-light is a
very basic exim which has the basic features and TLS encryption, while
exim4-daemon-heavy has most advanced features like LDAP, MySQL and
PostgreSQL, SPA SMTP authentication, an embedded Perl interpreter and
exiscan-acl.

The Debian exim4 packages use a debconf-driven configuration scheme
which might look strange to the experienced exim user.
