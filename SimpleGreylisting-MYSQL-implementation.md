This is MYSQL (MariaDB) implementation of https://github.com/Exim/exim/wiki/SimpleGreylisting with auto clean greylist table.

MYSQL tables:

CREATE TABLE `greylist` (
  `id` varchar(150) NOT NULL DEFAULT '' COMMENT 'Message ID',
  `expire` int(11) DEFAULT NULL COMMENT 'Expiry time',
  `host` varchar(150) NOT NULL COMMENT 'Original IP address',
  `helo` varchar(150) NOT NULL COMMENT 'Original HELO',
   PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Greylisted mail';

CREATE TABLE `resenders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Record ID',
  `host` varchar(150) NOT NULL DEFAULT '' COMMENT 'IP address',
  `helo` varchar(150) NOT NULL DEFAULT '' COMMENT 'HELO name',
  `added` int(11) NOT NULL COMMENT 'Record add time',
  `updated` int(11) NOT NULL COMMENT 'Record update time',
   PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Known resenders';

exim config:

# Clearing greylist table
GREYLIST_CLEAN          = DELETE FROM `greylist` WHERE (`expire` < UNIX_TIMESTAMP(DATE_ADD(now(),INTERVAL -14 DAY)))

# Refresh records in resenders table
GREYLIST_UPDATE         = UPDATE `resenders` SET `updated` = UNIX_TIMESTAMP(now()) WHERE `helo` = '${quote_mysql:$sender_helo_name}' AND `host` = '$sender_host_address'}

# Delete from resenders expired records (> 90 days from last refresh)
GREYLIST_DELETE         = DELETE FROM `resenders` WHERE (`updated` < UNIX_TIMESTAMP(DATE_ADD(now(),INTERVAL -90 DAY)))

#ACL BLOCK GREYLIST
greylist_mail:
# Clean greylist records at 00 and 30 of all day minutes
  warn
        condition       = ${if or {{eq {${substr{10}{2}{$tod_zulu}}}{00}}{eq {${substr{10}{2}{$tod_zulu}}}{30}}}{yes}{no}}
        set acl_m3      = ${lookup mysql{GREYLIST_CLEAN}}
        set acl_m4      = ${lookup mysql{GREYLIST_DELETE}}
        logwrite        = Old entries was deleted from the greylist tables.

# Accept if message was generated locally
  accept
        hosts           = +relay_from_hosts

# Accept if message was sent by authenticated clients
  accept
       authenticated   = *

# Accept mail from hosts which are known to resend their mail.
  accept
        condition       = ${lookup mysql{SELECT `host` FROM `resenders` WHERE `helo` = '${quote_mysql:$sender_helo_name}' AND `host`='$sender_host_address'} {1}}
        set acl_m5      = ${lookup mysql{GREYLIST_UPDATE}}

# Generate a hashed 'identity' for the mail, as described above.
  warn
        set acl_m_greyident = ${hash{20}{62}{$sender_address$recipients$h_message-id:}}

# Attempt to look up this mail in the greylist database. If it's there, remember
# the expiry time for it; we need to make sure they've waited long enough.
  warn
        set acl_m_greyexpiry = ${lookup mysql{SELECT `expire` FROM `greylist` WHERE `id` = '${quote_mysql:$acl_m_greyident}'}{$value}}

# If there's absolutely nothing suspicious about the email, accept it. BUT...
  accept
        condition       = ${if eq {$acl_m_greylistreasons}{} {1}}
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}


#finally, at the end of data acl:
  warn
        set acl_m_greylistreasons = Sender is new to me\n$acl_m_greylistreasons

  require
        acl             = greylist_mail
