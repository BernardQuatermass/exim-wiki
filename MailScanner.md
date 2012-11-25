[MailScanner](..%20_MailScanner%20Home%20Page:%20http://www.MailScanner.info)
is a very powerful daemon that can do several checks for viruses and
spam on emails. While it uses an external Scanner for the virus checks
(e.g. [Sophos](http://www.sophos.com), [FPProt](http://www.f-prot.com)
or [ClamAV](http://www.clamav.net)),
[SpamAssassin](http://spamassassin.apache.org) is used for doing the
Spam checks. All this can be done with exim, too - and already at SMTP
time, which offers the possibility to use the results (Spam or Non-Spam,
Virus found or not) to decide if the mail is to be rejected or accepted.

But MailScanner can do a little more: It can also "disarm" harmful
content of HTML mails. It can even convert HTML mails to
[PlainText](PlainText) mails - depending on the configuration. Thus,
MailScanner offers a bit more flexibility, but there are also some
disadvantages in comparison with exim: -
[SpamAssassin](SpamAssassin)\_ cannot be run in daemon mode (as
"spamd") - At the time a mail is being processed, the MTA has already
accepted it - whether it's spam/virus or not. But (from the author's
point of view) you get most flexibility when combining exim's and
MailScanner's features: Let exim, spamd and your virus scanner decide if
the mail is accepted and then pass it through MailScanner to disarm
potentially harmful HTML Code.

The setup is a bit tricky: You need two exim daemons. One of them (the
"listener") does accept (or reject |;-)| mails arriving via SMTP.
Whenever it accepts an email, it is put in MailScanner's "Incoming
Queue". MailScanner then runs its checks on this email and finally
invokes the second exim daemon which is only responsible for deliveries.

The setup procedure is described in the MailScanner docs. MailScanner
has been written in Perl and comes with an installer that builds and
installs all necessary Perl modules.

See also: \`MailScanner Home Page\`\_

Christian Schmidt \<christian(at)siebenbergen.de\>
