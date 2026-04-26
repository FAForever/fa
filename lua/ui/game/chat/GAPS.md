# Chat MVC refactor — remaining gaps

Inventory of legacy [`/lua/ui/game/chat.legacy.lua`](../chat.legacy.lua) behaviour that the new MVC tree does **not** yet replicate. Gaps are grouped by concern and cite line numbers in the old file so a future author can jump in.

Accepted & intentional differences live in [CHANGES.md](CHANGES.md); this file only tracks work that hasn't happened yet.

---

## Notify-command bridge

Slash commands in the legacy dispatcher fell through to [`RunChatCommand`](../../notify/commands.lua) ([chat.legacy.lua:729](../chat.legacy.lua)) so `/enablenotify`, `/disablenotify`, `/enablenotifyoverlay`, `/disablenotifyoverlay` worked from chat. The new [`ChatCommandRegistry`](commands/ChatCommandRegistry.lua) dispatcher does not, so those commands are dead.

Easy fix: an "unknown command" fallback in the dispatcher that hands off to `RunChatCommand` before reporting an error to the user.

## Command history recall (↑ / ↓)

Legacy kept a `commandHistory` ring and recalled it on `VK_UP` / `VK_DOWN` ([chat.legacy.lua:681-701](../chat.legacy.lua)). Not ported. The new [`ChatEditInterface.OnNonTextKeyPressed`](ChatEditInterface.lua) maps Up / Down to `CommandHint:SelectNext` / `SelectPrev` while the hint is open; outside of an open hint, Up / Down do nothing.

Both can co-exist: keep the hint behaviour while it's open, and fall through to history recall when `self.ChatCommandHintInterface == nil`.

## Drag / resize / window-state

- **Wheel-forward when hidden** — legacy `GUI.bg.HandleEvent` forwarded scroll to the worldview when chat was hidden ([chat.legacy.lua:1202-1209](../chat.legacy.lua)). [`ChatInterface.OnMouseWheel`](ChatInterface.lua) doesn't override `HandleEvent`. Whether this matters in practice depends on engine routing — the wheel may already reach the worldview when the chat window is `Hide()`-flagged. Verify before fixing.
- **Button tooltips** — no `Tooltip.AddCheckboxTooltip` / `AddControlTooltip` calls anywhere in the chat tree. Legacy had `chat_pin`, `chat_config`, `chat_close`, `chat_camera`, `chat_reset` ([chat.legacy.lua:1200, 1211-1214](../chat.legacy.lua)).

## Legacy public API with no replacement

If any external mod still calls these (no in-tree caller remains), they will break:

- `GUI` table (chat window handles)
- `ChatLines`
- `ReceiveChat` / `ReceiveChatFromSim` — migrate to [`ChatController.OnReceive`](ChatController.lua)
- `SetupChatLayout`
- `OnNISBegin`
- `ChatPageUp` / `ChatPageDown` — migrate to [`ChatInterface.OpenAndScrollLines`](ChatInterface.lua)
- `CloseChatConfig` — migrate to [`ChatConfigInterface.Close`](config/ChatConfigInterface.lua)
- `CloseChat`
- `AddChatOptionSetCallback` — no replacement; observers should `LazyVarDerive(ChatConfigModel.GetSingleton().Committed, ...)` instead
- `SetLayout`
- `GetArmyData` (the one defined in chat.lua; several other copies exist elsewhere)

---

## Already closed (do not re-list)

Send path, receive path, `FindClients`, controller `Init`, external importers, skin-layout orphan, `ConsoleOutput` sim-side logging, empty-text Enter, `ActivateChat` (Enter-key hook with Shift → allies), `chat.lua` renamed to `chat.legacy.lua`.

Closed in the most recent rounds of work:

- **Camera links** — outgoing (`CamCheckbox`), incoming render (`CamIcon` on the line), click-to-jump (`OnCameraClicked` with both `Camera` and `Location` paths).
- **Private reply by clicking a name** — `OnNameClicked` overridable on [`ChatLinesInterface`](ChatLinesInterface.lua); the chat window installs a handler that sets `Recipient` and re-acquires edit focus. Self-name clicks are filtered.
- **Window auto-close timer** — `LastActivity` LazyVar in the model, `NotifyActivity()` heartbeat in the controller, [`ChatInterface.OnFrame`](ChatInterface.lua) compares `GetSystemTimeSeconds() - LastActivity()` to `fade_time`. Hooked into edit keystrokes, scroll, mouse wheel, drag, resize, recipient-picker hover, and `AppendEntry`.
- **Window opacity** — [`ChatInterface.OptionsObserver`](ChatInterface.lua) calls `SetAlpha(_, true)` on every `Committed` change; cascades to chrome / lines / edit / scrollbar. Re-asserts full opacity on `ChatLinesInterface.Pool` so chat text stays crisp at low alpha while chrome and scrollbar still dim.
- **Per-line fade timer** — implemented in [`ChatFeedInterface`](ChatFeedInterface.lua), not in the main view (fade only matters when the window is hidden, which is exactly what the feed handles).
- **Feed mode itself** — [`ChatFeedInterface`](ChatFeedInterface.lua) is a sibling of the chat window pinned to the line area via LazyVar bind, observes `History` + `WindowVisible`, has a per-row pool, fades each row in its last 2 seconds, clears on window-open, hides itself when there are no rows. Bootstrapped eagerly from [`ChatController.Init`](ChatController.lua) so it can surface messages received before the user first opens the dialog.
- **Per-army mute (`muted`)** — per-game (not persisted to prefs), checkbox column in [`ChatConfigInterface`](config/ChatConfigInterface.lua), `/mute` and `/unmute` slash commands, `IsValidEntry` filter, `SetMuted` / `SetMutedLive` controllers.
- **`OnMoveSet` focus grab** — [`ChatInterface.OnMoveSet`](ChatInterface.lua) re-acquires edit focus after a drag.
- **`font_size` reactive** — [`ChatLinesInterface.ApplyOptions`](ChatLinesInterface.lua) reapplies on every `Committed` change.
- **Bottom-anchored line layout** — [`ChatLinesInterface.RebuildPool` / `CalcVisible`](ChatLinesInterface.lua) stack newest-at-bottom so chat and feed share the same vertical rhythm and open ↔ close transitions stay continuous.
- **`links` option** — [`ChatLinesInterface.IsValidEntry`](ChatLinesInterface.lua) drops entries with `Camera` or `Location` when `options.links == false`, mirroring the legacy filter. `Location` (sim-side point/area hint) is treated as a link too since it surfaces the same camera-icon affordance on the row.
- **Own-army name greying** — [`ChatLineInterface.SetHeader`](ChatLineInterface.lua) calls `Name:Disable()` when `entry.ArmyID == GetFocusArmy()` and `Name:Enable()` otherwise, mirroring the legacy "your own lines look greyed" hint. Re-applied on every `SetHeader` so pool reuse can't carry over a previous occupant's state.
- **Translucent feed background** — [`ChatFeedInterface`](ChatFeedInterface.lua) gives each feed row a per-line readability strip (Bitmap on the feed group, depth-pinned under the line, edges via `Layouter:Fill(line)`). Visibility is gated on `feed_background`; the alpha composes window opacity (`win_alpha`) × per-row fade × `FeedBackgroundAlpha = 0.5`. The chat-window line pool is unaffected — the BG lives on the feed only, so the regular history view stays bare.
- **Receive-side defensive guards** — [`ChatController.OnReceive`](ChatController.lua) coerces non-string senders, then runs everything else through a pure-shape validator (`IsValidIncomingMessage`) that checks: table-shaped, `Chat` flag set, `text` is a string, `text` length ≤ `ChatUtils.MaxMessageLength` (the same cap the edit box enforces on send), `to` is one of `RecipientAll` / `RecipientAllies` / `'notify'` / a number, and the optional `camera` / `location` payloads are tables when present. The dispatch loop then drops messages whose `Observer` flag contradicts the sender's army resolution (genuine observers have no army; an inconsistent combination implies tampering or a bug, not something to silently "repair"). Malformed input is dropped, never fixed.
- **Observer-source filter** — the existing `if not armyData and GetFocusArmy() ~= -1 and not SessionIsReplay() then return end` in [`ChatController.OnReceive`](ChatController.lua) already implements the legacy "players don't see observer chatter" rule (observers have no army → `armyData` nil → drop, unless the local viewer is also an observer or in a replay).
- **Colour palette wired** — 8-swatch [`ChatUtils.ColorPalette`](ChatUtils.lua) shared by the config dialog and the line renderer. [`ChatLineInterface`](ChatLineInterface.lua) resolves body-text colour through `ResolveBodyColor(entry)`, prioritising `entry.BodyColor` (explicit override for system / synthetic lines) over `entry.ColorKey` (palette lookup) over a hardcoded fallback. [`ChatController.AppendChatLine`](ChatController.lua) stamps `ColorKey` based on routing — camera-link / `Location` entries and observer broadcasts both pick up `link_color`; everyone else uses `ToStrings[recipient].colorkey`. Picking a different swatch in the config dialog repaints visible lines on the next `CalcVisible` pass.
- **Pin button** — [`ChatModel`](ChatModel.lua) carries a `Pinned: LazyVar<boolean>`; [`ChatController.SetPinned`](ChatController.lua) writes it (and stamps a fresh `LastActivity` on unpin so the user gets a full `fade_time` window after toggling off). [`ChatInterface.OnPinCheck`](ChatInterface.lua) wires the existing title-bar checkbox to the controller; [`ChatInterface.OnFrame`](ChatInterface.lua) short-circuits the auto-close check while pinned, so the window stays open through arbitrary inactivity.
- **Eager chat bootstrap** — [`ChatController.Init`](ChatController.lua) calls `ChatInterface.EnsureInstance()` at game start so the chat tree (and its sibling feed) exists before any messages arrive. The window itself stays hidden by default; only the feed observers are needed up front, and they're now subscribed in time to surface chat the user receives before first opening the dialog.
