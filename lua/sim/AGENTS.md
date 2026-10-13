# Sim: Units, Weapons and Projectiles

This guide covers working with simulation code: the class chains for units, weapons and projectiles, their lifecycle callbacks, threads, states, buffs and damage. It extends the root [AGENTS.md](../../AGENTS.md). Read its [Determinism and desyncs](../../AGENTS.md#determinism-and-desyncs), [Classes](../../AGENTS.md#classes) and [Performance](../../AGENTS.md#performance) sections first.

## Sim code outside this folder

`lua/sim/` holds the base classes, but the `/lua` root mixes sim and UI files. A sim change often spans folders:

| Location | Contents |
|---|---|
| [../defaultunits.lua](../defaultunits.lua), [defaultweapons.lua](defaultweapons.lua), [DefaultProjectiles.lua](DefaultProjectiles.lua) | Re-export hubs for the classes in `units/`, `weapons/` and `projectiles/`. Kept for backwards compatibility with mods and unit scripts |
| `../aeonunits.lua`, `../cybranweapons.lua`, `../seraphimprojectiles.lua`, … | Faction libraries. The unit and weapon ones re-export `units/<faction>/` and `weapons/<faction>/`. Aeon projectiles re-export `projectiles/aeon/`. The other projectile libraries define their classes inline |
| [../aibrain.lua](../aibrain.lua) | `AIBrain`, one per army. Unit events such as `OnUnitKilled` and `OnUnitStopBeingBuilt` are forwarded to it |
| [../SimCallbacks.lua](../SimCallbacks.lua), [../SimSync.lua](../SimSync.lua) | UI to sim and sim to UI boundaries. `SecureUnits` filters unit lists sent by a player |
| [../SimUtils.lua](../SimUtils.lua) | Unit transfer between armies (`TransferUnitsOwnership`) |
| [../shield.lua](../shield.lua), [../defaultcomponents.lua](../defaultcomponents.lua) | `Shield` classes, and the `IntelComponent` / `VeterancyComponent` mixed into `Unit` |
| [../ScenarioFramework.lua](../ScenarioFramework.lua), [ScenarioUtilities.lua](ScenarioUtilities.lua) | Map and campaign scripting helpers |
| `/units/<ID>/<ID>_script.lua`, `/projectiles/<Name>/<Name>_script.lua` | Per-unit and per-projectile classes. Each sets `TypeClass` |

## Class chains

Put a change on the lowest class that covers every unit it should affect. Changes in [Unit.lua](Unit.lua) reach every unit, including mod units.

- **Units**: [Unit.lua](Unit.lua) → [units/](units/) base classes ([MobileUnit](units/MobileUnit.lua) → [WalkingLandUnit](units/WalkingLandUnit.lua) → [CommandUnit](units/CommandUnit.lua) → [ACUUnit](units/ACUUnit.lua); [StructureUnit](units/StructureUnit.lua) → [FactoryUnit](units/FactoryUnit.lua); …) → faction classes in `units/<faction>/` (e.g. [TLandUnit](units/uef/TLandUnit.lua)) → `<ID>_script.lua`.
- **Weapons**: [weapon.lua](weapon.lua) → [weapons/](weapons/) (`DefaultProjectileWeapon`, `DefaultBeamWeapon`, `BareBonesWeapon`, …) → `weapons/<faction>/` → the `Weapons` table of a unit script, keyed by the blueprint weapon `Label`.
- **Projectiles**: [Projectile.lua](Projectile.lua) → [projectiles/](projectiles/) (`EmitterProjectile`, `SinglePolyTrailProjectile`, `NukeProjectile`, …) → `../<faction>projectiles.lua` → `<Name>_script.lua`.
- Mixins go in `components/` subfolders ([units/components/](units/components/), [projectiles/components/](projectiles/components/)) and are passed as extra bases: `ClassUnit(Unit, TreadComponent)`.
- Import a base class from its own file in new code. Unit scripts import from the faction libraries, so keep those exports when moving a class.

## Lifecycle

- **Unit creation**: `OnPreCreate` creates `self.Trash` and caches `Blueprint`, `EntityId`, `Army`, `UnitId` and `Brain` ([Unit.lua](Unit.lua) `OnPreCreate`). Weapons run their `OnCreate` before the unit's `OnCreate`, so anything a weapon reads from the unit must be set in `OnPreCreate`. `OnLayerChange` also runs before `OnCreate`, with `old == 'None'`, and caches `self.Layer`.
- **Construction**: `OnStartBeingBuilt` → `OnBeingBuiltProgress` → `OnStopBeingBuilt` (or `OnFailedToBeBuilt`). `OnStopBeingBuilt` starts idle effects, intel and preset enhancements.
- **Death**: `DoTakeDamage` calls `Kill` at zero health → `OnKilled` (death weapon, veterancy, brain callback) forks `DeathThread` → `DestroyUnit` creates the wreck and calls `Destroy` → `OnDestroy` destroys `self.Trash` and enters `DeadState`. `Destroy` without `Kill` skips `OnKilled`.
- **Weapons** ([weapon.lua](weapon.lua) `OnCreate`) cache `Blueprint`, `Brain` and `Army`, and share the unit's `Trash`. Weapon threads end with the unit.
- **Projectiles** ([Projectile.lua](Projectile.lua) `OnCreate`) cache `Blueprint`, `Army` and `Launcher` and own a separate `Trash`. Impacts go through `OnImpact` → `DoDamage`.
- Read the cached fields (`self.Blueprint`, `self.Army`, `self.Layer`) instead of calling the matching engine getters.
- Table literals in a class body are shared by every instance. Create per-instance tables in `OnCreate` (or `OnPreCreate`).

## Threads

- `self:ForkThread(fn, ...)` on units, weapons and projectiles adds the thread to `self.Trash`, so it is killed on destroy. A bare `ForkThread` is not cleaned up.
- After `WaitTicks`, `WaitSeconds` or `WaitFor`, the entity may be gone. Check `IsDestroyed(self)` before calling engine methods on it. Examples: `DisabledWhileReloadingThread` in [weapon.lua](weapon.lua), `RetargetThread` in [Projectile.lua](Projectile.lua).
- Never keep a cached vector (such as the `cachedPosition` argument of `Projectile.DoDamage`) across a wait or pass it to a thread. It is overwritten by the next call.

### Order within a tick

Read from the [faf-re](https://github.com/Draiget/faf-re) decompilation (`Sim::AdvanceBeat`), so treat it as evidence:

1. Player commands for the tick, including `SimCallback` handlers.
2. Each army's tick, in army order: platoon cleanup, economy, then weapon targeting and firing (`OnGotTarget`, `OnLostTarget`, `OnFire`). Weapons fire before unit orders run.
3. Unit command tasks: script task `TaskTick`, build and reclaim callbacks.
4. Lua threads: everything started with `ForkThread`, including state `Main` threads.
5. Entity ticks: motion, projectile collisions and impacts, and the damage and kills they cause (`OnImpact`, `OnDamage`, `OnKilled`, `OnLayerChange`).
6. Intel: one army per tick updates its blips, spreading the cost over as many ticks as there are armies. That army gets its `OnIntelChange` callbacks, and units it gets new blips for get `OnDetectedBy` ([../defaultcomponents.lua](../defaultcomponents.lua) `IntelComponent`).
7. Weapon cleanup for units killed this tick, then `OnDestroy` for every entity `Destroy()`ed this tick.
8. Sync to the UI. The engine deletes destroyed entities here, so `IsDestroyed` is true from the next tick.

A `ForkThread` from steps 1 to 4 runs in the same tick, because new threads go to the end of the thread list. One from step 5 or later first runs next tick. `WaitTicks(n)` with `n >= 2` waits `n - 1` ticks, `WaitTicks(1)` waits 1, and `WaitTicks(0)` continues at once. `WaitSeconds` adds 1 to make up for that.

The order explains the 1-tick gaps in weapon fire cycles. The engine's fire task (step 2) doesn't fire while the unit is busy. [DefaultProjectileWeapon.lua](weapons/DefaultProjectileWeapon.lua) sets busy while firing and reloading, and clears it in `RackSalvoFireReadyState.Main` (step 4). So when the fire cooldown ends during a salvo or reload, the next `OnFire` comes one tick after the weapon is ready again. [unitviewdetail.lua](../ui/game/unitviewdetail.lua) adds that tick when it estimates DPS.

## States

`State { ... }` and `ChangeState(self, self.SomeState)` are defined in [../system/class.lua](../system/class.lua). `ChangeState` calls `OnExitState`, swaps the instance's metatable to the state, calls `OnEnterState`, then forks the state's `Main` and kills the previous `Main` thread. Methods and fields defined in a state override the class's while it is active, e.g. each rack salvo state in [weapons/DefaultProjectileWeapon.lua](weapons/DefaultProjectileWeapon.lua) sets its own `StateName`. Other examples: `IdleState`, `WorkingState` and `DeadState` in [Unit.lua](Unit.lua), and the shield states in [../shield.lua](../shield.lua).

## Buffs

[Buff.lua](Buff.lua) applies buffs: `ApplyBuff`, `RemoveBuff`, `HasBuff`. Buffs are declared with `BuffBlueprint { ... }` in [BuffDefinitions.lua](BuffDefinitions.lua), [AdjacencyBuffs.lua](AdjacencyBuffs.lua), [CheatBuffs.lua](CheatBuffs.lua) and [OpBuffDefinitions.lua](OpBuffDefinitions.lua). Weapon blueprint `Buffs` travel with the damage table and apply on hit.

## Damage

- A weapon builds a damage table from its blueprint and caches it ([weapon.lua](weapon.lua) `GetDamageTable`). Projectiles use it as the metatable of their `DamageData`. Change damage through `AddDamageMod`, `AddDamageRadiusMod`, `DisableBuff` or `ReEnableBuff`, which invalidate the cache. Fields without such a function are changed by editing the cached table directly.
- [Projectile.lua](Projectile.lua) `DoDamage` calls the engine's `Damage` / `DamageArea`, which call the target's `OnDamage`. On units, `OnDamage` routes to an active personal shield or to `DoTakeDamage`.
- `DamageArea` also calls `OnGetDamageAbsorption` on each enemy bubble shield that the damage sphere touches from outside, and reduces the damage to everything inside that shield by the returned amount ([../shield.lua](../shield.lua); faf-re `SIM_DoDamage`).
- Damage over time runs in threads from [DefaultDamage.lua](DefaultDamage.lua) (`UnitDoTThread`, `AreaDoTThread`).

## Other subfolders

| Folder | Contents |
|---|---|
| [commands/](commands/) | Multi-unit orders (copy and distribute queue, ringing, self-destruct, load in transport). Called from [../SimCallbacks.lua](../SimCallbacks.lua) |
| [tasks/](tasks/) | Script tasks, see below |
| [collisionBeams/](collisionBeams/) | Collision beam classes used by beam weapons |
| [VictoryCondition/](VictoryCondition/) | Victory condition classes |
| `NavGenerator.lua`, `NavUtils.lua`, `NavDebug/` | Navigation mesh and pathing queries |
| `*Manager.lua`, `Builder.lua` | AI managers. See the AI row in the root [Repository layout](../../AGENTS.md#repository-layout) |

## Script tasks

[tasks/](tasks/) holds `ScriptTask` subclasses ([ScriptTask.lua](ScriptTask.lua)): custom orders. A UI command mode with `name = 'RULEUCC_Script'`, or `IssueScript` in sim code, names the task with `TaskName`, and the engine calls its `TaskTick`. The returned `TASKSTATUS` ([ScriptTask.lua](ScriptTask.lua) documents each value) says how many ticks to wait before the next call, or that the task is done. Unlike a sim callback, the order's entity or position target goes through the engine's order system, so Lua cheats can't forge it as easily.

- The engine never draws script orders on the command graph: its graph builder skips that command type (faf-re `AddCommandQueueToCommandGraph`), so the `UNITCOMMAND_Script` entry in [commandgraphparams.lua](../ui/game/commandgraphparams.lua) has no effect. Script tasks suit instant orders and orders that don't need a command-graph line.
- Existing tasks work around this. Attack move issues a script order, then [commandmode.lua](../ui/game/commandmode.lua) `OnScriptIssued` sends the `AttackMove` sim callback, which reads the order's position and issues a real aggressive move. [EnhanceTask.lua](tasks/EnhanceTask.lua) shows progress with `SetWorkProgress` and the UI's enhancement queue.
- There are few examples and mods can't easily add tasks, so treat new script tasks as experimental.

## Testing

Write sim test procedures per [in-game-testing.md](../../in-game-testing.md): spawn units with `CreateUnitAtMouse` and run sim code with `ConExecute[[SimLua ...]]`.
