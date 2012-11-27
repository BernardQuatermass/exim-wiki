Greylisting Using Memcached and Perl
====================================

See original mailing list message -
[http://lists.exim.org/lurker/message/20090727.160342.ac172696.en.html](http://lists.exim.org/lurker/message/20090727.160342.ac172696.en.html)

I have transcribed it directly into this wiki page without checking -
please correct if there are errors.

Implementation
--------------

This is an implementation of greylisting that uses memcached. Here are
what I perceive as advantages:

1.  Uses distributed storage instead of local state files.

2.  Memcached is *FAST*.

3.  Only greylist if reverse IP does not exist for host that is
    connecting.

4.  Uses existing perl module.

5.  Two macros do everything.

6.  Uses config file to set memcache servers.

First, add this to your `exim.conf` somewhere up near the top:

    perl_startup = do '/etc/exim/mod_exim.pl'
    perl_at_start
    # Greylist duration, TTL for entry, adjust as desired
    GREY_MINUTES  = 5
    GREY_TTL_DAYS = 7
    # Arguments to perl subroutines, don't touch
    GREYLIST_ARGS = {$sender_host_address}{${quote:$sender_address}}{${quote:$local_part}}{${quote:$domain}}{GREY_MINUTES}{GREY_TTL_DAYS}

Second, add this to your rcpt acl. I put it after RBL checks, and it's
after a whitelist ACL where I can whitelist specific IP addresses (done
separately in our internal RBL).

    defer   !senders       = :
            !authenticated = *
            !hosts         = +relay_from_hosts
            # $acl_c0 is set in my custom whitelist acl if host is whitelisted
            !condition     = ${if eq {$acl_c0}{$sender_host_address}}
            !condition     = ${lookup dnsdb{defer_never,ptr=$sender_host_address}{yes}}
            set acl_c_grey_host = 1
            condition      = ${perl{check_greylist}GREYLIST_ARGS}
            set acl_c_grey_time = ${perl{greylist_time}GREYLIST_ARGS}
            log_message    = No reverse DNS for IP $sender_host_address, greylist for $acl_c_grey_time minutes

    warn    condition      = ${if eq {$acl_c_grey_host}{1}}
            add_header     = X-Greylist: $sender_host_address passed GREY_MINUTES minute greylist, was greylisted due to missing reverse DNS

Third, create the perl script (attached to this page - [mod_exim.pl](attachments/mod_exim.pl.txt)

Fourth, create /etc/exim/memcached.conf file:

    # Leading hash mark comments a line
    # Can use short hostname, FQDN, or IP address
    server = memcached1:11211
    server = memcached2.domain.com:11211
    server = 192.168.1.100:11211
    # Prefixes key with this text, defaults to exim
    namespace = exim

How it works
------------

When receiving an email from IP: `69.169.219.58` Sender:
`3f9.4.90966988-48470119@harborlurch.com`, Recipient: `bld@example.com`

It will store the key:
`exim:69.169.219.58:"3f9.4.90966988-48470119@harborlurch.com":bld@example.com`

The value stored will be the current timestamp in unix time format (i.e.
seconds since 1970), and an expiration set to 7 days in the future. The
quotes in there are due to the way I defined the macro, but it doesn't
hurt anything that I can see. It defers with the message:

> No reverse DNS for IP 69.169.219.58, greylist for 5:00 minutes

If the mail server were to retry it in less than 5 minutes, they would
still get deferred with the message:

> No reverse DNS for IP 69.169.219.58, greylist for 1:42 minutes

When it finally retries after the 5 minute mark has timed-out, it
accepts the email.

The TTL (aka expiration) of a key is updated every time that IP connects
when sending to/from the same email address. Conversations between
customers and valid users of those DNS impaired mail servers no longer
get delayed after the first email as long as more than one email is sent
during the previous week (7 days is the default TTL of the key) because
the expiration is constantly being updated. The catch here is that it
must originate from the same IP. Some systems have banks of mail servers
all running the queue, and if it comes from different source IP for each
attempt, this will continue to defer that sender/recipient combo. Note
that if you run a cluster of mail servers and you don't have reverse
DNS, this doesn't bother me in the least because the chances that my
users want your mail is slimmer than a coat of paint.

That's pretty much it. Let me know if you use this or spot anything
wrong or unsafe. I'd be particularly interested if anybody spots
anything wrong with my quoting. It seems very unnecessary to me to quote
the sender address, but I'd rather be safe than exploited.
