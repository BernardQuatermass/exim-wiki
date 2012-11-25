Status of Exim version 3
========================

Exim version 3 was a popular MTA used by many sites and the standard MTA
used on some Operating System distributions - most notably [Debian
GNU/Linux](http://www.debian.org/).

Exim version 4 was released in February 2002. Since that time there has
been one final release of Exim version 3 - version 3.36, but no further
releases or development have happened and none are planned.

Maintenance Status
------------------

Exim 3 is no longer being maintained by the Exim developers.

It is believed that there may be security issues in Exim 3 (specifically
some of the Exim 4 security issues may also affect Exim 3), however the
Exim developers are not issuing updates against Exim 3. For this reason
if you wish to use Exim 3 then you should use a distribution version
where the distributor is looking after security updates.

Support/Help Status
-------------------

The major system for Exim support is the `exim-users` mailing list - see
[EximMailingLists](EximMailingLists). However none of the main
posters on the list (those who would normally answer questions) use Exim
3 any more - all have upgraded to Exim 4. The differences between the
two versions are such that it is very difficult to give accurate
information for Exim 3 any longer.

The documentation for Exim 3 is still online from the main
[website](http://www.exim.org/).

Recommendations
---------------

All users should update to Exim version 4. Most Operating System
distributions have been using Exim 4 for some time.

Upgrading to Exim 4 on Debian
-----------------------------

Exim version 3 was the default MTA in Woody, the previous version of
Debian stable. It is still available in Sarge (the current stable
release), packaged as *exim*. Exim 4 is available packaged as *exim4*,
which is the default MTA for new installs. Systems upgraded from Woody
to Sarge may still be running Exim 3.

While the non-Debian exim community still strongly recommends that users
upgrade to Exim version 4, Debian will continue to support exim 3 for as
long as it remains in the Debian GNU/Linux distribution. There will be
exim 3 packages available for some time. Debian is committed to deliver
security fixes for exim 3 within the scope of a volunteer-driven Linux
distribution. However, it is important to note that current versions of
Exim have many more eyes actively looking for security flaws, and
writing fixes.

As exim4 is an entirely different package from the exim package which
contains exim3, and exim3 and exim4's configuration are quite different,
there is unfortunately no seamless upgrade process. On installation, the
exim4 package tries to guess from an exim 3 configuration file which
might be found on the system which answers were given during exim 3
configuration and seeds its configuration questions appropriately.
However, there will be questions asked during installation. This
automatic parsing process might fail if you did elaborate things with
your exim 3 config.

Although you might be able to use the convert4r4 script to convert your
exim 3 config, the Debian maintainers recommend that you use its output
only as a basis for your local modifications to the exim4 config that
came with the package. That way, you will still see their changes when
we do changes to the default configuration which might let you profit as
well.

More information about Debian's exim4 packages is available on
[DebianExim4](DebianExim4).
