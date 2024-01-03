The following can be used to reject messages if they are received after a date given in the postfix of an address local_part. In this example config a postfix starting with ++ and followed with the date in YYYYMMDD format is used to define the validity date. With joe++20241231@example.com only messages received by end of 2024 are accepted.

# Router Config

```
local_user:
  debug_print = "R: local_user for $local_part@$domain"
  driver = accept
  domains = +local_domains
  check_local_user
  local_parts = ! root
  # add this
  local_part_suffix = +*
  local_part_suffix_optional
  #
  transport = LOCAL_DELIVERY
  cannot_route_message = Unknown user
```

Add the local_part_suffix and local_part_suffix_optional definitions to your local_user router.

# ACL Config

```
  deny
    local_parts = ^.*\\+\\+.*\$
    condition  = ${if <{ ${sg{$local_part_suffix_v}{^\\+}{0}} }{$tod_logfile} {true}{false}}
```

The sg function is used to replace the wildcard matched in the local_part_suffix with a 0 character. The resulting numeric string is numerically compared to $tod_logfile. If the date provided in the address is smaller than today's date, the message is rejected.