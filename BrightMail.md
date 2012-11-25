
Brightmail AntiSpam (BMI) suppport
==================================

Support for Brightmail [AntiSpam](AntiSpam) is
[Experimental](ExperimentalSpec)

Brightmail [AntiSpam](AntiSpam) is a commercial package. Please see
[http://www.brightmail.com](http://www.brightmail.com) for more
information on the product. For the sake of clarity, we'll refer to it
as "BMI" from now on.

BMI concept and implementation overview
---------------------------------------

In contrast to how spam-scanning with [SpamAssassin](SpamAssassin) is
implemented in exiscan-acl, BMI is more suited for per -recipient
scanning of messages. However, each message is scanned only once, but
multiple "verdicts" for multiple recipients can be returned from the BMI
server. The exiscan implementation passes the message to the BMI server
just before accepting it. It then adds the retrieved verdicts to the
messages header file in the spool. These verdicts can then be queried in
routers, where operation is per-recipient instead of per-message. To use
BMI, you need to take the following steps:

These steps are explained in more details below.

### Adding support for BMI at compile time

> To compile with BMI support, you need to link Exim against the
> Brighmail client SDK, consisting of a library
> (libbmiclient\_single.so) and a header file (bmi\_api.h). You'll also
> need to explicitly set a flag in the Makefile to include BMI support
> in the Exim binary. Both can be achieved with these lines in
> Local/Makefile:

    EXPERIMENTAL_BRIGHTMAIL=yes
    CFLAGS=-I/path/to/the/dir/with/the/includefile
    EXTRALIBS_EXIM=-L/path/to/the/dir/with/the/library -lbmiclient_single

> If you use other CFLAGS or EXTRALIBS\_EXIM settings then merge the
> content of these lines with them.
>
> Note for BMI6.x users: You'll also have to add -lxml2\_single to the
> EXTRALIBS\_EXIM line. Users of 5.5x do not need to do this. You should
> also include the location of libbmiclient\_single.so in your dynamic
> linker configuration file (usually /etc/ld.so.conf) and run "ldconfig"
> afterwards, or else the produced Exim binary will not be able to find
> the library file.

### Setting up BMI support in the Exim main configuration

> To enable BMI support in the main Exim configuration, you should set
> the path to the main BMI configuration file with the
> "bmi\_config\_file" option, like this:

    bmi_config_file = /opt/brightmail/etc/brightmail.cfg

> This must go into section 1 of Exim's configuration file (You can put
> it right on top). If you omit this option, it defaults to
> /opt/brightmail/etc/brightmail.cfg.
>
> Note for BMI6.x users: This file is in XML format in V6.xx and its
> name is /opt/brightmail/etc/bmiconfig.xml. So BMI 6.x users MUST set
> the bmi\_config\_file option.

### Set up ACL control statement

> To optimize performance, it makes sense only to process messages
> coming from remote, untrusted sources with the BMI server. To set up a
> messages for processing by the BMI server, you MUST set the "bmi\_run"
> control statement in any ACL for an incoming message. You will
> typically do this in an "accept" block in the "acl\_check\_rcpt" ACL.
> You should use the "accept" block(s) that accept messages from remote
> servers for your own domain(s). Here is an example that uses the
> "accept" blocks from Exim's default configuration file:

    accept  domains       = +local_domains
            endpass
            verify        = recipient
            control       = bmi_run

    accept  domains       = +relay_to_domains
            endpass
            verify        = recipient
            control       = bmi_run

> If bmi\_run is not set in any ACL during reception of the message, it
> will NOT be passed to the BMI server.

### Setting up routers to use BMI verdicts

> When a message has been run through the BMI server, one or more
> "verdicts" are present. Different recipients can have different
> verdicts. Each recipient is treated individually during routing, so
> you can query the verdicts by recipient at that stage. From Exim's
> view, a verdict can have the following outcomes:
-   deliver the message normally
-   deliver the message to an alternate location
-   do not deliver the message

    > To query the verdict for a recipient, the implementation offers
    > the following tools:
    -   Boolean router preconditions. These can be used in any

        > router. For a simple implementation of BMI, these may be all
        > that you need. The following preconditions are available:
        -   `bmi_deliver_default`

            > This precondition is TRUE if the verdict for the recipient
            > is to deliver the message normally. If the message has not
            > been processed by the BMI server, this variable defaults
            > to TRUE.
        -   `bmi_deliver_alternate`

            > This precondition is TRUE if the verdict for the recipient
            > is to deliver the message to an alternate location. You
            > can get the location string from the \$bmi\_alt\_location
            > expansion variable if you need it. See further below. If
            > the message has not been processed by the BMI server, this
            > variable defaults to FALSE.
        -   `bmi_dont_deliver`

            > This precondition is TRUE if the verdict for the recipient
            > is NOT to deliver the message to the recipient. You will
            > typically use this precondition in a top-level blackhole
            > router, like this:

<!-- -->

    # don't deliver messages handled by the BMI server
    bmi_blackhole:
      driver = redirect
      bmi_dont_deliver
      data = :blackhole:

> This router should be on top of all others, so messages that should
> not be delivered do not reach other routers at all. If the message has
> not been processed by the BMI server, this variable defaults to FALSE.
-   A list router precondition to query if rules "fired" on

    > the message for the recipient. Its name is "bmi\_rule". You use it
    > by passing it a colon-separated list of rule numbers. You can use
    > this condition to route messages that matched specific rules. Here
    > is an example:

<!-- -->

    # special router for BMI rule #5, #8 and #11
    bmi_rule_redirect:
      driver = redirect
      bmi_rule = 5:8:11
      data = postmaster@mydomain.com
-   Expansion variables. Several expansion variables are set

    > during routing. You can use them in custom router conditions, for
    > example. The following variables are available:
    -   `$bmi_base64_verdict`

        > This variable will contain the BASE64 encoded verdict for the
        > recipient being routed. You can use it to add a header to
        > messages for tracking purposes, for example:

<!-- -->

    localuser:
      driver = accept
      check_local_user
      headers_add = X-Brightmail-Verdict: $bmi_base64_verdict
      transport = local_delivery

> If there is no verdict available for the recipient being routed, this
> variable contains the empty string.
-   `$bmi_base64_tracker_verdict`

    > This variable will contain a BASE64 encoded subset of the verdict
    > information concerning the "rules" that fired on the message. You
    > can add this string to a header, commonly named
    > "X-Brightmail-Tracker". Example:

<!-- -->

    localuser:
      driver = accept
      check_local_user
      headers_add = X-Brightmail-Tracker: $bmi_base64_tracker_verdict
      transport = local_delivery

> If there is no verdict available for the recipient being routed, this
> variable contains the empty string.
-   `$bmi_alt_location`

    > If the verdict is to redirect the message to an alternate
    > location, this variable will contain the alternate location string
    > returned by the BMI server. In its default configuration, this is
    > a header-like string that can be added to the message with
    > "headers\_add". If there is no verdict available for the recipient
    > being routed, or if the message is to be delivered normally, this
    > variable contains the empty string.
-   `$bmi_deliver`

    > This is an additional integer variable that can be used to query
    > if the message should be delivered at all. You should use router
    > preconditions instead if possible.
    >
    > `$bmi_deliver` is '0': the message should NOT be delivered.
    > `$bmi_deliver` is '1': the message should be delivered.

    IMPORTANT NOTE: Verdict inheritance. The message is passed to the
    BMI server during message reception, using the target addresses from
    the RCPT TO: commands in the SMTP transaction. If recipients get
    expanded or re-written (for example by aliasing), the new
    address(es) inherit the verdict from the original address. This
    means that verdicts also apply to all "child" addresses generated
    from top-level addresses that were sent to the BMI server.

### Using per-recipient opt-in information (Optional)

> The BMI server features multiple scanning "profiles" for individual
> recipients. These are usually stored in a LDAP server and are queried
> by the BMI server itself. However, you can also pass opt-in data for
> each recipient from the MTA to the BMI server. This is particularly
> useful if you already look up recipient data in Exim anyway (which can
> also be stored in a SQL database or other source). This implementation
> enables you to pass opt-in data to the BMI server in the RCPT ACL.
> This works by setting the 'bmi\_optin' modifier in a block of that
> ACL. If should be set to a list of comma-separated strings that
> identify the features which the BMI server should use for that
> particular recipient. Ideally, you would use the 'bmi\_optin' modifier
> in the same ACL block where you set the 'bmi\_run' control flag. Here
> is an example that will pull opt-in data for each recipient from a
> flat file called '/etc/exim/bmi\_optin\_data'.
>
> The file format:

    user1@mydomain.com:   <OPTIN STRING1>:<OPTIN STRING2>
    user2@thatdomain.com: <OPTIN STRING3>

> The example:

    accept  domains   = +relay_to_domains
            endpass
            verify    = recipient
            bmi_optin = ${lookup{$local_part@$domain}\
                        lsearch{/etc/exim/bmi_optin_data}}
            control   = bmi_run

> Of course, you can also use any other lookup method that Exim
> supports, including LDAP, Postgres, MySQL, Oracle etc., as long as the
> result is a list of colon-separated opt-in strings.
>
> For a list of available opt-in strings, please contact your Brightmail
> representative.
