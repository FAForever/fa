# Autolobby — Architecture Guide

The automated lobby (used for matchmaking / automatch games) follows the same
reactive MVC structure as the in-game chat: a reactive **model**, a dumb
**view** that observes it, and a **controller** that is the only writer.

> **Read first:** [`/lua/ui/CLAUDE.md`](/lua/ui/CLAUDE.md) for project-wide UI
> patterns (`__init` vs `__post_init`, LazyVars and `Derive`, `TrashBag`) and
> [`/lua/ui/game/chat/CLAUDE.md`](/lua/ui/game/chat/CLAUDE.md) for the chat
> refactor this mirrors. This doc only covers what is autolobby-specific.

---

## Architecture

```
engine ──callbacks──► AutolobbyController (moho.lobby_methods)
                              │ writes (:Set)
                              ▼
                      AutolobbyModel  (LazyVars, singleton)
                              │ OnDirty / Derive
                              ▼
                      AutolobbyInterface (view, reads)
```

| Role | File | Responsibility |
|------|------|----------------|
| Model | [AutolobbyModel.lua](AutolobbyModel.lua) | Reactive singleton: raw synced state (player/game options, connection matrix, launch statuses) + derived view-models (`Connections`, `Statuses`, `Ownership`) + the pure derivation helpers. No UI, no networking. |
| View | [AutolobbyInterface.lua](AutolobbyInterface.lua) | Observes the model via `Derive` and feeds the child controls ([AutolobbyMapPreview.lua](AutolobbyMapPreview.lua), [AutolobbyConnectionMatrix.lua](AutolobbyConnectionMatrix.lua)). Never writes the model. |
| Controller | [AutolobbyController.lua](AutolobbyController.lua) | `AutolobbyCommunications`, the engine's lobby object. The only writer to the model and the only place that talks to peers / the lobby server. |
| Entry point | [/lua/ui/lobby/autolobby.lua](/lua/ui/lobby/autolobby.lua) | Engine-facing wrapper: `CreateLobby` / `HostGame` / `JoinGame` / `ConnectToPeer` / `DisconnectFromPeer`. Bootstraps model + view + controller in that order. |

---

## The key difference from chat

The chat controller is a module of free functions. **The autolobby controller
cannot be** — it is a `moho.lobby_methods` subclass that the *engine*
instantiates via `InternalCreateLobby` (in [autolobby.lua](/lua/ui/lobby/autolobby.lua))
and whose callbacks (`Hosting`, `DataReceived`, `EstablishedPeers`, …) the
engine calls. So:

- The controller stays a C-bound class. We extracted only its **state** (into
  the model) and its **view coupling** (it used to push into the view via
  `interface:Update*`; it now writes the model and the view reacts).
- **The controller does not hot-reload.** Unlike `ChatController.Init`, which
  re-binds via `__moduleinfo.OnReload`, the live C object keeps its bound
  methods and threads across a reload of this file. Edits to
  `AutolobbyController.lua` only take effect on the next `CreateLobby`. The
  model and the view *do* hot-reload (own `__moduleinfo` hooks), and because
  state now lives in the model, a view reload restores itself by re-reading the
  surviving model — no manual state replay.

---

## Model

`UIAutolobbyModel` ([AutolobbyModel.lua](AutolobbyModel.lua)) is a flat set of
`LazyVar`s plus a few derived ones.

**Raw** (written by the controller): `PlayerCount`, `LocalPeerId`,
`PlayerOptions`, `GameOptions`, `GameMods`, `ConnectionMatrix`, `LaunchStatutes`,
`IsAliveStamp`.

**Derived** (computed via `:Set(function() … end)`, never written directly):

| Derived | From | Replaces the old push |
|---------|------|-----------------------|
| `Connections` | `PlayerOptions`, `ConnectionMatrix`, `PlayerCount` | `interface:UpdateConnections` |
| `Statuses` | `PlayerOptions`, `LaunchStatutes` | `interface:UpdateLaunchStatuses` |
| `Ownership` | `PlayerCount`, `PeerIdToIndex(PlayerOptions, LocalPeerId)`; `false` until the local index is known | `interface:UpdateOwnership` |

The scenario preview is not a derived var — the view observes `GameOptions`
(for `ScenarioFile`) and `PlayerOptions` together.

The pure derivation helpers (`PeerIdToIndex`, `CreateConnectionsMatrix`,
`CreateConnectionStatuses`, `CreateOwnershipMatrix`, `CreateLaunchStatus`,
`CanLaunch`, `CreateRatingsTable`, `CreateDivisionsTable`,
`CreateClanTagsTable`) are free functions in the model module. The model uses
them for its derived vars; the controller calls the launch-flow / alive-stamp
ones via `AutolobbyModel.<fn>`.

`LocalPlayerName`, `HostID` and the rejoin parameters
(`LobbyParameters` / `HostParameters` / `JoinParameters`) stay
controller-internal — no view reads them and no derivation depends on them.

---

## Rules

- **The controller is the only writer to the model.** The view only reads
  (subscribes via `Derive`) and the child controls only render.
- **Never mutate a held table in place.** The synced tables (`PlayerOptions`,
  `ConnectionMatrix`, `LaunchStatutes`, `GameOptions`) are LazyVar values:
  `table.copy` → mutate the copy → `:Set` it, or dependents never go dirty. See
  [`/lua/ui/CLAUDE.md § 2`](/lua/ui/CLAUDE.md).
- **`IsAliveStamp` is a pulse, not state.** Set a fresh `{Index, Time}` table on
  every receive so the value identity always changes and the observer fires even
  for repeated pulses from the same peer.
- **Bootstrap order matters.** `CreateLobby` sets up the model *before* the view
  so the view subscribes against it, and *before* the controller so the
  controller's `__init` seeds an existing model. Rejoin re-runs `CreateLobby`,
  which calls `SetupSingleton` and thus resets the model to fresh state — a new
  lobby must not inherit stale connection / launch state.

---

## Verifying changes

Lobby ↔ server traffic can't be exercised with the local launch script. Use the
two-client procedure documented in
[components/AutolobbyServerCommunicationsComponent.lua](components/AutolobbyServerCommunicationsComponent.lua)
(two FAF clients against the test server, command-line format
`"%s" /init init_local_development.lua`, both on the same PR, both searching).

Smoke checklist: the connection matrix fills as peers connect; launch statuses
progress (`Connecting` → `Missing local peers` → `Ready`); the map preview
appears; alive pings blink on incoming traffic; the game launches ~5s after all
peers are `Ready` with correct army numbering; rejoin rebuilds the lobby with
clean state.
