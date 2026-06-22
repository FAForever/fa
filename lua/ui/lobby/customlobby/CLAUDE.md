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

## Two models

- **[CustomLobbyAuthoritativeModel.lua](CustomLobbyAuthoritativeModel.lua)** — the
  state the **host dictates** and that becomes part of the launched scenario: players,
  game options, mods, scenario, slot flags, identity. `Players` is an **array of
  per-slot LazyVars** so one slot's change re-fires only that row. Write helpers
  (`SetPlayer`, `SetPlayerField`, …) keep the copy-then-`Set` discipline.
- **[CustomLobbyModel.lua](CustomLobbyModel.lua)** — general, local, high-frequency
  state that is **not** part of the scenario (CPU benchmarks now; ping / connection
  status later). Kept separate so its churn doesn't dirty the authoritative snapshot.

## Status

| File | Role |
|------|------|
| [CustomLobbyAuthoritativeModel.lua](CustomLobbyAuthoritativeModel.lua) | host-dictated / scenario state (see above). |
| [CustomLobbyModel.lua](CustomLobbyModel.lua) | local connectivity state (CPU benchmarks + per-peer sim-performance history). |
| [CustomLobbyPerformancePopover.lua](CustomLobbyPerformancePopover.lua) | hover popover over the CPU column; hand-built bitmap bar chart of a peer's `PerformanceTrackingV2` history, with a yellow recommended-unit-cap line. |
| [CustomLobbyInstance.lua](CustomLobbyInstance.lua) | thin `moho.lobby_methods` shell; validates/dispatches traffic, forwards callbacks to the controller. |
| [CustomLobbyController.lua](CustomLobbyController.lua) | host-authority logic (free functions): seating, `Process*` handlers, intents (`RequestSetReady`, `RequestTakeSlot`, `RequestSwapSlots` — also callable from a future chat command), sharing the stored CPU benchmark. |
| [CustomLobbyMessages.lua](CustomLobbyMessages.lua) | message registry: `AddPlayer`, `SetPlayers`, `SetReady`, `TakeSlot`, `DisconnectPeer`, `ReportCpuBenchmark`, `SetCpuBenchmarks`. |
| [CustomLobbySlotInterface.lua](CustomLobbySlotInterface.lua) | one slot row; subscribes to its slot + CPU benchmarks; CPU column shows max units at +0 with a green→red cap-headroom square; click an open slot to take it, your own to toggle ready; the host can drag a row onto another to swap. |
| [CustomLobbyInterface.lua](CustomLobbyInterface.lua) | composition root (one model subscription for SlotCount); lays out slot rows and acts as their drag coordinator (`UICustomLobbySlotCoordinator`: hit-test, drop-highlight, drag ghost → `RequestSwapSlots`); `OpenDebug()` / hot-reload. |
| [/lua/ui/lobby/lobby.lua](../lobby.lua) | engine entry wrapper (`CreateLobby`/`HostGame`/`JoinGame`) → CustomLobby. Old lobby preserved at `lobby-old.lua`. |

Working today: host + clients see each other (host-authoritative player sync),
ready toggles round-trip, players can **take an open slot** (click it) and the host can
**swap two slots** (`RequestSwapSlots`, intent ready for a `/swap` command), each peer's
stored sim-performance benchmark is shared (no live stress test), and a **Leave** button
(or Esc) disconnects and returns to the menu — a leaving client frees its slot for
everyone via `OnPeerDisconnected`. Launched via
`scripts/LaunchCustomLobby.ps1`, or inspect UI only with
`UI_Lua import("/lua/ui/lobby/customlobby/customlobbyinterface.lua").OpenDebug()`.

## Next slices (per TARGET_ARCHITECTURE.md)

1. Make slot controls interactive (faction/colour/team → controller **intents**).
2. Options panel, map preview, observer list, footer, chat — each its own subscribing component.
3. Sub-dialogs (map select, mods, units, presets, prefs) as mini-MVC.
4. Map-derived `SlotCount`; the GPGNet (`localPort == -1`) FAF-client path.

## Rules (same as autolobby)

- Components subscribe via `Derive`; they never write the model.
- The controller is the only writer, through the model write-helpers (never mutate a held table in place).
- A `Derive` handler must read its own LazyVar (`function(xLazy) self:OnX(xLazy()) end`).
- FAF is Lua 5.0 — no `%` operator; use `math.mod`.
