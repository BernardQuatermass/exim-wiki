Exim can be configured to use SpamAssassin.

Perhaps the most useful way to integrate SpamAssassin is in ACLs. This
way, spam can be rejected at SMTP time, so you have no worries about
generating bounce messages (collateral spam), discarding email, or users
failing to find false positives. False positives should be bounced back
to the sender by the SMTP client.

[https://maretmanu.bobu.eu/homepage/inform/exim-spam.php\#spam](https://maretmanu.bobu.eu/homepage/inform/exim-spam.php#spam)

shows one way to include SpamAssassin.
