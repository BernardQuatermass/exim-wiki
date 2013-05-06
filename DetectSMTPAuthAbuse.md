# Detecting SMTP Auth Abuse

In a standard configuration of any mail system, users are allowed to send email based on two basic criteria:

1. From a known, trusted network (local LAN in an office for example), usually without a username and password.
1. From everywhere else, but only if they use a valid login and password.

It is a common tactic for botnets to be used to send out spam.  They do this by capturing some user's login and password, then distributing it out to a bunch of their compromised machines.  This means that one of the symptoms of a hacked account is that there will be many different IP addresses connecting and sending using SMTP Auth.

You have to consider a typical customer's usage when deciding what the max number of IP addresses should be.  It is a common configuration for someone to have their home computer, their work computer, and their cell phone all using IMAP and SMTP Auth to read and send messages.  Each of these could possibly change over the course of a day.  I add a few more to this total to give a buffer for things like internet instability, ISP instability, power instability (reboots causing new IP's to be handed out), etc.

The design of the script:

1. It uses the time frame of examining for issues to be 1 day, starting at 00:00 and ending at 23:59 for whatever time zone your system is logging into.
1. It defaults the limit to be 10 different IP addresses over the course of 1 day, but it is adjustable from the commandline.
1. Either pass the filename to open on the commandline, or pipe the file contents to the script.
1. It has a debug flag which will scan the logs and print out what it finds, but will not change passwords nor send alerts.

A copy of the generic perl script can be downloaded from my website at [detect_hacked_smtp_auth_conns.pl](http://downloads.mrball.net/Linux/Exim/detect_hacked_smtp_auth_conns.pl) until I can get the script attached to this page.