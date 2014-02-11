# Detecting SMTP Auth Abuse

In a standard configuration of any mail system, users are allowed to send email based on two basic criteria:

1. From a known, trusted network (local LAN in an office for example), usually without a username and password.
1. From everywhere else, but only if they use a valid login and password.

It is a common tactic for botnets to be used to send out spam.  They do this by capturing some user's login and password, then distributing it out to a bunch of their compromised machines.  This means that one of the symptoms of a hacked account is that there will be many different IP addresses connecting and sending using SMTP Auth.

You have to consider a typical customer's usage when deciding what the max number of IP addresses should be.  It is a common configuration for someone to have their home computer, their work computer, and their cell phone all using IMAP and SMTP Auth to read and send messages.  Each of these could possibly change over the course of a day.  I add a few more to this total to give a buffer for things like internet instability, ISP instability, power instability (reboots causing new IP's to be handed out), etc.

The design of the script:

1. It uses the time frame of examining for issues to be 1 day, starting at 00:00 and ending at 23:59 for whatever time zone your system is logging.
1. It defaults the limit to be 10 different IP addresses over the course of 1 day, but it is adjustable from the commandline.
1. Either pass the filename to open on the commandline, or pipe the file contents to the script.
1. It has a debug commandline option which will scan the logs and print out what it finds, but will not change passwords nor send alerts.
1. It only checks for plain and login types of SMTP Auth login.  If you use other types, you will have to add it to the regex in the main loop that parses each line.
1. Run it as a cronjob at some interval, for example: `@hourly /usr/local/bin/detect_hacked_smtp_auth_conns.pl --limit 12 /var/log/exim/main.log`

A copy of the generic perl script can be downloaded from my website at [detect_hacked_smtp_auth_conns.pl](http://downloads.mrball.net/Linux/Exim/detect_hacked_smtp_auth_conns.pl) until I can get the script attached to this page.

<b>UPDATE</b> [Ivo Truxa]: I did some minor changes to Todd's excellent script, including a GeoIP localization of addresses authenticating with Exim. This version will alert you not only when certain user account is accessed from more than the specified number of IP addresses (+ the exceptions in the ignore lists), but also when some account is accessed from a country not on your permission list. There is a more detailed description of the changes inside the script, including some usage tips. The script probably does not belong to the main Exim/Exim Git repository, so similarly as Todd, I just post an external link: [detect_SMTP_auth_abuse.pl](http://truxoft.com/resources/detect_SMTP_auth_abuse.pl)
