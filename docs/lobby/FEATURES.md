# Custom-Game Lobby — Feature Inventory (parity yardstick)

This catalogs **everything the current custom-game lobby does**, so a ground-up
MVC rebuild has a measurable parity target. It is a behaviour spec, not a design.

> Line references are **approximate** (gathered by code exploration; the files
> drift). Treat them as "look near here", and re-confirm against current source.
> Primary sources: [`/lua/ui/lobby/lobby.lua`](/lua/ui/lobby/lobby.lua) (~7400 lines),
> [`/lua/ui/lobby/lobbyComm.lua`](/lua/ui/lobby/lobbyComm.lua),
> [`/lua/ui/lobby/lobbyOptions.lua`](/lua/ui/lobby/lobbyOptions.lua),
> [`/lua/ui/lobby/ModsManager.lua`](/lua/ui/lobby/ModsManager.lua),
> [`/lua/ui/lobby/UnitsManager.lua`](/lua/ui/lobby/UnitsManager.lua),
> [`/lua/ui/lobby/presets.lua`](/lua/ui/lobby/presets.lua),
> [`/lua/ui/lobby/gameselect.lua`](/lua/ui/lobby/gameselect.lua),
> [`/lua/ui/dialogs/mapselect.lua`](/lua/ui/dialogs/mapselect.lua),
> [`/lua/ui/lobby/data/gamedata.lua`](/lua/ui/lobby/data/gamedata.lua),
> [`/lua/ui/lobby/data/playerdata.lua`](/lua/ui/lobby/data/playerdata.lua).

## What we're replacing (scale)

- `lobby.lua` alone is ~7,400 lines; the lobby ecosystem ~10,700 lines.
- Central state `gameInfo` is a hybrid: plain tables (`GameOptions`, `ClosedSlots`,
  `SpawnMex`, `GameMods`, `AutoTeams`) + reactive `WatchedValueArray` for
  `PlayerOptions` / `Observers`. **The reactivity primitive already exists** and
  there's a standing TODO to replace `SetSlotInfo` sledgehammers with lazy callbacks.
- Networking: **host-authority**. Non-hosts send requests; host validates and
  broadcasts authoritative state. ~30 message types. Full `GameInfo` dump on join.
- UI is driven by ~10 "refresh-everything" functions (`SetSlotInfo`,
  `RefreshOptionDisplayData`, `refreshObserverList`, …) called after each change.

---

## A. Lifecycle & entry

| Feature | Who | Trigger / function | Notes |
|---|---|---|---|
| Game discovery list | all | `gameselect.lua` LAN/IP discovery | shows map, name, players |
| Create game | host | `gameselect.lua` → `gamecreate` | nickname validation 2–32 chars |
| Direct IP connect | all | IP+port input, stored in prefs | |
| Host a lobby | host | `HostGame` (lobby.lua ~780); `lobbyComm.Hosting` (~5706) | loads last scenario/options from prefs, host into slot 1, keep-alive thread (30s) |
| Join a lobby | client | `JoinGame` (~788); `ConnectionToHostEstablished` (~5596) | sends `SetAvailableMods` + `AddPlayer`; host replies with full `GameInfo` |
| Leave / abort | all | `ReturnToMenu` (~1878), Escape handler (~669) | confirm dialog; destroys `lobbyComm`/`GUI`; quit-to-desktop if `/gpgnet` |
| Rehost | host | `/rehost` flag (~179, ~5812) | restores last-game preset, reassigns players/AIs to prior slots |
| Launch transition | host | `GameLaunched` (~5677) | saves loading faction, kills threads, destroys UI + comm |

---

## B. Slots & players

**Slot states & context menu** (`GetSlotMenuData` ~246, `GetSlotMenuTables` ~341, `DoSlotBehavior` ~548):

| Slot state | Host menu entries | Client menu entries |
|---|---|---|
| Open | Close, Close-spawn-mex (adaptive), Occupy | Occupy |
| Closed | Open, Close-spawn-mex (adaptive) | — |
| Human-occupied | Whisper, Move to Observer, Kick, Move to slot N | Whisper |
| AI-occupied | Remove (Kick), AI personality list | — |

**Actions:**

| Feature | Who | Function | Message | State |
|---|---|---|---|---|
| Open/close slot | host | `HostUtils.SetSlotClosed` (~6839) | `SlotClosed` | `ClosedSlots[slot]` |
| Close + spawn-mex (adaptive) | host | `SetSlotClosedSpawnMex` (~6859) | `SlotClosedSpawnMex` | `ClosedSlots`+`SpawnMex` |
| Occupy empty slot | player | host: `MovePlayerToEmptySlot` (~7039); client → host | `MovePlayer`→`SlotMove` | move player, force unready |
| Move player to slot | host | `SwapPlayers` (~7078) | `SlotMove`/`SwapPlayers` | relocate, unready |
| Swap two players | host | `SwapPlayers`/`DoSlotSwap` (~6762) | `SwapPlayers` | swap incl. team, unready both |
| Kick player | host | `EjectPeer` + confirm dialog (~590) | engine eject + `SystemMessage` | slot cleared; kick msg saved to prefs |

**Slot row display** (`CreateSlotsUI` ~2718, `SetSlotInfo` ~1032, `ClearSlotInfo` ~1245):
slot #, country flag, rating (R: mean±3·dev tooltip), games (G:), name (context-menu
combo, colour-coded host/player/you/AI), colour combo, faction combo, team combo,
CPU bar, ping bar, ready checkbox. `SetSlotInfo` recomputes the whole row on any change.

---

## C. Per-player settings

| Feature | Who | Function | Message | Notes |
|---|---|---|---|---|
| Faction | player (own) / host (AI) | faction combo + large selector `CreateUI_Faction_Selector` (~6375) | `PlayerOptions{Faction}` | per-map availability; random=5 resolved at launch; sets skin; saved to prefs |
| Colour | player (own) / host | colour combo; `Check_Availaible_Color` (~6706), `IsColorFree` (~1304) | client `RequestColor` → host `SetColor` | **scarcity**: taken colours hidden; host validates/reverts |
| Team | player (own) / host | team combo | `PlayerOptions{Team}` | disabled when AutoTeams active or ready; backend team = UI team+1 |
| Ready | player (own) | ready checkbox (~2991) | `PlayerOptions{Ready}` | disables own controls; gates launch; host can force-unready (`SetPlayerNotReady`) |
| Start position | player/host | map-preview click/drag `ConfigureMapListeners` (~4931) | `MovePlayer`/`SlotMove`/`AutoTeams` | fixed-spawn: move self; host swap mode; manual AutoTeams via map clicks |

---

## D. AI management (host-only)

| Feature | Function | Message | Notes |
|---|---|---|---|
| Add AI | `HostUtils.AddAI` → `TryAddPlayer` (~7186) | `SlotAssigned` | personality list from `aitypes.lua` (`GetAItypes`); AI auto-ready, `Human=false` |
| Remove AI | `HostUtils.RemoveAI` (~6988) | `ClearSlot` | |
| AI rating | `ComputeAIRating` (~456), `GetAIPlayerData` (~503) | — | from cheat/build/map multipliers + omni bonus (per `AILobbyProperties`) |
| AI faction/colour/team | via PlayerData | `PlayerOptions` | colour from `GetAvailableColor`/inherited; team via AutoTeams or explicit |
| Move/swap AI | `SwapPlayers`/`MovePlayerToEmptySlot` | `SlotMove`/`SwapPlayers` | same path as players |
| Fill slots | "Fill Slots" + AI combo (~3210) | `SlotAssigned` ×N | |

---

## E. Observers

| Feature | Who | Function | Message |
|---|---|---|---|
| Join as observer | auto (slots full / requested) | `TryAddObserver` (~7113) | `ObserverAdded` |
| Player → observer | host or player-request | `ConvertPlayerToObserver` (~6879) / `RequestConvertToObserver` | `ConvertPlayerToObserver` |
| Observer → player | host or observer-request | `ConvertObserverToPlayer` (~6923) / `RequestConvertToPlayer` (opt. slot) | `ConvertObserverToPlayer` |
| Observer list UI | all | `refreshObserverList` (~926) | name + rating + ping + CPU; team ratings if >2 teams |
| Kick observer | host | `KickObservers` (~7379) | engine eject; also auto-kick at launch if observers disallowed |
| Observer chat | observer | `AddChatText` greys observer names | `PublicChat`/`PrivateChat` |
| Rehost slot negotiation | host | `FindRehostSlotForID` (~841) | observers reclaim prior slots on rehost |

---

## F. Host authority & validation

- **Pattern**: client mutates own slot → broadcasts `PlayerOptions` (host `Accept`
  checks `SenderID == OwnerID`); non-owned mutations go request→host-validate→broadcast.
  Host-only gate: `AmHost` (~5067) on relevant handlers.
- **Optimistic UI**: client applies colour locally, host may revert (~5357).
- **Ready-gating**: `RefreshButtonEnabledness` (~7248) disables host option buttons
  while any human is not ready; launch enabled only when all ready (or single-player / host-observes).
- **Force unready**: `SetPlayerNotReady` (one), `SetAllPlayerNotReady` (all, on option reset).
- **Race guards**: e.g. ignore a move request if the player became ready meanwhile (~5323).

---

## G. Game options (complete enumeration — `lobbyOptions.lua`)

### Team options (~72–226)
| Key | Values | Default |
|---|---|---|
| `TeamSpawn` | fixed, penguin_autobalance, random, balanced, balanced_flex, random_reveal, balanced_reveal, balanced_reveal_mirrored, balanced_flex_reveal | fixed |
| `TeamLock` | locked, unlocked | locked |
| `AutoTeams` | none, tvsb, lvsr, pvsi, manual | none |
| `CommonArmy` | Off, UnionWhenDisconnected, Union, Common | Off |
| `TeamShareOverflow` | enabled, disabled | enabled |

### Global options (~229–706)
| Key | Values | Default |
|---|---|---|
| `Share` | FullShare, ShareUntilDeath, PartialShare, TransferToKiller, Defectors, CivilianDeserter | FullShare |
| `DisconnectShare` | SameAsShare | SameAsShare |
| `DisconnectShareCommanders` | Explode | Explode |
| `ShareUnitCap` | none, allies, all | allies |
| `ManualUnitShare` | all, no_builders, none | all |
| `RestrictedCategories` | set (Unit Manager) | none |
| `Victory` | demoralization, decapitation, domination, eradication, sandbox | demoralization |
| `FogOfWar` | explored, none | explored |
| `GameSpeed` | normal, fast, adjustable | normal |
| `CheatsEnabled` | false, true | false |
| `CivilianAlliance` | enemy, neutral, removed | enemy |
| `RevealCivilians` | Yes, No | Yes |
| `PrebuiltUnits` | Off, On | Off |
| `NoRushOption` | Off, 1..5,10,15,…,60 | Off |
| `RandomMap` | Off, Official, All | Off |
| `Score` | yes, no | yes |
| `UnitCap` | 125,250,…,1000,1250,1500 | 1000 |
| `AllowObservers` | true/false | true |
| `Timeouts` | 0, 3, -1 (MP only) | 3 |
| `DisconnectionDelay02` | 10, 30, 90 (MP only) | 90 |
| `Unranked` | No, Yes | No |

### AI options (~709–814)
| Key | Values | Default |
|---|---|---|
| `CheatMult` | 0.5–5.9 | 1.0 |
| `BuildMult` | 0.5–5.9 | 1.0 |
| `TMLRandom` | 0–20% | 0 |
| `LandExpansionsAllowed` | 0–8, 99999 | 6 |
| `NavalExpansionsAllowed` | 0–8, 99999 | 5 |
| `OmniCheat` | on, off | on |

Plus **map-specific options** (`mapname_options.lua`, validated by `maputil`) and
**custom AI options** from mods (`/lua/AI/LobbyOptions/`). Storage: `gameInfo.GameOptions[key]`
+ `Prefs LobbyOpt_<key>`; host writes via `SetGameOption(s)` (~5938) → `GameOptions` broadcast
+ GpgNet (`RestrictedCategories`→bool, `ScenarioFile`, `Slots`). Reset via `OptionUtils.SetDefaults` (~2592).
Display: `RefreshOptionDisplayData` (~4543), scrollable `GUI.OptionContainer`, optional "show changed only".

---

## H. Auto-teams & spawn

- **AutoTeams** (`AssignAutoTeams` ~1802): none / tvsb / lvsr / pvsi / manual (host clicks map markers, requires random spawn).
- **Spawn variants** (`TeamSpawn`): fixed, random, balanced (+flex, +reveal, +mirrored), penguin_autobalance.
- **Spawn-mex** (adaptive maps): per-slot `SpawnMex` toggle; embedded into GameOptions at launch.
- **Launch-time** (`TryLaunch` ~2077): `AssignAutoTeams`, `AssignRandomFactions`, `FixFactionIndexes`,
  `AssignRandomStartSpots`, `AssignAINames`, flatten gameInfo, build Ratings/ClanTags tables.

---

## I. Map selection (`mapselect.lua`)

- Map browser dialog `CreateDialog` (~453): list + preview + filters + options panel + Mods/Unit-Manager buttons.
- **Filters** (~117): supported players (2–16), size (5–81 km), type (official/custom), AI markers, hide-obsolete; persisted in prefs. Name search.
- **Preview**: `ResourceMapPreview` (terrain, water/cliff/buildable masks, mass/hydro markers, start spots).
- **Metadata** (`maputil` `LoadScenario` ~53): name, map/save/script/preview, size, reclaim, type, version, AdaptiveMap, Configurations (teams/armies).
- **Enumeration**: `EnumerateSkirmishScenarios` (~312) over `/maps/*` + mod map dirs; playable skirmish only.
- Hardcoded official-maps list for the "official" filter.

---

## J. Mods manager (`ModsManager.lua`)

- Dialog `CreateDialog(parent, isHost, availableMods, saveBehaviour)` (~160).
- **Types**: GAME (sim, network-replicated, disables rating), UI (local only), BLACKLISTED, LOCAL (host has, peers don't), NO_DEPENDENCY.
- **Browse**: grid (expand/collapse), sort (status/type/name/author/version), free-text search; prefs-persisted.
- **Favorites**: per-mod star; "Activate Favorites" (host: sim+UI, client: UI only).
- **Dependencies**: forward auto-activate, backward auto-deactivate, conflict prompts (`Mods.GetDependencies`).
- **Peer availability**: `availableMods[peerID]`; `EveryoneHasMod`; sim mods auto-disabled / peers kicked if missing.
- **Apply**: split sim/UI, `saveBehaviour(simMods, uiMods)` → host `UpdateMods` → `ModsChanged` broadcast; `Mods.SetSelectedMods`.

---

## K. Unit restrictions manager (`UnitsManager.lua` + `UnitsRestrictions.lua`)

- Dialog `CreateDialog(parent, initial, OnOk, OnCancel, isHost)` (~216); scales to ~90% screen.
- **150+ presets** in ~15 groups (tech levels, unit types, spam, snipes, anti-air, torpedo, direct-fire, defensive/intel, SCU/ACU, economy, missiles, engineers).
- **Expression system**: category algebra (`*` AND, `+` OR, `-` NOT, `()`), UPPERCASE categories + lowercase unit ids + enhancement names.
- Grid: presets + per-faction × category unit matrix; host editable, client read-only.
- Stored in `GameOptions.RestrictedCategories`; broadcast + GpgNet bool; saved in presets.

---

## L. Chat

| Feature | Trigger / function | Message |
|---|---|---|
| Public chat | `GUI.chatEdit` Enter → `PublicChat` (~1924) | `PublicChat` |
| Whisper | `/whisper`,`/pm`,`/w`,`/private` → `ParseWhisper` (~192) → `PrivateChat` (~1934) | `PrivateChat` |
| Unknown command | "Command Not Known" | — |
| Join/leave & connection notices | `AddPlayer`, `Peer_Really_Disconnected`, `CalcConnectionStatus` | `SystemMessage` |
| Rating in chat/list | `refreshObserverList` | — |
| Clickable names | `chatarea.lua` author click → prefill `/w name` | — |
| Input history | up/down over `commandQueue` | — |
| Scroll / auto-bottom | `AddChatText` (~4819) | — |

---

## M. Connectivity & health

| Feature | Function | Message | Notes |
|---|---|---|---|
| CPU benchmark | `UpdateBenchmark`/`StressCPU` (~6226) | `CPUBenchmark` | auto on connect + manual button; 0–450; cached in prefs; host re-broadcasts |
| CPU bar | `SetSlotCPUBar` (~6300) | — | green/yellow/red thresholds |
| Ping bar | ping thread (~4406) | — | shown if >500ms; status texture 1–4 |
| Connection tracking | `CalcConnectionStatus` (~4742) | — | ConnectionEstablished/CurrentConnection/ConnectedWithProxy |
| Pre-launch connectivity | `EveryoneHasEstablishedConnections` (~4785) | — | every important peer must reach every other |
| Peer disconnect | `PeerDisconnected` (~5833) | `Peer_Really_Disconnected` | clears slot/observer; chat notice |
| Host keep-alive/timeout | thread (~5616), `quietTimeout` 30s | — | "Keep Trying / Give Up" dialog |

---

## N. Compatibility & launch validation

- **Version check**: host `AddPlayer.Accept` (~5272) compares Version/GameType/Commit → reject + eject on mismatch.
- **Missing map**: `MissingMap` → `PlayerMissingMapAlert` (~7190) sets `BadMap`, system message; local fallback to default scenario; `ClearBadMapFlags` on map change.
- **Mods exchange**: `SetAvailableMods` → `availableMods[peer]`; `IsModAvailable` requires all peers; missing → kick with list.
- **Launch blockers** (`TryLaunch` ~2077): no players; host-as-observer when observers disallowed; observers present → confirm-kick; missing connections; map missing (warn, proceeds with fallback).

---

## O. Presets & rehost (`presets.lua`)

- Save preset (map, options, mods, restrictions, player options) to profile; load/apply (`ApplyGameSettings` ~6683); delete; rename.
- Auto-save "lastGame" preset at launch (`SaveLastGamePreset`).
- Rehost (`/rehost`): restore last-game settings; reassign returning players to prior slots (evicting AIs / displacing to observer), restore AIs, relocate host.
- Presets dialog UI: list + detail + Load/Create/Save/Delete/Help/Quit.

---

## P. Lobby preferences dialog (`ShowLobbyOptionsDialog` ~6519)

Local, non-game-affecting: background mode (factions/concept/screenshot/map/none),
chat font size, snowflake count, windowed lobby, stretch background, faction font colour,
player-colour-in-chat. Applied immediately; stored in prefs.

## Q. Other dialogs

- Briefing dialog (campaign/scenario), large map preview (water/cliff/buildable masks),
  save/load dialog (skirmish), kick/reset confirm popups.

---

## Network message catalog (~30)

`AddPlayer`, `PlayerOptions`, `MovePlayer`, `RequestColor`, `SetColor`,
`RequestConvertToObserver`, `RequestConvertToPlayer`, `ConvertPlayerToObserver`,
`ConvertObserverToPlayer`, `ObserverAdded`, `SlotAssigned`, `SlotMove`, `SwapPlayers`,
`ClearSlot`, `SlotClosed`, `SlotClosedSpawnMex`, `AutoTeams`, `GameOptions`,
`ModsChanged`, `SetAvailableMods`, `MissingMap`, `GameInfo` (full sync on join),
`Launch`, `PublicChat`, `PrivateChat`, `SystemMessage`, `CPUBenchmark`,
`SetPlayerNotReady`, `SetAllPlayerNotReady`, `Peer_Really_Disconnected`.

Engine callbacks: `Hosting`, `ConnectionToHostEstablished`, `PeerDisconnected`,
`DataReceived`, `GameLaunched`, `Ejected`, `ConnectionFailed`, `GameConfigRequested`.

---

## Data model

- **`gameInfo`** (`gamedata.lua`): `GameOptions` (table), `PlayerOptions` /
  `Observers` (`WatchedValueArray`), `ClosedSlots`, `SpawnMex`, `GameMods`, `AutoTeams`, `AdaptiveMap`.
- **`PlayerData`** (`playerdata.lua`): OwnerID, PlayerName, Human, Faction, PlayerColor,
  ArmyColor, Team, StartSpot, Ready, PL/MEAN/DEV/NG, PlayerClan, Country, AIPersonality,
  AILobbyProperties, Version/GameType/Commit, Civilian, BadMap, ObserverListIndex.
- Module globals: `gameInfo`, `lobbyComm`, `GUI`, `localPlayerID`, `hostID`,
  `availableMods`, `selectedSimMods`/`selectedUIMods`, `CPU_Benchmarks`, `rehostPlayerOptions`.

## "Refresh-everything" functions to replace with reactive subscriptions

`SetSlotInfo` (~1032), `ClearSlotInfo` (~1245), `UpdateGame` (~2302),
`refreshObserverList` (~926), `RefreshOptionDisplayData` (~4543),
`UpdateFactionSelector` (~6445), `RefreshButtonEnabledness` (~7248),
`Check_Availaible_Color` (~6706), `RefreshLobbyBackground`, `RefreshMapPositionForAllControls`.

---

## Reuse vs rebuild

**Relatively portable** (self-contained): map preview (`ResourceMapPreview`), mods
manager dialog, unit manager dialog, options definitions (`lobbyOptions.lua` data),
faction selector, CPU benchmark, chat (the new chat-MVC), presets storage.

**Deeply tangled core** (rebuild against the model): slot/player sync (`SetSlotInfo`
+ `HostUtils`), the 30-message dispatch, host-authority request/validate/broadcast,
connection tracking. These are where the MVC rebuild's value — and risk — concentrate.
