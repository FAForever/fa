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
| [CustomLobbyMapPreview.lua](CustomLobbyMapPreview.lua) / [CustomLobbyMapPreviewSpawn.lua](CustomLobbyMapPreviewSpawn.lua) | map preview (copied from the autolobby's, adapted to this model): subscribes to `ScenarioFile` (full render) + each slot (spawn-icon refresh); hidden until a scenario is set. Reuses the shared `/lua/ui/controls/mappreview.lua`. |
| [mapselect/](mapselect/CLAUDE.md) | the **map-select dialog** + its catalog and list, in their own folder (host-only `Popup`: searchable, filterable scenario list → `RequestSetScenario`). Self-contained sub-MVC; see [mapselect/CLAUDE.md](mapselect/CLAUDE.md) — including the **`MapPreview` texture-leak** writeup that shaped its design. |
| [CustomLobbyInterface.lua](CustomLobbyInterface.lua) | composition root (one model subscription for SlotCount); lays out slot rows + the observer strip, and acts as the rows' drag coordinator (`UICustomLobbySlotCoordinator`: hit-test, drop-highlight, drag ghost → `RequestSwapSlots`); `OpenDebug()` / hot-reload. |
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

1. **Options panel** — the next slice. The legacy `dialogs/mapselect.lua` bundled game options
   into the map dialog; we're splitting them out. Model the **option schema as a derivation** of
   `ScenarioFile` + `GameMods` (static lobby options ∪ the map's `_options.lua` ∪ mod options —
   computed per peer, *not* synced, like the map catalog), rendered against the synced
   `GameOptions` *values*. When the scenario/mods change, the controller **reconciles** the values
   (drop stale keys, seed new defaults) — see the `TODO` in `RequestSetScenario`. Merge rule:
   start with map/mod options only *adding* keys (no overriding base lobby options).
2. Remaining sub-dialogs (mods, units, presets, prefs) as mini-MVC, following the map-select shape.
3. Make slot controls interactive (faction/colour/team → controller **intents**).
4. Map-derived `SlotCount`; the GPGNet (`localPort == -1`) FAF-client path.

## Rules (same as autolobby)

- Components subscribe via `Derive`; they never write the model.
- The controller is the only writer, through the model write-helpers (never mutate a held table in place).
- A `Derive` handler must read its own LazyVar (`function(xLazy) self:OnX(xLazy()) end`).
- FAF is Lua 5.0 — no `%` operator; use `math.mod`.

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
| Memory climbs ~30 MB and never drops — not on re-texture, `ClearTexture`, `Destroy`, or dialog close | `MapPreview:SetTexture` / `SetTextureFromMap` allocate textures the engine **never frees** (no release API on the control or globally). Loading one per list row × hundreds of maps leaks memory the game needs in-match. | Don't put a `MapPreview` per list row. Render at most a **few** previews total (the map-select list is text-only; only the single candidate preview loads a texture, once per selection). The same applies to per-row `Bitmap` thumbnails via `SetNewTexture`. |

Reference implementation for all four: [mapselect/CustomLobbyMapSelect.lua](mapselect/CustomLobbyMapSelect.lua)
+ [mapselect/CustomLobbyMapList.lua](mapselect/CustomLobbyMapList.lua) (the pooled list's
`ScrollTop`, three-phase `Initialize`, post-loop `PoolCount`, nil-guarded `PaintRow`). The
texture-leak case is documented in depth in [mapselect/CLAUDE.md](mapselect/CLAUDE.md).
