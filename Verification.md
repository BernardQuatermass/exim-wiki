Sender Verify Fails on "Recipient"
==================================

This isn't 100% foolproof but the sending server has to be badly
misconfigured to get a false positive with this ACL. This is a sender
verification test that fails if the server specifically says the sending
email address does not exist. If the server fails to respond or rejects
the verification before the RCPT TO: then this ACL won't block it.

    drop    message = REJECTED - Sender Verify Failed - error code \"$sender_verify_failure\"\n\n\
    The return address you are using for this email message <$sender_address>\
    does not seem to be a working account.
            log_message = REJECTED - Sender Verify Failed - error code \"$sender_verify_failure\"
            !hosts = +no_verify
            !verify = sender/callout=2m,defer_ok
            condition = ${if eq{recipient}{$sender_verify_failure}}

The `no_verify` list is your white list in case there are domains that
are really badly configured and won't fix their configuration.

Sender Verify Failed and Blacklisted
====================================

Combination of sender verify fails and in a minor blacklist. Either one
of these is forgivable but if combined they get dropped.

    drop    message     = REJECTED - Sender Verify Failed and Host $sender_host_address is Blacklisted in $dnslist_domain=$dnslist_value - $dnslist_text
            log_message = REJECTED - Sender Verify Failed and Host $sender_host_address is Blacklisted in $dnslist_domain=$dnslist_value - $dnslist_text
            dnslists = dnsbl.sorbs.net : dnsbl.njabl.org : relays.ordb.org : bl.spamcop.net : opm.blitzed.org
            !verify = sender/callout=2m,defer_ok
            !condition =  ${if eq{$sender_verify_failure}{}}

Sender Verify Failed and no Reverse DNS
=======================================

This one bounces email if the sender verify fails and reverse DNS fails.
The idea being that the combination of two sins is enough to get you
excluded. Skip if the SPF validate (using perl or library).

    drop    message     = REJECTED - Sender Verify Failed and no RDNS
            log_message = REJECTED - Sender Verify Failed and no RDNS
            !verify = reverse_host_lookup
            !verify = sender/callout=2m,defer_ok
            !condition =  ${if eq{$sender_verify_failure}{}}

Contain ADSL in reverse, checked or unchecked
=============================================

Or not contain full host (ex: contain localhost, not host.domain.com).
Not block a MX of domain. Use only in `acl_check_mail` before accept
`relay_from_hosts` and authenticated.

    drop   message          = Helo is ADSL or DIAL (HELO was $sender_helo_name) and your ip $sender_host_address not is a MX/SPF of domain <$sender_address_domain>
             !senders       = :
             condition      = ${if match {$sender_helo_name}{\N\d+\.\d+\.\d+\.\d+|\d+-\d+-\d+-\d+|host|dsl|dial|broad|band|user|dhcp|pool|client|cable|pppoe|hsd|dyn|static|ppp|speedy|customer\N}{yes}{no}}
             !hosts         = +ignore_defer : +ignore_unknown : net-iplsearch;/etc/exim4/lst/skp_heloadsl
             condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=$sender_address_domain}}}}}{no}{yes}}
             !spf           = pass
             delay          = 45s
    #-
    drop   message          = Reverse verified ($sender_host_name) is ADSL or DIAL, Helo $sender_helo_name not is $sender_host_address and your ip $sender_host_address not is a MX/SPF of domain <$sender_address_domain>
             !senders       = :
             condition      = ${if def:sender_host_name {true}{false}}
             condition      = ${if match {$sender_host_name}{\N\d+\.\d+\.\d+\.\d+|\d+-\d+-\d+-\d+|host|dsl|dial|broad|band|user|dhcp|pool|client|cable|pppoe|hsd|dyn|static|ppp|speedy|customer\N}{yes}{no}}
             !hosts         = +ignore_defer : +ignore_unknown : net-iplsearch;/etc/exim4/lst/skp_heloadsl
             condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=$sender_address_domain}}}}}{no}{yes}}
             condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_never,a=$sender_helo_name}}}{no}{yes}}
             !spf           = pass
             delay          = 45s
    #-
    drop   message          = Reverse unchecked (${lookup dnsdb{>: defer_never,ptr=$sender_host_address}}) is ADSL or DIAL, Helo $sender_helo_name not is $sender_host_address and your ip $sender_host_address not is a MX/SPF of domain <$sender_address_domain>
             !senders       = :
             condition      = ${if def:sender_host_name {false}{true}}
             condition      = ${if match {${lookup dnsdb{>: defer_never,ptr=$sender_host_address}}}{\N\d+\.\d+\.\d+\.\d+|\d+-\d+-\d+-\d+|host|dsl|dial|broad|band|user|dhcp|pool|client|cable|pppoe|hsd|dyn|static|ppp|speedy|customer\N}{yes}{no}}
             !hosts         = +ignore_defer : +ignore_unknown : net-iplsearch;/etc/exim4/lst/skp_heloadsl
             condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=$sender_address_domain}}}}}{no}{yes}}
             condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_never,a=$sender_helo_name}}}{no}{yes}}
             !spf           = pass
             delay          = 45s

Side-comments: note the use of `\N...\N` to wrap the regexps, to protect against
backslashes being interpreted by the string-handling layer as well as in the
regexp library.  Also, this example originally did not make it through a wiki
format translation intact; the above is a best effort to recreate what should
work, but please ask on <mailto:exim-users@exim.org> if you encounter issues.

Another sidenote: this will not work in newer exim since match_ip will _not_ expand string2 due to security problems in configs. It's better rewritten so that 

    condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_never,a=$sender_helo_name}}}{no}{yes}}

became

    hosts = ${lookup dnsdb{>: defer_never,a=$sender_helo_name}}

and similar. (Or see *EXPAND_LISTMATCH_RHS* compile-time setting.)
Recipient Verification
======================

Drop at SMTP time if the Recipient doesn't exist.

    deny    message   = REJECTED - Recipient Verify Failed - User Not Found
            domains   = +all_mail_handled_locally
            !verify   = recipient/callout=2m,defer_ok,use_sender

Too many Failed Recipients
==========================

With multiple recipients the sender shouldn't get that many wrong. If
more than 3 are wrong it's probably a dictionary attack.

    drop message = REJECTED - Too many failed recipients - count = $rcpt_fail_count
            log_message = REJECTED - Too many failed recipients - count = $rcpt_fail_count
            condition = ${if > {${eval:$rcpt_fail_count}}{3}{yes}{no}}
            !verify = recipient/callout=2m,defer_ok,use_sender

but RSET resets `$rcpt_fail_count`, thus making any delays after a
certain number of failed recipients useless. So let's do it with an acl
variable, set the variable in a warn condition:

    warn    domains = +local_domains
                    !verify = recipient
                    set acl_c0 = ${eval: $acl_c0+1}
                    delay = ${eval: ($acl_c0 - 1) * 60}s
