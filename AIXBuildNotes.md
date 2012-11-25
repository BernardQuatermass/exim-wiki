AIX Build Notes
===============

Originally posted to the exim-users
[EximMailingLists](EximMailingLists) - archived at
[http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20050131/msg00201.html](http://www.exim.org/mail-archives/exim-users/Week-of-Mon-20050131/msg00201.html)
- original author was Mike Meredith

Just a few notes from building Exim (4.44+exiscan) on an AIX (5.3L) box
... in case someone else needs the info, or in case someone spots me
doing something stupid (I'm new to AIX).

1.  Change CC to gcc in OS/Makefile-AIX (no cc installed by default)

2.  Change CFLAGS in OS/Makefile-AIX :-

    1.  Remove -D:underline:\`STR31\` (this may not be necessary but it
        works without)

    2.  Add '-mcpu=power4 -maix64 -O3'

You also need to edit `src/exim.h` and remove the guard around

    #define SOCKLEN_T socklen_t

AIX has `SOCKLAN_T` defined in the standard headers as blank. Yes this
should go in `OS/os-AIX.h`, but the change isn't effective there.

    Note: The changes in OS/Makefile-AIX introduced with Exim 4.50 will break building on AIX 4.3 with at least the cc of /usr/ibmcxx/bin.

* * * * *

> [CategoryHowTo](CategoryHowTo)
