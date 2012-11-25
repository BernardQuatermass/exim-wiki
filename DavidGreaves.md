I'm a casual user of exim in my home network.

I have a [CyrusImap](CyrusImap) server which I use to access my mail
from wherever I am.

Setup
=====

Incoming mail arrives at my ISP and is popped using fetchmail (which
runs on the imap machine). It is then lmtp'ed into the imap server.

Outgoing mail is sent via a smarthost (smtp). In the event of 'local'
mail hitting the smarthost, it is then forwarded to exim running on the
imap server which also uses lmtp to deliver it.

I intend to allow fetchmail to deliver via smtp to the exim server.

My Alternate Exim Configuration
-------------------------------

This uses exim on the imap host to receive the mail and forward it
through a unix socket.

### Domain List

    domainlist local_domains = <your domains here>

### Routers

    localuser:
      driver = accept
      transport = lmtp_delivery

### Transport

    lmtp_delivery:
      driver = lmtp
      socket = /var/imap/socket/lmtp
      delivery_date_add
      envelope_to_add
      return_path_add
      user = mail
