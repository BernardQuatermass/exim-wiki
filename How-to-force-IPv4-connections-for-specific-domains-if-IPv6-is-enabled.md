This scenario arose as a result of the ISP providing IPv6 and then not being able to provide reverse PTR records for the IPv6 addresses.  It turns out that RIPE has not given the ISP SOA on that IPv6 subnet yet:
```
;; AUTHORITY SECTION:
0.a.2.ip6.arpa.         3600    IN      SOA     pri.authdns.ripe.net. dns.ripe.net. 1407144119 3600 600 864000 7200
```
As a consequence, some IPv6 capable recipients reject e.g. the following:
```
2014-08-04 12:31:56 1XEGUa-0006Kb-N8 ** invitations@linkedin.com R=dnslookup T=remote_smtp X=TLSv1.2:AES256-GCM-SHA384:256: SMTP error from remote mail server after RCPT TO:<invitations@linkedin.com>: host mail-c.linkedin.com [2620:109:c006:104::215]: 554 5.7.1 The sending mail server at 2a00:xxxx:xxxx:0:xxx:xxx:xxxx:xxxx does not have a reverse (address-to-name) DNS entry cf http://en.wikipedia.org/wiki/Reverse_DNS_lookup
```
### Domainlist

Add a domainlist:
```
domainlist ipv4_force_domains = \
        gmail.com : \
        googlemail.com : \
        virgin.net : \
        linkedin.com : \
        virginmedia.com
```
### Router configuration
Add a router:
```
ipv4_only:
        driver = dnslookup
        domains = +ipv4_force_domains
        transport = ipv4_smtp
        ignore_target_hosts = <; 0::0/0
```
### Transport configuration

Add a transport:
```
    ipv4_smtp:
        driver = smtp
        dkim_domain = mydomain.co.uk
        dkim_selector = x
        dkim_private_key = /usr/exim/dkim.private.key
        dkim_canon = relaxed
        interface = <my.v4.ip.address>
```







