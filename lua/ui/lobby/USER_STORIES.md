# Custom-Game Lobby — User Stories

Companion to [`FEATURES.md`](FEATURES.md). Same A–Q structure, so each story
traces back to a catalogued feature. Format: **As a `<role>`, I want `<goal>`, so
that `<reason>`** — with *when/given* conditions where they matter.

Roles: **Host**, **Player** (human in a slot), **Observer**, **Joining client**
(connecting peer), **System** (automatic / engine-driven).

---

## A. Lifecycle & entry

- As a **player**, I want to browse discovered games (map, name, player count), so that I can pick one to join.
- As a **host**, I want to create a game with a name and a starting map, so that others can find and join it. *(Given a valid nickname, 2–32 non-space chars.)*
- As a **player**, I want to join by direct IP:port, so that I can connect when discovery doesn't list the game.
- As a **joining client**, I want to receive the full lobby state on connect, so that I immediately see the current map, slots, options and mods.
- As a **player**, I want to leave the lobby with a confirmation prompt, so that I don't exit by accident; *and when launched via `/gpgnet`*, leaving quits to desktop instead of the menu.
- As a **host**, I want to rehost my last game, so that the previous map/options/mods and player slots are restored automatically.
- As a **player**, I want my lobby UI to tear down cleanly when the game launches, so that no stale threads or windows linger.

## B. Slots & players

- As a **host**, I want to open or close an empty slot, so that I control how many players can join.
- As a **host on an adaptive map**, I want to close a slot as "spawn-mex", so that the position yields mass instead of an ACU.
- As a **player**, I want to occupy an empty open slot, so that I can join the game; *when* I'm not already marked ready.
- As a **host**, I want to move a player to another slot or swap two players, so that I can arrange start positions and teams.
- As a **host**, I want to kick a player with an optional message, so that I can remove someone; *and* the message is remembered for next time.
- As a **player**, I want each slot row to show name, rating, country, faction, colour, team, ping, CPU and ready state, so that I can assess the lobby at a glance.
- As a **player**, I want a slot's controls to reflect who owns it (me / another player / host / AI) via colour and an appropriate right-click menu, so that I only see actions I'm allowed to take.

## C. Per-player settings

- As a **player**, I want to choose my faction (including Random), so that I play what I want; *given* the map allows it and I'm not ready.
- As a **player**, I want to pick a colour, so that I'm visually distinct; *when* the colour is free — taken colours are hidden and the host reverts conflicts.
- As a **player**, I want to set my team, so that I'm allied correctly; *when* AutoTeams is off and I'm not ready.
- As a **player**, I want to toggle Ready, so that I signal I'm set; *and when* ready, my own controls lock until I unready.
- As a **host**, I want to force a player not-ready, so that I can change settings that affect them.
- As a **player**, I want to pick my start position on the map preview, so that I control where I spawn; *when* spawn is fixed (host gets swap/assign tools otherwise).
- As a **player**, I want my last faction/colour remembered, so that I don't re-pick every lobby.

## D. AI management (host)

- As a **host**, I want to add an AI of a chosen personality to a slot, so that I can fill the game; *and* the AI is auto-ready.
- As a **host**, I want the AI personality list to include built-in and mod-provided AIs, so that all installed AIs are selectable.
- As a **host**, I want to remove an AI from a slot, so that I can free it.
- As a **host**, I want AIs to get a computed rating from cheat/build/map multipliers, so that game quality estimates stay meaningful.
- As a **host**, I want to set an AI's faction/colour/team and move/swap it like a player, so that I can arrange AI-inclusive setups.
- As a **host**, I want a quick "fill slots" action, so that I can populate remaining slots with AIs at once.

## E. Observers

- As a **joining client**, I want to enter as an observer when no slot is free or when I request it, so that I can still watch.
- As a **player**, I want to become an observer (or request it from the host), so that I can step out of the game without leaving.
- As an **observer**, I want to become a player / request a specific slot, so that I can join in; *given* a slot is available (host may evict an AI).
- As a **player**, I want to see the observer list with rating, ping and CPU, so that I know who's spectating.
- As a **host**, I want to kick an observer, so that I can manage spectators; *and* observers are auto-kicked at launch if observers are disallowed.
- As an **observer**, I want to use public and private chat (shown greyed), so that I can still communicate.

## F. Host authority & validation

- As a **host**, I want to be the single source of truth, so that all clients converge on one authoritative state.
- As a **player**, I want my own-slot changes applied optimistically and then confirmed by the host, so that the UI feels responsive but stays consistent.
- As a **host**, I want option-changing buttons disabled while any human is not ready, so that settings can't shift after people commit.
- As a **host**, I want the launch button enabled only when everyone is ready (or single-player / I'm observing), so that I can't start prematurely.
- As a **system**, I want to ignore a move request if the player became ready in the meantime, so that races don't corrupt slot state.

## G. Game options (host)

- As a **host**, I want to set the victory condition (assassination / decapitation / supremacy / annihilation / sandbox), so that the win rule fits the game.
- As a **host**, I want to configure share conditions (full / until-death / partial / transfer-to-killer / defectors / civilian-deserter) and share-unit-cap, so that resource/unit transfer on death matches our preference.
- As a **host**, I want to set unit cap, fog of war, game speed, no-rush timer, prebuilt units, civilians, score and cheats, so that the match rules are tuned.
- As a **host**, I want to mark the game unranked, so that it doesn't affect ratings.
- As a **host (multiplayer)**, I want to set timeouts and disconnection delay, so that disconnect handling fits the context (tournament/quick/regular).
- As a **host**, I want to set AI multipliers (cheat/build), omni, TML randomization and expansion limits, so that AIx difficulty is tuned.
- As a **host**, I want a "reset to defaults" action, so that I can clear all options at once (which also unreadies everyone).
- As a **host**, I want map-specific and mod-provided options surfaced alongside the standard ones, so that nothing is hidden.
- As a **player**, I want to see the active (and optionally only the changed) options, so that I understand the ruleset.

## H. Auto-teams & spawn

- As a **host**, I want AutoTeams modes (top/bottom, left/right, odd/even, manual), so that teams are assigned by position without manual fiddling.
- As a **host**, I want manual AutoTeams by clicking map markers, so that I can hand-place teams on random spawn.
- As a **host**, I want spawn variants (fixed, random, balanced/flex/reveal, penguin-autobalance), so that start placement matches the desired fairness/secrecy.
- As a **host on an adaptive map**, I want per-slot spawn-mex, so that closed positions still contribute economy.
- As a **system**, I want random factions/start spots/AI names and the ratings/clan tables resolved at launch, so that the final config is complete and fair.

## I. Map selection (host)

- As a **host**, I want to browse maps with a preview, so that I can choose a map informedly.
- As a **host**, I want to filter maps by player count, size, type (official/custom), AI markers and hide-obsolete, and search by name, so that I find the right map quickly; *and* my filters persist.
- As a **host**, I want a resource-aware preview (mass/hydro, water/cliff/buildable masks, start spots), so that I understand the map layout.
- As a **host**, I want to pick a random map, so that I can play something fresh.
- As a **player**, I want clear warnings when a map's files are missing, so that I'm not stuck on an unplayable map.

## J. Mods manager

- As a **host**, I want to enable/disable sim mods, so that gameplay-affecting mods apply to everyone; *and* doing so disables ranking.
- As a **player**, I want to enable UI mods locally, so that my client UI changes without affecting others.
- As a **player**, I want to browse, sort, search, expand/collapse and favorite mods, so that I can manage a large mod list; *and* my preferences persist.
- As a **player**, I want "activate favorites" in one click, so that I quickly enable my usual set (host: sim+UI, client: UI only).
- As a **player**, I want mod dependencies and conflicts handled automatically, so that I don't end up with a broken set.
- As a **host**, I want to see which peers lack a sim mod, so that missing-mod peers are flagged/auto-disabled or kicked rather than causing desyncs.

## K. Unit restrictions (host)

- As a **host**, I want to apply unit-restriction presets (tech levels, types, spam/snipe/anti-air/etc.), so that I can shape allowed units fast.
- As a **host**, I want to toggle individual units per faction, so that I can fine-tune beyond presets.
- As a **player**, I want a read-only view of the restrictions, so that I know what's banned.
- As a **host**, I want restrictions saved with presets and reflected in rating eligibility, so that custom rulesets are reusable and correctly rated.

## L. Chat

- As a **player/observer**, I want to send public chat, so that everyone in the lobby sees it.
- As a **player/observer**, I want to whisper via `/whisper` `/pm` `/w` `/private`, so that I can message one person privately.
- As a **player**, I want clear feedback on an unknown command or an invalid whisper target, so that I know it didn't send.
- As a **player**, I want join/leave/connection notices in chat, so that I'm aware of lobby changes.
- As a **player**, I want to click a name in chat to prefill a whisper, so that replying is quick.
- As a **player**, I want command history (up/down) and auto-scroll with a "new message" indicator, so that chatting is comfortable.
- As a **player**, I want ratings shown alongside names, so that I gauge the lobby's skill.

## M. Connectivity & health

- As a **player**, I want my CPU benchmarked (auto on connect, and on demand), so that others can see my performance; *and* the result is cached and re-broadcast by the host.
- As a **player**, I want CPU and ping bars per slot (ping shown when poor), so that I can spot weak links.
- As a **system**, I want to track per-peer connection status, so that the UI reflects who is fully connected.
- As a **host**, I want launch blocked until every important peer is connected to every other, so that the game doesn't start with broken links.
- As a **player**, I want a peer's disconnect to clear its slot and notify chat, so that the lobby stays accurate.
- As a **client**, I want a "host timed out — keep trying / give up" prompt, so that I can decide what to do on a stalled connection.

## N. Compatibility & launch validation

- As a **host**, I want to reject peers on a different game version/type/commit, so that desyncs are prevented (with a clear ejection reason).
- As a **player**, I want missing-map situations flagged (and a fallback used), so that the lobby communicates the problem instead of silently breaking.
- As a **host**, I want peers' available mods exchanged and validated, so that everyone has the required sim mods before launch.
- As a **host**, I want launch blocked with a clear reason (no players, host-as-observer when disallowed, observers present, missing connections), so that I know exactly what to fix.

## O. Presets & rehost

- As a **host**, I want to save the current setup (map, options, mods, restrictions, players) as a named preset, so that I can reuse it.
- As a **host**, I want to load/delete/rename presets, so that I can manage reusable configurations.
- As a **system**, I want the last game auto-saved as a preset at launch, so that rehost can restore it.
- As a **host**, I want rehost to reseat returning players to their prior slots (displacing AIs/others as needed), so that a replay setup reconstitutes quickly.

## P. Lobby preferences (per user)

- As a **player**, I want to choose the lobby background mode, chat font size, snowflake count, windowed mode, background stretch and chat colours, so that the lobby looks how I like; *and* changes apply immediately and persist.

## Q. Other dialogs

- As a **host**, I want a briefing dialog for scenarios that have one, so that players see the operation context.
- As a **player**, I want a large map preview (with terrain/resource masks), so that I can study the map closely.
- As a **host (skirmish)**, I want a save/load dialog, so that I can resume saved games.
- As a **host**, I want confirmation prompts for destructive actions (kick, reset options), so that I don't trigger them by mistake.
