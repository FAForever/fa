# Map select

The custom lobby's **map-select dialog** and its supporting pieces, split into their own folder
because the dialog is a self-contained sub-MVC and grew large. Opened by the host's "Change Map"
button in [`../CustomLobbyInterface.lua`](../CustomLobbyInterface.lua).

> Read [`../CLAUDE.md`](../CLAUDE.md) first (the lobby's MVC + the layout/init gotchas). This doc
> is map-select-specific.

## Files

| File | Role |
|------|------|
| [CustomLobbyMapSelect.lua](CustomLobbyMapSelect.lua) | the dialog (transient `Popup`, host-only). Laid out in **areas** (Group containers: title / left {filter, selection, stats} / preview / actions — flip the module `Debug` flag to tint them). Searchable list + size & player filters with comparison operators (`=`/`>=`/`<=`, persisted to Prefs); candidate preview (the shared `../CustomLobbyScenarioPreview` surface with numbered-dot spawns) with name overlay, an "Open page" link (allowlisted `url` → `OpenURL`), and toggle-able overlays (spawns / resources / wrecks); scrollable description; file-health check that disables Select for broken maps; Random / Select / Cancel. On Select → `CustomLobbyController.RequestSetScenario(file)`. Owns no synced state. |
| [CustomLobbyMapCatalog.lua](CustomLobbyMapCatalog.lua) | the lobby's **own** scenario data layer — and its single source of truth for what a scenario is, with **no MapUtil dependency** (the `_scenario.lua` / `_save.lua` `doscript` loaders + start-spot derivation are re-implemented here as small pure locals). Async enumeration of playable skirmish maps (streams into a `Scenarios` `LazyVar` across frames via `EnsureLoaded`; *not* `MapUtil.EnumerateSkirmishScenarios`), plus on-demand `LoadInfo` / `LoadSave` / `LoadMarkers` / `LoadOptions` (the save is memoised by path with a FIFO bound — the save `doscript` is expensive and browsing re-loads the same maps; `LoadMarkers` extracts the preview's start-spot / mass / hydro / wreck points so callers never touch the raw save; `LoadOptions` reads + validates the map's `_options.lua` schema, so the catalog is the one reader of every scenario file — `_scenario.lua` / `_save.lua` / `_options.lua`). **Reference data, never synced** — local only; the host syncs just its `ScenarioFile` choice. |
| [CustomLobbyMapList.lua](CustomLobbyMapList.lua) | the dialog's scrollable, **virtualised** list: a fixed pool of **text-only** rows (name + `size · players`) reused while scrolling, standard scrollbar contract, mouse-driven (no keyboard focus — a custom Group list can't take it). `OnSelect` / `OnConfirm`. |

This is the first sub-dialog split out of the legacy `dialogs/mapselect.lua` god-dialog: it does
**map selection only**. Game options, mods and unit restrictions become their own components (the
options panel will derive its schema from the selected map + mods — see [`../CLAUDE.md`](../CLAUDE.md)).

## The `MapPreview` texture leak (why the list is text-only)

The single most important constraint in this folder. **The engine never frees the textures a
`MapPreview` loads** — and that memory is needed in-match.

### Symptom

With a mini `MapPreview` thumbnail per list row, scrolling a real map vault grew the process by
~30 MB (≈120 → 155 MB) and the memory **never came back** — not while the dialog stayed open, and
not after it closed.

### What we ruled out

`MapPreview` exposes only `SetTexture` / `SetTextureFromMap` / `ClearTexture` — no release API, and
there is no global texture-cache flush. We tried, and none of these freed the memory:

- re-using one preview control per row and re-calling `SetTextureFromMap` (re-texture);
- **destroying and recreating** the `MapPreview` control per scenario;
- calling **`ClearTexture()`** before destroy, and on every row teardown + on dialog close.

The textures are cached engine-side by name, independent of any control's lifetime. Nothing we can
call from Lua releases them.

### Resolution

**Don't put a `MapPreview` in a list row.** The list is text-only; only the dialog's **single
candidate preview** loads a texture — once per selection. Total live previews ≈ 1, so the leak is
bounded to a trickle instead of one-per-row-scrolled.

The few small overlay icons (mass / hydro / wreck) load their texture **once** each into hidden
template bitmaps in `__init` and every marker shares it via `ShareTextures` — so they don't multiply
either. (Those templates are locked hidden with an `OnHide` returning `true`, the `TexturePool`
trick, so a parent `Show()` can't reveal an unpositioned bitmap.)

### Rule of thumb

A `MapPreview` (or any `Bitmap` via `SetNewTexture`) loading a **distinct, per-item** texture is a
leak in disguise. Render at most a handful, total — never one per list row / pool slot. If you need
many thumbnails, you need a different approach than `MapPreview`.
