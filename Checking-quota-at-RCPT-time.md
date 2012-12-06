**ATTENTION:**
This procedure is for **virtual users with Maildir style mail spools** only!

Exim normally accepts an email, then a transport actually checks to see if the account is over quota.  If it's over quota, the email sits in the queue and occasionally the queue runner will retry to deliver it. This page describes how to configure your exim to check a user's quota before it accepts the email, thus keeping your queue less cluttered.  It requires a small helper daemon that actually computes the quota used because depending on your user and filesystem configuration (for example nfs Maildir's with root squash), exim may not be able to access the maildirsize files.  Your system must also be of the type that the Maildir can be figured out or constructed, possibly duplicating any lookups in the 

First, the perl script requires a few perl packages, and the init script needs a couple of directories to exist.  This is for CentOS 5.x boxen, it shouldn't be much different for other Linux distros:
```# Packages are in RPMForge (i.e. Dag) repo
yum install perl-Log-Handler perl-Proc-Daemon
mkdir /var/log/helper /var/run/helper
chown vmail: /var/log/helper /var/run/helper
```

Second, we need to add some macros to `exim.conf`:
```OVERQUOTA_CHECK = ${readsocket{inet:localhost:8049}{CHECK_QUOTA $local_part $domain}}
OVERQUOTA_DATA = ${readsocket{inet:localhost:8049}{SHOW_QUOTA $local_part $domain}}
```

Third, somewhere in the *RCPT* acl before first accept statement in `exim.conf`:
```  defer   domains        = +local_domains
          condition      = ${if eq{OVERQUOTA_CHECK}{1} {yes}{no}}
          message        = The mailbox for $local_part@$domain is full, deferring.
          log_message    = Recipient mailbox is full, deferring.
```
The `message` modifier is what is displayed to the remote mail server that is attempting to send to this recipient.  The `log_message` modifier is what is logged into your local logs.  The sender and recipient are already present as part of the logged message, so no need to duplicate that info.

Fourth, you need the perl daemon, which I've named [exim-policyd](attachments/exim-policyd).

Fifth, you need an init script to start and stop the daemon [exim-policyd.init](attachments/exim-policyd.init).