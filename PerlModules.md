A list of Perl modules for use with Exim's [embedded Perl interpreter](https://www.exim.org/exim-html-current/doc/html/spec_html/ch-embedded_perl.html).

* [Mail::Exim::ACL::Attachments](#maileximblacklistattachments)
* [Mail::Exim::ACL::Geolocation](#maileximblacklistgeolocation)

# Mail::Exim::ACL::Attachments

The Perl module [Mail::Exim::ACL::Attachments](https://metacpan.org/dist/Mail-Exim-ACL-Attachments) checks email attachments and Zip archives for blocked filenames. The module identifies filenames that are [blocked by Outlook](https://support.microsoft.com/en-us/office/blocked-attachments-in-outlook-434752e1-02d3-4e90-9124-8b81e49a8519), that belong to macro-enabled [Office documents](https://en.wikipedia.org/wiki/List_of_Microsoft_Office_filename_extensions) or that are associated with [7-Zip](https://en.wikipedia.org/wiki/7-Zip).

```
acl_check_mime:

  warn
    condition = ${if and{{def:mime_filename} \
      {!match{${lc:$mime_filename}}{\N\.((json|xml)\.gz|zip)$\N}} \
      {eq{${perl{check_filename}{$mime_filename}}}{blocked}}}}
    set acl_m_blocked = yes

  warn
    condition = ${if match{${lc:$mime_filename}}{\N\. *(jar|zip)$\N}}
    decode = default
    condition = ${if eq{${perl{check_zip}{$mime_decoded_filename}}} \
                       {blocked}}
    set acl_m_blocked = yes
```

# Mail::Exim::ACL::Geolocation

The Perl module [Mail::Exim::ACL::Geolocation](https://metacpan.org/dist/Mail-Exim-ACL-Geolocation) maps IP addresses to [two-letter country codes](https://en.wikipedia.org/wiki/ISO_3166-2) such as "DE", "FR" and "US". SpamAssassin can use these country codes to filter junk email.

```
acl_check_rcpt:

  warn
    domains = +local_domains : +relay_to_domains
    set acl_m_country_code = ${perl{country_code}{$sender_host_address}}
    add_header = X-Sender-Host-Country: $acl_m_country_code
```

```
bayes_ignore_header X-Sender-Host-Country
header UNCOMMON_COUNTRY X-Sender-Host-Country !~ /^(?:DE|FR|US)/ [if-unset: US]
describe UNCOMMON_COUNTRY Message is sent from uncommon country
tflags UNCOMMON_COUNTRY noautolearn
score UNCOMMON_COUNTRY 0.1
```