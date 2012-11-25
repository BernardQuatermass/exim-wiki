The following is a quick and dirty HOWTO of setting up DSPAM 3.2.4 and
Exim 4.43 on Fedora Core 3. Exim came from the distro, DSPAM was
compiled with:

./configure --prefix=/usr/local/encap/dspam-3.2.4 --enable-spam-delivery

This is basically a combination of Troy Engel's HOWTO plus Adam J.
Henry's BSMTP transport. See:

[http://dspam.nuclearelephant.com/dspam-users/2676.html](http://dspam.nuclearelephant.com/dspam-users/2676.html)
[http://www.exim.org/pipermail/exim-users/Week-of-Mon-20040809/074946.html](http://www.exim.org/pipermail/exim-users/Week-of-Mon-20040809/074946.html)

My main hangups with the above configs were permission problems on my
Fedora Core 3 box. Instead of running as mail:mail, I needed DSPAM and
Exim to run as exim:mail, because otherwise it could not read the mail
spool or write to logs when exim was called again to deliver the mail.

The following setup will use DSPAM in BSMTP mode like Adam described.
This means that DSPAM doesn't have to be compiled with the correct
location of exim, nor does it have to be suid mail, since it does not
call exim, but instead is called by exim with the privs you specify in
exim.conf.

Like Troy, I also found it necessary to chain
[SpamAssassin](SpamAssassin) to feed mail it classifies as SPAM back
to the DSPAM corpus learner. This has helped minimize the complaints I
received from my users while DSPAM got up to speed on their mail spools,
and also helped DSPAM to learn quicker.

Lastly, I added more aliases to support users sending not just
missclassified mails, but also corpus mail to DSPAM.

Note that I prefer my DSPAM aliases to be in the form of username-XXX
instead of XXX-username.

Here are the relevant routers. In my exim.conf I place them right after
the dnslookup router and before the system\_aliases router, so that all
aliased and procmail filtered mail still gets scanned. The header flags
are used just as Troy's config used them.

BEWARE that all exim.conf directives must occupy a single line. If your
browser inserted any 's or otherwise broke the long lines, reassemble
them.

Routers
=======

    # Spam assassin router:
    sa_router:
       no_verify
       check_local_user
       # When to scan a message :
       # - it isn't already flagged as spam from DSPAM
       # - it isn't already flagged as spam from Spamassassin
       # - it isn't already scanned
       # - it isn't local
       # - it isn't from one internal domain user to another
       condition = "${if and { {!def:h_X-FILTER-DSPAM:} {!def:h_X-Spam-Flag:} {!eq {$received_protocol}{spam-scanned}} {!eq {$received_protocol}{local}} {!eq {$sender_address_domain}{$domain}} } {1}{0}}"
       driver = accept
       transport = sa_spamcheck

    # DSPAM router
    dspam_router:
       no_verify
       check_local_user
       # When to scan a message :
       # - it isn't already flagged as spam from Spamassassin
       # - it isn't already flagged as spam from DSPAM
       # - it isn't already scanned
       # - it isn't local
       # - it isn't from one internal domain user to another
       condition = "${if and { {!def:h_X-Spam-Flag:} {!def:h_X-FILTER-DSPAM:} {!eq {$received_protocol}{local}} {!eq {$sender_address_domain}{$domain}} } {1}{0}}"
       headers_add = "X-FILTER-DSPAM: by $primary_hostname on $tod_full"
       driver = accept
       transport = dspam_spamcheck
       transport = dspam_spam_corpus

    # nospam-username
    dspam_false_positive_router:
       driver = accept
       local_part_suffix = -notspam
       transport = dspam_false_positive

    dspam_clean_router:
       driver = accept
       local_part_suffix = -clean
       transport = dspam_clean

    # spam-username
    dspam_spam_miss_router:
       driver = accept
       local_part_suffix = -spam
       transport = dspam_spam_miss

    dspam_spam_corpus_router:
       driver = accept
       local_part_suffix = -spamcorp 
       transport = dspam_spam_corpus

Transports
==========

The transports can be placed anywhere in the transport section, since
they are "called" from the appropriate router. Note that I use the more
modern DSPAM 3 command line options, which are more descriptive and
allow for all 4 types of training data.

    dspam_spamcheck:
       driver = pipe
       command = /usr/sbin/exim -oMr ds -bS
       transport_filter = /usr/local/bin/dspam --stdout --deliver=innocent,spam --user ${local_part}
       use_bsmtp = true
       user = exim
       group = mail
       return_path_add = false
       log_fail_output = true
       log_defer_output = true
       temp_errors = *
       return_fail_output = true
       home_directory = "/tmp"
       current_directory = "/tmp"
       message_prefix = ""
       message_suffix = ""

    # SpamAssassin
    sa_spamcheck:
       driver = pipe
       command = /usr/sbin/exim -oMr spam-scanned -bS
       use_bsmtp = true
       transport_filter = /usr/bin/spamc
       home_directory = "/tmp"
       current_directory = "/tmp"
       user = exim
       group = mail
       log_output = true
       return_fail_output = true
       return_path_add = false
       message_prefix =
       message_suffix =

    dspam_spam_miss:
       driver = pipe
       command = "/usr/local/bin/dspam --user $local_part --class=spam --source=error"
       home_directory = "/tmp"
       current_directory = "/tmp"
       user = exim
       group = mail
       log_output = true
       return_fail_output = true
       return_path_add = false
       message_prefix =
       message_suffix =

    dspam_spam_corpus:
       driver = pipe
       command = "/usr/local/bin/dspam --user $local_part --class=spam --source=corpus"
       home_directory = "/tmp"
       current_directory = "/tmp"
       user = exim
       group = mail
       log_output = true
       return_fail_output = true
       return_path_add = false
       message_prefix =
       message_suffix =

    dspam_false_positive:
       driver = pipe
       command = "/usr/local/bin/dspam --user $local_part --class=innocent --source=error"
       home_directory = "/tmp"
       current_directory = "/tmp"
       user = exim
       group = mail
       log_output = true
       return_fail_output = true
       return_path_add = false
       message_prefix =
       message_suffix =

    dspam_clean:
       driver = pipe
       command = "/usr/local/bin/dspam --user $local_part --class=innocent --source=corpus"
       home_directory = "/tmp"
       current_directory = "/tmp"
       user = exim
       group = mail
       log_output = true
       return_fail_output = true
       return_path_add = false
       message_prefix =
       message_suffix =

Mutt
====

Also, just to round out the experience, here are some mutt keybindings:

    macro index S "bYOURUSERNAME-spam\ryd"
    macro pager S "bYOURUSERNAME-spam\ryd"
    macro index U "bYOURUSERNAME-notspam\ry"
    macro pager U "bYOURUSERNAME-notspam\ry"

    macro index X "bYOURUSERNAME-spamcorp\ry"
    macro pager X "bYOURUSERNAME-spamcorp\ry"
    macro index A "bYOURUSERNAME-clean\ry"
    macro pager A "bYOURUSERNAME-clean\ry"

S and U are for reporting missclassified messages, and X and A are for
submitting previously unseen spam and normal mail, respectively.

* * * * *

> [CategoryHowTo](CategoryHowTo)
