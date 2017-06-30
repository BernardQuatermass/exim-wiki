## Blacklist for email addresses in Reply-To and message bodies
The purpose of the EBL blacklist is described on [http://msbl.org/ebl-purpose.html](http://msbl.org/ebl-purpose.html) . I tested EBL since October 2016, in June 2017 it was [declared](https://spammers.dontlike.us/mailman/private/list/2017-June/010493.html) in public beta. How to use EBL in Exim config (requires Exim version 4.87 or higher):

    MLDOMAINS = /usr/local/etc/exim/mailing_list_domains
    acl_smtp_data = acl_check_data
    acl_smtp_mime = acl_check_mime
    acl_not_smtp = acl_check_notsmtp
    acl_not_smtp_mime = acl_check_notsmtpmime
    begin acl
    rt:
      warn	set acl_m_rt = ${sg{${lc:${address:$header_Reply-To:}}}{\\+.*@}{@}}
    	condition = ${if match{$acl_m_rt}{@g(oogle)?mail.com}}
    	set acl_m_rt = ${sg{${local_part:$acl_m_rt}}{\\.}{}}@${domain:$acl_m_rt}
    
      deny	condition = ${if def:acl_m_rt}
    	condition = ${lookup{${domain:$acl_m_rt}}nwildlsearch\
                         {MLDOMAINS}{0}{1}}
    	dnslists = ebl.msbl.org/${sha1:$acl_m_rt}
    	log_message = Reply-To: $header_Reply-To: in EBL: $dnslist_text \
    		From: $header_From:, envelope-from $sender_address, \
    		recipients=$recipients, Subject: $header_Subject:
    	message = spam detected
    		  # 419 (Nigerian) scams often sent by humans, do not tell them
    		  # that the spam was detected with EBL http://msbl.org
    
      accept
    
    mimeea:
      deny	condition = ${if match{$mime_content_type}{text}}
            condition = ${lookup{$sender_address_domain}nwildlsearch\
                         {MLDOMAINS}{0}{1}}
    	mime_regex = \N(?s).*?([\w.+=-]+@\w[\w-]*\.[\w.-]+\w)\
                              (.+?([\w.+=-]+@\w[\w-]*\.[\w.-]+\w))?\
                              (.+?([\w.+=-]+@\w[\w-]*\.[\w.-]+\w))?\
                              (.+?([\w.+=-]+@\w[\w-]*\.[\w.-]+\w))?\
                              (.+?([\w.+=-]+@\w[\w-]*\.[\w.-]+\w))?
    	condition = ${if forany{$regex1 :$regex3 :$regex5 :$regex7 :$regex9}\
                                   {eq{${acl{ea}{$item}}}{caught}}}
    	log_message = email address in body $acl_m_ea in EBL: $dnslist_text \
                    From: $header_From:, envelope-from $sender_address, \
                    recipients=$recipients, Subject: $header_Subject:
            message = spam detected
    
      accept
    
    ea:
      accept condition = ${if eq{}\
    		{${lookup dnsdb{defer_never,mxh=${domain:$acl_arg1}}}}}
    	condition = ${if eq{}\
    		{${lookup dnsdb{defer_never,a=${domain:$acl_arg1}}}}}
    
      warn  set acl_m_ea = ${sg{${lc:$acl_arg1}}{\\+.*@}{@}}
            condition = ${if match{$acl_m_ea}{@g(oogle)?mail.com}}
            set acl_m_ea = ${sg{${local_part:$acl_m_ea}}{\\.}{}}@${domain:$acl_m_ea}
    
      accept condition = ${lookup{${domain:$acl_m_ea}}nwildlsearch\
    			     {MLDOMAINS}{0}{1}}
            dnslists = ebl.msbl.org/${sha1:$acl_m_ea}
            message = caught
    
      accept
    
    acl_check_notsmtp:
      require acl = rt
    
      accept
    
    acl_check_notsmtpmime:
      require acl = mimeea
    
      accept
    
    acl_check_mime:

... (possible other checks before the first "accept")

      require acl = mimeea

... (the first "accept" if any)

      accept
    
    acl_check_data:

... (other checks before the first "accept")

      require acl = rt

... (the first "accept")

The file specified in the MLDOMAINS macro - domains of legitimate mailing lists, add to it others known for you:

    groups.io
    *.groups.io
    ^yahoogroups\.
    returns.groups.yahoo.com
    googlegroups.com
    ^listserv\.
    ^lists\.
    freebsd.org
    exim.org
    mailground.net
    opennet.ru
    subscribe.ru
    njabl.org
    spammers.dontlike.us
    mailop.org
    mutt.org

[Lena](Lena)