Configuration of Exim for Request Tracker
=========================================

The following will allow exim to query the request tracker database for
information whether a queue exists in request tracker. It is thus not
necessary to have dedicated aliases for a queue in the exim
configuration. Exim will pick up the configuration automatically.

This has been developed in the Debian project by Marc Haber with help
from Odhiambo Washington, but is not yet part of the Debian packages.

main configuration
------------------

    QUEUENAME_QUERY   = \
                      SELECT Name FROM Queues WHERE \
                      CorrespondAddress = '${quote_mysql:$local_part}@${quote_mysql:$domain}' \
                      AND Disabled = '0'

    hide mysql_servers = $DBHOST/$DBNAME/$DBUSER/$DBPASSWORD

    domainlist rt3_domains = $DOMAINLIST

transport
---------

    request_tracker3_pipe:
      debug_print = "T: request_tracker3_pipe for $local_part@$domain"
      driver = pipe
      return_fail_output
      allow_commands = /usr/bin/rt-mailgate

router
------

    request_tracker3:
      debug_print = "R: request_tracker3 for \
                        $local_part$local_part_suffix@$domain \
                        (calling ${substr_1:${if eq{$local_part_suffix}{}\
                                           {-correspond}\
                                           {$local_part_suffix} }})"
      driver = redirect
      domains = +rt3_domains
      local_parts = mysql; QUEUENAME_QUERY
      local_part_suffix = -comment
      local_part_suffix_optional
      pipe_transport = request_tracker3_pipe
      data = "|/usr/bin/rt-mailgate \
               --queue \"${lookup mysql{QUEUENAME_QUERY}}\" \
               --action ${substr_1:${if eq{$local_part_suffix}{}\
                                            {-correspond}\
                                            {$local_part_suffix} }} \
               --url RT3_URL"
      user = www-data

comments
--------

I don't particularly like the idea of running the mailgate process as
www-data, but since the bulk of rt runs as www-data anyway, there is
probably not a way to get around this.

If there are more suffixes supported/needed than -comment, these could
be added to the local\_part\_suffix list, colon separated.

This configuration has been tested by Odhiambo Washington on a
non-Debian system. I am currently not in a position do to any tests on
my own.
