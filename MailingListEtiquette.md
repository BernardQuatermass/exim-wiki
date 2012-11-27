Mailing List Etiquette
======================

The [EximMailingLists](EximMailingLists) are normally reasonably
friendly places, but have a few rules to try and keep them on an even
keel. Most of these fall under the category of basic
[Netiquette](http://www.wikipedia.com/wiki/Netiquette). You may also wish to look at
the [MailingListPolicies](MailingListPolicies).

It is worth looking at documents such as [How to keep out of trouble
with your
e-mail](http://www.penmachine.com/techie/emailtrouble_2003-07.html) and
[How to report bugs
effectively](http://www.chiark.greenend.org.uk/~sgtatham/bugs.html)
since these are very relevant to the lists in general. The following
sections touch on points that are particular bugbears on the lists.

Check Before You Post
---------------------

All of the [EximMailingLists](EximMailingLists) have searchable
archives. Exim has excellent [manuals](http://www.exim.org/docs.html).
There's an excellent
[book](http://books.google.com/books?id=foCRVaMeRMgC). And, there's this
wiki. Please try and find information before posting questions to the
list. If you find things that are similar, but don't fix your specific
problem then mention that in your posting so you don't just get pointed
back to the old information.

Check Again Before You Post
---------------------------

Yes, you read that correctly - read that last paragraph again before
moving on |:)|

Be Polite When Asking Questions
-------------------------------

When asking questions, be polite. Nobody is paid to answer questions, so
do your homework before asking. Be prepared to supply additional
information if required. Be prepared to listen if people tell you that
what you want to do is undesirable. Be patient, you won't get an
immediate response.

Be Polite When Answering Questions
----------------------------------

Similarly, people don't ask questions for fun, they do it because they
don't know the answers. If you aren't answering the question, then your
response may be unwelcome. Here are some unwelcome responses to the
question 'how do I X?'
-   [RTFM](http://www.wikipedia.com/wiki/RTFM) is swearing in a public arena. It
    doesn't directly answer the question and is felt by some to carry an
    arrogant tone. It says "don't waste my time", but it's a waste of
    everybody's time to say it. Better to point someone to the "How to
    X" section of the manual, with a URL, and an explanation of why the
    section is relevant to the question (where necessary). Similar
    comments apply to the wiki and the list archives.

If you feel you have to say something akin to RTFM, then please use the
following:

* * * * *

> *I feel that your question is answered in the FAQ and/or the
> documentation. Therefore, I would suggest that you follow the next
> five steps:*
>
> > *1. Check Exim's log on your system.*
> > :   *2. Run Exim in debug mode.* *3. Check the FAQ.* *4. Check the
> >     documentation.* *5. Check the wiki.*
> >
**IF none** *of those steps helped matters, then please send your
question to the list along with Exim debug output and relevant sections
of non-obfuscated log files.*

*Not following those steps will just lead you to getting more copies of
this email and may waste the time of regular list members.*

*Thank you for your attention.*

* * * * *
-   "X" is evil

The question wasn't about what's evil, and you should assume that the
questioner isn't trying to achieve evil ends. Still, it may be helpful
to explain why doing "X" is a bad idea. Remember, though, that there may
be contexts where "X" is acceptable, or the lesser of two evils.
Ultimately, you have to let some people learn through experience, or
accept that others have different needs. When trying to persuade someone
to take a different course of action, it's even more important to be
polite. Oh, and remember to separate the person from the idea. A daft
idea doesn't make a person daft.

Quote Intelligently When Replying
---------------------------------

You only need to quote the relevant parts of posts you are replying to.
It is far preferable to quote fragments with your contributions added
underneath the quotes. Using the standard
[Outlook](http://www.wikipedia.com/wiki/Outlook) form of [Top
Posting](http://mailformat.dan.info/quoting/top-posting.html) can be
particularly irritating if a long post asking a batch of questions is
responded to with a single answer to one question set above the whole
original article. If you use Outlook or Outlook Express, you might find
[Outlook
Quotefix](http://home.in.tum.de/~jain/software/outlook-quotefix/) or [OE
Quotefix](http://home.in.tum.de/~jain/software/oe-quotefix/) helps with
quoting.

Give Sufficient Information In Questions
----------------------------------------

Exim is a complex beast, and how it works depends on lots of details
about the configuration, the machine its running on, and the version and
compilation options of the software itself. If you ask a question about
exim without giving context then its very difficult to give a good
answer, and so you may not get any answers, or you start a negotiation
stage where people try and get sufficient information to answer the
original question - a process which takes up considerable time on the
parts of many people.

In general you need to say:-
-   What version of exim you are using
-   What OS you are running on
-   Relevant information about your build of exim
-   Quote fragments of logs or error messages relating to the problem.

It's also useful to indicate what steps you've already taken to identify
the problem, and what (if any) information you gained - this will
short-circuit several rounds of preliminary Q&A.

And please don't say 'I tried xxx and it didn't work'. What didn't work?
What unexpected behaviour is it you're seeing? What are the error
messages? What do the logs say? etc. This also helps get to the nitty
gritty of your problem more quickly.

Don't obfuscate detail unless absolutely necessary
--------------------------------------------------

Try not to mask out detail from your log extracts and error messages.
There are often important clues to be found there, and what's irrelevant
detail to you could be the key to the problem (this makes sense because
if you knew what was important already, you probably could have solved
the problem yourself).

For more information about obfuscation on the Exim mailing lists, see
[DontObfuscate](DontObfuscate).

Feature Requests and other Suggestions
--------------------------------------

Be respectful of other people when they make feature requests and
suggestions. Just because you don't need the feature doesn't mean that
everyone else is like you. If the feature is already there you can
politely point that out. Even though 90% feature requests are not worth
doing, the other 10% really help advance Exim for all of us.

Expectations
------------

The lists are managed in the spare time of people who are in general
very busy. Please bear in mind that the voluntary nature of the list's
subscribers means they may not be available to respond immediately.

Don't Restage Old Flame Wars
----------------------------

Some on the mailing lists think that
[SenderPPolicyFFramework](http://www.wikipedia.com/wiki/Sender_Policy_Framework) is
a really good thing, others are considerably less impressed. Rehashing
these discussions is generally unhelpful. Discussions of the `Reply-To:`
setting of the list are also only going to be fruitful if you find the
list manager's price and offer him a sufficient inducement to change the
setting.

Keep List Relevant Stuff On List and Other Stuff Off
----------------------------------------------------

In general discussion should take place on the list itself, and replies
should be sent to the list rather than the originator. Some people
prefer to send responses to both list and originator. If you prefer not
to get CCs to your personal address, set a Reply-to header containing
the mailing list address.

Autoreplies
-----------

See the information about [EximAutoReply](EximAutoReply). If you are
receiving list mail, please ensure that any autoreply system you may
have does not respond to list traffic (which is clearly marked, and will
not mention your email address in the main To/Cc headers). Sending
autoreplies back to the list sender addresses will cause the list
management software to unsubscribe you after a short time. If you send
autoreplies back to individual list contributors or to the list itself,
then your autoreply is very badly broken -- complaints to the list
manager about this normally earn the person causing this an
unsubscription from the list.

Thread Stealing
---------------

Don't start a new topic by replying to posts. This will break threading
in MUAs because they rely on header information. If you reply to a
message from the list, yours will appear as it belongs to some different
topic, even though it has not the same Subject. This confuses readers,
may annoy list regulars and your message may be ignored by people
because they ignore the thread you stole. So try to keep people happy
and just create a new message to the exim-users list address.
