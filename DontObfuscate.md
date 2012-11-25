Don't Obfuscate on the Exim Mailing Lists
=========================================

Try not to mask out detail from your log extracts, configuration
snippets, error messages, or problem statements. There are often
important clues to be found there, and what's irrelevant detail to you
could be the key to the problem (this makes sense because if you knew
what was important already, you probably could have solved the problem
yourself).

At a minimum, leave the RHS of email addresses intact, and all IP
addresses. There's nothing secret about an IP address, and nobody can
deduce anything from a domain name in your log that they can't find in
dozens of other places already. If individual localparts are key to the
problem, try to leave those intact, too. If you must avoid posting a
particular localpart, try to recreate the problem on your server using a
dummy address.

Apart from these reasons, it's only too easy to introduce errors when
you manually obfuscate things prior to posting, and the people answering
your question will waste time pointing out inconsistencies in your
obfuscation rather than concentrating on the real problem.

This rule is part of the agreed
[MailingListEtiquette](MailingListEtiquette) followed on all Exim
mailing lists.

Why was I sent this URL?
------------------------

You may find that some people on the Exim mailing lists refuse to answer
questions posted with obfuscated logs or configuration files. If you
post obfuscated details on the mailing list, you may receive a reply
directing you to this page. If you repost your question with
unobfuscated logs and configuration files, you might be more likely to
receive a helpful answer from the members of the Exim mailing lists.
