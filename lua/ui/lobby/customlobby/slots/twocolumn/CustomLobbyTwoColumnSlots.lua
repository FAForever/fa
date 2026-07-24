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
-- slot's side is read straight from the slots derived model (`entry.Side`), which resolves it once
-- (via CustomLobbyRules.BuildSideResolver) — this body no longer re-derives the split itself.
--
-- The CustomLobbyTeamScore widget sits in a strip across the top — it *is* the side indicator
-- (`Left  3150  ·  3025  Right`), so it doubles as the columns' header. It self-hides for the
-- "two columns, unresolved" case (a positional mode whose map / start positions aren't loaded yet),
-- where we still show both columns but fill them by slot-index parity; once positions resolve a
-- Relayout snaps the cards to their true sides and the score reappears. The strip is reserved either
-- way, so the cards don't jump when it appears.
--
-- It is a *layout body* under CustomLobbySlotsInterface: that selector owns the "Players" header and
-- is the rows' drag coordinator, so this body just builds the cards, places them by side, reveals
-- the active ones, and (with the module HeightForCount) reports how tall the taller column is. The
-- selector passes itself as the cards' coordinator.

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbySlotsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyslotsderivedmodel.lua")
local CustomLobbyTeamScore = import("/lua/ui/lobby/customlobby/customlobbyteamscore.lua")
local CustomLobbySlotCard = import("/lua/ui/lobby/customlobby/slots/twocolumn/customlobbyslotcard.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local CardHeight = 48
local CardGap = 2
local ColumnGap = 8               -- the gutter between the two columns
local ScoreHeight = 26            -- the team-score strip across the top (the side indicator)

--- Assigns the visible slots (1..count) to the two team columns, in slot order. Each seat's side is
--- read straight from the slots derived model (`entry.Side`, resolved once there); an unresolved seat
--- (a positional mode whose positions aren't loaded, or a slot past the map's start spots) is `false`
--- and falls back to slot-index parity so both columns still populate.
---@param count number
---@return table cols   # { [1] = {slots…}, [2] = {slots…} }
local function ComputeColumns(count)
    local slots = CustomLobbySlotsDerivedModel.GetSlots()
    local cols = { {}, {} }
    for slot = 1, count do
        local entry = slots[slot]
        local side = entry and entry.Side
        if side ~= 1 and side ~= 2 then
            side = (math.mod(slot, 2) == 1) and 1 or 2
        end
        table.insert(cols[side], slot)
    end
    return cols
end

---@class UICustomLobbyTwoColumnSlots : Group
---@field Trash TrashBag
---@field Coordinator UICustomLobbySlotCoordinator
---@field Rows UICustomLobbySlotCard[]
---@field TeamScore UICustomLobbyTeamScore   # the side indicator strip atop the columns
---@field Columns Group[]                    # [1] = side A container, [2] = side B
---@field Ready boolean
---@field SlotCountObserver LazyVar
---@field SlotsObserver LazyVar
local CustomLobbyTwoColumnSlots = Class(Group) {

    ---@param self UICustomLobbyTwoColumnSlots
    ---@param parent Control
    ---@param coordinator UICustomLobbySlotCoordinator
    __init = function(self, parent, coordinator)
        Group.__init(self, parent, "CustomLobbyTwoColumnSlots")

        self.Trash = TrashBag()
        self.Coordinator = coordinator
        self.Ready = false

        -- the side indicator (Left/Top/Odd · ratings · Right/Bottom/Even); self-manages its content
        -- and visibility (it hides when the sides can't be determined yet)
        self.TeamScore = CustomLobbyTeamScore.Create(self)

        self.Columns = { Group(self, "Col1"), Group(self, "Col2") }

        self.Rows = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Rows[slot] = CustomLobbySlotCard.Create(self, slot, coordinator)
        end

        -- each seat's side is resolved in the slots derived model, so re-place whenever that table
        -- changes (a seat's side flips when the mode / map / start positions change); the reveal count
        -- is session state, so watch it too
        self.SlotsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySlotsDerivedModel.GetSlotsVar(), function(lazy) lazy(); self:Relayout() end))
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySessionModel.GetSingleton().SlotCount, function(lazy)
                lazy()
                self:Relayout()
            end))
    end,

    ---@param self UICustomLobbyTwoColumnSlots
    __post_init = function(self)
        -- the team-score strip spans the top; the two columns fill the rest, split down the middle
        -- with a small gutter (a column is the positioning frame the cards anchor into)
        Layouter(self.TeamScore):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(ScoreHeight):End()

        Layouter(self.Columns[1]):AtLeftIn(self):AnchorToBottom(self.TeamScore, 2):AtBottomIn(self):End()
        self.Columns[1].Right:Set(function() return self.Left() + 0.5 * self.Width() - LayoutHelpers.ScaleNumber(0.5 * ColumnGap) end)
        Layouter(self.Columns[2]):AtRightIn(self):AnchorToBottom(self.TeamScore, 2):AtBottomIn(self):End()
        self.Columns[2].Left:Set(function() return self.Left() + 0.5 * self.Width() + LayoutHelpers.ScaleNumber(0.5 * ColumnGap) end)

        self.Ready = true
        self.TeamScore:Initialize()
        self:Relayout()
    end,

    --- Splits the active slots into the two columns and stacks each column's cards from its top;
    --- re-run whenever the mode / map / slot count changes.
    ---@param self UICustomLobbyTwoColumnSlots
    Relayout = function(self)
        if not self.Ready then
            return
        end
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        local cols = ComputeColumns(count)

        for column = 1, 2 do
            local prev = nil
            for _, slot in cols[column] do
                local card = self.Rows[slot]
                local builder = Layouter(card):AtLeftIn(self.Columns[column]):AtRightIn(self.Columns[column]):Height(CardHeight)
                if not prev then
                    builder:AtTopIn(self.Columns[column])
                else
                    builder:AnchorToBottom(prev, CardGap)
                end
                builder:End()
                card:SetMirrored(column == 2)   -- the right column faces inward (mirrored)
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

--- The (scaled) height of the score strip plus the taller team column for `count` slots — the
--- selector adds the "Players" header. Mirrors Relayout's split so the area fits what's drawn.
---@param count number
---@return number
HeightForCount = function(count)
    local cols = ComputeColumns(count)
    local rows = math.max(table.getn(cols[1]), table.getn(cols[2]))
    local height = LayoutHelpers.ScaleNumber(ScoreHeight) + rows * LayoutHelpers.ScaleNumber(CardHeight)
    if rows > 1 then
        height = height + (rows - 1) * LayoutHelpers.ScaleNumber(CardGap)
    end
    return height
end

---@param parent Control
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbyTwoColumnSlots
Create = function(parent, coordinator)
    return CustomLobbyTwoColumnSlots(parent, coordinator)
end
