RCPT ACL
========

Bounces are never sent to more than one recipient.

    drop    message = Legitimate bounces are never sent to more than one recipient.
            senders = : postmaster@*
            condition = ${if >{$recipients_count}{0}{true}{false}}

Drop if more than 3 bad recipients.

    drop    message = REJECTED - Too many failed recipients - count = $rcpt_fail_count
            log_message = REJECTED - Too many failed recipients - count = $rcpt_fail_count
            condition = ${if > {${eval:$rcpt_fail_count}}{3}{yes}{no}}
            condition = ${run{/etc/exim/scripts/log-file /var/spool/spam/host-spam.txt $sender_host_address}{yes}{yes}}
            !verify = recipient/callout=2m,defer_ok,use_sender

Drop if any of the recipients mentioned is one which only ever receives
spam (ideally, a spam "trap" address):

    drop    condition = ${lookup{$local_part@$domain}lsearch{/etc/exim/only-used-by-spammers} {yes}{no}}
            logwrite = :main,reject: $sender_host_address - $local_part@$domain is only used by spammers
            message = I don't think so

> Suggestions for improving the `condition` welcomed - e.g. maybe use
> match\_address?

Drop if destination is myprotecteddomain.com or my2protecteddomain.com
but source is not \*myowndomain.com . It will log useful info in exim
log and only give administration prohibited to the other mta. Great for
domains you know sources. (generaly internal use domain) :

    deny       log_message =  $sender_address is not permitted to send to myprotecteddomain.com my2protecteddomain.com
               domains     = myprotecteddomain.com : my2protecteddomain.com
               ! senders   = *myowndomain.com
