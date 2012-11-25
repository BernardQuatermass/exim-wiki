Fast Gray List Mini Tutorial (PostreSQL Edition)
================================================

Derivate from [FastGrayListMiniTutorial](FastGrayListMiniTutorial)

SQL Table Definition
--------------------

    --
    -- Create Sql BD
    --
    CREATE TABLE greylist (
        id serial NOT NULL,
        relay_ip character varying(20),
        sender_type character varying(6) DEFAULT 'NORMAL'::character varying NOT NULL,
        sender character varying(150),
        recipient character varying(150),
        block_expires timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
        record_expires timestamp without time zone DEFAULT '9999-12-31 23:59:59'::timestamp without time zone NOT NULL,
        create_time timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
        "type" character varying(6) DEFAULT 'MANUAL'::character varying NOT NULL,
        passcount bigint DEFAULT 0::bigint NOT NULL,
        last_pass timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
        blockcount bigint DEFAULT 0::bigint NOT NULL,
        last_block timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
        CONSTRAINT greylist_sender_type_check CHECK ((((sender_type)::text = 'NORMAL'::text) OR ((sender_type)::text = 'BOUNCE'::text))),
        CONSTRAINT greylist_type_check CHECK (((("type")::text = 'AUTO'::text) OR (("type")::text = 'MANUAL'::text)))
    );
    --
    -- Only for debug (optional)
    --
    CREATE TABLE greylist_log (
        id serial NOT NULL,
        listid bigint DEFAULT 0::bigint NOT NULL,
        "timestamp" timestamp without time zone DEFAULT '0001-01-01 00:00:00'::timestamp without time zone NOT NULL,
        kind character varying(8) DEFAULT 'deferred'::character varying NOT NULL,
        CONSTRAINT greylist_log_kind_check CHECK ((((kind)::text = 'deferred'::text) OR ((kind)::text = 'accepted'::text)))
    );

Exim Config File Definitions
----------------------------

First section of the config file.

    #Exim.conf file (allways enabled because PgSQL is enabled... ;-)
    GREYLIST_ENABLED_GREY          = yes
    GREYLIST_ENABLED_LOG           = yes
    GREYLIST_INITIAL_DELAY         = 12 MINUTES
    GREYLIST_INITIAL_LIFETIME      = 4 HOURS
    GREYLIST_WHITE_LIFETIME        = 36 DAY
    GREYLIST_BOUNCE_LIFETIME       = 7 DAY
    GREYLIST_RECORD_LIFETIME       = 3 DAY
    GREYLIST_CLEAR_LIFETIME        = 90 DAY
    GREYLIST_TABLE                 = greylist
    GREYLIST_LOG_TABLE             = greylist_log
    #....
    .ifdef GREYLIST_ENABLED_GREY
      GREYLIST_TEST      = SELECT CASE WHEN now() > block_expires THEN 'accepted' \
                           ELSE 'deferred' END AS result, id FROM GREYLIST_TABLE \
                           WHERE now() < record_expires \
                           AND sender_type ILIKE ${if def:sender_address_domain{'NORMAL'}{'BOUNCE'}} \
                           AND sender      ILIKE '${quote_pgsql:${if def:sender_address_domain{$sender_address_domain}{${domain:$h_from:}} }}' \
                           AND recipient   ILIKE '${quote_pgsql:${if def:domain{$domain}{${domain:$h_to:}} }}' \
                           AND relay_ip    ILIKE '${quote_pgsql:${mask:$sender_host_address/24}}' \
                           ORDER BY result DESC LIMIT 1
      GREYLIST_ADD       = DELETE FROM greylist  WHERE relay_ip = '${quote_pgsql:${mask:$sender_host_address/24}}'; \
                           INSERT INTO greylist (relay_ip, sender_type, sender, recipient, block_expires, record_expires, create_time, type) VALUES \
                           ('${quote_pgsql:${mask:$sender_host_address/24}}', ${if def:sender_address_domain{'NORMAL'}{'BOUNCE'}}, \
                                       '${quote_pgsql:${if def:sender_address_domain{$sender_address_domain}{${domain:$h_from:}} }}', \
                                       '${quote_pgsql:${if def:domain{$domain}{${domain:$h_to:}} }}', \
                                       now() + 'GREYLIST_INITIAL_DELAY'::interval, now() + 'GREYLIST_INITIAL_LIFETIME'::interval,now(), 'AUTO');
      GREYLIST_DEFER_HIT = UPDATE GREYLIST_TABLE SET blockcount=blockcount+1, last_block=now() WHERE id = $acl_m9
      GREYLIST_OK_COUNT  = UPDATE GREYLIST_TABLE SET passcount=passcount+1, last_pass=now() WHERE id = $acl_m9
      GREYLIST_OK_NEWTIME = UPDATE GREYLIST_TABLE SET record_expires = now() + 'GREYLIST_WHITE_LIFETIME'::interval WHERE id = $acl_m9 AND type='AUTO'
      GREYLIST_OK_BOUNCE = UPDATE GREYLIST_TABLE SET record_expires = now() + 'GREYLIST_BOUNCE_LIFETIME'::interval WHERE id = $acl_m9 AND type='AUTO'
      GREYLIST_CLEAN     = DELETE FROM greylist WHERE (record_expires < now() - 'GREYLIST_CLEAR_LIFETIME'::interval) AND (type='AUTO')
      GREYLIST_LOG       = INSERT INTO GREYLIST_LOG_TABLE (listid, timestamp, kind) VALUES ($acl_m9, now(), '$acl_m8')
    .endif

Greylist ACL
------------

    #-GreyList (before rcpt and data):
    .ifdef GREYLIST_ENABLED_GREY
    greylist_acl:
      # clean expired greylist records at 00 and 30 of all day minutes
      warn  condition       = ${if or {{eq {${substr{10}{2}{$tod_zulu}} }{00}}{eq {${substr{10}{2}{$tod_zulu}} }{30}} }{yes}{no}}
            set acl_m4      = ${lookup pgsql{GREYLIST_CLEAN}}
            log_message     = clean expired greylist records

      # For regular deliveries, check greylist.

      # check greylist tuple, returning "accepted", "deferred" or "unknown"
      # in acl_m8, and the record id in acl_m9

      warn  set acl_m8       = ${lookup pgsql{GREYLIST_TEST}{$value}{result=unknown}}
            # here acl_m8 = "result=x id=y"
            set acl_m9       = ${extract{id}{$acl_m8}{$value}{-1}}
            # now acl_m9 contains the record id (or -1)
            set acl_m8       = ${extract{result}{$acl_m8}{$value}{unknown}}
            # now acl_m8 contains unknown/deferred/accepted
            log_message     = check greylist tuple, set '$acl_m8'

      # check if we know a certain triple, add and defer message if not
      accept
           # if above check returned unknown (no record yet)
           condition        = ${if eq {$acl_m8} {unknown} {yes}}
           # then also add a record
           condition        = ${lookup pgsql{GREYLIST_ADD}{yes}{no}}

      # now log, no matter what the result was
      # if the triple was unknown, we don't need a log entry
      # (and don't get one) because that is implicit through
      # the creation time above.
      .ifdef GREYLIST_ENABLED_LOG
      warn  condition        = ${lookup pgsql{GREYLIST_LOG}}
      .endif

      # check if the triple is still blocked
      accept
           # if above check returned deferred then defer
           condition        = ${if eq{$acl_m8} {deferred} {yes}}
           # and note it down
           condition        = ${lookup pgsql{GREYLIST_DEFER_HIT}{yes}{yes}}

      # use a warn verb to count records that were hit
      warn  condition        = ${lookup pgsql{GREYLIST_OK_COUNT}}

      # use a warn verb to set a new expire time on automatic records,
      # but only if the mail was not a bounce, otherwise set to now().
      warn  !senders         = : postmaster@* : Mailer-Daemon@*
            condition        = ${lookup pgsql{GREYLIST_OK_NEWTIME}}
      warn  senders          = : postmaster@* : Mailer-Daemon@*
            condition        = ${lookup pgsql{GREYLIST_OK_BOUNCE}}
      deny
    .endif

You may find all additional information in the original HOWTO

[CategoryHowTo](CategoryHowTo)
