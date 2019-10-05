# A SRS configuration using Perl Mail::SRS

SRS can be configured using Exim's capability to embed the Perl interpreter. This shouldn't cost too much, as loading the Perl interpreter is deferred until it the `${perl }` expansion is used for the first time.

## Preparations

1. Make sure that your Exim version comes with Perl support built in.
    ```
    exim -bP macro _HAVE_PERL
    ```
1. Install the Perl module `Mail::SRS` using your favourite package manager.

## Configuration

1. Define a macro with the domain you'd like to use for "masquerading"
the rewritten senders. And do not forget to add this domain to your
local domains.
    ```
    SRS_DOMAIN = <domain>
    domainlist local_domains = SRS_DOMAIN : …
    ```
1. Load the `Mail::SRS` module into Exim and define 2 simple functions,
`srs`, and `unsrs`:

    ```
    # replace 'geheim' with a password of your choice
    hide perl_startup = use Mail::SRS;                          \
                my $srs = Mail::SRS->new(Secret => 'geheim');   \
                sub srs { $srs->forward(shift, 'SRS_DOMAIN') }  \
                sub unsrs { $srs->reverse(shift) }
    ```
1. We define the two conditions as macros to ease the following configuration:
    - sender domain has SPF
      ```
      SENDER_HAS_SPF = !eq{none}{${lookup{$sender_address}spf{0.0.0.0}}}
      ```
    - sender is not a local domain
      ```
      SENDER_ISNT_LOCAL_DOMAIN = !inlist{$sender_address_domain}{${listnamed:+local_domains}}
      ```
1. In the transport section, configure the return path modification for
all remote transports, based on the conditions defined above.
    ```
    # SMTP transport
    smtp:
      driver = smtp
      return_path = ${if and{{SENDER_ISNT_LOCAL_DOMAIN}{SENDER_HAS_SPF}}\
                {${perl{srs}{$sender_address}}}fail}
    ```
1. Bounces coming back to the "masquerading" domain must be
de-masqueraded. Configure a router and place this router before any
other router handling local domains.
    ```
    unsrs:
      driver = redirect
      senders = :
      domains = SRS_DOMAIN
      caseful_local_part
      local_parts = ^(?i)srs[01]=
      data = ${perl{unsrs}{$local_part@$domain}}
      allow_fail
    ```
1. You may want to watch the sender rewriting. Add a suitable
selector to the log selector bits:
    ```
    log_selector = +return_path_on_delivery
    ```

## Test outgoing

Send a message from a SPF protected domain, watch the log, and do the
same with a domain not protected by SPF:

```
$ exim -v -f 'foo@<spf-protected-domain>' rcpt@example.com
$ exim -v -f 'foo@<non-spf-protected-domain>' rcpt@example.com
```

## Test incoming

Check, if the modified return path from the above test will be rewritten
properly for the _empty_ sender:
```
$ exim -f '<>' -bt 'SRS0…'
```

Contact [hs@schlittermann.de](mailto:hs@schlittermann.de) if you have any suggestions.