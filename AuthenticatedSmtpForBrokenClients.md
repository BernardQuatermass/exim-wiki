
Some older Microsoft MUAs, such as Outlook Express 4, do not support the
RFC standard syntax for publishing SMTP AUTH support in the EHLO
response. Instead of "AUTH *sasl-method* *sasl-method* ...", OE4 looks
for "AUTH=*sasl-method* *sasl-method* ...". If it doesn't see it, it
won't attempt to authenticate.

Including an AUTH= line in the EHLO response would make exim
non-RFC-compliant, so there is no option to make it do so. The best
solution is to require your users to upgrade their MUA. There are
**many** good reasons not to be running such an old, insecure, buggy
client. However, if that is not possible for some reason, it is possible
to "trick" exim into returning the necessary AUTH= line.

Just add the following to the **end** of your list of authenticators:

    bogus:
      driver        = plaintext
      public_name   = "\r\n250-AUTH=PLAIN LOGIN"
      server_prompts = :
      server_condition = no

This assumes you have implemented both PLAIN and LOGIN authenticators -
if you haven't, include only the one you implemented in the
`public_name` string. Also, if your existing plaintext authenticators
are published conditionally, make sure you apply the same conditions to
the `bogus` authenticator. For example, if you don't advertise plaintext
authenticators on non-encrypted connections (a good idea, that), you'll
have a line like this in your PLAIN and/or LOGIN authenticators, and
should add it to the `bogus` authenticator as well:

> `server_advertise_condition = ${if def:tls_cipher}`

Finally, it is very important that this be the **last** authenticator in
the `begin authenticators` section. Otherwise, any authenticators that
follow it would only be published on the AUTH= line.

* * * * *

> [CategoryHowTo](CategoryHowTo)
