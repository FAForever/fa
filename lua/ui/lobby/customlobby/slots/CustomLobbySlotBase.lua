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
--   * the model subscription (`model.Players[slot]`) + the CPU-benchmark subscription,
--   * the CPU-cap math (most-played category, +0 unit count, green→red headroom step),
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
-- `RenderPlayer` / `RenderCpu` paint those from the normalised player / CPU views, so the formatting
-- (faction label, `T1`, ready/CPU colours, unit string) stays here, in one place. A presentation that
-- needs a different mapping (e.g. a faction *icon*) can override `RenderPlayer` / `RenderCpu`.
--
-- This keeps the drag/CPU/intent logic single-sourced; the presentations are pure arrangement.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameColors = import("/lua/gamecolors.lua").GameColors
local Color = import("/lua/shared/color.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyPerformancePopover = import("/lua/ui/lobby/customlobby/customlobbyperformancepopover.lua")
local CustomLobbyContextMenu = import("/lua/ui/lobby/customlobby/customlobbycontextmenu.lua")
local CustomLobbyMenus = import("/lua/ui/lobby/customlobby/customlobbymenus.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

--- Short faction label for a faction index (5 = Random has no factions.lua entry).
---@param faction number
---@return string
local function FactionLabel(faction)
    local factions = import("/lua/factions.lua").Factions
    local data = factions[faction]
    if data then
        return data.DisplayName or data.Key or tostring(faction)
    end
    return "Random"
end

--- The sim-rate categories tracked in PerformanceTrackingV2, ordered for the
--- "most-played" pick (matches the popover).
local PerformanceCategories = { 'Skirmish', 'SkirmishWithAI', 'Campaign' }

--- The bucket index for a sim rate (index k holds rate k - 11, so +0 -> 11, -4 -> 7).
---@param rate number
---@return number
local function BucketForRate(rate)
    return rate + 11
end

--- The most-played category in a benchmark, by sample count, or nil if none.
---@param metrics UIPerformanceMetrics | nil
---@return table | nil
local function PickCategory(metrics)
    if not metrics then
        return nil
    end
    local best, bestSamples = nil, -1
    for _, key in PerformanceCategories do
        local c = metrics[key]
        if c and (c.Samples or 0) > bestSamples then
            bestSamples = c.Samples or 0
            best = c
        end
    end
    if not best or bestSamples <= 0 then
        return nil
    end
    return best
end

--- Compact unit count for the slot label (e.g. 1421 -> "1.4k").
---@param value number
---@return string
local function FormatUnits(value)
    if value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(math.floor(value + 0.5))
end

--- Indicator colour for how far the sim has to slow down to sustain the cap: green
--- when +0 already suffices (step 0), fading to red at -4 or worse (step 4).
---@param step number   # sim-rate steps below +0 needed to reach the cap (0..4)
---@return Color
local function StepColor(step)
    local t = math.clamp(step / 4, 0.0, 1.0)
    local hue = (1.0 - t) * 0.333   -- 0.333 turns = green, 0 = red
    return Color.ColorHSV(hue, 1.0, 0.85, 1.0)
end

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
---@field ClickArea Bitmap
---@field PlayerObserver LazyVar
---@field CpuObserver LazyVar
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

        local model = CustomLobbyLaunchModel.GetSingleton()
        self.PlayerObserver = self.Trash:Add(
            LazyVarDerive(model.Players[slotIndex], function(playerLazy)
                self:OnPlayerChanged(playerLazy())
            end))

        self.CpuObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLocalModel.GetSingleton().CpuBenchmarks, function(benchmarksLazy)
                -- read the lazy so the dependency edge (re)forms; the value itself
                -- is read from the model inside RefreshCpu
                benchmarksLazy()
                self:RefreshCpu()
            end))
    end,

    ---@param self UICustomLobbySlotBase
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.Background):Fill(self):End()
        Layouter(self.DropHighlight):Fill(self):End()
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
    --#region Rendering (computes the view, defers painting to the hooks)

    --- Normalises the slot's player into a view and hands it to the presentation.
    ---@param self UICustomLobbySlotBase
    ---@param player UICustomLobbyPlayer | false
    OnPlayerChanged = function(self, player)
        self.CurrentPlayer = player
        self:RefreshCpu()

        if not player then
            self:RenderPlayer(nil)
            return
        end

        self:RenderPlayer({
            colorHex = GameColors.PlayerColors[player.PlayerColor] or 'ffffffff',
            name = player.PlayerName or "?",
            nameColor = player.Human and 'ffffffff' or 'ffd9c97a',
            faction = FactionLabel(player.Faction),
            team = (player.Team and player.Team > 1) and ("T" .. (player.Team - 1)) or "-",
            ready = player.Ready and "ready" or "",
            readyColor = player.Ready and 'ff7ad97a' or 'ff888888',
        })
    end,

    --- Computes the CPU view from this slot player's shared sim-performance benchmark: the label is
    --- the max units the machine handled at full speed (+0), and the indicator is green if that
    --- already covers the recommended cap, fading to red the further the sim must slow (down to -4).
    ---@param self UICustomLobbySlotBase
    RefreshCpu = function(self)
        local player = self.CurrentPlayer
        if not player then
            self:RenderCpu(nil)
            return
        end

        local metrics = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks()[player.OwnerID]
        local category = PickCategory(metrics)
        local atZero = category and category[BucketForRate(0)]
        if not (atZero and atZero.UnitCount) then
            self:RenderCpu({ text = "—", textColor = 'ff9aa0a8', showIndicator = false })
            return
        end

        local maxAtZero = atZero.UnitCount.Max or 0
        local view = { text = FormatUnits(maxAtZero), textColor = 'ff9aa0a8', showIndicator = false }

        local cap = CustomLobbyRules.RecommendedUnitCap()
        if cap and cap > 0 then
            -- how many sim-rate steps below +0 are needed before the machine sustains the
            -- cap (0 = fine at +0); worst case (red) if even -4 falls short
            local step = 0
            if maxAtZero < cap then
                step = 4
                for s = 1, 4 do
                    local bucket = category[BucketForRate(-s)]
                    if bucket and bucket.UnitCount and (bucket.UnitCount.Max or 0) >= cap then
                        step = s
                        break
                    end
                end
            end
            view.indicatorColor = StepColor(step)
            view.showIndicator = true
        end

        self:RenderCpu(view)
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
        local player = self.CurrentPlayer
        if not player then
            CustomLobbyPerformancePopover.Hide()
            return
        end
        local benchmark = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks()[player.OwnerID]
        CustomLobbyPerformancePopover.Show(self:CpuAnchor(), benchmark, CustomLobbyRules.RecommendedUnitCap())
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
