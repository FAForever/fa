# fa-lua-addon

A [lua-language-server](https://github.com/LuaLS/lua-language-server) workspace plugin that
teaches LuaLS to read Supreme Commander: Forged Alliance's Lua dialect. SupCom actually runs a
GPG-modified **Lua 5.0** - confirmed by [FAForever/lua-lang](https://github.com/FAForever/lua-lang),
a buildable reference implementation of it - and that modified dialect bends the language in
several ways: a preprocessor comment marker, table-size hints, an OOP call convention, an
implicit module system - none of it valid standard Lua. This addon rewrites each quirk into
something LuaLS already understands, in the source text, before the real parser ever sees it.
It's a from-scratch replacement for the outdated
[FAForever/fa-lua-language-server](https://github.com/FAForever/fa-lua-language-server) fork,
built as a plugin against mainline LuaLS instead of a fork of it.

The addon still configures `Lua.runtime.version = 'Lua 5.1'`, not 5.0: LuaLS doesn't support a
5.0 runtime at all, and 5.1 is both the earliest version it does support and the closest one to
SupCom's actual dialect.

## Setup

Point a workspace's `.vscode/settings.json` at `plugin.lua`:

```json
"Lua.runtime.plugin": "../fa-lua-addon/plugin.lua",
"Lua.language.fixIndent": false
```

`Lua.language.fixIndent` must be off: LuaLS computes that feature's edits against the
plugin-rewritten text but applies them to the original, so with this plugin it occasionally
deletes real code on the line where Enter was pressed. `config.lua` sets it too, but only if
LuaLS applies third-party configs in your workspace (`Lua.workspace.checkThirdParty`), so set it
explicitly.

`config.lua` is picked up automatically by LuaLS's third-party config system for any matching
workspace - no separate wiring needed.

## How it works

`plugin.lua` runs a chain of scanners over every file's text and merges their results into one
diff list for LuaLS to parse instead of the raw source. Each scanner is a single-purpose module;
its own file header explains the specific problem it solves and why, in more depth than fits
here.

| File | Solves |
|---|---|
| `lexer.lua` | shared tokenizer every scanner reads (comments, strings, `#` comments, numbers) |
| `hash-comments.lua` | `#` as a whole-line comment marker |
| `table-hints.lua` | `{&N &N}` table-preallocation hints |
| `class-support.lua` | `Class()`-family OOP sugar: strips the wrapper so LuaLS sees the spec table |
| `for-in-pairs.lua` | untyped bare-table `for` loops |
| `export-env.lua` | FA's implicit module system: scope-aware rewrite of a file's free names into a module table |
| `hook-files.lua` | SupCom mod "hook" file target detection |
| `config.lua` | workspace settings: non-standard tokens, engine globals, require/path conventions |
| `plugin.lua` | orchestrates the above, merges their diffs, resolves `import()` paths, keeps hook merges current |

## What belongs in the FA source instead

The addon only handles what annotations can't. Anything LuaLS gets right once the source is
annotated is left to the source:

- **Class docs.** Write `---@class Name: Base1, Base2` above `Name = Class(Base1, Base2) {...}`.
  For a class or state nested in another class's spec table, use FA's `Owner_Field` naming
  (`---@class DefaultProjectileWeapon_IdleState: State`). The addon strips the `Class(...)`
  wrapper (LuaLS can't see a spec table through the call), but doesn't invent docs; a class
  without one still gets its fields, but no named type or inheritance.
- **Global files.** A file loaded into the global environment with `doscript` (globalInit.lua,
  simInit.lua and the files they load) defines real globals, not module exports. Mark it with
  `---@declare-global` so `export-env.lua` leaves it alone.

## Design constraints

This is a set of token scanners, not a real parser - each one documents its own known
false-positive/false-negative edge cases and the reasoning behind them. `export-env.lua` tracks
real block scopes (locals, parameters, loop variables), so a name is only rewritten where nothing
shadows it. Behaviour changes are checked by running the transform over the whole FA source tree
and parsing every result.
