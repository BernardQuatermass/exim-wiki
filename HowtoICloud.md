# How to use iCloud as an outgoing mail server

For development machines, it is useful to send each and every mail to the same e-mail adress. This way mails can't "leak" into the real world.

I have set up Exim on my development machines to use Apple iCloud as the outgoing MTA, rewriting all mail to my own e-mail adress. The subject clearly indicates that this mail is coming from a development machine.

As setting up exim like this isn't obvious. You need to rewrite all From's and the To, and use the correct authentication method

To setup exim like that, use (and modify) the following exim.conf:

---

    # Exim config file for dev server: always send all mail to a single e-mail adress, using Apple iCloud

    # We don't have IPv6
    disable_ipv6 = true

    OUTGOINGSMTP = smtp.mail.me.com
    SMTP_PORT = 587
    SENDALLMAILTO = your_email@address
    SENDALLMAILFROM = your_email@address
    SUBJ_INTRO = Development -
    SMTP_USERID = your_icloud_userid@me.com
    SMTP_PASSWD = your_icloud_password
    local_interfaces = 127.0.0.1
    # Access list definitions
    acl_smtp_mail = accept_all
    acl_smtp_rcpt = accept_all
    acl_smtp_data = accept_all
    # The actual access lists (accept all, for debugging purposes)
    begin acl
    accept_all: accept
    # The routers: Only one to send to the SMTP gateway
    begin routers
    send_to_gateway:
      #Modify the Subject, to indicate it is a special mail
      headers_remove = Subject
      headers_add = "Subject: SUBJ_INTRO $h_subject"
      driver = manualroute
      transport = remote_smtp
      route_list = * OUTGOINGSMTP
      no_more
    #Transports
    begin transports
    remote_smtp:
      # Send to the following SMTP server
      driver = smtp
      port = SMTP_PORT
      hosts_require_auth = OUTGOINGSMTP
      hosts_require_tls = OUTGOINGSMTP
      hosts_try_auth = OUTGOINGSMTP
    begin authenticators
    login:
      driver = plaintext
      public_name = LOGIN
      hide client_send = : SMTP_USERID : SMTP_PASSWD
    # IMPORTANT: Always rewrite the destination e-mail address
    # For iCloud, rewriting the From address is necessary too.
    begin rewrite
    *@* SENDALLMAILTO   T
    *@* SENDALLMAILFROM Ff