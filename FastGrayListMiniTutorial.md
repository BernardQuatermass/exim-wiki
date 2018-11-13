Fast Gray List Mini Tutorial (MySQL Edition)
============================================

Taken from exim-users [EximMailingLists](EximMailingLists) posting by
Silmar A. Marca in
[http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20050131/msg00147.html](http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20050131/msg00147.html)

Introduction
------------

This is based (but modified) on the tutorial written by Tor Slettnes,
which essentially incorporates the stuff from
[http://johannes.sipsolutions.net/Projects/exim-greylist](http://johannes.sipsolutions.net/Projects/exim-greylist).

I have a tested implementation of modify graylist simplest: this gray
list compare only domain of sender and a mask/24 of sender to domain of
rcpt. Have a auto clean of gray list old recordes...

The configuration files has in [ConfigurationFile](ConfigurationFile)
session.

It is a fast gray list and work!!!

It is a MYSQL implementation. If you use PostreSQL, try see
[http://wiki.exim.org/FastGrayListMiniTutorialPGSQL](http://wiki.exim.org/FastGrayListMiniTutorialPGSQL)
session.

MySQL Table Definition
----------------------

    #Create Sql BD
    CREATE TABLE `greylist` (
      `id` bigint(20) NOT NULL auto_increment,
      `relay_ip` varchar(20) default NULL,
      `sender_type` enum('NORMAL','BOUNCE') NOT NULL default 'NORMAL',
      `sender` varchar(150) default NULL,
      `recipient` varchar(150) default NULL,
      `block_expires` datetime NOT NULL default '0000-00-00 00:00:00',
      `record_expires` datetime NOT NULL default '9999-12-31 23:59:59',
      `create_time` datetime NOT NULL default '0000-00-00 00:00:00',
      `TYPE` enum('AUTO','MANUAL') NOT NULL default 'MANUAL',
      `passcount` bigint(20) NOT NULL default '0',
      `last_pass` datetime NOT NULL default '0000-00-00 00:00:00',
      `blockcount` bigint(20) NOT NULL default '0',
      `last_block` datetime NOT NULL default '0000-00-00 00:00:00',
      PRIMARY KEY  (`id`),
      UNIQUE KEY `relay_ip` (`relay_ip`,`sender`,`recipient`,`sender_type`),
      KEY `sender` (`sender`),
    ) TYPE=MyISAM COMMENT='GrayList ';
    #Only for debug (optional)
    CREATE TABLE `greylist_log` (
      `id` bigint(20) NOT NULL auto_increment,
      `listid` bigint(20) NOT NULL default '0',
      `timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
      `kind` enum('deferred','accepted') NOT NULL default 'deferred',
      PRIMARY KEY  (`id`)
    ) TYPE=MyISAM COMMENT='GrayList Log';

Exim Config File Definitions
----------------------------

First section of the config file.

    #Exim.conf file (only enabled if Mysql is enabled...)
    .ifdef MYSQL_SERVER
     GREYLIST_ENABLED_GREY          = yes
     # GREYLIST_ENABLED_LOG         = yes
     GREYLIST_INITIAL_DELAY         = 12 MINUTE
     GREYLIST_INITIAL_LIFETIME      = 4 HOUR
     GREYLIST_WHITE_LIFETIME        = 36 DAY
     GREYLIST_BOUNCE_LIFETIME       = 7 DAY
     GREYLIST_RECORD_LIFETIME       = 3 DAY
     GREYLIST_CLEAR_LIFETIME        = 90 0:0:0
     GREYLIST_TABLE                 = greylist
     GREYLIST_LOG_TABLE             = greylist_log
    .endif
    #....

      .ifdef GREYLIST_ENABLED_GREY
        GREYLIST_TEST      = SELECT CASE WHEN now() > block_expires \
                                THEN "accepted" \
                                ELSE "deferred" END AS result, \
                                id FROM GREYLIST_TABLE \
                                WHERE (now() < record_expires) \
                                AND (sender_type = ${if def:sender_address_domain{'NORMAL'}{'BOUNCE'}}) \
                                AND (sender      = '${quote_mysql:${if def:sender_address_domain{$sender_address_domain}{${domain:$h_from:}} }}') \
                                AND (recipient   = '${quote_mysql:${if def:domain{$domain}{${domain:$h_to:}} }}') \
                                AND (relay_ip    = '${quote_mysql:${mask:$sender_host_address/24}}') \
                                ORDER BY result DESC \
                                LIMIT 1
        GREYLIST_ADD        = REPLACE INTO GREYLIST_TABLE (relay_ip, sender_type, sender, recipient, block_expires, record_expires, create_time, type) \
                                VALUES ( '${quote_mysql:${mask:$sender_host_address/24}}', \
                                    ${if def:sender_address_domain{'NORMAL'}{'BOUNCE'}}, \
                                    '${quote_mysql:${if def:sender_address_domain{$sender_address_domain}{${domain:$h_from:}} }}', \
                                    '${quote_mysql:${if def:domain{$domain}{${domain:$h_to:}} }}', \
                                    DATE_ADD(now(), INTERVAL GREYLIST_INITIAL_DELAY), \
                                    DATE_ADD(now(), INTERVAL GREYLIST_INITIAL_LIFETIME), \
                                    now(), \
                                    'AUTO' )
        GREYLIST_DEFER_HIT  = UPDATE GREYLIST_TABLE \
                                SET blockcount=blockcount+1, \
                                    last_block=now() \
                                WHERE id = $acl_m9
        GREYLIST_OK_COUNT   = UPDATE GREYLIST_TABLE \
                                SET passcount=passcount+1, \
                                    last_pass=now() \
                                WHERE id = $acl_m9
        GREYLIST_OK_NEWTIME = UPDATE GREYLIST_TABLE \
                                SET record_expires = DATE_ADD(now(), \
                                    INTERVAL GREYLIST_WHITE_LIFETIME) \
                                WHERE id = $acl_m9 AND type='AUTO'
        GREYLIST_OK_BOUNCE  = UPDATE GREYLIST_TABLE \
                                SET record_expires = DATE_ADD(now(), \
                                    INTERVAL GREYLIST_BOUNCE_LIFETIME) \
                                WHERE id = $acl_m9 \
                                    AND type='AUTO'
        GREYLIST_CLEAN      = DELETE FROM greylist \
                                WHERE (record_expires < SUBTIME(NOW(),'GREYLIST_CLEAR_LIFETIME')) \
                                     AND (type='AUTO')
        GREYLIST_LOG        = INSERT INTO GREYLIST_LOG_TABLE (listid, timestamp, kind) \
                                VALUES ($acl_m9, now(), '$acl_m8')   
      .endif
    #...

Greylist ACL
------------

    #-GreyList (before rcpt and data):
    .ifdef GREYLIST_ENABLED_GREY
     greylist_acl:
     # clean greylist records at 00 and 30 of all day minutos
      warn  condition       = ${if or {{eq {${substr{10}{2}{$tod_zulu}} }{00}}{eq {${substr{10}{2}{$tod_zulu}} }{30}} }{yes}{no}}
            set acl_m4      = ${lookup mysql{GREYLIST_CLEAN}}

      # For regular deliveries, check greylist.

      # check greylist tuple, returning "accepted", "deferred" or "unknown"
      # in acl_m8, and the record id in acl_m9

      warn set acl_m8       = ${lookup mysql{GREYLIST_TEST}{$value}{result=unknown}}
           # here acl_m8 = "result=x id=y"

           set acl_m9       = ${extract{id}{$acl_m8}{$value}{-1}}
           # now acl_m9 contains the record id (or -1)

           set acl_m8       = ${extract{result}{$acl_m8}{$value}{unknown}}
           # now acl_m8 contains unknown/deferred/accepted

      # check if we know a certain triple, add and defer message if not
      accept
           # if above check returned unknown (no record yet)
           condition        = ${if eq {$acl_m8} {unknown} {yes}}
           # then also add a record
           condition        = ${lookup mysql{GREYLIST_ADD}{yes}{no}}

      # now log, no matter what the result was
      # if the triple was unknown, we don't need a log entry
      # (and don't get one) because that is implicit through
      # the creation time above.
      .ifdef GREYLIST_ENABLED_LOG
      warn condition        = ${lookup mysql{GREYLIST_LOG}}
      .endif

      # check if the triple is still blocked
      accept
           # if above check returned deferred then defer
           condition        = ${if eq{$acl_m8} {deferred} {yes}}
           # and note it down
           condition        = ${lookup mysql{GREYLIST_DEFER_HIT}{yes}{yes}}

      # use a warn verb to count records that were hit
      warn condition        = ${lookup mysql{GREYLIST_OK_COUNT}}

      # use a warn verb to set a new expire time on automatic records,
      # but only if the mail was not a bounce, otherwise set to now().
      warn !senders         = : postmaster@* : Mailer-Daemon@*
           condition        = ${lookup mysql{GREYLIST_OK_NEWTIME}}
      warn senders          = : postmaster@* : Mailer-Daemon@*
           condition        = ${lookup mysql{GREYLIST_OK_BOUNCE}}
      deny
    .endif
    #....

Check RCPT ACL
--------------

    acl_check_rcpt:
      #....<put is in end of rcpt acl, before accept clause. Please comment spf clause if not compile it>
        .ifdef GREYLIST_ENABLED_GREY
        defer hosts         = !+relay_from_hosts
            senders = !:
            !authenticated  = *
            !spf            = pass
            !hosts      = ${lookup dnsdb{>: defer_never,mxh=$sender_address_domain}}
            acl             = greylist_acl
            message         = GreyListed: please try again later
            logwrite        = :reject:
            delay          = 15s
       .endif
       <the end clause accept is here>
    #....

Check DATA ACL
--------------

    acl_check_data:
      #....<put is in end of data acl, before accept clause>
       .ifdef GREYLIST_ENABLED_GREY
       defer  !spf           = pass
             condition      = ${if eq {${domain:$h_from:}}{$sender_address_domain}{no}{yes}}
             !hosts         = ${lookup dnsdb{>: defer_never,mxh=${domain:$h_from:}} }
             acl            = greylist_acl
             message        = GreyListed: please try again later
             logwrite       = :reject:
             delay          = 15s
       .endif
       <the end clause accept is here>

* * * * *

Although rare, some "legitimate" bulk mail senders, such as
groups.yahoo.com, will not retry temporarily failed deliveries. The
problem skip if have a spf TXT in dns of domain. Evan Harris has
compiled a list of such senders, suitable for whitelisting purposes

The list is avaliable here
[http://cvs.puremagic.com/viewcvs/greylisting/schema/whitelist\_ip.txt?view=markup](http://cvs.puremagic.com/viewcvs/greylisting/schema/whitelist_ip.txt?view=markup)

**Comment:** You might want to use an unsigned integer for ip storage,
which is more effective especially when you are creating an index over
the ip column, which i would recommend as it makes the hole thing faster
(note that comparing integer values is faster than comparing string
values). PostgreSQL also offers a special data type for ip Adress
storage. In MySQL, you can convert an ip adress to an integer using the
INET\_ATON() function. This doesn't support subnet masks, but I don't
see a real point in graylisting a whole /24 network which may also
consist of some spambots.

If you having multiple MX Servers, please note that these servers should
exchange the graylist information so that delivery does not get deferred
on every Server. This can for example be done using the MySQL NDBCluster
Engine.

[CategoryHowTo](CategoryHowTo)
