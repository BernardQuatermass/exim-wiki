How to authenticate users using NTLM (a.k.a. MS SPA).

There are two different strategies. The first one is to authenticate
users on a standalone mail server, without the support of any Domain
Controller, but requires the use of a plaintext password file. The
second strategy is to delegate the authentication to a Domain Controller
that support NTLM itself.

Standalone solution
===================

Use the spa driver to implement the standalone NTLM authentication.
Simply put the following lines into the authentication section of the
exim config files.

    ######################################################################
    #                   AUTHENTICATION CONFIGURATION                     #
    ######################################################################

    begin authenticators

    spa_auth:
      driver = spa
      public_name = NTLM
      server_password = ${lookup{$1}lsearch{/etc/exim4/spa_clearpass}}
      server_set_id = $2

You must also edit the file /etc/exim4/spa\_clearpass and put in it
account data as in the following example.

    ######################################################################
    #                       AUTHENTICATION DATA                          #
    ######################################################################

    myusername:       plain_password
    myusername2:      plain_password2

NOTE: The SPA authenticator requires the client machine to be running
NTLM version 1. Recent updates to XP break this. Vista also breaks this.
To fix this on the client:

(usual caveats about changing the registry apply)

1.  Run the registry editor and open this key:

HKEY\_LOCAL\_MACHINESYSTEMCurrentControlSet\_ControlLsa

1.  If it doesn't already exist, create a DWORD value named
    [LmCompatibilityLevel](LmCompatibilityLevel)

2.  Set the value to 1

3.  Reboot

The new version of NTLM is described here:
[http://download.microsoft.com/download/9/5/e/95ef66af-9026-4bb0-a41d-a4f81802d92c/%5bMS-SMTP%5d.pdf](http://download.microsoft.com/download/9/5/e/95ef66af-9026-4bb0-a41d-a4f81802d92c/%5bMS-SMTP%5d.pdf)

Authentication through a Domain Controller
==========================================

This second approach uses cyrus\_sasl driver to perform authentication.
Add the following lines to the authentication section of the exim
configuration.

    ######################################################################
    #                   AUTHENTICATION CONFIGURATION                     #
    ######################################################################

    begin authenticators

    sasl_auth:
        driver = cyrus_sasl
        public_name = NTLM
        server_realm = <YOUR-DOMAIN-NAME>
        server_set_id = $1

The sasl NTLM authentication scheme needs to forward authentication
requests to a server capable of handling them (in my case a Windows 2000
server). The NTLM server address can be defined in the sasl exim
configuration file (on a debian sarge /usr/lib/sasl2/exim.conf).

    ntlm_server: mydomaincontroller.domain.org

You should read the sasl\_getpath\_t man page to discover the system
default configuration file path.

See also
========

[AuthenticatedSmtpUsingIMAP](AuthenticatedSmtpUsingIMAP), to learn
how to enable cyrus\_sasl driver.

[How to set configuration
options](http://www.sendmail.org/~ca/email/cyrus/sysadmin.html#saslconf),
to learn more about sasl configuration files.
