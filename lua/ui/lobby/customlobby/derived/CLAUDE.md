# Derived models

Read-only reactive **projections** of the authoritative lobby state. The three models
([`../CustomLobbyLaunchModel`](../CustomLobbyLaunchModel.lua) / `SessionModel` / `LocalModel`) hold
the state in its most **compact** form — a map is a single `ScenarioFile`, sim mods are a set of
UUIDs, restrictions are preset keys. Turning those into something a view can actually render (the
map's name / size / start spots / texture, a mod's title + icon + dependencies, a restriction's
display name) takes work — disk loads, catalog lookups, lookups against reference data.

A **derived model** does that work **once** and exposes the result reactively, so every consumer
just reads the field it needs instead of each re-resolving the compact value. It is the "fishing"
layer between the compact synced fields and the views.

## The contract

- **Derived, never authoritative.** A derived model is a pure function of the models it reads. It is
  **read-only**: it has no write helpers, and the **controller never touches it**. To change what it
  holds, change the *source field* it derives from (the controller writes that). This keeps the
  authoritative model the single source of truth and the derived model a cache/projection.
- **Reactive + deduped.** It subscribes to its source field(s) and republishes a resolved bundle via
  a `LazyVar`. Because `LazyVar:Set` always re-fires (and the host rebroadcasts whole snapshots,
  re-setting fields to unchanged values), the internal observer **dedups by key** — the same input
  arriving twice is a no-op, so downstream views don't needlessly reload. Consumers subscribe to the
  bundle var (`Derive`) or pull the current value (`GetScenario()` etc.).
- **Not on the wire.** Purely local reactive reference data, like the catalogs — every peer derives
  its own from the synced compact fields.
- **Naming.** File **and** class carry the `DerivedModel` suffix
  (`CustomLobby<Thing>DerivedModel`), and the file lives here in `derived/`, so it is unmistakable at
  the import site and in the type that this is derived state — not something a controller writes.
- **Lifetime.** A module-level `ModelInstance` singleton (auto-created in `GetSingleton`) with the
  standard hot-reload hooks. The internal observer is pinned on the model table so it isn't GC'd.

## Files

| File | Derives | From | Read by |
|------|---------|------|---------|
| [CustomLobbyScenarioDerivedModel.lua](CustomLobbyScenarioDerivedModel.lua) | the resolved `Scenario` (info for the texture + extracted save markers `Spawns`/`MassPoints`/`HydroPoints`/`Wrecks` + `MaxDimension`/`ArmyCount`/`Name`/`Size`/`Version`) | the launch model's `ScenarioFile` | the bound [`../CustomLobbyMapPreview`](../CustomLobbyMapPreview.lua), the [`../config/CustomLobbyConfigInterface`](../config/CustomLobbyConfigInterface.lua) facts line, [`../CustomLobbyRules`](../CustomLobbyRules.lua) (map size + start spots) |
| [CustomLobbyOptionsDerivedModel.lua](CustomLobbyOptionsDerivedModel.lua) | the `Options` view: options split into **Categories** lobby / scenario / mods, each option **enriched** (label, help, chosen value-key + display, `IsDefault`, origin), plus `NonDefaultCount` | the launch model's `GameOptions` + `GameMods` and the scenario derived model (map file + name); the scenario `_options.lua` schema via the catalog's `LoadOptions`, the lobby/mod schema + value interpretation via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua) | the [`../config/CustomLobbyOptionsPanel`](../config/CustomLobbyOptionsPanel.lua) and the Options tab badge in [`../config/CustomLobbyConfigInterface`](../config/CustomLobbyConfigInterface.lua) |
| [CustomLobbyRestrictionsDerivedModel.lua](CustomLobbyRestrictionsDerivedModel.lua) | the `Restrictions` view: each active **preset** key **enriched** with its `Name` / `Icon` / `Tooltip`, plus `Count`. De-duped by set (length + sorted compare). Keys can also be **specific unit ids**, but enriching those (name + icon) is **parked** — see [../TODO.md](../TODO.md) — so a unit id currently shows as its raw id. | the launch model's `Restrictions`, joined with the preset table in [`/lua/ui/lobby/unitsrestrictions.lua`](/lua/ui/lobby/unitsrestrictions.lua) | the [`../config/CustomLobbyUnitsPanel`](../config/CustomLobbyUnitsPanel.lua) (icon + name rows) and the Restrictions tab badge |
| [CustomLobbyModsDerivedModel.lua](CustomLobbyModsDerivedModel.lua) | the `Mods` view: enabled mods split into **game** (sim) + **ui** `Groups`, each mod **enriched** (`Name` / `Icon` / `Author` / `Version` / `UiOnly`), plus `GameCount` / `UiCount`. The simplest model — `Mods.AllMods()` is available synchronously, so no disk load. | the launch model's `GameMods` (synced sim mods) + `ModUtilities.GetSelectedUIMods()` (per-peer prefs, re-read on each sim-mod change), joined with `/lua/mods.lua` | the [`../config/CustomLobbyModsPanel`](../config/CustomLobbyModsPanel.lua) (icon + name rows) and the Mods tab badge (`sim / ui`) |

The options model also shows a second trait worth copying: it **caches the expensive part**. Gathering
the option schema is disk work (the map's `_options.lua` `doscript`, mod option files) and only changes
when the scenario / mod set changes, so it is rebuilt only when those inputs change (keyed) — a value
edit just re-enriches the cached schema. (Composing derived models is fine too: it reads the scenario
*from the scenario derived model*, not by re-resolving the file.)

**Planned sibling** (same shape): a slots-info derived model (the seated players projected into the
shapes the slot layouts / team score want).
