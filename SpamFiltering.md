This is a collection of tips and tricks to get rid of spam. Please
describe your trick as fully as possible. If you have any information
about false positive risk please make that clear as well.

ACL Related Tricks
==================
-   [ACL HELO Tricks](AclHeloTricks)
-   [Sender/Recipient Verification](Verification)
-   [Blocking with Blacklists](BlackLists)
-   [Delay SMTP transactions](DelayTransactions)
-   [Rcpt ACL](AclSmtpRcpt)
-   [Data ACL](AclSmtpData)
-   [Block outgoing spam](BlockCracking)
-   [A package of checks](LenasConfig)

Spam Assassin
=============
-   [Maildir Spam Delivery](MaildirSpamDelivery)

Greylisting
===========
-   [Simple Greylisting with Exim](SimpleGreylisting)
-   [Grey Listing Mini Tutorial](FastGrayListMiniTutorial)
-   [E-Z Grey Listing Without A Database](DbLessGreyListing) (using
    Perl)
-   Greylisting without a database and without Perl: [using
    ${dlfunc](DbLessGreyListingC) and [using
    ${run](DbLessGreyListingRun)
-   [Heiko Schlitterman's
    implementation](http://www.schlittermann.de/doc/grey.shtml)
-   [Jakob Hirsch's Simple Greylisting with
    SQLite](http://plonk.de/sw/exim/greylist.txt)
-   [greylisting daemon using SQLite](http://greylstd.cmeerw.org)
-   [Greylisting using MySQL and stored
    procedures](http://www.phcomp.co.uk/TechTutorial/HOWTOs/GreyListing.php)
-   [ddgrey - dynamic and optionally distributed greylisting for exim4 (beta)](https://github.com/perericr/ddgrey)
-   More implementations at <strike>[Spam
    Links](http://spamlinks.net/filter-server-greylist.htm#implement-exim)</strike>, see [archived version](https://web.archive.org/web/20140209085322/http://spamlinks.net/filter-server-greylist.htm)

(Remember when searching for further implementations that some use
"grey" and others "gray" in their descrciptions).

Other Tricks
============
-   [Ideas for how to use Exim filters on
    delivery](MailFilteringTips)

External Sites with Good Spam Filtering Info
============================================
-   <strike>[Tor Slettnes Exim Spam Filtering
    Site](http://slett.net/spam-filtering-for-mx/)</strike>, see [archived version](https://web.archive.org/web/20180509021323/http://slett.net/spam-filtering-for-mx/)
-   [Marc Perkel's Spam Filtering
    Tricks](http://www.junkemailfilter.com/spam/how_it_works.html)
-   [Exim configuration at the University of
    Cambridge](https://fanf2.user.srcf.net/hermes/doc/talks/2005-02-eximconf/paper.html)
-   [Spam Assassin](http://www.spamassassin.org)
-   [Spam Probe](http://spamprobe.sourceforge.net/)
-   <strike>[Dynamic IP address filtering](http://tanaya.net/DynaStop/)</strike>, see [archived
    version](https://web.archive.org/web/20130816221540/http://dynastop.tanaya.net/)
-   <strike>[Spam Assassin
    Basics](http://blog.webhosting.uk.com/2006/09/26/spam-assassin-basics/)
    for CPanel users</strike>, see [archived version](https://web.archive.org/web/20061126204555/http://blog.webhosting.uk.com/2006/09/26/spam-assassin-basics/)
-   <strike>[ACL snippets](http://tehran.lain.pl/exim-snippets.html)</strike>, see [archived
    version](https://web.archive.org/web/20100626015552/http://tehran.lain.pl/exim-snippets.html)
-   <strike>[dlfunc functions for Exim](http://www.ols.es/exim/dlext/)</strike>, see [archived version](https://web.archive.org/web/20100717101404/http://www.ols.es/exim/dlext/)
-   <strike>[More ACL snippets](http://www.ols.es/exim/acl/)</strike>, see [archived
    version](https://web.archive.org/web/20161026081026/http://www.ols.es/exim/acl/)

External Sites with ${dlfunc{file}{function}{\<arg\>}{\<arg\>}...}
===================================================================
-   [${dlfunc dspam](http://mta.org.ua/exim-conf/dlfunc/dspam/)
-   [${dlfunc milter](http://mta.org.ua/exim-conf/dlfunc/milter/)
-   [${dlfunc spamd](http://mta.org.ua/exim-conf/dlfunc/spamd/)
-   [${dlfunc
    spamoborona2](http://mta.org.ua/exim-conf/dlfunc/spamoborona2/)
