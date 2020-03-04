This article was taken as a basis: https://github.com/Exim/exim/wiki/SimpleGreylisting. 

If you use mysql to store users, you can use it for greylisting.

Below is a working example of greylisting working with Mysql, with cleaning old records using Exim itself.

Create 2 new tables in database, used for store users:

CREATE TABLE `greylist` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Record ID',
  `msgid` varchar(150) NOT NULL DEFAULT '' COMMENT 'Message ID',
  `expire` int(11) DEFAULT NULL COMMENT 'Record Expiry time',
  `host` varchar(150) NOT NULL COMMENT 'Original IP address',
  `helo` varchar(150) NOT NULL COMMENT 'Original HELO',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COMMENT='Greylisted mail';

CREATE TABLE `resenders` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Record ID',
  `host` varchar(150) NOT NULL DEFAULT '' COMMENT 'IP address',
  `helo` varchar(150) NOT NULL DEFAULT '' COMMENT 'HELO name',
  `added` int(11) NOT NULL COMMENT 'Record add time',
  `updated` int(11) NOT NULL COMMENT 'Record update time',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COMMENT='Known resenders';

Edit exim.conf and add:

# delete entries from greylist table, older than 14 days
GREYLIST_CLEAN = DELETE FROM `greylist` WHERE (`expire` < UNIX_TIMESTAMP(DATE_ADD(now(),INTERVAL -14 DAY)))

# update entries in resenders table
GREYLIST_UPDATE = UPDATE `resenders` SET `updated` = UNIX_TIMESTAMP(now()) WHERE `helo` = '${quote_mysql:$sender_helo_name}' AND `host` = '$sender_host_address'}

# delete entries from table resenders, not updated 90 days
GREYLIST_DELETE = DELETE FROM `resenders` WHERE (`updated` < UNIX_TIMESTAMP(DATE_ADD(now(),INTERVAL -90 DAY)))

#================================================================================================
# ACL: GREYLIST
#================================================================================================
greylist_mail:

# Clean greylist records at 00 and 30 of all day minutes
  warn
        condition       = ${if or {{eq {${substr{10}{2}{$tod_zulu}}}{00}}{eq {${substr{10}{2}{$tod_zulu}}}{30}}}{yes}{no}}
        set acl_m3      = ${lookup mysql{GREYLIST_CLEAN}}
        set acl_m4      = ${lookup mysql{GREYLIST_DELETE}}
        logwrite        = Old entries was deleted from the greylist tables.

# Accept if message was generated locally
  accept
        hosts           = +relay_from_hosts : +wl_hosts

# Accept if message was sent by authenticated clients
#  accept
#       authenticated   = *

# Accept mail from hosts which are known to resend their mail.
  accept
        condition       = ${lookup mysql{SELECT `host` FROM `resenders` WHERE `helo` = '${quote_mysql:$sender_helo_name}' AND `host` = '$sender_host_address'} {1}}
        set acl_m5      = ${lookup mysql{GREYLIST_UPDATE}}

# Generate a hashed 'identity' for the mail, as described above.
  warn
        set acl_m_greyident = ${hash{20}{62}{$sender_address$recipients$h_message-id:}}

# Attempt to look up this mail in the greylist database. If it's there, remember
# the expiry time for it; we need to make sure they've waited long enough.
  warn
        set acl_m_greyexpiry = ${lookup mysql{SELECT `expire` FROM `greylist` WHERE `msgid` = '${quote_mysql:$acl_m_greyident}'}{$value}}

# If there's absolutely nothing suspicious about the email, accept it. BUT...
  accept
        condition       = ${if eq {$acl_m_greylistreasons}{} {1}}
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}

# ..if this same mail was greylisted before (perhaps because it came from a
# host which *was* suspicious), then we still want to mark that original host
# as a "known resender". If we don't, then hosts which attempt to deliver from
# a dodgy Legacy IP address but then fall back to using IPv6 after greylisting
# will *never* see their Legacy IP address added to the 'known resenders' list.
  accept
        condition       = ${if eq {$acl_m_greylistreasons}{} {1}}
        acl             = write_known_resenders

# If the mail isn't already the database -- i.e. if the $acl_m_greyexpiry
# variable we just looked up is empty -- then try to add it now. This is
# where the 15 minute timeout is set ($tod_epoch + 900), should you wish
# to change it.
  warn
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}
        set acl_m_dontcare = ${lookup mysql{INSERT INTO `greylist` ( `msgid`, `expire`, `host`, `helo` )  VALUES ( '$acl_m_greyident', '${eval10:$tod_epoch+900}', '$sender_host_address', '${quote_mysql:$sender_helo_name}' )}}

# Be paranoid, and check if the insertion succeeded (by doing another lookup).
# Otherwise, if there's a database error we might end up deferring for ever.
  defer
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}
        condition       = ${lookup mysql{SELECT `expire` FROM `greylist` WHERE msgid = '${quote_mysql:$acl_m_greyident}'} {1}}
        message         = Greylisted: ${sg {$acl_m_greylistreasons}{\n}{ }}

# Handle the error case (which should never happen, but would be bad if it did).
# First by whining about it in the logs, so the admin can deal with it...
  warn
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}
        log_message     = Greylist insertion failed. Bypassing greylist.

# ... and then by just accepting the message.
  accept
        condition       = ${if eq {$acl_m_greyexpiry}{} {1}}

# OK, we've dealt with the "new" messages. Now we deal with messages which _were_ already in the database...

# If the message was already listed but its time hasn't yet expired, keep rejecting it
  defer
        condition       = ${if > {$acl_m_greyexpiry}{$tod_epoch}}
        message         = Greylisted: greylisting in progress... retry after ${eval10:$acl_m_greyexpiry-$tod_epoch} seconds

  accept
        acl             = write_known_resenders

# The message was listed but it's been more than five minutes. Accept it now and whitelist
# the _original_ sending host by its { IP, HELO } so that we don't delay its mail again.
write_known_resenders:
  warn
        set acl_m_orighost      = ${lookup mysql{SELECT `host` FROM `greylist` WHERE `msgid` = '${quote_mysql:$acl_m_greyident}'}{$value}}
        set acl_m_orighelo      = ${lookup mysql{SELECT `helo` FROM `greylist` WHERE `msgid` = '${quote_mysql:$acl_m_greyident}'}{$value}}
        set acl_m_dontcare      = ${lookup mysql{INSERT INTO `resenders` (`host`, `helo`, `added`, `updated`) VALUES ( '$acl_m_orighost', '${quote_mysql:$acl_m_orighelo}', '$tod_epoch', '$tod_epoch' ) }}
        logwrite                = Added host $acl_m_orighost with HELO '$acl_m_orighelo' to known resenders

  accept
