starttls-everywhere is a stopgap until a host can do DANE.  Organised by the EFF, there's a website at https://starttls-everywhere.org/

The idea is that you preload your site with security information for sites you may need to send mail to, and check this information any time to connect to them.  There's a file to download with a set of records, which you lookup using the email recipient domain as an index.  If the domain is listed it must talk TLS, it must have a verifiable certificate, and you should talk to it at an MX host matching one of the patterns given.

The policy file currently has a declared lifetime of a couple of weeks, so you need to download a fresh version more often than that.

Assuming you have a good file (it comes with a signature, so you can verify that) you can tell if
- your connection is being intercepted and STARTTLS-stripped, to force you to talk unencrypted
- your connection is being diverted to an intercepting server unable to present you a verifiable certificate
The MX-host checking is somewhat less useful; an adversary could manipulate the PTR responses about as easily as the MX responses.
---
Currently the policy file is fairly small; 37kB of JSON.  The obvious way of using it for Exim would be to pull it apart
using some putative JSON utility into a set of flat files suitable for Exim lookups.  I've not done that yet.

What I have done is add (for a future Exim version, probably 4.93) a JSON lookup expansion for Exim.  Here's how it can be used to impliment starttls-everywhere directly against the downloaded JSON policy file:

Build-time requirements:
- Embedded perl.  This is for checking the file expiry.  You could avoid it if you only care about, say, 1-day precision and don't mind a bit more hackery done in expansions.
- LOOKUP_JSON.  The new lookup type mentioned above, for searching in the policy file.
- Events.  An event-triggered check is used for the MX-enforcement.

System requirements:
- The Date::Parse module for perl.
- A regular download and verification of the starttls-everywhere policy file

Exim configuration:
- An ancillary perl file with the line "use Date::Parse;"
- main option perl_startup
- a macro STARTTLS_EVERYWHERE giving the path of the policy file
- the following block of ACLs :-
~~~
starttls_expired:
  # This relies on having a perl_startup file containing "use Date::Parse;"
  accept        set acl_m_exp = ${lookup {expires} json {STARTTLS_EVERYWHERE}}
                condition =     ${if !def:acl_m_exp}
  accept        set acl_m_exp = ${sg {${perl {str2time}{$acl_m_exp}}} {^(\\d*).*}{\$1}}
                condition =     ${if !def:acl_m_exp}
  accept        condition =     ${if > {$tod_epoch}{$acl_m_exp}}

# arg1: domain
# Return policy record
starttls_policy:
                # If no policy, tls not required
  accept        condition =     ${if !exists{STARTTLS_EVERYWHERE}}
  accept        set acl_m_st =  ${lookup {policies : $acl_arg1} json {STARTTLS_EVERYWHERE}}
                condition =     ${if !def:acl_m_st}
                # If expired, tls not required
  accept        acl =           starttls_expired
                logwrite =      WARNING: starttls-everywhere policy file has expired
  accept        set acl_m_al =  ${extract json{policy-alias}{$acl_m_st}}
                condition =     ${if !def:acl_m_al}
                message =       $acl_m_st
  accept        message =       ${lookup {policy-aliases : ${sg {$acl_m_al} {\N^"(.*)"$\N} {\$1}}} \
                                    json {STARTTLS_EVERYWHERE}}

# arg1: policy record  arg2: nonempty-warn
# Return empty or "*"
starttls_require:
  accept        condition =     ${if !def:acl_arg1}
  accept        set acl_m_mo =  ${extract json {mode}{$acl_arg1}}
                condition =     ${if def:acl_arg2}
                condition =     ${if eq {\"testing\"}  {$acl_m_mo}}
                logwrite =      WARNING: TLS required but not acheived for $domain
  accept        condition =     ${if !eq {\"enforcing\"}{$acl_m_mo}}
  accept        message =       *
                logwrite =      NOTE: TLS resuired for $domain per starttls_everywhere

# check one name against list of REs
arg1: hostname  arg2: pattern-list
mx_chk:
  accept        condition =     ${if forany {$acl_arg2} {match {$acl_arg1}{$item}}}

starttls_mxs_chk:
  accept        condition =     ${if !eq {tcp:connect}{$event_name}}
  accept        set acl_m_po =  ${extract {st}{$address_data}}
                condition =     ${if !def:acl_m_po}
  accept        condition =     ${if !eq {\"enforcing\"}{${extract json {mode}{$acl_m_po}}}}
                # mxs list from json policy record
  accept        set acl_m_mx =  ${extract json {mxs}{$acl_m_po}}
                # strip [] json array wrap
                set acl_m_mx =  ${sg {$acl_m_mx} {^.(.*).\$} {\$1}}
                # strip "" json string wrap from each element
                set acl_m_mx =  ${map {<, $acl_m_mx} {${sg {$item} {^.(.*).\$} {\$1}}}}
                # convert each element to an RE
                set acl_m_mx =  ${map {<, $acl_m_mx} {${if eq {.}{${l_1:$item}} {$item\$}{^$item\$}}}}
                set acl_m_mx =  ${sg {$acl_m_mx} {\N\.\N} {\N\\.\N}}
                # check the rDNS list of names for this IP against the list of REs
                condition =     ${if forany {${lookup dnsdb {ptr=$host_address}}} \
                                    {acl {{mx_chk} {$item}{<, $acl_m_mx}}}}

starttls_mxs:
  accept        !acl =          starttls_mxs_chk
                logwrite =      NOTE: $host_address does not match required-MX list \
                                        for $domain per starttls-everywhere
                message =       noconnect
  accept        acl =           log_deliv
~~~
- In every router that sends mails offsite, set address_data to the value returned by the starttls_policy ACL. I add it as a tagged-element here because I use address_data for other information as well, but YMMV:
~~~
dnslookup:
  driver =              dnslookup
  domains =             ! +filter_for_domains
  transport =           remote_smtp
  address_data =        if=${quote:OUTBOUND_IF} \
                        st=${quote:${acl {starttls_policy}{$domain}}}
~~~
- In every transport that sends mails offsite, call the starttls_require ACL to see whether to enforce TLS and verifiable certificates, and the starttls_mxs ACL to do MX-checking:
~~~
  hosts_require_tls =   ${acl {starttls_require} {${extract {st}{$address_data}}} {warn}}
  tls_verify_hosts =    ${acl {starttls_require} {${extract {st}{$address_data}}}}
  event_action =        ${acl {starttls_mxs}}
~~~
