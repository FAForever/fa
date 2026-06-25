# Custom-Game Lobby — User Stories

Companion to [`FEATURES.md`](FEATURES.md). Same A–Q structure, so each story
traces back to a catalogued feature. Format: **As a `<role>`, I want `<goal>`, so
that `<reason>`** — with *when/given* conditions where they matter.

Roles: **Host**, **Player** (human in a slot), **Observer**, **Joining client**
(connecting peer), **System** (automatic / engine-driven).

> **Progress** (updated as the [`customlobby/`](customlobby/CLAUDE.md) rebuild lands slices):
> ✅ done · 🟡 partial / works with gaps · ⬜ not started. Markers reflect the reactive-MVC
> rebuild, not the legacy `lobby.lua`. Launch itself isn't wired yet, so anything that only
> resolves *at launch* is ⬜ even when its inputs are configurable.

---

## A. Lifecycle & entry

- ⬜ As a **player**, I want to browse discovered games (map, name, player count), so that I can pick one to join.
- 🟡 As a **host**, I want to create a game with a name and a starting map, so that others can find and join it. *(Given a valid nickname, 2–32 non-space chars.)* — *host/client connect + sync work; the create-game entry UI (name, nickname validation) isn't rebuilt.*
- 🟡 As a **player**, I want to join by direct IP:port, so that I can connect when discovery doesn't list the game. *(Engine join path works in testing; no direct-IP entry UI yet.)*
- ✅ As a **joining client**, I want to receive the full lobby state on connect, so that I immediately see the current map, slots, options and mods. *(`BroadcastPlayers` + `BroadcastLaunchInfo` + `BroadcastSessionState` on join.)*
- 🟡 As a **player**, I want to leave the lobby with a confirmation prompt, so that I don't exit by accident; *and when launched via `/gpgnet`*, leaving quits to desktop instead of the menu. — *Leave/Esc → menu works; no confirm prompt, no gpgnet quit-to-desktop.*
- ⬜ As a **host**, I want to rehost my last game, so that the previous map/options/mods and player slots are restored automatically.
- ⬜ As a **player**, I want my lobby UI to tear down cleanly when the game launches, so that no stale threads or windows linger.

## B. Slots & players

- 🟡 As a **host**, I want to open or close an empty slot, so that I control how many players can join. *(Closed-slot state is modelled + synced; the open/close control isn't wired.)*
- ⬜ As a **host on an adaptive map**, I want to close a slot as "spawn-mex", so that the position yields mass instead of an ACU.
- ✅ As a **player**, I want to occupy an empty open slot, so that I can join the game; *when* I'm not already marked ready.
- ✅ As a **host**, I want to move a player to another slot or swap two players, so that I can arrange start positions and teams. *(Drag a row onto another → `RequestSwapSlots`.)*
- 🟡 As a **host**, I want to kick a player with an optional message, so that I can remove someone; *and* the message is remembered for next time. *(Eject works; no message / recall.)*
- 🟡 As a **player**, I want each slot row to show name, rating, country, faction, colour, team, ping, CPU and ready state, so that I can assess the lobby at a glance. *(Name, CPU/headroom, ready shown; rating/country/faction/colour/team/ping not yet.)*
- ✅ As a **player**, I want a slot's controls to reflect who owns it (me / another player / host / AI) via colour and an appropriate right-click menu, so that I only see actions I'm allowed to take.

## C. Per-player settings

- ⬜ As a **player**, I want to choose my faction (including Random), so that I play what I want; *given* the map allows it and I'm not ready.
- ⬜ As a **player**, I want to pick a colour, so that I'm visually distinct; *when* the colour is free — taken colours are hidden and the host reverts conflicts.
- ⬜ As a **player**, I want to set my team, so that I'm allied correctly; *when* AutoTeams is off and I'm not ready.
- ✅ As a **player**, I want to toggle Ready, so that I signal I'm set; *and when* ready, my own controls lock until I unready.
- ⬜ As a **host**, I want to force a player not-ready, so that I can change settings that affect them.
- ⬜ As a **player**, I want to pick my start position on the map preview, so that I control where I spawn; *when* spawn is fixed (host gets swap/assign tools otherwise).
- ⬜ As a **player**, I want my last faction/colour remembered, so that I don't re-pick every lobby.

## D. AI management (host)

- ⬜ As a **host**, I want to add an AI of a chosen personality to a slot, so that I can fill the game; *and* the AI is auto-ready.
- ⬜ As a **host**, I want the AI personality list to include built-in and mod-provided AIs, so that all installed AIs are selectable.
- ⬜ As a **host**, I want to remove an AI from a slot, so that I can free it.
- ⬜ As a **host**, I want AIs to get a computed rating from cheat/build/map multipliers, so that game quality estimates stay meaningful.
- ⬜ As a **host**, I want to set an AI's faction/colour/team and move/swap it like a player, so that I can arrange AI-inclusive setups.
- ⬜ As a **host**, I want a quick "fill slots" action, so that I can populate remaining slots with AIs at once.

## E. Observers

- 🟡 As a **joining client**, I want to enter as an observer when no slot is free or when I request it, so that I can still watch. *(Observers are modelled/synced; auto-enter-as-observer on a full lobby isn't wired.)*
- 🟡 As a **player**, I want to become an observer (or request it from the host), so that I can step out of the game without leaving. *(Host moves a player to observers via the context menu, and an **"Observe" button** moves the local player out of their slot — host-side; a non-host's request-to-host path isn't wired yet.)*
- ✅ As an **observer**, I want to become a player / request a specific slot, so that I can join in; *given* a slot is available (host may evict an AI). *(Right-click → "Play this slot".)*
- 🟡 As a **player**, I want to see the observer list with rating, ping and CPU, so that I know who's spectating. *(Observer strip shows count + names; no rating/ping/CPU.)*
- ⬜ As a **host**, I want to kick an observer, so that I can manage spectators; *and* observers are auto-kicked at launch if observers are disallowed.
- ⬜ As an **observer**, I want to use public and private chat (shown greyed), so that I can still communicate.

## F. Host authority & validation

- ✅ As a **host**, I want to be the single source of truth, so that all clients converge on one authoritative state. *(Host-authoritative: request → validate → broadcast snapshot.)*
- 🟡 As a **player**, I want my own-slot changes applied optimistically and then confirmed by the host, so that the UI feels responsive but stays consistent. *(Round-trips through the host; not yet optimistic.)*
- ⬜ As a **host**, I want option-changing buttons disabled while any human is not ready, so that settings can't shift after people commit.
- 🟡 As a **host**, I want the launch button enabled only when everyone is ready (or single-player / I'm observing), so that I can't start prematurely. *(Launch works — `RequestLaunch` builds the config, broadcasts a `LaunchGame` message and calls the engine; it's validated on click (host + a map + ≥1 seat + every other human ready, the host exempt). Not yet reactively enabled/disabled, and the block reason is only logged.)*
- ⬜ As a **system**, I want to ignore a move request if the player became ready in the meantime, so that races don't corrupt slot state.

## G. Game options (host)

- ✅ As a **host**, I want to set the victory condition (assassination / decapitation / supremacy / annihilation / sandbox), so that the win rule fits the game. *(Options dialog.)*
- ✅ As a **host**, I want to configure share conditions (full / until-death / partial / transfer-to-killer / defectors / civilian-deserter) and share-unit-cap, so that resource/unit transfer on death matches our preference.
- ✅ As a **host**, I want to set unit cap, fog of war, game speed, no-rush timer, prebuilt units, civilians, score and cheats, so that the match rules are tuned.
- ✅ As a **host**, I want to mark the game unranked, so that it doesn't affect ratings.
- ✅ As a **host (multiplayer)**, I want to set timeouts and disconnection delay, so that disconnect handling fits the context (tournament/quick/regular).
- ✅ As a **host**, I want to set AI multipliers (cheat/build), omni, TML randomization and expansion limits, so that AIx difficulty is tuned. *(AI column of the options dialog.)*
- 🟡 As a **host**, I want a "reset to defaults" action, so that I can clear all options at once (which also unreadies everyone). *(Reset button clears to defaults; the auto-unready side-effect isn't wired.)*
- ✅ As a **host**, I want map-specific and mod-provided options surfaced alongside the standard ones, so that nothing is hidden. *(Scenario + Mods columns.)*
- ✅ As a **player**, I want to see the active (and optionally only the changed) options, so that I understand the ruleset. *(The config panel's **Options tab** shows the current values read-only to everyone, grouped Lobby / Scenario / Mods, with a hide-defaults toggle and origin markers; the host edits them via the Options dialog.)*

## H. Auto-teams & spawn

- 🟡 As a **host**, I want AutoTeams modes (top/bottom, left/right, odd/even, manual), so that teams are assigned by position without manual fiddling. *(Selectable as a lobby option; the actual auto-teaming/launch resolution isn't wired.)*
- ⬜ As a **host**, I want manual AutoTeams by clicking map markers, so that I can hand-place teams on random spawn.
- 🟡 As a **host**, I want spawn variants (fixed, random, balanced/flex/reveal, penguin-autobalance), so that start placement matches the desired fairness/secrecy. *(Selectable as a lobby option; placement is resolved at launch, which isn't wired.)*
- ⬜ As a **host on an adaptive map**, I want per-slot spawn-mex, so that closed positions still contribute economy.
- 🟡 As a **system**, I want random factions/start spots/AI names and the ratings/clan tables resolved at launch, so that the final config is complete and fair. *(At launch `BuildGameConfiguration` resolves random factions to a concrete one, assigns army numbers in slot order, and stamps the ratings/clan-tag tables into the game options; start-spot/AutoTeams resolution and AI names aren't done yet.)*

## I. Map selection (host)

- ✅ As a **host**, I want to browse maps with a preview, so that I can choose a map informedly.
- 🟡 As a **host**, I want to filter maps by player count, size, type (official/custom), AI markers and hide-obsolete, and search by name, so that I find the right map quickly; *and* my filters persist. *(Size, player count, name search + persistence done; type/AI-markers/hide-obsolete filters not.)*
- 🟡 As a **host**, I want a resource-aware preview (mass/hydro, water/cliff/buildable masks, start spots), so that I understand the map layout. *(Preview shows start spots, mass/hydro, wrecks; the lobby's Map tab also shows reclaim totals + description / author / url / version; terrain masks not.)*
- ✅ As a **host**, I want to pick a random map, so that I can play something fresh.
- ✅ As a **player**, I want clear warnings when a map's files are missing, so that I'm not stuck on an unplayable map. *(File-health check disables Select.)*

## J. Mods manager

- 🟡 As a **host**, I want to enable/disable sim mods, so that gameplay-affecting mods apply to everyone; *and* doing so disables ranking. *(Enable/disable + sync done via `RequestSetGameMods`; the ranking-disable side-effect isn't wired.)*
- ✅ As a **player**, I want to enable UI mods locally, so that my client UI changes without affecting others.
- 🟡 As a **player**, I want to browse, sort, search, expand/collapse and favorite mods, so that I can manage a large mod list; *and* my preferences persist. *(Browse, search, type filters, persistence done; sort + expand/collapse not; favorites replaced by presets — see next.)*
- 🟡 As a **player**, I want "activate favorites" in one click, so that I quickly enable my usual set (host: sim+UI, client: UI only). *(Replaced by named **presets** — load a saved selection; the host/client sim-vs-UI split is honoured.)*
- ✅ As a **player**, I want mod dependencies and conflicts handled automatically, so that I don't end up with a broken set. *(`ResolveEnable`/`ResolveDisable`.)*
- ⬜ As a **host**, I want to see which peers lack a sim mod, so that missing-mod peers are flagged/auto-disabled or kicked rather than causing desyncs.

## K. Unit restrictions (host)

- ⬜ As a **host**, I want to apply unit-restriction presets (tech levels, types, spam/snipe/anti-air/etc.), so that I can shape allowed units fast.
- ⬜ As a **host**, I want to toggle individual units per faction, so that I can fine-tune beyond presets.
- ⬜ As a **player**, I want a read-only view of the restrictions, so that I know what's banned.
- ⬜ As a **host**, I want restrictions saved with presets and reflected in rating eligibility, so that custom rulesets are reusable and correctly rated.

## L. Chat

- ⬜ As a **player/observer**, I want to send public chat, so that everyone in the lobby sees it.
- ⬜ As a **player/observer**, I want to whisper via `/whisper` `/pm` `/w` `/private`, so that I can message one person privately.
- ⬜ As a **player**, I want clear feedback on an unknown command or an invalid whisper target, so that I know it didn't send.
- ⬜ As a **player**, I want join/leave/connection notices in chat, so that I'm aware of lobby changes.
- ⬜ As a **player**, I want to click a name in chat to prefill a whisper, so that replying is quick.
- ⬜ As a **player**, I want command history (up/down) and auto-scroll with a "new message" indicator, so that chatting is comfortable.
- ⬜ As a **player**, I want ratings shown alongside names, so that I gauge the lobby's skill.

## M. Connectivity & health

- 🟡 As a **player**, I want my CPU benchmarked (auto on connect, and on demand), so that others can see my performance; *and* the result is cached and re-broadcast by the host. *(Stored benchmark is shared + re-broadcast; no live/on-demand stress test.)*
- 🟡 As a **player**, I want CPU and ping bars per slot (ping shown when poor), so that I can spot weak links. *(CPU column with cap-headroom done; ping not.)*
- 🟡 As a **system**, I want to track per-peer connection status, so that the UI reflects who is fully connected. *(`EstablishedPeers`/`OnPeerDisconnected` tracked; not fully surfaced.)*
- ⬜ As a **host**, I want launch blocked until every important peer is connected to every other, so that the game doesn't start with broken links.
- 🟡 As a **player**, I want a peer's disconnect to clear its slot and notify chat, so that the lobby stays accurate. *(Disconnect frees the slot for everyone; no chat notice — chat isn't in the lobby yet.)*
- ⬜ As a **client**, I want a "host timed out — keep trying / give up" prompt, so that I can decide what to do on a stalled connection.

## N. Compatibility & launch validation

- ⬜ As a **host**, I want to reject peers on a different game version/type/commit, so that desyncs are prevented (with a clear ejection reason).
- 🟡 As a **player**, I want missing-map situations flagged (and a fallback used), so that the lobby communicates the problem instead of silently breaking. *(The map dialog flags missing files; in-lobby fallback not.)*
- ⬜ As a **host**, I want peers' available mods exchanged and validated, so that everyone has the required sim mods before launch.
- ⬜ As a **host**, I want launch blocked with a clear reason (no players, host-as-observer when disallowed, observers present, missing connections), so that I know exactly what to fix.

## O. Presets & rehost

- 🟡 As a **host**, I want to save the current setup (map, options, mods, restrictions, players) as a named preset, so that I can reuse it. *(Save/load of map, options, mods and restrictions works via the action-bar **Presets** dialog; presets are **setup-only by design** — players/observers are not stored.)*
- ✅ As a **host**, I want to load/delete/rename presets, so that I can manage reusable configurations. *(The Presets dialog loads/deletes/renames; loading applies the setup host-authoritatively and reconciles options to the current map+mods.)*
- 🟡 As a **system**, I want the last game auto-saved as a preset at launch, so that rehost can restore it. *(Launch auto-saves the reserved `lastGame` setup; the rehost **restore** (in-lobby button + `/rehost` arg) is deferred. Note the auto-save carries no roster — reseating needs a separate player capture.)*
- ⬜ As a **host**, I want rehost to reseat returning players to their prior slots (displacing AIs/others as needed), so that a replay setup reconstitutes quickly. *(Blocked on AI-add + per-player slot intents; also needs its own roster capture — setup presets deliberately don't store players.)*

## P. Lobby preferences (per user)

- ⬜ As a **player**, I want to choose the lobby background mode, chat font size, snowflake count, windowed mode, background stretch and chat colours, so that the lobby looks how I like; *and* changes apply immediately and persist.

## Q. Other dialogs

- ⬜ As a **host**, I want a briefing dialog for scenarios that have one, so that players see the operation context.
- ⬜ As a **player**, I want a large map preview (with terrain/resource masks), so that I can study the map closely.
- ⬜ As a **host (skirmish)**, I want a save/load dialog, so that I can resume saved games.
- ⬜ As a **host**, I want confirmation prompts for destructive actions (kick, reset options), so that I don't trigger them by mistake.

## R. New requests

- ⬜ As a **host**, I want the ability to lock players in-place when autobalance is applied so that players that want to play together stay in the same team.
- ⬜ As a **player**, I want the observer bug that can freeze/crash the lobby fixed — or at least a warning when it's hit — so that observing doesn't break the lobby. *(Reliable repro needs a debuggable lobby setup.)*
- ⬜ As a **player**, I want to randomise among a chosen subset of factions (multi-choice), so that I get variety without pure random.
- ⬜ As a **player**, I want my FAF avatar shown in the lobby, so that players are recognisable.
- ⬜ As a **host**, I want a "players vs AI" AutoTeams option, so that all humans are teamed against the AIs automatically.
- ⬜ As a **host**, I want closing a slot to auto-move its player to a free slot (in opti), so that rearranging doesn't drop anyone.
- ⬜ As a **host**, I want an opti team preview, so that I can see the balanced teams before committing.
- ⬜ As a **host**, I want flexible mirror balancing, so that mirror match-ups can be balanced with some give.
- ⬜ As a **host**, I want a system for balancing premades, so that pre-made groups are distributed fairly across teams. *(Related to locking players in place during autobalance, above.)*
- ⬜ As a **player**, I want easier rehosting — a dedicated in-game/lobby rehost button that works with the client, including rehosting someone else's lobby (when they're AFK, or just to duplicate it), so that rehosting is quick. *(Extends the "rehost my last game" stories in A/O.)*
- ⬜ As a **non-host player**, I want to save presets as a client, so that I keep my setups even when I'm not hosting.
- ⬜ As a **host**, I want to load presets without switching maps, so that applying a preset doesn't force a map change.
- ⬜ As a **player**, I want lobby options categorised by mod, so that mod-provided options are grouped clearly.
- ⬜ As a **player**, I want to collapse lobby-option categories, so that I can focus on the ones I care about.
- ⬜ As a **non-host player**, I want to read each option's description, so that I understand what every setting does.
- ⬜ As a **host**, I want the unit-manager bug fixed where presets stop appearing after you disable units manually, so that presets keep working.
- ⬜ As a **host**, I want better unit stats in the unit manager, so that I can judge units when restricting them.
- ⬜ As a **host**, I want faster map/option loading when many maps are installed, so that the lobby isn't slow to open.
- ⬜ As a **player**, I want faster mod-manager loading, so that opening it isn't slow.
- ⬜ As a **modder**, I want a moddable lobby UI, so that the lobby can be extended/customised by mods.
- ⬜ As a **player**, I want mod presets kept separate from lobby-option presets, so that the two don't get entangled.
- ⬜ As a **host**, I want map-specific lobby options to persist between sessions when I rehost the same map, so that I don't reconfigure them each time.
- ⬜ As a **host**, I want last game's mods NOT auto-enabled when the game didn't launch (but kept when it did, for rehosting), so that a failed launch doesn't silently carry mods forward.
- ⬜ As a **player**, I want "disable all sim / UI / all mods" buttons, so that I can clear mods in one click.
- ⬜ As a **player**, I want the mod manager's dependency-related UI updates fixed, so that enabling/disabling reflects dependencies correctly.
- ⬜ As a **developer**, I want mod-dependency management reworked in the lobby frontend so it no longer keys off singular version UUIDs, so that the dependency system is fixed at the source.