# Custom-Game Lobby — Target Architecture (rebuild sketch)

A design sketch for rebuilding the custom-game lobby on the reactive-MVC pattern
proven in [`autolobby/`](autolobby/CLAUDE.md) and [`game/chat/`](/lua/ui/game/chat/CLAUDE.md).
Read alongside [`FEATURES.md`](FEATURES.md) (what it must do) and
[`USER_STORIES.md`](USER_STORIES.md) (from whose perspective).

This is a sketch, not final code. Representative code shapes are shown only for the
two load-bearing parts: the model and the host-authority flow.

---

## 1. Principles (carried from autolobby / chat)

- **Reactive model = single source of truth.** Replaces `gameInfo` + the ~10
  `SetSlotInfo`/`Refresh*` sledgehammers. Views subscribe via `Derive`; nobody pushes.
- **Thin `moho` Instance, logic in a free-function Controller.** The engine owns the
  `moho.lobby_methods` object; it forwards callbacks to a hot-reloadable controller
  (exactly the autolobby `AutolobbyInstance` ↔ `AutolobbyController` split).
- **Components own their reactivity and visibility.** A slot row subscribes to its
  own slot; the options panel to the options; etc. No parent push-hub.
- **Write discipline in the model.** All mutations go through model write-helpers
  (copy-then-`Set`), so in-place mutation can't silently break reactivity.
- **Standardize on `LazyVar`.** Drop `WatchedValueArray`/`WatchedValueTable`; use a
  per-slot array of `LazyVar`s for players/observers (per-slot granularity replaces
  per-field — a slot row is small enough to rebuild on any of its fields changing).

**The one thing the autolobby does NOT teach: host authority.** The autolobby is
single-writer (host computes everything). The custom lobby is request→validate→
broadcast. That shapes the Controller (§5) and is the main new design work.

---

## 2. Layer overview

```
                 engine callbacks
                        │
            ┌───────────▼────────────┐
            │  LobbyInstance          │  moho.lobby_methods, thin shell
            │  (engine ABI + dispatch)│  validation via LobbyMessages
            └───────────┬────────────┘
            forwards (passing self)         ▲ BroadcastData / SendData
                        │                   │
            ┌───────────▼────────────┐      │
            │  LobbyController        │──────┘  the only writer to the model
            │  intents · host-ops ·   │         and the only one talking to peers
            │  wire-handlers          │
            └───────────┬────────────┘
                writes via helpers
                        │
            ┌───────────▼────────────┐
            │  LobbyModel (+ submodels)│  reactive LazyVars + derived + write helpers
            └───────────┬────────────┘
                 OnDirty / Derive
                        │
        ┌───────────────┼───────────────────────────┐
        ▼               ▼                            ▼
   Components       Sub-dialogs (mini-MVC)      Reused widgets
 (slots, options,  (map select, mods, units,   (map preview, chat-MVC,
  observers, …)     presets, lobby prefs)        faction selector, …)
```

UI never writes the model. UI calls **controller intents**; the controller writes
the model (host) or sends a request (client); wire-handlers apply authoritative state.

---

## 3. Model decomposition

`gameInfo` becomes a small package of focused reactive models (like chat's
`ChatModel` + `ChatConfigModel`). Suggested split:

### `LobbyModel` — the synced game state (the gameInfo replacement)

| LazyVar | Replaces | Notes |
|---|---|---|
| `Players[1..N]` (array of LazyVars) | `gameInfo.PlayerOptions` | each slot a LazyVar of `PlayerData\|false` |
| `Observers[1..M]` (array of LazyVars) | `gameInfo.Observers` | |
| `ClosedSlots`, `SpawnMex` | same | slot-flag tables |
| `GameOptions` | `gameInfo.GameOptions` | one table; write via helper |
| `GameMods` | `gameInfo.GameMods` | selected sim/ui set |
| `AutoTeams` | `gameInfo.AutoTeams` | slot→team |
| `ScenarioFile` | `GameOptions.ScenarioFile` | split out so the preview observes it directly |
| `LocalPeerId`, `HostID`, `IsHost`, `LocalPlayerName` | globals | identity |

**Derived** (computed, never written): `Scenario` (bundle `{ScenarioFile, Players}`),
`AvailableColors[slot]`, `PlayersNotReady`, `CanLaunch`, `GameQuality`,
`SlotMenu[slot]` (the right-click model), `PlayerCount`. These replace
`Check_Availaible_Color`, `GetPlayersNotReady`, `RefreshButtonEnabledness`,
`ShowGameQuality`, `GetSlotMenuTables`.

### `LobbyConnectivityModel` — local, high-frequency, NOT part of the synced game state

`ConnectionStatus[peer]`, `Ping[peer]`, `CPUBenchmarks[name]`, `AvailableMods[peer]`,
`BadMap[peer]`. Kept separate so frequent ping/CPU churn doesn't dirty game state.

### `LobbyPrefsModel` — local UI preferences

`Committed` / `Pending` like [`ChatConfigModel`](/lua/ui/game/chat/config/ChatConfigModel.lua):
background mode, chat font, snowflakes, windowed, stretch, chat colours.

### Chat — reuse the chat MVC

Lobby chat is the same shape as in-game chat; reuse the model/controller, or a thin
lobby-scoped mirror. Do not reinvent.

Model write-helpers (mirroring autolobby's `SetPlayer`/`SetPeerStatus`/…):
`SetPlayer(slot, data)`, `ClearPlayer(slot)`, `SetObserver`, `SetPlayerField(slot, key, value)`,
`SetGameOption(key, value)`, `SetClosed(slot, …)`, `SetMods(…)`, `SetScenario(file)`.

```lua
-- shape (per autolobby AutolobbyModel)
function SetPlayerField(model, slot, key, value)
    local p = table.copy(model.Players[slot]() or {})
    p[key] = value
    model.Players[slot]:Set(p)        -- only slot `slot`'s subscribers re-fire
end
```

---

## 4. `LobbyInstance` — the thin `moho` shell

Same role as [`AutolobbyInstance`](autolobby/AutolobbyInstance.lua): the C-bound
object the engine instantiates. Keeps engine-ABI wrappers (`BroadcastData`,
`SendData`, `EjectPeer`, `LaunchGame`, `GetPeers`, …, with their `LobbyMessages`
validation), the command-line/identity creators, and `DataReceived`'s
validate→accept→dispatch. Every callback with behaviour forwards to the controller:

```lua
Hosting        = function(self) LobbyController.OnHosting(self) end,
DataReceived   = function(self, data) ... validate ... LobbyMessages[data.Type].Handler(self, data) end,
PeerDisconnected = function(self, name, id) LobbyController.OnPeerDisconnected(self, name, id) end,
GameLaunched   = function(self) LobbyController.OnGameLaunched(self) end,
```

Does **not** hot-reload (live C object) — keep it thin; behaviour lives in the controller.

---

## 5. `LobbyController` — the logic (and host authority)

A package of free-function modules (split by domain, like chat's `commands/` and
`config/`). Each function takes the `instance` as its first arg (for
`BroadcastData`/`SendData`/`IsHost`). Three faces:

### 5a. Local intents (called by the UI)
What the local user asks for. Each decides host vs client:

```lua
-- PlayerController
function RequestSetColor(instance, slot, color)
    if instance:IsHost() then
        HostSetColor(instance, slot, color)            -- authoritative path
    else
        instance:SendData(LobbyModel.GetSingleton().HostID(),
            { Type = 'RequestColor', Slot = slot, Color = color })
    end
end
```

### 5b. Host operations (host-only authority: validate → apply → broadcast)

```lua
function HostSetColor(instance, slot, color)
    if not LobbyModel.IsColorFree(LobbyModel.GetSingleton(), color, slot) then return end
    LobbyModel.SetPlayerField(LobbyModel.GetSingleton(), slot, 'PlayerColor', color)
    instance:BroadcastData({ Type = 'SetColor', Slot = slot, Color = color })
end
```

### 5c. Wire handlers (apply authoritative state arriving from the network)

```lua
function OnSetColor(instance, data)        -- registered as LobbyMessages.SetColor.Handler
    LobbyModel.SetPlayerField(LobbyModel.GetSingleton(), data.Slot, 'PlayerColor', data.Color)
end
```

### The host-authority data flow (the defining difference)

```
client UI ── intent ──► RequestX ──(not host)── SendData ─► host
                                                              │ HostX: validate
host UI ── intent ──► RequestX ──(host)──► HostX ◄────────────┘
                                   │ apply to model + BroadcastData
                                   ▼
                         every client: OnX wire-handler ─► apply to model ─► views react
```

Validation lives in the **message registry** `LobbyMessages.lua` (mirroring
[`AutolobbyMessages`](autolobby/AutolobbyMessages.lua)): a table of
`{ Validate, Accept, Handler }` per type, `Handler → LobbyController.OnX`. `Accept`
encodes `IsFromHost` / `AmHost` / ownership checks. ~30 entries (the full set in
[`FEATURES.md`](FEATURES.md) § "Network message catalog").

Suggested controller modules: `LobbyController` (lifecycle, dispatch, launch),
`PlayerController` (slots/players/AI/observers — intents + host-ops + handlers),
`OptionsController`, `ModsController`, `ConnectivityController`.

---

## 6. Components (views)

Each subscribes to its slice and feeds dumb children — replacing the refresh sledgehammers.

| Component | Subscribes to | Calls (intents) | Replaces |
|---|---|---|---|
| `LobbySlotInterface` (per slot) | `Players[slot]`, `AvailableColors[slot]`, `SlotMenu[slot]`, connectivity `Ping/CPU` | faction/colour/team/ready/move/kick/AI intents | per-slot part of `SetSlotInfo` |
| `LobbySlotsInterface` | `PlayerCount`, slot structure | — | `CreateSlotsUI` |
| `LobbyObserverListInterface` | `Observers`, connectivity | become-player / kick | `refreshObserverList` |
| `LobbyOptionsPanelInterface` | `GameOptions` (+ derived display) | open options/map/mods dialogs (host) | `RefreshOptionDisplayData` |
| `LobbyMapPreviewInterface` | `Scenario` | start-position intents | map preview wiring |
| `LobbyFooterInterface` | `CanLaunch`, `PlayersNotReady`, `IsHost` | launch, ready, leave | `RefreshButtonEnabledness` |
| `LobbyChatInterface` | chat model | chat controller | chat area |

`LobbyInterface` is the **composition root** (build + lay out children, no
subscriptions) — exactly like `AutolobbyInterface`.

---

## 7. Sub-dialogs as mini-MVC

Each heavy dialog is its own small MVC, reading the model and calling controller
intents on apply (like chat's `config/` trio):

| Dialog | Reads | On apply → controller | Reuse |
|---|---|---|---|
| Map select | map list, `Scenario` | `HostSetScenario` | `ResourceMapPreview` |
| Mods manager | `AvailableMods`, `GameMods` | `HostSetMods` | `ModsManager.lua` (port) |
| Unit manager | `GameOptions.RestrictedCategories` | `HostSetRestrictedCategories` | `UnitsManager.lua` (port) |
| Presets | preset storage | `ApplyGameSettings` via controller | `presets.lua` storage |
| Lobby prefs | `LobbyPrefsModel.Pending` | `LobbyPrefsController` Apply/Set | pattern from `ChatConfig` |

---

## 8. Reuse vs rebuild

- **Port mostly as-is**: `ResourceMapPreview`, `ModsManager`, `UnitsManager`,
  `lobbyOptions.lua` (option *data*), faction selector, CPU benchmark, presets
  storage, chat-MVC. Give each a model-backed input + a controller callback.
- **Rebuild against the model**: slot/player sync (`SetSlotInfo` + `HostUtils`),
  the message dispatch, host-authority validation, connection tracking. This is
  where the value and the risk concentrate.

---

## 9. Bootstrap & lifecycle

Order (from autolobby's lesson): in the entry wrapper (`lobby.lua`'s `CreateLobby`
equivalent) set up **models → views → instance**, so views subscribe to a live
model and the instance's `__init` seeds an existing model. On the connecting client,
the host's full `GameInfo` message seeds the model (one wire-handler that bulk-sets).

Hot-reload: model + views + controller reload (own `__moduleinfo` hooks); the
`LobbyInstance` C object does not — keep it thin. Long-running threads (ping/CPU
loops) reload only on the next lobby, as in autolobby.

A debug `OpenDebug()` (fake-populated model + views, no networking) lets the whole
lobby be inspected without a real game — the standalone-invocation principle.

---

## 10. Domain → architecture mapping (A–Q from FEATURES.md)

| Domain | Model | Controller | View / Dialog |
|---|---|---|---|
| A Lifecycle/entry | identity fields | `LobbyController` lifecycle + `OnHosting`/`OnConnect`/`OnGameLaunched` | entry wrapper, composition root |
| B Slots & players | `Players`, `ClosedSlots`, `SpawnMex`, derived `SlotMenu` | `PlayerController` (move/swap/kick/close) | `LobbySlotInterface` |
| C Per-player settings | `Players[slot]` fields, `AvailableColors` | `PlayerController` intents + host-ops | slot row controls |
| D AI | `Players[slot]` (AI) | `PlayerController` AddAI/RemoveAI | slot menu |
| E Observers | `Observers` | `PlayerController` convert/kick | `LobbyObserverListInterface` |
| F Host authority | `IsHost`, derived gates | all host-ops + `LobbyMessages.Accept` | footer enable/disable |
| G Game options | `GameOptions` | `OptionsController` | `LobbyOptionsPanelInterface`, options dialog |
| H Auto-teams/spawn | `AutoTeams`, `GameOptions.TeamSpawn` | `OptionsController` + launch-time resolves | options panel, map preview |
| I Map selection | `ScenarioFile`, `Scenario` | `HostSetScenario` | map select dialog + preview |
| J Mods | `GameMods`, conn `AvailableMods` | `ModsController` | mods manager dialog |
| K Unit restrictions | `GameOptions.RestrictedCategories` | `OptionsController` | unit manager dialog |
| L Chat | chat model | chat controller | `LobbyChatInterface` (reuse) |
| M Connectivity | `LobbyConnectivityModel` | `ConnectivityController` (CPU/ping/connection) | ping/CPU bars, observer/slot rows |
| N Compatibility/validation | conn `BadMap`, identity | `LobbyMessages.Accept`, launch checks | launch blockers, system chat |
| O Presets/rehost | `GameOptions`/`Players` snapshot | `LobbyController` apply/rehost | presets dialog |
| P Lobby prefs | `LobbyPrefsModel` | `LobbyPrefsController` | lobby prefs dialog |
| Q Other dialogs | (various) | host-ops | briefing, big preview, save/load |

---

## 11. Open decisions & risks

- **Migration**: parallel package (e.g. `/lua/ui/lobby/custom/`) behind a toggle vs
  in-place strangler of `lobby.lua`. A parallel rebuild needs a parity period measured
  against `FEATURES.md`/`USER_STORIES.md`; the strangler keeps it shippable throughout.
- **Reactivity granularity**: per-slot LazyVars (proposed) vs per-field. Per-slot is
  simpler and enough; revisit only if a row's rebuild cost ever shows up.
- **Connectivity model boundary**: keep ping/CPU out of the synced game state (proposed)
  to avoid churn dirtying game state — confirm no view needs them coupled.
- **Host migration / reconnect**: the current lobby's reconnect/keep-alive and
  rehost edge-cases are the least-understood surface; inventory them deeply before
  committing (the highest parity risk).
- **One model vs submodels**: proposed split is `LobbyModel` + `Connectivity` +
  `Prefs` + reused chat. Resist over-splitting the core game state — it's one
  consistent snapshot the host broadcasts.
