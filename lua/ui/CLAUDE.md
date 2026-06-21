# UI — General Patterns

This doc covers conventions that apply to **any** UI work in `/lua/ui` — control authoring, layout, reactivity, and lifecycle. Folder-specific docs (e.g. [`game/chat/CLAUDE.md`](game/chat/CLAUDE.md)) extend or specialize these rules; if you're working on chat, options dialogs, lobby UI, etc., read the local CLAUDE.md too.

The patterns described here came out of refactoring the in-game chat in 2026. Some older modules (legacy lobby, notify, etc.) predate them and won't match — when extending those modules, follow the rules here for **new** code rather than mirroring the existing style.

---

## 1. Class Construction — `__init` vs `__post_init`

Every UI class built with `ClassUI(...)` has two construction hooks. The factory in [class.lua:582-589](../system/class.lua#L582-L589) calls them in order, with the same arguments, on a freshly metatabled instance. **Both run before the constructor returns**, so callers see a fully initialized control either way — the split exists for ordering inside the class.

| Hook | Purpose |
|------|---------|
| `__init` | **Build state and children.** Allocate `self.X` fields, instantiate child controls, register hooks, derive observers, initialize plain-Lua bookkeeping (counters, tables, the `TrashBag`). |
| `__post_init` | **Lay out the tree.** Call the fluent layouter on the children built in `__init`. Do work that depends on the parent rect being bound. |

### Why the split exists

MAUI controls don't have concrete pixel positions — `Left`, `Right`, `Top`, `Bottom`, `Width`, `Height` are LazyVars whose compute functions reference each other (see `Control.ResetLayout` in [control.lua:35-42](../maui/control.lua#L35-L42)). Reading any one of them runs the chain. If a child has no anchor against a parent yet, that chain is **circular**, so calling `child.Width()` returns 0 (or worse, errors).

In `__init`, the parent hasn't been anchored against *its* parent yet either. So:

- Anything that just **stores** a layout binding (`self.Foo:Set(function() return ... end)`) is fine in either hook.
- Anything that **evaluates** layout to a concrete number (`Pool.Height()`, `Width()`, sizing a fixed-count pool) must wait until `__post_init` — or even later, see "Three-phase init" below.

### Canonical shape

```lua
---@class UIMyPanel : Group
---@field Trash    TrashBag
---@field Header   Text
---@field Body     Group
---@field Observer LazyVar
local MyPanel = ClassUI(Group) {

    ---@param self UIMyPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "MyPanel")

        self.Trash  = TrashBag()
        self.Header = UIUtil.CreateText(self, "Title", 14, UIUtil.bodyFont)
        self.Body   = Group(self, "MyPanelBody")

        -- Reactive subscription: safe in __init because Derive only registers
        -- the dependency edge — it doesn't read any layout values.
        self.Observer = self.Trash:Add(LazyVarDerive(SomeModel.Foo, function(fooLazy)
            self:OnFooChanged(fooLazy())
        end))
    end,

    ---@param self UIMyPanel
    __post_init = function(self, parent)
        Layouter(self.Header):AtLeftTopIn(self, 4):End()
        Layouter(self.Body)
            :AnchorToBottom(self.Header, 4)
            :AtLeftRightIn(self)
            :AtBottomIn(self)
            :End()
    end,

    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}
```

### Three-phase init: when even `__post_init` is too early

If a control's layout depends on the **parent** sizing it (e.g. building a fixed-count pool from a `Height()` evaluation), `__post_init` still fires before the parent has laid the child out. The fix is a public `Initialize()` (or similarly named) method the parent calls *after* anchoring. Real example in [game/chat/ChatLinesInterface.lua:180-191](game/chat/ChatLinesInterface.lua#L180-L191): the pool's `OptionsObserver` is wired in `Initialize`, not `__post_init`, because its first fire reads `Pool.Height()`.

Reach for this only when needed — most controls are happy with the two-phase split.

### Rules

- **Always call the parent class's `__init` first** in your own `__init`. It creates the C-side control; without it nothing else works.
- **Never read concrete layout values (`child.Width()`, `Height()`, …) in `__init`.** They return zero or trip the circular-evaluation guard. Defer to `__post_init` or a later method.
- **Never apply layout in `__init`.** The exception is when something downstream forces an early read — e.g. `SetupEditStd` reads bounds before `__post_init` runs. In that case, set placeholder values in `__init` and replace them in `__post_init`. See [game/chat/ChatEditInterface.lua:108-113](game/chat/ChatEditInterface.lua#L108-L113).
- **Always declare every `self.X` field on the class.** Every field assigned in `__init` / `__post_init` gets a matching `---@field` immediately above `ClassUI(...)`. See [annotation.md](../../annotation.md) for the project-wide annotation conventions.

---

## 2. Reactivity — LazyVars and `Derive`

LazyVars (defined in [`/lua/lazyvar.lua`](../lazyvar.lua)) are the reactivity primitive across the engine. The MAUI layout system is built on them; you can build feature reactivity on top of them too.

### Mental model

A LazyVar is a value that **knows who depends on it**. Reading it (calling it like a function) registers the caller as a dependent. Writing it (`:Set(x)` or `:Set(function() ... end)`) walks the dependency graph and fires `OnDirty` on everything that ever read it.

This means: if your code "needs to update when X changes," wire it up as a LazyVar dependency once. The engine handles the propagation. You never poll.

### Naming convention

A LazyVar is **not** the value it holds — it's a handle to a value that may change. Reflect that in the name: suffix LazyVar locals and parameters with `Lazy`, and read into a plainly-named local at the moment of use.

```lua
local recipientLazy = Create('all')   -- the LazyVar (a handle)
local recipient = recipientLazy()     -- the value (right now)
```

This applies to handler parameters too. Don't use `lv` — name the parameter after what it represents (`recipientLazy`, `optionsLazy`, `historyLazy`), then read it into a local at the top of the handler.

### Three calls you actually use

```lua
local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive

-- Static value
local recipientLazy = Create('all')              -- holds 'all'
recipientLazy:Set('allies')                      -- fires OnDirty on dependents
print(recipientLazy())                           -- 'allies' — call to read

-- Computed value (re-evaluates whenever its inputs change)
local labelLazy = Create()
labelLazy:Set(function() return "To: " .. recipientLazy() end)

-- Subscribe to a LazyVar you don't own (typical inside __init)
self.RecipientObserver = self.Trash:Add(Derive(model.Recipient, function(recipientLazy)
    local recipient = recipientLazy()
    self.Label:SetText("To: " .. recipient)
end))
-- The observer is itself a LazyVar; routing it through Trash:Add ensures it
-- gets destroyed (and its OnDirty unhooked) when the owning control is.
```

Reading the value into a local at the top of the handler is the convention even for single uses — it keeps the code grep-friendly and avoids walking the dependency graph twice if you read the value more than once.

### The `Derive` rule

**Never assign `OnDirty` directly on a LazyVar you don't own.** Direct assignment overwrites whatever handler was there before, silently breaking unrelated code. Always `Derive`. The Derive function bundles the safe three-step dance (create new LazyVar, hang OnDirty on it, Set a reader) into one call. See the rationale and the `Trash:Add` integration in [game/chat/CLAUDE.md § Reactive State](game/chat/CLAUDE.md).

### Don't use `OnFrame` for reactivity, unless strictly necessary

`OnFrame` exists for genuine **per-frame work** — animation, smooth interpolation, time-based polling against the wall clock. It is the wrong tool for "X changed → update Y."

| Need | Use |
|------|-----|
| "Re-render the recipient label when `model.Recipient` changes" | `Derive(model.Recipient, ...)` |
| "Animate this bitmap's alpha over 0.3 s" | `OnFrame` |
| "Recompute total when any item changes" | LazyVar with `Set(function() return sum(...) end)` |
| "Auto-hide the chat 15 s after the last message" | `OnFrame` polling `GetSystemTimeSeconds() - model.LastActivity()` |
| "When the user clicks a row, scroll to bottom" | Direct call from the click handler — neither |

Why this matters: an `OnFrame` poll runs every frame even when nothing changed; a LazyVar dependency only re-runs when an input is `Set`. With dozens of UI controls, the difference is real frame budget.

When you do need `OnFrame`, remember it is gated by `SetNeedsFrameUpdate(true)` — controls don't tick by default. Toggle it with the visibility/enabled state of the work it drives so you don't pay for an idle timer (chat does this in [game/chat/ChatInterface.lua:140-145, 369-377](game/chat/ChatInterface.lua#L369-L377)).

### Reactivity rules at a glance

1. **Don't cache a LazyVar's value in a local outside of OnDirty.** Always call it at the moment you need it so the dependency edge stays correct. *Inside* an OnDirty handler, storing the value once for readability is fine — the dependency was already registered when the handler was wired up.
2. **`OnDirty` is a pull notification.** It tells you the value *may* have changed; call into the LazyVar inside the handler to actually read.
3. **Use `Derive`, never raw `OnDirty =`,** on any LazyVar you didn't create.
4. **Don't mutate a LazyVar's held table in place.** Build a new table and `Set` it — otherwise dependents never go dirty (the value identity didn't change).
5. **Destroy your derived observers** via TrashBag in `OnDestroy`. Dangling `OnDirty` callbacks keep the dependent's frame alive in `used_by` and run forever.

### Models and controllers

Models and controllers are module singletons. Import them at the top of any file that needs them — never thread them through constructors or callback tables. Direct imports keep dependencies visible at the top of the file and avoid the autolobby's "prop drilling" pattern. See [game/chat/CLAUDE.md § Imports vs callbacks](game/chat/CLAUDE.md) for the chat refactor's specific framing.

---

## 3. Lifecycle and Cleanup — `TrashBag`

Anything you allocate that has a `Destroy()` (or anything that needs explicit teardown — coroutines, timers, derived LazyVars) goes in a `TrashBag` ([trashbag.lua](../system/trashbag.lua)). One bag per control:

```lua
__init = function(self, parent)
    Group.__init(self, parent, "Foo")
    self.Trash = TrashBag()

    -- Trash:Add returns what you pass it, so the assignment stays a one-liner:
    self.Observer = self.Trash:Add(LazyVarDerive(model.X, function(xLazy)
        self:OnXChanged(xLazy())
    end))
end,

OnDestroy = function(self)
    self.Trash:Destroy()
end,
```

`TrashBag` is a weak table for values, so an item already destroyed elsewhere drops out automatically — `Destroy()` should always be idempotent. See [trashbag.lua:30-50](../system/trashbag.lua#L1-L50) for the contract.

---

## 4. Layout — Fluent Layouter

Layout in `__post_init` is written through the fluent builder returned by `LayoutHelpers.ReusedLayoutFor` (aliased as `Layouter` by convention):

```lua
local Layouter = LayoutHelpers.ReusedLayoutFor

Layouter(self.Body)
    :AnchorToBottom(self.Header, 4)
    :AtLeftRightIn(self, 8)
    :AtBottomIn(self, 4)
    :End()
```

Conventions:

- **Always call `:End()`** — the builder is reusable and `End` releases it back to the pool.
- **Anchor against parents and siblings, not absolute pixels.** Width/height of children should derive from the parent's rect or a sibling's edge.
- **Use `LayoutHelpers.AnchorTo*` for sibling adjacency**, `:AtLeftIn`/`:AtRightIn`/etc. for pinning into a parent. Padding goes as the trailing argument.
- **Don't store layouter references on `self`.** They are pooled and reused by other controls after `End`.

Full operator catalog lives in [`/lua/maui/layouthelpers.lua`](../maui/layouthelpers.lua) — search for `function ` to see the available `AnchorToX` / `AtXIn` / `Fill` / `Over` / `From*In` / `Percent*` calls.

### UI scaling

The engine scales the entire UI by the user's `ui_scale` setting. The fluent `Layouter` runs every numeric padding through `LayoutHelpers.ScaleNumber` automatically, so the values in the examples above are in *unscaled* pixels — the output adapts to any scale.

When you pass numbers to anything **other** than the layouter (manual `:Set(...)`, fixed-size bitmaps, custom layout maths, font sizes through `SetFont`), wrap them in `LayoutHelpers.ScaleNumber` so they scale alongside the rest of the UI:

```lua
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local scaled = LayoutHelpers.ScaleNumber

self.SomeLine.Top:Set(scaled(20))
```

If you find yourself reaching for `ScaleNumber` a lot, that's usually a sign you should be using `Layouter` instead.

### Reusing layout files

`LayoutHelpers.*RelativeTo` reads positions from a layout `.lua` table — used by older skinned screens. New code generally prefers fluent anchors against siblings; reach for layout files only when matching an existing skinned design.

---

## 5. Skinning — `SkinnableFile` vs `UIFile`

Texture paths come from one of two helpers in [`/lua/ui/uiutil.lua`](uiutil.lua):

| Helper | Returns | Use for |
|--------|---------|---------|
| `UIUtil.SkinnableFile(path)` | a callable that resolves against the current skin **on every read** | anything that should follow the user's skin choice — chrome, icons, decorations |
| `UIUtil.UIFile(path)` | a string, frozen at module-load time | assets that aren't skin-themed (debug overlays, fixed brand graphics) |

`SkinnableFile` shines because MAUI bitmap setters accept LazyVar/callable inputs — bind a skinnable path through the layouter and the texture hot-swaps when the skin changes:

```lua
local WindowTextures = {
    tl = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_ul.dds'),
    tm = UIUtil.SkinnableFile('/game/chat_brd/chat_brd_horz_um.dds'),
    -- ...
}
```

Real example: [game/chat/ChatInterface.lua:31-42](game/chat/ChatInterface.lua#L31-L42).

**Do not** use string paths or `UIFile` for skinnable assets. They freeze at module-load time, so the texture is whatever the skin was when the file was first imported — even if the user changes skin afterwards. Switching to `SkinnableFile` is usually a one-line fix.

---

## 6. Base Components Reference

When building UI, prefer existing components over rolling your own. Two layers:

### 6.1 MAUI primitives (`/lua/maui/`)

Thin Lua wrappers over the C-side `moho.*_methods` controls. These are the leaves of the control tree.

| File | Class | Use for |
|------|-------|---------|
| [bitmap.lua](../maui/bitmap.lua) | `Bitmap` | Solid colour, single texture, or skinnable image |
| [border.lua](../maui/border.lua) | `Border` | Nine-slice border using a single texture set |
| [button.lua](../maui/button.lua) | `Button` | Up/over/down/disabled state textures |
| [checkbox.lua](../maui/checkbox.lua) | `Checkbox` | Two-state toggle with hover textures |
| [control.lua](../maui/control.lua) | `Control` | Base class — all other controls inherit |
| [cursor.lua](../maui/cursor.lua) | `Cursor` | Custom mouse cursor with hotspot |
| [dragger.lua](../maui/dragger.lua) | `Dragger` | Mouse-drag interaction handler |
| [edit.lua](../maui/edit.lua) | `Edit` | Single-line text input |
| [frame.lua](../maui/frame.lua) | `Frame` | Top-level engine frame (rare; use `GetFrame(0)`) |
| [grid.lua](../maui/grid.lua) | `Grid` | Fixed-cell grid layout |
| [group.lua](../maui/group.lua) | `Group` | Invisible container; the workhorse parent for laying out children |
| [histogram.lua](../maui/histogram.lua) | `Histogram` | Bar-chart visualization |
| [itemlist.lua](../maui/itemlist.lua) | `ItemList` | Scrollable list of strings (legacy; consider a custom Group + pool) |
| [mesh.lua](../maui/mesh.lua) | `Mesh` | Embedded 3D mesh viewport |
| [movie.lua](../maui/movie.lua) | `Movie` | Video playback control |
| [multilinetext.lua](../maui/multilinetext.lua) | `MultiLineText` | Word-wrapped text block |
| [radiobuttons.lua](../maui/radiobuttons.lua) | `RadioButtons` | Mutually exclusive button group |
| [scrollbar.lua](../maui/scrollbar.lua) | `Scrollbar` | Pair with a scrollable control via `SetScrollable` |
| [slider.lua](../maui/slider.lua) | `Slider` / `IntegerSlider` | Continuous or stepped value picker |
| [statusbar.lua](../maui/statusbar.lua) | `StatusBar` | Progress bar with min/max |
| [text.lua](../maui/text.lua) | `Text` | Single-line text run |
| [window.lua](../maui/window.lua) | `Window` | Draggable, optionally resizable framed dialog with title bar + client area |

### 6.2 UI controls (`/lua/ui/controls/`)

Higher-level compositions built on the primitives. Use these when one fits — they bake in standard skinning and behaviour.

| File | Class | Use for |
|------|-------|---------|
| [acubutton.lua](controls/acubutton.lua) | `ACUButton` | Faction-coloured ACU portrait button (lobby) |
| [border.lua](controls/border.lua) | `Border` | Themed nine-patch border |
| [checkbox.lua](controls/checkbox.lua) | `Checkbox` | Skinned checkbox with label support |
| [columnlayout.lua](controls/columnlayout.lua) | `ColumnLayout` | Auto-aligned column container |
| [combo.lua](controls/combo.lua) | `Combo` / `BitmapCombo` | Dropdown picker (text or bitmap entries) |
| [filepicker.lua](controls/filepicker.lua) | `FilePicker` | File-browser dialog |
| [mappreview.lua](controls/mappreview.lua) | `MapPreview` | Map thumbnail with markers |
| [ninepatch.lua](controls/ninepatch.lua) | `NinePatch` | Nine-slice scalable image |
| [radiobutton.lua](controls/radiobutton.lua) | `RadioButton` | Skinned single radio button |
| [resmappreview.lua](controls/resmappreview.lua) | `ResMapPreview` | Resource-mode map preview |
| [reticle.lua](controls/reticle.lua) | `Reticle` | World-space selection reticle |
| [specialgrid.lua](controls/specialgrid.lua) | `SpecialGrid` | Specialized grid for unit panels |
| [textarea.lua](controls/textarea.lua) | `TextArea` | Scrollable multi-line text display |
| [togglebutton.lua](controls/togglebutton.lua) | `ToggleButton` | Two-state pressed/unpressed button |
| [worldmesh.lua](controls/worldmesh.lua) | `WorldMesh` | World-anchored 3D mesh |
| [worldview.lua](controls/worldview.lua) | `WorldView` | Embedded world camera viewport |
| [popups/popup.lua](controls/popups/popup.lua) | `Popup` | Modal dialog wrapper |
| [popups/inputdialog.lua](controls/popups/inputdialog.lua) | `InputDialog` | Modal text-prompt dialog |

Anything not in this table — pull it from `/lua/maui/` if it's a primitive, or build it inline in your feature folder if it's a one-off composition. Don't add new files to `/lua/ui/controls/` unless the new control is genuinely reusable across features.

---

## 7. Debugging

Two patterns are worth standardizing across UI work.

### 7.1 Layout-bounds overlay

Each interface file in `/lua/ui/game/chat` declares a module-level `local Debug = false` flag. When flipped to `true`, `__post_init` adds a semi-transparent coloured `Bitmap` (`DebugBG`) covering the control's bounds — invaluable for reasoning about which control owns which rect.

```lua
local Debug = false  -- flip to true to visualise this control's bounds

-- inside __post_init:
if Debug then
    self.DebugBG = Bitmap(self)
    self.DebugBG:SetSolidColor('40ff4040')   -- distinct ARGB per file
    self.DebugBG:DisableHitTest()
    Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
end
```

Each file uses a distinct ARGB so overlapping controls can be told apart at a glance. `DisableHitTest` keeps the overlay from intercepting clicks; `:Over(self, 100)` lifts it above the control's own children.

`DebugBG` is annotated as an optional field on the class (`---@field DebugBG? Bitmap`) so the language server stays accurate. When `Debug` is false the field is never assigned — that's the entire point.

### 7.2 Hot reload

Top-level UI modules (the ones invoked from a hotkey) can hook into the engine's module manager so saving the file rebuilds the open window without restarting the game. Add this block at the bottom of the module:

```lua

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    newModule.Open()
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    if Instance then
        -- `OnDestroy` empties the trash bag, which in turn destroys every
        -- derived observer — no more `OnDirty` fires into a dead `self`.
        Instance:Destroy()
        Instance = nil
    end

    ForkThread(function()
        WaitFrames(2)
        import(__moduleinfo.name)
    end)
end

--#endregion
```

`OnDirty` fires when the file is saved on disk: tear down the existing instance (which destroys the `TrashBag` and unhooks every observer) and re-import the module after a couple of frames. `OnReload` runs on the freshly-loaded module and reopens the window, restoring the prior visible state.

This only works if your module follows the standalone-invocation convention (a module-level `Open()` / `Close()` / `Toggle()` and an `Instance` local). Without that, re-importing has nothing to call.

---

## What else this doc could cover

The seven sections above are the load-bearing patterns. Candidates for follow-up additions, in rough order of value:

1. **Standalone invocation convention** — every top-level UI module should export a module-level `Toggle()` / `Open()` / `Close()` that's safe to call from the keybind table or console. Currently documented only in [game/chat/CLAUDE.md § Standalone Invocation](game/chat/CLAUDE.md). Lifting this here would let every new feature inherit the convention without re-explaining it (and the hot-reload block in § 7.2 already assumes it).
2. **Tooltips** — `Tooltip.AddButtonTooltip` / `AddCheckboxTooltip` / `AddControlTooltip` and how their string keys resolve through the localization tables.
3. **Localization** — `<LOC key>fallback` strings and `LOC` / `LOCF` helpers; when text is user-visible, it must go through the LOC system.
4. **Hit testing** — `DisableHitTest()` on visual-only overlays is easy to forget and produces baffling click-through bugs. One paragraph would save a future debugging session.
5. **Render order** — `:Over(other, depth)` and `Depth` LazyVars; when stacking decorations or popups, the rules for keeping them above their owners.

Suggestion: do **(1) Standalone invocation** next — the hot-reload pattern in § 7.2 already references it implicitly, so codifying it removes a forward-reference. **(2)–(5)** are useful but lower priority — write them when the next bug or feature surfaces them.

Class field annotations (every `self.X` in `__init` / `__post_init` gets a matching `---@field`) live in the project-wide [`annotation.md § Class fields`](../../annotation.md) — see § 1 Rules for the inline reminder.
