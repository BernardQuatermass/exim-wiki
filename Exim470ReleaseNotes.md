Exim 4.70 Release Notes
=======================

Exim release 4.70 is now available from the primary ftp site:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.70.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-4.70.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.70.tar.bz2](ftp://ftp.exim.org/pub/exim/exim4/exim-4.70.tar.bz2)

* * * * *

This release is a combination feature and bug fix release. The major new
features are:-
-   Native DKIM support without an external library.
-   Experimental DCC support via dccifd (contributed by Wolfgang
    Breyha).

Other changes:-
-   PCRE is no longer included with the Exim distribution. You will need
    a separate PCRE library (and matching headers) to compile Exim. You
    will need to change your Local/Makefile to support this. Most modern
    systems have a packaged PCRE library, alternatively PCRE can be
    found at [http://www.pcre.org](http://www.pcre.org)/
-   Experimental Yahoo! Domainkeys support dropped in favor of native
    DKIM support.
-   The documentation has been updated and regenerated.

As usual, all changes are in the doc/ChangeLog file, which can also be
seen at
[http://vcs.exim.org/viewvc/exim/exim-doc/doc-txt/ChangeLog?view=markup&pathrev=exim\_4\_70](http://vcs.exim.org/viewvc/exim/exim-doc/doc-txt/ChangeLog?view=markup&pathrev=exim_4_70)

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

    012d32acb63342f60d50f8905e20acb2f73f59b0  exim-4.70.tar.bz2
    9483cf513f9b9b5a60e8228e88962c549b542f9d  exim-4.70.tar.bz2.asc
    f758ad1d31fa4b1dec538a160668e6f2b676a8a2  exim-4.70.tar.gz
    248804500e01569383d84ae9e886e53cc62e6877  exim-4.70.tar.gz.asc
    45c7e09dc0fafa62c31da880b96a9acef8d28ff5  exim-html-4.70.tar.bz2
    f6126e084bfa6128069a06e86fa07140f3a5bf43  exim-html-4.70.tar.gz
    ff80170aba79c25b773625c8e9f934690b714d7c  exim-info-4.70.tar.bz2
    716a3ffac67e33ba325549b1cfc250286b97f9c9  exim-info-4.70.tar.gz
    f429a6cc6c6e388f9ad0775a77fe6bedc56027bb  exim-pdf-4.70.tar.bz2
    8f6c604c766333b6f78655bea90fd82d6701c69d  exim-pdf-4.70.tar.gz
    20f5dbafaea4c6ea8c8833b54743c451d6ae1735  exim-postscript-4.70.tar.bz2
    b11e3b688dd1a05a92621442452da73e92b9ee98  exim-postscript-4.70.tar.gz
    d7e2269330a437b92723795e3ff8577672480d12  exim-texinfo-4.70.tar.bz2
    1396e1ed0b91a7ab4a0682ec15d52a4ee0c6f169  exim-texinfo-4.70.tar.gz

The distribution contains an ASCII copy of the 4.70 manual and other
documents. Other formats of the documentation are also available:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.70.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.70.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.70.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.70.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.70.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.70.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-texinfo-4.70.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-texinfo-4.70.tar.gz)

The .bz2 versions of these tarbundles are also available.

The [ChangeLog](ChangeLog) for this, and several previous releases,
is included in the distribution. Individual change log files are also
available on the ftp site, the current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.70](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.70)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.70.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.70.gz)

Brief documentation for new features is available in the
[NewStuff](NewStuff) file in the distribution. Individual
[NewStuff](NewStuff) files are also available on the ftp site, the
current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.70](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.70)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.70.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.70.gz)

* * * * *
