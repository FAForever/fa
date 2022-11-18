
# Code Style Overview

Code is read much more often than it is written, so code should be written in a manner that is easy to read.
As such, code should be "self-documenting" as much as possible, and supplemented with comments to explain more complex processes.
(Note that, in general, complex code is more likely to be incorrect, inefficient, and thus be rewritten in the future because it is harder to understand, debug, and reason about.)

These guidelines are to ensure consistence across the codebase and are formed based on concerns of readability, performance, and existing style.

Always [annotate](annotation.md) your code.
If you are dealing with UI text, also familiarize yourself with the [localization guidelines](loc/guidelines.md).

When in doubt, follow the style of code in the project known to be well-styled, or other Lua best-practices such as [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide).
Consistency is more important than "being correct", or readability as perceived by any one individual.

## General File Structure

- Header, copyright, and description
- Annotation structures that aren't inline
- Imports
- Local variables
- "Interfacing" functions that get called outside the file
- Classes
- Global functions
- Local functions
- Module maintenance

The general idea is that logic flow travels top to bottom in the file.
The exception is local functions, which must be declared before they are used.
In particular, helper functions of another should appear just before the function they are helping

### The header

The header has the form

```lua
--******************************************************************************
--** <license>
--******************************************************************************

-- a short summary of the file, if applicable
-- ...
```

This is where the license that lets Forged Alliance Forever use your contribution goes and how you will be attributed.
Future contributors to this file will be added here.

### In-file grouping

A file can be grouped into logical subcomponents and aspects by inserting a comment heading in the form

```lua
 
----------
-- lowest level heading
----------
```

Note the preceding newline.
To form higher-level headings, precede with another newline and add 10 more dashes `----------` to the box.
Also consider a transition from `lower case` to `Sentence case` to `Title Case` or using three dashes `---` in the middle name for these.

### Imports

Imports should be grouped as follows and sorted alphabetically:
- File imports
- Class imports
- Method imports
- Function imports
- Upvaling of global variables

Imports locations are entirely lowercase and non-relative, meaning they begin with a baskslash `/`.
Always use parentheses `()`, for consistency with class imports that require them.

If an import is deemed no longer necessary, move it to the end of the file with the rest of the module maintenance logic instead of deleting it.
This maintains mod compatibility.

# Spacing

Aim for a maximum line width of 100 characters (up to the start of column 101 in your text editor)
- Try to make this a hard rule in comments
- Slightly longer is okay for code, especially if breaking up the line would disproportionately decrease readability

## Whitespace

Whitespace in code should be condensed to a single space, except for:
- Leading whitespace in indentation
- Separating statements on the same line; prefer two spaces <code>  </code> for this task
- Spaces inserted to align similar code to read better vertically (such as is common in assignments)

### Where to not insert whitespace

- Trailing at the end of lines in code (but is okay in comments for markdown support)
- Between function names and their following openning parenthesis `(` (both for declarations and calls)

### Where to insert a space

- Between all operators (but not separators) and their argument(s), as well as in assignment
- After all commas not at the end of a line
    * In particular, *always* separate function parameters with a space
- Anywhere that otherwise improves readability.
Further guidance is subject to community consensus.

## Newlines

- To break up long lines, start a new line and indent twice relative to the current indentation level (so that it doesn't get mistaken for starting a new scope)
    * Prefer to place line breaks *before* operators (with higher preference at lower precedence) and the period in table accesses and *after* commas
- Especially long lines can utilize **locally spaced indentation blocks** as though they describe a new scope
    * Prefer to place line breaks *before* the period in table accesses and *after* operators (with higher preference at lower precedence) and commas
    * Prefer to group indentation blocks by paired delimiters such as `{}`, `[]`, or `()`

### Where to not insert newlines

- Do not put a blank line after function declarations
- Do not break up the code with superfluous newlines unless they serve to group similar statements

### Where to insert newlines

- Place blank lines between functions, classes, and groups of imports or variable declarations
    * More than one blank line can be used to group such items into further logical groups (such as for the general file structure described above)
    * You may elect to not put blank lines between functions that are there purely for another function, e.g. local helpers functions to a global one or the thread function of its instantiator
- After logical breaks in code, e.g. to separate the setup, working, and cleanup code of a function

## Indentation

- Use 4 (four) spaces for indentation, *not* 2 spaces, *not* the tab character
    * If you find this eats up a lot of space for deeply nested code, *wonderful*.
That is discouraged: deeply nested code is hard to read and likely means that the function is doing more than one thing.
Consider breaking up such code into smaller segments.
- Indent each enclosed scope or mutli-line table constructor  
- For **locally spaced indentation blocks**
    * Prefer to place line breaks *after* operators, commas, and the period in table accesses
    * Prefer to place new blocks to group subexpressions based on operator precedence
    * Additional spaces can be placed to increase readability based on alignment and vertical spacing
 - If statements should always be block-indented unless it is part of an idiom such as fail-fast returning or loop breaking
 - Functions should be block-indented unless they are empty or a short single-line return

### Locally spaced indentation block examples

```lua
if  var1 > minimum and var1  < maximum or
    var2 > minimum and var45 < maximum or (
        a == 1 and b == 2 or c == 3
) then
    -- do something
end
```

```lua
if var1 == 5
    and var2 == 1
    and var4 == 9
    and var99 = 3902
then
    -- do something
end
```

# Lexis

## Naming

In general, a name should be about as long as it gets used: names in larger scopes or lower nesting structures will be more descriptive than those in local, smaller, deeply nested scopes.
* for-loops have a tradition of using single-letter names for their iterators; we encourage more descriptive names, but it's fine if you don't (until it becomes a mess of one-letter names when you get 3 for-loops deep)
If this becomes confusing after several nestings of for-loops, you may be trying to do too much with them.
Consider breaking them down into smaller chunks.

### Variables and parameters

Are in lower `camelCase` or `snake_case` (which has been shown to increase readability of the name, but it also makes lines longer - which decreases overall readability)
- For variables (but not parameters) that get used in another function within their scope: use `PascalCase` to indicate that they outlive that function and are more expensive to manipulate (being upvalues, not local variables)
- Use the same convention throughout the file
- Use `_` iff the variable is syntactically required, but unused
- Apps Hungarian notation can be used (where names are prefixed by the *kind* of data they hold or its intention).
Systems Hungarian notation (where names are prefixed by their data type) is strictly banned.
- Function declarations intended as methods should use `self` for the instance name

### Functions, methods, and classes

Are in `PascalCase`
* Note that this distinguishes them from library functions and modules which are all lowercase. This is a good thing.

### Class fields

Are more vague. Generally:
- In Sim code, fields tend to be `PascalCase`
- In UI code
    * object attributes tend to be lower `camelCase`
    * UI components or other "private" data not meant to used outside of the file tend to be `_lowercase` (prefixed by that underscore `_`, and may or may not also be in `_snake_case`)
- As usual, metafields (and only metafields) are prefixed by two underscores `__`

## Literals

- Always precede decimals with a number. No hanging decimal points like `.1`.
- Prefer double-quote strings to single-quote ones to increase recognizability
    * Single-quote strings are fine when used to embed double-quote characters more easily in the string by not having to escaping them
    * You are encouraged to use single quotes to enclose strings that represent a single character
        * In particular, this helps differentiate `""`, `' '`, and `"  "` at a glance
        * Note that `'\t'` is a single character

# Syntax

- The deprecated usage (by Lua 5.0) of not using an iterator like `pairs` or `ipairs` in a foreach loop is extensive in the codebase.
Newly written foreach loops should explicitly use an iterator to document intention.
    * Note that a ranged for-loop may be better suited than `ipairs` if the range is known beforehand
- Moho accepts lines starting with `#` as comments; avoid this

## Empty statements

- No superfluous semicolons `;` at the end of lines
    * Use redundant semicolons to disambiguate potential function calls.
These go at the beginning of the statement.
    * There may be occasions where it increases readability to have more than one statement on a line; separate these with a semicolon and two spaces `;  `
    * Note that field separators that happen to be semicolons are syntaxically different objects than the empty statement

## Functions

- Use `local function fn()` or `function fn()` instead of `local fn = function()` or `fn = function()`
- Function calls without parentheses should have a space separating it and the following string or table constructor such as `sort_by "name"` or `Class {}`
- Colon-style daisy-chaining should be indented on a newline *before* the colon for each chain call
    
    ```lua
    local control = LayoutFor(NewControl(a, b, c))
        :Fill(parent)
        :AtLeftIn(sibling)
        :End()
    ```

## Tables

- Table access in the form `table.key` is preferred over `table["key"]`
    * Prefer to be consist in enumeration-like code however.
This means that if you need to use `table["key with spaces"]`, similar items that counterpart it should do the same, even if `table.key` would suffice for them.
- Place all unkeyed values before all key-value pairs and separate with a newline. Never interlace them.
- The preferred field separator is a comma `,`
    * A semicolon `;` may be used after the final unkeyed value to signal the start of key-value pairs

### One-line table constructors

- Prefer for array-like tables
- Do not add spaces padding the insides of the braces like ~~`{ 1 }`~~
    * Empty tables look like `{}` with no spaces
- Do not add a trailing field separator to the last item

### Multi-line table constructors

- Prefer for dictionary-like tables
- Format as an new indentation block starting immediately after the opening brace `{` and before the closing brace `}`
    * Do not leave any fields after the opening brace, unless these are "pre-fields" that may not make sense to include with the rest of the data (such as a zero index or a few unkeyed values in an otherwise key-value paired table)
- Put each item on a newline (unless it improves readability to do otherwise)
- Leave a trailing field separator after the last item

# Semantics

## Classes

- [***Annotate every class***](annotation.md)
- For "fa-classes", the `Class` function is used:
    * Use the form `ClassName = Class(Base) {...}` only when you have class bases
    * Otherwise, use `ClassName = ClassSimple {...}`
    * Each method is defined in the class specification *before* being passed to the `Class` function
        * In particular, adding methods afterwards like `function ClassName:Method()` is discouraged for these 
- For manual classes, the class metatable is directly handled

    ```lua
    ClassName = {}
    ClassName.__index = ClassName

    function ClassName.New(...)
        local obj = {}
        setmetatable(obj, ClassName)
        ...
        return obj
    end

    function ClassName:Method()
    end
    ```

- FA classes are preferred to manual classes
- In either one, the following member order is observed:
    * default class fields (note that fields are usually set in the initializer)
    * `__init` and `__post_init` - or the equivalent creation function for a manual class
    * Each getter & setter pair
    * Main interfacing methods, grouped by aspect
    * Helper methods

## Library functions

Instead using the `string.<fn>(x, ...)` functions, prefer to use `x:<fn>(...)`.
If `x` is a raw string, you will need to do `(x):<fn>(...)` instead.

# Specifics

- Put a newline after functions that correspond to coroutine yielding such as `WaitSeconds`: this makes the break in logic flow visually apparent
- Reuse table accesses or other repeated code

    ```lua
    local x = a.b.c.d
    if x then
        local y = x
    end
    ```

    not

    ```lua
    if a.b.c.d then
        local y = a.b.c.d
    end
    ```
