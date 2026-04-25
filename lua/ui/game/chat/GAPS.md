# Chat MVC refactor — remaining gaps

Inventory of legacy [`/lua/ui/game/chat.legacy.lua`](../chat.legacy.lua) behaviour that the new MVC tree does **not** yet replicate. Gaps are grouped by concern and cite line numbers in the old file so a future author can jump in.

Accepted & intentional differences live in [CHANGES.md](CHANGES.md); this file only tracks work that hasn't happened yet.

---

## Feed mode finishing touches

The bones of feed mode are in place — [`ChatFeedInterface`](ChatFeedInterface.lua) renders, fades, and clears in line with legacy expectations. What's still missing is the *configurable* layer:

- **Translucent feed background** — `feed_background` option has no effect. Legacy showed a `lineStickybg` strip per row when set ([chat.legacy.lua:233-238, 465](../chat.legacy.lua)). Feed rows are currently bare; would need a sticky background back on [`ChatLineInterface`](ChatLineInterface.lua), wired to the option, drawn behind the row when the row is in feed mode. Note that we explicitly dropped the legacy `StickyBg` field from `ChatLineInterface` because the chat-window `Show()` cascade was double-painting it; bringing it back needs the SetTexture/SetSolidColor cycling trick used for `CamIcon` / `FactionIcon`.
- **`feed_persist`** — option has no effect. Today we always `ClearAll()` on window-open and always gate `OnHistoryChanged` on `not WindowVisible()`. To support persist=true, both branches need to flip: don't clear on open, and queue rows even while window is visible (paused timer until reveal). Two-mode logic.
- **Pin button / pin toggle** — no pin button on the chat window. Pin should suspend both the window auto-close (`OnFrame` skips advancing toward `fade_time` while pinned) and the feed fade (per-row timers don't tick). Legacy: [chat.legacy.lua:1177-1187](../chat.legacy.lua).

## Message filtering

[`ChatLinesInterface.IsValidEntry`](ChatLinesInterface.lua) gates on the per-army `muted` map only. Two parts of the legacy filter are still missing:

- **`links` option** — `ChatConfigModel` defines the key, but `IsValidEntry` doesn't check it. Camera-link entries are always shown regardless of the user's preference. Legacy: [chat.legacy.lua:304-310](../chat.legacy.lua).
- **Self-echo / observer rules on receive** — [`ChatController.OnReceive`](ChatController.lua) doesn't filter incoming messages by sender / observer-mode. Legacy had a small set of receive-time rules that prevented self-echo loops and gated certain messages by observer state. Audit needed against [chat.legacy.lua:304-310](../chat.legacy.lua).

## Color palette not wired

[`ChatConfigModel`](config/ChatConfigModel.lua) defines the full palette (`all_color`, `allies_color`, `priv_color`, `link_color`, `notify_color`) and the dialog persists choices, but [`ChatLineInterface.SetHeader`](ChatLineInterface.lua) only uses `entry.Color` (the team-colour square) and a hard-coded `'ffc2f6ff'` for the body text. Legacy looked up `ChatOptions[entry.tokey]` against an 8-colour swatch array per line ([chat.legacy.lua:63, 446-450](../chat.legacy.lua)).

The fix: expose the colour-swatch array on the model (or at module level on the line file), have `SetHeader` index into it via the entry's `tokey`, and make sure `ApplyOptions` triggers a re-render when any palette key changes.

## Notify-command bridge

Slash commands in the legacy dispatcher fell through to [`RunChatCommand`](../../notify/commands.lua) ([chat.legacy.lua:729](../chat.legacy.lua)) so `/enablenotify`, `/disablenotify`, `/enablenotifyoverlay`, `/disablenotifyoverlay` worked from chat. The new [`ChatCommandRegistry`](commands/ChatCommandRegistry.lua) dispatcher does not, so those commands are dead.

Easy fix: an "unknown command" fallback in the dispatcher that hands off to `RunChatCommand` before reporting an error to the user.

## Command history recall (↑ / ↓)

Legacy kept a `commandHistory` ring and recalled it on `VK_UP` / `VK_DOWN` ([chat.legacy.lua:681-701](../chat.legacy.lua)). Not ported. The new [`ChatEditInterface.OnNonTextKeyPressed`](ChatEditInterface.lua) maps Up / Down to `CommandHint:SelectNext` / `SelectPrev` while the hint is open; outside of an open hint, Up / Down do nothing.

Both can co-exist: keep the hint behaviour while it's open, and fall through to history recall when `self.ChatCommandHintInterface == nil`.

## Drag / resize / window-state

- **Wheel-forward when hidden** — legacy `GUI.bg.HandleEvent` forwarded scroll to the worldview when chat was hidden ([chat.legacy.lua:1202-1209](../chat.legacy.lua)). [`ChatInterface.OnMouseWheel`](ChatInterface.lua) doesn't override `HandleEvent`. Whether this matters in practice depends on engine routing — the wheel may already reach the worldview when the chat window is `Hide()`-flagged. Verify before fixing.
- **Button tooltips** — no `Tooltip.AddCheckboxTooltip` / `AddControlTooltip` calls anywhere in the chat tree. Legacy had `chat_pin`, `chat_config`, `chat_close`, `chat_camera`, `chat_reset` ([chat.legacy.lua:1200, 1211-1214](../chat.legacy.lua)).

## Per-line visuals

- **Own-army name greying** — legacy `line.name:Disable()` greyed the sender name on your own messages so you could see at a glance which lines were yours ([chat.legacy.lua:409-413](../chat.legacy.lua)). Not ported to [`ChatLineInterface.SetHeader`](ChatLineInterface.lua).

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
- **Window opacity** — [`ChatInterface.OptionsObserver`](ChatInterface.lua) calls `SetAlpha(_, true)` on every `Committed` change; cascades to chrome / lines / edit / scrollbar.
- **Per-line fade timer** — implemented in [`ChatFeedInterface`](ChatFeedInterface.lua), not in the main view (fade only matters when the window is hidden, which is exactly what the feed handles).
- **Feed mode itself** — [`ChatFeedInterface`](ChatFeedInterface.lua) is a sibling of the chat window pinned to the line area via LazyVar bind, observes `History` + `WindowVisible`, has a per-row pool, fades each row in its last 2 seconds, clears on window-open, hides itself when there are no rows.
- **Per-army mute (`muted`)** — per-game (not persisted to prefs), checkbox column in [`ChatConfigInterface`](config/ChatConfigInterface.lua), `/mute` and `/unmute` slash commands, `IsValidEntry` filter, `SetMuted` / `SetMutedLive` controllers.
- **`OnMoveSet` focus grab** — [`ChatInterface.OnMoveSet`](ChatInterface.lua) re-acquires edit focus after a drag.
- **`font_size` reactive** — [`ChatLinesInterface.ApplyOptions`](ChatLinesInterface.lua) reapplies on every `Committed` change.
- **Bottom-anchored line layout** — [`ChatLinesInterface.RebuildPool` / `CalcVisible`](ChatLinesInterface.lua) stack newest-at-bottom so chat and feed share the same vertical rhythm and open ↔ close transitions stay continuous.
