# Custom Lobby — rebuild (work in progress)

A ground-up, reactive-MVC rebuild of the custom-games lobby (the player-driven
counterpart to the matchmaker [`autolobby/`](../autolobby/CLAUDE.md)). It replaces
the organically-grown [`/lua/ui/lobby/lobby.lua`](../lobby.lua).

> **Read first**, in order:
> - [`/lua/ui/CLAUDE.md`](/lua/ui/CLAUDE.md) — UI patterns (LazyVar/`Derive`, `__init`/`__post_init`, `TrashBag`).
> - [`/lua/ui/lobby/autolobby/CLAUDE.md`](../autolobby/CLAUDE.md) — the proven Model / Instance / Controller / components split this mirrors.
> - [`/lua/ui/lobby/TARGET_ARCHITECTURE.md`](../TARGET_ARCHITECTURE.md) — the design for this rebuild.
> - [`/lua/ui/lobby/FEATURES.md`](../FEATURES.md) / [`USER_STORIES.md`](../USER_STORIES.md) — the parity target.

## Naming

Folder `customlobby/`, class/module prefix `CustomLobby` — pairs with `autolobby/` /
`Autolobby*`. "Custom" is FAF's own term for non-matchmaker games (the autolobby is
the automated/matchmaker path).

## Three models

State is split by two questions — *is it shared (host-dictated → everyone)?* and *does
it get launched (becomes part of the game)?* See the `customlobby-model-choice` skill.

- **[CustomLobbyLaunchModel.lua](CustomLobbyLaunchModel.lua)** — shared **and** launched:
  the launch payload (players, observers, scenario, game options, mods, auto-teams, spawn
  mex, unit restrictions) + `MaxSlots` + the `UICustomLobbyPlayer` shape. `Players` is an **array of per-slot
  LazyVars** so one slot's change re-fires only that row. Write helpers (`SetPlayer`,
  `SetPlayerField`, `AddObserver`, …) keep the copy-then-`Set` discipline.
- **[CustomLobbySessionModel.lua](CustomLobbySessionModel.lua)** — shared but **not**
  launched: lobby-room management (slot count, closed slots, `SlotsPinned`). A closed slot is
  just empty at launch and slot count is map-derived presentation — neither reaches the scenario.
  `SlotsPinned` locks seating so the host rejects client slot-takes (only the host may move
  players), enforced in `ProcessTakeSlot`.
- **[CustomLobbyLocalModel.lua](CustomLobbyLocalModel.lua)** — **per-peer, never synced**:
  identity (`LocalPeerId` / `HostID` / `IsHost`, set on the connection handshake) +
  connectivity (CPU benchmarks now; ping later). Broadcasting identity would corrupt the
  receiver's sense of itself, so it never goes on the wire.

## Status

| File | Role |
|------|------|
| [CustomLobbyLaunchModel.lua](CustomLobbyLaunchModel.lua) | shared + launched state — the launch payload (see above). |
| [CustomLobbySessionModel.lua](CustomLobbySessionModel.lua) | shared, lobby-room-only state (slot count, closed slots). |
| [CustomLobbyLocalModel.lua](CustomLobbyLocalModel.lua) | per-peer state, never synced: identity + CPU benchmarks. |
| [CustomLobbyPerformancePopover.lua](CustomLobbyPerformancePopover.lua) | hover popover over the CPU column; hand-built bitmap bar chart of a peer's `PerformanceTrackingV2` history, with a yellow recommended-unit-cap line. |
| [CustomLobbyInstance.lua](CustomLobbyInstance.lua) | thin `moho.lobby_methods` shell; validates/dispatches traffic, forwards callbacks to the controller. Also feeds [`CustomLobbyLog`](CustomLobbyLog.lua) from its three network choke points (BroadcastData / SendData / DataReceived). |
| [CustomLobbyLog.lua](CustomLobbyLog.lua) | the **network traffic log** — a reactive, per-peer, never-synced ring buffer (`Entries` LazyVar, capped) of every message this peer broadcasts / sends / receives, fed by the instance and rendered by the **Logs** tab. Each peer logs only its own traffic, so host and client views differ naturally. Not one of the three models (no game state); a diagnostic feed. |
| [CustomLobbyController.lua](CustomLobbyController.lua) | host-authority logic (free functions): seating, `Process*` handlers, intents (`RequestSetReady`, `RequestTakeSlot`, `RequestSwapSlots`, `RequestEject`, `RequestMoveToObserver`, `RequestSetScenario`, `RequestSetGameMods/Options`, `RequestResetGameOptions`, `RequestSetSlotsPinned`, `RequestAutoBalance` (stub), `RequestReopenClosedSlots`, `RequestLaunch`, `RequestSaveSetupPreset`/`RequestLoadSetupPreset` — all keyed by slot/bool/file/name so a chat command can call them too; permission is gated separately), sharing the stored CPU benchmark. **Launch:** `RequestLaunch` (host-only, readiness-validated) → auto-saves the `lastGame` preset (`BuildSetupSnapshot`) → `BuildGameConfiguration` (seed option defaults + scenario, resolve random factions, assign army numbers + push to server, stamp ratings/clan tags, resolve sim mods via `Mods.GetGameMods`) → broadcast `LaunchGame` + `instance:LaunchGame`; clients run `ProcessLaunchGame`. **Presets:** `BuildSetupSnapshot` (read the launch state → serializable snapshot) + `ApplySetup` (host-only: write scenario/mods/restrictions/teams, reconcile options to the current schema, one broadcast); players are captured but not reseated (see [presetselect/](presetselect/CLAUDE.md)). |
| [CustomLobbyRules.lua](CustomLobbyRules.lua) | game-rule derivations from lobby state (not view, not networking): `RecommendedUnitCap()` (per-player cap by map size, memoised scenario lookup). |
| [CustomLobbyPresets.lua](CustomLobbyPresets.lua) | **named full-setup presets** — pure prefs CRUD (`GetPresets`/`GetPreset`/`SavePreset`/`DeletePreset`/`RenamePreset`) over one key (`customlobby_setup_presets`), an ordered `{ Name, Setup }` array mirroring the mod presets in [`/lua/ui/modutilities.lua`](/lua/ui/modutilities.lua). Holds no models, no network. A reserved `LastGamePresetName` entry is auto-saved at launch (the rehost source). Capturing/applying a setup lives in the controller (`BuildSetupSnapshot`/`ApplySetup`); see [presetselect/](presetselect/CLAUDE.md). |
| [CustomLobbySession.lua](CustomLobbySession.lua) | the lobby session's **main trash bag**. The lobby lives in the persistent front-end Lua state, which is *not* reset when the game launches in its own state — so anything left reachable (a running thread, a cache, a singleton) leaks for the whole match. This module owns one session-lifetime `TrashBag` (`GetTrash()`); every lobby-scoped `Destroyable` registers in it, and one `Teardown()` (clean-slate in `CreateLobby`, on leave, on `OnGameLaunched`) frees the lot. Works despite the bag being weak-valued because each singleton is pinned by its own module `Instance` local. **Rollout in progress** — the map catalog is the first resource converted; models / interface / instance follow. |
| [CustomLobbyMessages.lua](CustomLobbyMessages.lua) | message registry: `AddPlayer`, `SetPlayers` (launch model: players + observers), `SentLaunchInfo` (launch model: scenario / options / mods / teams / spawn mex), `SetSessionState` (session model: slot count / closed slots), `SetReady`, `TakeSlot`, `DisconnectPeer`, `LaunchGame` (host's final game config → `instance:LaunchGame`), `ReportCpuBenchmark`, `SetCpuBenchmarks`. |
| [CustomLobbyContextMenu.lua](CustomLobbyContextMenu.lua) | generic framed floating menu; `Show(entries, x, y)` renders any `{label, action, enabled}` list, dismisses on item click / click-outside / Esc. Knows nothing about the lobby. |
| [CustomLobbyMenus.lua](CustomLobbyMenus.lua) | declarative menu **definitions**: entry lists with `when(ctx)`/`action(ctx)` filtered by lobby state (`BuildSlotMenu`). Adding/state-gating an item is a one-liner here. |
| [slots/](slots/) | the **slot subsystem** (its own folder, a sub-folder per layout). [`CustomLobbySlotsInterface`](slots/CustomLobbySlotsInterface.lua) is the entry the composition root mounts: a "Players" header over the **active layout body**, picked by the AutoTeams mode — one-column for the non-team modes, the two-column team layout for the binary modes (left/right, top/bottom, even/odd). It observes `GameOptions` and swaps the body when the kind flips (create-on-mode / destroy-on-switch); a change *within* the binary modes is handled by the two-column body's own re-layout. It is the rows' **drag coordinator** (`UICustomLobbySlotCoordinator`: hit-test which row a point is in, drop-highlight, drag ghost → `RequestSwapSlots`) for *every* layout — it alone needs to hit-test across rows — so the layout bodies stay pure build/place/reveal and never duplicate the drag logic; it also exposes `PreferredHeight()` (computed from the mode + model, swap-order-independent) so the root sizes the slot area. The header band carries a **host-only tool strip** (right-aligned: pin seating · auto-balance · reopen closed slots) of small icon buttons (local `SlotTool`, mirroring the config column's `PreviewTool`); the pin button is lit from the synced `SlotsPinned` and the strip is hidden for clients. A **"Locked" notice** (lock glyph + label) sits right of the "Players" label and is shown to **everyone** while `SlotsPinned` is on, so a client can see seating is host-controlled before clicking an open slot to no effect. [`CustomLobbySlotBase`](slots/CustomLobbySlotBase.lua) holds **all slot behaviour** (the slot + CPU subscriptions, the CPU-cap math, click/right-click/drag-to-swap + intents, the background/highlight/click overlays) and the default `RenderPlayer`/`RenderCpu` that paint the standard named controls from normalised views; a presentation subclasses it and implements just `CreateContents` / `LayoutContents`. [`onecolumn/`](slots/onecolumn/): [`CustomLobbyOneColumnSlots`](slots/onecolumn/CustomLobbyOneColumnSlots.lua) (stacks thin rows, reveals 1..count) + [`CustomLobbySlotRow`](slots/onecolumn/CustomLobbySlotRow.lua) (thin one-line presentation). [`twocolumn/`](slots/twocolumn/): [`CustomLobbyTwoColumnSlots`](slots/twocolumn/CustomLobbyTwoColumnSlots.lua) (splits slots into two team columns via [`CustomLobbyRules.BuildSideResolver`](CustomLobbyRules.lua), with a [`CustomLobbyTeamScore`](CustomLobbyTeamScore.lua) strip across the top as the Left/Right indicator, and the "two columns, unresolved" fallback — parity fill + the score self-hides until a positional map's start positions load) + [`CustomLobbySlotCard`](slots/twocolumn/CustomLobbySlotCard.lua) (fat half-width / two-line presentation; `SetMirrored` flips the right column's cards so the two teams face each other). Each body exports `HeightForCount`. |
| [CustomLobbyObserversInterface.lua](CustomLobbyObserversInterface.lua) | observer strip; subscribes to the model's `Observers` list and shows the count + names (read-only). |
| [CustomLobbyScenarioPreview.lua](CustomLobbyScenarioPreview.lua) | **shared** map-preview *surface*: the scenario's map texture + overlays (start spots, resource/wreck markers, plus a **dummy translucent `WaterMask`** placeholder until a real mask exists) with aspect-correct positioning, texture-leak-safe icon sharing, per-group visibility (`SetOverlayVisible('spawns'\|'resources'\|'wrecks'\|'water', …)`), and three-phase init. Chrome-free; `CustomLobbyMapPreview` wraps it with the frame. Spawn appearance is the owner's via a `CreateSpawnIcon` factory. |
| [CustomLobbyMapPreview.lua](CustomLobbyMapPreview.lua) | the map preview **as one whole** — the chrome (glow border on top + dark backdrop, surface inset by `Padding`), the surface, and the faction spawn icon (local `MapPreviewSpawn`). Used by **both** consumers: created `Bound = true` it subscribes to the launch model and renders the committed `ScenarioFile` with per-slot faction spawns (no reload on take/swap); created unbound (the map-select dialog) it does no model wiring and the owner drives `preview.Surface` directly (numbered-dot spawns). Exposes `.Surface` for owners to drive / anchor overlays to. |
| [mapselect/](mapselect/CLAUDE.md) | the **map-select dialog** + its catalog and list, in their own folder (host-only `Popup`: searchable, filterable scenario list → `RequestSetScenario`). Self-contained sub-MVC; see [mapselect/CLAUDE.md](mapselect/CLAUDE.md) — including the **`MapPreview` texture-leak** writeup that shaped its design. |
| [modselect/](modselect/CLAUDE.md) | the **mod-select dialog** + its catalog and list, built to the map-select shape (checkbox list + type filters + detail panel + **presets**). Returns a uid set; the opener routes it — sim mods → `RequestSetGameMods` (synced), UI mods → local prefs — or persists the lot standalone. Mod domain logic lives in [`/lua/ui/modutilities.lua`](/lua/ui/modutilities.lua) (the `maputil.lua` sibling, fronting `/lua/mods.lua`). See [modselect/CLAUDE.md](modselect/CLAUDE.md). |
| [presetselect/](presetselect/CLAUDE.md) | the **setup-presets dialog** (host-only `Popup`): a list of named full-setup snapshots (map / options / mods / restrictions) with **Load / Save / Rename / Delete**, opened by the action-bar **Presets** button. Owns no synced state — Save/Load route through the controller's host-authoritative `RequestSaveSetupPreset` / `RequestLoadSetupPreset` intents; the persistence is [`CustomLobbyPresets`](CustomLobbyPresets.lua). Players are captured in the snapshot but **not reseated on load yet** (deferred — see presetselect/CLAUDE.md). |
| [optionselect/](optionselect/CLAUDE.md) | the **options dialog**: three columns (lobby / scenario / mod options) over the selected scenario + mods, with search + hide-defaults filters; non-default options are marked. Derives the option *schema* per-peer (reference data) via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua); edits a working copy of the *values* and on OK routes the reconciled set through `RequestSetGameOptions` (synced via `GameOptions`). Host-only. See [optionselect/CLAUDE.md](optionselect/CLAUDE.md). |
| [CustomLobbyInterface.lua](CustomLobbyInterface.lua) | composition root, laid out in **areas** (flip the module `Debug` flag to tint them), sized for the **1024×768** floor. A **one-column** layout (the two-column variant was reverted by community request): a **title bar** (title · team score) over a **left column** split vertically — the **slots** on top (a single column of rows, up to 16, height tracking the slot count) and the **Chat / Observers** tabs below — beside a fixed-width **right column** (the config component: a pinned map preview + facts line over Options / Mods / Restrictions tabs). A full-width **action bar** at the bottom holds the global actions: **Leave** + status on the left, the host-only **Presets** button (opens the setup-presets dialog — see [presetselect/](presetselect/CLAUDE.md)) + the host-only **Launch** on the right. Reads IsHost (action-bar buttons) + SlotCount (to size the slot area via `CustomLobbySlotsInterface.HeightForSlots`); Leave (Esc handler) + **Become observer** (`RequestMoveToObserver`, in the Observers tab). The slot rows + their drag coordination now live in [`CustomLobbySlotsInterface`](CustomLobbySlotsInterface.lua), which fills the slot area. `OpenDebug()` / hot-reload. |
| [CustomLobbyTeamScore.lua](CustomLobbyTeamScore.lua) | the **accumulated team rating** side indicator — `Side A  N · M  Side B`. Hosted in the strip atop the two-column slot layout (it doubles as the columns' Left/Right header). Shown only for the binary auto-team formations; **hidden** for `none`/`manual` or until a positional map's start positions load. Reads the mode + side split from [`CustomLobbyRules`](CustomLobbyRules.lua) (`AutoTeamMode` / `SideLabels` / `BuildSideResolver`) and the ratings from each slot's `PL`. Reference data; never writes. |
| [CustomLobbyTabs.lua](CustomLobbyTabs.lua) | a **generic tabbed panel** (strip + content; one panel alive, created on select / destroyed on switch). Tabs **divide the strip evenly** across its width. Construct with a `{ Label, Create, Badge?, Action?, Icon?, Compact? }` list + optional `OnSelect`. A tab's optional `Badge` LazyVar drives a grey **count pill** to the right of the label; its optional `Action` (`{ Create, Visible? }`) is a small button the owner builds **inside the tab, left of the label** (e.g. a config gear), whose `Visible` LazyVar hides it (collapsing it from the layout) when it doesn't apply. The action, label and pill are centred together as one cluster; any absent/hidden/empty piece contributes 0 width so the rest re-centres. A tab can instead be **`Compact`** (a fixed narrow width, excluded from the even division — the flexible tabs share what's left) and/or show an **`Icon`** centred instead of its label (an icon-only utility tab); the default active tab is the first non-compact one. The container just mirrors the LazyVars, the owner decides what they mean. Used for the bottom-left (Logs / Chat / Observers) and the config interface's Options / Mods / Restrictions. |
| [social/](social/) | the lobby's **bottom-left** column (the `CustomLobbyTabs` content): [`CustomLobbyChatPanel`](social/CustomLobbyChatPanel.lua) (the **Chat** tab — placeholder until the chat slice lands) and [`CustomLobbyObserversPanel`](social/CustomLobbyObserversPanel.lua) (the **Observers** tab — the shared observer list + a host-authoritative **Become observer** button → `RequestMoveToObserver`). Each is a tab content component (`Create(parent)`, created on select / destroyed on switch). The Chat / Observers tabs mirror the config column's shape — a per-tab **config gear** (`CustomLobbyInterface`'s local `GearAction`; both no-ops with a "coming soon" tooltip for now) + a right-side **count pill**: Observers shows the live observer count, Chat a dummy until the chat slice lands. A third **compact, icon-only [`CustomLobbyLogsPanel`](social/CustomLobbyLogsPanel.lua)** sits left of Chat (the **Logs** tab — a live **tail view** of this peer's network traffic from [`CustomLobbyLog`](CustomLobbyLog.lua): the most recent entries that fit, in columns `time · kind · ⚠ · name`, with a malformed/unauthorised message tinted + a ⚠ icon whose tooltip is the failure reason). |
| [config/](config/) | the lobby's **right** column. [`CustomLobbyConfigInterface.lua`](config/CustomLobbyConfigInterface.lua) is the column **composition**: a bound square `CustomLobbyMapPreview` **pinned** at the top with a vertical **preview tool strip** to its right (local `PreviewTool` icon buttons — toggles for army/start icons, mass+hydro deposits and the dummy water mask, driving `preview.Surface:SetOverlayVisible`, + a host-only **change-map** config icon at the bottom → the map-select dialog), a name + size/players/version facts line under it, and a [`CustomLobbyTabs`](CustomLobbyTabs.lua) (**Options / Mods / Restrictions**) filling the rest. Each tab carries its own **config gear** (`CustomLobbyTabs`' per-tab `Action`, built by the interface's `GearAction` helper) — a skinned button **inside the tab, left of the label** — that opens that tab's editor: Options → `CustomLobbyOptionSelect`, Mods → `CustomLobbyModSelect`, Restrictions → `CustomLobbyUnitSelect` (see [unitselect/](unitselect/)). The Options + Restrictions gears are **host-only**: their `Visible` LazyVar is the `IsHost` field, so they're **hidden** for clients and the label re-centres; the Mods gear shows for everyone (UI mods are local; the sim portion is host-gated inside the dialog). The interface also owns the tabs' **count badges** as computed LazyVars over the launch model — Options shows the non-default-option count (`OptionUtil.CountNonDefault`), Mods shows `sim / ui` (synced sim mods / this peer's UI-mod prefs), Restrictions shows the active restriction count (preset keys in the launch model's `Restrictions`). All three tab panels are now **read-only**: their per-domain action buttons (open editor / reset / manage mods) are removed — the grid/content fills the whole panel — and the action-bar **Settings** button (now joined by this gear) is the edit entry point. [`CustomLobbyOptionsPanel`](config/CustomLobbyOptionsPanel.lua) (options grouped **Lobby / Scenario / Mods** + hide-defaults toggle; map/mod options gold-flagged with an origin tooltip — schema via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua)), [`CustomLobbyModsPanel`](config/CustomLobbyModsPanel.lua) (enabled mods in **Game / UI** sections), [`CustomLobbyUnitsPanel`](config/CustomLobbyUnitsPanel.lua) (the **Restrictions** read-only list — the active restrictions' names, from the launch model's `Restrictions`). Each self-subscribes to the model and exposes `Initialize()` + `Create(parent)`. **Parked** (built, but unwired): [`CustomLobbyMapPanel`](config/CustomLobbyMapPanel.lua) (the full Map tab — preview + label/value details + Change-map), now superseded by the pinned preview. Churning a preview is safe here because the lobby shows only **one** current map and the engine caches map textures by name (the texture-leak rule only bites the *map-select dialog* — see [mapselect/CLAUDE.md](mapselect/CLAUDE.md)). |
| [/lua/ui/lobby/lobby.lua](../lobby.lua) | engine entry wrapper (`CreateLobby`/`HostGame`/`JoinGame`) → CustomLobby. Old lobby preserved at `lobby-old.lua`. |

Working today: host + clients see each other (host-authoritative player sync), the
host's launch config (scenario / options / mods) and session state (slot count / closed
slots) are pushed to clients as whole snapshots (`SentLaunchInfo` + `SetSessionState`, on
join and on change) so the map preview / slot grid render,
ready toggles round-trip, players can **take an open slot** (click it) and the host can
**swap** (drag a row onto another), **eject**, and **move a player to observers** (right-click
→ context menu); observers are synced in the `SetPlayers` snapshot, shown in an observer
strip, and an observer rejoins via right-click → **Play this slot**. Each peer's
stored sim-performance benchmark is shared (no live stress test), and a **Leave** button
(or Esc) disconnects and returns to the menu — a leaving client frees its slot for
everyone via `OnPeerDisconnected`. The host can edit the **game options** via the action-bar
**Settings** button → the options dialog (synced through `RequestSetGameOptions`). (The per-domain
**Change-map** and **mod-select** entry points are temporarily removed during the layout rework —
the dialogs themselves still exist and will be rewired once it lands; `RequestSetScenario` /
`RequestSetGameMods` remain callable, e.g. from chat commands.) The host can
**launch the game** (Launch button → `RequestLaunch`): once a map is picked, ≥1 slot is seated
and every other human is ready, it builds the game config, broadcasts `LaunchGame` and hands it to
the engine, so all peers start together. (Lobby-UI teardown on launch and reactive enable/disable
of the button are still TODO.) The host can **save / load named setup presets** (the action-bar
**Presets** button → the presets dialog): a preset captures map / options / mods / restrictions and
loading applies them host-authoritatively (options reconciled to the current map+mods); launch
auto-saves the `lastGame` preset. (Player reseating + rehost restore are deferred — see
[presetselect/](presetselect/CLAUDE.md).) Launched via
`scripts/LaunchCustomLobby.ps1`, or inspect UI only with
`UI_Lua import("/lua/ui/lobby/customlobby/customlobbyinterface.lua").OpenDebug()`.

## Next slices (per TARGET_ARCHITECTURE.md)

1. **Options panel** — done; see [optionselect/](optionselect/CLAUDE.md). The schema is derived
   per-peer from `ScenarioFile` + `GameMods` (lobby ∪ scenario `_options.lua` ∪ mod options) via
   [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua); the dialog edits the synced `GameOptions`
   *values* and reconciles on confirm (seed defaults, drop stale keys) → `RequestSetGameOptions`.
   Still TODO: reconcile in the **controller** on scenario/mod change too (the `TODO` in
   `RequestSetScenario`), so values stay sane even without opening the dialog.
2. Remaining sub-dialogs (units, prefs) as mini-MVC, following the map-select shape. **Mods** and
   **options** are done — see [modselect/](modselect/CLAUDE.md) (carries its own presets, replacing
   the legacy per-mod "favorites") and [optionselect/](optionselect/CLAUDE.md).
3. Make slot controls interactive (faction/colour/team → controller **intents**).
4. Map-derived `SlotCount`; the GPGNet (`localPort == -1`) FAF-client path.

## Rules (same as autolobby)

- Components subscribe via `Derive`; they never write the model.
- The controller is the only writer, through the model write-helpers (never mutate a held table in place).
- A `Derive` handler must read its own LazyVar (`function(xLazy) self:OnX(xLazy()) end`).
- FAF is Lua 5.0 — no `%` operator; use `math.mod`.

## The label/value detail format

How we present a single entity's metadata (a map, a mod). Used by the in-lobby **Map tab**
([config/CustomLobbyMapPanel.lua](config/CustomLobbyMapPanel.lua)), the **map-select dialog**
([mapselect/CustomLobbyMapSelect.lua](mapselect/CustomLobbyMapSelect.lua)) and the **mod-select
dialog** ([modselect/CustomLobbyModSelect.lua](modselect/CustomLobbyModSelect.lua)) — they read
identically.

**Shape (top → bottom):**

- An optional **header** — the title (16–18pt `titleFont`) over a single **quick-facts line** of
  the short, always-present facts joined by `"   ·   "` (`20km · 8 players · v3`; `v3 · Game mod`),
  centred. The map dialog/tab put the preview here; the mod dialog puts the icon.
- A stack of **labelled sections**, each a **dim label above its value**:
  - **Label** — `UIUtil.CreateText(parent, text, 12, UIUtil.titleFont)`, colour `LabelColor` =
    `'ff8a909a'`, hit-test off. Built by a local `CreateSectionLabel`.
  - **Value** — 13pt `bodyFont` in `ValueColor` = `'ffc8ccd0'` for one-liners (author, reclaim), or
    a `TextArea` (same `ValueColor`) for long text (description, dependencies).
  - Examples: `Author` / `Description` / `Reclaim` (mass·energy icons) / `Dependencies` / `Details`.

**Collapse + stacking.** A `LayoutSections` / `LayoutDetail` method stacks the *visible* sections
top-to-bottom, anchoring each under the previous and **skipping (hiding) the ones the entity
doesn't declare** so the rest floats up; the long text area (description / deps) fills the
remaining space. Anchor the value's left/right statically in `__post_init` but set the *tops*
in this method — and call it from the clear path too, so an empty open doesn't leave a control
unanchored (→ circular dependency at render).

**TextArea width** still follows the gotcha below: bind `Width` to the laid-out span in
`Initialize` (post-mount), never `__post_init`.

**On sharing.** Each consumer keeps its **own local copy** of these helpers (`CreateSectionLabel`,
`LayoutSections`/`LayoutDetail`, `FormatAmount`, the `LabelColor`/`ValueColor` constants) rather
than a shared component — a deliberate *drift-is-fine* call, so the three can diverge as each
context needs. If they start drifting in ways that matter, that's the signal to extract a shared
`CustomLobbyMapDetails`-style view.

## Layout / init gotchas (learned building the map-select dialog)

These are the recurring footguns when writing a custom control here — all variations of
"layout isn't a value you can read yet." Read `/lua/ui/CLAUDE.md` § 1–2 first; this is the
lobby-specific checklist.

| Symptom | Cause | Fix |
|---|---|---|
| `attempt to call method 'SetFunction' (a nil value)` while laying a control out | A `self.X` field name **collides with a Control edge** — `Left` / `Right` / `Top` / `Bottom` / `Width` / `Height` / `Depth` are reserved LazyVars; assigning `self.Top = 0` clobbers the edge. | Name custom fields anything else (`ScrollTop`, not `Top`). |
| `attempt to call method 'AtLeftRightIn' (a nil value)` (or similar) in a layouter chain | Not every `LayoutHelpers.*` function is exposed on the fluent `ReusedLayoutFor` builder. `AtLeftRightIn` is bare-only. | Use the methods other components use — `:AtLeftIn(p):AtRightIn(p)`, `:AnchorToBottom`, `:Fill`, … — or call `LayoutHelpers.Foo(control, …)` directly. |
| `circular dependency in lazy evaluation` when an `Edit`'s font is set, or a list/preview reads its size | Reading a **concrete** layout value (`SetFont`, `ShowItem`, `Width()`) before the control is anchored into a settled parent rect. | Three-phase init: build in `__init`, anchor in `__post_init`, and read geometry only in an `Initialize()` the **opener calls after mounting** (e.g. after `Popup` centres the dialog). For an `Edit`, give it placeholder `:Left(0):Top(0):Width():Height()` before `SetFont`. |
| Cascade of errors after one layout failure (half-built pools, observers firing into a broken control) | A throw mid-`Initialize` left partial state (e.g. `PoolCount` set before the rows existed), and a streaming `Derive`/thread kept calling into it. | Set "ready" counters **after** the thing they describe is fully built; guard paint/refresh paths against nil rows; gate model-observer work on a `self.Ready` flag set in `Initialize`. |
| `circular dependency in lazy evaluation` with **no frame from your files** (fires during the render pass) | A control you created in `__init` is **never anchored** in `__post_init` (or you renamed/moved its layout and forgot it). Its `Left`/`Right`/`Top`/`Bottom` stay at the circular defaults, and it errors the moment it's rendered. | Every visible control needs a layout. To find which one, set `import("/lua/lazyvar.lua").ExtendedErrorMessages = true` — the error then appends the offending control's **creation stack** (file + line). Then anchor it (or hide it). |
| `circular dependency` only **on hot-reload** (or when the model already has state), not on a fresh open | A `Derive` observer fires **immediately on creation** in `__init`, and its handler reads layout geometry (e.g. positions icons via `self.Preview.Width()`). Fresh open: the model field is empty, handler no-ops. Reload: the field already has a value, so it renders before the parent has laid the component out. | Gate the observer handlers behind a `self.Ready` flag (default false). Set `Ready = true` and do the first render **deferred** (`ForkThread` + `WaitFrames(1)` from `__post_init`, or an `Initialize()` the parent calls) — once the parent has actually sized you. See `CustomLobbyMapPreview`. |
| Controls in a hidden container still render — a hidden tab's list/buttons bleed over the active one | MAUI's `Hide()`/`Show()` cascade the hidden flag to the children that exist **at call time**; there's no render-time ancestor check (the `OnHide` "return true to stop the cascade" contract in [`/lua/maui/grid.lua`](/lua/maui/grid.lua) confirms it). So anything created or `Show()`-n in a panel *after* it was hidden (a rebuilt grid row, a button you re-showed) renders, because it missed the cascade. | Don't keep hidden-but-alive panels at all: **create the active panel and destroy it on switch** so only one is ever live (the [`CustomLobbyTabs`](CustomLobbyTabs.lua) model — strip + create-on-select / destroy-on-switch). If you must keep a panel alive and toggle it, re-assert visibility *after* any rebuild (show the active, re-`Hide()` the inactive) rather than trusting an earlier `Hide()`. |
| A `TextArea`'s text wraps far too early (~50–60% of the visible box) | `TextArea.__init` pins `Width` to its **constructor** `width` arg via `SetDimensions`, and `ReflowText` wraps to `Width()` — but the fluent `:AtLeftIn():AtRightIn()` set only `Left`/`Right`, never `Width`. So the box renders `Left..Right` wide while the text still wraps at the stale constructor width. | Bind `Width` to the span: `self.X.Width:Set(function() return self.X.Right() - self.X.Left() end)`. **Do this in `Initialize()` (post-mount), not `__post_init`:** `TextArea` hooks `Width.OnDirty → ReflowText`, so the bind *eagerly* reads `Right()/Left()` → the parent geometry, which is still circular until `Popup` mounts the dialog. (Left/Right anchor to the parent, so no self-cycle once mounted.) |
| Memory climbs ~30 MB and never drops — not on re-texture, `ClearTexture`, `Destroy`, or dialog close | `MapPreview:SetTexture` / `SetTextureFromMap` allocate textures the engine **never frees** (no release API on the control or globally). Loading one per list row × hundreds of maps leaks memory the game needs in-match. | Don't put a `MapPreview` per list row. Render at most a **few** previews total (the map-select list is text-only; only the single candidate preview loads a texture, once per selection). The same applies to per-row `Bitmap` thumbnails via `SetNewTexture`. |

Reference implementation for all four: [mapselect/CustomLobbyMapSelect.lua](mapselect/CustomLobbyMapSelect.lua)
+ [mapselect/CustomLobbyMapList.lua](mapselect/CustomLobbyMapList.lua) (the pooled list's
`ScrollTop`, three-phase `Initialize`, post-loop `PoolCount`, nil-guarded `PaintRow`). The
texture-leak case is documented in depth in [mapselect/CLAUDE.md](mapselect/CLAUDE.md).
