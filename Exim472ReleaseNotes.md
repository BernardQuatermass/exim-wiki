Exim 4.72 Release Notes
=======================

Exim release 4.72 is now available from the primary ftp site:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.72.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-4.72.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-4.72.tar.bz2](ftp://ftp.exim.org/pub/exim/exim4/exim-4.72.tar.bz2)

* * * * *

The changes involved are:-

1.  TWO SECURITY FIXES: one relating to mail-spools which are globally
    writable, the other to locking of MBX folders (not mbox). These have
    CVE identifiers CVE-2010-2023 and CVE-2010-2024

2.  MySQL stored procedures are now supported.

3.  The dkim\_domain transport option is now a list, not a single
    string, and messages will be signed for each element in the list
    (discarding duplicates).

4.  The 4.70 release unexpectedly changed the behaviour of dnsdb TXT
    lookups in the presence of multiple character strings within the RR.
    Prior to 4.70, only the first string would be returned. The dnsdb
    lookup now, by default, preserves the pre-4.70 semantics, but also
    now takes an extended output separator specification. The separator
    can be followed by a semicolon, to concatenate the individual text
    strings together with no join character, or by a comma and a second
    separator character, in which case the text strings within a TXT
    record are joined on that second character. Administrators are
    reminded that DNS provides no ordering guarantees between multiple
    records in an RRset. For example:

<!-- -->

    foo.example.  IN TXT "a" "b" "c"
    foo.example.  IN TXT "d" "e" "f"

    ${lookup dnsdb{>/ txt=foo.example}}   -> "a/d"
    ${lookup dnsdb{>/; txt=foo.example}}  -> "def/abc"
    ${lookup dnsdb{>/,+ txt=foo.example}} -> "a+b+c/d+e+f"

Due to packaging build issues no texinfo documentation files have been
produced - however they should be build-able from the documentation
source should you have the correct toolchain available.

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

    3aab453faaa076a6b5f02320d7f8ad8aba21b347  exim-4.72.tar.bz2
    261c02c95b4d3aada73840b01f836e6874841c44  exim-4.72.tar.gz
    3e8434b1a07bcb92235233db6a7f6dbda8802c75  exim-html-4.72.tar.bz2
    6c5ee19c154ba12004b38dc74f7015cc668570c0  exim-html-4.72.tar.gz
    9d1a5517d52ec5730d1e552740adf2beb37349ab  exim-pdf-4.72.tar.bz2
    3bd08fb77574a712944aff00a1add482b64a2b7d  exim-pdf-4.72.tar.gz
    cf95726555dbc999aff3c2e884f4508933a6a875  exim-postscript-4.72.tar.bz2
    3094cdc4a63308dd62f41d09079d6ae4c76c56cb  exim-postscript-4.72.tar.gz

The distribution contains an ASCII copy of the 4.72 manual and other
documents. Other formats of the documentation are also available:
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.72.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-html-4.72.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.72.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-pdf-4.72.tar.gz)
-   [ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.72.tar.gz](ftp://ftp.exim.org/pub/exim/exim4/exim-postscript-4.72.tar.gz)

The .bz2 versions of these tarbundles are also available.

The ChangeLog for this, and several previous releases, is included in
the distribution. Individual change log files are also available on the
ftp site, the current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.72](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.72)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.72.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/ChangeLog-4.72.gz)

Brief documentation for new features is available in the NewStuff file
in the distribution. Individual NewStuff files are also available on the
ftp site, the current one being:
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.72](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.72)
-   [ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.72.gz](ftp://ftp.exim.org/pub/exim/ChangeLogs/NewStuff-4.72.gz)

* * * * *
