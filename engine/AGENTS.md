# Engine stubs

Files in `engine/` declare the globals and `moho.*` classes that the closed-source engine provides. They exist only for the language server (LuaLS / the FA Lua extension): the game never loads them, and nothing in them runs. Each file starts with `---@meta`, so LuaLS treats it as declarations only. Read the root [AGENTS.md](../AGENTS.md) first. Annotation and comment style follow [annotation.md](../annotation.md).

## Layout

| Path | Contents |
|---|---|
| [Core.lua](Core.lua) | Globals available in both sim and user states (vectors, `Random`, `ForkThread`, disk access, ...) |
| [Sim.lua](Sim.lua) | Sim-only globals (`CreateUnit`, emitters, manipulator constructors, army functions, ...) |
| [User.lua](User.lua) | User (UI) state globals |
| [Library.lua](Library.lua) | Differences between the engine's Lua 5.0 standard library and the Lua 5.1 library LuaLS assumes, including `LOG` |
| [Unsafe.lua](Unsafe.lua) | `SHGetFolderPath` |
| [Enums.lua](Enums.lua) | Aliases for engine string constants (`EngineCommandCap`, ...) |
| [AnnotationCommon.lua](AnnotationCommon.lua) | Shared base types: `Destroyable`, `InternalObject`, `cfunction`, `nonnil` |
| [moho.lua](moho.lua) | The `moho` global: maps each `moho.*_methods` table to its stub file |
| [Sim/](Sim/), [User/](User/), [Core/](Core/) | One file per engine class, by context. File names follow the engine's C++ class (`CAiBrain.lua`, `CMauiBitmap.lua`) |
| [Core/Blueprints/](Core/Blueprints/) | Blueprint field annotations (`UnitBlueprint`, `WeaponBlueprint`, ...) |
| [Core/Categories.lua](Core/Categories.lua) | The `categories` global and its known names |

Functions in `Core.lua`, `Sim.lua` and `User.lua` are sorted alphabetically. Keep new entries in order.

## Contexts

A function exists only in the state(s) its stub file names. Calling it elsewhere raises an error ([Runtime changes to Lua behavior](../AGENTS.md#runtime-changes-to-lua-behavior)).

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
- Methods have empty bodies. Use specific types such as `Unit`, `Vector` or `Bone` rather than `any` when known.
- Engine callbacks (methods the engine calls on the Lua object) are `nil` in the engine class and implemented by the Lua classes. Declare them as fields set to `nil`, typed `nil | fun(...)`, with a `Called by the engine when ...` description. The function type gives the parameters the engine passes and the values it expects back when the callback exists:

```lua
--- Called by the engine when the unit was out of fuel and recharges fuel
---@type nil | fun(self: Unit)
Unit.OnGotFuel = nil
```

## Annotation markers

The full list is in the [LuaLS annotation reference](https://luals.github.io/wiki/annotations/). The ones used most here:

- `---@unknown` marks a function whose purpose or arguments are not known ([Sim/Entity.lua](Sim/Entity.lua) `AddShooter`). Replace it when you learn the behavior.
- `---@deprecated <reason>` marks engine functions that are slower than plain Lua, such as the vector math helpers in [Core.lua](Core.lua). The reason names the alternative.
- `---@see Name # description` links related functions (`BeginLoggingStats` and `EndLoggingStats`). It can reference a field one level deep in a class as `<class>.<field>`. Link engine methods and callbacks through their moho class, e.g. `---@see moho.unit_methods.OnGotFuel`.
- `---@overload fun(...)` adds a call signature, but doesn't reliably narrow the return type by argument (e.g. `EntityCategoryFilterDown`).
- `---@generic T` makes a template-like signature, where the return type follows a parameter's type.

## Documenting behavior

Stubs are the only documentation of engine functions. Record what a consumer needs before calling one:

- Units and side effects, in the description.
- Engine quirks and typos: [Sim/Entity.lua](Sim/Entity.lua) notes that "Thread" in `AddThreadScroller` should have been "Tread".
- Functions or fields added by [FA-Binary-Patches](https://github.com/FAForever/FA-Binary-Patches): link the patch PR, e.g. `Introduced by https://github.com/FAForever/FA-Binary-Patches/pull/132`. Group them at the bottom of the file under `-- Added by FA-Binary-Patches` (or `Changed by`, for engine behavior a patch changes). When a patch predates the repository's PRs, link the commit that added it.
- Complex engine logic: a `--[[ ]]` Lua pseudocode block above the function, as for `CanFire` in [Sim/UnitWeapon.lua](Sim/UnitWeapon.lua).
- Caveats for blueprint fields go on the field in [Core/Blueprints/](Core/Blueprints/), e.g. `RenderFireClock` in [WeaponBlueprint.lua](Core/Blueprints/WeaponBlueprint.lua).

## Adding or correcting a stub

- Base changes on observed behavior: an in-game test, the moho log, or a [benchmark](../lua/benchmarks/). Use faf-re only as described in [Gotchas](../AGENTS.md#gotchas).
- Fix the stub in the same PR as the Lua change that relies on it. Annotation-only PRs are fine too.
- Add a new class file to [moho.lua](moho.lua) when it backs a `moho.*` table.
- Never add a function to a stub because it would be convenient. If it is not in the engine, it does not exist.
- The syntax test skips `engine/`, so keep these files valid Lua yourself.
