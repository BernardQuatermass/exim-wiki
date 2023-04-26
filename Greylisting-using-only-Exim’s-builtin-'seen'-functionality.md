#

This variant of greylisting is done entirely in exim, without external databases or scripts.

It is based on the [example for the 'seen' ACL condition in the exim docs](https://exim.org/exim-html-current/doc/html/spec_html/ch-access_control_lists.html#SECTseen).

It allows for exemptions, in the example below based on a scoring system.

# In the 'connect' ACL

We check if the host is already known to retry sending after a temporary error / deferral. If it does, we set a variable that we check to later to disable greylisting.

```
warn
  # Initialize to value that would cause mail to be greylisted
  set acl_c_greylisting_host_is_retrying = false
  # Check in the 'seen' db whether this host is already known to retry sending
  # The minus is needed so that entries 0 minutes old _and older_ are considered,
  # not entries 0 minutes old _and newer_!
  seen = -0m / key=host_passed_greylisting_retry_test_${sender_host_address} / readonly
  # If it is known to retry, remember that
  set acl_c_greylisting_host_is_retrying = true
  logwrite = Antispam_Greylisting: IP [$sender_host_address] is known to retry, so will bypass greylisting
```


# In the 'RCPT' ACL

We check if we have seen this sender/recipient combination before (but not in the last 5 minutes). If we have, this is very likely a retry after a deferral, so we set variables indicating this to be checked later when we decide whether to actually greylist.

```
warn
  # Do not bother with our own authenticated users
  !authenticated = *
  # Check whether we already know that the host is retrying
  !condition = $acl_c_greylisting_host_is_retrying
  # Initialize to a value that will cause mail to be greylisted
  set acl_m_defer_because_of_greylisting = true
  # Check if the sender/recipient combination has already been seen more than 5 minutes ago
  # Some senders have a / in the local part so we need to quote this as / is the option delimiter for 'seen'
  seen = -5m / key=${listquote{/}{${sender_address}}}_${local_part}@${domain}
  # Remember that we do not want to greylist if the combination has already been seen
  # and that the host is retrying
  set acl_m_defer_because_of_greylisting = false
  set acl_c_greylisting_host_is_retrying = true
  logwrite = Antispam_Greylisting: Mail from $sender_address to $local_part@$domain is being retried and will not be greylisted

warn
  # Do not bother with our own authenticated users
  !authenticated = *
  # Check whether we know that the host is retrying to send this mail
  condition = $acl_c_greylisting_host_is_retrying
  # Remember this host as retrying after deferrals to avoid greylisting it next time for 180 days
  # The minus is needed so that entries 0 minutes old _and older_ are considered,
  # not entries 0 minutes old _and newer_!
  seen = -0m / key=host_passed_greylisting_retry_test_${sender_host_address} / write / refresh=180d
  logwrite = Antispam_Greylisting: Added $sender_host_address to greylisting whitelist DB
```

Potential issue: if the sending host retries in a window smaller than 5 minutes, the entry will be updated but not return true.
If that keeps happening, it will never be allowed.

Potential solution: separate this into a `seen` with the `readonly` for checking and one without `readonly` for updating. (Since I ultimately decided to not do greylisting, I couldn’t be bothered to do this. Feel free to do it and update here!)

# In the 'DATA' ACL

We do a last check whether we really want to greylist, apply exemptions, and then do the actual `defer` based on the value of the variable we set in the course of the process.

```
warn
  # Do not bother with our own authenticated users
  !authenticated = *
  # Exemptions for hosts and sender domains that are on a whitelist
  condition = ${if >={$acl_m_DNSWL_domain_score}{10} }
  condition = ${if >={$acl_m_DNSWL_IP_score}{10} }
  # Remember that we do not want to greylist
  set acl_m_defer_because_of_greylisting = false
  logwrite = Antispam_Greylisting: Mail from ${sender_address} to ${local_part_data}@${domain_data} has DNSWL score for domain of $acl_m_DNSWL_domain_score and for IP of $acl_c_DNSWL_IP_score and will NOT be greylisted.

defer
  # Do not bother with our own authenticated users
  !authenticated = *
  # Check if we really decided to greylist this particular mail
  condition = $acl_m_defer_because_of_greylisting
  logwrite = Antispam_Greylisting: Mail from ${sender_address} to ${local_part_data}@${domain_data} deferred for greylisting
```

