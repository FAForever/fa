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

## States

`State { ... }` and `ChangeState(self, self.SomeState)` are defined in [../system/class.lua](../system/class.lua). `ChangeState` calls `OnExitState`, swaps the instance's metatable to the state, calls `OnEnterState`, then forks the state's `Main` and kills the previous `Main` thread. Methods defined in a state override the class methods while it is active. Examples: `IdleState`, `WorkingState` and `DeadState` in [Unit.lua](Unit.lua), the rack salvo states in [weapons/DefaultProjectileWeapon.lua](weapons/DefaultProjectileWeapon.lua).

## Buffs

[Buff.lua](Buff.lua) applies buffs: `ApplyBuff`, `RemoveBuff`, `HasBuff`. Buffs are declared with `BuffBlueprint { ... }` in [BuffDefinitions.lua](BuffDefinitions.lua), [AdjacencyBuffs.lua](AdjacencyBuffs.lua), [CheatBuffs.lua](CheatBuffs.lua) and [OpBuffDefinitions.lua](OpBuffDefinitions.lua). Weapon blueprint `Buffs` travel with the damage table and apply on hit.

## Damage

- A weapon builds a damage table from its blueprint and caches it ([weapon.lua](weapon.lua) `GetDamageTable`). Projectiles use it as the metatable of their `DamageData`. Change damage through `AddDamageMod`, `AddDamageRadiusMod`, `DisableBuff` or `ReEnableBuff`, which invalidate the cache.
- [Projectile.lua](Projectile.lua) `DoDamage` calls the engine's `Damage` / `DamageArea`, which call the target's `OnDamage`. On units, `OnDamage` routes to an active personal shield or to `DoTakeDamage`.
- Damage over time runs in threads from [DefaultDamage.lua](DefaultDamage.lua) (`UnitDoTThread`, `AreaDoTThread`).

## Other subfolders

| Folder | Contents |
|---|---|
| [commands/](commands/) | Multi-unit orders (copy and distribute queue, ringing, self-destruct, load in transport). Called from [../SimCallbacks.lua](../SimCallbacks.lua) |
| [tasks/](tasks/) | `ScriptTask` subclasses ([ScriptTask.lua](ScriptTask.lua)) run by `IssueScript` or a `RULEUCC_Script` order, selected by `TaskName`. `TaskTick` returns a `TASKSTATUS` value |
| [collisionBeams/](collisionBeams/) | Collision beam classes used by beam weapons |
| [VictoryCondition/](VictoryCondition/) | Victory condition classes |
| `NavGenerator.lua`, `NavUtils.lua`, `NavDebug/` | Navigation mesh and pathing queries |
| `*Manager.lua`, `Builder.lua` | AI managers. See the AI row in the root [Repository layout](../../AGENTS.md#repository-layout) |

## Testing

Write sim test procedures per [in-game-testing.md](../../in-game-testing.md): spawn units with `CreateUnitAtMouse` and run sim code with `ConExecute[[SimLua ...]]`.
