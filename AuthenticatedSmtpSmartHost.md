Authenticated Outgoing SMTP
===========================

Introduction
------------

This in a situation where you need to use an outgoing mail relay
(smarthost) that requires authentication. ISPs sometimes need this, they
may block outgoing SMTP to force you to use their MTAs and then require
authentication.

Required Software:
------------------
-   Exim 4.x

Configuring exim
----------------

You will need to configure a router, a transport and the authenticator
sections. You will also need to configure a file to contain the
password.

In this example, the smarthost is at *smarthost.isp.com*

### Router configuration

Add a router like this:

    outgoing:
      driver = manualroute
      domains = ! +local_domains
      transport = IspSmarthost
      route_list = * smarthost.isp.com

### Transport configuration

    IspSmarthost:
      driver = smtp
      hosts_try_auth = isp_auth

### Authenticator configuration

    begin authenticators

    cram_md5:
         driver = cram_md5
         public_name = CRAM-MD5
         client_name = "${extract{auth_name}{${lookup{$host}lsearch{/etc/exim/smtp_users}{$value}fail} }}"
         client_secret = "${extract{auth_pass}{${lookup{$host}lsearch{/etc/exim/smtp_users}{$value}fail} }}"
    plain:
         driver = plaintext
         public_name = PLAIN
         client_send = "${extract{auth_plain}{${lookup{$host}lsearch{/etc/exim/smtp_users}{$value}fail} }}"

### Contents of password lookup file

The file */etc/exim/smtp\_users* will contain lines like:

    isp_auth:     auth_name=my_username   auth_pass=secret        auth_plain=^my_username^secret

You substitute appropriate values for *my\_username* and *secret*.

### See also

[http://www.tgunkel.de/docs/exim\_smarthosts.en](http://www.tgunkel.de/docs/exim_smarthosts.en)

[http://www.hserus.net/wiki/index.php/Exim](http://www.hserus.net/wiki/index.php/Exim)

[http://linux.derkeiler.com/Mailing-Lists/Debian/2005-02/1926.html](http://linux.derkeiler.com/Mailing-Lists/Debian/2005-02/1926.html)

* * * * *

> [CategoryHowTo](CategoryHowTo) [HowTo](../HowTo)
