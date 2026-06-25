# Preset select

The custom lobby's **setup-presets dialog** — named setup snapshots (map / options / mods /
restrictions) the host can Load / Save / Rename / Delete. The customlobby-native rebuild of the
legacy [`/lua/ui/lobby/presets.lua`](../../presets.lua) dialog (which keyed `LobbyPresets`), built
to the same shape as the [`../mapselect/`](../mapselect/CLAUDE.md) / [`../modselect/`](../modselect/CLAUDE.md)
dialogs. Opened by the host-only **Presets** button in the action bar
([`../CustomLobbyInterface.lua`](../CustomLobbyInterface.lua)).

> Read [`../CLAUDE.md`](../CLAUDE.md) first (the lobby's MVC + the layout/init gotchas).

## Files

| File | Role |
|------|------|
| [CustomLobbyPresetSelect.lua](CustomLobbyPresetSelect.lua) | the dialog (transient `Popup`). **Areas** layout (title / preset list (left) / detail (right) / actions — flip the module `Debug` flag to tint them), three-phase init. Left: an `ItemList` of saved presets (the reserved `lastGame` entry shows as "Last game"). Right: a read-only `ItemList` of the selected preset's facts (map · #mods · #restrictions · #players). Bottom: **Load / Save / Rename / Delete** + Close. Owns **no** synced state — Load/Save go through the controller's host-authoritative intents; Delete/Rename are host-local prefs (called straight on `CustomLobbyPresets`). |

The persistence lives one level up in [`../CustomLobbyPresets.lua`](../CustomLobbyPresets.lua) (pure
prefs CRUD, key `customlobby_setup_presets`, mirroring the mod presets in
[`/lua/ui/modutilities.lua`](/lua/ui/modutilities.lua)). Capturing the live launch state into a
snapshot (`BuildSetupSnapshot`) and applying one back (`ApplySetup`) touch the synced model + the
network, so they live in [`../CustomLobbyController.lua`](../CustomLobbyController.lua) (the host is
the only writer) — the dialog only calls the `RequestSaveSetupPreset` / `RequestLoadSetupPreset`
intents.

## The MVC boundary (where the setup goes)

- **Save** → `RequestSaveSetupPreset(name)` → `CustomLobbyPresets.SavePreset(name, BuildSetupSnapshot())`.
  A pure read of the model + a local prefs write; never mutates the lobby.
- **Load** → `RequestLoadSetupPreset(name)` → `ApplySetup(setup)`: host-only. Sets scenario (re-sizing
  the room), mods, restrictions and teams/spawn-mex on the launch model, **reconciles** the saved
  option values against the now-current scenario+mods schema (drop stale keys, seed defaults — same
  path as the options dialog / reset), then **one** `BroadcastLaunchInfo`. Mirrors the legacy
  `ApplyGameSettings` → single `UpdateGame`.
- **Delete / Rename** → straight to `CustomLobbyPresets` (host-local prefs; no sync).

## Setup-only — no players (§ O)

A preset stores **only** the setup: scenario / game options / sim mods / restrictions. Players,
observers and the (not-yet-applied) auto-teams / spawn-mex are **not** captured — a preset
reconfigures a lobby, it doesn't restore a roster. The launch still auto-saves the reserved
`lastGame` preset, so the *configuration* of the last game can be reapplied, but it carries no
roster. The future rehost reseat (§ O.4 — reseat returning players, in-lobby "Rehost last game"
button + `/rehost` detection at `CreateLobby`) is a separate slice that will need its **own** player
capture, not these presets (and the missing AI-add / per-player slot intents — roadmap slice #3).
