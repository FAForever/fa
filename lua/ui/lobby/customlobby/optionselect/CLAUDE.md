# Option select

The custom lobby's **options dialog** — three columns (lobby / scenario / mod options) over the
selected scenario + mods. The third sibling of [`../mapselect/`](../mapselect/CLAUDE.md) and
[`../modselect/`](../modselect/CLAUDE.md), built to the same shape. Opened by the host-only
"Options" button in [`../CustomLobbyInterface.lua`](../CustomLobbyInterface.lua).

> Read [`../CLAUDE.md`](../CLAUDE.md) first (the lobby's MVC + the layout/init gotchas), then the
> map/mod dialog docs — this mirrors them.

## Files

| File | Role |
|------|------|
| [CustomLobbyOptionSelect.lua](CustomLobbyOptionSelect.lua) | the dialog (transient `Popup`). Three fixed columns + a top filter bar (search by label + a **Hide defaults** toggle) + Reset / OK / Cancel. Owns a *working copy* of the option values; on OK it seeds defaults for every untouched option and hands the complete set to `onConfirm`. The in-lobby opener routes that through the host-authoritative `RequestSetGameOptions` intent. Owns no synced state. |
| [CustomLobbyOptionColumn.lua](CustomLobbyOptionColumn.lua) | one column: header (title + shown count), a native **`Grid`** of option rows, an auto-hiding scrollbar, and an **empty state**. Each row is `[marker] label … [value dropdown]`; the marker + a tinted label flag an option that's **not at its default**. Reads/writes the shared values table and reads the schema via `optionutil`. |

The option domain logic lives one level up in [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua) —
the `maputil.lua` / `modutilities.lua` sibling (inspired by Penguin5's `optionutil.lua`): it
**gathers** the schema from the three sources, and **interprets** options + values (default value,
current value, is-default, value index, display text, seed-defaults).

## The schema (reference data) vs. the values (synced)

The option **schema** is derived per-peer from the synced `ScenarioFile` + `GameMods` — it is
*reference data*, not a model (like the map/mod catalogs). The three sources:

- **lobby** — the static base options (team ∪ global ∪ AI) from [`../../lobbyOptions.lua`](../../lobbyOptions.lua);
- **scenario** — the selected map's `_options.lua`, via the map catalog's `LoadOptions`
  ([`../mapselect/CustomLobbyMapCatalog.lua`](../mapselect/CustomLobbyMapCatalog.lua) — the lobby's
  one reader of scenario files; the `_options.lua` name mirrors `_scenario.lua` / `mod_info.lua`);
- **mods** — each selected sim mod's `/lua/AI/LobbyOptions/lobbyoptions.lua` (`AIOpts`).

Only the option **values** sync: the host edits them here and they ride in the launch model's
`GameOptions` (broadcast via `BroadcastLaunchInfo`, applied in `ProcessSentLaunchInfo`). The dialog
seeds defaults + drops keys absent from the current schema, so confirming is also the
**reconciliation** the [`../CLAUDE.md`](../CLAUDE.md) options-slice note called for.

## Why a `Grid`, not the pooled list

The map/mod lists are text-only and virtualise by hand. Option rows hold a live **`Combo`** each,
which is painful to repaint on every scroll tick. The native `Grid` hides off-screen rows itself,
so the combos are created once (per filter rebuild) with no clipping tricks and no per-scroll
churn. Rows are rebuilt only when the **filter** (search / hide-defaults) changes — never on a
value edit — so editing never disturbs an open dropdown.

## Known gaps (deliberate, for a later pass)

- **No per-column show/hide toggles.** The `Grid` destroys its items on `SetDimensions`, so
  reflowing to fewer/wider columns means a rebuild; the three columns are fixed for now. The top
  bar is search + hide-defaults only.
- **Host-only.** Options are all host-dictated + synced, so the dialog is host-only (the button
  hides for clients; the intent is host-gated regardless). No read-only client view yet.
- **No live cross-mod/scenario key-clash handling.** `optionutil` de-dups within a source by key;
  it doesn't resolve a scenario option colliding with a base lobby key (rare).
