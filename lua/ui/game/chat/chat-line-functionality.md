# Chat Line Functionality — Inventory

Catalogue of every behaviour related to chat lines in the original
`lua/ui/game/chat.lua`, grouped by concern. Intended as the planning input for
decomposing the chat-line code into the MVC structure used elsewhere in
`lua/ui/game/chat/`.

---

## 1. Line construction (`CreateChatLine`, chat.lua:178–240)

Each line is a `Group` with five child controls:

- **`teamColor`** — a solid-colour square on the left, coloured with the sender's team colour.
- **`factionIcon`** — a bitmap overlaid on the team-colour square, showing the sender's faction (or an observer icon for observers).
- **`name`** — bold text prefix showing the sender and who the message is for (e.g. `"PlayerX to Allies:"`). Clickable for private reply.
- **`text`** — the message body. Clickable *only* when the entry carries a `camera` payload.
- **`lineStickybg`** — a semi-transparent `aa000000` bar that fills the line, depth-under the content, hidden by default. Shown in feed mode when `feed_background` is on, so lines stay readable over the game world.
- **`camIcon`** — optional camera-pin bitmap inserted between `name` and `text` when the entry has a camera link; created lazily in `CalcVisible`, destroyed when the line's entry no longer has one.

---

## 2. Pool sizing — dynamic line count (`CreateChatLines`, chat.lua:177–290)

- Computes how many lines fit in `chatContainer` as `floor(container.Height / line.Height)`.
- Adds new lines (`Below` the previous) when the window grows; destroys excess lines when it shrinks.
- First-time setup places line 1 at `AtLeftTopIn(container, 0, 0)`, then stacks more while `prev.Bottom + line.Height < container.Bottom`.
- Each line's `Height` is set lazily to `name.Height + 2` (so it scales with `font_size`).

---

## 3. Scroll container (`SetupChatScroll`, chat.lua:296–364)

Implements the standard MAUI scrollable interface on `chatContainer`:

- **Virtual size** = sum of `wrappedtext` lengths across only *filtered* entries (`IsValidEntry`: per-army filter + link filter). Cached in `prevsize` / `prevtabsize`.
- `GetScrollValues`, `ScrollLines`, `ScrollPages`, `ScrollSetTop`, `IsScrollable` — the usual scrollbar API.
- `ScrollToBottom` — jumps to the most-recent line.
- Mouse wheel on the chat window maps to `ScrollSetTop` (in `CreateChat` / `OnMouseWheel`).
- Page Up / Page Down hotkeys (`ChatPageUp(mod)`, `ChatPageDown(mod)`), with Shift reducing the page size to 1.

---

## 4. Visibility mapping (`CalcVisible`, chat.lua:366–507)

Projects the history onto the line pool:

- Walks `chatHistory` skipping filtered-out entries until the target scroll offset is reached.
- First wrapped line of an entry shows the name, team-color square, faction icon, etc.; continuation lines show only indented text with an empty name slot.
- Text colour per line picked from `ChatOptions[tokey]` (`all_color` / `allies_color` / `priv_color` / `link_color` / `notify_color`); camera-link lines use `link_color`.
- Name is disabled (greyed) when the line's `armyID` matches the focus army (your own messages).
- Camera icon inserted / removed based on whether the current entry has a `camera` field; also shifts the text's `Left` over by the icon's width.
- `line:SetAlpha(ChatOptions.win_alpha)` applied every refresh so opacity changes take effect immediately.

---

## 5. Text wrapping (`WrapText` / `RewrapLog`, chat.lua:1223–1247)

- `WrapText(data)` delegates to `maui/text.lua.WrapText` and returns an array of wrapped lines.
- Width callback uses `chatLines[1]`'s actual pixel width: the **first** wrapped line reserves space for the name prefix (measured via `text:GetStringAdvance(name)`), subsequent lines indent past just the team-color/faction column.
- Called once when a message arrives (in `ReceiveChatFromSim`).
- `RewrapLog()` re-wraps every entry in `chatHistory` on window resize or option change.

---

## 6. Feed mode (window hidden, chat.lua:455–494)

- When `GUI.bg` is hidden, the most recent lines render over the game world via the existing pool (the window chrome is just hidden, the line controls stay).
- Each visible line gets an `OnFrame` that increments `curHistory.time`; once `time > fade_time`, the line hides itself.
- Continuation lines of a wrapped entry don't tick their own timer — they wait on the first wrapped line's timer (special-cased).
- `feed_background` option controls the `lineStickybg`'s visibility per line.
- `ToggleChat` un-hides every line and hides every `lineStickybg` when opening the window; does the inverse on close.

---

## 7. Filtering (chat.lua:304–323)

- Per-army toggle: `ChatOptions[entry.armyID]` (one checkbox per non-civilian army in the config dialog).
- Link filter: camera-link entries require `ChatOptions.links` to display.
- Filtered entries are excluded from both the virtual scroll size and from `CalcVisible`'s walk.
- When a new entry arrives whose army is filtered out, `ScrollToBottom` is skipped.

---

## 8. Interactivity

- **Name `ButtonPress`** (chat.lua:199–211) → if the line has a `chatID`, it shows the window (if hidden), sets `ChatTo` to that army, focuses the edit box, and ticks the "private" checkbox.
- **Text `ButtonPress`** (chat.lua:223–229) → if the entry carries `cameraData`, `GetCamera('WorldCamera'):RestoreSettings(cameraData)` — the "camera link" feature that lets a sender point teammates at a position.

---

## 9. Display-lifecycle state stored on history entries (the design-doc smell)

These three fields currently live on `chatHistory` entries, mixing data with view state:

- `new` — true until the entry has been shown once (controls whether the fade timer starts from zero or from the entry's existing time).
- `time` — seconds-since-displayed fade counter.
- `wrappedtext` — per-width wrapped text array; rebuilt by `RewrapLog` on resize.

---

## 10. Styling tied to `ChatOptions`

Every display option from the config dialog hits a chat-line property somewhere:

- `font_size` → line `Height` and text point size.
- `win_alpha` → `line:SetAlpha` on refresh.
- `fade_time` → feed-mode timeout comparator.
- Colour indices (`*_color`) → text colour per line.
- `feed_background` → per-line `lineStickybg` visibility.
- `links` + per-army filters → inclusion/exclusion from `IsValidEntry`.
