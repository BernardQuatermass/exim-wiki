Sender Verification
===================

This is a fairly safe sender verify ACL. It only rejects the message if
the sender verify specifically rejects the message during the recipient
part of the verification. It also uses a specific email address rather
an empty message for verification. This avoids misconfigured hosts that
reject empty from addresses at the recipient phase. It also supports the
use of a no verify list for really stupid hosts where testing must be
avoided. The no verify list will whitelist both the senders domain and
the host address.

    deny    message = REJECTED - Sender Verify Failed - The email server for the domain [$sender_address_domain] tells junkemailfilter.com that the sender's email address [$sender_address] is not a valid. $sender_verify_failure
            log_message = REJECTED - Sender Verify Failed - The email server for the domain [$sender_address_domain] tells junkemailfilter.com that the sender's email address [$sender_address] is not a valid. $sender_verify_failure
            !verify = header_sender/callout=2m,defer_ok,mailfrom=sender-verify@junkemailfilter.com
            condition = ${if eq{recipient}{$sender_verify_failure}}
            condition = ${lookup{$sender_address_domain}wildlsearch{/etc/exim/acllists/noverify.txt}{no}{yes}}
            condition = ${lookup{$sender_host_address}wildlsearch{/etc/exim/acllists/noverify.txt}{no}{yes}}

This sender verification combines a wider verify fail with failed
reverse DNS. It's a combination of two sins that causes the bounce.

    deny    message     = REJECTED - Sender Verify Failed and no RDNS - error code = $sender_verify_failure
            log_message = REJECTED - Sender Verify Failed and no RDNS - error code = $sender_verify_failure
            !verify = reverse_host_lookup
            !verify = header_sender/callout=2m,defer_ok,mailfrom=sender-verify@junkemailfilter.com
            !condition =  ${if eq{$sender_verify_failure}{}}
            condition = ${lookup{$sender_address_domain}wildlsearch{/etc/exim/acllists/noverify.txt}{no}{yes}}

Check Syntax
============

    drop  condition       = ${if match{$h_to:}{(?i)Undisclosed-recipient}{no}{yes}}
          message         = Header Syntax error: $acl_verify_message
          !verify         = header_syntax
          logwrite        = :reject,main: Header Syntax Error: $acl_verify_message

Null Address Check Headers
==========================

    drop  message         = Header From exist, but not have a valid address
          condition       = ${if def:h_from: {yes}{no}}
          condition       = ${if or { \
                              { eq{${address:$h_from:}}{} } \
                              { eq{${domain:$h_from:}}{} } \
                              { eq{${local_part:$h_from:}}{} } \
                            } {yes}{no}}
          delay           = 45s
    drop  message         = Header Reply-to exist, but not have a valid address
          condition       = ${if def:h_reply-to: {yes}{no}}
          condition       = ${if or { \
                              { eq{${address:$h_reply-to:}}{} } \
                              { eq{${domain:$h_reply-to:}}{} } \
                              { eq{${local_part:$h_reply-to:}}{} } \
                            } {yes}{no}}
          delay           = 45s
    drop  message         = Header Sender exists, but not have a valid address
          condition       = ${if def:h_sender: {yes}{no}}
          condition       = ${if or { \
                              { eq{${address:$h_sender:}}{} } \
                              { eq{${domain:$h_sender:}}{} } \
                              { eq{${local_part:$h_sender:}}{} } \
                            } {yes}{no}}
          delay           = 45s

Fast Check Mx Headers Address
=============================

    drop  message         = Header From have a invalid ${sender_verify_failure}: <${address:$h_from:}>
          condition       = ${if def:h_from: {yes}{no}}
          !verify         = sender=${address:$h_from:}/no_details
          delay           = 45s
    drop  message         = Header Reply have a invalid ${sender_verify_failure}: <${address:$h_reply-to:}>
          condition       = ${if def:h_reply-to: {yes}{no}}
          !verify         = sender=${address:$h_reply-to:}/no_details
          delay           = 45s
    drop  message         = Header Sender have a invalid ${sender_verify_failure}: <${address:$h_sender:}>
          condition       = ${if def:h_sender: {yes}{no}}
          !verify         = sender=${address:$h_sender:}/no_details
          delay           = 45s

Slow, but efficient callout
===========================

    drop  message         = Header From have a invalid callout ${sender_verify_failure}: <${address:$h_from:}>
          condition       = ${if def:h_from: {yes}{no}}
          condition       = ${if eqi {$sender_address} {${address:$h_from:}}{no}{yes}}
          condition       = ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/machine_senders}{no}{yes}}
          condition       = ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/bounce_senders}{no}{yes}}
          condition       = ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/skp_callout}{no}{yes}}
          .ifdef SKP_Spf_LIB
              !spf         = SKP_Spf_LIB
          .endif
          .ifdef SKP_Spf_PERL
              set acl_m_spfaddr = ${address:$h_from:}
              !acl         = spf_acpt
          .endif
          condition       = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=${domain:$h_from:}}}}}}{no}{yes}}
          !verify         = sender=${address:$h_from:}/no_details/callout=20s,connect=10s,maxwait=45s,defer_ok,random
           delay          = 30s
    drop  message         = Header Reply have a invalid callout ${sender_verify_failure}: <${address:$h_reply-to:}>
          condition       = ${if def:h_reply-to: {yes}{no}}
          condition       = ${if eqi {$sender_address} {${address:$h_reply-to:}}{no}{yes}}
          condition       = ${lookup{${address:$h_reply-to:}}wildlsearch{/etc/exim4/lst/skp_callout}{no}{yes}}
          .ifdef SKP_Spf_PERL
              set acl_m_spfaddr = ${address:$h_from:}
              !acl         = spf_acpt
          .endif
          condition       = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=${domain:$h_reply-to:}}}}}}{no}{yes}}
          !verify         = sender=${address:$h_reply-to:}/no_details/callout=20s,connect=10s,maxwait=45s,defer_ok,random
           delay          = 30s
    drop  message         = Header Sender have a invalid callout ${sender_verify_failure}: <${address:$h_sender:}>
          condition       = ${if def:h_sender: {yes}{no}}
          condition       = ${if eqi {$sender_address} {${address:$h_sender:}}{no}{yes}}
          condition       = ${lookup{${address:$h_sender:}}wildlsearch{/etc/exim4/lst/machine_senders}{no}{yes}}
          condition       = ${lookup{${address:$h_sender:}}wildlsearch{/etc/exim4/lst/bounce_senders}{no}{yes}}
          condition       = ${lookup{${address:$h_sender:}}wildlsearch{/etc/exim4/lst/skp_callout}{no}{yes}}
          .ifdef SKP_Spf_PERL
              set acl_m_spfaddr = ${address:$h_from:}
              !acl         = spf_acpt
          .endif
          condition       = ${if eqi {${domain:$h_sender:}} {$sender_address_domain} {no}{yes}}
          condition       = ${if eqi {${domain:$h_sender:}} {${domain:$reply_address}} {no}{yes}}
          condition       = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=${domain:$h_sender:}}}}}}{no}{yes}}
          !verify         = sender=${address:$h_sender:}/no_details/callout=20s,connect=10s,maxwait=45s,defer_ok,random
           delay          = 30s

Black List headers
==================

`blk_sender` contains address patterns, line separated
(`*@domainspam.com`, `*.domainspam.com`)

    drop   condition      = ${if def:h_from: {yes}{no}}
           condition      = ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/blk_sender}{yes}{no}}
           message        = Header From <${address:$h_from:}> black listed: ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/blk_sender}}
           delay          = 45s
    drop   condition      = ${if def:h_reply-to: {yes}{no}}
           condition      = ${lookup{${address:$h_reply-to:}}wildlsearch{/etc/exim4/lst/blk_sender}{yes}{no}}
           message        = Header Reply <${address:$h_reply-to:}> black listed: ${lookup{${address:$h_reply-to:}}wildlsearch{/etc/exim4/lst/blk_sender}}
           delay          = 45s
    drop   condition      = ${if def:h_sender: {yes}{no}}
           condition      = ${lookup{${address:$h_sender:}}wildlsearch{/etc/exim4/lst/blk_sender}{yes}{no}}
           message        = Header From <${address:$h_sender:}> black listed: ${lookup{${address:$h_sender:}}wildlsearch{/etc/exim4/lst/blk_sender}}
           delay          = 45s
    drop   condition      = ${if def:h_Message-Id: {yes}{no}}
           condition      = ${lookup{${address:$h_Message-Id:}}wildlsearch{/etc/exim4/lst/blk_sender}{yes}{no}}
           message        = Header Message-ID <${address:$h_Message-Id:}> black listed: ${lookup{${address:$h_Message-Id:}}wildlsearch{/etc/exim4/lst/blk_sender}}
           delay          = 45s

Blind copy in bounce?
====================

    drop  message         = Bounce errors never contains bind copy headers!
          senders         = :
          !verify         = not_blind
          delay           = 45s

Fake my message ID domain or subdomain
======================================

    drop   message        = No you are not ME or OURS (Message-ID was ${domain:$h_Message-ID:} and equal my local domains or my domains relay)
           !hosts         = +relay_from_hosts : +relay_mx_hosts
           condition      = ${if or{{!def:h_message-id:}{eqi{${domain:$h_Message-ID:}}{}}}{no}{yes}}
           condition      = ${if match_domain{${domain:$h_Message-ID:}}{+local_domains:+alias_domains:+relay_to_domains}{yes}{no}}
           delay          = 45s
    drop   message        = No you are not Me or OURS (Message-ID was ${domain:$h_Message-ID:} and the subdomain is my domain ${extract{-3}{.}{${domain:$h_Message-ID:}}}.${extract{-2}{.}{${domain:$h_Message-ID:}}}.${extract{-1}{.}{${domain:$h_Message-ID:}}})
           !hosts         = +relay_from_hosts : +relay_mx_hosts
           condition      = ${if or{{!def:h_message-id:}{eqi{${domain:$h_Message-ID:}}{}}}{no}{yes}}
           condition      = ${if match_domain{${extract{-3}{.}{${domain:$h_Message-ID:}}}.${extract{-2}{.}{${domain:$h_Message-ID:}}}.${extract{-1}{.}{${domain:$h_Message-ID:}}}}{+local_domains:+alias_domains:+relay_to_domains}{yes}{no}}
           delay          = 45s
    drop   message        = No you are not ME or OURS (Message-ID was ${domain:$h_Message-ID:} and equal my interface hostname)
           !hosts         = +relay_from_hosts : +relay_mx_hosts
           condition      = ${if !def:interface_address {no}{yes}}
           condition      = ${if !def:h_message-id: {no}{yes}}
           condition      = ${if match_ip{$interface_address}{${lookup dnsdb{>: defer_never,a=${domain:$h_Message-ID:}}}}{yes}{no}}
           delay          = 45s

Duplicate Message-ID or Subject ?
=================================

If use it, set numer of messages by period. Warning, the lists have
equal subjects to diferents receipients in diferents mail to sessions:
`BLK_DUP_MESSAGEID = 2 / 7d BLK_DUP_MESSAGESUB = 5 / 7d`

    .ifdef BLK_DUP_MESSAGEID
    #-BLK: Ratelimit para mensagens duplicadas pelo id (#exim_dumpdb /var/spool/exim4/ ratelimit)
    drop   !hosts         = +relay_from_hosts : +relay_mx_hosts
           !authenticated = *
           condition      = ${if !def:h_Message-Id: {no}{yes}}
           ratelimit      = BLK_DUP_MESSAGEID / strict / Message-ID=${md5:${escape:${lc:$h_Message-Id:}}}${sha1:${escape:${lc:$h_Message-Id:}}}
           logwrite       = :reject,main: $message_exim_id RateLimit: $sender_rate/$sender_rate_limit/$sender_rate_period - F=$sender_address_domain H=$sender_rcvhost: Message-ID=${length_150:${escape:$h_Message-Id:}}
           message        = This message is duplicated id and has been previously sent. Possible SPAM!
           delay          = ${eval: ${sg{$sender_rate}{[.].*}{}} - $sender_rate_limit }s
    .endif
    .ifdef BLK_DUP_MESSAGESUB
    #-BLK: Ratelimit para mensagens duplicadas pelo subject (#exim_dumpdb /var/spool/exim4/ ratelimit)
    #Trocar leaky / strict ???
    drop   !hosts         = +relay_from_hosts : +relay_mx_hosts
           !authenticated = *
           condition      = ${if !def:h_Subject: {no}{yes}}
           condition      = ${if def:h_In-Reply-To: {no}{yes}}
           condition      = ${if def:h_References: {no}{yes}}
           ratelimit      = BLK_DUP_MESSAGESUB / leaky / Subject=${md5:${escape:${lc:$h_Subject:$h_Date:}}}${sha1:${escape:${lc:$h_Subject:$h_Date:}}}
           logwrite       = :reject,main: $message_exim_id RateLimit: $sender_rate/$sender_rate_limit/$sender_rate_period - F=$sender_address_domain H=$sender_rcvhost: Subject=${length_150:${escape:$h_Subject:}}
           message        = This message is duplicated subject and has been previously sent. Possible SPAM!
           delay          = ${eval: ${sg{$sender_rate}{[.].*}{}} - $sender_rate_limit }s
     .endif

Other Tricks
============

Block if Subject and Body are both Empty.

    deny    message = REJECTED - No Subject or Body
            !condition = ${if def:h_Subject:}
            condition = ${if <{$body_linecount}{1}{true}{false}}
