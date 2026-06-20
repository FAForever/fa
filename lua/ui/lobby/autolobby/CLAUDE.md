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
| Model | [AutolobbyModel.lua](AutolobbyModel.lua) | Reactive singleton: raw synced state (player/game options, connection matrix, launch statuses) + derived view-models (`Connections`, `Statuses`, `Ownership`, `Scenario`) + the pure derivation helpers + the copy-then-`Set` write helpers. No UI, no networking. |
| Composition root | [AutolobbyInterface.lua](AutolobbyInterface.lua) | Builds and lays out the children; holds **no** model subscriptions. |
| Components | [AutolobbyConnectionMatrix.lua](AutolobbyConnectionMatrix.lua), [AutolobbyMapPreview.lua](AutolobbyMapPreview.lua) | Each subscribes to the model via `Derive`, feeds its dot grid / preview, and owns its own visibility. Never write the model. |
| Controller | [AutolobbyController.lua](AutolobbyController.lua) | `AutolobbyCommunications`, the engine's lobby object. The only writer to the model and the only place that talks to peers / the lobby server. |
| Entry point | [/lua/ui/lobby/autolobby.lua](/lua/ui/lobby/autolobby.lua) | Engine-facing wrapper: `CreateLobby` / `HostGame` / `JoinGame` / `ConnectToPeer` / `DisconnectFromPeer`. Bootstraps model + view + controller in that order. |

Like the chat (`ChatLinesInterface`, `ChatEditInterface`, … each subscribe to the
model themselves), the components own their reactivity. `AutolobbyInterface` is a
pure composition root, not a push hub.

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

| Derived | From | Consumed by |
|---------|------|-------------|
| `Connections` | `PlayerOptions`, `ConnectionMatrix`, `PlayerCount` | matrix |
| `Statuses` | `PlayerOptions`, `LaunchStatutes` | matrix |
| `Ownership` | `PlayerCount`, `PeerIdToIndex(PlayerOptions, LocalPeerId)`; `false` until the local index is known | matrix |
| `Scenario` | `{ ScenarioFile = GameOptions().ScenarioFile, PlayerOptions }` | preview |

`Scenario` is a bundle so the preview can subscribe with **one** observer that
reads **one** LazyVar — the same shape as every other observer. (An earlier
two-observer version that read the model directly instead of its LazyVar never
formed the dependency edge and silently stopped firing; bundling removes that
footgun.)

The pure derivation helpers (`PeerIdToIndex`, `CreateConnectionsMatrix`,
`CreateConnectionStatuses`, `CreateOwnershipMatrix`, `CreateLaunchStatus`,
`CanLaunch`, `CreateRatingsTable`, `CreateDivisionsTable`,
`CreateClanTagsTable`) are free functions in the model module. The model uses
them for its derived vars; the controller calls the launch-flow / alive-stamp
ones via `AutolobbyModel.<fn>`.

### Write helpers

Writes to the synced tables go through helpers that encapsulate the copy-then-`Set`
discipline, so call sites can't accidentally mutate in place: `SetPlayer`,
`SetPeerStatus`, `EnsurePeerStatus`, `SetPeerConnections`, `SetScenarioFile`,
`StampLaunchTables`. The controller calls these instead of building tables by hand.

`LocalPlayerName`, `HostID` and the rejoin parameters
(`LobbyParameters` / `HostParameters` / `JoinParameters`) stay
controller-internal — no view reads them and no derivation depends on them.

---

## Rules

- **The controller is the only writer to the model.** Components only read
  (subscribe via `Derive`) and render.
- **Write through the model helpers, never mutate a held table in place.** The
  synced tables (`PlayerOptions`, `ConnectionMatrix`, `LaunchStatutes`,
  `GameOptions`) are LazyVar values — mutating in place never marks dependents
  dirty (see [`/lua/ui/CLAUDE.md § 2`](/lua/ui/CLAUDE.md)). The write helpers
  encapsulate the `table.copy` → mutate → `:Set` dance; use them.
- **A `Derive` handler must read its own LazyVar.** `Derive` only forms the
  dependency edge when the handler calls `lv()`. A handler that reads the model
  some other way fires once at construction and then never again. Always
  `function(fooLazy) self:OnFoo(fooLazy()) end`.
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

For a quick visual check of the UI without any networking, mount it against a
fake-populated model from the console:

```
UI_Lua import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").OpenDebug()
```

`OpenDebug` builds a 4-player model with statuses and a fully-connected matrix;
`CloseDebug()` tears it down. (The map preview stays hidden unless you also
`AutolobbyModel.SetScenarioFile` with an installed scenario.)

For the real flow, lobby ↔ server traffic can't be exercised with the local
launch script. Use the two-client procedure documented in
[components/AutolobbyServerCommunicationsComponent.lua](components/AutolobbyServerCommunicationsComponent.lua)
(two FAF clients against the test server, command-line format
`"%s" /init init_local_development.lua`, both on the same PR, both searching).

Smoke checklist: the connection matrix fills as peers connect; launch statuses
progress (`Connecting` → `Missing local peers` → `Ready`); the map preview
appears; alive pings blink on incoming traffic; the game launches ~5s after all
peers are `Ready` with correct army numbering; rejoin rebuilds the lobby with
clean state.
