Sender Policy Framework (SPF) support
=====================================

As of version 4.91, SPF support has been promoted from Experimental to Supported status.

To learn more about SPF, visit
[http://www.openspf.org](http://www.openspf.org). This document does not
explain the SPF fundamentals, you should read and understand the
implications of deploying SPF on your system before doing so.

SPF is specified in [https://tools.ietf.org/html/rfc7208](https://tools.ietf.org/html/rfc7208).

SPF support is added via the libspf2 library. Visit

> [http://www.libspf2.org](http://www.libspf2.org)/

to obtain a copy, then compile and install it. By default, this will put
headers in /usr/local/include and the static library in /usr/local/lib.

To compile Exim with SPF support, set these additional flags in
Local/Makefile:

    SUPPORT_SPF=yes
    CFLAGS=-DSPF -I/usr/local/include
    EXTRALIBS_EXIM +=-L/usr/local/lib -lspf2

This assumes that the libspf2 files are installed in their default
locations.

NOTE: on Fedora/RedHat/Centos 64 bit systems you can compile the SPF
libs running configure as follows:

    configure --prefix=/usr --libdir=/usr/lib64

Then the Local/Makefile would be:

    SUPPORT_SPF=yes
    CFLAGS=-DSPF -I/usr/include/spf2
    EXTRALIBS_EXIM +=-L/usr/lib64 -lspf2

You can now run SPF checks in incoming SMTP by using the "spf" ACL
condition in either the MAIL, RCPT or DATA ACLs. When using it in the
RCPT ACL, you can make the checks dependend on the RCPT address (or
domain), so you can check SPF records only for certain target domains.
This gives you the possibility to opt-out certain customers that do not
want their mail to be subject to SPF checking.

The spf condition takes a list of strings on its right-hand side. These
strings describe the outcome of the SPF check for which the spf
condition should succeed. Valid strings are:

| string     | meaning |
| ---------- | ------- |
| `pass`     | The SPF check passed, the sending host is positively verified by SPF. |
| `fail`     | The SPF check failed, the sending host is NOT allowed to send mail for the domain in the envelope-from address. |
| `softfail` | The SPF check failed, but the queried domain can't absolutely confirm that this is a forgery. |
| `none`     | The queried domain does not publish SPF records. |
| `neutral`  | The SPF check returned a "neutral" state. This means the queried domain has published a SPF record, but does neither allow nor object the sending host from sending mail under its domain. This should be treated like "none". |
| `permerror` | This indicates a syntax error in the SPF record of the queried domain. This should be treated like "none". |
| `temperror` | This indicates a temporary error during all processing, including Exim's SPF processing. You may defer messages when this occurs. |

You can prefix each string with an exclamation mark to invert is
meaning, for example "!fail" will match all results but "fail". The
string list is evaluated left-to-right, in a short-circuit fashion. When
a string matches the outcome of the SPF check, the condition succeeds.
If none of the listed strings matches the outcome of the SPF check, the
condition fails.

Here is a simple example to fail forgery attempts from domains that
publish SPF records:

    deny message = $sender_host_address is not allowed to send mail from $sender_address_domain
         spf = fail

You can also give special treatment to specific domains:

    deny message = AOL sender, but not from AOL-approved relay.
         sender_domains = aol.com
         spf = fail:neutral

Explanation: AOL publishes SPF records, but is liberal and still allows
non-approved relays to send mail from aol.com. This will result in a
"neutral" state, while mail from genuine AOL servers will result in
"pass". The example above takes this into account and treats "neutral"
like "fail", but only for aol.com. Please note that this violates the
SPF specification.

When the spf condition has run, it sets up several expansion variables.

| Variable | Description |
| -------- | ----------- |
| `$spf_header_comment` | This contains a human-readable string describing the outcome of the SPF check. You can add it to a custom header or use it for logging purposes. |
| `$spf_received`       | This contains a complete SPF-Received: header that can be added to the message. Please note that according to the SPF draft, this header must be added at the top of the header list. Please see section 10 on how you can do this. |
| `$spf_result`         | This contains the outcome of the SPF check in string form, one of pass, fail, softfail, none, neutral, err_perm or err_temp. |
| `$spf_smtp_comment`   | This contains a string that can be used in a SMTP response to the calling party. Useful for "fail". |


Making SPF Useful
-----------------

Exim processes SPF based on raw logic. Thus if a domain uses +all, which
means every host will pass, this doesn't provide any useful information.
Here's an ACL that filters out the +all and returns more useful
information.

    spf_test:
    warn    set acl_m_spf_record = ${lookup dnsdb{txt=$sender_address_domain}{$value}}

    # No SPF record
    accept  !condition = ${if def:acl_m_spf_record}

    # SPF +all is meaningless
    accept  condition = ${if match {$acl_m_spf_record}{\\+all}}

    accept  spf = pass
            set acl_m_spf_pass = $acl_m_spf_record

    accept  spf = fail
            set acl_m_spf_fail = $acl_m_spf_record

    accept

Here's an example of how to use the ACL. In this case we are combining
good SPF with a good white list lookup.

    accept  acl = spf_test
            condition = ${if def:acl_m_spf_pass}
            dnslists = hostkarma.junkemailfilter.com=127.0.0.1/$sender_address_domain
