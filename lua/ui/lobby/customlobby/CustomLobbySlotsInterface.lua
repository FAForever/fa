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

-- The lobby's slot column: a "Players" header over a single column of slot rows (one
-- CustomLobbySlotInterface per possible slot). It subscribes to the session's SlotCount and reveals
-- the active rows (1..count), hiding the rest.
--
-- It is also the rows' **drag coordinator** (`UICustomLobbySlotCoordinator`): the slot rows raise
-- the drag gesture but this container owns it, because it is the only thing that knows every row's
-- rect. The "what's grabbed / where" state here is purely visual — a drop resolves to the
-- host-authoritative `RequestSwapSlots` intent.
--
-- The composition root fills its slot area with this component and sizes that area to the visible
-- rows via `HeightForSlots(count)` (kept here so the row height math has a single source), so the
-- chat/observers panel below grows for smaller games.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbySlotInterface = import("/lua/ui/lobby/customlobby/customlobbyslotinterface.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local SlotHeight = 24
local HeaderHeight = 24           -- the "Players" header + gap above the rows

---@class UICustomLobbySlotsInterface : Group, UICustomLobbySlotCoordinator
---@field Trash TrashBag
---@field Header Text
---@field Panel Group
---@field Rows UICustomLobbySlotInterface[]
---@field SlotCountObserver LazyVar
---@field HighlightedSlot number | false   # slot currently shown as a drop target
---@field DragGhost Group | false          # floating label following the cursor mid-drag
local CustomLobbySlotsInterface = Class(Group) {

    ---@param self UICustomLobbySlotsInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbySlotsInterface")

        self.Trash = TrashBag()
        self.HighlightedSlot = false
        self.DragGhost = false

        self.Header = UIUtil.CreateText(self, "Players", 14, UIUtil.titleFont)
        self.Header:SetColor('ff9aa0a8')
        self.Header:DisableHitTest()

        self.Panel = Group(self, "CustomLobbySlotsPanel")

        -- One row per possible slot, stacked in a single column; the SlotCount observer reveals the
        -- active ones.
        self.Rows = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Rows[slot] = CustomLobbySlotInterface.Create(self.Panel, slot, self)
        end

        local session = CustomLobbySessionModel.GetSingleton()
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(session.SlotCount, function(slotCountLazy)
                self:OnSlotCountChanged(slotCountLazy())
            end))
    end,

    ---@param self UICustomLobbySlotsInterface
    __post_init = function(self)
        Layouter(self.Header):AtLeftIn(self, 4):AtTopIn(self):End()
        Layouter(self.Panel)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.Header, 4):AtBottomIn(self)
            :End()

        -- stack the rows top-to-bottom (slot i sits under slot i-1)
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local row = self.Rows[slot]
            local builder = Layouter(row):AtLeftIn(self.Panel):AtRightIn(self.Panel):Height(SlotHeight)
            if slot == 1 then
                builder:AtTopIn(self.Panel)
            else
                builder:AnchorToBottom(self.Rows[slot - 1], 0)
            end
            builder:End()
        end
    end,

    --- Shows the active slots (1..count) and hides the rest.
    ---@param self UICustomLobbySlotsInterface
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

    ---------------------------------------------------------------------------
    --#region Slot drag coordination (UICustomLobbySlotCoordinator)
    --
    -- A drop resolves to the RequestSwapSlots intent, host-authoritative; the state here is purely
    -- visual.

    --- Only the host can drag, and only a slot that holds a player (you grab a token).
    ---@param self UICustomLobbySlotsInterface
    ---@param slot number
    ---@return boolean
    CanDrag = function(self, slot)
        if not CustomLobbyLocalModel.GetSingleton().IsHost() then
            return false
        end
        return CustomLobbyLaunchModel.GetSingleton().Players[slot]() ~= false
    end,

    --- The active slot whose row contains the screen point, or nil.
    ---@param self UICustomLobbySlotsInterface
    ---@param x number
    ---@param y number
    ---@return number | nil
    SlotIndexAt = function(self, x, y)
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        for slot = 1, count do
            local row = self.Rows[slot]
            if row and x >= row.Left() and x <= row.Right() and y >= row.Top() and y <= row.Bottom() then
                return slot
            end
        end
        return nil
    end,

    --- Mid-drag: follow the cursor with the ghost and highlight the row under it.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDragMove = function(self, source, x, y)
        if not self.DragGhost then
            self.DragGhost = self:CreateDragGhost(source)
        end
        self.DragGhost.Left:Set(x + LayoutHelpers.ScaleNumber(12))
        self.DragGhost.Top:Set(y + LayoutHelpers.ScaleNumber(8))
        self:HighlightSlot(self:SlotIndexAt(x, y))
    end,

    --- Drop: swap the source slot with whatever row the cursor is over (a move if it's
    --- empty). Dropping outside any row is a no-op.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDrop = function(self, source, x, y)
        local target = self:SlotIndexAt(x, y)
        if target and target ~= source then
            CustomLobbyController.RequestSwapSlots(source, target)
        end
    end,

    --- Clears the transient drag visuals.
    ---@param self UICustomLobbySlotsInterface
    OnSlotDragEnd = function(self)
        self:HighlightSlot(nil)
        if self.DragGhost then
            self.DragGhost:Destroy()
            self.DragGhost = false
        end
    end,

    --- Moves the drop-target highlight to `slot` (nil clears it).
    ---@param self UICustomLobbySlotsInterface
    ---@param slot number | nil
    HighlightSlot = function(self, slot)
        slot = slot or false
        if self.HighlightedSlot == slot then
            return
        end
        if self.HighlightedSlot and self.Rows[self.HighlightedSlot] then
            self.Rows[self.HighlightedSlot]:SetDropHighlight(false)
        end
        self.HighlightedSlot = slot
        if slot and self.Rows[slot] then
            self.Rows[slot]:SetDropHighlight(true)
        end
    end,

    --- Builds the floating drag label (the grabbed player's name) so it draws above the rows.
    --- Destroyed in OnSlotDragEnd.
    ---@param self UICustomLobbySlotsInterface
    ---@param source number
    ---@return Group
    CreateDragGhost = function(self, source)
        local player = CustomLobbyLaunchModel.GetSingleton().Players[source]()
        local name = (player and player.PlayerName) or ("Slot " .. tostring(source))

        local ghost = Group(self, "CustomLobbyDragGhost")
        ghost:DisableHitTest()

        local bg = Bitmap(ghost)
        bg:SetSolidColor('cc101418')
        bg:DisableHitTest()

        local label = UIUtil.CreateText(ghost, name, 14, UIUtil.bodyFont)
        label:DisableHitTest()

        Layouter(label):AtLeftTopIn(ghost, 6, 3):End()
        Layouter(bg):Fill(ghost):End()
        ghost.Width:Set(function() return label.Width() + LayoutHelpers.ScaleNumber(12) end)
        ghost.Height:Set(function() return label.Height() + LayoutHelpers.ScaleNumber(6) end)
        return ghost
    end,

    --#endregion

    ---@param self UICustomLobbySlotsInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- The (scaled) height needed to show `count` slot rows plus the header — the composition root sizes
--- the slot area with this so the rows fit exactly and the panel below floats up.
---@param count number
---@return number
HeightForSlots = function(count)
    local rows = math.max(count or 0, 1)
    return LayoutHelpers.ScaleNumber(HeaderHeight) + rows * LayoutHelpers.ScaleNumber(SlotHeight)
end

---@param parent Control
---@return UICustomLobbySlotsInterface
Create = function(parent)
    return CustomLobbySlotsInterface(parent)
end
