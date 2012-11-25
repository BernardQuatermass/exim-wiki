History of Linuxconf
====================

Back in the old days, in the long long ago, back before Google existed
there was a configuration utility that shipped with Redhat and several
other distributions called
[Linuxconf](..%20_Home%20Site:%20http://www.solucorp.qc.ca/linuxconf/).
The product is still supported today and is still excelent. Linuxconf
included a virtual email server that worked with Sendmail and UW-IMAP.
It used some custom extensions to accomplish virtual delivery and POP.

Eventually a patch was written to UW-IMAP called [Virtual
IMAP](http://vimap.sourceforge.net/) but the author hasn't updated it in
years. However receintly [Dovecot](http://www.dovecot.org) has added
Linuxconf compatibility and here is the [Dovecot
Configuration](http://wiki.dovecot.org/VirtualUsers).

Linuxconf is still in use today because it provides an HTML interface
for managing virtual users and aliases and allows users to change their
own passwords. It also controls what UNIX users are allowed to manage
which virtual domains. And it has a text mode interface allowing quick
and easy configuration form an SSH session.

How Linuxconf Works
===================

Linuxconf had a really simple way of doing virtual domains. They use a
passwd/shadow type file structure that is just like your passwd/shadow
files except they had one for each separate domain as follows:

    /etc/vmail/passwd.domain1.com
    /etc/vmail/shadow.domain1.com
    /etc/vmail/aliases.domain1.com

    /etc/vmail/passwd.domain2.com
    /etc/vmail/shadow.domain2.com
    /etc/vmail/aliases.domain2.com

The mail is stored in a directory structure in MBOX format. Assuning the
login name passed to Dovecot is
[[user@domain.com](mailto:user@domain.com)](mailto:user@domain.com), for
IMAP folders the directory structure is:

    /vhome/domain.com/home/user

The INBOX is stored as follows:

    /var/spool/vmail/domain.com/user

The Linuxconf virtual email system is actually pretty good especially if
you are merging several existing single domain servers into one virtual
domain servers. All you have to do is copy over your existing
passwd/shadow files into the /etc/vmail folder and rename them. You will
need to do some editing on the passwd file to point to where you wish to
store your email.

Configuring Exim to work with Linuxconf
=======================================

Exim works very well with this configuration.

Routers
=======

    # Virtual Aliases

    virtual_alias:
      driver = redirect
      allow_defer
      allow_fail
      data = ${expand:${lookup{$local_part}lsearch*{/etc/vmail/aliases.$domain} } }
      domains = +virtual_local_domains
      file_transport = address_file
      pipe_transport = special_pipe
      qualify_preserve_domain
      user = mail
      require_files = /etc/vmail/aliases.$domain

    # Virtual Localuser

    virtual_localuser:
      driver = accept
      condition = ${lookup {$local_part} lsearch {/etc/vmail/passwd.$domain} {$value}}
      domains = +virtual_local_domains
      require_files = /etc/vmail/passwd.$domain
      transport = virtual_local_delivery

    ################################################### 
    # This router matches virtual local user imap folders.
    # Folders are addresses folder-name@domain

    virtual_localuser_folder:
      driver = accept
      local_part_suffix=-*
      condition = ${lookup {$local_part} lsearch {/etc/vmail/passwd.$domain} {$value}}
      domains = +virtual_local_domains
      require_files = /etc/vmail/passwd.$domain:\
         /vhome/$domain/home/$local_part/${sg {$local_part_suffix}{-}{}}
      retry_use_local_part
      transport = virtual_local_folder_delivery
      user = root

Transports
==========

    virtual_local_delivery:
      driver = appendfile
      allow_symlink
      create_directory
      delivery_date_add
      directory_mode = 600
      envelope_to_add
    #  file = /vhome/$domain/home/$local_part/INBOX
      file = /var/spool/vmail/$domain/$local_part
      group = mail
      mode = 600
      return_path_add
      user = ${extract{2} {:} {${lookup {$local_part} lsearch {/etc/vmail/passwd.$domain} {$value} } } }

    # This allows for direct folder delivery. A very nice trick to add. If a message is
    # addressed to user-folder@domain.com then it will be delivered into the users imap folder.

    virtual_local_folder_delivery:
      driver = appendfile
      allow_symlink
      create_directory
      delivery_date_add
      directory_mode = 600
      envelope_to_add
      file = /vhome/$domain/home/$local_part/${sg {$local_part_suffix}{-}{}}
      group = mail
      mode = 600
      return_path_add
      user = ${extract{2} {:} {${lookup {$local_part} lsearch {/etc/vmail/passwd.$domain} {$value} } } }

More information about Linuxconf can be found at their \`Home Site\`\_.
