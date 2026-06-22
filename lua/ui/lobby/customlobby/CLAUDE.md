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
| [CustomLobbyMapCatalog.lua](CustomLobbyMapCatalog.lua) | cached enumeration of playable skirmish scenarios (`MapUtil.EnumerateSkirmishScenarios`). **Reference data — not a sync model**: identical on every peer, derived from disk, never on the wire. |
| [CustomLobbyMapSelect.lua](CustomLobbyMapSelect.lua) | the map-select dialog (transient `Popup`, host-only): searchable list (from the catalog) + candidate preview + info; Select calls the `RequestSetScenario` intent. Owns no synced state. First slice of splitting the legacy `dialogs/mapselect.lua` god-dialog — map selection only (options / mods / units become their own components). |
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
