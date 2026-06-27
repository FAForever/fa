--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The behaviour of a single slot, shared by every presentation (the thin CustomLobbySlotRow and the
-- fat CustomLobbySlotCard). It owns *everything except the visible widgets and their layout*:
--
--   * one subscription to the derived slots model (the lookup table that already merged this seat's
--     player / placement / closed flag / CPU benchmark into a ready-to-paint entry),
--   * the click / right-click / drag-to-swap gesture handling and the controller intents,
--   * the layout-agnostic overlays (background, drop highlight, the full-row click catcher).
--
-- A presentation subclasses this (`Class(import(...).SlotBase) { ... }`) and implements two hooks:
--
--   CreateContents(self)        build the visible widgets (+ the CPU hover zone, wired to
--                               `self:HandleCpuHoverEvent`); called from this base's `__init`.
--   LayoutContents(self)        lay them out; called from this base's `__post_init`.
--
-- A presentation just has to provide the standard named controls — `ColorSwatch`, `Name`, `Faction`,
-- `Team`, `Ready`, `Cpu` (Texts) and `CpuIndicator` (Bitmap) — arranged however it likes; the base's
-- `RenderPlayer` / `RenderCpu` paint those from the entry's resolved player / CPU views. The formatting
-- (faction label, `T1`, ready/CPU colours, unit string, the green→red headroom step) lives in the
-- derived model now — see derived/CustomLobbySlotsDerivedModel.lua — so it is single-sourced and the
-- CPU bar restyles consistently across every seat when the unit cap moves. A presentation that needs a
-- different mapping (e.g. a faction *icon*) can override `RenderPlayer` / `RenderCpu`.
--
-- This keeps the drag/intent logic single-sourced; the presentations are pure arrangement.

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbyPerformancePopover = import("/lua/ui/lobby/customlobby/customlobbyperformancepopover.lua")
local CustomLobbyContextMenu = import("/lua/ui/lobby/customlobby/customlobbycontextmenu.lua")
local CustomLobbyMenus = import("/lua/ui/lobby/customlobby/customlobbymenus.lua")
local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- cursor travel (screen px) before a press becomes a drag instead of a click
local DragThreshold = 5

--- The container that owns the slot rows and coordinates drag-to-swap. The row only
--- starts the gesture; the coordinator hit-tests across all rows (it's the only thing
--- that knows their rects) and resolves a drop to a controller intent.
---@class UICustomLobbySlotCoordinator
---@field CanDrag fun(self: UICustomLobbySlotCoordinator, slot: number): boolean
---@field SlotIndexAt fun(self: UICustomLobbySlotCoordinator, x: number, y: number): number | nil
---@field OnSlotDragMove fun(self: UICustomLobbySlotCoordinator, source: number, x: number, y: number)
---@field OnSlotDrop fun(self: UICustomLobbySlotCoordinator, source: number, x: number, y: number)
---@field OnSlotDragEnd fun(self: UICustomLobbySlotCoordinator)

--- A presentation-supplied view of a seated player (nil = the empty state).
---@class UICustomLobbySlotPlayerView
---@field colorHex string
---@field name string
---@field nameColor string
---@field faction string
---@field team string
---@field ready string
---@field readyColor string

--- A presentation-supplied view of the CPU column (nil = no data, clear it).
---@class UICustomLobbySlotCpuView
---@field text string
---@field textColor string
---@field indicatorColor? Color
---@field showIndicator boolean

---@class UICustomLobbySlotBase : Group
---@field Trash TrashBag
---@field SlotIndex number
---@field Coordinator UICustomLobbySlotCoordinator
---@field Background Bitmap
---@field DropHighlight Bitmap
---@field LockStripe Bitmap                          # left-edge accent shown while this seat is locked
---@field ClickArea Bitmap
---@field SlotObserver LazyVar
---@field CurrentEntry UICustomLobbySlot | nil      # the seat's last resolved entry (interaction reads it)
---@field CurrentPlayer UICustomLobbyPlayer | false
-- the standard named controls a presentation must provide (the base's Render* paint these):
---@field ColorSwatch Bitmap
---@field Name Text
---@field Faction Text
---@field Team Text
---@field Ready Text
---@field Cpu Text
---@field CpuIndicator Bitmap
local CustomLobbySlotBase = Class(Group) {

    ---@param self UICustomLobbySlotBase
    ---@param parent Control
    ---@param slotIndex number
    ---@param coordinator UICustomLobbySlotCoordinator
    __init = function(self, parent, slotIndex, coordinator)
        Group.__init(self, parent, "CustomLobbySlot" .. tostring(slotIndex))

        self.Trash = TrashBag()
        self.SlotIndex = slotIndex
        self.Coordinator = coordinator
        self.CurrentPlayer = false

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('22ffffff')
        self.Background:DisableHitTest()

        -- drop-target highlight during a drag (sits above the background, below text)
        self.DropHighlight = Bitmap(self)
        self.DropHighlight:SetSolidColor('ffffffff')
        self.DropHighlight:SetAlpha(0.0)
        self.DropHighlight:DisableHitTest()

        -- left-edge accent shown while this seat is locked for auto-balance (same gold as the header's
        -- "Locked" notice); hidden otherwise. Layout-agnostic, so it never overlaps a presentation's
        -- content.
        self.LockStripe = Bitmap(self)
        self.LockStripe:SetSolidColor('ffd9c97a')
        self.LockStripe:SetAlpha(0.0)
        self.LockStripe:DisableHitTest()

        -- transparent overlay that catches clicks on the whole row (take / ready / context / drag)
        self.ClickArea = Bitmap(self)
        self.ClickArea:SetSolidColor('00000000')
        self.ClickArea.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if event.Modifiers.Right then
                    self:OnRowContext(event)
                else
                    self:OnRowPress(event)
                end
                return true
            end
            return false
        end

        -- the presentation builds its visible widgets (+ the CPU hover zone)
        self:CreateContents()

        -- one subscription to the derived slots table: it already merged this seat's player,
        -- placement, closed flag and CPU benchmark into a resolved entry. The table is rebuilt whole, so
        -- this fires for every seat whenever the unit cap (seated count) moves — exactly when a CPU bar
        -- needs restyling — not only when *this* seat's player changes.
        self.SlotObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySlotsDerivedModel.GetSlotsVar(), function(slotsLazy)
                self:OnSlotChanged(slotsLazy()[slotIndex])
            end))
    end,

    ---@param self UICustomLobbySlotBase
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.Background):Fill(self):End()
        Layouter(self.DropHighlight):Fill(self):End()
        Layouter(self.LockStripe):AtLeftIn(self):AtTopIn(self):AtBottomIn(self):Width(3):Over(self, 15):End()
        Layouter(self.ClickArea):Fill(self):Over(self, 10):End()

        -- the presentation lays out its widgets (its CPU hover zone sits above ClickArea, Over 20)
        self:LayoutContents()
    end,

    ---------------------------------------------------------------------------
    --#region Presentation hooks (implemented by the subclass)

    --- Builds the visible widgets + the CPU hover zone (wired to `self:HandleCpuHoverEvent`).
    ---@param self UICustomLobbySlotBase
    CreateContents = function(self)
    end,

    --- Lays out the widgets built in CreateContents.
    ---@param self UICustomLobbySlotBase
    LayoutContents = function(self)
    end,

    --- Paints a player (or the empty state when `view` is nil) onto the standard named controls.
    --- Overridable for a presentation that maps the fields differently.
    ---@param self UICustomLobbySlotBase
    ---@param view UICustomLobbySlotPlayerView | nil
    RenderPlayer = function(self, view)
        if not view then
            self.ColorSwatch:SetSolidColor('00000000')
            self.Name:SetText("- open -")
            self.Name:SetColor('ff888888')
            self.Faction:SetText("")
            self.Team:SetText("")
            self.Ready:SetText("")
            return
        end

        self.ColorSwatch:SetSolidColor(view.colorHex)
        self.Name:SetText(view.name)
        self.Name:SetColor(view.nameColor)
        self.Faction:SetText(view.faction)
        self.Team:SetText(view.team)
        self.Ready:SetText(view.ready)
        self.Ready:SetColor(view.readyColor)
    end,

    --- Paints the CPU column (or clears it when `view` is nil) onto the standard named controls.
    ---@param self UICustomLobbySlotBase
    ---@param view UICustomLobbySlotCpuView | nil
    RenderCpu = function(self, view)
        if not view then
            self.Cpu:SetText("")
            self.CpuIndicator:SetAlpha(0.0)
            return
        end

        self.Cpu:SetText(view.text)
        self.Cpu:SetColor(view.textColor)
        if view.showIndicator then
            self.CpuIndicator:SetSolidColor(view.indicatorColor)
            self.CpuIndicator:SetAlpha(1.0)
        else
            self.CpuIndicator:SetAlpha(0.0)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Rendering (paints the resolved entry; the derived model did the formatting)

    --- The seat's resolved entry changed: keep the raw refs interaction needs (the player for
    --- click/drag, the whole entry for the CPU popover) and paint the pre-resolved player + CPU views.
    ---@param self UICustomLobbySlotBase
    ---@param entry UICustomLobbySlot
    OnSlotChanged = function(self, entry)
        self.CurrentEntry = entry
        self.CurrentPlayer = entry.Player
        self:RenderPlayer(entry.PlayerView or nil)
        self:RenderCpu(entry.CpuView or nil)
        -- a locked seat (only meaningful when occupied) shows the gold left-edge accent
        self.LockStripe:SetAlpha((entry.Locked and entry.Player) and 1.0 or 0.0)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Interaction

    --- Routes the CPU hover zone's events: enter shows the popover, exit hides it, a press is a
    --- click / context like the rest of the row. The presentation attaches this to its hover bitmap.
    ---@param self UICustomLobbySlotBase
    ---@param event KeyEvent
    ---@return boolean
    HandleCpuHoverEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:OnCpuHoverEnter()
            return true
        elseif event.Type == 'MouseExit' then
            CustomLobbyPerformancePopover.Hide()
            return true
        elseif event.Type == 'ButtonPress' then
            if event.Modifiers.Right then
                self:OnRowContext(event)
            else
                self:OnRowPress(event)
            end
            return true
        end
        return false
    end,

    --- Mouse entered the CPU score: show this player's sim-performance popover. The presentation
    --- passes the control to anchor the popover to (its CPU label).
    ---@param self UICustomLobbySlotBase
    OnCpuHoverEnter = function(self)
        local entry = self.CurrentEntry
        if not (entry and entry.Player) then
            CustomLobbyPerformancePopover.Hide()
            return
        end
        -- the entry already carries the owner's raw benchmark + the unit cap the indicator was sized to
        CustomLobbyPerformancePopover.Show(self:CpuAnchor(), entry.Benchmark or nil, entry.UnitCap or nil)
    end,

    --- The control the performance popover anchors to (the CPU label). Overridable; defaults to the
    --- whole row if a presentation has no dedicated CPU control.
    ---@param self UICustomLobbySlotBase
    ---@return Control
    CpuAnchor = function(self)
        return self.Cpu or self
    end,

    --- A press on the row: if the coordinator allows dragging this slot (host, holding
    --- a player) start a drag-to-swap; otherwise it's a plain click.
    ---@param self UICustomLobbySlotBase
    ---@param event KeyEvent
    OnRowPress = function(self, event)
        if self.Coordinator and self.Coordinator:CanDrag(self.SlotIndex) then
            self:BeginDrag(event)
        else
            self:OnClicked()
        end
    end,

    --- Right-click: open this slot's context menu (entries depend on lobby state —
    --- see CustomLobbyMenus). Empty menus simply don't show.
    ---@param self UICustomLobbySlotBase
    ---@param event KeyEvent
    OnRowContext = function(self, event)
        CustomLobbyPerformancePopover.Hide()
        CustomLobbyContextMenu.Show(CustomLobbyMenus.BuildSlotMenu(self.SlotIndex), event.MouseX, event.MouseY)
    end,

    --- Starts a drag from this row. The press only becomes a drag once the cursor
    --- travels past DragThreshold — under it, the release is treated as a click, so
    --- take/ready still work. Movement + drop are routed to the coordinator (it owns
    --- the hit-test across rows); a drop resolves to RequestSwapSlots.
    ---@param self UICustomLobbySlotBase
    ---@param event KeyEvent
    BeginDrag = function(self, event)
        -- the press may have started on the CPU hover zone; the captured mouse won't
        -- fire MouseExit, so dismiss the popover up front
        CustomLobbyPerformancePopover.Hide()

        local startX, startY = event.MouseX, event.MouseY
        local moved = false
        local source = self.SlotIndex
        local coordinator = self.Coordinator

        local drag = Dragger()
        drag.OnMove = function(dragSelf, x, y)
            if not moved and (math.abs(x - startX) > DragThreshold or math.abs(y - startY) > DragThreshold) then
                moved = true
            end
            if moved then
                coordinator:OnSlotDragMove(source, x, y)
            end
        end
        drag.OnRelease = function(dragSelf, x, y)
            if moved then
                coordinator:OnSlotDrop(source, x, y)
                coordinator:OnSlotDragEnd()
            else
                self:OnClicked()
            end
            drag:Destroy()
        end
        drag.OnCancel = function(dragSelf)
            coordinator:OnSlotDragEnd()
            drag:Destroy()
        end
        PostDragger(self:GetRootFrame(), event.KeyCode, drag)
    end,

    --- Toggles the drop-target highlight (called by the coordinator during a drag).
    ---@param self UICustomLobbySlotBase
    ---@param on boolean
    SetDropHighlight = function(self, on)
        self.DropHighlight:SetAlpha(on and 0.15 or 0.0)
    end,

    --- Click on the row (a controller intent — the host applies and broadcasts it):
    --- an open slot is taken by the local player; your own slot toggles ready.
    ---@param self UICustomLobbySlotBase
    OnClicked = function(self)
        local player = self.CurrentPlayer
        if not player then
            CustomLobbyController.RequestTakeSlot(self.SlotIndex)
            return
        end
        if player.OwnerID == CustomLobbyLocalModel.GetSingleton().LocalPeerId() then
            CustomLobbyController.RequestSetReady(not player.Ready)
        end
    end,

    --#endregion

    ---@param self UICustomLobbySlotBase
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-- exported for the presentations to subclass (`Class(import(...).SlotBase) { ... }`)
SlotBase = CustomLobbySlotBase
