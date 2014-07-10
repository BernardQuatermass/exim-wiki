The goal is simple. Messages that are marked as spam but do not score high enough to get rejected: put them in the user defined SPAM directory.

Router section:

    maildir_spam:
     driver = accept
     local_parts = !www:!root:!nobody:!postmaster:!abuse:!admin
     transport = maildir_spam_delivery
     condition = ${if def:h_X-Spam-Flag: {true}}

Keep in mind, though that certain tutorials do not use the X-Spam-Flag,
but, rather, the X-Spam-Score, for those cases, use this router
configuration:

    maildir_spam:
     driver = accept
     local_parts = !www:!root:!nobody:!postmaster:!abuse:!admin
     transport = maildir_spam_delivery
     condition = ${if def:h_X-Spam-Score: {true}}

Transport section

Is just the same as your generic maildir delivery transport but the
directory is SPAM

    maildir_spam_delivery:
      driver = appendfile
      maildir_format = true
      directory = /var/mail/Maildirs/$local_part/.SPAM/  <---- example
     (...)
     [ rest of your settings here ]
