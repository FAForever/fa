# Engine stubs

Files in `engine/` declare the globals and `moho.*` classes that the closed-source engine provides. They exist only for the language server (LuaLS / the FA Lua extension): the game never loads them, and nothing in them runs. Each file starts with `---@meta` (two older manipulator files use `---@declare-global`), so LuaLS treats it as declarations and [lua-ls-addon/export-env.lua](../lua-ls-addon/export-env.lua) leaves it untransformed. Read the root [AGENTS.md](../AGENTS.md) first. Annotation and comment style follow [annotation.md](../annotation.md).

## Layout

| Path | Contents |
|---|---|
| [Core.lua](Core.lua) | Globals available in both sim and user states (vectors, `Random`, `ForkThread`, disk access, ...) |
| [Sim.lua](Sim.lua) | Sim-only globals (`CreateUnit`, emitters, manipulator constructors, army functions, ...) |
| [User.lua](User.lua) | User (UI) state globals |
| [Library.lua](Library.lua) | Differences between the engine's Lua 5.0 standard library and the Lua 5.1 library LuaLS assumes, including `LOG`. Its header says these appear to be built into every state, including the init files |
| [Unsafe.lua](Unsafe.lua) | `SHGetFolderPath`. Built in like `Library.lua`, per that file's header |
| [Enums.lua](Enums.lua) | Aliases for engine string constants (`EngineCommandCap`, ...) |
| [AnnotationCommon.lua](AnnotationCommon.lua) | Shared base types: `Destroyable`, `InternalObject`, `cfunction`, `nonnil` |
| [moho.lua](moho.lua) | The `moho` global: maps each `moho.*_methods` table to its stub file. Example only, never executed |
| [Sim/](Sim/), [User/](User/), [Core/](Core/) | One file per engine class, by context. File names follow the engine's C++ class (`CAiBrain.lua`, `CMauiBitmap.lua`) |
| [Core/Blueprints/](Core/Blueprints/) | Blueprint field annotations (`UnitBlueprint`, `WeaponBlueprint`, ...) |
| [Core/Categories.lua](Core/Categories.lua) | The `categories` global and its known names |

Functions in `Core.lua`, `Sim.lua` and `User.lua` are sorted alphabetically. Keep new entries in order.

## Contexts

A function exists only in the state(s) its stub file names. Calling a sim-only function from UI code (or the reverse) raises "access to nonexistent global variable" because of [lua/system/config.lua](../lua/system/config.lua), not a quiet `nil`. See [Runtime changes to Lua behavior](../AGENTS.md#runtime-changes-to-lua-behavior) and [Lua contexts](../AGENTS.md#lua-contexts). Guard functions that only some engine builds provide with `rawget(_G, "Name")`, as [lua/simInit.lua](../lua/simInit.lua) does for `SetNavigatorPersonalPosMaxDistance`.

## Class stubs

Each class file declares a local table with the moho class annotation, adds methods to it, and returns it:

```lua
---@meta

---@class moho.unit_methods : moho.entity_methods
local Unit = {}

--- Returns the build rate of a unit
---@return number
function Unit:GetBuildRate()
end

return Unit
```

- The class name is the `moho.*` table name the engine exposes (`moho.entity_methods`, `moho.bitmap_methods`), not the file name. Inherit with `:` the way the engine does: [Sim/Unit.lua](Sim/Unit.lua) extends `moho.entity_methods`, the MAUI controls extend `moho.control_methods`, and root classes extend `Destroyable`.
- Lua classes build on these: `---@class Entity : moho.entity_methods, InternalObject` above `Entity = Class(moho.entity_methods)` in [lua/sim/Entity.lua](../lua/sim/Entity.lua). Put Lua-side fields and overrides there, not in the stub.
- Methods have empty bodies. Every `@param` and `@return` has a type. Use the real types (`Unit`, `Vector`, `Bone`) rather than `any` when known.
- Engine callbacks (methods the engine calls on the Lua object) are declared as typed fields set to `nil`, with a `Called by the engine when ...` description:

```lua
--- Called by the engine when the unit was out of fuel and recharges fuel
---@type fun(self: Unit)
Unit.OnGotFuel = nil
```

## Annotation markers

- `---@unknown` marks a function whose purpose or arguments are not known ([Sim/Entity.lua](Sim/Entity.lua) `AddShooter`). Replace it when you learn the behavior.
- `---@deprecated <reason>` marks engine functions that are slower than plain Lua, such as the vector math helpers in [Core.lua](Core.lua). The reason names the alternative.
- `---@see Name # description` links related functions and counterparts (`BeginLoggingStats` and `EndLoggingStats`).
- `---@overload` and `---@generic` describe functions with several call signatures.

## Documenting behavior

Stubs are the only documentation of engine functions. Record what a consumer needs before calling one:

- Defaults, units and side effects, in the description: "Default engine value is 50."
- Engine quirks and typos: [Sim/Entity.lua](Sim/Entity.lua) notes that `AddThreadScroller` should have been "Tread".
- Functions or fields added by [FA-Binary-Patches](https://github.com/FAForever/FA-Binary-Patches): link the patch PR, e.g. `Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/132`.
- Complex engine logic: a `--[[ ]]` Lua pseudocode block above the function, as for `CanFire` in [Sim/UnitWeapon.lua](Sim/UnitWeapon.lua).
- Caveats for blueprint fields go on the field in [Core/Blueprints/](Core/Blueprints/), e.g. `RenderFireClock` in [WeaponBlueprint.lua](Core/Blueprints/WeaponBlueprint.lua).

## Adding or correcting a stub

- Base changes on observed behavior: an in-game test, the moho log, or a [benchmark](../lua/benchmarks/). Use [faf-re](https://github.com/Draiget/faf-re) only as a last resort, as described in [Gotchas](../AGENTS.md#gotchas), and say so in the PR when a stub depends on it.
- Fix the stub in the same PR as the Lua change that relies on it (e.g. #7258 typed `DiskGetFileInfo`'s return as `FileInfo` while fixing the Lua wrapper in `userInit.lua`). Annotation-only changes are fine on their own.
- Add a new class file to [moho.lua](moho.lua) when it backs a `moho.*` table.
- Never add a function to a stub because it would be convenient. If it is not in the engine, it does not exist.

## Tooling

- LuaLS indexes `engine/` as part of the workspace. No setting points at it: [.vscode/settings.json](../.vscode/settings.json) only excludes other folders. The `---@meta` header marks the files as declaration-only.
- [tests/run-syntax-test.sh](../tests/run-syntax-test.sh) skips `engine/`, so the syntax test does not check these files. Keep them valid Lua anyway.
