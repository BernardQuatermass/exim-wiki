Use ClamAV for virus scanning. Do it in an ACL, so that you can reject
messages bearing viruses - you don't want to do anything else with them.

Don't use "demime = \*", it's no longer necessary and is deprecated [see
section 41.6 of the docs]. Most Exim/Clam tips on the internet suggest
that you should use it, as do the Exim docs themselves!

You might find it necessary to ensure that your Clam daemon runs as the
same user as Exim.

Section 41.1 of the documentation shows how to declare the scanner
location.

Obtain ClamAV from [http://www.clamav.net](http://www.clamav.net)/

Make sure you're using the latest version of ClamAV. Some earlier
versions will eat all your CPU time under certain circumstances.
Besides, it's security software, and you want that to be up to date.
