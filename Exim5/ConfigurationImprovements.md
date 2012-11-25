Configuration file improvements
===============================

Arguments in macros
-------------------

Macros could be made more function-like, so that they can accept
arguments (in a similar manner that C allows macros with arguments).
That would make the config files a lot cleaner in some sophisticated
lookup and condition scenarios. Today, to make a argumented macro, I
must make two macros, eg.:

    MACRO_START = ${some lookup or something: /base/path/to/
    MACRO_END = .db}

And the macro usage looks like:

    MACRO_STARTdirectory/filenameMACRO_END

That's both hard to read and unconvenient to use (what if one wants the
filename to appear twice in the macro?).

I'd suggest something like:

    MACRO(x,y) = ${some lookup: /base/path/to/%x%/%y%.db}

With usage scenario:

    MACRO(directory,filename)

That makes variables inside '%' (just a suggestion, sure they need to be
escapable) behave in a special manner. It can easily be assumed that
macro definitions and usage could not contain spaces inside these
parentheses, to make parsing easier and less human error prone. To avoid
confusion, macro definitions can be made more explicit. Again, taking C
as an example, I'd go for:

    .define MACRO something

Exim already is using ".if" etc. as preprocessing keywords.

Replace with Lua
----------------

I think we should consider the idea of replacing the complete
configuration set with an embeddable scripting language used for both
control and configuration. This would allow greater flexibility and
probably improve consistancy (if done right). It is a major change, but
I think worth investigating.

A good potential candidate for this would be [Lua](http://www.lua.org/)
which is used as a configuration language. However a lot of preparatory
investigation work would need doing. -- NigelMetheringham\_
\`[[DateTime(2007-02-27T13:35:13Z)]]\`\_
