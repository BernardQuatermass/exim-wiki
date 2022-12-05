## Blocking compromised accounts (outgoing spam) and auth cracking
Nowadays users' passwords often are stolen (with drive-by exploits, Windows malware, phishing) and used for spamming. Spam sent with authentication via your server causes it to be blacklisted without notice and sometimes no appeal. Simple rate limiting authenticated users constrains honest users while still allowing spam to trickle through, your server still ends up in blacklists. Each server needs automatic detection and blocking of compromised accounts (stolen passwords). I amended and implemented (for Exim version 4.67 or higher) Andrew Hearn's [idea](https://lists.exim.org/lurker/message/20100226.153132.58ab2e98.en.html) to check not rate of messages or all recipients, but rate of attempts to send to nonexistent recipient email addresses. Vast majority of spammers never try to validate every recipient address. Spammers harvest strings looking like email addresses from webpages and disks of trojaned Windowses, then sell huge lists of email addresses to each other. These lists contain very much email addresses which don't exist anymore or never existed: Message-Ids, corrupted strings in memory and files. In short, spammers' lists of email addresses are much dirtier than lists honest users send to. Honest users are very unlikely to attempt to send to 100 nonexistent email addresses in one hour. Below I explain in detail (for novices at Exim) what to change in Exim config for automatic blocking of compromised and spammers' accounts, with automatic email notification to sysadmin or your abuse or support staff.

This code also blocks brute force password cracking via SMTP (it's not as important but a little useful).

Replace the paragraph with the line `accept  authenticated = *` with four paragraphs:

      drop  authenticated = *
            set acl_m_user = ${sg{$authenticated_id}{\N[^\w.=@-]\N}{}}
            condition = ${if exists{$spool_directory/blocked_authenticated_users}}
            set acl_m_wasfree = ${if def:acl_c_blocked{$acl_c_spoolfree}\
                          {${lookup{$acl_m_user}lsearch\
                          {$spool_directory/blocked_authenticated_users}}}}
            condition = ${if match{$acl_m_wasfree}{\N^\d+$\N}}
            condition = ${if match{$spool_space}{\N^\d+$\N}}
            condition = ${if <={$spool_space}{${eval:$acl_m_wasfree/2}}}
            log_message = free space on spool disk $spool_space KB - less than \
                          half than it was when the user $acl_m_user was blocked
            message = spool disk too full
    
      accept authenticated = *
            condition = ${if exists{$spool_directory/blocked_authenticated_users}}
            condition = ${lookup{$acl_m_user}lsearch\
                                {$spool_directory/blocked_authenticated_users}\
                                {1}{$acl_c_blocked}}
            # The variable acl_c_blocked is used because lookup can be cached. 
            control = freeze/no_tell
            control = submission/domain=
            add_header = X-Authenticated-As: $acl_m_user
    
      accept authenticated = *
            !verify = recipient/defer_ok/callout=10s,defer_ok,use_sender
            ratelimit = WRONG_RCPT_LIMIT / PERIOD / per_rcpt / user-$acl_m_user
            set acl_c_blocked = 1
            set acl_c_spoolfree = $spool_space
            continue = ${run{SHELL -c "echo $acl_m_user:$acl_c_spoolfree \
               >>$spool_directory/blocked_authenticated_users; \
               \N{\N echo Subject: user $acl_m_user blocked; echo; echo because \
               has sent mail to WRONG_RCPT_LIMIT invalid recipients during PERIOD.; \
               \N}\N | $exim_path -f root WARNTO"}}
            control = freeze/no_tell
            control = submission/domain=
            add_header = X-Authenticated-As: $acl_m_user
    
      accept authenticated = *
            control = submission/domain=

If you use Exim version 4.90 or higher then in the code above change `use_sender` to `use_sender,hold`

If the line `hostlist   relay_from_hosts =`
contains something besides `localhost` or `127.0.0.1`
or this server's IP-address, i.e. your server is a relay for
your LAN or users on your company's IP-addresses,
then replace the paragraph with the line
`accept  hosts         = +relay_from_hosts`
with four paragraphs:

      drop  hosts = !@[] : +relay_from_hosts
            set acl_m_user = $sender_host_address
                             # or username from RADIUS, then change
                             # iplsearch to lsearch in this and next paragraphs
            condition = ${if exists{$spool_directory/blocked_relay_users}}
            set acl_m_wasfree = ${if def:acl_c_blocked{$acl_c_spoolfree}\
                          {${lookup{$acl_m_user}iplsearch\
                          {$spool_directory/blocked_relay_users}}}}
            condition = ${if match{$acl_m_wasfree}{\N^\d+$\N}}
            condition = ${if match{$spool_space}{\N^\d+$\N}}
            condition = ${if <={$spool_space}{${eval:$acl_m_wasfree/2}}}
            log_message = free space on spool disk $spool_space KB - less than \
                          half than it was when the user $acl_m_user was blocked
            message = spool disk too full
    
      accept hosts = !@[] : +relay_from_hosts
            condition = ${if exists{$spool_directory/blocked_relay_users}}
            condition = ${lookup{$acl_m_user}iplsearch\
                                {$spool_directory/blocked_relay_users}\
                                {1}{$acl_c_blocked}}  
            control = freeze/no_tell
            control = submission/domain=
            add_header = X-Relayed-From: $acl_m_user
    
      accept hosts = !@[] : +relay_from_hosts
            !verify = recipient/defer_ok/callout=10s,defer_ok,use_sender
            ratelimit = WRONG_RCPT_LIMIT / PERIOD / per_rcpt / relayuser-$acl_m_user
            set acl_c_blocked = 1
            set acl_c_spoolfree = $spool_space
            continue = ${run{SHELL -c 'echo \\\"$acl_m_userMASKL\\\":$acl_c_spoolfree \
               >>$spool_directory/blocked_relay_users; \
               \N{\N echo Subject: relay user $acl_m_user blocked; echo; echo \
               because has sent mail to WRONG_RCPT_LIMIT invalid recipients during PERIOD.; \
               \N}\N | $exim_path -f root WARNTO'}}
            control = freeze/no_tell
            control = submission/domain=
            add_header = X-Relayed-From: $acl_m_user
    
      accept hosts = +relay_from_hosts
            control = submission/domain=

Insert into beginning of config:

    acl_smtp_connect = acl_check_connect
    acl_smtp_helo = acl_check_helo
    acl_smtp_auth = acl_check_auth
    acl_smtp_mail = acl_check_mail
    acl_smtp_quit = acl_check_quit
    acl_smtp_notquit = acl_check_notquit
    IPNOTIF = echo Subject: blocked $sender_host_address $acl_c_country \
      ${sg{${lookup dnsdb{>, defer_never,ptr=$sender_host_address}}}{\N[^\w.,-]\N}{}}; \
      echo; echo for bruteforce auth cracking attempt.; 
    WRONG_RCPT_LIMIT = 100
    PERIOD = 1h
    WARNTO = abuse@example.com
    SHELL = /bin/sh
    # these two masks are used only in case of IPv6:
    # how many IPv6 addresses you give to your single user:
    MASKL = ${if match{$acl_m_user}{:}{/64}}
    # how many external IPv6 addresses you treat as one attacker:
    MASKW = ${if match{$sender_host_address}{:}{/56}}

In the WARNTO line replace `abuse@example.com` with your
abuse or support or sysadmin email address.

Immediately after the "begin acl" line insert:

    acl_check_auth:
      drop  message = authentication is allowed only once per message in order \
                      to slow down bruteforce cracking
            set acl_m_auth = ${eval10:0$acl_m_auth+1}
            condition = ${if >{$acl_m_auth}{2}}
            delay = 22s
    
      drop  message = blacklisted for bruteforce cracking attempt
            set acl_c_authnomail = ${eval10:0$acl_c_authnomail+1}
            condition = ${if >{$acl_c_authnomail}{4}}
            condition = ${if exists{$spool_directory/blocked_IPs}\
                             {${lookup{$sender_host_address}iplsearch\
                               {$spool_directory/blocked_IPs}{0}{1}}}\
                             {1}}
            acl = setdnslisttext
            continue = ${run{SHELL -c 'echo \\\"$sender_host_addressMASKW\\\" \
               >>$spool_directory/blocked_IPs; \
               \N{\N IPNOTIF \N}\N | $exim_path -f root WARNTO'}}

      drop  message = blacklisted for bruteforce cracking attempt
            condition = ${if >{$acl_c_authnomail}{4}}
    
      accept set acl_c_authhash = ${if match{$smtp_command_argument}\
                      {\N(?i)^(?:plain|login) (.+)$\N}{${nhash_1000:$1}}}
    
    acl_check_quit:
      warn  condition = $authentication_failed
            condition = ${if def:acl_c_authhash}
            ratelimit = 0 / 5m / strict / $sender_host_address-$acl_c_authhash
            set acl_c_hashrate = ${sg{$sender_rate}{[.].*}{}}
    
      warn  condition = $authentication_failed
            logwrite = :reject: quit after authentication failed: \
                                ${sg{$sender_rcvhost}{\N[\n\t]+\N}{\040}}
            condition = ${if or{\
                                {!def:acl_c_authhash}\
                                {<{$acl_c_hashrate}{2}}\
                               }}
            ratelimit = 7 / 5m / strict / per_conn
            condition = ${if exists{$spool_directory/blocked_IPs}\
                             {${lookup{$sender_host_address}iplsearch\
                               {$spool_directory/blocked_IPs}{0}{1}}}\
                             {1}}
            acl = setdnslisttext
            continue = ${run{SHELL -c 'echo \\\"$sender_host_addressMASKW\\\" \
               >>$spool_directory/blocked_IPs; \
               \N{\N IPNOTIF \N}\N | $exim_path -f root WARNTO'}}
    
    acl_check_notquit:
      warn  condition = $authentication_failed
            condition = ${if def:acl_c_authhash}
            ratelimit = 0 / 2h / strict / $sender_host_address-$acl_c_authhash
            set acl_c_hashrate = ${sg{$sender_rate}{[.].*}{}}
    
      warn  condition = $authentication_failed
            logwrite = :reject: $smtp_notquit_reason after authentication failed: \
                                ${sg{$sender_rcvhost}{\N[\n\t]+\N}{\040}}
            condition = ${if eq{$smtp_notquit_reason}{connection-lost}}
            condition = ${if or{\
                                {!def:acl_c_authhash}\
                                {<{$acl_c_hashrate}{2}}\
                               }}
            ratelimit = 7 / 2h / strict / per_conn
            condition = ${if exists{$spool_directory/blocked_IPs}\
                             {${lookup{$sender_host_address}iplsearch\
                               {$spool_directory/blocked_IPs}{0}{1}}}\
                             {1}}
            acl = setdnslisttext
            continue = ${run{SHELL -c 'echo \\\"$sender_host_addressMASKW\\\" \
               >>$spool_directory/blocked_IPs; \
               \N{\N IPNOTIF \N}\N | $exim_path -f root WARNTO'}}
    
    acl_check_mail:
      accept set acl_c_authnomail = 0
    
    acl_check_connect:
      drop  message = $sender_host_address locally blacklisted for a bruteforce \
                      auth (username+password) cracking attempt
            condition = ${if exists{$spool_directory/blocked_IPs}}
            condition = ${lookup{$sender_host_address}iplsearch\
                         {/var/..$spool_directory/blocked_IPs}{1}{0}}
            # Another path to the same file in order to circumvent lookup caching.
    
      accept
    
    acl_check_helo:
      drop  message = Cutwail/PushDo bot blacklisted
            condition = ${if eq{$sender_helo_name}{ylmf-pc}}
      acl = setdnslisttext
      continue = ${run{SHELL -c 'echo \\\"$sender_host_addressMASKW\\\" \
         >>$spool_directory/blocked_IPs; \
         \N{\N IPNOTIF \N}\N | $exim_path -f root WARNTO'}}
      # if this bot is dropped at helo, it repeats multiple times,
      # but if dropped at connect, it tries only twice
    
      accept
    
    setdnslisttext:
      accept dnslists = all.ascc.dnsbl.bit.nl
             set acl_c_country = ${if match{$dnslist_text}{ CC=(\\S+) }{$1}}
    
      accept
   
    hash:
      accept set acl_c_authhash = ${nhash_1000:$acl_arg1}

Each authenticator  must contain `server_set_id` line. After the
`begin authenticators` line if the paragraph with PLAIN contains
`driver = plaintext` then it must contain `server_set_id = $auth2`,
if the paragraph with LOGIN contains `driver = plaintext` then it must contain
`server_set_id = $auth1`.

If you use Exim version 4.82 or higher and `driver = plaintext` after
`begin authenticators`
then in the paragraph with `PLAIN` append (without a blank) at the very end of
`server_condition` line: `${acl{hash}{$auth2,$auth3}}` and in the paragraph
with `LOGIN` append at the very end of `server_condition` line:
`${acl{hash}{$auth1,$auth2}}`. For example:

      server_condition = ${if pam{$auth2:${sg{$auth3}{:}{::}}}}${acl{hash}{$auth2,$auth3}}

When your staff receives a message with Subject like
`blocked 115.150.81.95 cn`, just check that the IP-address is
unknown for you (in this example China) - it's who attempted
to crack passwords.

When your staff receives a message with Subject like
`user johndoe@yourisp.com blocked`, it means that using this user's
password multiple messages were sent through your server,
and during last hour 100 of recipient email addresses were rejected 
(5xx) by recipient MXs. This is very unlikely with honest users,
but typical for spammers. You can look in your logs
which recipient email addresses were rejected by your Exim:

    cd /var/log/exim;
    zcat mainlog*.* | fgrep 'Unknown user' | fgrep -v 'sender verify fail' | sed -E -e 's/^.+<.*<//' -e 's/>.+$//' | sort | uniq -c | sort -nr | less

Besides role accounts nonexistent on your domains like
webmaster@, sales@, office@, you'll see Message-IDs,
pieces of email addresses, pieces glued with random pieces of words.
For example, there were 540 attempts to spam a never existing address
on my domain `x-originating-ipa@lena.kiev.ua`.
Spammers will try to send through your relay (using passwords
stolen from your users) to multiple nonexistent addresses too.
When your staff receives notification with `Subject: user ... blocked`,
using `exipick` command (it's installed with Exim) look at content of messages
frozen in the queue sent with the username specified in the notification,
for example:

    exipick -zi '$h_X-Authenticated-As eq johndoe@yourisp.com' | xargs -n 1 exim -Mvc | less

If you see not spam (very unlikely) then using a text editor
delete the line with that username from the file `blocked_authenticated_users`
in Exim spool directory, for example `/var/spool/exim/` in FreeBSD
(if the file contains only one line which is likely
then you can just delete the file instead)
and unfreeze detained messages:

    exipick -zi '$h_X-Authenticated-As eq johndoe@yourisp.com' | xargs exim -Mt

If you see spam then change the user's password, notify the user
and delete the line or file (see previous paragraph).
In order for the user to really get it,
provide a clause in the user agreement or contract beforehand:
if the user's password was used for spam (no matter who spammed -
the user or somebody else) then the user pays a fine.
Spam frozen in the queue is evidence.
When the evidence is not needed anymore, delete the frozen spam:

    exipick -zi '$h_X-Authenticated-As eq johndoe@yourisp.com' | xargs exim -Mrm

Similarly with users on LAN or the ISP's IP-ranges
(file `blocked_relay_users`,
notifications with Subject like `relay user 192.168.12.34 blocked`).

### How to use this approach to block outgoing spam submitted locally such as from web-server (for web-hosting admins):  

After reading the above, a web-hosting admin asked me how to use
this approach to block outgoing spam from webhosting accounts -
malicious or compromised because a webhosting user installed
vulnerable version of soft such as WordPress or Joomla.
Web scripts can submit mail either via SMTP to localhost or not via SMTP
(via pipe to `sendmail` binary which calls exim).
I was told that PHP's `mail()` function submits not via SMTP, at least usually.
When not via SMTP, instead of the `rcpt` ACL for each recipient,
the `not_smtp` ACL is executed once per message with possibly several
email addresses in `$recipients`, but each recipient needs to be
verified separately - I contrived how:

If not via SMTP, and each webhosting user/client's scripts run under
unique userid, and Exim version 4.82 or higher, then (untested):

    acl_not_smtp = acl_check_not_smtp
    UNLIMITED_USERIDS = root : toor : cron : mailnull : mail : exim : somethingelse
    # "mailnull" is Exim user id under FreeBSD, "mail" under some other OSes.
    WRONG_RCPT_LIMIT = 100
    PERIOD = 1h
    WARNTO = abuse@example.com
    SHELL = /bin/sh
    
    begin acl
    acl_check_not_smtp:
      accept set acl_m_user = $authenticated_id
            condition = ${if inlist{$acl_m_user}{UNLIMITED_USERIDS}}
    
      discard condition = ${if exists{$spool_directory/blocked_notsmtp_users}}
            set acl_m_wasfree = ${lookup{$acl_m_user}lsearch\
                          {$spool_directory/blocked_notsmtp_users}}
            condition = ${if match{$acl_m_wasfree}{\N^\d+$\N}}
            condition = ${if match{$spool_space}{\N^\d+$\N}}
            condition = ${if <={$spool_space}{${eval:$acl_m_wasfree/2}}}
            log_message = free space on spool disk $spool_space KB - less than \
                          half than it was when the user $acl_m_user was blocked
    
      accept condition = ${if exists{$spool_directory/blocked_notsmtp_users}}
            condition = ${lookup{$acl_m_user}lsearch\
                        {$spool_directory/blocked_notsmtp_users}{1}{0}}
            control = freeze/no_tell
            add_header = X-Username: $acl_m_user
    
      accept condition = ${if forany{<, $recipients}\
                                    {eq{${acl{recipient}{$item}}}{caught}}}
            continue = ${run{SHELL -c "echo $acl_m_user:$spool_space \
               >>$spool_directory/blocked_notsmtp_users; \
               \N{\N echo Subject: local user $acl_m_user blocked; echo; echo because \
               has sent mail to WRONG_RCPT_LIMIT invalid recipients during PERIOD.; \
               \N}\N | $exim_path -f root WARNTO"}}
            control = freeze/no_tell
            add_header = X-Username: $acl_m_user
    
      accept
    
    recipient:
      accept condition = ${if match{$acl_arg1}{\N[$/"'`\\]\N}}
    
      accept !verify = sender=$acl_arg1/defer_ok/callout=10s,defer_ok
            ratelimit = WRONG_RCPT_LIMIT / PERIOD / per_cmd / notsmtpuser-$acl_m_user
            message = caught
    
      accept

You can either disable mail from webserver via SMTP to localhost
or use `identd` daemon, then username should be in `$sender_ident`.
In case of FreeBSD the `ident` service is provided by inetd, see `man inetd`:
in `/etc/inetd.conf` uncomment after `Provide internally a real "ident" service`,
in `/etc/rc.conf` `inetd_enable="YES"` and
`/etc/rc.d/inetd start`
or `restart`), in Exim config

    rfc1413_hosts = *
    rfc1413_query_timeout = 2s

[Lena](Lena)


### Restricting logins to the user's "home country":

Another approach to this, is to restrict the user's login ability to the user's "home country". With "home country", its meant to be the country from which the user residental adress is, did pay their webhosting bill from (country of credit card or bank account), or in case of free account, the country from which the user registred (IP Country) or from which country the user validated their phone number or similiar from.

For this, you need to append the 2 letter country to their password, which can be done next time they login to webmail or webadmin, and then use a custom authenticator to append the user's 2 letter country to their password when they login over SMTP. Note that the same transformation also needs to be done on IMAP login.

By "locking" the user's login to their home country, you drastically reduce the attack surface as logins which originate from the incorrect country will automatically have an invalid password, and thus fail authentication.

Of course, if you are only providing service to customers in specific countries, for example if the payment method offered is only available for citizens in a specific country, its much better to set auth_advertise_hosts to the list of CIDR ranges used in those countries, thus completely locking out authentication attempts from "foregin" countries.
