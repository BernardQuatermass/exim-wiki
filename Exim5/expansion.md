MagnusHolmgren\_ posted this to the mailing list:

Hello everybody! This is my vision of and suggestion for a reform of the
string expansion language:
-   The distinction between items, operators, and conditions is
    eliminated. Instead there are only functions.
    -   All functions can be used as conditions. The truth value is the
        same as with the "condition" ACL condition and router
        precondition today.
    -   Any punctuation character except \$ can be used as the argument
        delimiter. The character following the function name determines
        the delimiter.
        -   Characters that come in matching pairs - () [] {} \<\> - are
            used together (like in Perl).
        -   Single and double quotes could possibly be used the the same
            way, with single quote turning off expansion.
        -   Space can be the delimiter. If the first nonblank character
            after the function name is not a valid punctuation
            character, then any amount of consecutive whitespace
            separates arguments, except when the function already has
            enough arguments.
        -   In fact, all bracketing delimiters and no delimiters can be
            used interchangeably, so that this is no special case:

                ${if ${match_address $sender_address
                                     ${list:foo@example.com:bar@foo.example}
                     {The address matches}
                     [No match]}
        -   I don't think following nesting of bracketing delimiters
            that do *not* enclose expansion functions or their
            arguments, like Perl does, is worth it, though.
        -   Examples:

                ${substr:3:2:$local_part}
                ${tr/abcdea/ac/13}
    -   The special operators that take arguments separated by
        underscores have to become normal: `${substr:3:2:$local_part}`
-   The list is a special data type. Some expansion functions return
    lists (for example lookup, perl, and list, which is the generic list
    constructor). The colon, or other delimiter, is only used as such in
    the configuration file, not internally. Also, expansions are parsed
    when parsing list settings. This avoids the need to double colons
    inside expansions in e.g. require\_files, as well as
    `${sg{<password>}{:}{::}}` in places where an expansion result might
    contain colons that are not intended as list separators.

    This breaks with the principle that expansions are simple string
    substitutions, but I think it can implemented quite easily by
    passing a list\_context flag to `string_expand_internal()` and
    converting to a string before returning when a list isn't wanted
    (either by simply concatenating the elements, concatenating with
    colons between, or by returning the number of elements (like in
    Perl).

This should give the following advantages:
-   The syntax becomes more coherent.
-   Fewer braces overall.
-   You can say `${eq $foo bar}` instead of `${if eq{$foo}{bar}}` :-).
-   The code becomes simpler, even if there are more ways for the user
    to express the same thing.
-   The current syntax for most expansion items and operators is still
    valid.

But is this too much of a reform? Just how incompatible can the changes
be? Much should be auto-convertable and there were huge changes between
Exim 3 and Exim 4 that required manual attention.
