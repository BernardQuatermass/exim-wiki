# Blacklisting

Here's a few popular and fairly safe blacklists. Let's have some other lists added and some comments as to how reliable the lists are.

```
drop    message = REJECTED - ${sender_host_address} is blacklisted at $dnslist_domain ($dnslist_value); ${dnslist_text}
        dnslists = sbl-xbl.spamhaus.org/<;$sender_host_address;$sender_address_domain

drop    message = REJECTED - ${sender_address_domain} is blacklisted at ${dnslist_domain}; ${dnslist_text}
        dnslists = nomail.rhsbl.sorbs.net/$sender_address_domain

drop    message = REJECTED - ${sender_host_address} is blacklisted at ${dnslist_domain}; ${dnslist_text}
        dnslists = bl.spamcop.net : cbl.abuseat.org : list.dsbl.org
```