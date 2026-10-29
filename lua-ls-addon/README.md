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
"Lua.runtime.plugin": "../fa-lua-addon/plugin.lua"
```

`config.lua` is picked up automatically by LuaLS's third-party config system for any matching
workspace - no separate wiring needed.

## How it works

`plugin.lua` runs a chain of scanners over every file's text and merges their results into one
diff list for LuaLS to parse instead of the raw source. Each scanner is a single-purpose module;
its own file header explains the specific problem it solves and why, in more depth than fits
here.

| File | Solves |
|---|---|
| `hash-comments.lua` | `#` as a comment marker |
| `table-hints.lua` | `{&N &N}` table-preallocation hints |
| `class-support.lua` | `Class()`-family OOP sugar |
| `for-in-pairs.lua` | untyped bare-table `for` loops |
| `export-env.lua` | FA's implicit module system (bare top-level exports, forward references) |
| `hook-files.lua` | SupCom mod "hook" file target detection |
| `config.lua` | workspace settings: non-standard tokens, engine globals, require/path conventions |
| `plugin.lua` | orchestrates the above, and safely merges their diffs |

## Design constraints

This is a set of heuristic text scanners, not a real parser - each one documents its own known
false-positive/false-negative edge cases and the reasoning behind them. Where a rewrite carries
real risk (e.g. `export-env.lua`'s reference rewriting under name shadowing), the trade-off is
verified against the full FA source tree and documented in that file, not just asserted.
