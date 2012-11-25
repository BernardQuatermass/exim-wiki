Exiscan Examples & Configurations FAQ
=====================================

Author: Tom Kistner
\<[[tom@duncanthrax.net](mailto:tom@duncanthrax.net)](mailto:tom@duncanthrax.net)\>

*This is a conversion of Tom's documentation to wiki format - nothing
other than reformatting has been done to Tom's documentation for Exiscan
4.42-27 --* [NigelMetheringham](NigelMetheringham)

*I have adapted the document a little bit to reflect the new
possibilities, most notably the acl\_m variables --*
[ZugSchlus](ZugSchlus)

The exiscan website is at
[http://duncanthrax.net/exiscan/](http://duncanthrax.net/exiscan/). You
will find the latest patch versions, as well as links to the mailing
list and its archives there. Please notice that since Exim 4.50, exiscan
is part of the Exim distribution, so additional patches are not
required.

This document shows some example configuration snippets:- .. contents:

::

These examples serve as a guideline and should give you some pointers
that can help you to create your own configuration. Please do not copy
these examples verbatim. You really need to know what you are doing. The
content scanning topic is really complex and you can screw up your mail
server easily if you do not get it "right".

I recommend to read the exiscan documentation on the above mentioned
website before trying to make sense of the following examples.

Each example shows part of a DATA ACL definition, unless otherwise
noted.

Basic setup for simple site-wide filtering
------------------------------------------

The following example only shows the most basic use of the exiscan
content filtering features. You should see it as a base that you can
build on. However, it may be all you need for smaller systems with only
a few users.

Main configuration:

    spamd_address = 127.0.0.1 783

This is the spamassassin default, so you don't have to change anything
there.

An alternative is using a unix socket:

    spamd_address = /var/run/spamd/socket

You have to run spamassassin with *--socketpath /var/run/spamd/socket*
then.

This points exim towards a spamd running on localhost and Port 783/TCP.

ACL:

    # Do not scan messages submitted from our own hosts
    # and locally submitted messages. Since the DATA ACL
    # is not called for messages not submitted via SMTP
    # protocols, we do not need to check for an empty
    # host field.
    accept  hosts = 127.0.0.1:+relay_from_hosts

    # Unpack MIME containers and reject file extensions
    # used by worms. Note that the extension list may be
    # incomplete.
    deny  message = $found_extension files are not accepted here
          demime = com:vbs:bat:pif:scr

    # Reject messages that have serious MIME errors.
    # This calls the demime condition again, but it
    # will return cached results.
    deny  message = Serious MIME defect detected ($demime_reason)
          demime = *
          condition = ${if >{$demime_errorlevel}{2}{1}{0}}

    # Reject messages containing malware.
    deny message = This message contains malware ($malware_name)
         malware = *

    # Reject spam messages. Remember to tweak your
    # site-wide SA profile. Do not spam-scan messages
    # larger than eighty kilobytes.
    deny message = Classified as spam (score $spam_score)
         condition = ${if <{$message_size}{80k}{1}{0}}
         spam = nobody

    # Finally accept all other messages that have
    # made it to this point
    accept

Adding a cryptographic "scanning done" header
---------------------------------------------

If you have a mail setup where the same message may pass your server
twice (redirects from other servers), or you have multiple mail servers,
you may want to make sure that each message is only checked once, to
save processing time. Here is how to do it:

At the very beginning of your DATA ACL, put this:

    # Check our crytographic header. If it matches, accept
    # the message.
    accept condition = ${if eq {${hmac{md5}\
                                      {mysecret}\
                                      {$body_linecount}\
                                 }}\
                               {$h_X-Scan-Signature:} {1}{0}}

At the end, just before the final "accept" verb, put this:

    # Add the cryptographic header.
    warn message = X-Scan-Signature: ${hmac{md5}{mysecret}\
                                           {$body_linecount}}

Notice the two "mysecret" strings? Replace them with your own secret,
and don't tell anyone |:)| The hash also includes the number of lines in
the message body, to protect against message "modifications".

Marking Spam messages with extra headers and subject tag
--------------------------------------------------------

Since the false positive rate with spam scanning is high compared to
virus scanning, it is wise to implement a scheme with two thresholds,
where you reject messages with high scores and just mark messages with
lower scores. End users can then set up filters in their Mail User
Agents (MUAs). Since many MUAs can not filter on custom headers, it can
be necessary to put a "spam tag" in the subject line. Since it is not
(yet) possible to remove headers in Exims DATA ACL, we must do this in a
system filter. Please see the Exim docs on how to set up a system
filter.

The following example will unconditionally put two spam information
headers in each message, if it is smaller than eighty kilobytes:

    # Always put X-Spam-Score header in the message.
    # It looks like this:
    # X-Spam-Score: 6.6 (++++++)
    # When a MUA cannot match numbers, it can match for an
    # equivalent number of '+' signs.
    # The 'true' makes sure that the header is always put
    # in, no matter what the score.
    warn message = X-Spam-Score: $spam_score ($spam_bar)
         condition = ${if <{$message_size}{80k}{1}{0}}
         spam = nobody:true

    # Always put X-Spam-Report header in the message.
    # This is a multiline header that informs the user
    # which tests a message has "hit", and how much a
    # test has contributed to the score.
    warn message = X-Spam-Report: $spam_report
         condition = ${if <{$message_size}{80k}{1}{0}}
         spam = nobody:true

For the subject tag, we prepare a new subject header in the ACL, then
swap it with the original Subject in the system filter.

In the DATA ACL, put this:

    warn message = X-New-Subject: *SPAM* $rh_subject:
         spam = nobody

In the system filter, put this:

    if first_delivery then
      if $h_X-New-Subject: is not ""
      then
         headers remove Subject
         headers add "Subject: $rh_X-New-Subject:"
         headers remove X-New-Subject
      endif

      # ...
    endif

In newer exim versions, the acl\_m variables can be used to transport
the new subject from the ACL to the sytem filter.

For a different way of tagging the Subject header which allows per-user
configuration, see
[SpamTagSubjectHeaderPerUser](SpamTagSubjectHeaderPerUser).

Replacing foreign Spamassassin headers with local ones
------------------------------------------------------

In some cases, incoming messages might already have Spamassassin headers
which have been put in by some other server the message has passed
through. As to not confuse user filters, it is recommended to remove
these headers before adding the local Spamassassin headers. This is
unfortunately not easy to do.

    warn
      spam = exiscan:true
      set acl_m0 = ($spam_bar) $spam_score
      set acl_m1 = $spam_report

This will set ACL variables appropriately for the following processing
in the system filter:

    if first_delivery then
      # ...

      headers remove X-Spam-Score:X-Spam-Report:X-Spam-Checker-Version:X-Spam-Status:X-Spam-Level
      if $acl_m2 is not "" then
        headers add "X-Spam-Score: $acl_m0"
        headers add "X-Spam-Report: $acl_m1"
      endif
    endif

This system filter removes a list of known Spamassassin headers and adds
in the local headers from the ACL variables, should they be defined.

Defining multiple spam thresholds with different actions
--------------------------------------------------------

If you want to mark messages if they exceed your threshold, but also
have a higher "cutoff" threshold where you reject messages, use the
example above, plus this part:

    deny message = Spam score too high ($spam_score)
         condition = ${if <{$message_size}{80k}{1}{0}}
         spam = nobody:true
         condition = ${if >{$spam_score_int}{100}{1}{0}}

The last condition is only true if the spam score exceeds 10.0 points
(Keep in mind that \$spam\_score\_int is the messages score multiplied
by ten).

Redirect infected or spam messages to special accounts
------------------------------------------------------

Sometimes it is desirable not to reject messages, but to stop them for
inspection, and then decide wether to delete, bounce or pass them.

There are multiple ways to achieve this. The simplest way is to freeze
suspicious messages, and then thaw or bounce them after a review. Here
is a simple example that will freeze spam suspicious messages when they
exceed the SA threshold:

    warn log_message = frozen by spam scanner, score $spam_score
         spam = nobody
         control = freeze

Another way is to redirect suspicious messages to special postmaster
accounts, where they can be reviewed. This involves setting up a router
for these special accounts that acts on a header set in the DATA ACL.

This is the DATA ACL entry:

    warn message = X-Redirect-To: spambox@mycompany.com
         spam = nobody

This puts the target address in a special header, which can in turn be
read with this router:

    scan_redirect:
         driver = redirect
         condition = ${if def:h_X-Redirect-To: {1}{0}}
         headers_add = X-Original-Recipient: $local_part@$domain
         data = $h_X-Redirect-To:
         headers_remove = X-Redirect-To
         redirect_router = my_second_router

This router should probably be your very first one, and you need to edit
the last line (redirect\_router = ) to replace "my\_second\_router" with
the name of your original first router. Note that the original message
recipient is saved in the "X-Original-Recipient" header, and the
X-Redirect-To header line is removed.

Having multiple content scanning profiles for several users or domains
----------------------------------------------------------------------

This is one of the most often asked questions, and it also has the most
complicated answer. To understand the difficulties, you should first
remember that the exiscan facilities are run in the DATA ACL. This ACL
is called ONCE per message, after the sending server has transmitted the
end-of-data marker. This gives us the very cool possibility to reject
unwanted messages with a 5xx error code in response. The big drawback is
that a message can have multiple recipients, and you can only reject or
accept a message for ALL recipients, not individual ones.

I will first sum up the possible solutions to this dilemma:

a.  Make sure that each incoming message can have only one envelope
    recipient. This is brutal, but effective and reliably solves the
    problem on your end. |:)| **Drawback:** Incoming mail to multiple
    recipients is slowed down. The exact time depends on the retry
    strategies of the sending hosts.

b.  Offer a limited number of "profiles" that your customers can
    subscribe to. Then, similar to a.), only accept recipients with the
    same profile in a single "batch", and defer the others. This does
    improve on the drawback of a.) a bit.

c.  Do scanning as usual, but never reject messages in the DATA ACL.
    Instead put appropriate information in extra headers and query those
    in routers or transports later. **Drawback:** You'll have to send
    bounces yourself, and your queue will fill up with frozen bounces.
    **Advantage:** clean solution, protocol-wise.

As you see, you can't have your cake and eat it too. Now lets get into
the details of each possible solution.

### Making sure each incoming message that will be scanned only has one recipient

To use this scheme, you must make sure that you do not use it on your
+relay\_from\_hosts and authenticated senders. Both of these may be MUAs
who cannot cope with such a thing.

Here is a RCPT ACL that implements the behaviour (shortened, do not copy
1:1!):

    acl_check_rcpt:

      # accept local, relay-allowed
      # and authenticated sources

      accept  hosts         = :
      deny    local_parts   = ^.*[@%!/|]
      accept  hosts         = 127.0.0.1:+relay_from_hosts
      accept  authenticated = *

      # the following treat non-local,
      # non-authenticated sources

      defer   message       = only one recipient at a time
              condition     = ${if def:acl_m0 {1}{0}}

      # [ .. ]
      # put RBLs etc. here
      # [ .. ]

      accept  domains       = +local_domains
              endpass
              message       = unknown user
              verify        = recipient
              set acl_m0    = $local_part@$domain

      accept  domains       = +relay_to_domains
              endpass
              message       = unrouteable address
              verify        = recipient
              set acl_m0    = $domain

      deny    message       = relay not permitted

The lines which contain acl\_m0 are the important ones. The \$acl\_m0
variable gets set when a remote server successfully sends one RCPT.
Subsequent RCPT commands are deferred if this variable is set. The
\$acl\_m0 variable now contains the single recipient domain, which you
can use in the DATA ACL to determine the scanning profile.

This scheme is only recommended for small servers with a low number of
possible recipients, where recipients do not belong to the same
organization. An example would be a multiuser shell server.

### Having several scanning profiles that "customers" can choose from

Suppose you want to offer three profiles. Lets call them
"reject-aggressive", "reject-conservative", and "warn-only". Customers
can select one of the profiles for each of their domains. So you end up
with a mapping like this:

    domain-a.com:   reject-aggressive
    domain-b.org:   warn-only
    domain-c.net:   reject-aggressive
    domain-d.com:   reject-conservative
    [ .. ]

> Suppose you put that in a file called `/etc/exim/scanprefs`

Now we make a scheme similar to a.), but we do allow more than one
recipient if they have the same scanning profile than the first
recipient.

Here is a RCPT ACL that implements the behaviour (shortened, do not copy
1:1!):

    acl_check_rcpt:

      # accept local, relay-allowed and authenticated sources

      accept  hosts         = :
      deny    local_parts   = ^.*[@%!/|]
      accept  hosts         = 127.0.0.1:+relay_from_hosts
      accept  authenticated = *

      # the following treat non-local, non-authenticated sources

      defer   message       = try this address in the next batch
              condition     = ${if eq {${acl_m0}}\
                              {${lookup{$domain}\
                              lsearch{/etc/exim/scanprefs} }}\
                              {0}{1}}

      # [ .. ]
      # put RBLs etc. here
      # [ .. ]

      accept  domains       = +local_domains
              endpass
              message       = unknown user
              verify        = recipient
              set acl_m0    = $local_part@$domain

      accept  domains       = +relay_to_domains
              endpass
              message       = unrouteable address
              verify        = recipient
              set acl_m0    = ${lookup{$domain}\
                              lsearch{/etc/exim/scanprefs}}

      deny    message       = relay not permitted

Now a recipient address get deferred if its scan profile does not match
the current batch profile. The \$acl\_m0 variable contains the name of
the profile, that can be used for processing in the DATA ACL.

This scheme works pretty well if you keep the number of possible
profiles low, since that will prevent fragmentation of RCPT blocks.

### Classic content scanning without the possibility of rejects after DATA

This emulates the "classic" content scanning in routers and transports.
The difference is that we still do the scan in the DATA ACL, but put the
outcome of each facility in message headers, that can the be evaluated
in special routers, individually for each recipient.

A special approach can be taken for spam scanning, since the
\$spam\_score\_int variable is also available in routers and transports
(it gets written to the spool files), so you do not need to put that
information in a header, but rather act on \$spam\_score\_int directly.
