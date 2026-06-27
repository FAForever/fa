# Derived models

Read-only reactive **projections** of the authoritative lobby state. The three models
([`CustomLobbyLaunchModel`](/lua/ui/lobby/customlobby/models/CustomLobbyLaunchModel.lua) / `SessionModel` / `LocalModel`) hold
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
  (`CustomLobby<Thing>DerivedModel`), and the file lives here in `models/derived/`, so it is unmistakable at
  the import site and in the type that this is derived state — not something a controller writes.
- **Lifetime.** Each is a `ClassSimple` implementing `Destroyable`, registered in the session trash
  (see [`../../CustomLobbySession`](/lua/ui/lobby/customlobby/customlobbysession.lua)) on first access,
  so one `CustomLobbySession.Teardown()` frees its LazyVar(s) and severs its subscriptions instead of
  leaking them into the persistent front-end state for the whole match. Each owns a `Trash` that holds
  its published LazyVar(s) **and** its observer(s); `Destroy` is idempotent (`Destroyed` guard),
  `Trash:Destroy()`s, and nils the module `Instance` so the next access rebuilds. Observers are pinned
  on the instance (`self.Observer` / `self.Observers`) *and* added to the trash — the trash is
  weak-valued, so the trash alone wouldn't keep them alive. The map catalog
  ([`../../mapselect/CustomLobbyMapCatalog`](/lua/ui/lobby/customlobby/mapselect/CustomLobbyMapCatalog.lua))
  is the original worked example; see [`../../design/session-trashbag-teardown.md`](/lua/ui/lobby/customlobby/design/session-trashbag-teardown.md).

## Files

| File | Derives | From | Read by |
|------|---------|------|---------|
| [CustomLobbyScenarioDerivedModel.lua](CustomLobbyScenarioDerivedModel.lua) | the resolved `Scenario` (info for the texture + extracted save markers `Spawns`/`MassPoints`/`HydroPoints`/`Wrecks` + `MaxDimension`/`ArmyCount`/`Name`/`Size`/`Version`) | the launch model's `ScenarioFile` | the bound [`CustomLobbyMapPreview`](/lua/ui/lobby/customlobby/CustomLobbyMapPreview.lua), the [`config/CustomLobbyConfigInterface`](/lua/ui/lobby/customlobby/config/CustomLobbyConfigInterface.lua) facts line, [`CustomLobbyRules`](/lua/ui/lobby/customlobby/CustomLobbyRules.lua) (map size + start spots) |
| [CustomLobbyOptionsDerivedModel.lua](CustomLobbyOptionsDerivedModel.lua) | the `Options` view: options split into **Categories** lobby / scenario / mods, each option **enriched** (label, help, chosen value-key + display, `IsDefault`, origin), plus `NonDefaultCount`. **Two dedups:** a *disk* dedup (the `SchemaKey`-keyed schema cache, so a value change doesn't re-read the option files) and a *publish* dedup (`table.equal` over the scenario file + mod set + option values, so an unrelated launch-info rebroadcast doesn't rebuild the panel). | the launch model's `GameOptions` + `GameMods` and the scenario derived model (map file + name); the scenario `_options.lua` schema via the catalog's `LoadOptions`, the lobby/mod schema + value interpretation via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua) | the [`config/CustomLobbyOptionsPanel`](/lua/ui/lobby/customlobby/config/CustomLobbyOptionsPanel.lua) and the Options tab badge in [`config/CustomLobbyConfigInterface`](/lua/ui/lobby/customlobby/config/CustomLobbyConfigInterface.lua) |
| [CustomLobbyRestrictionsDerivedModel.lua](CustomLobbyRestrictionsDerivedModel.lua) | the `Restrictions` view: each active **preset** key **enriched** with its `Name` / `Icon` / `Tooltip`, plus `Count`. De-duped by an order-independent set signature (`table.concat(table.sorted(keys), …)`). Keys can also be **specific unit ids**, but enriching those (name + icon) is **parked** — see [TODO.md](/lua/ui/lobby/customlobby/TODO.md) — so a unit id currently shows as its raw id. | the launch model's `Restrictions`, joined with the preset table in [`/lua/ui/lobby/unitsrestrictions.lua`](/lua/ui/lobby/unitsrestrictions.lua) | the [`config/CustomLobbyUnitsPanel`](/lua/ui/lobby/customlobby/config/CustomLobbyUnitsPanel.lua) (icon + name rows) and the Restrictions tab badge |
| [CustomLobbyModsDerivedModel.lua](CustomLobbyModsDerivedModel.lua) | the `Mods` view: enabled mods split into **game** (sim) + **ui** `Groups`, each mod **enriched** (`Name` / `Icon` / `Author` / `Version` / `UiOnly`), plus `GameCount` / `UiCount`. No disk load (`Mods.AllMods()` is synchronous). De-duped by an order-independent set signature (`table.concatkeys` over the game + ui sets). | the launch model's `GameMods` (synced sim mods) + `ModUtilities.GetSelectedUIMods()` (per-peer prefs, re-read on each sim-mod change), joined with `/lua/mods.lua` | the [`config/CustomLobbyModsPanel`](/lua/ui/lobby/customlobby/config/CustomLobbyModsPanel.lua) (icon + name rows) and the Mods tab badge (`sim / ui`) |
| [CustomLobbySlotsDerivedModel.lua](CustomLobbySlotsDerivedModel.lua) | **two faces** over the seating board. `Slots` — a **lookup table** (one entry per slot, 1..MaxSlots): each seat merges its **player** (resolved `PlayerView`), scenario **placement** (`StartSpot` + map `Position`), **closed** flag, **locked** flag (the gold lock stripe / auto-balance pin), **CPU benchmark** (`CpuView` + raw `Benchmark`/`UnitCap` for the popover), and its binary auto-team **`Side`** (1/2/false). `Teams` — the **aggregate** (`Mode` / `Labels` / `Resolved` / per-side rating `Totals`). The side rule stays in [`CustomLobbyRules`](/lua/ui/lobby/customlobby/CustomLobbyRules.lua) (`BuildSideResolver`); this model *applies* it once so the two-column layout reads `entry.Side` and the score reads `Teams`. Each face deduped by its **own** signature, so a rating change re-fires `Teams` but not the rows. | the launch model's `Players[slot]` + `GameOptions` (the AutoTeams mode), the session model's `ClosedSlots`, the local model's `CpuBenchmarks` (per-peer, **not launched**), and the scenario derived model (placement + map size, via `CustomLobbyRules`) | the [`slots/CustomLobbySlotBase`](/lua/ui/lobby/customlobby/slots/CustomLobbySlotBase.lua) (`Slots`), the [`slots/twocolumn/CustomLobbyTwoColumnSlots`](/lua/ui/lobby/customlobby/slots/twocolumn/CustomLobbyTwoColumnSlots.lua) (`entry.Side`) and [`CustomLobbyTeamScore`](/lua/ui/lobby/customlobby/CustomLobbyTeamScore.lua) (`Teams`) |

The options model also shows a second trait worth copying: it **caches the expensive part**. Gathering
the option schema is disk work (the map's `_options.lua` `doscript`, mod option files) and only changes
when the scenario / mod set changes, so it is rebuilt only when those inputs change (keyed) — a value
edit just re-enriches the cached schema. (Composing derived models is fine too: both the options model
and the slots model read the scenario *from the scenario derived model*, not by re-resolving the file.)

The slots model shows a third variation: **one table rebuilt whole vs. a var per item.** The other
models expose a list/bundle, but the slots model is keyed by slot index because a seat's CPU bar is
styled against the unit cap, which depends on the *total* seated count — so filling one seat must
restyle every seat. A per-slot var would leave the others stale (only the changed seat's var fires); a
single table rebuilt whole keeps the board consistent. The de-dup then compares a **signature** of the
rendered fields so an unchanged rebroadcast still re-publishes nothing.
