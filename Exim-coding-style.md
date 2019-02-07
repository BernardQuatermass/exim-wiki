Preferred C coding style, in order to match that used in most of the rest of the project:

- C89 standard 'C' with limited C99 later features listed here:
    - designated initializers, for struct/union/array elements.  Use whereever possible.
    - loop-variable declared in "for"
- variables
    - No non-block-head variable declarations (except as already permitted)
    - generally, declare in the smallest scope possible
    - Use the "uschar" type for chars
    - Use the BOOL type for general booleans
- 2-space indent, 8-space hard tabs
- 80-char line max.  Continuation lines indented
- Code-block braces align vertically and are indented
- Toplevel code in functions is zero-indented
- In conditions
    - use boolean variables directly - do not compare against TRUE or FALSE.
    - test pointers for (non)NULL by treating as boolean
    - complex conditionals have subclases vertically aligned and indented
    - assignments used also as conditionals are encouraged where it makes code tighter, but must be parethesized
- if-else has the else aligned with the if
- Inline block comments
    - blankline-separated from code
    - generally describe reasoning for subsequent code
    - align with code and do not put asterix on continuation lines.
- Block comments on functions
    - left-aligned
    - describe purpose of function
    - list arguments with purpose, and describe return value
- Functions
    - return type on separate line
    - use "static" return type wherever possible
    - functions written purely to make codeflow more clear are permissable, even if used only once
- Use the project memory-allocation methods, not direct malloc
- Use the project string-manipulation facilities

Note that these are guidelines only, and variation is permissable when there is specific reason.