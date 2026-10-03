# Forged Alliance Forever — Game Code

This repository is the Lua game code (plus blueprints, effects, textures, localization) for [FAF](https://www.faforever.com/), the community continuation of *Supreme Commander: Forged Alliance*. The C++ engine is closed-source; this repo is everything the engine loads through its Lua VM. There is no build step: files are packaged into `.nx2`/`.scd` archives at deploy time, or loaded straight from disk during local development.

Folder-specific guides extend this one. Read them when working in those folders:

- [lua/ui/AGENTS.md](lua/ui/AGENTS.md): UI patterns (`__init` vs `__post_init`, LazyVars and `Derive`, `TrashBag`, fluent `Layouter`, skinning, hot reload).
- [lua/ui/game/chat/AGENTS.md](lua/ui/game/chat/AGENTS.md): the MVC chat refactor.
- [annotation.md](annotation.md): annotation and comment style. Applies to all new code.
- [CONTRIBUTING.md](CONTRIBUTING.md): PR process, review, merge conventions.

---

## Lua dialect

The engine runs a GPG-modified **LuaPlus 5.0** (not 5.1+). Things that trip up tooling and assumptions:

- `^` is bitwise XOR. Use `math.pow` for exponentiation. `|`, `&`, `<<`, `>>` are bitwise operators.
- `!=` is accepted as `~=`. `#` starts a comment (like `--`). Avoid both in new code.
- `continue` exists and works inside loops. It is fine to use.
- `{&h &a}` pre-allocates a table (`2^h` hash slots, `a` array slots), e.g. `{&1 &8}`. See [Performance](#performance).
- There is no `#t` length operator (`#` is a comment). Use `table.getn` / `table.getsize`. Varargs use the implicit `arg` table (`arg.n`), not `select('#', ...)`.
- **Indexing `nil` returns `nil` instead of raising an error.** Standard Lua errors here, so this is easy to miss. `local v = t.a.b` is `nil` when `t` or `t.a` is `nil`, and much of the repo relies on this for implicit nil checks in access chains (`if t[1].a then` is safe when `t[1]` is missing). Don't "fix" such chains with extra `and` guards, and don't assume they are bugs. What still errors:
  - Calling `nil` (`t.a.b()` when `b` is missing).
  - Assigning to a `nil` key (`t[nil] = v`). Reading `t[nil]` returns `nil`.
  - Setting a field on `nil` (see [Runtime changes](#runtime-changes-to-lua-behavior)).
- `io` and `os` exist only in the init context. No C modules, no `require` in game code.

Details: [docs/development-start-here/lua-syntax.md](docs/development-start-here/lua-syntax.md).

### Runtime changes to Lua behavior

[lua/system/config.lua](lua/system/config.lua) runs early in every Lua state and changes some default behavior. These change how code fails:

- **Reading an undefined global raises an error** ("access to nonexistent global variable") instead of returning `nil`. Modules see this too, because their environment falls through to `_G`. `if SomeOptionalGlobal then` errors when the global is missing. Probe with `rawget(_G, "SomeOptionalGlobal")` instead, as the init files do for `SetProcessPriority`. The same applies to engine functions that exist in only one context (sim vs. user).
- **Setting a field on `nil`, a boolean, a number or a string raises an error.** Reading a field on `nil` still returns `nil`. Stock LuaPlus allows it, storing the value on the type's shared metatable. Strings are locked at the end of [lua/system/utils.lua](lua/system/utils.lua), after that file adds the extra `string.*` functions.
- **Threads have a metatable.** `thread:Destroy()` calls `KillThread`, which is why threads can go in a `TrashBag`. Setting a field on a thread raises an error, so store thread state on the owning object.
- **`math.random` is replaced by the engine's `Random`.** In the sim, `Random` uses the synchronized RNG, so it is safe for determinism. It follows `Random`'s argument semantics ([engine/Core.lua](engine/Core.lua)), not stock `math.random`'s.
- It defines the global `iscallable(f)`, which returns `f` if it is a function, a C function or a table with a `__call` metamethod.

### `EmptyTable`

[lua/globalInit.lua](lua/globalInit.lua) defines the global `EmptyTable`: a shared empty table whose `__newindex` logs a warning and discards the write. Use it wherever a table is required but has no content, typically as an argument to a C function, to avoid allocating a new `{}`. Lua code may also return it as a "no results" value (e.g. `Unit:GetTerrainTypeEffects`).

Every caller shares the same instance, so:

- Never write to a table that might be `EmptyTable`. Writes are dropped with only a `WARN`, so the bug is easy to miss. `rawset` bypasses the guard and corrupts it for every caller.
- Never call `setmetatable` on it, and never pass it to code that does (e.g. something that turns a table into a class instance).
- If the caller might modify the result, return a fresh `{}` instead.

## Modules and imports

- Load modules with `import("/lua/path/file.lua")` using absolute, lowercase-tolerant virtual paths (the engine's filesystem is case-insensitive). `lazyimport` defers loading until first access. Implementation: [lua/system/import.lua](lua/system/import.lua).
- `local` keeps a variable private to the file.
- Performance-sensitive files cache globals and methods as upvalues at the top of the file. See [Performance](#performance).
- `__moduleinfo.OnDirty` / `OnReload` support hot reload when the game runs with `/EnableDiskWatch`.

### Module scope vs. Lua state globals

`doscript(file, env)` runs `file` with `env` as its environment. Without `env`, it uses the caller's environment (`getfenv()`). Where a top-level non-local assignment ends up depends on which environment that is:

- **Module scope (the default).** `import` runs the file with `doscript(name, module)`, passing a fresh module table as the environment (see `LoadModule` in [lua/system/import.lua](lua/system/import.lua)). A top-level `Foo = ...` becomes a field of that module table. Other files reach it only through `import(...).Foo`. Reads of undefined names fall through to the state's globals (`__module_metatable` has `__index = _G`).
- **Lua state globals.** A value is visible to every file in that Lua state when:
  - it is assigned to `_G` explicitly (`_G.Foo = ...`, or `rawset(_G, ...)`), from any file, or
  - it is assigned in a file the engine runs to initialize a state ([lua/globalInit.lua](lua/globalInit.lua), [lua/simInit.lua](lua/simInit.lua), [lua/SessionInit.lua](lua/SessionInit.lua), [lua/RuleInit.lua](lua/RuleInit.lua), …). Those run in the global environment, and so do the files they load with a bare `doscript` (`/lua/system/import.lua`, `utils.lua`, `class.lua`, `trashbag.lua`, …). This is where `import`, `ClassUnit`, `TrashBag` and friends come from.
- **A bare `doscript` inside a module** runs the file in *that module's* environment, not `_G`. Its globals become fields of the calling module:
  - [lua/sim/Recall.lua](lua/sim/Recall.lua) runs `doscript "/lua/shared/recallparams.lua"`. The recall parameters become part of the `Recall.lua` module, not sim globals.
  - [lua/aibrains/easy-ai.lua](lua/aibrains/easy-ai.lua) `doscript`s the base, builder-group and builder templates under `lua/aibrains/templates/` into its own module.

Files written to be loaded with a bare `doscript` carry a `---@declare-global` annotation on line 1 (the init files, the system files they load, `RecallParams.lua`, the AI templates). Keep that annotation on such files, and don't add it to files loaded with `import`.

When adding new code, use `import` and module-scope variables. Only add a state global when the value is truly needed everywhere in that state.

## Lua contexts

Each context is a separate, isolated Lua state. Code that runs in one cannot see the others' globals. Engine globals for each are declared (for intellisense only) in [engine/](engine/): `Core.lua` (shared), `Sim.lua`, `User.lua`.

The engine runs one init file to set up each state, then calls Lua entry points into it.

| Context | Init file | Entry points the engine calls | Notes |
|---|---|---|---|
| Init | `init_faf.lua` / `init_fafbeta.lua` / `init_fafdevelop.lua` | | Mounts directories and archives. `io`/`os` available. |
| Blueprint loading | [lua/RuleInit.lua](lua/RuleInit.lua) | | The game rules' own state. Runs `config.lua`, `utils.lua` and other system files (not `globalInit.lua`), then [lua/system/Blueprints.lua](lua/system/Blueprints.lua) `LoadBlueprints()` to load and post-process all `*.bp` files and mod blueprints. The engine exports the results to the session UI and sim states as `__blueprints`. |
| Main menu UI | [lua/userInit.lua](lua/userInit.lua) | [lua/ui/uimain.lua](lua/ui/uimain.lua): `StartSplashScreen`, `StartFrontEndUI`, `StartHostLobbyUI`, `StartJoinLobbyUI`. [lua/SinglePlayerLaunch.lua](lua/SinglePlayerLaunch.lua): `StartCommandLineSession` for the `/map` and `/scenario` command-line arguments. | The user state created at startup. `userInit.lua` sets up user globals and runs `globalInit.lua`. Splash, menus, lobby. |
| Session UI ("user") | [lua/SessionInit.lua](lua/SessionInit.lua) | `uimain.lua`: `StartGameUI`, plus callbacks such as `ShowEscapeDialog`, `UpdateDisconnectDialog`, `ShowDesyncDialog`, `StartCursorText`. | A fresh state per session. `SessionInit.lua` runs `userInit.lua` first, then adds UI mods and `UserSync.lua`. In-game UI, local to one player. |
| Session sim | [lua/simInit.lua](lua/simInit.lua) | `SetupSession`, `OnCreateArmyBrain` (per army), `BeginSession` | The deterministic simulation. Runs `globalInit.lua`. |

`globalInit.lua` is shared setup run by the user and sim init files (and the editor and viewer ones). It is not an entry point of its own.

### Session setup

A session starts from the main menu state with a launch function: the lobby's `LaunchGame(sessionInfo)`, `LaunchSinglePlayerSession(sessionInfo)` (used by `SinglePlayerLaunch.lua` and the campaign UI) or `LaunchReplaySession(filename)`. The engine turns `sessionInfo` into the sim's starting values:

| `sessionInfo` field | Becomes in the sim |
|---|---|
| `GameMods` | `__active_mods`. The rules state gets it too, where it decides which mod blueprints load. |
| `GameOptions` | `ScenarioInfo`: the table from the scenario file named by `GameOptions.ScenarioFile`, with `GameOptions` stored as `ScenarioInfo.Options`. |
| `PlayerOptions` | `ScenarioInfo.ArmySetup[armyName]`, one table per army. Read by `OnCreateArmyBrain` and by AI code (`.AIPersonality`). |

A replay stores the same configuration in the replay file, and `LaunchReplaySession` rebuilds the session from it.

### Determinism and desyncs

**Determinism is the critical rule.** The sim runs in lockstep on every client. Anything in sim code that differs between clients causes a desync.

- UI → sim: go through [lua/SimCallbacks.lua](lua/SimCallbacks.lua) (`SimCallback(...)` from UI, handler registered there). Validate every argument in the handler; callbacks are player input and can be forged.
- Sim → UI: write into the `Sync` table ([lua/SimSync.lua](lua/SimSync.lua)), consumed by [lua/UserSync.lua](lua/UserSync.lua).
- Some sim functions return a different value on each client. Use them only to decide what to send to the local UI, never to change sim state:
  - `GetFocusArmy()`: the army this client is watching. Often used to sync data only for that army.
  - Debug functions such as `DebugGetSelection()`, `SelectedUnit()` and `GetSystemTimeSecondsOnlyForProfileUse()`.
- Iteration order with `pairs`/`next`/`for k, v in t`: keys that are strings, numbers or booleans are hashed by value. Keys that are tables, functions or userdata (units, for example) are hashed by memory address, so their order is not guaranteed to match between clients. Don't let results depend on the iteration order of such tables. Sim code keys tables of entities by `entity.EntityId` (from `Entity:GetEntityId()`, a string) instead of by the entity itself.

Debugging a desync:

- Launch with `/synclog <folder>` to log everything that feeds the sim checksum, one file per beat. The sim keeps the files for the last `sim_ChecksumPeriod + 20` beats (the period defaults to 50) and deletes them on a clean exit, so the beats around a desync remain.
- The rolling checksum is seeded from the game rules when the sim is set up: the footprints, the number of blueprints, and each blueprint's ID and load order, but not their contents. A desync on the first checksum (beat 0) therefore usually means the clients loaded a different set of blueprints, e.g. different mods or game files. After that, each checksum adds each army's economy, the entities that moved (ID, health, position, orientation, velocity) and the RNG state. Map data such as terrain height is never hashed directly: different map files only cause a desync once they make units behave differently.

Details: [docs/development-start-here/lua-contexts.md](docs/development-start-here/lua-contexts.md).

## Repository layout

| Path | Contents |
|---|---|
| `lua/sim/` | Simulation core: [Unit.lua](lua/sim/Unit.lua), [weapon.lua](lua/sim/weapon.lua), [Projectile.lua](lua/sim/Projectile.lua), buffs, damage, navigation (`NavGenerator`, `NavUtils`), `units/` (unit base classes such as `LandUnit`, `FactoryUnit`, `ACUUnit`), `weapons/`, `projectiles/`, `commands/`, `tasks/`. |
| `lua/` (top level) | Faction class libraries (`aeonunits.lua`, `cybranweapons.lua`, `terranweapons.lua`, …), `defaultunits.lua`, effect templates/utilities, scenario framework, AI brain (`aibrain.lua`), sim/user sync. |
| `lua/ui/` | All UI: `game/` (in-game HUD), `lobby/`, `menus/`, `dialogs/`, `controls/` (reusable composed controls). |
| `lua/maui/` | UI primitives wrapping engine controls (`Bitmap`, `Group`, `Text`, `layouthelpers.lua`, …). |
| `lua/system/` | Runtime infrastructure: `class.lua` (class system), `import.lua`, `Blueprints.lua` + `blueprints-*.lua` (blueprint post-processing), `trashbag.lua`, `categories.lua`, `utils.lua`. |
| `lua/AI/`, `lua/aibrains/`, `lua/sim/*Manager.lua` | AI: builders, platoons, base templates, the AI brain variants. |
| `lua/shared/` | Code usable from more than one context. |
| `units/<ID>/` | One folder per unit: `<ID>_unit.bp` (blueprint), `<ID>_script.lua` (unit class), meshes, textures, icons. |
| `projectiles/`, `effects/`, `env/`, `meshes/`, `textures/` | Assets and their blueprints/scripts. Only assets FAF adds or changes are here (see below). |
| `schook/` | Hook files mounted on top of the base game's `/lua` via the `hook` table in the init files. Code here is appended to the original file of the same path. |
| `loc/<LANG>/` | Localization string tables. Use `<LOC key>fallback` strings in user-facing text. |
| `engine/` | Annotation-only stubs of engine-provided globals and `moho.*` classes. Never loaded by the game. Keep them accurate when you learn engine behavior. |
| `lua-ls-addon/` | LuaLS plugin that teaches the language server this Lua dialect. Wired in via `.vscode/settings.json`. |
| `tests/` | Offline Lua tests (see below). |
| `changelog/snippets/` | Per-PR changelog snippets. |
| `docs/` | Jekyll site published to faforever.github.io/fa (dev docs, changelogs in `docs/_posts/`). |
| `setup/bin/init_local_development.lua` | Init file for running the game against a local checkout. |
| `scripts/LaunchFAInstances.ps1` | Launches several local game instances (host + clients) for multiplayer testing. |
| `testmaps/` | Maps used for manual testing. |

## Classes

Use the typed class constructors from [lua/system/class.lua](lua/system/class.lua), not plain `Class`, when one applies: `ClassUnit`, `ClassWeapon`, `ClassProjectile`, `ClassShield`, `ClassUI`, `ClassDummyUnit`, `ClassSimple`. States use `State { ... }` and `ChangeState(self, self.SomeState)`.

```lua
local ACUUnit = import("/lua/defaultunits.lua").ACUUnit

---@class UEL0001 : ACUUnit
---@field HasLeftPod boolean
UEL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
    },

    ---@param self UEL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
    end,
}
TypeClass = UEL0001
```

- Call the base method explicitly (`Base.Method(self, ...)`). There is no `super`.
- A unit script must set `TypeClass` to its class.
- Per-instance resources (threads, emitters, entities) go in `self.Trash` so they are cleaned up on destroy.
- Declare every `self.X` field with `---@field` above the class. See [annotation.md](annotation.md).

## Blueprints

`*.bp` files are Lua table constructors (`UnitBlueprint { ... }`). They are processed at load time in [lua/system/Blueprints.lua](lua/system/Blueprints.lua) and the `blueprints-*.lua` files, which compute derived fields (categories, LOD, weapon data, build presets). In sim code, read blueprints with `self.Blueprint` or `__blueprints[id]`. Do not mutate a blueprint at runtime: it is shared by every instance.

## Performance

Large games run thousands of units, and UI code often runs every frame. Standard Lua advice applies (locals over globals, no allocations or closures in hot loops, no string building per tick). The points below are specific to this engine and dialect. Most are measured in [lua/benchmarks/](lua/benchmarks/), where header comments record the results. Some of those results differ from what standard Lua would predict, so check the benchmark rather than assuming.

### Upvalue globals and methods

Cache engine globals, library functions, class methods and `moho.*_methods` entries as file-level locals. Do this in sim and UI hot paths alike. Reading an upvalue (GETUPVAL) is cheaper than a global or table lookup (GETTABLE), which is cheaper than a `:` call (SELF). [function-scope.lua](lua/benchmarks/function-scope.lua) measures this.

```lua
-- Upvalued for performance
local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local IsAlly = IsAlly
local TableGetn = table.getn
local EntityGetPosition = moho.entity_methods.GetPosition

-- in the hot path
local pos = EntityGetPosition(unit)   -- instead of unit:GetPosition()
TrashAdd(self.Trash, thread)          -- instead of self.Trash:Add(thread)
```

- Upvalue at file scope, not inside the loop. Fetching into a local on each iteration is slower than using the global ([math-generic.lua](lua/benchmarks/math-generic.lua)).
- [lua/sim/Unit.lua](lua/sim/Unit.lua) and [lua/system/trashbag.lua](lua/system/trashbag.lua) show the pattern. `trashbag.lua` has a copy-paste block of the `Trash*` upvalues.

### Avoid engine calls

Crossing into C (a "CFunction" or a `moho` method) is expensive compared with plain Lua.

- Read fields instead of calling getters. `unit.Dead` is about 17x faster than `unit:BeenDestroyed()` ([function-origin.lua](lua/benchmarks/function-origin.lua)). Use `self.Blueprint` instead of `self:GetBlueprint()`.
- Prefer Lua-side tables over engine lookups: `ArmyBrains[i]` is 50–100x faster than `GetArmyBrain(i)` ([value-access.lua](lua/benchmarks/value-access.lua)).
- **Distances.** `VDist3` is fast thanks to an [engine patch](https://github.com/FAForever/FA-Binary-Patches/pull/54), so upvalue and use it ([VDist3.lua](lua/benchmarks/VDist3.lua)). `VDist2` is not patched: inline Lua math beats it. When you only compare distances, compare squared distances and skip the square root ([VDist2.lua](lua/benchmarks/VDist2.lua)).
- `ForkThread` costs far more than a function call ([function-threads.lua](lua/benchmarks/function-threads.lua)). Check the conditions that would end the thread at once *before* forking it.

### Iterate the fast way

From [table-loops.lua](lua/benchmarks/table-loops.lua), for a 20-element array:

| Loop | Relative cost |
|---|---|
| `for i = 1, TableGetn(t) do local v = t[i] ... end` | 1x |
| `for _, v in ipairs(t)` | ~16x |
| `for k, v in t` / `next` / `pairs` | ~26x |

- For arrays, use a numeric `for` with an upvalued `table.getn`. `ipairs` is much slower here than in standard Lua.
- For hash tables, `for k, v in t` is at least as fast as `pairs(t)`. LuaPlus compiles it by inserting a `getglobal next` as the iterator function, making it equivalent to `for k, v in next, t`. Upvaluing `next` gives no measurable gain.
- Don't call `table.getn` on every insert. Keep a counter and assign `t[n] = v` ([table-insert.lua](lua/benchmarks/table-insert.lua)). Upvalue `table.insert` when you do use it.
- `table.getsize` and `table.empty` come from the engine (with Lua fallbacks in [lua/system/utils.lua](lua/system/utils.lua)). Use `table.empty(t)` instead of `table.getsize(t) == 0`.

### Cache table reads

Reading a table field costs a GETTABLE each time. When a function reads the same fields more than once, read them into locals first. The benchmarks show a large speedup even for a single use ([table-array.lua](lua/benchmarks/table-array.lua), [table-hash.lua](lua/benchmarks/table-hash.lua), [table-sub.lua](lua/benchmarks/table-sub.lua)).

```lua
local x1, y1, z1 = a[1], a[2], a[3]
local Defense = bp.Defense   -- instead of repeating bp.Defense.X
```

### Classes and metatables

- Method lookups walk the class `__index` chain. A table `__index` is much cheaper than a function `__index` ([metatables.lua](lua/benchmarks/metatables.lua)). For values read in hot paths, copy them onto the instance in `OnCreate` rather than resolving them through the chain each time. Measure first: in that benchmark, copying `ForkThread` onto the instance made it slower.

### Allocations

- Reuse vectors and tables in hot paths. Allocating a `Vector` per call is about 6x slower than filling a cached one, and puts pressure on the garbage collector ([memory.lua](lua/benchmarks/memory.lua)). `unit:GetPositionXYZ()` returns the components without allocating a vector, although it was barely faster than `GetPosition()` in that benchmark.
- Pre-allocate tables whose size you know with `{&h &a}`. Examples: [lua/lazyvar.lua](lua/lazyvar.lua) (`{&1 &8}`), [lua/system/categories.lua](lua/system/categories.lua) (`{&4 &0}`). Files using this syntax must be added to the skip list in `tests/run-syntax-test.sh`.
- Avoid creating closures per call when one can be defined once and reused ([function-closures.lua](lua/benchmarks/function-closures.lua)).

### Categories

Category expressions like `categories.AIR * categories.TECH3` create new category objects. Compute them once at file scope (or once per outer loop), not inside an `EntityCategoryContains` call in a hot path ([categories.lua](lua/benchmarks/categories.lua): 21 ms vs 130 ms). [lua/system/categories.lua](lua/system/categories.lua) now caches the results of `+`, `-` and `*` (99% hit rate in a recorded 1-hour game), so repeated inline expressions cost less than the benchmark shows. Upvaluing is still cheaper and clearer.

### Measuring

Benchmarks live in [lua/benchmarks/](lua/benchmarks/). Each file sets `ModuleName`, a `BenchmarkData` table mapping function names to display names, and benchmark functions that take a loop count and return elapsed seconds (`GetSystemTimeSecondsOnlyForProfileUse`). Run them in-game from the **Benchmarks** tab of the profiler window ([lua/ui/game/Profiler.lua](lua/ui/game/Profiler.lua), sim side in [lua/sim/Profiler.lua](lua/sim/Profiler.lua)). The runner subtracts the cost of an empty loop ([control.lua](lua/benchmarks/control.lua)). When you make a performance claim in a PR, add or extend a benchmark and record its results in the file's header comment.

## Code style

- Annotate everything new (see [annotation.md](annotation.md)): `---` description on every function and class, `@param`/`@return` with types, `---@field` for every class field. The FA Lua VS Code extension / LuaLS depends on these.
- Comments: declarative, succinct, no trailing period on single-sentence comments, no em-dashes.
- 4-space indentation. Follow the [Lua Style Guide](http://lua-users.org/wiki/LuaStyleGuide).
- Match surrounding code. Much of the tree is legacy GPG code with its own style; don't reformat code you aren't changing.

## Testing and verification

There is no way to run the game in CI. Tests are small, offline, and require the FAF Lua interpreter ([FAForever/lua-lang](https://github.com/FAForever/lua-lang), CI uses the `faforever/lua:v5.0-3` Docker image). Standard Lua 5.1+ will not parse this code.

```bash
bash ./tests/run-syntax-test.sh      # luac -p over every .lua and .bp file
bash ./tests/run-utility-tests.sh    # tests/utility/*.spec.lua (luft framework)
bash ./tests/run-blueprint-tests.sh  # sanity checks on units/*/*.bp
```

Run with Docker if the interpreter isn't installed locally:

```bash
docker run --rm -v "$PWD:/fa" -w /fa faforever/lua:v5.0-3 sh -c "apk add bash findutils >/dev/null && bash ./tests/run-syntax-test.sh"
```

The syntax test skips files that use `{&h&a}` syntax (`lua/lazyvar.lua`, `lua/system/class.lua`, `lua/sim/NavGenerator.lua`, `lua/system/categories.lua`). Add to that list if you introduce the syntax elsewhere.

Real verification means running the game: copy `setup/bin/init_local_development.lua` into the FAF client's `bin` folder (usually `C:\ProgramData\FAForever\bin`), set `locationOfRepository` in it, and launch `ForgedAlliance.exe /init "init_local_development.lua" /EnableDiskWatch /showlog /nomovie`. Check the moho log for Lua errors. See [docs/development/setup.md](docs/development/setup.md). When you can't run the game, say so and state what the user should check in-game.

## Branches, PRs, changelog

- PRs target **`develop`**. Deployment branches: `deploy/faf` (release), `deploy/fafbeta`, `deploy/fafdevelop`. See [docs/deployment.md](docs/deployment.md).
- Commit subject: imperative, under 80 characters, no trailing period. Squash merges append the PR number, e.g. `Fix MaxHealth buff leaving current health above max health (#7230)`.
- Keep PRs small. Split large changes into [stacked PRs](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs), and medium ones into "atomic" commits that each review on their own:
  - Refactors that don't change behavior go in their own PR or commit, separate from functional changes.
  - Each functional change gets its own PR or commit, one piece of functionality at a time.
  - When proposing commits for the user, follow this split rather than one commit for everything.
- PR descriptions link the Discord or forum discussion that approved the change, and tick the "approved conceptually" box once it is greenlit (bugfix, game team lead decision, or positive discussion).
- **Testing in live games.** FAForever organization members can deploy a branch to the `FAF Beta Balance` or `FAF Develop` game types. They force-push it to `staging/fafbeta` or `staging/fafdevelop`, then run the matching deploy workflow ([deploy-fafbeta.yaml](.github/workflows/deploy-fafbeta.yaml), [deploy-fafdevelop.yaml](.github/workflows/deploy-fafdevelop.yaml)). This tests a PR without merging it. Staging branches are also reset from `develop` on a schedule, so deployed test changes are temporary. Force-pushing shared branches is outward-facing: only do it when the user explicitly asks. See [docs/deployment.md](docs/deployment.md).
- Every PR needs a changelog snippet at `changelog/snippets/<category>.<PR number>.md`. Categories, in priority order: `graphics`, `ai`, `performance`, `balance`, `features`, `fix`, `other`. Snippets are written for players, not developers. Opening a PR runs a workflow that commits a template snippet for you to fill in. Details: [docs/development-changelog.md](docs/development-changelog.md).
- Balance changes need balance team sign-off. Feature changes need discussion before review (see [CONTRIBUTING.md](CONTRIBUTING.md)).

## Gotchas

- Mods and the co-op featured mod ([FAForever/fa-coop](https://github.com/FAForever/fa-coop)) hook and override these files. Renaming or removing a public function, class field, or module path can break mods silently. Prefer adding over changing signatures, and keep deprecated aliases (`---@deprecated`) when you must rename.
- **Not every asset is in the repo.** FAF replaces the base game's Lua, but the init files still mount the original installation's asset `.scd` archives (`textures.scd`, `units.scd`, `meshes.scd`, `effects.scd`, …) alongside this repo's files. The `allowedAssetsScd` table in [init_faf.lua](init_faf.lua) lists which archives are mounted and which (`lua.scd`, `schook.scd`, `mohodata.scd`, `moholua.scd`) are fully replaced by the repo. A texture, mesh, sound or effect path that appears in code or blueprints but not in the repo usually comes from those archives. Don't treat it as a broken reference. Don't "fix" it or delete the code using it.
- Engine functions without Lua source are documented only through `engine/*.lua` stubs and observed behavior. Don't assume a function exists because it would be convenient; check `engine/`.
- **[faf-re](https://github.com/Draiget/faf-re)** is a decompilation of the engine. Use it only as a last resort: when the `engine/` stubs and repo docs are missing details about an engine function or callback, or when they contradict observed results. It is incomplete, and its comments say where. Treat its code as evidence of engine behavior, not proof. Mention it when a conclusion depends on it.
- Performance matters in both sim and UI code. See [Performance](#performance).
- `.bp` files are treated as Lua by the editor (`files.associations`) and the syntax test.
