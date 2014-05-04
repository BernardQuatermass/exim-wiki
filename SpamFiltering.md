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
-   More implementations at [Spam
    Links](http://spamlinks.net/filter-server-greylist.htm#implement-exim)

(Remember when searching for further implementations that some use
"grey" and others "gray" in their descrciptions).

Other Tricks
============
-   [Ideas for how to use Exim filters on
    delivery](MailFilteringTips)

External Sites with Good Spam Filtering Info
============================================
-   [Tor Slettnes Exim Spam Filtering
    Site](http://slett.net/spam-filtering-for-mx/)
-   [Marc Perkel's Spam Filtering
    Tricks](http://www.junkemailfilter.com/spam/how_it_works.html)
-   [Exim configuration at the University of
    Cambridge](http://www-uxsup.csx.cam.ac.uk/~fanf2/hermes/doc/talks/2005-02-eximconf/paper.html)
-   [Spam Assassin](http://www.spamassassin.org)
-   [Spam Probe](http://spamprobe.sourceforge.net/)
-   [Dynamic IP address filtering](http://tanaya.net/DynaStop/)
-   [Spam Assassin
    Basics](http://blog.webhosting.uk.com/2006/09/26/spam-assassin-basics/)
    for CPanel users
-   [ACL snippets](http://tehran.lain.pl/exim-snippets.html)
-   [dlfunc functions for Exim](http://www.ols.es/exim/dlext/)
-   [More ACL snippets](http://www.ols.es/exim/acl/)

External Sites with ${dlfunc{file}{function}{\<arg\>}{\<arg\>}...}
===================================================================
-   [${dlfunc dspam](http://mta.org.ua/exim-conf/dlfunc/dspam/)
-   [${dlfunc milter](http://mta.org.ua/exim-conf/dlfunc/milter/)
-   [${dlfunc spamd](http://mta.org.ua/exim-conf/dlfunc/spamd/)
-   [${dlfunc
    spamoborona2](http://mta.org.ua/exim-conf/dlfunc/spamoborona2/)
