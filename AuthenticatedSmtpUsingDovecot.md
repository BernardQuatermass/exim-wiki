*Update*: Since Exim 4.64 it is possible to use Dovecot-SASL without
patches, see
[http://wiki.dovecot.org/HowTo/EximAndDovecotSASL](http://wiki.dovecot.org/HowTo/EximAndDovecotSASL)

Andrey Panin wrote a patch for exim (version 4.43) to add an
authentication driver called `dovecot` that authenticates against
dovecot's auth system.

I'm saving this information here for future use and easier reference -
here's a link too:
[http://thread.gmane.org/gmane.mail.imap.dovecot/4565](http://thread.gmane.org/gmane.mail.imap.dovecot/4565)
(unfortunately the posting wasn't archived properly in the official
dovecot mailing list archive, see
[http://www.dovecot.org/list/dovecot/2004-December/005534.html)](http://www.dovecot.org/list/dovecot/2004-December/005534.html)).

He wrote:

    attached patch makes possible to use dovecot as an authentication
    backend for Exim 4. Reasons beyond this patch are simple:
    exim's authenticators require use of plaintext passwords and NTLM
    code in exim is quite outdated and hairy.
    Patch generated against Exim 4.43, but should apply to earlier
    versions too.

    Patch adds new 'dovecot' authenticator, which can be used as such:

    ntlm:
            driver = dovecot
            public_name = NTLM
            server_socket = /var/authentication_socket_path
            server_set_id = $1

    cram:
            driver = dovecot
            public_name = CRAM-MD5
            ...

    Authenticator has only one parameter 'server_socket', it's value
    used as path for dovecot's authentication socket. Authenticator
    can be used for server authentication only.

    Hope it will be useful for someone.

    Best regards.

And attached this patch {{{diff -urdpNx build-Linux-i386 -x Local
exim-4.43.vanilla/scripts/MakeLinks exim-4.43/scripts/MakeLinks ---
exim-4.43.vanilla/scripts/MakeLinks 2004-10-05 12:32:08.000000000 +0400
+++ exim-4.43/scripts/MakeLinks 2004-12-09 15:38:46.000000000 +0300 @@
-167,6 +167,8 @@ ln -s ../../src/auths/auth-spa.h

> ln -s ../../src/auths/sha1.c sha1.c ln -s ../../src/auths/spa.c spa.c
> ln -s ../../src/auths/spa.h spa.h

+ln -s ../../src/auths/dovecot.c dovecot.c +ln -s
../../src/auths/dovecot.h dovecot.h

> cd ..
>
> \# The basic source files for Exim and utilities. NB local\_scan.h
> gets linked,

diff -urdpNx build-Linux-i386 -x Local
exim-4.43.vanilla/src/auths/dovecot.c exim-4.43/src/auths/dovecot.c ---
exim-4.43.vanilla/src/auths/dovecot.c 1970-01-01 03:00:00.000000000
+0300 +++ exim-4.43/src/auths/dovecot.c 2004-12-09 15:38:46.000000000
+0300 @@ -0,0 +1,247 @@ +/\* + \* Copyright (c) 2004 Andrey Panin
\<[[pazke@donpac.ru](mailto:pazke@donpac.ru)](mailto:pazke@donpac.ru)\>
+ \* + \* This program is free software; you can redistribute it and/or
modify + \* it under the terms of the GNU General Public License as
published + \* by the Free Software Foundation; either version 2 of the
License, or + \* (at your option) any later version. + */ + +\#include
"../exim.h" +\#include "dovecot.h" + +\#define VERSION\_MAJOR 1
+\#define VERSION\_MINOR 0 + +/* Options specific to the authentication
mechanism. */ +optionlist auth\_dovecot\_options[] = { + { +
"server\_socket", + opt\_stringptr, +
(void*)(offsetof(auth\_dovecot\_options\_block, server\_socket)) + },
+}; + +/\* Size of the options list. An extern variable has to be used
so that its +address can appear in the tables drtables.c. */ +int
auth\_dovecot\_options\_count = + sizeof(auth\_dovecot\_options) /
sizeof(optionlist); + +/* Default private options block for the
authentication method. */ +auth\_dovecot\_options\_block
auth\_dovecot\_option\_defaults = { + NULL, server\_socket +}; +
+/************************************************\* +* Initialization
entry point \* +*************************************************/ + +/*
Called for each instance, after its options have been read, to +enable
consistency checks to be done, or anything else that needs +to be set
up. */ +void auth\_dovecot\_init(auth\_instance*ablock) +{ +
auth\_dovecot\_options\_block *ob = +
(auth\_dovecot\_options\_block*)(ablock-\>options\_block); + + if
(ablock-\>public\_name == NULL) + ablock-\>public\_name = ablock-\>name;
+ if (ob-\>server\_socket != NULL) + ablock-\>server = TRUE; +
ablock-\>client = FALSE; +} + +static int strcut(char *str, char**ptrs,
int nptrs) +{ + char*tmp = str; + int n; + + for (n = 0; n \< nptrs;
n++) + ptrs[n] = NULL; + n = 1; + + while (*str) { + if (*str == 't') {
+ if (n \<= nptrs) { + *ptrs++ = tmp; + tmp = str + 1; +*str = 0; + } +
n++; + } + str++; + } + + if (n \< nptrs) + *ptrs = tmp; + + return n;
+} + +\#define CHECK\_COMMAND(str, arg\_min, arg\_max) do { + if
(strcasecmp((str), args[0]) != 0) + goto out; + if (nargs - 1 \<
(arg\_min)) + goto out; + if (nargs - 1 \> (arg\_max)) + goto out; +}
while (0) + +\#define OUT(msg) do { + auth\_defer\_msg = (msg); + goto
out; +} while(0) + +/************************************************\*
+* Server entry point \*
+*************************************************/ + +int
auth\_dovecot\_server(auth\_instance*ablock, uschar *data) +{ +
auth\_dovecot\_options\_block*ob = + (auth\_dovecot\_options\_block
*)(ablock-\>options\_block); + struct sockaddr\_un sa; + char
buffer[4096]; + char*args[8]; + int nargs, tmp; + int cuid = 0, cont =
1, found = 0, fd, ret = DEFER; + FILE *f; + + memset(&sa, 0,
sizeof(sa)); + sa.sun\_family = AF\_UNIX; + if (strncpy(sa.sun\_path,
ob-\>server\_socket, sizeof(sa.sun\_path)) \< 0) { + auth\_defer\_msg =
"authentication socket path too long"; + return DEFER; + } + +
auth\_defer\_msg = "authentication socket connection error"; + + fd =
socket(PF\_UNIX, SOCK\_STREAM, 0); + if (fd \< 0) + return DEFER; + + if
(connect(fd, (struct sockaddr*) &sa, sizeof(sa)) \< 0) + goto out; + + f
= fdopen(fd, "a+"); + if (f == NULL) + goto out; + + auth\_defer\_msg =
"authentication socket protocol error"; + + while (cont) { + if
(fgets(buffer, sizeof(buffer), f) == NULL) + OUT("authentication socket
read error or premature eof"); + + buffer[strlen(buffer) - 1] = 0; +
nargs = strcut(buffer, args, sizeof(args) / sizeof(args[0])); + + switch
(toupper(*args[0])) { + case 'C': + CHECK\_COMMAND("CUID", 1, 1); + cuid
= atoi(args[1]); + break; + + case 'D': + CHECK\_COMMAND("DONE", 0, 0);
+ cont = 0; + break; + + case 'M': + CHECK\_COMMAND("MECH", 1,
INT\_MAX); + if (!strcasecmp(args[1], ablock-\>public\_name)) + found =
1; + break; + + case 'S': + CHECK\_COMMAND("SPID", 1, 1); + break; + +
case 'V': + CHECK\_COMMAND("VERSION", 2, 2); + if (atoi(args[1]) !=
VERSION\_MAJOR) + OUT("authentication socket protocol version
mismatch"); + break; + + default: + goto out; + } + } + + if (!found) +
goto out; + + fprintf(f, "VERSIONt%dt%drnSERVICEtSMTPrnCPIDt%drn" +
"AUTHt%dt%strip=%stlip=%stresp=%srn", + VERSION\_MAJOR, VERSION\_MINOR,
getpid(), cuid, + ablock-\>public\_name, sender\_host\_address,
interface\_address, + data ? (char*) data : ""); + + while (1) { + if
(fgets(buffer, sizeof(buffer), f) == NULL) { + auth\_defer\_msg =
"authentication socket read error or premature eof"; + goto out; + } + +
buffer[strlen(buffer) - 1] = 0; + nargs = strcut(buffer, args,
sizeof(args) / sizeof(args[0])); + + if (atoi(args[1]) != cuid) +
OUT("authentication socket connection id mismatch"); + + switch
(toupper(*args[0])) { + case 'C': + CHECK\_COMMAND("CONT", 1, 2); + +
tmp = auth\_get\_no64\_data(&data, args[2]); + if (tmp != OK) { + ret =
tmp; + goto out; + } + + if (fprintf(f, "CONTt%dt%srn", cuid, data) \<
0) + OUT("authentication socket write error"); + + break; + + case 'F':
+ CHECK\_COMMAND("FAIL", 1, 2); + + FIXME: add proper response handling
+ if (args[2]) { + char*p = strchr(args[2], '='); + if (p) { + ++p; +
expand\_nstring[1] = p; + expand\_nlength[1] = strlen(p); + expand\_nmax
= 1; + } + } + + ret = FAIL; + goto out; + + case 'O': +
CHECK\_COMMAND("OK", 2, 2); + { + FIXME: add proper response handling +
char *p = strchr(args[2], '='); + if (!p) + OUT("authentication socket
protocol error, username missing"); + + p++; + expand\_nstring[1] = p; +
expand\_nlength[1] = strlen(p); + expand\_nmax = 1; + } + ret = OK; +
fallthrough + + default: + goto out; + } + } + +out: close(fd); + return
ret; +} diff -urdpNx build-Linux-i386 -x Local
exim-4.43.vanilla/src/auths/dovecot.h exim-4.43/src/auths/dovecot.h ---
exim-4.43.vanilla/src/auths/dovecot.h 1970-01-01 03:00:00.000000000
+0300 +++ exim-4.43/src/auths/dovecot.h 2004-12-09 15:47:43.000000000
+0300 @@ -0,0 +1,28 @@
+/************************************************\* +* Exim - an
Internet mail transport agent \*
+*************************************************/ + +/* Copyright (c)
University of Cambridge 1995 - 2003*/ +/* See the file NOTICE for
conditions of use and distribution.*/ + +/* Private structure for the
private options.*/ + +typedef struct { + uschar*server\_socket; +}
auth\_dovecot\_options\_block; + +/\* Data for reading the private
options. */ + +extern optionlist auth\_dovecot\_options[]; +extern int
auth\_dovecot\_options\_count; + +/* Block containing default values. */
+ +extern auth\_dovecot\_options\_block auth\_dovecot\_option\_defaults;
+ +/* The entry points for the mechanism */ + +extern void
auth\_dovecot\_init(auth\_instance*); +extern int
auth\_dovecot\_server(auth\_instance *, uschar*); + +/\* End of
dovecot.h \*/ diff -urdpNx build-Linux-i386 -x Local
exim-4.43.vanilla/src/auths/Makefile exim-4.43/src/auths/Makefile ---
exim-4.43.vanilla/src/auths/Makefile 2004-10-05 12:32:08.000000000 +0400
+++ exim-4.43/src/auths/Makefile 2004-12-09 15:46:44.000000000 +0300 @@
-7,7 +7,7 @@

> OBJ = b64encode.o b64decode.o call\_pam.o call\_pwcheck.o call\_radius.o 
> :   xtextencode.o xtextdecode.o get\_data.o get\_no64\_data.o md5.o
-   cram\_md5.o cyrus\_sasl.o plaintext.o pwcheck.o sha1.o auth-spa.o
    spa.o + cram\_md5.o cyrus\_sasl.o plaintext.o pwcheck.o sha1.o
    auth-spa.o spa.o dovecot.o

> auths.a: \$(OBJ)
>
> > /bin/rm -f auths.a

@@ -37,4 +37,6 @@ cyrus\_sasl.o: \$(HDRS) cyrus\_sasl.c cy

> plaintext.o: \$(HDRS) plaintext.c plaintext.h spa.o: \$(HDRS) spa.c
> spa.h

+dovecot.o: \$(HDRS) dovecot.c dovecot.h +

> \# End

diff -urdpNx build-Linux-i386 -x Local
exim-4.43.vanilla/src/config.h.defaults exim-4.43/src/config.h.defaults
--- exim-4.43.vanilla/src/config.h.defaults 2004-10-05
12:32:08.000000000 +0400 +++ exim-4.43/src/config.h.defaults 2004-12-09
15:38:46.000000000 +0300 @@ -20,6 +20,7 @@ in config.h unless some value
is defined

> \#define AUTH\_CYRUS\_SASL \#define AUTH\_PLAINTEXT \#define AUTH\_SPA

+\#define AUTH\_DOVECOT

> \#define BIN\_DIRECTORY

diff -urdpNx build-Linux-i386 -x Local exim-4.43.vanilla/src/drtables.c
exim-4.43/src/drtables.c --- exim-4.43.vanilla/src/drtables.c 2004-10-05
12:32:08.000000000 +0400 +++ exim-4.43/src/drtables.c 2004-12-09
15:47:14.000000000 +0300 @@ -515,6 +515,10 @@ set to NULL for those that
are not compi

> \#include "auths/spa.h" \#endif

+\#ifdef AUTH\_DOVECOT +\#include "auths/dovecot.h" +\#endif +

> auth\_info auths\_available[] = {
>
> Checking by an expansion condition on plain text

@@ -571,6 +575,18 @@ auth\_info auths\_available[] = {

> },
>
> \#endif

+\#ifdef AUTH\_DOVECOT + { + US"dovecot", lookup name +
auth\_dovecot\_options, + &auth\_dovecot\_options\_count, +
&auth\_dovecot\_option\_defaults, +
sizeof(auth\_dovecot\_options\_block), + auth\_dovecot\_init, init
function + auth\_dovecot\_server, server function + }, +\#endif +

> { US"", NULL, NULL, NULL, 0, NULL, NULL, NULL } };

diff -urdpNx build-Linux-i386 -x Local exim-4.43.vanilla/src/EDITME
exim-4.43/src/EDITME --- exim-4.43.vanilla/src/EDITME 2004-10-05
12:32:08.000000000 +0400 +++ exim-4.43/src/EDITME 2004-12-09
16:00:00.000000000 +0300 @@ -410,6 +410,7 @@ FIXED\_NEVER\_USERS=root

> \# AUTH\_CYRUS\_SASL=yes \# AUTH\_PLAINTEXT=yes \# AUTH\_SPA=yes

+\# AUTH\_DOVECOT=yes

> \#

* * * * *

> diff -urdpNx build-Linux-i386 -x Local exim-4.43.vanilla/src/exim.c
> exim-4.43/src/exim.c --- exim-4.43.vanilla/src/exim.c 2004-10-05
> 12:32:08.000000000 +0400 +++ exim-4.43/src/exim.c 2004-12-09
> 15:38:46.000000000 +0300 @@ -895,6 +895,10 @@ fprintf(f,
> "Authenticators:");
>
> > \#ifdef AUTH\_SPA
> >
> > > fprintf(f, " spa");
> >
> > \#endif

+\#ifdef AUTH\_DOVECOT + fprintf(f, " dovecot"); +\#endif +

> fprintf(f, "n");
>
> fprintf(f, "Routers:");

}}}
