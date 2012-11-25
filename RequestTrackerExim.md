Exim and RT (Request Tracker) 3
===============================

This was motivated by the fact that we need to have RT3.x work
transparently with Exim 4.x, so that there is no need to create aliases
for the queue addresses. The motivation was to have RTIR integrate
seamlessly into my rt-3.4 installation. The problem I faced was the fact
that RTIR created a queue whose name had spaces - "Incident Reports", as
opposed to my other queues whose names consisted of a single word.

We therefore had the router/transport re-worked to also handle queues
with spaces. The key changes are:
-   The "does this queue exist" now ignores disabled lists
-   The queue name to use is now pulled from the mysql database instead
    of the e-mail address, allowing queues to have a name different from
    the e-mail address, and allowing queues to have a name with spaces.

<!-- -->

    # This query is used to pull the queue name from the database

    QUEUENAME_QUERY = SELECT Name FROM Queues \
                      WHERE CorrespondAddress = '${quote_mysql:$local_part}@${quote_mysql:$domain}'\
                      AND Disabled = '0'

    # This domainlist is to specify the domains for which we run RT

    domainlist rt3_domains = rt.mydomain.tld

    # Our RT URL

    RT3_URL = http://rt.mydomain.tld/

    # This is the transport used for RT

    request_tracker3_pipe:
      driver         = pipe
      return_fail_output
      allow_commands = /opt/rt3/bin/rt-mailgate

    # This the new router for RT3

    request_tracker3:
      driver            = redirect
      domains           = +rt3_domains
      local_parts       = mysql;QUEUENAME_QUERY
      local_part_suffix = -comment
      local_part_suffix_optional
      pipe_transport    = request_tracker3_pipe
      data              = "|/opt/rt3/bin/rt-mailgate \
                           --queue \"${lookup mysql{QUEUENAME_QUERY}}\" \
                           --action ${substr_1:${if eq{$local_part_suffix}{}\
                           {-correspond}{$local_part_suffix}} } \
                           --url RT3_URL"
      user              = www

If there are more suffixes supported/needed than -comment, these could
be added to the local\_part\_suffix list, colon separated.

This configuration has been tested by myself on FreeBSD and it works for
all intents and purposes.

For a Debian-ized version of this HOWTO, Debian users can refer to the
following URL:

[http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=229052](http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=229052).
