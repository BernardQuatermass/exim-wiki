The aim is to have a table containing a list of regexes that are matched
against MIME filenames. If a filename matches, the message is rejected
with an error from the table.

To do this, put the following in your `acl_smtp_mime`:

    deny
      message = Bad attachment filename ($mime_filename): $acl_m0
      set acl_m0 = ${lookup {$mime_filename} \
                     nwildlsearch {/etc/exim/mime_regexes} }
      condition = ${if def:acl_m0 }

The file `mime_regexes` contains entries like

    ^.*\.exe$     executable files are dangerous in email
    ^.*\.scr$     screensavers are dangerous in email
    ^.*\s{10}     possible file type hiding attack
    ^.{50}        excessively long

Or you can just put such all-in-one

    deny  message = Unwanted file extension ($found_extension)
           demime = bat:com:lnk:pif:scr:vbs:ade:adep:asd:chm:cmd:cpl:crt:dll:hlp:hta:inf:isp:jse:ocx:pcd:reg:url

* * * * *

The configuration files abouve without exim.checkpkt.sh has in [ConfigurationFile](ConfigurationFile) session To filter in zip files:

    #free_arqexec contain emails of permited sender. Example: *@gmail.com
    drop !senders     = wildlsearch;/etc/exim4/lst/fre_arqexec
       demime         = zip:rar:arj:tar:tgz:gz:bz2
       set acl_m9     = ${run{/etc/exim4/exim.checkpkt.sh ${lc:$found_extension} $message_exim_id}}
       message        = This message contains an unwanted binary Attachment in .${uc:$found_extension} file.
       condition      = ${if eq {$runrc}{0}{false}{true}}

The content of exim.checkpkt.sh file is:

    ##########################################################################
    # Please verify if your sistem have a unzip, zipinfo, rar, arj, unarj, tar...
    ###########################################################################
    #Definicoes
    EXTENS='(ad[ep]|asd|ba[st]|chm|cmd|com|cpl|crt|dll|exe|hlp|hta|in[fs]|isp|jse?|jar|lib|lnk|md[bez]|ms[cipt]|ole|ocx|pcd|pif|reg|sc[rt]|sh[sb]|sys|url|vb[es]?|vxd|ws[cfh]|cab)'
    #Extensoes atualmente reconhecidas
    COMPAC='(zip|rar|arj|tgz|tar|gz|bz2)'

    #Previne arquivos compactados dentro de compactados
    EXTENS='[.]('${EXTENS}'|'${COMPAC}')'

    #Testa se esta entre as extensoec conhecidas
    if [ "`echo .$1 | egrep -i "[.]${COMPAC}$"`" = "" ]; then
        echo -n 'File Extension <.'$1'> is unknow compact type!\n'
        exit 0
    fi

    #Mudar diretorios
    if [ ! -z "$2" ]; then
        if [ -d /var/spool/exim4/scan/$2 ]; then
            cd /var/spool/exim4/scan/$2
        else
            echo -n 'Diretorio desconhecido em /var/spool/exim4/scan/'$2'\n'
            exit 1
        fi
    fi

    #Todos arquivos do arquivo compactado
    for i in `ls | egrep -i ".${COMPAC}$"`; do
       EXTFILE="`basename $i | sed -e 's/.*\.//' | tr [A-Z] [a-z]`"
       case "${EXTFILE}" in
         zip)
            CMD_TST="unzip -t $i"
            CMD_VRF="zipinfo -1 $i"
            ;;
         rar)
            CMD_TST="rar t $i"
            CMD_VRF="rar vt $i"
            ;;
         arj)
            CMD_TST="unarj t $i"
            CMD_VRF="arj l $i"
            ;;
         tar)
            CMD_VRF="tar --list -f $i"
            ;;
         tgz|gz)
            CMD_VRF="tar --list -zf $i"
            ;;
         bz2)
            CMD_VRF="tar --list -jf $i"
            ;;
         *)
            echo -n '* Extension of File <'$i'> is unknow archive compact!\n'
       esac

       #Testar pra ver se o arquivo esta OK
       if [ ! -z "${CMD_VRF}" ]; then
            ${CMD_TST} 2> /dev/null > /dev/null
            if [ ! $? -eq 0 -o ]; then
                echo -n '* The file <'$i'> is not '${EXTFILE}' archive!\n'
                FOUND=1
            fi
       fi

       #Ver se existe executaveis no conteudo do mesmo
        ARQS="`${CMD_VRF} 2> /dev/null | gawk '{ print $1 }' | egrep -i "${EXTENS}$"`"
        if [ ! -z "$ARQS" ]; then
            echo -n '* File(s) in <'$i'>: '$ARQS'\n'
            FOUND=1
        fi
    done

    if [ ! -z "${FOUND}" ]; then
        exit 1
    else
        exit 0
    fi
