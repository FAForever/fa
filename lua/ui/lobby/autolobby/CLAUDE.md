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
engine ──callbacks──► AutolobbyInstance (moho.lobby_methods, thin shell)
                              │ forwards (passing self)
                              ▼
                      AutolobbyController (logic, free functions)
                              │ writes via model helpers
                              ▼
                      AutolobbyModel  (LazyVars, singleton)
                              │ OnDirty / Derive
                              ▼
                      AutolobbyInterface (composition) → matrix / preview (read)
```

| Role | File | Responsibility |
|------|------|----------------|
| Model | [AutolobbyModel.lua](AutolobbyModel.lua) | Reactive singleton: raw synced state + derived view-models (`Connections`, `Statuses`, `Ownership`, `Scenario`) + the pure derivation helpers + the copy-then-`Set` write helpers. No UI, no networking. |
| Instance | [AutolobbyInstance.lua](AutolobbyInstance.lua) | The `moho.lobby_methods` object the engine instantiates. Thin shell: engine-ABI wrappers + validation/dispatch + command-line creators stay here; callbacks with behaviour forward to the controller. |
| Controller | [AutolobbyController.lua](AutolobbyController.lua) | The lobby logic as **free functions** (`OnHosting`, `OnEstablishedPeers`, `Process*`, threads, `Rejoin`, launch-flow). The only writer to the model. Hot-reloadable. |
| Composition root | [AutolobbyInterface.lua](AutolobbyInterface.lua) | Builds and lays out the children; holds **no** model subscriptions. |
| Components | [AutolobbyConnectionMatrix.lua](AutolobbyConnectionMatrix.lua), [AutolobbyMapPreview.lua](AutolobbyMapPreview.lua) | Each subscribes to the model via `Derive`, feeds its dot grid / preview, and owns its own visibility. Never write the model. |
| Entry point | [/lua/ui/lobby/autolobby.lua](/lua/ui/lobby/autolobby.lua) | Engine-facing wrapper: `CreateLobby` / `HostGame` / `JoinGame` / `ConnectToPeer` / `DisconnectFromPeer`. Bootstraps model + view + instance in that order. |

Like the chat (`ChatLinesInterface`, `ChatEditInterface`, … each subscribe to the
model themselves), the components own their reactivity. `AutolobbyInterface` is a
pure composition root, not a push hub.

---

## Instance vs Controller

The chat controller is a module of free functions; the engine doesn't own it. The
autolobby's engine object (`AutolobbyInstance`) *is* owned by the engine — it
instantiates it via `InternalCreateLobby` and calls its callbacks. So the
autolobby uses a **humble-object** split:

- **`AutolobbyInstance`** is the C-bound shell. It keeps what is genuinely
  engine-adjacent: the `moho` overrides (`BroadcastData` / `SendData` / …, with
  their `AutolobbyMessages` validation), `DataReceived`'s validate→accept→dispatch,
  and the command-line creators (`CreateLocalPlayer` / `CreateLocalGameOptions`,
  which lean on the mixed-in argument component). Trivial callbacks (a single
  `SendXToServer`) stay inline; callbacks with behaviour forward to the controller.
- **`AutolobbyController`** holds the behaviour as free functions taking the
  instance as their first argument (`OnHosting(instance)`, etc.). `AutolobbyMessages`
  routes each validated message straight to `AutolobbyController.Process*`.

**Why:** the logic becomes **hot-reloadable** — the instance's forwarders resolve
through the live controller module table, so editing a handler takes effect
without re-hosting. It is also testable with a mock instance. Two caveats:

- The **instance does not hot-reload** (the live C object keeps its bound methods
  across a reload of `AutolobbyInstance.lua`). Keep it thin; edits there need a new
  `CreateLobby`. The view and model hot-reload on their own.
- The **threads don't hot-reload** either — a forked `ShareLaunchStatusThread` /
  `LaunchThread` holds the function it started with, so thread edits take effect
  on the next lobby. The message/event handlers do reload.

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
(`LobbyParameters` / `HostParameters` / `JoinParameters`) live on the
**instance** — no view reads them and no derivation depends on them.

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
  so the view subscribes against it, and *before* the instance so the instance's
  `__init` seeds an existing model. Rejoin re-runs `CreateLobby`,
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
