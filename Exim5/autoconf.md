Somebody once tried to autoconf Exim, but found it too big a job. I now
have some experience with using autoconf for PCRE, and I think maybe
some use could be made of it. I don't, however, believe that all Exim
build-time configuration should be done that way. The reason is that,
unlike something like PCRE, there is quite a lot of information that is
just a user choice. Giving it all as options to a ./configure command
does not seem the best way of doing things.

Whenever I build something that needs more than a couple of obvious
options to ./configure, I always save them in a file anyway, so I know
what I did for next time. Therefore, I think it is sensible to retain
the current Local file structure for all the user choice configuration.

However, it might be helpful to use autoconf to dig out various bits of
information about the operating system. At present, the OS/Makefile-\*
files have hard-wired settings, and maybe this information could be
figured out by running autoconf, which would save having to keep
maintaining these files.

I would arrange things so that ./configure is run automatically the
first time that "make" is run, but it would be possible to run it
manually first, to override defaults. (For example, if you have both cc
and gcc installed on your system, you need to be able to specify which
to use.)

Just another proposal: Wouldn't it be sensible to use something less
painful than autoconf/automake? Some other projects seem to be happy
with e. g. [cmake](http://www.cmake.org/).
