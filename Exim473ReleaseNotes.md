Exim 4.73 Release Notes
=======================

Exim release 4.73 is now available from the primary ftp site:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.73.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-4.73.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.73.tar.bz2](ftp://ftp.exim.org/pub/exim/exim4/exim-4.73.tar.bz2)

* * * * *

This is primarily a security and bug fix release. The changes involved
are:-

1.  TWO MAJOR SECURITY FIXES:-
    -   CVE-2010-4344 exim remote code execution flaw
    -   CVE-2010-4345 exim privilege escalation

2.  Improvements to OpenSSL support.

3.  Convert to a more recent Clam/AV API.

4.  Additional improvements to DKIM support

5.  Remove reliance on C99 va\_copy()

CVE-2010-4344 was actually resolved by a fix in release 4.70, but not
identified at the time as a security issue. Changes have been made in
release 4.73 to resolve CVE-2010-4345. We recommend that users should
migrate to 4.73 as soon as possible, however some distributions are
instead using older releases with specific patches for these issues.

Due to packaging build issues no texinfo documentation files have been
produced - however they should be buildable from the documentation
source should you have the correct toolchain available. The HTML
documentation included is now built using the same toolchain as the
website documentation.

* * * * *

The primary ftp server is in Cambridge, England. There is a list of
mirrors in:
-   [http://www.exim.org/mirmon/ftp\_mirrors.html](http://www.exim.org/mirmon/ftp_mirrors.html)

The master ftp server is now ftp.exim.org.

The distribution files are signed with Nigel Metheringham's GPG key
(address is
[[nigel@exim.org](mailto:nigel@exim.org)](mailto:nigel@exim.org), key id
is DDC03262), which is available on the ftp site and on a number of
keyservers. The ASCII signature files are in the same directory as the
tarbundles. The SHA1 hashes for the distribution files are:

    41a2025b250e212bf3d6890dc6636eeb4fa087b9  exim-4.73.tar.gz
    e40a6beece6642ab372be1bc25ce53275b4fbc54  exim-4.73.tar.bz2
    2ab231fd66e587fbcdd5c84107ce500ed0b15253  exim-html-4.73.tar.gz
    c3973f9c41ae8d7f3b28d572f2e1dcb87ae6f996  exim-html-4.73.tar.bz2
    b55c23b4bf6c1d5080e45bf9e90e43764b2bd776  exim-pdf-4.73.tar.gz
    a3f4da6afc6f064730685001a20f824c060f5268  exim-pdf-4.73.tar.bz2
    880ddd479c021c031612c11336fc2b14467d9d13  exim-postscript-4.73.tar.gz
    481ad6527f8dba4b4b9602d288e5a919c506416f  exim-postscript-4.73.tar.bz2

The distribution contains an ASCII copy of the 4.73 manual and other
documents. Other formats of the documentation are also available:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.73.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.73.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.73.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.73.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.73.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.73.tar.gz)

The .bz2 versions of these tarbundles are also available.

The ChangeLog for this, and several previous releases, is included in
the distribution. Individual change log files are also available on the
ftp site, the current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.73](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.73)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.73.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.73.gz)

Brief documentation for new features is available in the NewStuff file
in the distribution. Individual NewStuff files are also available on the
ftp site, the current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.73](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.73)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.73.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.73.gz)

* * * * *
