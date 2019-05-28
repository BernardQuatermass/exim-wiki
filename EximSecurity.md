Exim Security
=============

Much consideration of Exim's security is given in
[Chapter 55 - Security considerations](http://www.exim.org/exim-html-current/doc/html/spec_html/ch55.html)
of [The Exim Specification](http://www.exim.org/exim-html-current/doc/html/spec_html/index.html).
 This includes suggested hardening steps.

Reporting
---------

Please email reports of security issues to security@exim.org

Encryption keys for the Exim developers are [available here](https://downloads.exim.org/Exim-Maintainers-Keyring.asc).

Vulnerability History
---------------------

Note that a "remote code execution as Exim run-time user" vulnerability
can be combined with a privilege escalation attack to become even more
serious.

-   CVE-2016-9963 fixed in 4.88 and in 4.87.1. If several conditions are met, Exim
may leak the private DKIM key to the main log and if even more conditions are met, to the sender of the message. For details please read [CVE-2016-9963](https://exim.org/static/doc/CVE-2016-9963.txt). If you use a distro package of Exim, you may find it has been fixed even for older-numbered releases.

-   CVE-2016-1531 fixed in 4.86.2. If Exim loads the Perl interpreter during startup, a privilege escalation was possible. For details please read [CVE-2016-1531](https://exim.org/static/doc/CVE-2016-1531.txt). If you use a distro package of Exim, it may be fixed even for older releases.

-   CVE-2015-0235 is a **glibc** bug, affecting multiple applications on platforms which use glibc for their system C library; this was a problem with `gethostbyname()` functions.  The security advisory referenced Exim as an exploit vector for remote access.  The fix is to update glibc; workarounds include disabling configuration directives which enable the HELO checking which exposes the vulnerability.  See <https://lists.exim.org/lurker/message/20150127.200135.056f32f2.en.html> for our advisory on this.
-   CVE-2014-2972 fixed in 4.83: mathematical comparison functions were
    expanding args twice. Impact: local code execution if specific
    mathematical comparison functions were performing data lookups from
    user controlled data.
-   CVE-2014-2957 fixed in 4.82.1, introduced in 4.82: used untrusted
    data when parsing the From header in Experimental DMARC code and
    allowed macro expansion.
    [Details post](https://lists.exim.org/lurker/message/20140528.122536.a31d60a4.en.html)
-   CVE-2012-5671 fixed in 4.80.1, introduced in 4.70: buffer overflow
    vulnerability in DKIM DNS response processing. Impact: remote code
    execution as Exim run-time user.
    [Details post](https://lists.exim.org/lurker/message/20121026.083548.4647373a.en.html)
-   CVE-2011-1764 fixed in 4.76, introduced in 4.70: format string
    attack in DKIM processing. Impact: remote code execution as Exim
    run-time user. [Bugzilla 1106](http://bugs.exim.org/1106).
-   CVE-2011-1407 fixed in 4.76, introduced in 4.70: flaw in handling
    DKIM DNS records. Impact: remote code execution as Exim run-time
    user
-   CVE-2011-0017 fixed in 4.73: return values of setuid()/setgid() not
    checked; only an issue on Linux. Impact: privilege escalation from
    Exim run-time user to root
-   CVE-2010-4345 fixed in 4.73: Exim privilege escalation from Exim
    run-time user to root via configuration overrides
-   CVE-2010-2023 fixed in 4.72: Hardlink attack via sticky mbox
    directory. Impact: overwrite files of target user on same partition
    as mbox directory. [Bugzilla 988](http://bugs.exim.org/988).
-   CVE-2010-2024 fixed in 4.72: Symlink attack in /tmp for MBX locking
    algorithm. [Bugzilla 989](http://bugs.exim.org/989).
-   CVE-2010-4344 fixed in 4.70: buffer overflow in string\_format().
    Impact: remote code execution as Exim run-time user. [Bugzilla
    787](http://bugs.exim.org/787).

See Also
--------

* [Security Release Process](SecurityReleaseProcess)
