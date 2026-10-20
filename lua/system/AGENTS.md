# Lua states and runtime

How the engine sets up each Lua state, how modules and globals resolve, and what [config.lua](config.lua) changes about default Lua behavior. Read the root [AGENTS.md](../../AGENTS.md) first: it has the rules, this file has the details behind them.

## Lua contexts

Each context is a separate, isolated Lua state. Code that runs in one cannot see the others' globals. Engine globals for each are declared (for intellisense only) in [engine/](../../engine/): `Core.lua` (shared), `Sim.lua`, `User.lua`.

The engine runs one init file to set up each state, then calls Lua entry points into it.

| Context | Init file | Entry points the engine calls | Notes |
|---|---|---|---|
| Init | `init_faf.lua` / `init_fafbeta.lua` / `init_fafdevelop.lua` | | Mounts directories and archives. `io`/`os` available. |
| Blueprint loading | [lua/RuleInit.lua](../../lua/RuleInit.lua) | | The game rules' own state. Runs `config.lua`, `utils.lua` and other system files (not `globalInit.lua`), then [lua/system/Blueprints.lua](Blueprints.lua) `LoadBlueprints()` to load and post-process all `*.bp` files and mod blueprints. The engine exports the results to the session UI and sim states as `__blueprints`. |
| Main menu UI | [lua/userInit.lua](../../lua/userInit.lua) | [lua/ui/uimain.lua](../../lua/ui/uimain.lua): `StartSplashScreen`, `StartFrontEndUI`, `StartHostLobbyUI`, `StartJoinLobbyUI`. [lua/SinglePlayerLaunch.lua](../../lua/SinglePlayerLaunch.lua): `StartCommandLineSession` for the `/map` and `/scenario` command-line arguments. | The user state created at startup. `userInit.lua` sets up user globals and runs `globalInit.lua`. Splash, menus, lobby. |
| Session UI ("user") | [lua/SessionInit.lua](../../lua/SessionInit.lua) | `uimain.lua`: `StartGameUI`, plus callbacks such as `ShowEscapeDialog`, `UpdateDisconnectDialog`, `ShowDesyncDialog`, `StartCursorText`. | A fresh state per session. `SessionInit.lua` runs `userInit.lua` first, then adds UI mods and `UserSync.lua`. In-game UI, local to one player. |
| Session sim | [lua/simInit.lua](../../lua/simInit.lua) | `SetupSession`, `OnCreateArmyBrain` (per army), `BeginSession` | The deterministic simulation. Runs `globalInit.lua`. |

`globalInit.lua` is shared setup run by the user and sim init files (and the editor and viewer ones). It is not an entry point of its own.

## Session setup

A session starts from the main menu state with a launch function: the lobby's `LaunchGame(sessionInfo)`, `LaunchSinglePlayerSession(sessionInfo)` (used by `SinglePlayerLaunch.lua` and the campaign UI) or `LaunchReplaySession(filename)`. The engine turns `sessionInfo` into the sim's starting values:

| `sessionInfo` field | Becomes in the sim |
|---|---|
| `GameMods` | `__active_mods`. The rules state gets it too, where it decides which mod blueprints load. |
| `GameOptions` | `ScenarioInfo`: the table from the scenario file named by `GameOptions.ScenarioFile`, with `GameOptions` stored as `ScenarioInfo.Options`. |
| `PlayerOptions` | `ScenarioInfo.ArmySetup[armyName]`, one table per army. Read by `OnCreateArmyBrain` and by AI code (`.AIPersonality`). |

A replay stores the same configuration in the replay file, and `LaunchReplaySession` rebuilds the session from it.

## Module scope vs. Lua state globals

`doscript(file, env)` runs `file` with `env` as its environment. Without `env`, it uses the caller's environment (`getfenv()`). Where a top-level non-local assignment ends up depends on which environment that is:

- **Module scope (the default).** `import` runs the file with `doscript(name, module)`, passing a fresh module table as the environment (see `LoadModule` in [lua/system/import.lua](import.lua)). A top-level `Foo = ...` becomes a field of that module table. Other files reach it only through `import(...).Foo`. Reads of undefined names fall through to the state's globals (`__module_metatable` has `__index = _G`).
- **Lua state globals.** A value is visible to every file in that Lua state when:
  - it is assigned to `_G` explicitly (`_G.Foo = ...`, or `rawset(_G, ...)`), from any file, or
  - it is assigned in a file the engine runs to initialize a state ([lua/globalInit.lua](../../lua/globalInit.lua), [lua/simInit.lua](../../lua/simInit.lua), [lua/SessionInit.lua](../../lua/SessionInit.lua), [lua/RuleInit.lua](../../lua/RuleInit.lua), …). Those run in the global environment, and so do the files they load with a bare `doscript` (`/lua/system/import.lua`, `utils.lua`, `class.lua`, `trashbag.lua`, …). This is where `import`, `ClassUnit`, `TrashBag` and friends come from.
- **A bare `doscript` inside a module** runs the file in *that module's* environment, not `_G`. Its globals become fields of the calling module:
  - [lua/sim/Recall.lua](../../lua/sim/Recall.lua) runs `doscript "/lua/shared/recallparams.lua"`. The recall parameters become part of the `Recall.lua` module, not sim globals.
  - [lua/aibrains/easy-ai.lua](../../lua/aibrains/easy-ai.lua) `doscript`s the base, builder-group and builder templates under `lua/aibrains/templates/` into its own module.

Files written to be loaded with a bare `doscript` carry a `---@declare-global` annotation on line 1 (the init files, the system files they load, `RecallParams.lua`, the AI templates). Keep that annotation on such files, and don't add it to files loaded with `import`.

When adding new code, use `import` and module-scope variables. Only add a state global when the value is truly needed everywhere in that state.

## Runtime changes to Lua behavior

[lua/system/config.lua](config.lua) runs early in every Lua state and changes some default behavior. These change how code fails:

- **Reading an undefined global raises an error** ("access to nonexistent global variable") instead of returning `nil`. Modules see this too, because their environment falls through to `_G`. `if SomeOptionalGlobal then` errors when the global is missing. Probe with `rawget(_G, "SomeOptionalGlobal")` instead, as the init files do for `SetProcessPriority`. The same applies to engine functions that exist in only one context (sim vs. user).
- **Setting a field on `nil`, a boolean, a number or a string raises an error.** Reading a field on `nil` still returns `nil`. Stock LuaPlus allows it, storing the value on the type's shared metatable. Strings are locked at the end of [lua/system/utils.lua](utils.lua), after that file adds the extra `string.*` functions.
- **Threads have a metatable.** `thread:Destroy()` calls `KillThread`, which is why threads can go in a `TrashBag`. Setting a field on a thread raises an error, so store thread state on the owning object.
- **`math.random` is replaced by the engine's `Random`.** In the sim, `Random` uses the synchronized RNG, so it is safe for determinism. It follows `Random`'s argument semantics ([engine/Core.lua](../../engine/Core.lua)), not stock `math.random`'s.
- It defines the global `iscallable(f)`, which returns `f` if it is a function, a C function or a table with a `__call` metamethod.

## `EmptyTable`

[lua/globalInit.lua](../../lua/globalInit.lua) defines the global `EmptyTable`: a shared empty table whose `__newindex` logs a warning and discards the write. Use it wherever a table is required but has no content, typically as an argument to a C function, to avoid allocating a new `{}`. Lua code may also return it as a "no results" value (e.g. `Unit:GetTerrainTypeEffects`).

Every caller shares the same instance, so:

- Never write to a table that might be `EmptyTable`. Writes are dropped with only a `WARN`, so the bug is easy to miss. `rawset` bypasses the guard and corrupts it for every caller.
- Never call `setmetatable` on it, and never pass it to code that does (e.g. something that turns a table into a class instance).
- If the caller might modify the result, return a fresh `{}` instead.

## Debugging a desync

- Launch with `/synclog <folder>` to log everything that feeds the sim checksum, one file per beat. The sim keeps the files for the last `sim_ChecksumPeriod + 20` beats (the period defaults to 50) and deletes them on a clean exit, so the beats around a desync remain.
- The rolling checksum is seeded from the game rules when the sim is set up: the footprints, then every blueprint in load order (its ID and the values the engine parsed from it), then the number of unit, projectile, prop and mesh blueprints. A desync on the first checksum (beat 0) therefore usually means the clients loaded different blueprints or blueprint values, e.g. different mods or game files. After that, each checksum adds each army's economy, the entities that moved (ID, health, position, orientation, velocity) and the RNG state. Map data such as terrain height is never hashed directly: different map files only cause a desync once they make units behave differently.
