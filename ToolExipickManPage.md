This is the man page for the exipick utility (the same text printed when
running 'exipick --help'). See [ToolExipick](ToolExipick) for more
examples and tutorials.

NAME

> exipick - selectively display messages from an Exim queue

SYNOPSIS

> exipick [\<options\>] [\<criterion\> [\<criterion\> ...]]

DESCRIPTION

> exipick is a tool to display messages in an Exim queue. It is very
> similar to exiqgrep and is, in fact, a drop in replacement for exiq-
> grep. exipick allows you to select messages to be displayed using any
> piece of data stored in an Exim spool file. Matching messages can be
> displayed in a variety of formats.

QUICK START

> Delete every frozen message from queue:
>
> > exipick -zi | xargs exim -Mrm
>
> Show only messages which have not yet been virus scanned:
>
> > exipick '\$received\_protocol ne virus-scanned'
>
> Run the queue in a semi-random order:
>
> > exipick -i --random | xargs exim -M
>
> Show the count and total size of all messages which either originated
> from localhost or have a received protocol of 'local':
>
> > exipick --or --size --bpc '\$sender\_host\_address eq 127.0.0.1'
> > '\$received\_protocol eq local'
>
> Display all messages received on the MSA port, ordered first by the
> sender's email domain and then by the size of the emails:
>
> > exipick --sort sender\_address\_domain,message\_size
> > '\$received\_port == 587'
>
> Display only messages whose every recipient is in the example.com
> domain, also listing the IP address of the sending host:
>
> > exipick --show-vars sender\_host\_address '\$each\_recipients =
> > example.com'

OPTIONS

> --and
>
> > Display messages matching all criteria (default)
>
> -b Display messages in brief format (exiqgrep) -bp Display messages in
> standard mailq format (default) -bpa
>
> > Same as -bp, show generated addresses also (exim)
>
> -bpc
>
> > Show a count of matching messages (exim)
>
> -bpr
>
> > Same as '-bp --unsorted' (exim)
>
> -bpra
>
> > Same as '-bpr --unsorted' (exim)
>
> -bpru
>
> > Same as '-bpu --unsorted' (exim)
>
> -bpu
>
> > Same as -bp, but only show undelivered messages (exim)
>
> -c Show a count of matching messages (exiqgrep) --caseful
>
> > Make operators involving '=' honor case
>
> --charset
>
> > Override the default local character set for \$header\_ decoding
>
> -f \<regexp\>
>
> > Same as '\$sender\_address = \<regexp\>' (exiqgrep)
>
> --flatq
>
> > Use a single-line output format
>
> --freeze \<cache file\>
>
> > Save queue information in an quickly retrievable format
>
> --help
>
> > Display this output
>
> -i Display only the message IDs (exiqgrep) -l Same as -bp (exiqgrep)
> --not
>
> > Negate all tests.
>
> -o \<seconds\>
>
> > Same as '\$message\_age \> \<seconds\>' (exiqgrep)
>
> --or
>
> > Display messages matching any criteria
>
> -R Same as --reverse (exiqgrep) -r \<regexp\>
>
> > Same as '\$recipients = \<regexp\>' (exiqgrep)
>
> --random
>
> > Display messages in random order
>
> --reverse
>
> > Display messages in reverse order
>
> -s \<string\>
>
> > Same as '\$shown\_message\_size eq \<string\>' (exiqgrep)
>
> --spool \<path\>
>
> > Set the path to the exim spool to use
>
> --show-rules
>
> > Show the internal representation of each criterion specified
>
> --show-tests
>
> > Show the result of each criterion on each message
>
> --show-vars \<variable\>[,\<variable\>...]
>
> > Show the value for \<variable\> for each displayed message
>
> --size
>
> > Show the total bytes used by each displayed message
>
> --thaw \<cache file\>
>
> > Read queue information cached from a previous --freeze run
>
> --sort \<variable\>[,\<variable\>...]
>
> > Display matching messages sorted according to \<variable\>
>
> --unsorted
>
> > Do not apply any sorting to output
>
> --version
>
> > Display the version of this command
>
> -x Same as '!\$deliver\_freeze' (exiqgrep) -y Same as '\$message\_age
> \< \<seconds\>' (exiqgrep)
>
> -z Same as '\$deliver\_freeze' (exiqgrep)

CRITERIA

> Exipick decides which messages to display by applying a test against
> each message. The rules take the general form of 'VARIABLE OPERATOR
> VALUE'. For example, '\$message\_age \> 60'. When exipick is deciding
> which messages to display, it checks the \$message\_age variable for
> each message. If a message's age is greater than 60, the message will
> be displayed. If the message's age is 60 or less seconds, it will not
> be displayed.
>
> Multiple criteria can be used. The order they are specified does not
> matter. By default all criteria must evaluate to true for a message to
> be displayed. If the --or option is used, a message is displayed as
> long as any of the criteria evaluate to true. See the VARIABLES and
> OPERATORS sections below for more details

OPERATORS

> BOOLEAN
>
> > Boolean variables are checked simply by being true or false. There
> > is no real operator except negation. Examples of valid boolean
> > tests:
> >
> > > '\$deliver\_freeze'
> > >
> > > '!\$deliver\_freeze'
>
> NUMERIC
>
> > Valid comparisons are \<, \<=, \>, \>=, ==, and !=. Numbers can be
> > integers or floats. Any number in a test suffixed with d, h, m, s,
> > M, K, or B will be mulitplied by 86400, 3600, 60, 1, 1048576, 1024,
> > or 1 respectively. Examples of valid numeric tests:
> >
> > > '\$message\_age \>= 3d'
> > >
> > > '\$local\_interface == 587' '\$message\_size \< 30K'
>
> STRING
>
> > The string operators are =, eq, ne, =\~, and !\~. With the exception
> > of '=', the operators all match the functionality of the like-named
> > perl operators. eq and ne match a string exactly. !\~, =\~, and =
> > apply a perl regular expression to a string. The '=' operator
> > behaves just like =\~ but you are not required to place // around
> > the regular expression. Examples of valid string tests:
> >
> > > '\$received\_protocol eq esmtp'
> > >
> > > '\$sender\_address = example.com' '\$each\_recipients =\~
> > > /\^a[a-z]{2,3}@example.com\$/'
>
> NEGATION
>
> > There are many ways to negate tests, each having a reason for
> > existing. Many tests can be negated using native operators. For
> > instance, \>1 is the opposite of \<=1 and eq and ne are opposites.
> > In addition, each individual test can be negated by adding a ! at
> > the beginning of the test. For instance, '!\$acl\_m1 =\~ /\^DENY\$/'
> > is the same as '\$acl\_m1 !\~ /\^DENY\$/'. Finally, every test can
> > be specified by using the command line argument --not. This is func-
> > tionally equivilant to adding a ! to the beginning of every test.

VARIABLES

> With a few exceptions the available variables match Exim's internal
> expansion variables in both name and exact contents. There are a few
> notable additions and format deviations which are noted below.
> Although a brief explanation is offered below, Exim's spec.txt should
> be consulted for full details. It is important to remember that not
> every variable will be defined for every message. For example,
> \$sender\_host\_port is not defined for messages not received from a
> remote host.
>
> Internally, all variables are represented as strings, meaning any
> oper- ator will work on any variable. This means that
> '\$sender\_host\_name \> 4' is a legal criterion, even if it does not
> produce meaningful results. Variables in the list below are marked
> with a 'type' to help in choosing which types of operators make sense
> to use.
>
> > Identifiers
> >
> > > B - Boolean variables
> > >
> > > S - String variables N - Numeric variables
> > >
> > > -   Standard variable matching Exim's content definition
> > >
> > > \# - Standard variable, contents differ from Exim's definition + -
> > > Non-standard variable
>
> S . \$acl\_c0-\$acl\_c9, \$acl\_m0-\$acl\_m9
>
> > User definable variables.
>
> B + \$allow\_unqualified\_recipient
>
> > TRUE if unqualified recipient addresses are permitted in header
> > lines.
>
> B + \$allow\_unqualified\_sender
>
> > TRUE if unqualified sender addresses are permitted in header lines.
>
> S . \$authenticated\_id
>
> > Optional saved information from authenticators, or the login name of
> > the calling process for locally submitted messages.
>
> S . \$authenticated\_sender
>
> > The value of AUTH= param for smtp messages, or a generated value
> > from the calling processes login and qualify domain for locally
> > submitted messages.
>
> S . \$bheader\_*, \$bh\_*
>
> > Value of the header(s) with the same name with any RFC2047 words
> > decoded if present. See section 11.5 of Exim's spec.txt for full
> > details.
>
> S + \$bmi\_verdicts
>
> > The verdict string provided by a Brightmail content scan
>
> N . \$body\_linecount
>
> > The number of lines in the message's body.
>
> N . \$body\_zerocount
>
> > The number of binary zero bytes in the message's body.
>
> B + \$deliver\_freeze
>
> > TRUE if the message is currently frozen.
>
> N + \$deliver\_frozen\_at
>
> > The epoch time at which message was frozen.
>
> B + \$dont\_deliver
>
> > TRUE if, under normal circumstances, Exim will not try to deliver
> > the message.
>
> S + \$each\_recipients
>
> > This is a psuedo variable which allows you to apply a test against
> > each address in \$recipients individually. Whereas '\$recipients =\~
> > /@aol.com/' will match if any recipient address contains aol.com,
> > '\$each\_recipients =\~ /@aol.com\$/' will only be true if every
> > recip- ient matches that pattern. Note that this obeys --and or --or
> > being set. Using it with --or is very similar to just matching
> > against \$recipients, but with the added benefit of being able to
> > use anchors at the beginning and end of each recipient address.
>
> S + \$each\_recipients\_del
>
> > Like \$each\_recipients, but for \$recipients\_del
>
> S + \$each\_recipients\_undel
>
> > Like \$each\_recipients, but for \$recipients\_undel
>
> B . \$first\_delivery
>
> > TRUE if the message has never been deferred.
>
> S . \$header\_*, \$h\_*
>
> > This will always match the contents of the corresponding
> > \$bheader\_\* variable currently (the same behaviour Exim displays
> > when iconv is not installed).
>
> B . \$host\_lookup\_deferred
>
> > TRUE if there was an attempt to look up the host's name from its IP
> > address, but an error occurred that during the attempt.
>
> B . \$host\_lookup\_failed
>
> > TRUE if there was an attempt to look up the host's name from its IP
> > address, but the attempt returned a negative result.
>
> B + \$local\_error\_message
>
> > TRUE if the message is a locally-generated error message.
>
> S . \$local\_scan\_data
>
> > The text returned by the local\_scan() function when a message is
> > received.
>
> B . \$manually\_thawed
>
> > TRUE when the message has been manually thawed.
>
> N . \$message\_age
>
> > The number of seconds since the message was received.
>
> S \# \$message\_body
>
> > The message's body. Unlike Exim's variable of the same name, this
> > variable contains the entire message body. Newlines and nulls are
> > replaced by spaces.
>
> B + \$message\_body\_missing
>
> > TRUE is a message's spool data file (-D file) is missing or
> > unreadable.
>
> N . \$message\_body\_size
>
> > The size of the body in bytes.
>
> S . \$message\_exim\_id, \$message\_id
>
> > The unique message id that is used by Exim to identify the message.
> > \$message\_id is deprecated as of Exim 4.53.
>
> S . \$message\_headers
>
> > A concatenation of all the header lines except for lines added by
> > routers or transports. RFC2047 decoding is performed
>
> S . \$message\_headers\_raw
>
> > A concatenation of all the header lines except for lines added by
> > routers or transports. No decoding or translation is performed.
>
> N . \$message\_linecount
>
> > The number of lines in the entire message (body and headers).
>
> N . \$message\_size
>
> > The size of the message in bytes.
>
> N . \$originator\_gid
>
> > The group id under which the process that called Exim was running as
> > when the message was received.
>
> S + \$originator\_login
>
> > The login of the process which called Exim.
>
> N . \$originator\_uid
>
> > The user id under which the process that called Exim was running as
> > when the message was received.
>
> N . \$received\_count
>
> > The number of Received: header lines in the message.
>
> S . \$received\_ip\_address, \$interface\_address
>
> > The address of the local IP interface for network-originated
> > messages. \$interface\_address is deprecated as of Exim 4.64
>
> N . \$received\_port, \$interface\_port
>
> > The local port number if network-originated messages.
> > \$interface\_port is deprecated as of Exim 4.64
>
> S . \$received\_protocol
>
> > The name of the protocol by which the message was received.
>
> N . \$received\_time
>
> > The epoch time at which the message was received.
>
> S \# \$recipients
>
> > The list of envelope recipients for a message. Unlike Exim's ver-
> > sion, this variable always contains every recipient of the message.
> > The recipients are seperated by a comma and a space. See also
> > \$each\_recipients.
>
> N . \$recipients\_count
>
> > The number of envelope recipients for the message.
>
> S + \$recipients\_del
>
> > The list of delivered envelope recipients for a message. This non-
> > standard variable is in the same format as \$recipients and contains
> > the list of already-delivered recipients including any generated
> > addresses. See also \$each\_recipients\_del.
>
> N + \$recipients\_del\_count
>
> > The number of envelope recipients for the message which have already
> > been delivered. Note that this is the count of original recipients
> > to which the message has been delivered. It does not include
> > generated addresses so it is possible that this number will be less
> > than the number of addresses in the \$recipients\_del string.
>
> S + \$recipients\_undel
>
> > The list of undelivered envelope recipients for a message. This
> > non-standard variable is in the same format as \$recipients and con-
> > tains the list of undelivered recipients. See also \$each\_recipi-
> > ents\_undel.
>
> N + \$recipients\_undel\_count
>
> > The number of envelope recipients for the message which have not yet
> > been delivered.
>
> S . \$reply\_address
>
> > The contents of the Reply-To: header line if one exists and it is
> > not empty, or otherwise the contents of the From: header line.
>
> S . \$rheader\_*, \$rh\_*
>
> > The value of the message's header(s) with the same name. See section
> > 11.5 of Exim's spec.txt for full description.
>
> S . \$sender\_address
>
> > The sender's address that was received in the message's envelope.
> > For bounce messages, the value of this variable is the empty string.
>
> S . \$sender\_address\_domain
>
> > The domain part of \$sender\_address.
>
> S . \$sender\_address\_local\_part
>
> > The local part of \$sender\_address.
>
> S . \$sender\_helo\_name
>
> > The HELO or EHLO value supplied for smtp or bsmtp messages.
>
> S . \$sender\_host\_address
>
> > The remote host's IP address.
>
> S . \$sender\_host\_authenticated
>
> > The name of the authenticator driver which successfully authenti-
> > cated the client from which the message was received.
>
> S . \$sender\_host\_name
>
> > The remote host's name as obtained by looking up its IP address.
>
> N . \$sender\_host\_port
>
> > The port number that was used on the remote host for network-origi-
> > nated messages.
>
> S . \$sender\_ident
>
> > The identification received in response to an RFC 1413 request for
> > remote messages, the login name of the user that called Exim for
> > locally generated messages.
>
> B + \$sender\_local
>
> > TRUE if the message was locally generated.
>
> B + \$sender\_set\_untrusted
>
> > TRUE if the envelope sender of this message was set by an untrusted
> > local caller.
>
> S + \$shown\_message\_size
>
> > This non-standard variable contains the formatted size string. That
> > is, for a message whose \$message\_size is 66566 bytes,
> > \$shown\_message\_size is 65K.
>
> S . \$smtp\_active\_hostname
>
> > The value of the active host name when the message was received, as
> > specified by the "smtp\_active\_hostname" option.
>
> S . \$spam\_score
>
> > The spam score of the message, for example '3.4' or '30.5'.
> > (Requires exiscan or WITH\_CONTENT\_SCAN)
>
> S . \$spam\_score\_int
>
> > The spam score of the message, multiplied by ten, as an integer
> > value. For instance '34' or '305'. (Requires exiscan or WITH\_CON-
> > TENT\_SCAN)
>
> B . \$tls\_certificate\_verified
>
> > TRUE if a TLS certificate was verified when the message was
> > received.
>
> S . \$tls\_cipher
>
> > The cipher suite that was negotiated for encrypted SMTP connec-
> > tions.
>
> S . \$tls\_peerdn
>
> > The value of the Distinguished Name of the certificate if Exim is
> > configured to request one
>
> N + \$warning\_count
>
> > The number of delay warnings which have been sent for this message.

CONTACT

> EMAIL:
> [[proj-exipick@jetmore.net](mailto:proj-exipick@jetmore.net)](mailto:proj-exipick@jetmore.net)
>
> HOME: jetmore.org/john/code/\#exipick
