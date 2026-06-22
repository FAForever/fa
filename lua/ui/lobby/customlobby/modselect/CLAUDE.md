# Mod select

The custom lobby's **mod-select dialog** and its supporting pieces, in their own folder — the
mod-side counterpart to [`../mapselect/`](../mapselect/CLAUDE.md), built to the same shape. Opened
by the "Mods" button in [`../CustomLobbyInterface.lua`](../CustomLobbyInterface.lua), and usable
standalone (the main-menu mod manager use case).

> Read [`../CLAUDE.md`](../CLAUDE.md) first (the lobby's MVC + the layout/init gotchas), then
> [`../mapselect/CLAUDE.md`](../mapselect/CLAUDE.md) — this dialog mirrors it, including the
> **texture-leak** rule that keeps the list text-only.

## Files

| File | Role |
|------|------|
| [CustomLobbyModSelect.lua](CustomLobbyModSelect.lua) | the dialog (transient `Popup`). Same **areas** layout as the map dialog (title / left {filter, list, stats} / detail / actions — flip the module `Debug` flag to tint them). Left: name/author search + **Game / UI / Unavailable** type filters (persisted to Prefs) + a checkbox list; right: the highlighted mod's icon, author/version/type, website/source links (allowlisted → `OpenURL`), scrollable description, and a requires/conflicts/missing summary. Bottom: **presets** (load / save / delete) + OK / Cancel. Owns a *working selection set*, not synced state; on OK it hands the set to an `onConfirm` callback. |
| [CustomLobbyModCatalog.lua](CustomLobbyModCatalog.lua) | the lobby's **own** mod data layer — **reference data, never synced** (each peer enumerates its own disk; only the host's sim-mod *choice* syncs). Async-streams classified, display-ready `UILobbyModInfo` entries into a `LazyVar` (built from `ModUtilities`, which fronts `/lua/mods.lua`), so the dialog shows a live "N mods" count and fills in progressively. `EnsureLoaded` / `GetModsVar` / `FindByUid` / `Refresh`. |
| [CustomLobbyModList.lua](CustomLobbyModList.lua) | the dialog's scrollable, **virtualised** list: a fixed pool of rows reused while scrolling, each a **checkbox + name + type badge**. The list doesn't own the selection — it paints checkboxes from a set the dialog hands it (`SetChecked`) and asks a predicate whether each row may be toggled (`SetCanToggle`). `OnSelect` / `OnToggle` / `OnConfirm`. |

The mod domain logic lives one level up in [`/lua/ui/modutilities.lua`](/lua/ui/modutilities.lua) —
the UI-facing front door over `/lua/mods.lua` (the sibling of `maputil.lua` for maps): mod
classification, name/version/author formatting (lifted out of the legacy `ModsManager.lua`),
dependency-aware selection edits, **prefs persistence** (so a dialog never touches prefs), and
**presets** (named snapshots, replacing the legacy "favorites").

## The MVC boundary (where the selection goes)

The dialog is decoupled from the lobby models — it just returns a uid set. The **opener** decides
what that means, which is the whole point:

- **`Open` (in-lobby).** Seeds from the host's sim mods (`launch.GameMods()`) + this peer's UI
  mods (prefs). On OK, **sim** mods go through the host-authoritative `RequestSetGameMods` intent
  → `GameMods` → broadcast (a non-host sees them read-only via `canEditGameMods`); **UI** mods are
  this peer's own choice and persist locally via `ModUtilities.SetSelectedUIMods`. UI mods never
  go on the wire — see the `customlobby-model-choice` skill.
- **`OpenStandalone` (no lobby).** Seeds from `ModUtilities.GetSelectedMods()`; on OK the whole
  selection persists to the preference file via `ModUtilities.SetSelectedMods`.

Selection edits (checkbox ticks, preset loads) run through `ModUtilities.ResolveEnable` /
`ResolveDisable`, which pull in requirements and drop conflicts; the dialog repaints the list from
the resulting set. Blacklisted / missing-dependency mods can't be enabled.

## Texture leak (same as mapselect)

Rows are **text-only** (checkbox + name + badge) for the same reason the map list is: a mod's
`icon` is a distinct texture per mod, and the engine never frees the textures a `Bitmap`/
`MapPreview` loads (full writeup in [`../mapselect/CLAUDE.md`](../mapselect/CLAUDE.md)). One icon
per row × a big vault would leak the memory the game needs in-match. The icon is shown **once**, in
the detail panel, re-textured per highlighted mod — the same bounded trickle the map dialog's
single preview accepts.
