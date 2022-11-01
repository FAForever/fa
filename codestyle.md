# Code Style

Code is read much more often than it is written, so code should be written in a manner that is easy to read. As such, code should be "self-documenting" as much as possible, and supplemented with comments to explain more complex processes (Note that, in general, complex code is more likely to be incorrect, inefficient, and thus be rewritten in the future because it is harder to understand, debug, and reason about).

Always [annotate](annotation.md) your code. If you are dealing with UI text, also familiarize yourself with the [localization guidelines](loc/guidelines.md).

When in doubt, follow Lua best-practices such as [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide)

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

The general idea is that logic flow travels top to bottom in the file

## Imports

Imports should be grouped as follows and sorted alphabetically:
  - File imports
  - Class imports
  - Method imports
  - Function imports
  - Upvaling of global variables

Imports locations should be entirely lowercase for efficiency.

If an import is deemed no longer necessary, move it to the end of the file instead of deleting it for mod compatibility.

## Naming

  - In general, a name should be about as long as it gets used: names in larger scopes or lower nesting structures will be more descriptive than those in local, smaller, deeply nested scopes.
    - for-loops have a tradition of using single-letter names for their iterators. If this becomes confusing after several nestings of for-loops, you may be trying to do too much with them. Consider breaking them down into smaller chunks.
  - Variables and parameters should be in lower **camelCase**
    - For variables (but not parameters) that get used in another function within their scope: use **PascalCase** to indicate that they outlive that function and are more expensive to manipulate (being upvalues, not local variables).
  - Functions, methods, and classes should be in **PascalCase**
    - Note that this distinguishes them from library functions and modules that are all lowercase. This is a good thing.
  - Class fields are more vague. In general:
    - In Sim code, fields tend to be `PascalCase`
    - In UI code, components to be `_lowercase` (prefixed by that underscore) and attributes tend to be lower `camelCase` 
  - Use `_` iff the variable is syntactically required, but unused
  - Apps Hungarian notation can be used (where names are prefixed by the *kind* of data they hold or its intention). Systems Hungarian notation (where names are prefixed by their data type) is strictly banned.

## Spacing

  - Use 4 (four) spaces for indentation, *not* 2 spaces, *not* the tab character
    - If you find this eats up a lot of space for deeply nested code, *wonderful*. It is discouraged: deeply nested code is hard to read and likely means that the function is doing more than one thing. Break up such code into smaller segments.
  - Aim for a maximum line width of 100 characters (up to column 101 in your text editor), but longer is okay for code (especially if breaking up the line would disproportionately decrease readability)
  - To break up long lines, indent twice on the next line
    - Prefer to place line breaks *before* operators and after commas and the period in table accesses
  - Extra long lines can locally spaced like a separate scope with different indentation blocks
    - Prefer to place line breaks *after* operators, commas, and the period in table accesses
    - Prefer to place new blocks to group subexpressions based on operator precedence
    - Additional spaces can be placed to increase readability based on alignment and vertical spacing 
  - If statements should always be block indented unless it is part of an idiom such as fail-fast returning or loop breaking
  - Functions should usually be block indented unless they are empty or a short single-line return

### Locally spaced indentation block example
```lua
if  var1 > minimum and var1  < maximum or
    var2 > minimum and var45 < maximum or (
        a == 1 and b == 2 or c == 3
) then
    -- do something
end
```

## Literals

  - Always precede decimals with a number. No hanging decimals points like `.1`.
  - Prefer double-quote strings to single-quote ones to increase recognizability
    - You are encouraged to use single quotes to enclose strings that represent a single character. In particular, this helps differentiate `""`, `' '`, and `"  "` at a glance. Note that `'\t'` is a single character.
    - Single-quote strings are fine when used to embed double-quote characters more easily in the string without escaping them

## Tables

  - One-line table constructors should not have spaces padding the insides of the braces and no trailing field separator
    - Empty tables look like `{}` with no spaces as well
  - Multi-line table constructors should format their braces as an indentation block and have a trailing field separator
  - The preferred field separator is `,` after non-function values and `;` after functions

## Syntax

  - The deprecated usage (by Lua 5.0) of not using an iterator like `pairs` or `ipairs` in a foreach loop is extensive in the codebase. New foreach loops should explicitly use an iterator to document usage.
    - Note that a ranged for-loop may be better suited than `ipairs` if the range is known beforehand
  - Function calls without parentheses should have a space separating it and the following string or table constructor
  - Daisy-chaining using colon-style method calling should be indented on a newline after the colon for each chain call
  - Table access in the form `a.b` is preferred over `a["b"]`
  - Use `local function fn()` or `function fn()` instead of `local fn = function()` or `fn = function()`
  - Moho accepts lines starting with `#` as comments; avoid this

## Classes

  - *Annotate every class*
  - For "fa-classes", the `Class` function is used:
    - Use the form `ClassName = Class(Base) {...}` only when you have class bases
    - Otherwise, use `ClassName = ClassSimple {...}`
    - Each method is defined in the class specification *before* being passed to the `Class` function
      - In particular, adding methods afterwards like `function ClassName:Method()` is discouraged for these 
  - For manual classes, the class metatable is directly handled (see prototype at the end of the section)
  - FA classes are preferred to manual classes
  - In either one, the following member order is observed:
    - class fields
    - `__init` - or the equivalent creation function for a manual class
    - `__postinit`
    - Getter & Setter pairs
    - Main interfacing methods, grouped by aspect
    - Helper methods

### Manual class prototype
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

# Specifics

  - Put a newline after functions that correspond to coroutine yielding such as `WaitSeconds`: this makes the break in logic flow visually apparent
