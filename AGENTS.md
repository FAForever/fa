# Forged Alliance Forever — Game Code

This repository is the Lua game code (plus blueprints, effects, textures, localization) for [FAF](https://www.faforever.com/), the community continuation of *Supreme Commander: Forged Alliance*. The C++ engine is closed-source. There is no build step: the game loads these files from archives or straight from disk.

## Where to look

Read the guide for a folder before working in it.

| Path | Contents | Guide |
|---|---|---|
| `lua/sim/` | Simulation: units, weapons, projectiles, buffs, damage, navigation. Sim files outside it too | [lua/sim/AGENTS.md](lua/sim/AGENTS.md) |
| `lua/ui/` | All UI. `lua/maui/` has the primitives it builds on | [lua/ui/AGENTS.md](lua/ui/AGENTS.md), chat: [lua/ui/game/chat/AGENTS.md](lua/ui/game/chat/AGENTS.md) |
| `lua/system/` | Runtime: `import`, classes, blueprint loading, `config.lua` | [lua/system/AGENTS.md](lua/system/AGENTS.md): Lua states, entry points, module scope, globals |
| `lua/` (top level) | Faction class libraries, `defaultunits.lua`, effects, scenario framework, AI brain, sync | [lua/sim/AGENTS.md](lua/sim/AGENTS.md) |
| `lua/AI/`, `lua/aibrains/` | AI | |
| `units/<ID>/` | Unit blueprints and scripts | [units/AGENTS.md](units/AGENTS.md). Unit IDs by name, tech and role: [units/unit-names.md](units/unit-names.md) |
| `engine/` | Annotation-only stubs of engine globals and `moho.*` classes. Never loaded | [engine/AGENTS.md](engine/AGENTS.md) |
| `projectiles/`, `effects/`, `env/`, `meshes/`, `textures/` | Assets FAF adds or changes | |
| `loc/<LANG>/` | Localization. Use `<LOC key>fallback` in user-facing text | |
| `schook/` | Empty placeholders that blank out base game hooks. Edit the file under `lua/` instead | |
| `changelog/snippets/`, `docs/` | Changelog snippets, dev docs site | |

Applies everywhere: [annotation.md](annotation.md) (annotation and comment style), [performance.md](performance.md) (hot paths in sim and UI), [in-game-testing.md](in-game-testing.md) (test procedures), [CONTRIBUTING.md](CONTRIBUTING.md) (PR process).

## Lua dialect

GPG-modified **LuaPlus 5.0**, not 5.1+. [Details](docs/development-start-here/lua-syntax.md).

- `^` is bitwise XOR; use `math.pow`. `|`, `&`, `<<`, `>>` are bitwise.
- `#` starts a comment, so there is no `#t`. Use `table.getn` / `table.getsize`. Varargs use `arg` (`arg.n`).
- `!=` works as `~=`. Avoid it and `#` comments in new code. `continue` works in loops.
- `{&h &a}` pre-allocates hash and array slots ([performance.md](performance.md#allocations)).
- **Indexing `nil` returns `nil`.** `t.a.b` is `nil` when `t.a` is missing, and the repo relies on this. Don't add `and` guards or treat such chains as bugs. Calling `nil` and `t[nil] = v` still error.
- `io` and `os` exist only in the init context. No `require` or C modules.

### Runtime changes to Lua behavior

[lua/system/config.lua](lua/system/config.lua) changes how code fails, in every state ([details](lua/system/AGENTS.md#runtime-changes-to-lua-behavior)):

- Reading an undefined global errors. Probe optional globals and context-specific engine functions with `rawget(_G, "Name")`.
- Setting a field on `nil`, a boolean, number, string or thread errors.
- `math.random` is the engine's `Random`, which is sim-safe.
- `EmptyTable` is a shared global: never write to it or `setmetatable` it, and return a fresh `{}` when the caller may modify the result ([details](lua/system/AGENTS.md#emptytable)).

## Modules and imports

- `import("/lua/path/file.lua")` with absolute paths. The filesystem is case-insensitive, but lower-case is preferred.
- Top-level assignments in an imported file are module fields, not globals. Use `import` and module scope in new code. Add a state global only when every file in that state needs it ([details](lua/system/AGENTS.md#module-scope-vs-lua-state-globals)).
- Don't use `lazyimport`: hot reload skips its importers, and it breaks mod hooks ([#4484](https://github.com/FAForever/fa/pull/4484), [#4612](https://github.com/FAForever/fa/pull/4612)).

## Lua contexts

The init, blueprint loading, main menu UI, session UI and sim states are isolated: code in one can't see the others' globals. Engine functions are declared per context in `engine/` (`Core.lua` shared, `Sim.lua`, `User.lua`). Entry points and init files: [lua/system/AGENTS.md](lua/system/AGENTS.md#lua-contexts).

### Determinism and desyncs

**The sim runs in lockstep on every client.** Anything in sim code that differs between clients desyncs the game.

- UI → sim: [lua/SimCallbacks.lua](lua/SimCallbacks.lua). Validate every argument: callbacks are player input and can be forged.
- Sim → UI: the `Sync` table ([lua/SimSync.lua](lua/SimSync.lua) → [lua/UserSync.lua](lua/UserSync.lua)).
- `GetFocusArmy()`, `DebugGetSelection()`, `SelectedUnit()` and `GetSystemTimeSecondsOnlyForProfileUse()` differ per client. Use them only to pick what to send to the local UI.
- `pairs`/`next` order over table, function or userdata keys (units) differs between clients. Key entity tables by `entity.EntityId`.

Debugging one: [lua/system/AGENTS.md](lua/system/AGENTS.md#debugging-a-desync).

## Classes

Use the typed constructors from [lua/system/class.lua](lua/system/class.lua) (`ClassUnit`, `ClassWeapon`, `ClassProjectile`, `ClassShield`, `ClassUI`, `ClassSimple`, …), not plain `Class`. Call base methods explicitly (`Base.Method(self, ...)`); there is no `super`. Put per-instance threads, emitters and entities in `self.Trash`. Unit scripts set `TypeClass`.

## Blueprints

`*.bp` files are Lua table constructors, post-processed at load by [lua/system/Blueprints.lua](lua/system/Blueprints.lua). Read them through `self.Blueprint` or `__blueprints[id]`, and never mutate one at runtime: every instance shares it.

## Performance

Large games run thousands of units, and UI code often runs every frame. Upvalue globals and methods at file scope, loop arrays with a numeric `for`, and avoid allocations and category expressions in hot paths. Read [performance.md](performance.md) before writing or changing a hot path.

## Code style

- Annotate everything new ([annotation.md](annotation.md)): a `---` description, typed `@param`/`@return`, `---@field` for every class field.
- Comments: declarative, succinct, no period at the end, no em-dashes.
- 4-space indentation. Match the surrounding code, and don't reformat code you aren't changing.

## Testing and verification

The tests need the FAF Lua interpreter ([FAForever/lua-lang](https://github.com/FAForever/lua-lang)); standard Lua won't parse this code.

```bash
bash ./tests/run-syntax-test.sh      # luac -p over .lua and .bp files
bash ./tests/run-utility-tests.sh    # tests/utility/*.spec.lua
bash ./tests/run-blueprint-tests.sh  # sanity checks on units/*/*.bp
```

Files using `{&h &a}` must be added to the skip list in `run-syntax-test.sh`.

Real verification means running the game ([setup](docs/development/setup.md)): copy `setup/bin/init_local_development.lua` into the FAF client's `bin` folder, set `locationOfRepository`, and launch `ForgedAlliance.exe /init "init_local_development.lua" /EnableDiskWatch /showlog /nomovie`. Check the moho log for Lua errors. When you can't run the game, say so and write a test procedure following [in-game-testing.md](in-game-testing.md).

## Branches, PRs, changelog

- PRs target **`develop`**. Commit subjects: imperative, under 80 characters, no trailing period.
- Keep refactors and each functional change in separate commits or PRs, and propose commits to the user that way.
- Every PR needs `changelog/snippets/<category>.<PR number>.md`, written for players. Categories: `graphics`, `ai`, `performance`, `balance`, `features`, `fix`, `other` ([details](docs/development-changelog.md)).
- Balance changes need balance team sign-off, and features need discussion first ([CONTRIBUTING.md](CONTRIBUTING.md)).
- Force-pushing shared branches, including the `staging/*` test deploys ([in-game-testing.md](in-game-testing.md#testing-in-live-games)), only when the user asks.

## Gotchas

- Mods and [co-op](https://github.com/FAForever/fa-coop) hook these files. Renaming or removing a public function, field or module path breaks them silently. Prefer adding, and keep `---@deprecated` aliases when renaming.
- **Not every asset is in the repo.** The base game's `units.scd`, `textures.scd` and other archives are still mounted (`allowedAssetsScd` in [init_faf.lua](init_faf.lua)). A path with no file here usually comes from them. Don't "fix" or delete it.
- If a function isn't in `engine/`, it doesn't exist. Don't assume a convenient one does.
- **[faf-re](https://github.com/Draiget/faf-re)** is an incomplete decompilation of the engine. Use it only as a last resort, when the stubs and docs are missing details or contradict observed results. Its code is evidence, not proof. Say so when a conclusion depends on it.
