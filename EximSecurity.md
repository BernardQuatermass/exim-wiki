Exim Security
=============

Much consideration of Exim's security is given in .. raw:: html
:   &ldquo;

[Chapter 52 - Security considerations](http://www.exim.org/exim-html-current/doc/html/spec_html/ch52.html).. raw:: html
:   &rdquo;

> of [The Exim
> Specification](http://www.exim.org/exim-html-current/doc/html/spec_html/index.html).
> This includes suggested hardening steps.

Vulnerability History
---------------------

Note that a "remote code execution as Exim run-time user" vulnerability
can be combined with a privilege escalation attack to become even more
serious.
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
