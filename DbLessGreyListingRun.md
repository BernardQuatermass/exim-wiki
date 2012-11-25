Greylisting without a database and without Perl
===============================================

Introduction
------------

I used [Michael Peek's Perl script](DbLessGreyListing), then decided
to reimplement its general algorithm without using Perl in order to
decrease memory expense. You can choose between two variants:
[one](DbLessGreyListingC) requires to recompile Exim (4.51 or newer)
but is more efficient, another described here works with any Exim
instance (Perl support isn't needed) but is slightly slower (though much
faster than Perl).

Michael wrote:

[Table not converted]

It certainly makes sense. A filesystem can be considered as a database
of sorts, using it for keeping greylisting data requires much less
memory and maintenance. My implementation also keeps the data in files
in a directory, but I place the data into filenames, not file content -
that speeds up searching. Also, with my modifications of the algorithm a
(long) update at every call is unnecessary.

Requirements
------------
-   Basic knowledge of your Exim configuration file.
-   Basic knowledge of Unix commands.

Collect info
------------

You need to know where binaries of some Unix commands live and where
Exim spool directory is. Run commands:

    whereis find touch; exim -be '$spool_directory'

In my case (FreeBSD) the output is:

    find: /usr/bin/find /usr/share/man/man1/find.1.gz /usr/src/usr.bin/find
    touch: /usr/bin/touch /usr/share/man/man1/touch.1.gz /usr/src/usr.bin/touch
    /var/spool/exim

So, in my case both `find` and `touch` binaries are in `/usr/bin`, Exim
spool directory is `/var/spool/exim`

Create directory
----------------

In Exim spool directory create a subdirectory `greylist` with same owner
and permissions as other subdirectories there. An example:

    root@lena:/root# cd /var/spool/exim/
    root@lena:/var/spool/exim# ls -l
    total 56
    drwxr-x---  2 mailnull  mail    512 May 17 17:23 db
    drwxr-x---  2 mailnull  mail    512 May 24 21:59 input
    drwxr-x---  2 mailnull  mail    512 May 24 21:44 msglog
    drwxr-x---  2 mailnull  mail    512 May 24 21:59 scan
    root@lena:/var/spool/exim# mkdir greylist
    root@lena:/var/spool/exim# chown mailnull:mail greylist
    root@lena:/var/spool/exim# chmod 750 greylist

Create a cron job
-----------------

Create a cron job like this (one line):

    */30 * * * * /usr/bin/find /var/spool/exim/greylist -cmin +363 -type f -delete

Here 363 is time in minutes: after the first attempt (defer), letters
from the /24 block with the envelope-from and envelope-to addresses are
deferred for 3 minutes, then allowed for a time between 6 hours and 6.5
hours.

Edit your Exim config file
--------------------------

Make a backup copy of your Exim configuration file.

If you used the Perl script for greylisting and don't use Perl for
anything else then delete (or comment out) the `perl_startup` line.

For simplest usage, in your RCPT acl check choose a place (somewhere
below accepting authenticated users) to put something like this (correct
directory names if they differ in your operating system):

    warn set acl_m_greyfile = /var/spool/exim/greylist/${length_255:\
      ${sg{$sender_host_address}{\N\.\d+$\N}{}},\
      ${sg{$sender_address,$local_part@$domain}{\N[^\w.,=@-]\N}{} }}

    defer log_message = greylisted
      condition = ${if exists{$acl_m_greyfile}\
      {${if >{${eval:$tod_epoch-\
      ${extract{mtime}{${stat:$acl_m_greyfile}} }}\
      }{180}{0}{1}}\
      }{${if eq{${run{/usr/bin/touch $acl_m_greyfile} }}{}{1}{1} }} }
      message = Deferred: Temporary error, please try again later

Here the first `sg` does the same as `$cidr_mask=24` in Michael's
script, 180 is defer timeout in seconds.

If you use Exim 4.63 or older then change `$acl_m_greyfile` to for
example `$acl_m9`.

I greylist only suspicious connections and use various whitelists in
order to minimize delays and false positives. You can use [snippets from
my Exim configuration file](http://lena.kiev.ua/Lena-eximconf-run.txt)
for developing your Exim configuration.

You can test greylisting on one email address (receiving spam) before
employing it for all mail, for that insert a condition between
`log_message` and the condition with `exists`, like this:

    condition = ${if eq{$local_part@$domain}\
                       {someaddress@your.domain}}

Restart Exim
------------

Check syntax of your updated Exim configuration file with `exim -bV`,
restart exim daemon (using `kill -HUP`) and watch the log files for
possible errors.

No maintenance needed
---------------------

The data is kept in names of files in the `greylist` directory. Its size
varies, but doesn't grow forever. My mailserver endures about 3 thousand
spam attempts per day, at the time of this writing the directory is 25
Kbytes long and contains 350 files. No noticeable delays were observed
in case of 60000 files (FreeBSD 7). 350000 files proved too much (too
slow) - in case of so heavy load a database copes better. Quantity of
files is limited also by quantity of free inodes on the partition with
the `greylist` directory (one inode per file). Check quantity of free
inodes with `df -i` command. For example, under FreeBSD a 3 GB /var
partition has 400000 free inodes by default.

[Lena](Lena)
