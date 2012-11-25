Configuration for Mailman
=========================

The following will allow exim to query Mailman for information whether a
list exists in Mailman. It is thus not necessary to have dedicated
aliases for a queue in the exim configuration. Exim will pick up the
configuration automatically.

transport
---------

    mailman:
      driver = pipe
      command = /usr/lib/mailman/mail/mailman \
                 '${if def:local_part_suffix \
                      {${sg{$local_part_suffix}{-(\\w+)(\\+.*)?}{\$1} }} \
                      {post}}' \
                  $local_part
      current_directory = /var/lib/mailman
      debug_print = "T: mailman for $local_part@$domain."
      group = list
      home_directory = /var/lib/mailman
      user = list

router
------

    mailman:
      driver = accept
      debug_print = "D: mailman for $local_part@$domain"
      domains = CONFDIR/mailman_domains
      local_part_suffix = -bounces : -bounces+* : \
                                      -confirm+* : -join : -leave : \
                                      -owner : -request : -admin
      local_part_suffix_optional
      require_files = /var/lib/mailman/lists/$local_part/config.pck
      retry_use_local_part
      transport = mailman

    bounce_mailman:
      driver = redirect
      allow_defer
      allow_fail
      data = :fail: Unknown user
      debug_print = "D: bounce_mailman for $local_part@$domain"
      domains = CONFDIR/mailman_domains
      retry_use_local_part
      # this director bounces all mail from a mailman domain that hasn't been
      # picked up by the mailman director

Alternative configuration
=========================

The configuration above will not work for lists ending with -admin,
-owner, etc.. Here is an alternative solution (embedded perl is
required):

main section
------------

    perl_startup = do '/etc/exim4/mailman.pl'
    MM_UID = list
    MM_GID = list
    domainlist mm_domains = whatever1 : wahetever2

router section
--------------

    mailman_router:
        driver = redirect
        domains = +mm_domains
        data = ${perl{getmmalias}{$local_part}}
        user = MM_UID
        group = MM_GID
        pipe_transport = address_pipe

/etc/exim4/mailman.pl
---------------------

    $MM_HOME='/var/lib/mailman';

    sub getmmalias {

    opendir(IMD, "$MM_HOME/lists");
    foreach $f (readdir(IMD)) {
      unless ( ($f eq ".") || ($f eq "..") ) {
        if ( $f eq $_[0]  ) {
          closedir(IMD);
          return "|$MM_HOME/mail/mailman post $f\n";
        }
        foreach $postf ("admin","bounces", "confirm", "join", "leave","owner", "request", "subscribe", "unsubscribe") {
          if ( "$f-$postf" eq $_[0] ) {
            closedir(IMD);
            return "|$MM_HOME/mail/mailman $postf $f\n";
          }
        }
      }
    }

    closedir(IMD);
    return;
    }

2nd alternative for lists with -admin in the name
=================================================

Another way of dealing with lists with -admin in the name is to have a
router to catch the list before the mailman router. e.g.: use the
transport from the 1st example and then

router
------

    mailman_pre:
      driver = accept
      debug_print = "D: mailman for $local_part@$domain"
      domains = CONFDIR/mailman_domains
      require_files = /var/lib/mailman/lists/$local_part/config.pck
      retry_use_local_part
      transport = mailman

    mailman:
      driver = accept
      debug_print = "D: mailman for $local_part@$domain"
      domains = CONFDIR/mailman_domains
      local_part_suffix = -bounces : -bounces+* : \
                                      -confirm+* : -join : -leave : \
                                      -owner : -request : -admin
      require_files = /var/lib/mailman/lists/$local_part/config.pck
      retry_use_local_part
      transport = mailman

    bounce_mailman:
      driver = redirect
      allow_defer
      allow_fail
      data = :fail: Unknown user
      debug_print = "D: bounce_mailman for $local_part@$domain"
      domains = CONFDIR/mailman_domains
      retry_use_local_part
      # this director bounces all mail from a mailman domain that hasn't been
      # picked up by the mailman director

The mailman\_pre route will catch the listnames including \*-admin
lists, while the mailman router will deal with all the administrative
requests.
