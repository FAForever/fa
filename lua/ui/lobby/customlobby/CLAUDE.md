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
  mex) + `MaxSlots` + the `UICustomLobbyPlayer` shape. `Players` is an **array of per-slot
  LazyVars** so one slot's change re-fires only that row. Write helpers (`SetPlayer`,
  `SetPlayerField`, `AddObserver`, …) keep the copy-then-`Set` discipline.
- **[CustomLobbySessionModel.lua](CustomLobbySessionModel.lua)** — shared but **not**
  launched: lobby-room management (slot count, closed slots). A closed slot is just empty
  at launch and slot count is map-derived presentation — neither reaches the scenario.
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
| [CustomLobbyInstance.lua](CustomLobbyInstance.lua) | thin `moho.lobby_methods` shell; validates/dispatches traffic, forwards callbacks to the controller. |
| [CustomLobbyController.lua](CustomLobbyController.lua) | host-authority logic (free functions): seating, `Process*` handlers, intents (`RequestSetReady`, `RequestTakeSlot`, `RequestSwapSlots`, `RequestEject`, `RequestMoveToObserver`, `RequestSetScenario` — all keyed by slot/bool/file so a chat command can call them too; permission is gated separately), sharing the stored CPU benchmark. |
| [CustomLobbyRules.lua](CustomLobbyRules.lua) | game-rule derivations from lobby state (not view, not networking): `RecommendedUnitCap()` (per-player cap by map size, memoised scenario lookup). |
| [CustomLobbyMessages.lua](CustomLobbyMessages.lua) | message registry: `AddPlayer`, `SetPlayers` (launch model: players + observers), `SentLaunchInfo` (launch model: scenario / options / mods / teams / spawn mex), `SetSessionState` (session model: slot count / closed slots), `SetReady`, `TakeSlot`, `DisconnectPeer`, `ReportCpuBenchmark`, `SetCpuBenchmarks`. |
| [CustomLobbyContextMenu.lua](CustomLobbyContextMenu.lua) | generic framed floating menu; `Show(entries, x, y)` renders any `{label, action, enabled}` list, dismisses on item click / click-outside / Esc. Knows nothing about the lobby. |
| [CustomLobbyMenus.lua](CustomLobbyMenus.lua) | declarative menu **definitions**: entry lists with `when(ctx)`/`action(ctx)` filtered by lobby state (`BuildSlotMenu`). Adding/state-gating an item is a one-liner here. |
| [CustomLobbySlotInterface.lua](CustomLobbySlotInterface.lua) | one slot row; subscribes to its slot + CPU benchmarks; CPU column shows max units at +0 with a green→red cap-headroom square; left-click an open slot to take it / your own to toggle ready; right-click opens its context menu; the host can drag a row onto another to swap. |
| [CustomLobbyObserversInterface.lua](CustomLobbyObserversInterface.lua) | observer strip; subscribes to the model's `Observers` list and shows the count + names (read-only). |
| [CustomLobbyScenarioPreview.lua](CustomLobbyScenarioPreview.lua) | **shared** map-preview *surface*: the scenario's map texture + overlays (start spots, resource/wreck markers) with aspect-correct positioning, texture-leak-safe icon sharing, per-group visibility, and three-phase init. Chrome-free; `CustomLobbyMapPreview` wraps it with the frame. Spawn appearance is the owner's via a `CreateSpawnIcon` factory. |
| [CustomLobbyMapPreview.lua](CustomLobbyMapPreview.lua) | the map preview **as one whole** — the chrome (glow border on top + dark backdrop, surface inset by `Padding`), the surface, and the faction spawn icon (local `MapPreviewSpawn`). Used by **both** consumers: created `Bound = true` it subscribes to the launch model and renders the committed `ScenarioFile` with per-slot faction spawns (no reload on take/swap); created unbound (the map-select dialog) it does no model wiring and the owner drives `preview.Surface` directly (numbered-dot spawns). Exposes `.Surface` for owners to drive / anchor overlays to. |
| [mapselect/](mapselect/CLAUDE.md) | the **map-select dialog** + its catalog and list, in their own folder (host-only `Popup`: searchable, filterable scenario list → `RequestSetScenario`). Self-contained sub-MVC; see [mapselect/CLAUDE.md](mapselect/CLAUDE.md) — including the **`MapPreview` texture-leak** writeup that shaped its design. |
| [modselect/](modselect/CLAUDE.md) | the **mod-select dialog** + its catalog and list, built to the map-select shape (checkbox list + type filters + detail panel + **presets**). Returns a uid set; the opener routes it — sim mods → `RequestSetGameMods` (synced), UI mods → local prefs — or persists the lot standalone. Mod domain logic lives in [`/lua/ui/modutilities.lua`](/lua/ui/modutilities.lua) (the `maputil.lua` sibling, fronting `/lua/mods.lua`). See [modselect/CLAUDE.md](modselect/CLAUDE.md). |
| [optionselect/](optionselect/CLAUDE.md) | the **options dialog**: three columns (lobby / scenario / mod options) over the selected scenario + mods, with search + hide-defaults filters; non-default options are marked. Derives the option *schema* per-peer (reference data) via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua); edits a working copy of the *values* and on OK routes the reconciled set through `RequestSetGameOptions` (synced via `GameOptions`). Host-only. See [optionselect/CLAUDE.md](optionselect/CLAUDE.md). |
| [CustomLobbyInterface.lua](CustomLobbyInterface.lua) | composition root, laid out in **areas** (flip the module `Debug` flag to tint them), sized for the **1024×768** floor: a **title bar** (title · team score · Leave) over a **slots region that owns the whole top** (the rows in **two columns** — odd slots left, even right — up to 16), and a **middle row** split into a left tabbed panel (Chat / Observers) and a right one (the config component), and a full-width **action bar** at the very bottom for the global actions (status + host-only Launch stub, and the like). The slots region is sized to its rows (two columns of `MaxSlots`/2); the two tabbed panels fill the room between it and the action bar. Holds the SlotCount + IsHost observers; Leave (Esc handler) + **Become observer** (`RequestMoveToObserver`, in the Observers tab). Also the rows' drag coordinator (`UICustomLobbySlotCoordinator`: hit-test, drop-highlight, drag ghost → `RequestSwapSlots`); `OpenDebug()` / hot-reload. |
| [CustomLobbyTeamScore.lua](CustomLobbyTeamScore.lua) | the **accumulated team rating** in the title — `Side A  N · M  Side B`. Shown only for the binary auto-team formations (`tvsb`→Top/Bottom, `lvsr`→Left/Right by start position; `pvsi`→Odd/Even by start-spot parity); **hidden** for `none`/`manual` (no 2-side split) or until a map's start positions are loaded. Reads the mode from `GameOptions().AutoTeams`, the ratings from each slot's `PL`. Reference data; never writes. |
| [CustomLobbyTabs.lua](CustomLobbyTabs.lua) | a **generic tabbed panel** (strip + content; one panel alive, created on select / destroyed on switch). Construct with a `{ Label, Create }` list + optional `OnSelect`. Used for the bottom-left (Chat / Observers); the config interface keeps its own bespoke variant (it coordinates the persistent preview). |
| [social/](social/) | the lobby's **bottom-left** column (the `CustomLobbyTabs` content): [`CustomLobbyChatPanel`](social/CustomLobbyChatPanel.lua) (the **Chat** tab — placeholder until the chat slice lands) and [`CustomLobbyObserversPanel`](social/CustomLobbyObserversPanel.lua) (the **Observers** tab — the shared observer list + a host-authoritative **Become observer** button → `RequestMoveToObserver`). Each is a tab content component (`Create(parent)`, created on select / destroyed on switch). |
| [config/](config/) | the lobby's **bottom-right** column. [`CustomLobbyConfigInterface.lua`](config/CustomLobbyConfigInterface.lua) is now just the **tab-list definition** (Map / Mods / Options / Restrictions) handed to a generic [`CustomLobbyTabs`](CustomLobbyTabs.lua); every tab — Map included — is a normal **created-on-select / destroyed-on-switch** panel. The **Map tab owns its own preview** ([`CustomLobbyMapPanel`](config/CustomLobbyMapPanel.lua): a large square preview filling the left, with the name + size/players/version line and the label/value details stacked in the column to its right; Change map at the bottom). Churning the preview is safe here because the lobby shows only **one** current map and the engine caches map textures by name, so re-opening the Map tab re-binds the cached texture — no leak. (The texture-leak rule only bites the *map-select dialog*, which browses hundreds of maps — see [mapselect/CLAUDE.md](mapselect/CLAUDE.md).) Other panels: [`CustomLobbyOptionsPanel`](config/CustomLobbyOptionsPanel.lua) (read-only options grouped **Lobby / Scenario / Mods** + hide-defaults toggle; map/mod options gold-flagged with an origin tooltip — schema via [`/lua/ui/optionutil.lua`](/lua/ui/optionutil.lua)), [`CustomLobbyModsPanel`](config/CustomLobbyModsPanel.lua) (enabled mods in **Game / UI** sections), [`CustomLobbyUnitsPanel`](config/CustomLobbyUnitsPanel.lua) (the **Restrictions** tab — placeholder). Each panel self-subscribes to the model + `IsHost`, and exposes `Initialize()` + `Create(parent)`. |
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
everyone via `OnPeerDisconnected`. The host can **pick the map** via a Change-Map button →
the map-select dialog (searchable list + preview), which sets `ScenarioFile` through the
`RequestSetScenario` intent and broadcasts it so every peer's preview updates. Launched via
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
