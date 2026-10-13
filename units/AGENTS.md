# Units

Unit blueprints and unit scripts. Read the root [AGENTS.md](../AGENTS.md) first: [Classes](../AGENTS.md#classes), [Blueprints](../AGENTS.md#blueprints) and [Gotchas](../AGENTS.md#gotchas) apply here and are not repeated.

## Folder layout

- `units/<ID>/<ID>_unit.bp`: the unit blueprint. The unit ID is the lowercased file name without `_unit.bp` (`SetShortId` in [Blueprints.lua](../lua/system/Blueprints.lua)).
- `units/<ID>/<ID>_script.lua`: the unit class.
- Meshes (`.scm`), animations (`.sca`), textures (`.dds`) and extra mesh blueprints (`<ID>_PhaseShield_mesh.bp`) appear only when FAF adds or changes them. Everything else comes from the mounted `units.scd` archive, so a path in a blueprint without a matching file here is normal. Some folders hold only a texture override (e.g. `URA0310`).
- Folder names are uppercase, and some file names vary in case (`XRL0302_Script.lua`). The engine's filesystem is case-insensitive.

## Unit IDs

The letters are prefix, faction, then type. Examples: `UEL0001` (UEF land ACU), `XSL0001` (Seraphim ACU), `UEB0101` (UEF T1 land factory).

| Position | Values |
|---|---|
| Prefix | `u` original game, `x` Forged Alliance. Other prefixes (`d`, `z`, `o`) mark later or special-purpose units |
| Faction | `a` Aeon, `e` UEF, `r` Cybran, `s` Seraphim |
| Type | `l` land, `a` air, `s` sea, `b` building, `c` civilian |

The digits loosely group units by role and tech level, with many exceptions (`UEL0201`, the Striker, is `TECH1`). Read `Categories`, not the ID.

## Blueprints

A `.bp` file is a call to `UnitBlueprint { ... }`. Field types and docs are in [engine/Core/Blueprints/UnitBlueprint.lua](../engine/Core/Blueprints/UnitBlueprint.lua). Main sections: `General` (`FactionName`, `CommandCaps`, `UnitName`), `Categories`, `Defense` (`Health`, `MaxHealth`, `ArmorType`, `Shield`), `Economy` (costs, `BuildTime`, `BuildRate`), `Physics` (`MotionType`, speeds), `Intel`, `Weapon` (array of weapons, each with a `Label`), `Display`, `Audio`, `Wreckage`, `Enhancements`.

Display strings use `<LOC key>fallback`. The keys live in [loc/US/strings_db.lua](../loc/US/strings_db.lua) (`url0107_name`, `url0107_desc`), and the longer unit descriptions in [lua/ui/help/unitdescription.lua](../lua/ui/help/unitdescription.lua).

### Values computed at load

[Blueprints.lua](../lua/system/Blueprints.lua) and the `blueprints-*.lua` files overwrite or add these. Don't hand-tune them in a blueprint:

- `BlueprintId`, `CategoriesHash`, `TechCategory`, `LayerCategory`, `FactionCategory`, `SizeVolume`, `VetThresholds`, `VetEnabled`, `Intel.State`.
- `OVERLAY*` and `WEAK*` categories, from weapon range categories and DPS ([blueprints-units.lua](../lua/system/blueprints-units.lua)). Many blueprints already list `OVERLAY*` categories, which is harmless. The range overlays draw only for units with the matching `OVERLAY*` category ([rangeoverlayparams.lua](../lua/ui/game/rangeoverlayparams.lua)).
- `Defense.*ThreatLevel`, unless `Defense.SkipDynamicThreatCalculations` is set ([blueprints-ai.lua](../lua/system/blueprints-ai.lua)).
- `Display.Mesh.LODs[*].LODCutoff`, from the unit size ([blueprints-lod.lua](../lua/system/blueprints-lod.lua)).
- Defaults when unset: `AI.GuardScanRadius`, `Physics.TransportSpeedReduction`, `Interface.HelpText`, and the weapon fields `TargetCheckInterval`, `TrackingRadius` and `AlwaysRecheckTarget` ([blueprints-weapons.lua](../lua/system/blueprints-weapons.lua)). Setting them in the blueprint overrides the default.
- `Footprint` of most air units (not experimentals or transports), set by unit type and capped by tech level.

### Categories

`Categories` is an array of uppercase strings. Sim code tests them through `categories.X` expressions and `EntityCategoryContains`, and blueprint code through `bp.CategoriesHash.X`. Build options come from `BUILTBYTIER1FACTORY`-style categories matched against the builder's `Economy.BuildableCategory`. `AddCategories` / `DelCategories` exist for mods and are removed at load.

### Formatting

Most blueprints were machine-formatted in [#6272](https://github.com/FAForever/fa/pull/6272): keys in alphabetical order (with `Description` usually first), strings in double quotes, one `Sound { ... }` per line in `Audio`. Match the file you edit rather than reformatting it. Write rates of fire as `RateOfFire = 10/3, --10/integer interval in ticks`. The weapon fires every 3 ticks, and the test below rejects values the tick rate can't produce.

## Scripts

```lua
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon

---@class URL0107 : CWalkingLandUnit
URL0107 = ClassUnit(CWalkingLandUnit) {
    Weapons = {
        LaserArms = ClassWeapon(CDFLaserHeavyWeapon) {},
    },
}
TypeClass = URL0107
```

- Inherit from the faction class libraries: `terranunits.lua`, `aeonunits.lua`, `cybranunits.lua`, `seraphimunits.lua` (or [defaultunits.lua](../lua/defaultunits.lua)), with weapons from the matching `*weapons.lua`.
- Keys of `Weapons` are blueprint weapon `Label`s. A blueprint weapon without a matching entry uses the base `Weapon` class (`GetWeaponClass` in [Unit.lua](../lua/sim/Unit.lua)).
- Read blueprint values through `self.Blueprint`. Newer scripts upvalue engine functions at file scope under a `-- upvalue for performance` comment (`local TrashBagAdd = TrashBag.Add`, see [UAB1103_script.lua](UAB1103/UAB1103_script.lua)).
- A few legacy scripts still use `Class(...)` instead of `ClassUnit(...)`. Use `ClassUnit` in new code.

## Balance and fix changes

A blueprint or script change can be a balance change, a bug fix, or both. A fix that changes gameplay noticeably (for example, how shields repair) gets a changelog snippet in both the `balance` and `fix` sections, so competitive players see it. Balance changes need balance team sign-off ([Branches, PRs, changelog](../AGENTS.md#branches-prs-changelog)). Behavior shared by several units goes in the shared class in `lua/` or `lua/sim/`, not in each unit script.

## Tests

- [tests/run-syntax-test.sh](../tests/run-syntax-test.sh) runs `luac -p` over every `.bp` file.
- [tests/run-blueprint-tests.sh](../tests/run-blueprint-tests.sh) runs [tests/blueprint/unit.spec.lua](../tests/blueprint/unit.spec.lua), which checks:
  - `VisionRadius` is a multiple of 2, and the other intel and stealth radii are multiples of 4 (the intel grid cell size).
  - `RadarRadius` differs from `SonarRadius`, `RadarStealthFieldRadius`, `SonarStealthFieldRadius` and `CloakFieldRadius`, so the radar ring doesn't hide the others.
  - `RateOfFire` and enhancement `NewRateOfFire` match a value the tick rate can produce. Weapons with `DummyWeapon` are skipped.
- That spec keys units by `Description`, so units sharing a description (every "Land Factory") are only tested once.

## Unit data tooling

- [wiki/](../wiki/) holds the config for generating the unit wiki with [BrewWikiGen](https://github.com/The-Balthazar/BrewWikiGen) ([wiki-generate-blueprints.yaml](../.github/workflows/wiki-generate-blueprints.yaml)).
- [bake-blueprints.yaml](../.github/workflows/bake-blueprints.yaml) uses BrewWikiGen to bake processed values into blueprint files. Only a props baking script exists so far.
- [unitdb-update.yaml](../.github/workflows/unitdb-update.yaml) refreshes [unitdb.faforever.com](https://unitdb.faforever.com) on each push to `deploy/faf`.
