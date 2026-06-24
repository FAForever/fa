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

-- The two-column slot layout: the binary AutoTeams modes (left/right, top/bottom, even/odd) split
-- the slots into two team columns of half-width, double-height CustomLobbySlotCard cards. Each
-- slot's side comes from CustomLobbyRules.BuildSideResolver (start position for the positional
-- modes, start-spot parity for pvsi).
--
-- "Two columns, unresolved": for a positional mode whose map / start positions aren't loaded yet the
-- resolver can't place anyone, so we still show both columns but fill them by slot-index parity and
-- withhold the side labels (Left / Right / …); once positions resolve, a Relayout snaps the cards to
-- their true sides and reveals the labels.
--
-- It is a *layout body* under CustomLobbySlotsInterface: that selector owns the header and is the
-- rows' drag coordinator, so this body just builds the cards, places them by side, reveals the
-- active ones, and (with the module HeightForCount) reports how tall the taller column is. The
-- selector passes itself as the cards' coordinator.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyRules = import("/lua/ui/lobby/customlobby/customlobbyrules.lua")
local CustomLobbySlotCard = import("/lua/ui/lobby/customlobby/slots/twocolumn/customlobbyslotcard.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local CardHeight = 48
local CardGap = 2
local ColumnGap = 8               -- the gutter between the two columns
local LabelHeight = 20            -- the per-column team label (shown only when resolved)
local LabelColor = 'ff8a909a'

--- Assigns the visible slots (1..count) to the two team columns, in slot order. Returns `cols`
--- (`{ [1] = {slots…}, [2] = {slots…} }`) and `resolved` (false when a positional mode's start
--- positions aren't loaded — sides then fall back to slot-index parity and the labels are withheld).
---@param count number
---@return table cols
---@return boolean resolved
local function ComputeColumns(count)
    local resolver, resolved = CustomLobbyRules.BuildSideResolver()
    local cols = { {}, {} }
    for slot = 1, count do
        local side = resolved and resolver and resolver(slot) or nil
        if side ~= 1 and side ~= 2 then
            side = (math.mod(slot, 2) == 1) and 1 or 2
        end
        table.insert(cols[side], slot)
    end
    return cols, resolved
end

---@class UICustomLobbyTwoColumnSlots : Group
---@field Trash TrashBag
---@field Coordinator UICustomLobbySlotCoordinator
---@field Rows UICustomLobbySlotBase[]
---@field Columns Group[]              # [1] = side A container, [2] = side B
---@field Labels Text[]                # [1]/[2] per-column team labels
---@field Ready boolean
---@field SlotCountObserver LazyVar
---@field ScenarioObserver LazyVar
---@field GameOptionsObserver LazyVar
local CustomLobbyTwoColumnSlots = Class(Group) {

    ---@param self UICustomLobbyTwoColumnSlots
    ---@param parent Control
    ---@param coordinator UICustomLobbySlotCoordinator
    __init = function(self, parent, coordinator)
        Group.__init(self, parent, "CustomLobbyTwoColumnSlots")

        self.Trash = TrashBag()
        self.Coordinator = coordinator
        self.Ready = false

        self.Columns = { Group(self, "Col1"), Group(self, "Col2") }
        self.Labels = {
            UIUtil.CreateText(self.Columns[1], "", 12, UIUtil.titleFont),
            UIUtil.CreateText(self.Columns[2], "", 12, UIUtil.titleFont),
        }
        for _, label in self.Labels do
            label:SetColor(LabelColor)
            label:DisableHitTest()
        end

        self.Rows = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Rows[slot] = CustomLobbySlotCard.Create(self, slot, coordinator)
        end

        -- the side split depends on the mode + the map's start positions, so re-place on any of them
        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.GameOptionsObserver = self.Trash:Add(
            LazyVarDerive(launch.GameOptions, function(lazy) lazy(); self:Relayout() end))
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(launch.ScenarioFile, function(lazy) lazy(); self:Relayout() end))
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySessionModel.GetSingleton().SlotCount, function(lazy)
                lazy()
                self:Relayout()
            end))
    end,

    ---@param self UICustomLobbyTwoColumnSlots
    __post_init = function(self)
        -- two columns split down the middle with a small gutter (a column is the positioning frame
        -- the cards anchor into; the side label sits at its top)
        Layouter(self.Columns[1]):AtLeftIn(self):AtTopIn(self):AtBottomIn(self):End()
        self.Columns[1].Right:Set(function() return self.Left() + 0.5 * self.Width() - LayoutHelpers.ScaleNumber(0.5 * ColumnGap) end)
        Layouter(self.Columns[2]):AtRightIn(self):AtTopIn(self):AtBottomIn(self):End()
        self.Columns[2].Left:Set(function() return self.Left() + 0.5 * self.Width() + LayoutHelpers.ScaleNumber(0.5 * ColumnGap) end)

        Layouter(self.Labels[1]):AtHorizontalCenterIn(self.Columns[1]):AtTopIn(self.Columns[1]):End()
        Layouter(self.Labels[2]):AtHorizontalCenterIn(self.Columns[2]):AtTopIn(self.Columns[2]):End()

        self.Ready = true
        self:Relayout()
    end,

    --- Splits the active slots into the two columns and stacks each column's cards; shows the side
    --- labels only when the sides are resolved. Re-run whenever the mode / map / slot count changes.
    ---@param self UICustomLobbyTwoColumnSlots
    Relayout = function(self)
        if not self.Ready then
            return
        end
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        local cols, resolved = ComputeColumns(count)
        local labels = CustomLobbyRules.SideLabels(CustomLobbyRules.AutoTeamMode())
        local labelled = resolved and labels ~= nil

        for column = 1, 2 do
            local label = self.Labels[column]
            if labelled then
                label:SetText(labels[column])
                label:Show()
            else
                label:Hide()
            end

            -- stack this column's cards under the label (or the column top when unlabelled)
            local prev = nil
            for _, slot in cols[column] do
                local card = self.Rows[slot]
                local builder = Layouter(card):AtLeftIn(self.Columns[column]):AtRightIn(self.Columns[column]):Height(CardHeight)
                if not prev then
                    if labelled then
                        builder:AnchorToBottom(label, 2)
                    else
                        builder:AtTopIn(self.Columns[column])
                    end
                else
                    builder:AnchorToBottom(prev, CardGap)
                end
                builder:End()
                card:Show()
                prev = card
            end
        end

        -- hide the rows past the active count (every slot 1..count landed in a column above)
        for slot = count + 1, CustomLobbyLaunchModel.MaxSlots do
            self.Rows[slot]:Hide()
        end
    end,

    ---@param self UICustomLobbyTwoColumnSlots
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- The (scaled) height of the taller team column for `count` slots — the selector adds the header.
--- Mirrors Relayout's split so the area is sized to what's actually drawn (label + stacked cards).
---@param count number
---@return number
HeightForCount = function(count)
    local cols, resolved = ComputeColumns(count)
    local rows = math.max(table.getn(cols[1]), table.getn(cols[2]))
    local height = rows * LayoutHelpers.ScaleNumber(CardHeight)
    if rows > 1 then
        height = height + (rows - 1) * LayoutHelpers.ScaleNumber(CardGap)
    end
    if resolved then
        height = height + LayoutHelpers.ScaleNumber(LabelHeight)
    end
    return height
end

---@param parent Control
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbyTwoColumnSlots
Create = function(parent, coordinator)
    return CustomLobbyTwoColumnSlots(parent, coordinator)
end
