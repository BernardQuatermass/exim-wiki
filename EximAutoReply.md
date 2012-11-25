How To Do Autoreplies Without The World Hating You
==================================================

There is often a requirement for creating messages automatically, in
response to incoming mail. On a personal level, these are often called
"Out Of Office" (OoO) messages. Unix users may well refer to them as
"vacation" messages, from the traditional program that implemented the
functionality. Systems may automatically generate responses to incoming
mail too, perhaps acknowledgements for submissions to a Helpdesk or role
address.

For the purposes of this document, we refer to all automatically
generically response messages as "autoreplies".

Care needs to be taken when generating autoreplies. A system which
blindly autoreplies to any incoming message will likely annoy someone
and cause complaints. To take a simple case, much spam forges the sender
address to be that of an innocent third party. This third party may then
receive autoreplies from the system for messages they didn't send in the
first place. Imagine if a million spams were sent with their address
forged as the sender. As well as all the delivery failure reports, they
will receive many autoreply messages. This is collateral spam, or
backscatter.

The following resources may be informative:

> [JANET CSIRT advice on collateral
> spam](http://www.ja.net/services/csirt/advice/policies/collateral-spam.html)
>
> [Wikipedia page on Backscatter from
> email](http://en.wikipedia.org/wiki/Backscatter_(e-mail))

Many spam fighters are vociferous about inappropriate autoreply
mechanisms. Any autoreply mechanism must be carefully implemented to
minimise the risk of a system being penalised by others for being seen
as a source of backscatter.

Some autoreply systems implemented in commercial products are
particularly broken, in that they will reply to messages sent to a
mailing list, directing the traffic to the list posting address, so that
all members of the list see the autoreply message (assuming the
autoreply user's address is able to post to the list unmoderated). This
is particularly abhorrent behaviour, and will often cause immediate
unsubscription from the list by list owner or moderator.

Rules for Autoreply Messages
----------------------------

There are two basic sets of rules to follow: determining which messages
to reply to, and formatting the reply message in such a way as to
minimise the chances that the receiving system will itself generate an
autoreply.

### Selecting Which Messages to Reply To

There are a number of ways of determining whether or not a message
should be responded to. This is a brief list of the very basics:
-   Only reply to email with your address in the To/Cc headers (this can
    help prevent you replying to mailing list stuff, as well as other
    things)
-   Do not reply to messages including obvious mailing list headers, or
    with `Precedence: bulk`, `Precedence: list` or `Precedence: junk`,
    or from addresses clearly identifiable with mailing lists
-   Do not reply to messages with null SMTP sender (mail system warning,
    error, and notification messages), or with from addresses such as
    `MAILER-DAEMON`, or other senders that are clearly identifiable as
    being connected with mailing lists or other automated systems
-   Do not reply to messages from a sender address to which you have
    recently sent an autoreply (ie in the last week or day - so if it
    goes horribly wrong you don't bury the other party under mail).

[This
thread](http://lists.exim.org/lurker/message/20040123.190954.dbca68a3.en.html)
from the mailing list archives details a number of checks that agents
creating autoresponses should perform.

The reader should also become familiar with:
-   [RFC 3834 Recommendations for Automatic Responses to Electronic
    Mail](http://www.rfc-editor.org/rfc/rfc3834.txt)
-   [RFC 5230 Sieve Email Filtering: Vacation
    Extension](http://www.ietf.org/rfc/rfc5230.txt)
-   [RFC 2369 The Use of URLs as Meta-Syntax for Core Mail List Commands
    and their Transport through Message Header Fields (regarding List-\*
    headers)](http://www.ietf.org/rfc/rfc2369.txt)

### Crafting Your Reply
-   Send your replies using the null SMTP sender (ie `<>`) - this makes
    them appear like bounces, and prevents other systems trying to reply
    to them.
-   Add a `Precedence: junk` header to further reduce the chance of
    other systems replying to your message.
-   Add an `Auto-Submitted: auto-replied` header
-   Send your autoreply to the envelope sender address (as reflected in
    the `Return-Path:` header [^1] of the original message - this
    prevents you trying to send to a list address which may legitimately
    appear as the `From:` header. Do not try and interpret explicit
    `Reply-To:`, `Resent-From:` etc.

Exim Implementation
-------------------

### Example 1

The following is a recipe posted by Edgar Lovecraft on the [mailing
list](http://lists.exim.org/lurker/message/20040126.033829.d0e2c1bd.en.html).
It consists of a router, which runs an exim filter file, and an
autoreply transport.

#### Router

    ##Router##
    uservacation:
      driver = redirect
      allow_filter
      hide_child_in_errmsg
      ignore_eacces
      ignore_enotdir
      reply_transport = vacation_reply
      no_verify
      require_files = <location_to_user_spool_directory>/.vacation.msg
      file = <location_to_user_spool_directory>/.vacation.msg
      user = exim
      group = exim
      unseen

#### Transport

    ##Transport##
    vacation_reply:
      driver = autoreply

(Note that the autoreply transport driver automatically adds an
"Auto-Submitted:" header with value "auto-replied" to the message it
generates.)

#### Per Recipient Filter

This could be hard/symlinked if needed, or even modify the router to
always use one file, but dependent on the existance of a per-user
`.vacation.msg` file.

    # Exim filter
    if ($h_subject: does not contain "SPAM?" and personal) then
     mail
    ##### This is the only thing that a user can set when they      #####
    ##### decide to enable vacation messaging. The vacation.msg.txt #####
     expand file <location_to_user_spool_directory>/.vacation.msg.txt
     once <location_to_user_spool_directory>/.vacation.db
     log <location_to_user_spool_directory>/.vacation.log
     once_repeat 7d
     to $reply_address
     from $local_part\@$domain
     subject "This is an autoreply...[Re: $h_subject:]"
    endif

Note that the filter's 'personal' test has a very narrow scope; see the
Exim documentation for details.

### Example 2

Here is a rather more complex example, implemented slightly differently
by a router and a transport, and triggered by the presence of a
`.vacation.msg` file. It goes to great lengths to avoid generating a
response to which it shouldn't reply, according to the principles
discussed above. Some may consider it overkill. Likely there can be
improvements to this implementation.

Note that at present, it doesn't perform a check for the presence of a
user's address or any of their aliases in the To: or Cc: headers. The
interested reader may like to make this addition.

#### Router

    ##Router##
    uservacation:
      driver = accept
      domains = +local_domains
      condition = ${if or { \
        { match {$h_precedence:} {(?i)junk|bulk|list} } \
        { eq {$sender_address} {} } \
        { def:header_X-Cron-Env: } \
        { def:header_Auto-Submitted: } \
        { def:header_List-Id: } \
        { def:header_List-Help: } \
        { def:header_List-Unsubscribe:} \
        { def:header_List-Subscribe: } \
        { def:header_List-Owner: } \
        { def:header_List-Post: } \
        { def:header_List-Archive: } \
        { def:header_Autorespond: } \
        { def:header_X-Autoresponse: } \
        { def:header_X-Autoreply-From: } \
        { def:header_X-eBay-MailTracker: } \
        { def:header_X-MaxCode-Template: } \
        { match {$h_X-Auto-Response-Suppress: } {OOF} } \
        { match {$h_X-OS:} {HP Onboard Administrator} } \
        { match {$h_X-MimeOLE:} {\N^Produced By phpBB2$\N} } \
        { match {$h_Subject:} {\N^Yahoo! Auto Response$\N} } \
        { match {$h_Subject:} {\N^ezmlm warning$\N} } \
        { match {$h_X-FC-MachineGenerated:} {true} } \
        { match {$message_body} {\N^Your \"cron\" job on\N} } \
        { match {$h_Subject:} {\N^Out of Office\N} } \
        { match {$h_Subject:} {\N^Auto-Reply:\N} } \
        { match {$h_Subject:} {\N^Autoresponse:\N} } \
        { match {$h_Subject:} {\N(Auto Reply)$\N} } \
        { match {$h_Subject:} {\N(Out of Office)$\N} } \
        { match {$h_Subject:} {\Nis out of the office.$\N} } \
        { match {$h_From:} {\N(via the vacation program)\N } } \
        } \
                           } {no} {yes} \
                   }
      require_files = <location_of_user_home_directory>/.vacation.msg
      user = ${lc:$local_part}
      senders = !+noautoreply_senders
      transport = vacation_transport
      unseen
      no_expn
      no_verify

Depending on your environment, you may receive the non-English
equivalent of a typical OoO's Subject: "XYZ is out of the office" -- for
example, I have seen the German equivalent "XYZ ist ausser haus".
Matching these possibilities could be more fun, especially considering
that they may be marked up with different charsets, etc. Unless you
receive a lot of non-English mail, checking for these as well probably
really is overkill: the chances are some of the other more generic rules
will get them anyway).

You may also like to add a check for any mail that was detected and
marked up as spam by local checking facilities, for example:

    { match {$h_X-Spam-Flag:} {\N^yes\N} } \

    ##Transport##
    vacation_transport:
      driver = autoreply
      log = <location_of_user_home_directory>/.vacation.log
      once = <location_of_user_home_directory>/.vacation.once
      once_repeat = 7d
      # Errors-To: is deprecated
      # There are arguments over whether this should send to the SMTP sender, or
      # to a From:, Reply-To: or Resent-From: header
      to = "${if def:h_Errors-To: {$h_Errors-To:} {$sender_address}}"
      file =  <location_of_user_home_directory>/.vacation.msg
      return_message
      subject = ${if def:h_subject: \
                    {Auto: Re: ${rfc2047:${quote:${escape:${length_60:$h_subject:}} }} }\
                    {Auto: I am away from my mail} \
                }
      user = ${lc:$local_part}

You will also need the following list establishing:

    addresslist  noautoreply_senders = <location_of_exim_data_files>/autorep.noanswer

The file `autorep.noanswer` contains patterns of sender addresses, mail
from which should not be responded to. Here is a start, ordered roughly
from very generically useful, to likely to be quite site-specific; some
are commented out, you may like to think a bit harder about using them:

    ^.*-request@.*
    #^request.*@.*
    ^owner-.*@.*
    ^.*-owner@.*
    ^.*-admin@.*
    ^bounce-.*@.*
    ^.*@bounce\..*
    ^.*-outgoing@.*
    ^.*-relay@.*
    ^.*-bounces@.*
    ^.*-bounce@.*
    ^.*-confirm@.*
    ^.*-errors@.*
    ^mailer@.*
    ^postmaster@.*
    ^mailer-daemon@.*
    ^mailer_daemon@.*
    ^majordomo@.*
    ^majordom@.*
    ^mailman@.*
    ^nobody@.*
    ^reminder@.*
    ^autoreply.*@.*
    ^.*-autoresponder@.*
    ^autoresponder@.*
    ^listserv@.*
    ^daemon@.*
    ^server@.*
    ^root@.*
    ^noreply.*@.*
    ^no-reply@.*
    ^bounce@.*
    ^news@.*
    #^news.*@.*
    #^newsletter-?.*@.*
    #^.*-?newsletter@.*
    #^.*@newsletter.*
    ^request.*@.*
    ^httpd@.*
    ^lighttpd@.*
    ^www@.*
    ^www-data@.*
    ^nagios@.*
    ^sales@.*
    ^info@.*
    #^.*@info.*
    ^fetchmail.*@.*
    ^listmaster@.*
    ^mailmaster@.*
    ^webmaster@.*
    ^squid@.*
    ^support@.*
    ^exim@.*
    #^fetchmail.*@.*
    scomp@aol.net

Some people argue that autoreply messages should be sent to email that
comes from role accounts, like info@..., webmaster@... and so on. Your
own circumstances will dictate whether that seems reasonable, modify the
above list to suit. You will wish to consider the risks of sending an
autoreply message inappropriately, verses any inconvenience caused by a
genuine message sender (as opposed to an automated system) not receiving
an autoreply.

What Will Happen If You Ignore These Recommendations
----------------------------------------------------

If you send an autoreply to one of the exim mailing lists you will be
unsubscribed. If you have caught the list admins in a good mood then
this is all that happens.... otherwise....

* * * * *

[CategoryHowTo](CategoryHowTo)

[^1]: Some people disagree with this - feel free to add your reasoning
    to this page. One thread starts
    [[[http://lists.exim.org/lurker/message/20040123.060645.9aa2db18.en.html](http://lists.exim.org/lurker/message/20040123.060645.9aa2db18.en.html)|here]];
    there are others
