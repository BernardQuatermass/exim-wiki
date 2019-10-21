## Inroduction
If you cannot install the srsd service or do not want to, here is the full configuration to add both SRS0 and SRS1 capabilities to exim as defined at [Wikipedia](https://en.wikipedia.org/wiki/Sender_Rewriting_Scheme) and [libsrs](https://www.libsrs2.org/srs/srs.pdf)

## Exim configuration
_This configuration has been tested on a few thousand servers handling around 20 million emails per day_

Add the following to the top of exim config (usually at /etc/exim/exim.conf) where you define your macros.

`USE_SRS= yes`

Add SRS macros below this as follows:
```
.ifdef USE_SRS
#  The SRS Secret that's been generated for signing SRS-rewritten addresses. 
# **Please replace this with your own**
SRS_SECRET      = myrandomsecretforsrs

# The number of characters to extract from the computed hash and include within the SRS-rewritten address.
# 10 plays well with most MTA's
SRS_HASH_LENGTH = 10

# The modulus at which the age (in days) wraps around. 0xfff = 4095 days = ~11 years
SRS_AGE_MODULUS = 0xfff

# The maximum age (in days) of a valid SRS-rewritten address. Messages arriving for addresses older than this 
# will be rejected. 10 days is my setting, but feel free to change this.
SRS_MAX_AGE     = 10

#
.endif
```

### Set Variables at the start of the acl_smtp_rcpt section of acl's
```
.ifdef USE_SRS
  # SRS CLEAN UP.ifdef USE_SRS
# SRS0=HHH=TT=orig-domain=orig-local-part@domain-part
  srs0_remote_forwarded_smtp:
  driver             = smtp
  max_rcpt           = 1
  return_path        = SRS0\
                        =${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$acl_c_sender}}}}}\
                        =${eval:$tod_epoch / 86400 & SRS_AGE_MODULUS}\
                        =${lc:$acl_c_srsdom}\
                        =${lc:$acl_c_srslcp}\
                        @$original_domain
  hosts_require_tls  = *
  hosts_require_auth = *

# SRS1=HHH=orig-local-part==HHH=TT=orig-domain-part=orig-local-part@domain-part
  srs1_remote_forwarded_smtp:
  driver             = smtp
  max_rcpt           = 1
  return_path        = SRS1\
                        =${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$return_path}}}}}\
                        =${domain:$return_path}\
                       ==${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$acl_c_sender}}}}}\
                        =${eval:$tod_epoch / 86400 & SRS_AGE_MODULUS}\
                        =${lc:$acl_c_srsdom}\
                        =${lc:$acl_c_srslcp}\
                        @$original_domain
  hosts_require_tls  = *
  hosts_require_auth = *
.endif
  require
  set acl_c_srsdom = $sender_address_domain
  set acl_c_srslcp = $sender_address_local_part
  set acl_c_srslpr =
  set acl_c_sender = $sender_address
  set acl_c_srsrel = 0
      
  warn
         condition = ${if match{$sender_address}{\N^(SRS|srs)(0|1)=\N}{yes}{no}}
  set acl_c_srsrel = 1
  set acl_c_srsdom = ${extract{4}{=}{$sender_address}}
  set acl_c_srslpr = ${extract{5}{=}{$sender_address}}
  set acl_c_srslcp = ${extract{1}{@}{$acl_c_srslpr}}
  set acl_c_sender = $acl_c_srslcp@$acl_c_srsdom
.endif

```

### EXIM ROUTERS
#### Add the following router as high up as possibe in the exim routers section
#### * Edit +our_domains to match your own config for local domains list
```
.ifdef USE_SRS
### SRS
srs_inbound:
  driver =    redirect
  senders =   :
  domains =   +our_domains  # Modify this to match your own config
  condition = ${if <{$acl_m_spam}{1}{yes}{no}}  # This acl is set for spam as I do not forward spam
  condition = ${if match{$sender_address}{\N=(SRS|srs)0=\N}{no}{yes}}
  condition = ${if match{$h_To:}{\N=(SRS|srs)0=\N}{no}{yes}}
  condition = ${if match {$local_part} {^(?i)SRS0=([^=]+)=([0-9]+)=([^=]*)=(.*)\$} \
                   {${if and { \
                                 {<= {${eval:$tod_epoch/86400 - $2 & SRS_AGE_MODULUS}} {SRS_MAX_AGE} } \
                                 {eq {$1} {${length {SRS_HASH_LENGTH} {${hmac {md5} {SRS_SECRET} {${lc:$4@$3}}}}}}} \
                             } \
                         }} \
                   {false}}

  data =    ${sg {$local_part} \
                 {^(?i)SRS0=[^=]+=[^=]+=([^=]*)=(.*)\$} \
                 {\$2@\$1}}

####
srs_inbound_failure:
  driver =    redirect
  senders =   :
  domains =   +our_domains   # Modify to match your config
  condition = ${if match {$local_part} \
                         {^(?i)SRS0=([^=]+)=([^=]+)=([^=]*)=(.*)\$} \
                }
  allow_fail
  data =    :fail: Invalid SRS recipient address
###################
.endif

```
### Add the following as the last router BEFORE your outbound smtp router
#### * Edit normal_outbound_smtp to mtach your DEFAULT outbound smtp transport
#### * Edit +our_domains to match your own config for local domains list
```
outbound_smtp:
  driver     = manualroute
  domains    = ! +our_domains  # Change to match your config
  condition  = ${if ={$acl_c_srsrel}{0}{yes}{no}}
#  condition  = ${if <{$acl_m_spam}{1}{yes}{no}} # Stop marked spam
  condition  = ${if def:h_X-Is-A-Bounce:{no}{yes}}
  transport  = ${if eq {$local_part@$domain} \
                      {$original_local_part@$original_domain} \
                      {normal_outbound_smtp} {srs0_remote_forwarded_smtp}}
  route_list = $domain <%=@local_spamexperts_smarthost%>::587
  no_more

outbound_srsrelay:
  driver     = manualroute
  domains    = ! +our_domains    # Change to match your config
  condition  = ${if ={$acl_c_srsrel}{1}{yes}{no}}
#  condition  = ${if <{$acl_m_spam}{1}{yes}{no}} # Stop marked spam
  condition  = ${if def:h_X-Is-A-Bounce:{no}{yes}}
  transport  = ${if eq {$local_part@$domain} \
                      {$original_local_part@$original_domain} \
                      {normal_outbound_smtp} {srs1_remote_forwarded_smtp}}
  route_list = $domain <%=@local_spamexperts_smarthost%>::587
  no_more
.endif


```

### EXIM TRANSPORTS (order does not matter here)
```
.ifdef USE_SRS
# SRS0=HHH=TT=orig-domain=orig-local-part@domain-part
  srs0_remote_forwarded_smtp:
  driver             = smtp
  max_rcpt           = 1
  return_path        = SRS0\
                        =${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$acl_c_sender}}}}}\
                        =${eval:$tod_epoch / 86400 & SRS_AGE_MODULUS}\
                        =${lc:$acl_c_srsdom}\
                        =${lc:$acl_c_srslcp}\
                        @$original_domain
  hosts_require_tls  = *
  hosts_require_auth = *

# SRS1=HHH=orig-local-part==HHH=TT=orig-domain-part=orig-local-part@domain-part
  srs1_remote_forwarded_smtp:
  driver             = smtp
  max_rcpt           = 1
  return_path        = SRS1\
                        =${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$return_path}}}}}\
                        =${domain:$return_path}\
                       ==${length {SRS_HASH_LENGTH} {${hmac{md5}{SRS_SECRET}{${lc:$acl_c_sender}}}}}\
                        =${eval:$tod_epoch / 86400 & SRS_AGE_MODULUS}\
                        =${lc:$acl_c_srsdom}\
                        =${lc:$acl_c_srslcp}\
                        @$original_domain
  hosts_require_tls  = *
  hosts_require_auth = *
.endif

```
### END