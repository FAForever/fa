# Custom lobby — TODO / parked work

Things deliberately deferred, with enough context to pick them up without re-deriving the problem.

## Enrich specific-unit restrictions (name + icon) in the Restrictions panel

**Status:** parked — needs a decision on how to manage blueprint-loading complexity in the front-end.

### What works today

The launch model's `Restrictions` is a `string[]` of keys. A key is one of two kinds:

- a **preset** key (e.g. `"T3"`, `"AIR"`) — fully resolved by
  [derived/CustomLobbyRestrictionsDerivedModel.lua](derived/CustomLobbyRestrictionsDerivedModel.lua)
  against [`/lua/ui/lobby/unitsrestrictions.lua`](/lua/ui/lobby/unitsrestrictions.lua) → name / icon / tooltip.
- a **specific unit id** (e.g. `"uel0201"`) — **not** enriched yet; it currently shows as its raw id
  (no icon, no name) via the fallback branch in `EnrichKey`.

The goal: a unit-id restriction should show the unit's **icon + name** (+ tooltip), like the preset rows,
so it's easy to read. The panel already renders `{ Name, Icon, Tooltip }` generically — so this is purely a
model-side resolution problem; **no panel change is needed** once the model can produce those fields.

### The complexity (why it's parked)

There is no cheap, synchronous "unit id → name + icon" lookup available in the lobby (front-end) Lua state:

- **`__blueprints` is sim-side only.** It is created when a *game* loads (see
  [`/lua/RuleInit.lua`](/lua/RuleInit.lua) `__blueprints = …`) and is **not populated in the front-end** —
  confirmed by the note in [`/lua/ui/lobby/UnitsAnalyzer.lua`](/lua/ui/lobby/UnitsAnalyzer.lua) (~line 496:
  "we cannot use global `__blueprints` … because it is created on SIM side"). An earlier attempt that read
  `__blueprints[unitId]` was reverted for this reason — it always hit nil and fell through.
- **The icon, on its own, *is* resolvable synchronously.** The build icon lives on disk at
  `/textures/ui/common/icons/units/<id>_icon.dds`, and `DiskGetFileInfo` works in the front-end (that's how
  `UnitsAnalyzer.GetImagePath` resolves it). So **icon-only** enrichment needs no blueprint load.
- **The name needs a loaded blueprint.** In the front-end the only source is
  [`/lua/ui/lobby/UnitsAnalyzer.lua`](/lua/ui/lobby/UnitsAnalyzer.lua), which loads blueprints by
  **reading the `.bp` files itself** (`GetBlueprints` → `LoadBlueprints('*_unit.bp', …)` → `CacheUnit`, which
  sets `bp.Name = GetUnitName(bp)` etc.). It is **async**, **mod-aware**, and **loads the entire unit set**.
  It's wrapped reactively by [mapselect-style] [`unitselect/CustomLobbyUnitCatalog.lua`](unitselect/CustomLobbyUnitCatalog.lua)
  (`EnsureLoaded(activeMods)` + `GetFactionsVar()`), which the unit-select dialog uses.

### Options considered (pick one when we resume)

1. **Icon + raw id (lightweight).** Resolve the icon via the disk path (sync), label = unit id. Zero load
   cost, works for host + clients immediately. Loses the human-readable name.
2. **Full name via UnitsAnalyzer.** Have the model consume `CustomLobbyUnitCatalog` (trigger
   `EnsureLoaded` only when unit-id restrictions are present, re-derive when `GetFactionsVar()` fires).
   Proper names + tooltips, but loads *all* blueprints (async, heavy) in any lobby with unit restrictions,
   on host **and** clients — a lot of machinery for a few labels.
3. **Lightweight single-`.bp` read.** Mirror what `UnitsAnalyzer`/`CacheUnit` do but for *one* unit:
   synchronously `doscript` the unit's `_unit.bp` and read `General.UnitName` / `Description`. Avoids loading
   the whole set, but re-implements a slice of the blueprint loader and needs care (mods, file path from id,
   `doscript` safety/caching).

### Open question

How to manage this blueprint-loading complexity for a **read-only** panel without paying the full
load-everything cost — likely option 3 (a small cached "resolve one unit's name from its `.bp`") or option 1
as an interim. Decide, then implement entirely in the derived model's `EnrichKey` (the panel is already generic).
