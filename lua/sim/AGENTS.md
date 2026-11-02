# Sim: Units, Weapons and Projectiles

This guide covers working with simulation code: the class chains for units, weapons and projectiles, their lifecycle callbacks, threads, states, buffs and damage. It extends the root [AGENTS.md](../../AGENTS.md). Read its [Determinism and desyncs](../../AGENTS.md#determinism-and-desyncs), [Classes](../../AGENTS.md#classes) and [Performance](../../AGENTS.md#performance) sections first, and [performance.md](../../performance.md) before changing a hot path.

## Sim code outside this folder

`lua/sim/` holds the base classes, but the `/lua` root mixes sim and UI files. A sim change often spans folders:

| Location | Contents |
|---|---|
| [../defaultunits.lua](../defaultunits.lua), [defaultweapons.lua](defaultweapons.lua), [DefaultProjectiles.lua](DefaultProjectiles.lua) | Re-export hubs for the classes in `units/`, `weapons/` and `projectiles/`. Kept for backwards compatibility with mods and unit scripts |
| `../aeonunits.lua`, `../cybranweapons.lua`, `../seraphimprojectiles.lua`, … | Faction libraries. Most re-export the classes in `units/<faction>/`, `weapons/<faction>/` and `projectiles/<faction>/` |
| [../aibrain.lua](../aibrain.lua) | `AIBrain`, one per army. Unit events such as `OnUnitKilled` and `OnUnitStopBeingBuilt` are forwarded to it |
| [../SimCallbacks.lua](../SimCallbacks.lua), [../SimSync.lua](../SimSync.lua) | UI to sim and sim to UI boundaries. `SecureUnits` filters unit lists sent by a player |
| [../SimUtils.lua](../SimUtils.lua) | Unit transfer between armies (`TransferUnitsOwnership`) |
| [../shield.lua](../shield.lua), [../defaultcomponents.lua](../defaultcomponents.lua) | `Shield` classes, and the `IntelComponent` / `VeterancyComponent` mixed into `Unit` |
| [../ScenarioFramework.lua](../ScenarioFramework.lua), [ScenarioUtilities.lua](ScenarioUtilities.lua) | Map and campaign scripting helpers |
| `/projectiles/<Name>/<Name>_script.lua` | Per-projectile classes. Unit scripts are covered in [units/AGENTS.md](../../units/AGENTS.md) |

## Class chains

Put a change on the lowest class that covers every unit it should affect. Changes in [Unit.lua](Unit.lua) reach every unit, including mod units.

- **Units**: [Unit.lua](Unit.lua) → [units/](units/) base classes ([MobileUnit](units/MobileUnit.lua) → [WalkingLandUnit](units/WalkingLandUnit.lua) → [CommandUnit](units/CommandUnit.lua) → [ACUUnit](units/ACUUnit.lua); [StructureUnit](units/StructureUnit.lua) → [FactoryUnit](units/FactoryUnit.lua); …) → faction classes in `units/<faction>/` (e.g. [TLandUnit](units/uef/TLandUnit.lua)) → `<ID>_script.lua`.
- **Weapons**: [weapon.lua](weapon.lua) → [weapons/](weapons/) (`DefaultProjectileWeapon`, `DefaultBeamWeapon`, `BareBonesWeapon`, …) → `weapons/<faction>/` → the `Weapons` table of a unit script, keyed by the blueprint weapon `Label`.
- **Projectiles**: [Projectile.lua](Projectile.lua) → [projectiles/](projectiles/) (`EmitterProjectile`, `SinglePolyTrailProjectile`, `NukeProjectile`, …) → `../<faction>projectiles.lua` → `<Name>_script.lua`.
- Mixins go in `components/` subfolders ([units/components/](units/components/), [projectiles/components/](projectiles/components/)) and are passed as extra bases: `ClassUnit(Unit, TreadComponent)`.
- Import a base class from its own file in new code. Keep the faction library exports when moving a class, since unit scripts import from them.

## Lifecycle

- **Unit creation**: `OnPreCreate` creates `self.Trash` and the [cached fields](#cached-fields). Weapons run their `OnCreate` before the unit's `OnCreate`, so anything a weapon reads from the unit must be set in `OnPreCreate`. `OnLayerChange` also runs before `OnCreate`, with `old == 'None'`.
- **Construction**: `OnStartBeingBuilt` → `OnBeingBuiltProgress` → `OnStopBeingBuilt` (or `OnFailedToBeBuilt`). `OnStopBeingBuilt` starts idle effects, intel and preset enhancements.
- **Death**: `DoTakeDamage` calls `Kill` at zero health → `OnKilled` (death weapon, veterancy, brain callback) forks `DeathThread` → `DestroyUnit` creates the wreck and calls `Destroy` → `OnDestroy` destroys `self.Trash` and enters `DeadState`. `Destroy` without `Kill` skips `OnKilled`.
- **Weapons** share the unit's `Trash`, so weapon threads end with the unit. **Projectiles** own a separate `Trash`. Impacts go through `OnImpact` → `DoDamage`.
- Table literals in a class body are shared by every instance. Create per-instance tables in `OnCreate` (or `OnPreCreate`).

### Cached fields

Sim objects cache values as fields. Read these instead of calling the engine getter, which is slower:

| Field | Instead of | Set in |
|---|---|---|
| `self.Blueprint` | `self:GetBlueprint()` | `OnPreCreate` (units), `OnCreate` (weapons, projectiles, props) |
| `self.Army` | `self:GetArmy()` | `OnPreCreate` (units), `OnCreate` (weapons, projectiles) |
| `self.Brain` | `self:GetAIBrain()` | `OnPreCreate` (units), `OnCreate` (weapons) |
| `self.EntityId` | `self:GetEntityId()` | `OnPreCreate` (units), `OnCreate` (props) |
| `self.UnitId` | `self:GetUnitId()` | `OnPreCreate` (units) |
| `self.Layer` | `self:GetCurrentLayer()` | `OnLayerChange` (units) |
| `self.Launcher` | `self:GetLauncher()` | `OnCreate` (projectiles) |

## Threads

- `self:ForkThread(fn, ...)` on units, weapons and projectiles adds the thread to `self.Trash`, so it is killed on destroy. A bare `ForkThread` is not cleaned up.
- After `WaitTicks`, `WaitSeconds` or `WaitFor`, the entity may be gone. Check `IsDestroyed(self)` before calling engine methods on it. Examples: `DisabledWhileReloadingThread` in [weapon.lua](weapon.lua), `RetargetThread` in [Projectile.lua](Projectile.lua).
- Never keep a cached vector (such as the `cachedPosition` argument of `Projectile.DoDamage`) across a wait or pass it to a thread. It is overwritten by the next call.

### Order within a tick

From `Sim::AdvanceBeat` in the [faf-re](https://github.com/Draiget/faf-re) decompilation:

1. Player commands for the tick, including `SimCallback` handlers.
2. Each army's tick, in army order: platoon cleanup, economy, then weapon targeting and firing (`OnGotTarget`, `OnLostTarget`, `OnFire`). Weapons fire before unit orders run.
3. Unit command tasks: script task `TaskTick`, build and reclaim callbacks.
4. Lua threads: everything started with `ForkThread`, including state `Main` threads.
5. Entity ticks: motion, projectile collisions and impacts, and the damage and kills they cause (`OnImpact`, `OnDamage`, `OnKilled`, `OnLayerChange`).
6. Intel: one army per tick updates its blips (`OnIntelChange`, and `OnDetectedBy` in [../defaultcomponents.lua](../defaultcomponents.lua) `IntelComponent`).
7. Weapon cleanup for units killed this tick, then `OnDestroy` for every entity `Destroy()`ed this tick.
8. Sync to the UI. The engine deletes destroyed entities here, so `IsDestroyed` is true from the next tick.

A `ForkThread` from steps 1 to 4 runs in the same tick, because new threads go to the end of the thread list. One from step 5 or later first runs next tick. `WaitTicks(n)` with `n >= 2` waits `n - 1` ticks, and `WaitTicks(1)` waits 1. `WaitTicks` with 0 or less raises an error, and without an argument it ends the thread. `WaitSeconds` adds 1 to make up for that. For an example of the order mattering, see the 1-tick gap between salvos at `RackSalvoFireReadyState` in [DefaultProjectileWeapon.lua](weapons/DefaultProjectileWeapon.lua).

### Destroyed checks

- `unit:BeenDestroyed()` is true as soon as `Destroy()` is called.
- `unit.Dead` is set by `Kill` before `OnKilled` runs. A unit destroyed without being killed (reclaimed, cancelled, `Destroy()` from script) gets it in `OnDestroy` at step 7.
- `IsDestroyed(obj)` is true once the engine deletes the C object at step 8, and accepts `nil`.

These aren't interchangeable: Lua running later in the tick of a direct `Destroy()` sees `BeenDestroyed()` true while `.Dead` and `IsDestroyed` are still false. From the next tick on, all three are true.

Engine methods keep working until step 8, then error with "Game object has been destroyed". `BeenDestroyed()` itself is safe on a deleted entity, but not on `nil`. Use:

- `BeenDestroyed()` to skip work on an entity that is going away, including one destroyed earlier this tick. Effects, threads or orders started on it are lost at the end of the tick.
- `.Dead` to check whether a unit was killed.
- `IsDestroyed(obj)` before calling methods after a wait, and on values that may be `nil`.

## States

`State { ... }` and `ChangeState(self, self.SomeState)` are defined in [../system/class.lua](../system/class.lua). `ChangeState` calls `OnExitState`, swaps the instance's metatable to the state, calls `OnEnterState`, then forks the state's `Main` and kills the previous `Main` thread. Methods and fields defined in a state override the class's while it is active, e.g. each rack salvo state in [weapons/DefaultProjectileWeapon.lua](weapons/DefaultProjectileWeapon.lua) sets its own `StateName`. Other examples: `IdleState`, `WorkingState` and `DeadState` in [Unit.lua](Unit.lua), and the shield states in [../shield.lua](../shield.lua).

## Damage and buffs

- [Buff.lua](Buff.lua) applies buffs: `ApplyBuff`, `RemoveBuff`, `HasBuff`. Buffs are declared with `BuffBlueprint { ... }` in [BuffDefinitions.lua](BuffDefinitions.lua), [AdjacencyBuffs.lua](AdjacencyBuffs.lua), [CheatBuffs.lua](CheatBuffs.lua) and [OpBuffDefinitions.lua](OpBuffDefinitions.lua). Weapon blueprint `Buffs` travel with the damage table and apply on hit.
- A weapon builds a damage table from its blueprint and caches it ([weapon.lua](weapon.lua) `GetDamageTable`). Projectiles use it as the metatable of their `DamageData`. Change damage through `AddDamageMod`, `AddDamageRadiusMod`, `DisableBuff` or `ReEnableBuff`, which invalidate the cache. Fields without such a function are changed by editing the cached table directly.
- [Projectile.lua](Projectile.lua) `DoDamage` calls the engine's `Damage` / `DamageArea`, which call the target's `OnDamage`. On units, `OnDamage` routes to an active personal shield or to `DoTakeDamage`.
- `DamageArea` lets enemy bubble shields absorb damage through `OnGetDamageAbsorption` in [../shield.lua](../shield.lua).
- Damage over time runs in threads from [DefaultDamage.lua](DefaultDamage.lua) (`UnitDoTThread`, `AreaDoTThread`).

## Other subfolders

| Folder | Contents |
|---|---|
| [commands/](commands/) | Multi-unit orders (copy and distribute queue, ringing, self-destruct, load in transport). Called from [../SimCallbacks.lua](../SimCallbacks.lua) |
| [collisionBeams/](collisionBeams/) | Collision beam classes used by beam weapons |
| [VictoryCondition/](VictoryCondition/) | Victory condition classes |
| `NavGenerator.lua`, `NavUtils.lua`, `NavDebug/` | Navigation mesh and pathing queries |
| `*Manager.lua`, `Builder.lua` | AI managers. The rest of the AI is in `lua/AI/` and `lua/aibrains/` |

## Script tasks

[tasks/](tasks/) holds `ScriptTask` subclasses ([ScriptTask.lua](ScriptTask.lua)): custom orders. A UI command mode with `name = 'RULEUCC_Script'`, or `IssueScript` in sim code, names the task with `TaskName`, and the engine calls its `TaskTick`. The returned `TASKSTATUS` ([ScriptTask.lua](ScriptTask.lua) documents each value) says how many ticks to wait before the next call, or that the task is done. Unlike a sim callback, the order's target goes through the engine's order system. Script orders are never drawn on the command graph, so they suit instant orders and orders that don't need a command-graph line. Examples: attack move (`OnScriptIssued` in [commandmode.lua](../ui/game/commandmode.lua)) and [EnhanceTask.lua](tasks/EnhanceTask.lua). There are few examples and mods can't easily add tasks, so treat new script tasks as experimental.
