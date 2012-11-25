Simple Greylisting, with working example for Exim
=================================================

Introduction
------------

This page introduces the concepts behind greylisting in a way that's
applicable to **all** MTAs, and then gives a simple but full-featured
implementation implemented entirely within Exim without needing to call
out to external programs or run embedded Perl. Exim is perfectly capable
of doing all this for itself; all you need is a version of Exim with
sqlite3 support built in (or any other database if you prefer, but
sqlite is nice and simple and doesn't require an external database
server; it's all built in).

Principles of greylisting
-------------------------

The basic idea behind greylisting is that virus and spam bots often
don't bother to try again, if they fail to deliver a message on the
first attempt. They'll just drop that victim and move onto the next. A
*genuine* mail server, on the other hand, will respond to a temporary
failure by queueing the mail and trying it again later.

What we call "greylisting" is the practice of using this fact to avoid
receiving mail from spam bots. The first time we see an email, we
generate a temporary failure. If we ever see that email *again*, only
then do we accept it.

(Actually, we don't accept it if it's tried again *immediately*; we make
them wait at least a few minutes before they retry.)

Problems with greylisting
-------------------------

There are a few potential issues with greylisting. One problem is that
some "genuine" mail servers might be broken in the same way as we expect
the spam bots to be – they might actually give up and fail completely
when we give them the *temporary* failure report. Thankfully, such mail
servers are extremely rare – since greylisting is quite common now,
they've mostly been fixed already.

Another potential problem is that greylisting can delay urgent incoming
mail that you're waiting for. There are some simple and obvious ways to
alleviate this:
-   Remember which hosts actually *do* retry, and never delay mail from
    those hosts in future.
-   Only delay mails which actually look suspicious in some way; don't
    just delay everything blindly.
-   Avoid greylisting for hosts on the [DNS
    Whitelist](http://www.dnswl.org/) database.

These two rules go a long way towards addressing the 'delay' problem,
but obviously can't deal with it completely. If you absolutely require
*immediate* delivery of all mail, even spammy-looking HTML crap from
people you've never received mail from before, then greylisting is not
for you.

Note that you can define your own rules for what mail is considered
'suspicious' and what isn't, and define your own rules for bypassing the
greylist too (for example, avoid greylisting if your sales@ address is
one of the recipients). But do be aware of what you're doing.

Requirements
------------

So, bearing in mind the above concerns, here's what we want a
greylisting implementation to do:
-   Look at incoming mail, decide whether it's "suspicious" or not.
-   If it's not suspicious, just accept it.
-   If it's from a mail host which has previously been observed to
    retry, just accept it.
-   If this mail has already been seen (we greylisted it before), and if
    the required time has elapsed, then accept it.
-   So it's a suspicious mail we haven't seen before, from a mail server
    which isn't known to retry sending. Remember it in a simple database
    somehow, and reject it with a *temporary* failure (4xx error code).

Databases
---------

To support the above, you need two really simple databases. So simple
that they can even be done as text files. In fact, my original
implementation really did use text files, but now I use Exim's built-in
SQLite support. To use an external database server for it would be
overkill, unless you already have one for other reasons (in which case
you're probably quite capable of switching this example over to your
preferred database).

### Known resenders

Firstly, there's the database of "known resenders", which lists the
hosts that are known to retry sending mail. We need to avoid greylisting
mail from these hosts; since they're *known* to retry, we know that it
would only introduce a pointless delay, without actually giving any
benefit.

To remember a host, I use a combination of both its IP address *and* the
name it uses in its `HELO` greeting. Using the `HELO` name in addition
to the IP address means that you can more easily distinguish between
various hosts behind the same NAT, or different machines which end up
with the same dynamic IP address at different times. The `resenders`
table looks like this:

[Table not converted]

We record the time that the host was added to the `resenders` table, in
case we later decide that we want to expire old entries. I haven't found
an overriding reason to expire such entries so far, but I have the
information in case I later want to.

### Greylisted mail

The second database we need is the one which keeps details of the mail
itself, so that we can recognise it when we later see the same mail
again. Firstly, we generate an 'ID' for the mail. This is a hash of the
sender address, the recipient addresses, and the `Message-Id:` header of
the mail. We *don't* include the sending host in this ID, because often
we'll find that the mail is tried again from a *different* address on
the second attempt; we don't want it to fail to match when that happens.

We do, however, store the IP address and the name used in `HELO` for the
original submission. It's those which will be added into the `resenders`
table if/when the mail is later accepted after a retry.

We also store the time after which the mail will be accepted. We don't
always accept mail on the second attempt; we make them wait at least a
few minutes, so that an *immediate* retry doesn't succeed. They actually
have to queue it and try again later. That's why we have to store the
timestamp. So the `greylist` table looks like this:

[Table not converted]

Exim Implementation (users of other MTAs can stop now)
------------------------------------------------------

### Creating the SQLite file

First you need to create the SQLite database which will contain the
above tables. You can do this with the `sqlite3` command, and then
ensure that it's owned by the Exim user/group:

    # sqlite3 /var/spool/exim/db/greylist.db <<EOF
    CREATE TABLE resenders (
            host            TEXT,
            helo            TEXT,
            time            INTEGER,
        PRIMARY KEY (host, helo)
    );

    CREATE TABLE greylist (
            id              TEXT PRIMARY KEY,
            expire          INTEGER,
            host            TEXT,
            helo            TEXT
    );
    EOF
    # chown exim.exim /var/spool/exim/db/greylist.db

### Greylisting ACL 'subroutine'

This is the ACL code which implements greylisting. You shouldn't have to
look too hard at this; you can just paste it into your configuration
file or include it with Exim's `.include` directive. Instructions on
setting it up and using it are given below.

    # $Id: acl-greylist-sqlite,v 1.3 2007/11/25 19:17:28 dwmw2 Exp $

    GREYDB=/var/spool/exim/db/greylist.db

    # ACL for greylisting. Place reason(s) for greylisting into a variable named
    # $acl_m_greylistreasons before invoking with 'require acl = greylist_mail'.
    # The reasons should be separate lines of text, and will be reported in
    # the SMTP rejection message as well as the log message.
    #
    # When a suspicious mail is seen, we temporarily reject it and wait to see
    # if the sender tries again. Most spam robots won't bother. Real mail hosts
    # _will_ retry, and we'll accept it the second time. For hosts which are
    # observed to retry, we don't bother greylisting again in the future --
    # it's obviously pointless. We remember such hosts, or 'known resenders',
    # by a tuple of their IP address and the name they used in HELO.
    #
    # We also include the time of listing for 'known resenders', just in case
    # someone wants to expire them after a certain amount of time. So the
    # database table for these 'known resenders' looks like this:
    #
    # CREATE TABLE resenders (
    #        host            TEXT,
    #        helo            TEXT,
    #        time            INTEGER,
    #    PRIMARY KEY (host, helo) );
    #
    # To remember mail we've rejected, we create an 'identity' from its sender
    # and recipient addresses and its Message-ID: header. We don't include the
    # sending IP address in the identity, because sometimes the second and
    # subsequent attempts may come from a different IP address to the original.
    #
    # We do record the original IP address and HELO name though, because if
    # the message _is_ retried from another machine, it's the _first_ one we
    # want to record as a 'known resender'; not just its backup path.
    #
    # Obviously we record the time too, so the main table of greylisted mail
    # looks like this:
    #
    # CREATE TABLE greylist (
    #        id              TEXT,
    #        expire          INTEGER,
    #        host            TEXT,
    #        helo            TEXT);
    #

    greylist_mail:
      # Firstly,  accept if it was generated locally or by authenticated clients.
      accept hosts = :
      accept authenticated = *

      # Secondly, there's _absolutely_ no point in greylisting mail from
      # hosts which are known to resend their mail. Just accept it.
      accept condition = ${lookup sqlite {GREYDB SELECT host from resenders \
                                   WHERE helo='${quote_sqlite:$sender_helo_name}' \
                                   AND host='$sender_host_address';} {1}}

      # Generate a hashed 'identity' for the mail, as described above.
      warn set acl_m_greyident = ${hash{20}{62}{$sender_address$recipients$h_message-id:}}

      # Attempt to look up this mail in the greylist database. If it's there,
      # remember the expiry time for it; we need to make sure they've waited
      # long enough.
      warn set acl_m_greyexpiry = ${lookup sqlite {GREYDB SELECT expire FROM greylist \
                                    WHERE id='${quote_sqlite:$acl_m_greyident}';}{$value}}

      # If there's absolutely nothing suspicious about the email, accept it. BUT...
      accept condition = ${if eq {$acl_m_greylistreasons}{} {1}}
             condition = ${if eq {$acl_m_greyexpiry}{} {1}}

      # ..if this same mail was greylisted before (perhaps because it came from a
      # host which *was* suspicious), then we still want to mark that original host
      # as a "known resender". If we don't, then hosts which attempt to deliver from
      # a dodgy Legacy IP address but then fall back to using IPv6 after greylisting
      # will *never* see their Legacy IP address added to the 'known resenders' list.
      accept condition = ${if eq {$acl_m_greylistreasons}{} {1}}
             acl = write_known_resenders

      # If the mail isn't already the database -- i.e. if the $acl_m_greyexpiry
      # variable we just looked up is empty -- then try to add it now. This is
      # where the 5 minute timeout is set ($tod_epoch + 300), should you wish
      # to change it.
      warn  condition = ${if eq {$acl_m_greyexpiry}{} {1}}
            set acl_m_dontcare = ${lookup sqlite {GREYDB INSERT INTO greylist \
                                            VALUES ( '$acl_m_greyident', \
                                                     '${eval10:$tod_epoch+300}', \
                                                     '$sender_host_address', \
                                                     '${quote_sqlite:$sender_helo_name}' );}}

      # Be paranoid, and check if the insertion succeeded (by doing another lookup).
      # Otherwise, if there's a database error we might end up deferring for ever.
      defer condition = ${if eq {$acl_m_greyexpiry}{} {1}}
            condition = ${lookup sqlite {GREYDB SELECT expire FROM greylist \
                                    WHERE id='${quote_sqlite:$acl_m_greyident}';} {1}}
            message = Your mail was considered suspicious for the following reason(s):\n$acl_m_greylistreasons \
                      The mail has been greylisted for 5 minutes, after which it should be accepted. \
                      We apologise for the inconvenience. Your mail system should keep the mail on \
                      its queue and retry. When that happens, your system will be added to the list \
                      genuine mail systems, and mail from it should not be greylisted any more. \
                      In the event of problems, please contact postmaster@$qualify_domain
            log_message = Greylisted <$h_message-id:> from <$sender_address> for offences: ${sg {$acl_m_greylistreasons}{\n}{,}}

      # Handle the error case (which should never happen, but would be bad if it did).
      # First by whining about it in the logs, so the admin can deal with it...
      warn   condition = ${if eq {$acl_m_greyexpiry}{} {1}}
             log_message = Greylist insertion failed. Bypassing greylist.
      # ... and then by just accepting the message.
      accept condition = ${if eq {$acl_m_greyexpiry}{} {1}}

      # OK, we've dealt with the "new" messages. Now we deal with messages which
      # _were_ already in the database...

      # If the message was already listed but its time hasn't yet expired, keep rejecting it
      defer condition = ${if > {$acl_m_greyexpiry}{$tod_epoch}}
            message = Your mail was previously greylisted and the time has not yet expired.\n\
                      You should wait another ${eval10:$acl_m_greyexpiry-$tod_epoch} seconds.\n\
                      Reason(s) for greylisting: \n$acl_m_greylistreasons

      accept acl = write_known_resenders

    write_known_resenders:
      # The message was listed but it's been more than five minutes. Accept it now and whitelist
      # the _original_ sending host by its { IP, HELO } so that we don't delay its mail again.
      warn set acl_m_orighost = ${lookup sqlite {GREYDB SELECT host FROM greylist \
                                    WHERE id='${quote_sqlite:$acl_m_greyident}';}{$value}}
           set acl_m_orighelo = ${lookup sqlite {GREYDB SELECT helo FROM greylist \
                                    WHERE id='${quote_sqlite:$acl_m_greyident}';}{$value}}
           set acl_m_dontcare = ${lookup sqlite {GREYDB INSERT INTO resenders \
                                    VALUES ( '$acl_m_orighost', \
                                             '${quote_sqlite:$acl_m_orighelo}', \
                                             '$tod_epoch' ); }}
           logwrite = Added host $acl_m_orighost with HELO '$acl_m_orighelo' to known resenders

      accept

### Setting the conditions for "suspicious" mail

Now, it's up to you what you consider to be "suspicious", to trigger
greylisting. Remember, you can be very much stricter with these
decisions than you can with things that you're actually going to
*reject* mail for. My rules cover things like "is HTML", "has more than
0.1 [SpamAssassin](SpamAssassin) points", "Has Re: in Subject but no
References: header". Yours can be whatever you like.

Whatever your rules are, when they trigger you should add a line to the
`$acl_m_greylistreasons` variable. When this rule is non-empty, the
greylisting routing will kick in and do its thing (at least, it will
after you follow the instructions a little further down the page, where
you hook it into your DATA ACL).

Here are some examples of how you might do this for various triggers;
you can come up with your own...

MIME errors (in DATA ACL):

    warn  message = X-MIME-Error: $demime_reason
          demime = *
          condition = ${if >{$demime_errorlevel}{0}{1}{0}}
          set acl_m_greylistreasons = Message has MIME error: $demime_reason\n$acl_m_greylistreasons

Fake replies (DATA ACL):

    warn  condition = ${if and {                                  \
                          {match {${lc:$h_subject:}}{^re:}}       \
                          {!def:h_References:}                    \
                          {!def:h_In-Reply-To:}                   \
                       } {1}{0}}
          message = X-Bad-Reply: 'Re:' in Subject but no References or In-Reply-To headers
          set acl_m_greylistreasons = Message has 'Re:' in Subject: but neither References: nor In-Reply-To:\n$acl_m_greylistreasons

No `Message-Id:` header (DATA ACL):

    warn condition = ${if !def:h_Message-ID: {1}}
          set acl_m_greylistreasons = Message has no Message-Id: header\n$acl_m_greylistreasons

Non-zero [SpamAssassin](SpamAssassin) points (in DATA ACL, after
invoking SA of course):

    warn condition = ${if >{$spam_score_int}{0} {1}}
         set acl_m_greylistreasons = Message has $spam_score SpamAssassin points\n$acl_m_greylistreasons

Sending host in DNS blacklist (MAIL, RCPT or DATA ACL):

    warn dnslists = psbl.surriel.org
         set acl_m_greylistreasons = Host listed in $dnslist_domain blacklist: $dnslist_text\n$acl_m_greylistreasons

HTML mail (MIME ACL):

    warn !condition = $mime_is_rfc822
          condition = $mime_is_coverletter
          condition = ${if eq{$mime_content_type}{text/html} {1}}
          set acl_m_greylistreasons = Message appears to have HTML content, not just plain text.\n$acl_m_greylistreasons

And finally an example of how to *disable* greylisting based on some
trigger. Put these *after* anything else which might set the
`$acl_m_greylistreasons` variable:

    warn  senders = boss@bigcorp.com
          set acl_m_greylistreasons =

    warn dnslists = list.dnswl.org
         set acl_m_greylistreasons =

### Invoking the greylist ACL

The last thing you need to do in your Exim configuration is make it
actually call the `acl_greylist` 'subroutine' given above. Having
processed the mail and decided whether to set the
`$acl_m_greylistreasons` variable, you can invoke the greylisting code
by putting this at the end of your `acl_smtp_data` ACL:

    require acl = greylist_mail

### Tidying the database

To prevent the database from growing forever without bound, we something
simple to expire old entries from the `greylist` table. All you need to
do is run something like this from cron, daily:

    if [ -r /var/spool/exim/db/greylist.db ]; then
        sqlite3 /var/spool/exim/db/greylist.db <<EOF
    .timeout 5000
    DELETE FROM greylist WHERE expire < strftime('%s', 'now', '-14 days');
    EOF
    fi

Other tips
----------

### Manually inserting a 'known resender'

If you know of a problematic host which doesn't correctly handle a
temporary failure, then the first thing to do is make sure the person
responsible for that machine is aware of the problem. They'll be
throwing away genuine mail a lot of the time; not only when their
recipients are using greylisting. But having done that, you can also
manually add the host to the 'known resenders' table, if you know the IP
address and the name it will use in its `HELO` greeting. For example:

    sqlite3 /var/spool/exim/db/greylist.db "REPLACE INTO resenders VALUES('127.0.0.1', 'localhost', strftime('%s', 'now'));"

### Sharing resenders database between hosts

Sometimes it's useful to copy your list of "known resenders" from one
machine to another. Perhaps you're installing a new mail server, or just
want to make sure that your secondary MX host is kept up to date with a
list of the machines which your primary MX has observed to retry mail.
This simple script will ensure that all entries on one machine are
present in the database on another:

    if [ -z "$1" ]; then
            echo "need hostname"
            exit 1
    fi

    sqlite3 /var/spool/exim/db/greylist.db 'select * from resenders;' |
            sed 's/|/ /g' | while read IPADDR HOST STAMP ; do
                    echo  "replace into resenders values('$IPADDR','$HOST',$STAMP);";
            done |
    ssh  $1 sqlite3 /var/spool/exim/db/greylist.db

### Fedora package

This greylisting setup is available as a package for Fedora, called
`exim-greylist`. Installing the package will create the database for you
and install the cron job to expire old entries. All you need to do is
set up the conditions which set the `$acl_m_greylistreasons` variable
for suspicious mail, include the `/etc/exim/exim-greylist.conf.inc` file
into your configuration, then invoke it from your DATA ACL as shown
above.

### Statistics

The `greylist` database table lists every mail which was delayed by the
greylisting. When a mail is later retried and accepted, the host is
added to the `resenders` database table. So you can see how many mails
were actually rejected by greylisting, by comparing the two tables. This
query, for example, shows the number of mails which have *not* yet been
retried:

    SELECT COUNT(*) FROM greylist LEFT OUTER JOIN resenders ON (greylist.host = resenders.host AND greylist.helo = resenders.helo) WHERE resenders.host IS NULL;

*(Thanks for Simon Farnsworth for the above SQL query)*

Note that this may include mails from the last few minutes which have
not *yet* been retried, but which soon will be. It also includes
messages which may have been accepted by another of your MX hosts, if
you have more than one. So it's worth running the above script to share
the resenders table between hosts, before you take any statistics this
way.

This shell script reports statistics of the number of retried/unretried
mails for the *previous* day (to avoid confusion with mails which are
*currently* being greylisted, and will be retried soon).:

    DAY=$(($(date +%s)/86400))

    echo -n "Mails greylisted and not retried yesterday: "
    sqlite3 /var/spool/exim/db/greylist.db <<EOF
    SELECT COUNT(*) FROM greylist LEFT OUTER JOIN resenders ON
      (greylist.host = resenders.host AND greylist.helo = resenders.helo)
      WHERE resenders.host IS null
      AND greylist.expire > $(((DAY - 1) * 86400))
      AND greylist.expire <= $((DAY * 86400));
    EOF

    echo -n "Mails greylisted and then retried yesterday: "
    sqlite3 /var/spool/exim/db/greylist.db <<EOF
    SELECT COUNT(*) FROM greylist LEFT OUTER JOIN resenders ON
      (greylist.host = resenders.host AND greylist.helo = resenders.helo)
      WHERE resenders.host IS NOT null
      AND greylist.expire > $(((DAY - 1) * 86400))
      AND greylist.expire <= $((DAY * 86400));
    EOF
