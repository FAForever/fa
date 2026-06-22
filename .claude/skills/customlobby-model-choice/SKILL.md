---
name: customlobby-model-choice
description: Decide which CustomLobby model new state belongs in — the host-authoritative model (host-dictated, synced, part of the launched scenario) vs the regular connectivity model (local, high-frequency, not synced) — and keep hot-reload working. Use when adding a field/state to the custom lobby, or unsure where lobby state should live.
---

# Which CustomLobby model does this state go in?

Two reactive singletons. Pick by **who owns the truth and whether it's part of the game**:

| Put it in… | When the state is… | Examples |
|---|---|---|
| **[CustomLobbyAuthoritativeModel.lua](/lua/ui/lobby/customlobby/CustomLobbyAuthoritativeModel.lua)** | **host-dictated** and **part of what launches** — everyone must agree, the host broadcasts it. | players (per-slot), observers, game options, mods, scenario, slot flags (closed / spawn-mex / auto-teams), identity (`LocalPeerId` / `HostID` / `IsHost`). |
| **[CustomLobbyModel.lua](/lua/ui/lobby/customlobby/CustomLobbyModel.lua)** | **local / per-peer / high-frequency** and **not** part of the scenario — churns independently of the synced game state. | CPU benchmarks (now); ping / connection status (later). |

**Litmus test:** *"Does the launched game need this, and must all peers see the same value?"* → authoritative. *"Is it just this client's view of connectivity/health?"* → regular. Keeping fast-churning local state out of the authoritative model is the whole point — it stops connection noise from dirtying the synced snapshot.

## Adding a field — also touch OnReload

Both models hand-copy their LazyVars in `__moduleinfo.OnReload` so a hot-reload doesn't reset live state. When you add a field:

1. add it to `SetupSingleton` (a `Create(...)` with its default), and
2. **add a matching copy line in that model's `OnReload`** — miss this and the field silently resets on every save-reload (exactly when you're iterating).

## Gotchas — do / don't

| | Rule |
|---|------|
| ✅ | Route every write through the model's write helpers (`SetPlayer`, `SetGameOption`, `AddObserver`, `SetCpuBenchmark`, …) — they keep the copy-then-`Set` discipline. |
| ✅ | Add the matching `OnReload` copy line whenever you add a field (see above). |
| ✅ | Mirror state to the authoritative model **only from the controller**, after the host validates; clients send a request message. |
| 🚫 | Put ping / CPU / connection churn in the **authoritative** model — its dirtying would ride along with the synced game snapshot. |
| 🚫 | Put scenario / launch-affecting state in the **regular** model — it won't be part of the game the host dictates or broadcasts. |
| 🚫 | Mutate a LazyVar's held table in place — always `table.copy` → mutate → `:Set` (a new table), or dependents never go dirty. |
| 🚫 | Write either model from a view/component — views read via `Derive` only; the controller is the sole writer. |
| 🚫 | Use the `%` operator (FAF is Lua 5.0 — use `math.mod`). |
