This describes how to run Exim under the control of SMF in Solaris 10.
It is not necessarily the best that can be done, but does work to some
extent.

First create the XML file (as 'exim-smf.xml') to be imported into SMF :-

    <?xml version="1.0"?>
    <!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
    <service_bundle type='manifest' name='Local:exim'>
    <service
        name='site/exim'
        type='service'
        version='1'>
        <create_default_instance enabled='false' />
        <single_instance/>
        <dependency
            name='fs-local'
            grouping='require_all'
            restart_on='none'
            type='service'>
            <service_fmri value='svc:/system/filesystem/local' />
        </dependency>
        <dependency
            name='network-service'
            grouping='require_all'
            restart_on='none'
            type='service'>
            <service_fmri value='svc:/network/service' />
        </dependency>
        <dependent
            name='exim_multi-user-server'
            grouping='require_all'
            restart_on='none'>
            <service_fmri value='svc:/milestone/multi-user-server' />
        </dependent>
        <exec_method
            type='method'
            name='start'
            exec='/opt/exim/bin/smf-script start'
            timeout_seconds='60'>
            <method_context>
               <method_credential user='root' group='root' />
            </method_context>
        </exec_method>
        <exec_method
            type='method'
            name='refresh'
            exec='/opt/exim/bin/smf-script refresh'
            timeout_seconds='60' />
        <exec_method
            type='method'
            name='stop'
            exec='/opt/exim/bin/smf-script stop'
            timeout_seconds='60' />
        <template>
            <common_name>
                <loctext xml:lang='C'>
                Exim mail transport agent
                </loctext>
            </common_name>
        </template>
    </service>
    </service_bundle>

Note that this XML refers to a shell script with the absolute path of
'/opt/exim/bin/smf-script' and you may prefer a different location or
name. In either case the script is as follows :-

    #
    EXIM_DIR="/opt/exim"
    #       Where is Exim installed ?
    EXIM_CONF="$EXIM_DIR/configure"
    #       Where is the configuration file ?
    EXIM_PID="/var/spool/exim/exim-daemon.pid"
    #       Exim PID file
    case "$1" in
    'refresh')
            [ -f $EXIM_PID ] && kill -HUP `head -1 $EXIM_PID`
            ;;
    'start')
            $EXIM_DIR/bin/exim -bd -q10m
            ;;
    'stop')
            [ -f $EXIM_PID ] && kill `head -1 $EXIM_PID`
            ;;
    *)
            echo "Usage: $0 { start | stop | refresh }"
            exit 1
            ;;
    esac
    exit 0

Once this is done, you can import the XML file with
`svccfg import exim-smf.xml` If this imports successfully, you can use
the standard SMF commands to start (`svcadm enable exim`), stop
(`svcadm disable exim`), and reconfigure (`svcadm refresh exim`) to
control Exim.
