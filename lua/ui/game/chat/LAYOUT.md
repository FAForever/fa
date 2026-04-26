# Chat layout — component tree and scaling

Anchors-and-dependencies map of the chat UI tree, used to reason about UI-scale behaviour. Read alongside [CLAUDE.md](CLAUDE.md) for the chat MVC contract and [`/lua/ui/CLAUDE.md`](../../CLAUDE.md) §§ 4 (Layout, UI scaling) and 5 (Skinning) for the project-wide rules.

Notation throughout:

- **(S)** — scales with the UI factor (`pixelScaleFactor`). Includes values passed through `Layouter`, `LayoutHelpers.ScaleNumber(N)`, and font metrics like `GetFontHeight()`.
- **(F)** — fixed actual pixels. Bitmap-intrinsic dimensions on `Bitmap` / `Button` / `Checkbox` controls don't auto-scale; they render at their texture size regardless of UI factor.
- **(D)** — derived from other LazyVars (e.g. `Bottom = Top + Height`).

---

## Component hierarchy

```
ChatInterface (Window)
│   Left/Top/Right/Bottom = DefaultRect (S, drag/resize moves these)
│   client = inside skin-border insets
│
├── DragTL/TR/BL/BR        (F bitmap)   AtLeftTopIn(self, -26, -8) etc.
├── _pinCheckbox / _configBtn / _closeBtn  (F bitmap)  Window-chrome row
├── ResetPositionBtn       (F bitmap)   AnchorToLeft(_configBtn, 4)
│
└── client (Window's inner group)
    │
    ├── Lines (ChatLinesInterface, Group)
    │   │   Left   = client.Left + 8(S)
    │   │   Right  = client.Right - 8(S)
    │   │   Top    = client.Top + 2(S)
    │   │   Bottom = Edit.Top - 4(S)               ← AnchorToTop(Edit, 4)
    │   │
    │   ├── Pool (Group)
    │   │   │   Left   = ChatLinesInterface.Left
    │   │   │   Right  = ChatLinesInterface.Right - ScrollbarReserve(S)
    │   │   │   Top    = ChatLinesInterface.Top
    │   │   │   Bottom = ChatLinesInterface.Bottom
    │   │   │
    │   │   └── Lines[1..N]   ChatLineInterface pool
    │   │          Height = Name.Height(S) + 2(S)
    │   │          pool size = floor(Pool.Height / row.Height)
    │   │
    │   └── Scrollbar     CreateVertScrollbarFor(Pool)
    │                     anchored to Pool's right edge
    │
    └── Edit (ChatEditInterface)
        │   Left   = ChatInterface.Left            ← anchored to window, not client
        │   Right  = ChatInterface.Right
        │   Bottom = ChatInterface.Bottom - 6(S)
        │   Height = 19(S)                          ← fixed in parent (ChatInterface.lua)
        │   Top    = Bottom − Height                 (D)
        │   :Over(client)                            ← visually layered over client area
        │
        ├── ChatBubble       (F ≈ 24×24 bitmap)
        │      AtLeftIn(self, 6(S))
        │      AtVerticalCenterIn(self)
        │
        ├── RecipientLabel   (S font, ≈ font_h)
        │      AnchorToRight(ChatBubble, 6(S))
        │      AtVerticalCenterIn(self)
        │
        ├── EditBox          (S font)
        │      AnchorToRight(RecipientLabel, 4(S))
        │      AnchorToLeft(CamCheckbox, 4(S))
        │      AtVerticalCenterIn(self)
        │      Height = GetFontHeight()(S)
        │
        ├── CamCheckbox      (F ≈ 24×24 bitmap)
        │      AtRightIn(self, 12(S))
        │      AtVerticalCenterIn(self, −2)          ← 2-pixel upward nudge
        │
        ├── ChatListInterface       (popup, child of self, on demand)
        │      Above(ChatBubble, 15(S))
        │      AtLeftIn(ChatBubble, 15(S))
        │
        └── ChatCommandHintInterface (popup, child of self, on demand)
               Above(EditBox, 14(S))
               AtLeftIn(EditBox)
```

---

## ChatFeedInterface (sibling feed shown while the window is closed)

```
self
│   When bound to the chat window (ChatController.Init does this):
│   │   Left   = ChatInterface.Lines.Left          ← reactive LazyVar bind
│   │   Right  = ChatInterface.Lines.Right
│   │   Top    = ChatInterface.Lines.Top
│   │   Bottom = ChatInterface.Lines.Bottom
│   │
│   When standalone (debug Toggle, no window):
│   │   AtLeftBottomIn(parent, 8(S), 60(S))
│   │   Width  = 420(S)
│   │   Height = 160(S)
│
└── Rows[i]   stacked; each row carries its own `Time` for
              independent fade. Row geometry mirrors ChatLineInterface.
```

The reactive `Left/Right/Top/Bottom = ChatLinesInterface.X` bind is one-way and read-only — drag/resize the chat window with the feed visible (e.g. during a transition) and the feed tracks for free; no observer glue, no model write. Visibility is owned entirely by the feed: it's shown only when the window is hidden **and** at least one row exists.

---

## ChatLineInterface (one row in the line pool)

```
self
│   Height = Name.Height(S) + 2(S)         ← row tracks the font
│
├── TeamColor       AtLeftTopIn(self)
│   │   Width  = self.Height
│   │   Height = self.Height               ← square
│   │
│   └── FactionIcon Fill(TeamColor)
│
├── Name (S Text)   CenteredRightOf(TeamColor, 4)
│                   Over(self, 10)
│
├── CamIcon         RightOf(Name, 4(S))
│   (F ≈ 20×16)     AtVerticalCenterIn(TeamColor)
│                   Width=20(S), Height=16(S)
│                   ← shown when entry.Camera **or** entry.Location is set
│
└── Text (S)        Left  = Name.Right + 2(S)
                       (or CamIcon.Right + 4 when an icon is shown)
                    Right = self.Right
                    Top   = AtVerticalCenterIn(TeamColor)
```

`SetHeader` / `SetContinuation` / `Clear` re-anchor `Text.Left` between Name and CamIcon depending on whether the row displays the camera/location affordance. Continuation rows clear the icon entirely (`SolidColor 00000000`, hit-test off), so wrapped-text lines align flush under the first chunk.

---

## ChatCommandHintInterface (slash-command popup)

```
self
│   Width  = textWidth(S) + ScaleNumber(HorizontalPadding*2 + ScrollbarWidth)
│   Height = min(VisibleCount, MaxVisibleRows) * RowHeight(S)
│   Position = LayoutHelpers.Above(EditBox, 14)(S) by parent
│
├── Background    Left/Right/Top/Bottom = self edges (Fill)
│                 Depth = self.Depth (lowest layer)
│
├── Rows[i]       text.Left   = self.Left + horizontalPadding(S)
│                 text.Bottom = self.Bottom - (slot - 1) * RowHeight(S)
│                 BG.Top = text.Top - 1(S), BG.Bottom = text.Bottom + 1(S)
│
├── Scrollbar     CreateVertScrollbarFor(self, -ScrollbarWidth(S))
│
└── Borders       LTBG/RTBG/.../BBG hug outside of self
```

The scrollbar's "top" is inverted: ordinals grow upward (1 at the bottom), so `GetScrollValues` reports `top = N - ScrollBottom - MaxVisibleRows + 2`. Drag the thumb up → highest ordinals visible at the top of the popup.

---

## ChatListInterface (recipient picker popup)

```
self
│   Width  = sized to entry content
│   Height = sum(Entries[i].Height)
│
├── Entries[i]    Stacked Below(prev)
│   ├── Text
│   ├── BG        Left  = self.Left - 6(S)
│   │             Width = self.Width + 8(S)    ← BG bleeds outside self
│   │             Top/Bottom = text ± 1(S)
│   └── ChatFactionBadge (per-player entries; absent on the all/allies entries)
│         AtLeftIn(self, 3(S))
│         AtVerticalCenterIn(Text)
│
└── Borders LTBG/RTBG/.../BBG
```

---

## ChatFactionBadge (faction icon over team colour)

Used by `ChatListInterface` for per-player entries and intended for any other chat surface that surfaces a player.

```
self (Group)
│   Default size: 14 × 14(S)
│   Consumers override via Layouter or LayoutHelpers.SetDimensions
│
├── Color (Bitmap)  Fill(self), DepthOverParent +1
│                   SolidColor = team colour (defaults to white)
│
└── Icon  (Bitmap)  Fill(self), DepthOverParent +2
                    Texture = faction icon (or observer icon when faction is nil)
```

Both children fill the badge; depth ordering puts the faction icon over the team-colour tile, and the tile shows through the icon's transparent pixels.

---

## What scales, what doesn't

| Control            | Width × Height           | Notes                                            |
|--------------------|--------------------------|--------------------------------------------------|
| `ChatBubble`       | (F) ≈ 24 × 24            | Bitmap intrinsic, no auto-scale.                 |
| `CamCheckbox`      | (F) ≈ 24 × 24            | Bitmap intrinsic, no auto-scale.                 |
| `CamIcon`          | (S) 20 × 16              | `Layouter:Width`/`:Height` literal — auto-scaled. |
| `TeamColor`        | (S) N × N                | `Width = Height = Name.Height + 2`.              |
| `FactionIcon`      | (S) fills TeamColor      |                                                  |
| `ChatFactionBadge` | (S) default 14 × 14      | Auto-scaled; both children Fill the badge.       |
| `ResetPositionBtn` | (F) bitmap intrinsic     |                                                  |
| Drag handles       | (F) bitmap intrinsic     |                                                  |
| Text controls      | (S) font-derived         | `Name`, `RecipientLabel`, `EditBox`, message `Text`. |
| Borders            | (F) bitmap intrinsic     | `LTBG`/`RTBG`/etc. on every popup.               |
| Hint `Background`  | (S) Fill of self         | self is sized in scaled units, so this is too.   |

---

## Edit row at scale

`font_h ≈ 17 / 25 / 33` (S)   ·   `bitmap_h ≈ 24` (F)   ·   `Edit.Height = 19` (S, fixed in parent)

| UI scale | `Edit.Height(S)` (raw px) | `bitmap_h(F)` | Bitmap vs row    |
|----------|---------------------------|---------------|------------------|
| 100%     | 19                        | 24            | 2.5 px overhang  |
| 150%     | 28.5                      | 24            | 2.25 px headroom |
| 200%     | 38                        | 24            | 7 px headroom    |

`AtVerticalCenterIn(self)` keeps both bitmap buttons visually centred at every scale. The small overhang at 100% sits on top of the line-area background and is not visually disruptive in practice. `CamCheckbox` adds an extra `-2` topOffset to compensate for asymmetric padding inside its texture.

The fixed `Edit.Height = 19(S)` is intentional: the row appears to grow around the bitmap as scale increases, while the affordance art stays at its source resolution. This is the desired behaviour — bitmaps lose detail when stretched, but text gains it. Earlier iterations tried to derive `Edit.Height` from the font size; that worked but made the bitmaps drift visibly across the centre line at low scales because the row shrank below the texture height. Fixing the row height in scaled units kept the bitmap-vs-text relationship constant.

---

## Where each value lives in the code

| Concern                                                  | File                                                                          |
|----------------------------------------------------------|-------------------------------------------------------------------------------|
| `DefaultRect`, drag handles, window chrome               | [`ChatInterface.lua`](ChatInterface.lua)                                      |
| `Lines` ↔ `Edit` anchoring (window-level)                | [`ChatInterface.lua` `__post_init`](ChatInterface.lua)                        |
| Sibling feed bound to lines rect                          | [`ChatFeedInterface.lua` `__post_init`](ChatFeedInterface.lua)                |
| Pool / Scrollbar layout, scroll state, wrapping, filtering | [`ChatLinesInterface.lua`](ChatLinesInterface.lua)                          |
| `ChatBubble` / `RecipientLabel` / `EditBox` / `CamCheckbox` layout | [`ChatEditInterface.lua` `__post_init`](ChatEditInterface.lua)      |
| Row geometry (`TeamColor`, `Name`, `CamIcon`, `Text`)    | [`ChatLineInterface.lua` `__post_init`](ChatLineInterface.lua)                |
| Faction badge composition (recipient picker, per row)    | [`ChatFactionBadge.lua`](ChatFactionBadge.lua)                                |
| Hint popup width / height / row positioning              | [`ChatCommandHintInterface.lua`](ChatCommandHintInterface.lua)                |
| Recipient picker entries + BG bleed                       | [`ChatListInterface.lua` `CreateEntry`](ChatListInterface.lua)               |
