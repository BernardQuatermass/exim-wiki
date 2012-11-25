Routing to Procmail
===================

The following router/transport combination will natively use a
\$HOME/.procmailrc file. It has been taken from Debian's default
configuration.

Router:

    procmail:
      debug_print = "R: procmail for $local_part@$domain"
      driver = accept
      domains = +local_domains
      check_local_user
      transport = procmail_pipe
      # emulate OR with "if exists"-expansion
      require_files = ${local_part}:\
                      ${if exists{/etc/procmailrc}\
                        {/etc/procmailrc}{${home}/.procmailrc}}:\
                      +/usr/bin/procmail
      no_verify
      no_expn

Transport:

    procmail_pipe:
      debug_print = "T: procmail_pipe for $local_part@$domain"
      driver = pipe
      path = "/bin:/usr/bin:/usr/local/bin"
      command = "/usr/bin/procmail"
      return_path_add
      delivery_date_add
      envelope_to_add
