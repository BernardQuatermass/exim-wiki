
This is a method described by [TimJackson](TimJackson).

When doing spam scanning, and trying to flag "possible spam" to users,
one common method is to tag the Subject header. However, this is a bit
nasty (as it screws up replies etc. if the mail isn't really spam) and
it would be better for end-user filtering to use another header like
X-Spam-Flag or similar. However, unfortunately, some common mail clients
do not permit filtering on arbitrary headers. Therefore, sometimes it's
desirable to allow tagging of the Subject header on a per-user basis so
that users who use sensible mail clients don't get the Subject header
mashed up, but those who use poor clients that can only filter on
Subject can get the messages tagged.

Assuming the X-Spam-Flag header is being set to "YES" in your DATA ACL
(if not, then modify accordingly), add a mantra like this to a suitable
router that most mails are going to pass through: (A downside of this
method is that if you have several "main" routers you may need to
duplicate this code)

    # Add a "*****SPAM***** " prefix to the Subject header, if the X-Spam-Flag header
    # is set to 'YES' and the recipient has enabled spam_replace_subject
    headers_remove = Subject
    headers_add = ${if and{ {eq{$h_X-Spam-Flag:}{YES}} \
                            {eq{${lookup{$local_part@$domain}lsearch*{/path/to/spam_replace_subject} } }{1}} \
                          } \
                            {Subject: *****SPAM***** $h_Subject:} \
                            {Subject: $h_Subject:} \
                   }

You will note that this refers to a file called
/path/to/spam\_replace\_subject: this is a file containing lines like:

    joe@example.com: 1
    bob@example.com: 1
    *:0

In this case,
[[joe@example.com](mailto:joe@example.com)](mailto:joe@example.com) and
[[bob@example.com](mailto:bob@example.com)](mailto:bob@example.com) are
local users that want Subject line spam tagging. All other users
(denoted by the "\*" wildcard) don't.
