* * * * *

> Taken from exim's spec.txt file "as it is" - ie this duplicates
> [http://www.exim.org/exim-html-4.62/doc/html/spec\_html/ch04.html\#id2524758](http://www.exim.org/exim-html-4.62/doc/html/spec_html/ch04.html#id2524758)

* * * * *

Having installed Exim, you can check that the run time configuration
file is syntactically valid by running the following command, which
assumes that the Exim binary directory is within your PATH environment
variable:

    exim -bV

If there are any errors in the configuration file, Exim outputs error
messages. Otherwise it outputs the version number and build date, the
DBM library that is being used, and information about which drivers and
other optional code modules are included in the binary. Some simple
routing tests can be done by using the address testing option. For
example,

    exim -bt <local username>

should verify that it recognizes a local mailbox, and

    exim -bt <remote address>

a remote one. Then try getting it to deliver mail, both locally and
remotely. This can be done by passing messages directly to Exim, without
going through a user agent. For example:

    exim -v postmaster@your.domain.example
    From: user@your.domain.example
    To: postmaster@your.domain.example
    Subject: Testing Exim

    This is a test message.
    ^D

The -v option causes Exim to output some verification of what it is
doing. In this case you should see copies of three log lines, one for
the message's arrival, one for its delivery, and one containing
"Completed".

Admin users can test the malware scanning configuration (in Exim \>=
4.73) with the `-bmalware` option:

    exim -bmalware <filename>

If you encounter problems, look at Exim's log files (mainlog and
paniclog) to see if there is any relevant information there. Another
source of information is running Exim with debugging turned on, by
specifying the -d option. If a message is stuck on Exim's spool, you can
force a delivery with debugging turned on by a command of the form

    exim -d -M <exim-message-id>

You must be root or an "admin user" in order to do this. The -d option
produces rather a lot of output, but you can cut this down to specific
areas. For example, if you use -d-all+route only the debugging
information relevant to routing is included. (See the -d option in
chapter 5 for more details.)

One specific problem that has shown up on some sites is the inability to
do local deliveries into a shared mailbox directory, because it does not
have the "sticky bit" set on it. By default, Exim tries to create a lock
file before writing to a mailbox file, and if it cannot create the lock
file, the delivery is deferred. You can get round this either by setting
the "sticky bit" on the directory, or by setting a specific group for
local deliveries and allowing that group to create files in the
directory (see the comments above the local\_delivery transport in the
default configuration file). Another approach is to configure Exim not
to use lock files, but just to rely on fcntl() locking instead. However,
you should do this only if all user agents also use fcntl() locking. For
further discussion of locking issues, see chapter 26.

One thing that cannot be tested on a system that is already running an
MTA is the receipt of incoming SMTP mail on the standard SMTP port.
However, the -oX option can be used to run an Exim daemon that listens
on some other port, or inetd can be used to do this. The -bh option and
the exim\_checkaccess utility can be used to check out policy controls
on incoming SMTP mail.

Testing a new version on a system that is already running Exim can most
easily be done by building a binary with a different CONFIGURE\_FILE
setting. From within the run time configuration, all other file and
directory names that Exim uses can be altered, in order to keep it
entirely clear of the production version.

* * * * *
