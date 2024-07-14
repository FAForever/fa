---
layout: page
nav_order: 3
title: Lua version and syntax
parent: Development - Start here
permalink: development/start-here/lua-syntax
---

# Lua

[Lua](https://www.lua.org/) is a programming language that can be embedded in software. There are many different versions of Lua both in terms of syntax and in whether the Lua code is interpret or (just in time) compiled. In Supreme Commander: Forged Alliance we have LuaPlus version 5.01 with build number 1081 from February 2024. This is not to be confused with [Lua++](https://docs.luaplusplus.org/). This version of Lua is an interpreter. Often the byte code is almost a one-to-one representation of interpret Lua code.

## Lua syntax

In general the following list is valid syntax in LuaPlus. You're not encouraged to use them however. Using them may be confusing to other developers. And all files that use this syntax is incompatible with external tools that may perform some form of postprocessing.

- The operator `^` is the bit-wise XOR operator and **not** the typical power operator, which is `math.pow`.
- The operator `|` is the bit-wise OR operator.
- The operator `&` is the bit-wise AND operator.
- The operators `>>` and `<<` are the bit-wise shift operators.
- The operator `!=` is an alternative to `~=` to check for inequality.
- The syntax `#` is an alternative to `--` for creating comments.

One useful exception is the following statement.

- The statement `continue` exists, which works like you'd expect in other languages with the `continue` keyword.

And another useful exception is the following syntax:

- The `{h&a&}` is new syntax to create a table with a pre-allocated hash and array sections. The value `h` pre-allocates `math.pow(2, h)` entries in the hash section of a table. The value `a` pre-allocates `a` entries in the array section of a table. 

It is for example applied in [#4539](https://github.com/FAForever/fa/issues/4539) to significantly improve the performance of the game.

## Lua modules

Due to safety concerns various modules and/or functions that are part of the default Lua library are not available. This primarily applies to the entire `io` and `os` modules, which is only available during the initialisation phase of the game. [Interfacing with a C package](https://www.lua.org/pil/8.2.html) is also not available. In general anything that would provide access outside of the sandbox of the game is not available. There are some alternatives such as `DiskFindFiles` and `DiskGetFileInfo` that provide basic access to files that are made accessible during the initialisation phase of the game.

## Tips and tricks

In general the white paper '[The Implementation of Lua 5.0](https://www.lua.org/doc/jucs05.pdf)' is a great introduction on understanding the Lua interpreter of Supreme Commander: Forged Alliance. 