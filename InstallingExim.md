Installing Exim
===============

First you need to obtain a copy of Exim - either the source of a binary
package for your platform. In either case this is covered in
[ObtainingExim](ObtainingExim).

Standard Build Instructions
---------------------------

### Unpacking

Exim is distributed as a gzipped or bzipped tar file which, when
upacked, creates directory with the name of the current release (for
example, exim-4.40) into which the following files are placed:

    ACKNOWLEDGMENTS       contains some acknowledgments
    CHANGES       contains a reference to where changes are documented
    LICENCE       the GNU General Public Licence
    Makefile      top-level make file
    NOTICE        conditions for the use of Exim
    README        list of files, directories and simple build instructions

Other files whose names begin with README may also be present. The
following subdirectories are created:

    Local      an empty directory for local configuration files
    OS         OS-specific files
    doc        documentation files
    exim_monitor source files for the Exim monitor
    scripts    scripts used in the build process
    src        remaining source files
    util       independent utilities

The main utility programs are contained in the src directory, and are
built with the Exim binary. The util directory contains a few optional
scripts that may be useful to some sites.

### Multiple machine architectures and operating systems

The building process for Exim is arranged to make it easy to build
binaries for a number of different architectures and operating systems
from the same set of source files. Compilation does not take place in
the src directory. Instead, a build directory is created for each
architecture and operating system. Symbolic links to the sources are
installed in this directory, which is where the actual building takes
place.

In most cases, Exim can discover the machine architecture and operating
system for itself, but the defaults can be overridden if necessary.

### DBM libraries

Even if you do not use any DBM files in your configuration, Exim still
needs a DBM library in order to operate, because it uses indexed files
for its hints databases. Unfortunately, there are a number of DBM
libraries in existence, and different operating systems often have
different ones installed.

If you are using Solaris, IRIX, one of the modern BSD systems, or a
modern Linux distribution, the DBM configuration should happen
automatically, and you may be able to ignore this section. Otherwise,
you may have to learn more than you would like about DBM libraries from
what follows.

Licensed versions of Unix normally contain a library of DBM functions
operating via the ndbm interface, and this is what Exim expects by
default. Free versions of Unix seem to vary in what they contain as
standard. In particular, some early versions of Linux have no default
DBM library, and different distributors have chosen to bundle different
libraries with their packaged versions. However, the more recent
releases seem to have standardised on the Berkeley DB library.

Different DBM libraries have different conventions for naming the files
they use. When a program opens a file called dbmfile, there are four
possibilities:

1.  A traditional ndbm implementation, such as that supplied as part of
    Solaris, operates on two files called dbmfile.dir and dbmfile.pag.

2.  The GNU library, gdbm, operates on a single file. If used via its
    ndbm compatibility interface it makes two different hard links to it
    with names dbmfile.dir and dbmfile.pag, but if used via its native
    interface, the file name is used unmodified.

3.  The Berkeley DB package, if called via its ndbm compatibility
    interface, operates on a single file called dbmfile.db, but
    otherwise looks to the programmer exactly the same as the
    traditional ndbm implementation.

4.  If the Berkeley package is used in its native mode, it operates on a
    single file called dbmfile; the programmer's interface is somewhat
    different to the traditional ndbm interface.

5.  To complicate things further, there are several very different
    versions of the Berkeley DB package. Version 1.85 was stable for a
    very long time, releases 2.x and 3.x were current for a while, but
    the latest versions are now numbered 4.x. Maintenance of some of the
    earlier releases has ceased. All versions of Berkeley DB can be
    obtained from [http://www.sleepycat.com](http://www.sleepycat.com)/

6.  Yet another DBM library, called tdb, has become available from
    [http://download.sourceforge.net/tdb](http://download.sourceforge.net/tdb)
    It has its own interface, and also operates on a single file.

Exim and its utilities can be compiled to use any of these interfaces.
In order to use any version of the Berkeley DB package in native mode,
you must set USE\_DB in an appropriate configuration file (typically
Local/Makefile). For example:

    USE_DB=yes

Similarly, for gdbm you set USE\_GDBM, and for tdb you set USE\_TDB. An
error is diagnosed if you set more than one of these.

At the lowest level, the build-time configuration sets none of these
options, thereby assuming an interface of type (1). However, some
operating system configuration files (for example, those for the BSD
operating systems and Linux) assume type (4) by setting USE\_DB as their
default, and the configuration files for Cygwin set USE\_GDBM. Anything
you set in Local/Makefile, however, overrides these system defaults.

As well as setting USE\_DB, USE\_GDBM, or USE\_TDB, it may also be
necessary to set DBMLIB, to cause inclusion of the appropriate library,
as in one of these lines:

    DBMLIB = -ldb
    DBMLIB = -ltdb

Settings like that will work if the DBM library is installed in the
standard place. Sometimes it is not, and the library's header file may
also not be in the default path. You may need to set INCLUDE to specify
where the header file is, and to specify the path to the library more
fully in DBMLIB, as in this example:

    INCLUDE=-I/usr/local/include/db-4.1
    DBMLIB=/usr/local/lib/db-4.1/libdb.a

There is further detailed discussion about the various DBM libraries in
the file `doc/dbm.discuss.txt` in the Exim distribution.

### Pre-building configuration

Before building Exim, a local configuration file that specifies options
independent of any operating system has to be created with the name
Local/Makefile. A template for this file is supplied as the file
src/EDITME, and it contains full descriptions of all the option settings
therein. These descriptions are therefore not repeated here. If you are
building Exim for the first time, the simplest thing to do is to copy
src/EDITME to Local/Makefile, then read it and edit it appropriately.

There are three settings that you must supply, because Exim will not
build without them. They are the location of the run time configuration
file (CONFIGURE\_FILE), the directory in which Exim binaries will be
installed (BIN\_DIRECTORY), and the identity of the Exim user
(EXIM\_USER and maybe EXIM\_GROUP as well). The value of CONFIGURE\_FILE
can in fact be a colon-separated list of file names; Exim uses the first
of them that exists.

There are a few other parameters that can be specified either at build
time or at run time, to enable the same binary to be used on a number of
different machines. However, if the locations of Exim's spool directory
and log file directory (if not within the spool directory) are fixed, it
is recommended that you specify them in Local/Makefile instead of at run
time, so that errors detected early in Exim's execution (such as a
malformed configuration file) can be logged.

If you are going to build the Exim monitor, a similar configuration
process is required. The file exim\_monitor/EDITME must be edited
appropriately for your installation and saved under the name
Local/eximon.conf. If you are happy with the default settings described
in exim\_monitor/EDITME, Local/eximon.conf can be empty, but it must
exist.

This is all the configuration that is needed in straightforward cases
for known operating systems. However, the building process is set up so
that it is easy to override options that are set by default or by
operating-system-specific configuration files, for example to change the
name of the C compiler, which defaults to gcc. See section 4.10 below
for details of how to do this. 4.5. Support for iconv()

The contents of header lines in messages may be encoded according to the
rules described RFC 2047. This makes it possible to transmit characters
that are not in the ASCII character set, and to label them as being in a
particular character set. When Exim is inspecting header lines by means
of the \$h\_ mechanism, it decodes them, and translates them into a
specified character set (default ISO-8859-1). The translation is
possible only if the operating system supports the iconv() function.

However, some of the operating systems that supply iconv() do not
support very many conversions. The GNU libiconv library (available from
[http://www.gnu.org/software/libiconv/](http://www.gnu.org/software/libiconv/))
can be installed on such systems to remedy this deficiency, as well as
on systems that do not supply iconv() at all. After installing libiconv,
you should add

    HAVE_ICONV=yes

to your Local/Makefile and rebuild Exim.

### Including TLS/SSL encryption support

Exim can be built to support encrypted SMTP connections, using the
STARTTLS command as per RFC 2487. It can also support legacy clients
that expect to start a TLS session immediately on connection to a
non-standard port (see the -tls-on-connect command line option).

If you want to build Exim with TLS support, you must first install
either the OpenSSL or GnuTLS library. There is no cryptographic code in
Exim itself for implementing SSL.

If OpenSSL is installed, you should set

    SUPPORT_TLS=yes
    TLS_LIBS=-lssl -lcrypto

in Local/Makefile. You may also need to specify the locations of the
OpenSSL library and include files. For example:

    SUPPORT_TLS=yes
    TLS_LIBS=-L/usr/local/openssl/lib -lssl -lcrypto
    TLS_INCLUDE=-I/usr/local/openssl/include/

If GnuTLS is installed, you should set

    SUPPORT_TLS=yes
    USE_GNUTLS=yes
    TLS_LIBS=-lgnutls -ltasn1 -lgcrypt

in Local/Makefile, and again you may need to specify the locations of
the library and include files. For example:

    SUPPORT_TLS=yes
    USE_GNUTLS=yes
    TLS_LIBS=-L/usr/gnu/lib -lgnutls -ltasn1 -lgcrypt
    TLS_INCLUDE=-I/usr/gnu/include

You do not need to set TLS\_INCLUDE if the relevant directory is already
specified in INCLUDE. Details of how to configure Exim to make use of
TLS are given in chapter 37.

### Use of tcpwrappers

Exim can be linked with the tcpwrappers library in order to check
incoming SMTP calls using the tcpwrappers control files. This may be a
convenient alternative to Exim's own checking facilities for
installations that are already making use of tcpwrappers for other
purposes. To do this, you should set USE\_TCP\_WRAPPERS in
Local/Makefile, arrange for the file tcpd.h to be available at compile
time, and also ensure that the library libwrap.a is available at link
time, typically by including -lwrap in EXTRALIBS\_EXIM. For example, if
tcpwrappers is installed in /usr/local, you might have

    USE_TCP_WRAPPERS=yes
    CFLAGS=-O -I/usr/local/include
    EXTRALIBS_EXIM=-L/usr/local/lib -lwrap

in Local/Makefile. The name to use in the tcpwrappers control files is
"exim". For example, the line

    exim : LOCAL 192.168.1. .friendly.domain.example

in your /etc/hosts.allow file allows connections from the local host,
from the subnet 192.168.1.0/24, and from all hosts in
friendly.domain.example. All other connections are denied. Consult the
tcpwrappers documentation for further details.

### Including support for IPv6

Exim contains code for use on systems that have IPv6 support. Setting
HAVE\_IPV6=YES in Local/Makefile causes the IPv6 code to be included; it
may also be necessary to set IPV6\_INCLUDE and IPV6\_LIBS on systems
where the IPv6 support is not fully integrated into the normal include
and library files.

IPv6 is still changing rapidly. Two different types of DNS record for
handling IPv6 addresses have been defined. AAAA records are already in
use, and are currently seen as the "mainstream", but another record type
called A6 is being argued about. Its status is currently "experimental".
Exim has support for A6 records, but this is included only if you set
SUPPORT\_A6=YES in Local/Makefile. 4.9. The building process

Once Local/Makefile (and Local/eximon.conf, if required) have been
created, run make at the top level. It determines the architecture and
operating system types, and creates a build directory if one does not
exist. For example, on a Sun system running Solaris 8, the directory
build-SunOS5-5.8-sparc is created. Symbolic links to relevant source
files are installed in the build directory.

Warning: The -j (parallel) flag must not be used with make; the building
process fails if it is set.

If this is the first time make has been run, it calls a script that
builds a make file inside the build directory, using the configuration
files from the Local directory. The new make file is then passed to
another instance of make. This does the real work, building a number of
utility scripts, and then compiling and linking the binaries for the
Exim monitor (if configured), a number of utility programs, and finally
Exim itself. The command make makefile can be used to force a rebuild of
the make file in the build directory, should this ever be necessary.

If you have problems building Exim, check for any comments there may be
in the README file concerning your operating system, and also take a
look at the FAQ, where some common problems are covered. 4.10.
Overriding build-time options for Exim

The main make file that is created at the beginning of the building
process consists of the concatenation of a number of files which set
configuration values, followed by a fixed set of make instructions. If a
value is set more than once, the last setting overrides any previous
ones. This provides a convenient way of overriding defaults. The files
that are concatenated are, in order:

    OS/Makefile-Default
    OS/Makefile-<ostype>
    Local/Makefile
    Local/Makefile-<ostype>
    Local/Makefile-<archtype>
    Local/Makefile-<ostype>-<archtype>
    OS/Makefile-Base

where *\<ostype\>* is the operating system type and *\<archtype\>* is
the architecture type. Local/Makefile is required to exist, and the
building process fails if it is absent. The other three Local files are
optional, and are often not needed.

The values used for \<ostype\> and \<archtype\> are obtained from
scripts called scripts/os-type and scripts/arch-type respectively. If
either of the environment variables EXIM\_OSTYPE or EXIM\_ARCHTYPE is
set, their values are used, thereby providing a means of forcing
particular settings. Otherwise, the scripts try to get values from the
uname command. If this fails, the shell variables OSTYPE and ARCHTYPE
are inspected. A number of ad hoc transformations are then applied, to
produce the standard names that Exim expects. You can run these scripts
directly from the shell in order to find out what values are being used
on your system.

OS/Makefile-Default contains comments about the variables that are set
therein. Some (but not all) are mentioned below. If there is something
that needs changing, review the contents of this file and the contents
of the make file for your operating system (OS/Makefile-\<ostype\>) to
see what the default values are.

If you need to change any of the values that are set in
OS/Makefile-Default or in OS/Makefile-\<ostype\>, or to add any new
definitions, you do not need to change the original files. Instead, you
should make the changes by putting the new values in an appropriate
Local file. For example, when building Exim in many releases of the
Tru64-Unix (formerly Digital UNIX, formerly DEC-OSF1) operating system,
it is necessary to specify that the C compiler is called cc rather than
gcc. Also, the compiler must be called with the option -std1, to make it
recognize some of the features of Standard C that Exim uses. (Most other
compilers recognize Standard C by default.) To do this, you should
create a file called Local/Makefile-OSF1 containing the lines

    CC=cc
    CFLAGS=-std1

If you are compiling for just one operating system, it may be easier to
put these lines directly into Local/Makefile.

Keeping all your local configuration settings separate from the
distributed files makes it easy to transfer them to new versions of Exim
simply by copying the contents of the Local directory.

Exim contains support for doing LDAP, NIS, NIS+, and other kinds of file
lookup, but not all systems have these components installed, so the
default is not to include the relevant code in the binary. All the
different kinds of file and database lookup that Exim supports are
implemented as separate code modules which are included only if the
relevant compile-time options are set. In the case of LDAP, NIS, and
NIS+, the settings for Local/Makefile are:

    LOOKUP_LDAP=yes
    LOOKUP_NIS=yes
    LOOKUP_NISPLUS=yes

and similar settings apply to the other lookup types. They are all
listed in src/EDITME. In most cases the relevant include files and
interface libraries need to be installed before compiling Exim. However,
in the case of cdb, which is included in the binary only if

    LOOKUP_CDB=yes

is set, the code is entirely contained within Exim, and no external
include files or libraries are required. When a lookup type is not
included in the binary, attempts to configure Exim to use it cause run
time configuration errors.

Exim can be linked with an embedded Perl interpreter, allowing Perl
subroutines to be called during string expansion. To enable this
facility,

    EXIM_PERL=perl.o

must be defined in Local/Makefile. Details of this facility are given in
chapter 12.

The location of the X11 libraries is something that varies a lot between
operating systems, and of course there are different versions of X11 to
cope with. Exim itself makes no use of X11, but if you are compiling the
Exim monitor, the X11 libraries must be available. The following three
variables are set in OS/Makefile-Default:

    X11=/usr/X11R6
    XINCLUDE=-I$(X11)/include
    XLFLAGS=-L$(X11)/lib

These are overridden in some of the operating-system configuration
files. For example, in OS/Makefile-SunOS5 there is

    X11=/usr/openwin
    XINCLUDE=-I$(X11)/include
    XLFLAGS=-L$(X11)/lib -R$(X11)/lib

If you need to override the default setting for your operating system,
place a definition of all three of these variables into your
Local/Makefile-\<ostype\> file.

If you need to add any extra libraries to the link steps, these can be
put in a variable called EXTRALIBS, which appears in all the link
commands, but by default is not defined. In contrast, EXTRALIBS\_EXIM is
used only on the command for linking the main Exim binary, and not for
any associated utilities. There is also DBMLIB, which appears in the
link commands for binaries that use DBM functions (see also section
4.3). Finally, there is EXTRALIBS\_EXIMON, which appears only in the
link step for the Exim monitor binary, and which can be used, for
example, to include additional X11 libraries.

The make file copes with rebuilding Exim correctly if any of the
configuration files are edited. However, if an optional configuration
file is deleted, it is necessary to touch the associated non-optional
file (that is, Local/Makefile or Local/eximon.conf) before rebuilding.
4.11. OS-specific header files

The OS directory contains a number of files with names of the form
os.h-\<ostype\>. These are system-specific C header files that should
not normally need to be changed. There is a list of macro settings that
are recognized in the file OS/os.configuring, which should be consulted
if you are porting Exim to a new operating system.

### Overriding build-time options for the monitor

A similar process is used for overriding things when building the Exim
monitor, where the files that are involved are

    OS/eximon.conf-Default
    OS/eximon.conf-<ostype>
    Local/eximon.conf
    Local/eximon.conf-<ostype>
    Local/eximon.conf-<archtype>
    Local/eximon.conf-<ostype>-<archtype>

As with Exim itself, the final three files need not exist, and in this
case the OS/eximon.conf-\<ostype\> file is also optional. The default
values in OS/eximon.conf-Default can be overridden dynamically by
setting environment variables of the same name, preceded by EXIMON\_.
For example, setting EXIMON\_LOG\_DEPTH in the environment overrides the
value of LOG\_DEPTH at run time.

### Installing Exim binaries and scripts

The command make install runs the exim\_install script with no
arguments. The script copies binaries and utility scripts into the
directory whose name is specified by the BIN\_DIRECTORY setting in
Local/Makefile.

Exim's run time configuration file is named by the CONFIGURE\_FILE
setting in Local/Makefile. If this names a single file, and the file
does not exist, the default configuration file src/configure.default is
copied there by the installation script. If a run time configuration
file already exists, it is left alone. If CONFIGURE\_FILE is a
colon-separated list, naming several alternative files, no default is
installed.

One change is made to the default configuration file when it is
installed: the default configuration contains a router that references a
system aliases file. The path to this file is set to the value specified
by SYSTEM\_ALIASES\_FILE in Local/Makefile (/etc/aliases by default). If
the system aliases file does not exist, the installation script creates
it, and outputs a comment to the user.

The created file contains no aliases, but it does contain comments about
the aliases a site should normally have. Mail aliases have traditionally
been kept in /etc/aliases. However, some operating systems are now using
/etc/mail/aliases. You should check if yours is one of these, and change
Exim's configuration if necessary.

The default configuration uses the local host's name as the only local
domain, and is set up to do local deliveries into the shared directory
/var/mail, running as the local user. System aliases and .forward files
in users' home directories are supported, but no NIS or NIS+ support is
configured. Domains other than the name of the local host are routed
using the DNS, with delivery over SMTP.

The install script copies files only if they are newer than the files
they are going to replace. The Exim binary is required to be owned by
root and have the setuid bit set, for normal configurations. Therefore,
you must run make install as root so that it can set up the Exim binary
in this way. However, in some special situations (for example, if a host
is doing no local deliveries) it may be possible to run Exim without
making the binary setuid root (see chapter 48 for details).

It is possible to install Exim for special purposes (such as building a
binary distribution) in a private part of the file system. You can do
this by a command such as

    make DESTDIR=/some/directory/ install

This has the effect of pre-pending the specified directory to all the
file paths, except the name of the system aliases file that appears in
the default configuration. (If a default alias file is created, its name
is modified.) For backwards compatibility, ROOT is used if DESTDIR is
not set, but this usage is deprecated.

Running make install does not copy the Exim 4 conversion script
convert4r4, or the pcretest test program. You will probably run the
first of these only once (if you are upgrading from Exim 3), and the
second isn't really part of Exim. None of the documentation files in the
doc directory are copied, except for the info files when you have set
INFO\_DIRECTORY, as described in section 4.14 below.

For the utility programs, old versions are renamed by adding the suffix
.O to their names. The Exim binary itself, however, is handled
differently. It is installed under a name that includes the version
number and the compile number, for example exim-4.40-1. The script then
arranges for a symbolic link called exim to point to the binary. If you
are updating a previous version of Exim, the script takes care to ensure
that the name exim is never absent from the directory (as seen by other
processes).

If you want to see what the make install will do before running it for
real, you can pass the -n option to the installation script by this
command:

    make INSTALL_ARG=-n install

The contents of the variable INSTALL\_ARG are passed to the installation
script. You do not need to be root to run this test. Alternatively, you
can run the installation script directly, but this must be from within
the build directory. For example, from the top-level Exim directory you
could use this command:

    (cd build-SunOS5-5.5.1-sparc; ../scripts/exim_install -n)

There are two other options that can be supplied to the installation
script.
-   `-no_chown` bypasses the call to change the owner of the installed
    binary to root, and the call to make it a setuid binary.
-   `-no_symlink` bypasses the setting up of the symbolic link exim to
    the installed binary.

INSTALL\_ARG can be used to pass these options to the script. For
example:

    make INSTALL_ARG=-no_symlink install

The installation script can also be given arguments specifying which
files are to be copied. For example, to install just the Exim binary,
and nothing else, without creating the symbolic link, you could use:

    make INSTALL_ARG='-no_symlink exim' install

### Installing info documentation

Not all systems use the GNU info system for documentation, and for this
reason, the Texinfo source of Exim's documentation is not included in
the main distribution. Instead it is available separately from the ftp
site (see section 1.5).

If you have defined INFO\_DIRECTORY in Local/Makefile and the Texinfo
source of the documentation is found in the source tree, running make
install automatically builds the info files and installs them.

### Setting up the spool directory

When it starts up, Exim tries to create its spool directory if it does
not exist. The Exim uid and gid are used for the owner and group of the
spool directory. Sub-directories are automatically created in the spool
directory as necessary.

### Testing

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

If you encounter problems, look at Exim's log files (mainlog and
paniclog) to see if there is any relevant information there. Another
source of information is running Exim with debugging turned on, by
specifying the -d option. If a message is stuck on Exim's spool, you can
force a delivery with debugging turned on by a command of the form

    exim -d -M <message-id>

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
entirely clear of the production version. 4.17. Replacing another MTA
with Exim

Building and installing Exim for the first time does not of itself put
it in general use. The name by which the system's MTA is called by mail
user agents is either /usr/sbin/sendmail, or /usr/lib/sendmail
(depending on the operating system), and it is necessary to make this
name point to the exim binary in order to get the user agents to pass
messages to Exim. This is normally done by renaming any existing file
and making /usr/sbin/sendmail or /usr/lib/sendmail a symbolic link to
the exim binary. It is a good idea to remove any setuid privilege and
executable status from the old MTA. It is then necessary to stop and
restart the mailer daemon, if one is running.

Some operating systems have introduced alternative ways of switching
MTAs. For example, if you are running FreeBSD, you need to edit the file
/etc/mail/mailer.conf instead of setting up a symbolic link as just
described. A typical example of the contents of this file for running
Exim is as follows:

    sendmail            /usr/exim/bin/exim
    send-mail           /usr/exim/bin/exim
    mailq               /usr/exim/bin/exim -bp
    newaliases          /usr/bin/true

Once you have set up the symbolic link, or edited /etc/mail/mailer.conf,
your Exim installation is "live". Check it by sending a message from
your favourite user agent.

You should consider what to tell your users about the change of MTA.
Exim may have different capabilities to what was previously running, and
there are various operational differences such as the text of messages
produced by command line options and in bounce messages. If you allow
your users to make use of Exim's filtering capabilities, you should make
the document entitled Exim's interface to mail filtering available to
them.

### Upgrading Exim

If you are already running Exim on your host, building and installing a
new version automatically makes it available to MUAs, or any other
programs that call the MTA directly. However, if you are running an Exim
daemon, you do need to send it a HUP signal, to make it re-exec itself,
and thereby pick up the new binary. You do not need to stop processing
mail in order to install a new version of Exim.

Operating System Specific Information
-------------------------------------

### Solaris
-   [Solaris10Smf](Solaris10Smf) - Running Exim under the control of
    the SMF facility in Solaris 10.
-   Solaris 2.5.1 (as of 4.66)
    -   in OS/os.h-SunOS5
        -   uncomment EXIM\_SOCKLEN\_T definition
        -   change LOAD\_AVE\_FIELD from value.ui32 to value.ul

### AIX
-   [AIX Build Notes](AIXBuildNotes)

[ManagingExim](ManagingExim)

* * * * *

> [CategoryHowTo](CategoryHowTo)
>
> > == Many interesting infos == Now 20051001-084247\_123.
