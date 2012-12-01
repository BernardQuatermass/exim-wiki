Greylisting without a database and without Perl
===============================================

Introduction
------------

I used [Michael Peek's Perl script](DbLessGreyListing), then decided
to reimplement its general algorithm without using Perl in order to
decrease memory expense. You can choose between two variants: one
described here requires to recompile Exim (4.51 or newer) but is more
efficient, [another](DbLessGreyListingRun) works with any Exim
instance (Perl support isn't needed) but is slightly slower (though much
faster than Perl).

Michael wrote:
> We're a small organization, and I'm a lazy man. I don't really want to set up and maintain a database server. Especially since for us a greylist only involves keeping track of a few hundred KB of data at any one time.

It certainly makes sense. A filesystem can be considered as a database
of sorts, using it for keeping greylisting data requires much less
memory and maintenance. My implementation also keeps the data in files
in a directory, but I place the data into filenames, not file content -
it speeds up searching. Also, it runs update faster and much less
frequently.

Requirements
------------
-   Exim source and knowledge how to compile it.
-   Basic knowledge of your Exim configuration file.

Recompile Exim
--------------

You need to change some options and recompile Exim without "make clean"
at the end. Exim documentation says [(11.5,
dlfunc)](http://exim.org/exim-html-current/doc/html/spec_html/ch11.html#SECTexpansionitems):
*This functionality is available only if Exim is compiled with*
`EXPAND_DLFUNC=yes` *set in Local/Makefile*; *in the Exim build-time
configuration, you must add* `-export-dynamic` *to EXTRALIBS.*

### FreeBSD

Here I describe how I did it under FreeBSD. If you did it under some
other operating system then please edit this wiki page adding how you
did it.
-   Update ports tree.
-   Edit the file `/usr/ports/mail/exim/files/patch-src::EDITME` : at
    the end of the long line beginning with `+EXTRALIBS` add a blank and
    `-export-dynamic`
-   Recompile Exim and reinstall:

<!-- -->

    cd /usr/ports/mail/exim
    make clean all deinstall reinstall

After that a directory for example
`/usr/ports/mail/exim/work/exim-4.76/build-FreeBSD-i386` contains files
needed for the next step, so don't do `make clean` after reinstall.
-   Restore your versions of scripts such as
    `/usr/local/etc/periodic/daily/460.exim-mail-rejects` and
    `/usr/local/etc/rc.d/exim` if you edited them earlier.

Dynamically linked module
-------------------------

Download attached source of the module: [exim-ext-grey.c](attachments/exim-ext-grey.c.txt)
save it for example in the `/root` directory and compile placing the
binary for example in `/root/bin` :

    gcc -O2 -Wall -Werror -shared -fPIC -g \
    -I/usr/ports/mail/exim/work/exim-4.76/build-FreeBSD-i386 \
    -L/usr/local/lib \
    -o /root/bin/exim-ext-grey.so /root/exim-ext-grey.c
    strip /root/bin/exim-ext-grey.so

Edit your Exim config file
--------------------------

Make a backup copy of your Exim configuration file.

If you used the Perl script for greylisting and don't use Perl for
anything else then delete (or comment out) the `perl_startup` line.

For simplest usage, in your RCPT acl check choose a place (somewhere
below accepting authenticated users) to put something like this:

    defer log_message = greylisted
          condition = ${dlfunc{/root/bin/exim-ext-grey.so}{grey}\
                        {${sg{$sender_host_address}{\N\.\d+$\N}{}},\
                         $sender_address,$local_part@$domain}}
          message = Deferred: Temporary error, please try again later

Here `sg` does the same as `$cidr_mask=24` in Michael's script.

I greylist only suspicious connections and use various whitelists in
order to minimize delays and false positives. You can use [snippets from
my Exim configuration file](http://lena.kiev.ua/Lena-eximconf.txt) for
developing your Exim configuration.

You can test greylisting on one email address (receiving spam) before
employing it for all mail, for that insert a condition between
`log_message` and the condition with `dlfunc`, like this:

    condition = ${if eq{$local_part@$domain}\
                       {someaddress@your.domain}}

Restart Exim
------------

Check syntax of your updated Exim configuration file with `exim -bV`,
restart exim daemon (using `kill -HUP`) and watch the log files for
possible errors.

No maintenance needed
---------------------

At the very first run the module creates empty file `grey.lastupdated`
and subdirectory `grey` in Exim spool directory. The data is kept in
names of files in the `grey` subdirectory. Its size varies, but doesn't
grow forever. My mailserver endures about 3 thousand spam attempts per
day, at the time of this writing the subdirectory is 25 Kbytes long and
contains 350 files. No noticeable delays were observed in case of 60000
files (FreeBSD 7). 350000 files proved too much (too slow) - in case of
so heavy load a database copes better. Quantity of files is limited also
by quantity of free inodes on the partition with the `grey` directory
(one inode per file). Check quantity of free inodes with `df -i`
command. For example, under FreeBSD a 3 GB /var partition has 400000
free inodes by default.

[Lena](Lena).
