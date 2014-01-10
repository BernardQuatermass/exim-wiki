Author: Silmar A. Marca

If you use the SPF, this technology helps to make a bridge of
communication between e-mails with dual external redirects.

Before, set these in Main Configuration Settings:

    #-SRS0 DATESIZE = 4 for dual gateway expire in year, 6 for dual gateway expire in montly, 8 for day expire
    #- Sintaxe: SRS0=secpassword=forwarddomaindest.com.br=user@hostmx.yourdomain.com.br (SIGN_DOMAIN is $qualify_domain as correct)
    SIGN_PREFIX             = SRS0
    SIGN_PASS               = themasterpassword
    SIGN_SIZE               = 10
    SIGN_DATESIZE           = 8
    SIGN_HASH               = md5
    SIGN_DOMAIN             = $qualify_domain

\#--

    acl_check_rcpt:
      .ifdef SIGN_PASS
        #BLK: Nega se sintaxe errada para dominios tipo forward (ponte de um dominio para outro atraves deste servidor). Geralmente usado em apelidos para
        #evitar bloqueios de SPF
        drop  local_parts   = ^SIGN_PREFIX=*
              domains       = SIGN_DOMAIN : +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if match{$local_part}{(?i)^(.+)=(.+)=(.+)\\.(.+)=(.+)\$}{no}{yes}}
              message       = Invalid sintax of forward signature.
              delay         = 45s
        drop  senders       = !:
              local_parts   = ^SIGN_PREFIX=*
              domains       = SIGN_DOMAIN : +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi\
                                {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=${extract{4}{=}{$local_part}}=$sender_address_domain=$sender_address_local_part}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                                {no}{yes}}
              message       = Invalid or expired forward signature to send mail from <$sender_address> for external address <${extract{4}{=}{${lc:$local_part}}}@${extract{3}{=}{${lc:$local_part}}}>
              delay         = 45s
         accept senders     = !:
              local_parts   = ^SIGN_PREFIX=*
              domains       = SIGN_DOMAIN : +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi {$local_part@$domain} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
              condition     = ${if eqi\
                                {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=${extract{4}{=}{$local_part}}=$sender_address_domain=$sender_address_local_part}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                                {yes}{no}}
              verify        = recipient
              control       = queue_only
              logwrite      = :main: $message_exim_id Sign: accept recipient F=${extract{4}{=}{$local_part}}@${extract{3}{=}{$local_part}} T=$sender_address H=$sender_rcvhost
         accept senders     = !: ^SIGN_PREFIX=*
              sender_domains= SIGN_DOMAIN : +local_domains : +alias_domains : +relay_to_domains
              condition     = ${if eqi {$local_part@$domain} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
              condition     = ${if eqi\
                                {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                    ${lc:${extract{3}{=}{$sender_address_local_part}}=${extract{4}{=}{$sender_address_local_part}}=$domain=$local_part}}}}}\
                                {${extract{2}{=}{$sender_address_local_part}}}\
                                {yes}{no}}
              verify        = recipient
              logwrite      = :main: $message_exim_id Sign: accept sender F=${extract{4}{=}{$sender_address_local_part}}@${extract{3}{=}{$sender_address_local_part}} T=$local_part@$domain H=$sender_rcvhost
      .endif

\#--

    .ifdef SIGN_PASS
      #-Envia diretamente os emails ja assinados via SIGN_PASS. Evita fazer re-assinaturas
      # Quando o RCPT eh validado
      sign_remote_recipient_send:
        driver            = dnslookup
        senders           = !: ^SIGN_PREFIX=*
        domains           = !+local_domains : !+alias_domains : !+relay_to_domains
        mx_domains        = ${domain}
        #condition        = ${if eqi {$local_part@$domain} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
        condition         = ${if eqi\
                                {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=${extract{4}{=}{$local_part}}=$sender_address_domain=$sender_address_local_part}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                             {true}fail}
        self              = fail
        transport         = nosign_delivery
        ignore_target_hosts   = +ignore_target_hosts
        cannot_route_message  = Unrouteable address: <${domain}>
        debug_print       = "R: sign_remote_recipient_send from <${extract{4}{=}{${lc:$local_part}}}@${extract{3}{=}{${lc:$local_part}}}> for <${local_part}@${domain}>"
        headers_remove      = BYPASS_NHEADER
        no_more

      sign_remote_sender_send:
        driver            = dnslookup
        senders           = !: ^SIGN_PREFIX=*
        domains           = !+local_domains : !+alias_domains : !+relay_to_domains
        mx_domains        = ${domain}
        #condition        = ${if eqi {$local_part@$domain} {$sender_address_local_part@$sender_address_domain} {no}{yes}}
        condition         = ${if and {\
                                 { match_domain{$sender_address_domain}{+local_domains : +relay_to_domains : +alias_domains} }\
                                 { eqi\
                                    {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                        ${lc:${extract{3}{=}{$sender_address_local_part}}=${extract{4}{=}{$sender_address_local_part}}=$domain=$local_part}}}}}\
                                    {${extract{2}{=}{$sender_address_local_part}}}}\
                             }{true}fail}
        self              = fail
        transport         = nosign_delivery
        ignore_target_hosts   = +ignore_target_hosts
        cannot_route_message  = Unrouteable address: <${domain}>
        debug_print       = "R: sign_remote_sender_send from <${extract{4}{=}{${lc:$sender_address_local_part}}}@${extract{3}{=}{${lc:$sender_address_local_part}}}> for <${local_part}@${domain}>"
        headers_remove      = BYPASS_NHEADER
        no_more

      #-Verificacao de endereco e redirecionamento ao endereco correto. Possibilita callout de outros servidores na origem fiel e tambem o envio de emails
      sign_redirect:
        senders           = !:
        driver            = redirect
        local_parts       = ^SIGN_PREFIX=*
        domains           = SIGN_DOMAIN
        condition         = ${if eqi\
                                {${hash_SIGN_SIZE:${hmac{SIGN_HASH}{${length_SIGN_DATESIZE:$tod_zulu}SIGN_PASS}{\
                                    ${lc:${extract{3}{=}{$local_part}}=${extract{4}{=}{$local_part}}=$sender_address_domain=$sender_address_local_part}}}}}\
                                {${extract{2}{=}{$local_part}}}\
                             {true}fail}
        data              = ${extract{4}{=}{${lc:$local_part}}}@${extract{3}{=}{${lc:$local_part}}}
        debug_print       = "R: sign_redirect from <$sender_address_local_part@$sender_address_domain> for <${extract{4}{=}{${lc:$local_part}}}@${extract{3}{=}{${lc:$local_part}}}>"
        headers_remove    = to:errors-to
        headers_add       = "To: ${extract{4}{=}{${lc:$local_part}}}@${extract{3}{=}{${lc:$local_part}}}\nErrors-To: ${address:$reply_address}"
        no_expn
        no_more
    .endif
