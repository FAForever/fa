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

-- A single slot row. Subscribes to its own slot LazyVar (`model.Players[slot]`) and
-- renders it; a change to one slot re-fires only this row. Read-only for now —
-- interactive controls (faction/colour/team/ready) call controller intents in a
-- later slice. See /lua/ui/lobby/TARGET_ARCHITECTURE.md § 6.

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

---@class UICustomLobbySlotInterface : Group
---@field Trash TrashBag
---@field SlotIndex number
---@field Coordinator UICustomLobbySlotCoordinator
---@field Background Bitmap
---@field DropHighlight Bitmap
---@field ClickArea Bitmap
---@field CpuHover Bitmap
---@field SlotNumber Text
---@field ColorSwatch Bitmap
---@field Name Text
---@field Faction Text
---@field Cpu Text
---@field CpuIndicator Bitmap
---@field Team Text
---@field Ready Text
---@field PlayerObserver LazyVar
---@field CpuObserver LazyVar
---@field CurrentPlayer UICustomLobbyPlayer | false
local CustomLobbySlotInterface = Class(Group) {

    ---@param self UICustomLobbySlotInterface
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

        self.SlotNumber = UIUtil.CreateText(self, tostring(slotIndex), 14, UIUtil.bodyFont)
        self.ColorSwatch = Bitmap(self)
        self.ColorSwatch:SetSolidColor('00000000')
        self.Name = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Faction = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Cpu = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        -- a small square left of the CPU label: green when the machine sustains the
        -- recommended unit cap at full speed, fading to red the more the sim must slow
        self.CpuIndicator = Bitmap(self)
        self.CpuIndicator:SetSolidColor('ff7ad97a')
        self.CpuIndicator:SetAlpha(0.0)
        self.CpuIndicator:DisableHitTest()
        self.Team = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Ready = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)

        -- transparent overlay that catches clicks on the whole row; for now a click
        -- on your own slot toggles ready (the one interactive message this far)
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

        -- a hover zone over the CPU score; entering it pops the performance chart
        self.CpuHover = Bitmap(self)
        self.CpuHover:SetSolidColor('00000000')
        self.CpuHover.HandleEvent = function(control, event)
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
        end

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

    ---@param self UICustomLobbySlotInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.Background):Fill(self):End()
        Layouter(self.DropHighlight):Fill(self):End()
        Layouter(self.ClickArea):Fill(self):Over(self, 10):End()
        Layouter(self.CpuHover):Fill(self.Cpu):Over(self, 20):End()

        Layouter(self.SlotNumber):AtLeftIn(self, 6):AtVerticalCenterIn(self):End()
        Layouter(self.ColorSwatch):AnchorToRight(self.SlotNumber, 8):AtVerticalCenterIn(self):Width(14):Height(14):End()
        Layouter(self.Name):AnchorToRight(self.ColorSwatch, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Ready):AtRightIn(self, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Team):AnchorToLeft(self.Ready, 12):AtVerticalCenterIn(self):End()
        Layouter(self.Cpu):AnchorToLeft(self.Team, 12):AtVerticalCenterIn(self):End()
        Layouter(self.CpuIndicator):AnchorToLeft(self.Cpu, 5):AtVerticalCenterIn(self):Width(8):Height(12):End()
        Layouter(self.Faction):AnchorToLeft(self.CpuIndicator, 10):AtVerticalCenterIn(self):End()
    end,

    --- Renders the slot from its player (or the empty state).
    ---@param self UICustomLobbySlotInterface
    ---@param player UICustomLobbyPlayer | false
    OnPlayerChanged = function(self, player)
        self.CurrentPlayer = player
        self:RefreshCpu()

        if not player then
            self.ColorSwatch:SetSolidColor('00000000')
            self.Name:SetText("- open -")
            self.Name:SetColor('ff888888')
            self.Faction:SetText("")
            self.Team:SetText("")
            self.Ready:SetText("")
            return
        end

        local colorHex = GameColors.PlayerColors[player.PlayerColor] or 'ffffffff'
        self.ColorSwatch:SetSolidColor(colorHex)

        self.Name:SetText(player.PlayerName or "?")
        self.Name:SetColor(player.Human and 'ffffffff' or 'ffd9c97a')

        self.Faction:SetText(FactionLabel(player.Faction))
        self.Team:SetText(player.Team and player.Team > 1 and ("T" .. (player.Team - 1)) or "-")
        self.Ready:SetText(player.Ready and "ready" or "")
        self.Ready:SetColor(player.Ready and 'ff7ad97a' or 'ff888888')
    end,

    --- Renders the CPU column from this slot player's shared sim-performance benchmark:
    --- the label is the max units the machine handled at full speed (+0), and the square
    --- is green if that already covers the recommended cap, fading to red the further the
    --- sim has to slow down (down to -4) to reach it.
    ---@param self UICustomLobbySlotInterface
    RefreshCpu = function(self)
        local player = self.CurrentPlayer
        if not player then
            self.Cpu:SetText("")
            self.CpuIndicator:SetAlpha(0.0)
            return
        end

        local metrics = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks()[player.OwnerID]
        local category = PickCategory(metrics)
        local atZero = category and category[BucketForRate(0)]
        if not (atZero and atZero.UnitCount) then
            self.Cpu:SetText("—")
            self.Cpu:SetColor('ff9aa0a8')
            self.CpuIndicator:SetAlpha(0.0)
            return
        end

        local maxAtZero = atZero.UnitCount.Max or 0
        self.Cpu:SetText(FormatUnits(maxAtZero))
        self.Cpu:SetColor('ff9aa0a8')

        local cap = CustomLobbyRules.RecommendedUnitCap()
        if not cap or cap <= 0 then
            self.CpuIndicator:SetAlpha(0.0)
            return
        end

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

        self.CpuIndicator:SetSolidColor(StepColor(step))
        self.CpuIndicator:SetAlpha(1.0)
    end,

    --- Mouse entered the CPU score: show this player's sim-performance popover.
    ---@param self UICustomLobbySlotInterface
    OnCpuHoverEnter = function(self)
        local player = self.CurrentPlayer
        if not player then
            CustomLobbyPerformancePopover.Hide()
            return
        end
        local benchmark = CustomLobbyLocalModel.GetSingleton().CpuBenchmarks()[player.OwnerID]
        CustomLobbyPerformancePopover.Show(self.Cpu, benchmark, CustomLobbyRules.RecommendedUnitCap())
    end,

    --- A press on the row: if the coordinator allows dragging this slot (host, holding
    --- a player) start a drag-to-swap; otherwise it's a plain click.
    ---@param self UICustomLobbySlotInterface
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
    ---@param self UICustomLobbySlotInterface
    ---@param event KeyEvent
    OnRowContext = function(self, event)
        CustomLobbyPerformancePopover.Hide()
        CustomLobbyContextMenu.Show(CustomLobbyMenus.BuildSlotMenu(self.SlotIndex), event.MouseX, event.MouseY)
    end,

    --- Starts a drag from this row. The press only becomes a drag once the cursor
    --- travels past DragThreshold — under it, the release is treated as a click, so
    --- take/ready still work. Movement + drop are routed to the coordinator (it owns
    --- the hit-test across rows); a drop resolves to RequestSwapSlots.
    ---@param self UICustomLobbySlotInterface
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
    ---@param self UICustomLobbySlotInterface
    ---@param on boolean
    SetDropHighlight = function(self, on)
        self.DropHighlight:SetAlpha(on and 0.15 or 0.0)
    end,

    --- Click on the row (a controller intent — the host applies and broadcasts it):
    --- an open slot is taken by the local player; your own slot toggles ready.
    ---@param self UICustomLobbySlotInterface
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

    ---@param self UICustomLobbySlotInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@param slotIndex number
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbySlotInterface
Create = function(parent, slotIndex, coordinator)
    return CustomLobbySlotInterface(parent, slotIndex, coordinator)
end
