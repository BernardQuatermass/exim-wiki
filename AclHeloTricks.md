This section contains tricks to identify spam based on the HELO message.

The examples below use "drop"; you may prefer to use "deny", in which
case you might also consider adding something like

    deny
        condition = ${if eq{$sender_helo_name}{}}
        message   = HELO required before MAIL

to your `acl_smtp_mail`.

Invalid HELO
============

What is valid?
--------------

*Valid* HELOs are according to RFC2821 4.1.1.1:
-   some.domain.name
-   [\<ipv4-address\>]
-   [\<ipv4-address\>] optional arbitrary information, maybe with a
    finishing dot
-   [IPv6:\<ipv6-address\>]
-   [IPv6:\<ipv6-address\>] optional arbitrary information

RFC2821 is ambiguous about the "optional arbitrary information" after
address literals; it says

    In situations in which the SMTP client system does not have a meaningful domain name ... the client
    SHOULD send an address literal ... optionally followed by information that will help to identify
    the client system.

However it later goes on to specify that the syntax is (in part):

    ehlo            = "EHLO" SP Domain CRLF
    helo            = "HELO" SP Domain CRLF

    Domain = (sub-domain 1*("." sub-domain)) / address-literal

    address-literal = "[" IPv4-address-literal /
                          IPv6-address-literal /
                          General-address-literal "]"
          ; See section 4.1.3

which leaves no scope for "optional arbitrary information" tagged onto
the end of the HELO.

Invalid HELOs
-------------

If you want to strictly apply the RFCs then all other HELOs are invalid.
Here follow some recipes for detecting and blocking some of the more
common types of invalid HELO.

### HELO is an open Proxy or Subnet

*Type: syntax error*

    drop   message        = Open Proxy in HELO/EHLO (HELO was $sender_helo_name)
           condition      = ${if eqi {$sender_helo_name} {$sender_host_address}{no}{yes}}
           condition      = ${if isip {$sender_helo_name} {yes}{no}}
           delay          = 45s

### HELO is an IP address

*Type: syntax error*

    drop
        condition   = ${if isip{$sender_helo_name}}
        message     = Access denied - Invalid HELO name (See RFC2821 4.1.3)

A plain IP address is not allowed. It needs to be an address literal,
i.e. an IP address enclosed in [ ].

### HELO contain a IP part

*Type: syntax error*

    drop   message        = Helo name contains a ip address (HELO was $sender_helo_name) and not is valid
           condition      = ${if match{$sender_helo_name}{\N((\d{1,3}[.-]\d{1,3}[.-]\d{1,3}[.-]\d{1,3})|([0-9a-f]{8})|([0-9A-F]{8}))\N}{yes}{no}}
           condition      = ${if match {${lookup dnsdb{>: defer_never,ptr=$sender_host_address}}}{$sender_helo_name}{no}{yes}}
           delay          = 45s

The helo name contain x-x-x-x or x.x.x.x in name and name is fake.

### HELO contain my domains, subdomains or my interface by dns lookup

*Type: syntax error*

    drop   message        = No you are not ME or OURS (HELO was $sender_helo_name and equal my local domains or my domains relay)   
           condition      = ${if match_domain{$sender_helo_name}{+local_domains:+alias_domains:+relay_to_domains}{yes}{no}}
           delay          = 45s
    drop   message        = No you are not Me or OURS (HELO was $sender_helo_name and the subdomain is my domain ${extract{-3}{.}{$sender_helo_name}}.${extract{-2}{.}{$sender_helo_name}}.${extract{-1}{.}{$sender_helo_name}})
           condition      = ${if match_domain{${extract{-3}{.}{$sender_helo_name}}.${extract{-2}{.}{$sender_helo_name}}.${extract{-1}{.}{$sender_helo_name}}}{+local_domains:+alias_domains:+relay_to_domains}{yes}{no}}
           delay          = 45s
    drop   message        = No you are not ME or OURS (HELO was $sender_helo_name and equal my interface hostname)
           condition      = ${if !def:interface_address {no}{yes}}
           condition      = ${if match_ip{$interface_address}{${lookup dnsdb{>: defer_never,a=$sender_helo_name}}}{yes}{no}}
           delay          = 45s

### HELO not contain a full host (ex: host.domain.com)

*Type: syntax error*

    drop   message        = Invalid domain or IP given in HELO/EHLO (HELO was $sender_helo_name)
           condition      = ${if match{$sender_helo_name}{.+\\\..+\\\..+}{no}{yes}}
           !authenticated = *
           !senders       = wildlsearch;/etc/exim4/lst/skp_helodot
           !hosts         = +ignore_defer : +ignore_unknown : +relay_from_hosts : net-iplsearch;/etc/exim4/lst/skp_heloadsl
           condition      = ${if match_ip{$sender_host_address}{${lookup dnsdb{>: defer_lax,a=${lookup dnsdb{>: defer_lax,mxh=$sender_address_domain}}}}}{no}{yes}}
           delay          = 45s

To skip check, put a hosts in skp\_heloadsl list. Skip if is a MX of
domain or SPF (if exists). Put this in check\_mail.

### HELO is neither FQDN nor address literal

*Type: syntax error*

    drop
        # Required because "[IPv6:<address>]" will have no .s
        condition   = ${if match{$sender_helo_name}{\N^\[\N}{no}{yes}}
        condition   = ${if match{$sender_helo_name}{\N\.\N}{no}{yes}}
        message     = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)

Neither an address literal nor something containing dots.

    drop
        condition   = ${if match{$sender_helo_name}{\N\.$\N}}
        message     = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)

Something ending with a dot.

DISCUSSION: If I understand rfc2821 4.1.3 correctly, helo might end with
a dot (see examples above).

    drop
        condition   = ${if match{$sender_helo_name}{\N\.\.\N}}
        message     = Access denied - Invalid HELO name (See RFC2821 4.1.1.1)

Something containing two subsequent dots. Wouldn't be good for FQDN nor
IP address.

### HELO is my hostname

*Type: forgery*

Sometimes spammers impersonate the hostname of the MX they are
delivering their junk to. This ACL drops those connections. Since only
spam tools seem to use such an HELO, this ACL is pretty safe.

    drop  message   = "REJECTED - Bad HELO - Host impersonating [$sender_helo_name]"
          condition = ${if match{$sender_helo_name}{$primary_hostname}}

### HELO is one of my Domains

*Type: forgery*

Sometimes spammers will try to send spam by impersonating one of our
domains in the HELO. This ACL assumes that you have a domainlist called
all\_mail\_handled\_locally.

Be sure to use this AFTER your authenticated SMTP and other bless email
that you will forward for, since some mail clients use the domain part
of the senders address as the HELO string.

    drop  message = "REJECTED - Bad HELO - Host impersonating [$sender_helo_name]"
          condition = ${if match_domain{$sender_helo_name}{+all_mail_handled_locally}{true}{false}}

(There is a small chance that mail which uses this kind of HELO is
actually valid; e.g. company *example.com* might have a web server whose
canonical hostname is *example.com*. If you handle mail for that domain,
then the web server could legitimately connect to your mail server and
say "HELO example.com". However that is pretty theoretical; I've never
seen that actually happen in practice.)

### HELO is faked interface address

*Type: forgery*

Some spammers put the server's interface address they connect to in
their HELO, maybe asuming it is whitelisted or something.

    drop condition = ${if eq{[$interface_address]}{$sender_helo_name}}
         message   = $interface_address is _my_ address

Note: If you are running your mail server behind NAT, you should replace
`$interface_address` with your external IP address.

Note: If you have more than one ip-addresses on your's interface use @[]
instead of \$interface\_address, full acl will be:

    drop    message     = Bad helo name
            condition   = ${if  \
                             and{    \
                                 {isip {$sender_helo_name}}  \
                                 {match_ip{$sender_helo_name}{@[]}}  \
                             }{yes}{no}  \
                         }
