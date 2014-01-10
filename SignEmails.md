Author: Silmar A. Marca

To block spam from bounce emails, and not block callout to your domain,
try to use: - Sign all outgoin mail - Permit Callout Check - Permit
Password, timeout of signed mails etc.

Before, set these in Main Configuration Settings:

\#-prvs - DATESIZE = 4 for year expire, 6 for montly expire, 8 for daily
expire \#- Sintax of outgoin or inbound:
prvs=password=[[user@yourrdomain.com.br](mailto:user@yourrdomain.com.br)](mailto:user@yourrdomain.com.br)

    BATV_PREFIX             = prvs
    BATV_PASS               = thepasswordmaster
    BATV_SIZE               = 10
    BATV_DATESIZE           = 8
    BATV_HASH               = md5

    #BATV_HSTPASS is optional
    BATV_HSTPASS            = +ignore_defer : +ignore_unknown : ${lookup dnsdb{>: defer_never,mxh=optionalexternalwebhostingwithoutsignbounce.com.br}}

    .ifdef BATV_PASS
        hostlist_cache batv_pass_host = BATV_HSTPASS
    .endif

\#.....

    acl_check_mail:
      .ifdef BATV_PASS
        #BLK: Valida sintaxe da assinatura
        drop  senders       = !: ^BATV_PREFIX=
              sender_domains= !: +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if match{$sender_address_local_part}{(?i)^BATV_PREFIX=(.+)=(.+)\$}{no}{yes}}
              message       = Invalid sintax of reverse path signature from sender <$sender_address>
              delay         = 45s
        #-BLK: Valida assinatura
        drop  senders       = !: ^BATV_PREFIX=
              !hosts        = +batv_pass_host
              sender_domains = !: +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$sender_address_local_part}}=$sender_address_domain}}}}}\
                                {${extract{2}{=}{$sender_address_local_part}}}\
                                {no}{yes}}
              message       = Invalid or expired reverse path signature for sender F=${lc:${extract{3}{=}{$sender_address_local_part}}@$sender_address_domain}
              delay         = 45s
        #-ACT: Aceita de dominios ja verificados em outro servidor com a senha, ou seja, de saida. Mas apenas para os relay_mx_hosts
        accept senders      = !: ^BATV_PREFIX=
              hosts         = +relay_mx_hosts
              sender_domains = !: +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$sender_address_local_part}}=$sender_address_domain}}}}}\
                                {${extract{2}{=}{$sender_address_local_part}}}\
                                {yes}{no}}
              verify        = sender/no_details
              logwrite      = :main: $message_exim_id Batv: accept sender ${lc:${extract{3}{=}{$sender_address_local_part}}@$sender_address_domain} H=$sender_rcvhost
      .endif

\#....

    acl_check_rcpt:
      .ifdef BATV_PASS
      #-ACT: Valida Sintaxe da assinatura
        drop  local_parts   = ^BATV_PREFIX=*
              domains       = +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if match{$local_part}{(?i)^BATV_PREFIX=(.+)=(.+)\$}{no}{yes}}
              message       = Invalid sintax of reverse path signature from <$sender_address> to <$local_part@domain>
              delay         = 45s

      #-ACT: Valida assinatura, exceto das hosts liberadas para enviar erros. Provavelmente por serem servidores WEB externos, alugados...
        drop  !hosts       = +batv_pass_host
              local_parts   = ^BATV_PREFIX=*
              domains       = +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=$domain}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                                {no}{yes}}
              message       = Invalid or expired reverse path signature from <$sender_address> to ${lc:${extract{3}{=}{$local_part}}@$domain}
              delay         = 45s
      #-ACT: Aceita de dominios ja verificados em servidor com a senha, ou seja, de retorno de mensagem de email. Mas nao aceita se for o mesmo email de from e rcpt...
        accept local_parts  = ^BATV_PREFIX=*
              domains       = +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi {$local_part@$domain} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=$domain}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                                {yes}{no}}
              verify        = recipient
              logwrite      = :main: $message_exim_id Batv: accept from <$sender_address> to ${lc:${extract{3}{=}{$local_part}}@$domain} H=$sender_rcvhost
      .endif

\#.... This not disable callout check

    # Permit External Callout using mailto <>
    acl_check_predata:
      .ifdef BATV_PASS
        #-BLK: Re-Verifica sintaxe. Antes, ele permitia callout, agora obriga assinatura para todos os bounces!
        # Aceita se for do mx secundario cadastrado...
        drop  senders       = : +bounce_senders
             !hosts         = +relay_mx_hosts
              condition     = ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX(.+)=(.+)\$}{no}{yes}}
              condition     = ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
              message       = Signature nonexistent for bounce message from <$sender_address> to <${address:$recipients}>
              delay         = 45s
        #-BLK: Re-Verifica assinatura. Antes, ele permitia callout, agora obriga assinatura para todos os bounces!
        # As vezes um bounce tem um sender tipo mailer-daemon@dominio, as vezes nao
        drop  !hosts        = +batv_pass_host
              condition     = ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX(.+)=(.+)\$}{yes}{no}}
              condition     = ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{${local_part:$recipients}}}=${domain:$recipients}}}}}}\
                                {${extract{2}{=}{${local_part:$recipients}}}}\
                                {no}{yes}}
              message       = Invalid or expired reverse path signature for bounce message from <$sender_address> to ${lc:${extract{3}{=}{${local_part:$recipients}}}@${domain:$recipients}}
              delay         = 45s
       #-ACT: Aceita de dominios ja verificados em servidor com a senha, ou seja, de retorno de mensagem de email.
       # Aqui independe se for bounce ou nao... As vezes um bounce pode ter um sender e as vezes nao
        accept condition    = ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX=(.+)=(.+)\$}{yes}{no}}
              condition     = ${if eqi {$recipients} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
              condition     = ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{${local_part:$recipients}}}=${domain:$recipients}}}}}}\
                                {${extract{2}{=}{${local_part:$recipients}}}}\
                                {yes}{no}}
              logwrite      = :main: $message_exim_id Batv: accept from <$sender_address> to ${lc:${extract{3}{=}{${local_part:$recipients}}}@${domain:$recipients}} H=$sender_rcvhost
      .endif

\#...

    acl_check_data:  
      #-ACT: Aceita de dominios ja verificados em servidor com a senha, ou seja, de retorno de mensagem de email. Evita GreyList.
      #A sintaxe e o resto ja foi verificado em predata...
        accept condition    = ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX=(.+)=(.+)\$}{yes}{no}}
              condition     = ${if eqi {$recipients} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
              condition     = ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
              condition     = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{${local_part:$recipients}}}=${domain:$recipients}}}}}}\
                                {${extract{2}{=}{${local_part:$recipients}}}}\
                                {yes}{no}}
              logwrite      = :main: $message_exim_id Batv: accept from <$sender_address> to F=${lc:${extract{3}{=}{${local_part:$recipients}}}@${domain:$recipients}} H=$sender_rcvhost
         .ifdef BLK_MachineNotBounce
                drop !hosts = +relay_mx_hosts
                   condition = ${if !def:h_from: {no}{yes}}
                   condition= ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX(.+)=(.+)\$}{no}{yes}}
                   condition= ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/bounce_senders}{yes}{no}}
                   condition= ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
                   logwrite = :reject: H=$sender_rcvhost Signature nonexistent for bounce message from <$sender_address>, header <${address:$h_from:}> to <${address:$recipients}>
                   message  = Signature nonexistent for bounce message from <$sender_address>, header <${address:$h_from:}> to <${address:$recipients}>
                   delay    = 45s
                drop !hosts = +relay_mx_hosts
                   condition= ${if !def:h_from: {no}{yes}}
                   condition= ${if match{${local_part:$recipients}}{(?i)^BATV_PREFIX(.+)=(.+)\$}{yes}{no}}
                   condition= ${lookup{${address:$h_from:}}wildlsearch{/etc/exim4/lst/bounce_senders}{yes}{no}}
                   condition= ${if or { \
                                { match_domain{${domain:$recipients}}{+local_domains} } \
                                { match_domain{${domain:$recipients}}{+alias_domains} } \
                                { match_domain{${domain:$recipients}}{+relay_to_domains} } \
                              } {yes}{no}}
                   condition= ${if eqi\
                                  {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                      ${lc:${extract{3}{=}{${local_part:$recipients}}}=${domain:$recipients}}}}}}\
                                   {${extract{2}{=}{${local_part:$recipients}}}}\
                                {no}{yes}}
                 logwrite = :reject: H=$sender_rcvhost Signature invalid or expired for bounce message from <$sender_address>, header <${address:$h_from:}> to <${lc:${extract{3}{=}{${local_part:$recipients}}}@${domain:$recipients}}>
                 message    = Invalid or expired reverse path signature  from <$sender_address>, header <${address:$h_from:}> to <${address:$recipients}>
                 delay      = 45s
         .endif
      .endif

\#...

    begin routers
    .ifdef BATV_PASS
      #-Envia diretamente os emails ja assinados via BATV. Evita fazer re-assinaturas
      batv_remote_send:
        driver            = dnslookup
        senders           = ^BATV_PREFIX=*
        domains           = !+local_domains : !+alias_domains : !+relay_to_domains
        mx_domains        = ${domain}
        condition         = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$sender_address_local_part}}=$sender_address_domain}}}}}\
                                {${extract{2}{=}{$sender_address_local_part}}}\
                             {true}fail}
        self              = fail
        transport         = nosign_delivery
        ignore_target_hosts   = +ignore_target_hosts
        cannot_route_message  = Unrouteable address: <${domain}>
        debug_print       = "R: batv_remote_send from <${extract{3}{=}{${lc:$sender_address_local_part}}}@$sender_address_domain> for <${local_part}@${domain}>"
        headers_remove      = BYPASS_NHEADER
        no_more

      #-Verificacao de endereco de envio para bounces. Possibilita assim callout de outros servidores e tambem o envio de emails
      batv_redirect:
        driver            = redirect
        local_parts       = ^BATV_PREFIX=*
        domains           = +local_domains : +alias_domains : +relay_to_domains
        condition         = ${if eqi\
                                {${hash_BATV_SIZE:${hmac{BATV_HASH}{${length_BATV_DATESIZE:$tod_zulu}BATV_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=$domain}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                             {true}fail}
        data              = ${extract{3}{=}{${lc:$local_part}}}@$domain
        debug_print       = "R: batv_redirect from <$sender_address_local_part@$sender_address_domain> for <${extract{3}{=}{${lc:$local_part}}}@$domain>"
        no_expn
    .endif

    remote_send:
      driver                = dnslookup
      domains               = ! +local_domains : !+alias_domains : !+relay_to_domains
      mx_domains            = ${domain}
      self                  = fail
      transport             = ${if or { \
                                { match_domain{${domain:$return_path}}{+local_domains : +relay_to_domains : +alias_domains} } \
                                { match_domain{$sender_address_domain}{+local_domains : +relay_to_domains : +alias_domains} } \
                            }{batv_delivery}{sign_delivery}}
      ignore_target_hosts   = +ignore_target_hosts
      cannot_route_message  = Unrouteable address: <${domain}>
      no_more

    virtual_users:
      driver                = accept
      local_parts           = !^SRS0=* : !^prvs=* : !^SIGN_PREFIX=* : !^BATV_PREFIX=*
      <others clauses, transport...>
