---
name: customlobby-model-choice
description: Decide which of the three CustomLobby models new state belongs in — Launch (shared + launched), Session (shared, lobby-room only), or Local (per-peer, never synced) — and keep hot-reload working. Use when adding a field/state to the custom lobby, or unsure where lobby state should live.
---

# Which CustomLobby model does this state go in?

Three reactive singletons, chosen by two questions: **is it shared (host-dictated → broadcast to everyone)?** and **does it get launched (becomes part of the game)?**

| Put it in… | Shared? | Launched? | Examples |
|---|---|---|---|
| **[CustomLobbyLaunchModel.lua](/lua/ui/lobby/customlobby/CustomLobbyLaunchModel.lua)** | ✅ | ✅ | players (per-slot), observers, scenario, game options, mods, auto-teams, spawn-mex. |
| **[CustomLobbySessionModel.lua](/lua/ui/lobby/customlobby/CustomLobbySessionModel.lua)** | ✅ | ❌ | slot count, closed slots (later: lobby title, password, kick log). |
| **[CustomLobbyLocalModel.lua](/lua/ui/lobby/customlobby/CustomLobbyLocalModel.lua)** | ❌ | — | identity (`LocalPeerId` / `HostID` / `IsHost`), CPU benchmarks (later: ping). |

**Decide with two litmus questions:**
1. *Does the launched game consume this?* → **Launch**. (A closed slot is just empty at launch and slot count is map-derived presentation — neither reaches the scenario, so they're **Session**, not Launch.)
2. *Is it this client's own state?* → **Local**. Identity is per-peer (the host's `IsHost` is true, a client's is false); broadcasting it would corrupt the receiver — it never goes on the wire.

Everything else host-dictated that isn't launched is **Session**.

**Not all state is a model.** *Reference data* — identical on every peer and derived from disk
or computed from synced inputs — belongs in **neither**. It's a cached module, not a LazyVar
singleton on the wire. Examples: the **map catalog** ([CustomLobbyMapCatalog.lua](/lua/ui/lobby/customlobby/mapselect/CustomLobbyMapCatalog.lua),
enumerated scenarios), and the upcoming **option schema** (derived from `ScenarioFile` + `GameMods`).
Only the host's *choice* (the `ScenarioFile` / `GameMods` / `GameOptions` values in Launch) syncs;
each peer recomputes the catalog/schema locally. Filter/search state in a picker is per-peer UI
preference (component-local + Prefs), not a model either.

## Sync mapping (host → clients)

| Model | Message(s) | Broadcast by |
|---|---|---|
| Launch | `SetPlayers` (players + observers) and `SentLaunchInfo` (scenario / options / mods / teams / spawn) | `BroadcastPlayers` / `BroadcastLaunchInfo` |
| Session | `SetSessionState` | `BroadcastSessionState` |
| Local | — (never synced; set on the connection handshake) | — |

The host pushes **whole snapshots** on join and on change. Adding a synced field means adding it to the relevant broadcast *and* its `Process*` handler in the controller.

## Adding a field — also touch OnReload

Each model hand-copies its LazyVars in `__moduleinfo.OnReload` so a hot-reload doesn't reset live state. When you add a field:

1. add it to that model's `SetupSingleton` (a `Create(...)` with its default), and
2. **add a matching copy line in that model's `OnReload`** — miss this and the field silently resets on every save-reload (exactly when you're iterating).

## Gotchas — do / don't

| | Rule |
|---|------|
| ✅ | Route every write through the owning model's helpers (`SetPlayer`, `SetGameOption`, `AddObserver`, `SetClosed`, `SetCpuBenchmark`, …) — they keep the copy-then-`Set` discipline. |
| ✅ | Add the matching `OnReload` copy line whenever you add a field (see above). |
| ✅ | Write the shared (Launch / Session) models **only from the controller**, after the host validates; clients send a request message. |
| 🚫 | Put ping / CPU / connection churn in **Launch** or **Session** — its dirtying would ride along with a synced snapshot. It's **Local**. |
| 🚫 | Put launch-affecting state in **Session** (it won't reach the game) or **Local** (it won't be shared). If the game needs it and all peers must agree → **Launch**. |
| 🚫 | Broadcast anything from **Local** — identity/connectivity is per-peer; sending it corrupts the receiver. |
| 🚫 | Mutate a LazyVar's held table in place — always `table.copy` → mutate → `:Set` (a new table), or dependents never go dirty. |
| 🚫 | Write any model from a view/component — views read via `Derive` only; the controller is the sole writer. |
| 🚫 | Use the `%` operator (FAF is Lua 5.0 — use `math.mod`). |
