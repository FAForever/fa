# Chat layout — component tree and scaling

Anchors-and-dependencies map of the chat UI tree, used to reason about UI-scale
behaviour. Read alongside [CLAUDE.md](CLAUDE.md) for the MVC contract.

Notation throughout:

- **(S)** — value scales with the UI factor (`pixelScaleFactor`). Includes
  values passed through layout helpers, `ScaleNumber(N)`, and font-derived
  metrics like `GetFontHeight()`.
- **(F)** — fixed actual pixels. Bitmap-intrinsic dimensions on `Bitmap` /
  `Button` / `Checkbox` controls don't auto-scale; they render at their texture
  size regardless of UI factor.
- **(D)** — derived from other LazyVars (e.g. `Bottom = Top + Height`).

---

## Component hierarchy

```
ChatInterface (Window)
│   Left/Top/Right/Bottom = DefaultRect (S, drag/resize moves these)
│   client = inside skin-border insets
│
├── DragTL/TR/BL/BR  (F bitmap)   AtLeftTopIn(self, -26, -8) etc.
├── ResetPositionBtn (F bitmap)   AnchorToLeft(_configBtn, 4)
│
└── client (Window's inner group)
    │
    ├── Lines (ChatLinesInterface, Group)
    │   │   Left   = client.Left + pad(S)
    │   │   Right  = client.Right - pad(S)
    │   │   Top    = client.Top + pad(S)
    │   │   Bottom = Edit.Top - 12(S)              ← anchored to Edit's top
    │   │
    │   ├── Pool (Group)
    │   │   │   Left   = ChatLinesInterface.Left
    │   │   │   Right  = ChatLinesInterface.Right - 20(S)   ← scrollbar reserve
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
        │   Left   = client.Left
        │   Right  = client.Right
        │   Bottom = client.Bottom
        │   Height = EditBox.Height(S) + ScaleNumber(6)(S)   ← the padding
        │   Top    = Bottom - Height                           (D)
        │
        ├── ChatBubble       (F ≈ 24×24 bitmap)
        │      Left = self.Left + 3(S)
        │      Top  = AtVerticalCenterIn(self)
        │           = self.Top + (self.Height(S) - 24(F)) / 2
        │
        ├── RecipientLabel   (S font, ≈ font_h)
        │      Left = ChatBubble.Right + 2(S)
        │      Top  = AtVerticalCenterIn(self)
        │           = self.Top + (self.Height(S) - font_h(S)) / 2
        │
        ├── EditBox          (S font, height = GetFontHeight)
        │      Left   = RecipientLabel.Right + 4(S)
        │      Right  = CamCheckbox.Left - 4(S)
        │      Top    = AtVerticalCenterIn(self) = self.Top + pad/2
        │      Height = GetFontHeight()(S)
        │
        ├── CamCheckbox      (F ≈ 24×24 bitmap)
        │      Right = self.Right - 4(S)
        │      Top   = AtVerticalCenterIn(self)
        │
        ├── ChatList         (popup, child of self, on demand)
        │      Above(ChatBubble, 15(S))
        │      AtLeftIn(ChatBubble, 15(S))
        │
        └── CommandHint      (popup, child of self, on demand)
               Above(EditBox, 14(S))
               AtLeftIn(EditBox)
```

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
│                   :Width(20)(S)  :Height(16)(S)
│                   ← hidden when entry.Camera is nil
│
└── Text (S)        Left  = Name.Right + 2(S)
                       (or CamIcon.Right + 4 if camera attached)
                    Right = self.Right
                    Top   = AtVerticalCenterIn(TeamColor)
```

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

The scrollbar's "top" is inverted: ordinals grow upward (1 at the bottom), so
`GetScrollValues` reports `top = N - ScrollBottom - MaxVisibleRows + 2`. Drag
the thumb up → highest ordinals visible at the top of the popup.

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
│   └── Badge?    AtLeftIn(self, 3(S))
│                 AtVerticalCenterIn(Text)
│
└── Borders LTBG/RTBG/.../BBG
```

---

## What scales, what doesn't

| Control            | Width × Height           | Notes                                            |
|--------------------|--------------------------|--------------------------------------------------|
| `ChatBubble`       | (F) ≈ 24 × 24            | Bitmap intrinsic, no auto-scale.                 |
| `CamCheckbox`      | (F) ≈ 24 × 24            | Bitmap intrinsic, no auto-scale.                 |
| `CamIcon`          | (S) 20 × 16              | `Layouter:Width`/`:Height` literal — auto-scaled. |
| `TeamColor`        | (S) N × N                | `Width = Height = Name.Height + 2`.              |
| `FactionIcon`      | (S) fills TeamColor      |                                                  |
| `ResetPositionBtn` | (F) bitmap intrinsic     |                                                  |
| Drag handles       | (F) bitmap intrinsic     |                                                  |
| Text controls      | (S) font-derived         | `Name`, `RecipientLabel`, `EditBox`, message `Text`. |
| Borders            | (F) bitmap intrinsic     | `LTBG`/`RTBG`/etc. on every popup.               |
| Hint `Background`  | (S) Fill of self         | self is sized in scaled units, so this is too.   |

---

## Chat-edit vertical layout at 100% / 150% / 200%

`font_h ≈ 17 / 25 / 33` (S)   ·   `bitmap_h ≈ 24 / 24 / 24` (F)

### `pad = ScaleNumber(6)` (current)

|                         | 100%                    | 150%                    | 200%                    |
|-------------------------|-------------------------|-------------------------|-------------------------|
| `self.Height`           | `17 + 6 = 23`           | `25 + 9 = 34`           | `33 + 12 = 45`          |
| `EditBox.Top`           | `self.Top + 3`          | `self.Top + 4.5`        | `self.Top + 6`          |
| `ChatBubble.Top` center | `(23-24)/2 = -0.5`      | `(34-24)/2 = 5`         | `(45-24)/2 = 10.5`      |
| `ChatBubble.Top` value  | `self.Top − 1`          | `self.Top + 5`          | `self.Top + 10`         |
| `CamCheckbox.Top`       | `self.Top − 1`          | `self.Top + 5`          | `self.Top + 10`         |
| `RecipientLabel.Top`    | `self.Top + 3`          | `self.Top + 4.5`        | `self.Top + 6`          |
| **net**                 | buttons 4 px above text | buttons 0.5 px above    | buttons 4 px above      |
|                         | (over-correct)          | (looks OK)              | (looks OK-ish, but 4 px |
|                         |                         |                         | empty above text)       |

### `pad = 0` (legacy, no padding)

|                         | 100%                    | 150%                    | 200%                    |
|-------------------------|-------------------------|-------------------------|-------------------------|
| `self.Height`           | `17`                    | `25`                    | `33`                    |
| `EditBox.Top`           | `self.Top + 0`          | `self.Top + 0`          | `self.Top + 0`          |
| `ChatBubble.Top`        | `self.Top − 4`          | `self.Top + 0`          | `self.Top + 5`          |
| **net**                 | buttons 4 px above text | buttons AT text top     | buttons 5 px BELOW text |
|                         | (legacy "frame" look)   | (looks low — empty      | top (looks low —        |
|                         |                         | space below button)     | growing gap below)      |

---

## The structural issue

Buttons are **fixed pixels (F)**. Text is **scaled pixels (S)**. As the UI
factor grows, `font_h` overtakes `bitmap_h`. `AtVerticalCenterIn` aligns
geometric centres — but the eye reads alignment between the bitmap centre
and the **text's optical centre** (about `font_h / 3` from the top, because
of ascender/descender asymmetry).

| pad value | Behaviour |
|-----------|-----------|
| `pad = 0`     | button geometric-centre == text geometric-centre. Works only when `font_h ≈ bitmap_h` (i.e. ~100% UI scale). Drifts visibly at higher scales. |
| `pad = 6(S)`  | everything centred in a slightly bigger box; text sits higher within `self`, which "fixes" higher scales but over-corrects at 100% (text leaves its natural baseline). |

Neither single constant works at every scale because the offset we want
between button and text scales **with `font_h`**, not with the UI factor
alone.

### Two paths forward

Both anchor the bitmap buttons to the text optical line instead of geometric
centre:

**(A) Per-button `SetFunction`**

```lua
ChatBubble.Top:SetFunction(function()
    return self.EditBox.Top()
         + self.EditBox.Height() / 3
         - self.ChatBubble.Height() / 2
end)
-- and self.Height = EditBox.Height (drop the pad)
```

**(B) Helper `OpticalCenterIn(child, edit)`** that does (A); apply to each
bitmap-sized child (`ChatBubble`, `CamCheckbox`). `RecipientLabel` and the
edit text stay on `AtVerticalCenterIn` since they're font-sized and already
align with each other at every scale.

The critical observation: **only the bitmap-sized children (`ChatBubble`,
`CamCheckbox`) misbehave across scales.** The font-sized children
(`RecipientLabel`, `EditBox`) align fine with each other at every scale
because they share the same intrinsic height. The fix only needs to touch the
bitmap children.

---

## Where each value lives in the code

| Concern                            | File                                                                      |
|------------------------------------|---------------------------------------------------------------------------|
| `DefaultRect`, drag handles, window chrome | [`ChatInterface.lua`](ChatInterface.lua)                          |
| `Lines` ↔ `Edit` anchoring (window-level) | [`ChatInterface.lua` `__post_init`](ChatInterface.lua)             |
| Pool / Scrollbar layout, scroll state, wrapping, filtering | [`ChatLinesInterface.lua`](ChatLinesInterface.lua) |
| `ChatBubble` / `RecipientLabel` / `EditBox` / `CamCheckbox` layout | [`ChatEditInterface.lua` `__post_init`](ChatEditInterface.lua) |
| Row geometry (`TeamColor`, `Name`, `CamIcon`, `Text`) | [`ChatLineInterface.lua` `__post_init`](ChatLineInterface.lua) |
| Hint popup width / height / row positioning | [`ChatCommandHintInterface.lua`](ChatCommandHintInterface.lua) |
| Recipient picker entries + BG bleed | [`ChatListInterface.lua` `CreateEntry`](ChatListInterface.lua)            |
