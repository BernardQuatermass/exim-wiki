How can I send notifications to the sender/recipient/administrator when a virus is detected?
============================================================================================

(by [TimJackson](TimJackson))

Summary
-------

Mostly this is pointless, and in some cases harmful.

Notifications to sender
-----------------------

**DO NOT DO THIS!** Notifications to senders are extremely harmful. They
are rapidly becoming as much, if not more, of a problem than the viruses
themselves. Consider that almost all e-mail-borne viruses fake the
envelope sender - if you send alerts, they will either go to some random
person who had nothing to do with sending the e-mail (which means
basically that you are sending spam) or they will be undeliverable, in
which case they will freeze on your queue.

Remember that if you reject at SMTP time (e.g. using Exiscan) then, in
the case of "legitimate" mail which is virus infected (e.g. a macro
virus in a word processor document; these are rare), the sender *will*
be notified by the generation of an SMTP error upstream from you. So put
any information that you want to pass to the sender in your SMTP
rejection.

There are lots of efforts to block "bogus virus warnings" caused by
ill-advised "notifications to sender", including
[TimJackson](TimJackson)'s [bogus-virus-warnings.cf for
SpamAssassin](http://www.timj.co.uk/linux/sa.php).

Notifications to recipients
---------------------------

Frankly, why do you want to do this? There is not going to be anything
useful that the recipient can do. If you send them a notification (e.g.
with the "sender" and subject line), what are they going to do?
-   They might ignore the e-mail, in which case what was the point in
    sending it and cluttering up their inbox?
-   Odds on, they will e-mail the (probably faked) "sender" saying
    something like "why did you send me a virus?" or "please disinfect
    and resend your mail". This has much of the same annoyance effect as
    "Notifications to sender" as discussed above, creates confusion and
    wastes time.

If you need to show your recipients that you are "doing something", do a
weekly report based on your logs showing how many viruses you rejected,
or something.

Notifications to administrators
-------------------------------

Well, you can do this if you really want. But, honestly, do you have
nothing better to do than read e-mails every time your organisation
receives a virus? Read your logs! If you do really want to send
notifications to administrators, see
[ExiscanExamples](ExiscanExamples).

I would recommend existats for an overview of exim logs.
