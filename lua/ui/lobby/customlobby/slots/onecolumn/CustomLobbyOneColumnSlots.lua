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

-- The one-column slot layout: every slot stacked in a single full-width column of thin
-- CustomLobbySlotRow rows. Used for the non-team AutoTeams modes (none / manual).
--
-- It is a *layout body* under CustomLobbySlotsInterface: that selector owns the "Players" header and
-- is the rows' drag coordinator (it alone needs to hit-test across rows), so this body just builds
-- the rows, stacks them, reveals the active ones (1..SlotCount), and exposes `Rows` for the
-- coordinator + `HeightForCount` for the selector's preferred-height calc. The selector passes
-- itself as the `coordinator` each row is wired to.

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbySlotRow = import("/lua/ui/lobby/customlobby/slots/onecolumn/customlobbyslotrow.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local SlotHeight = 24

---@class UICustomLobbyOneColumnSlots : Group
---@field Trash TrashBag
---@field Coordinator UICustomLobbySlotCoordinator
---@field Rows UICustomLobbySlotBase[]
---@field SlotCountObserver LazyVar
local CustomLobbyOneColumnSlots = Class(Group) {

    ---@param self UICustomLobbyOneColumnSlots
    ---@param parent Control
    ---@param coordinator UICustomLobbySlotCoordinator
    __init = function(self, parent, coordinator)
        Group.__init(self, parent, "CustomLobbyOneColumnSlots")

        self.Trash = TrashBag()
        self.Coordinator = coordinator

        self.Rows = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Rows[slot] = CustomLobbySlotRow.Create(self, slot, coordinator)
        end

        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbySessionModel.GetSingleton().SlotCount, function(slotCountLazy)
                self:OnSlotCountChanged(slotCountLazy())
            end))
    end,

    ---@param self UICustomLobbyOneColumnSlots
    __post_init = function(self)
        -- stack the rows top-to-bottom (slot i sits under slot i-1)
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local row = self.Rows[slot]
            local builder = Layouter(row):AtLeftIn(self):AtRightIn(self):Height(SlotHeight)
            if slot == 1 then
                builder:AtTopIn(self)
            else
                builder:AnchorToBottom(self.Rows[slot - 1], 0)
            end
            builder:End()
        end
    end,

    --- Shows the active slots (1..count) and hides the rest.
    ---@param self UICustomLobbyOneColumnSlots
    ---@param count number
    OnSlotCountChanged = function(self, count)
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            if slot <= count then
                self.Rows[slot]:Show()
            else
                self.Rows[slot]:Hide()
            end
        end
    end,

    ---@param self UICustomLobbyOneColumnSlots
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- The (scaled) height of the row block for `count` slots — the selector adds the header on top.
---@param count number
---@return number
HeightForCount = function(count)
    return math.max(count or 0, 1) * LayoutHelpers.ScaleNumber(SlotHeight)
end

---@param parent Control
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbyOneColumnSlots
Create = function(parent, coordinator)
    return CustomLobbyOneColumnSlots(parent, coordinator)
end
