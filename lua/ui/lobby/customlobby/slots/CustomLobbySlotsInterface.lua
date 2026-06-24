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

-- The slot subsystem's entry point: the "Players" header over the active *layout body*, plus the
-- shared drag coordinator. The composition root mounts this and fills its area with it.
--
-- One layout is alive at a time, picked by the AutoTeams mode: the one-column layout
-- ([onecolumn/CustomLobbyOneColumnSlots](onecolumn/CustomLobbyOneColumnSlots.lua)) for the non-team
-- modes, and the two-column team layout for the binary modes (left/right, top/bottom, even/odd).
-- (The two-column layout + the AutoTeams-driven swap land in the next step; for now it is always
-- one-column.)
--
-- This selector is the rows' **drag coordinator** (`UICustomLobbySlotCoordinator`) for *every*
-- layout, because it alone needs to hit-test across the rows and float the drag ghost — so the
-- layout bodies stay pure "build + place + reveal" and never duplicate the drag logic. Each body is
-- handed this selector as its rows' coordinator and exposes its `Rows` for the hit-test.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyOneColumnSlots = import("/lua/ui/lobby/customlobby/slots/onecolumn/customlobbyonecolumnslots.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local HeaderHeight = 24           -- the "Players" header + gap above the layout body

---@class UICustomLobbySlotsInterface : Group, UICustomLobbySlotCoordinator
---@field Trash TrashBag
---@field Header Text
---@field Body UICustomLobbyOneColumnSlots   # the active layout body
---@field HighlightedSlot number | false       # slot currently shown as a drop target
---@field DragGhost Group | false              # floating label following the cursor mid-drag
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

        -- the active layout body; the selector is its rows' coordinator (passed as `self`)
        self.Body = CustomLobbyOneColumnSlots.Create(self, self)
    end,

    ---@param self UICustomLobbySlotsInterface
    __post_init = function(self)
        Layouter(self.Header):AtLeftIn(self, 4):AtTopIn(self):End()
        Layouter(self.Body)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.Header, 4):AtBottomIn(self)
            :End()
    end,

    --- The (scaled) height the slot area wants: the header plus the active layout's row block. The
    --- composition root binds the slot area's height to this (it reads SlotCount, so it re-fires as
    --- the lobby fills/empties).
    ---@param self UICustomLobbySlotsInterface
    ---@return number
    PreferredHeight = function(self)
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        return LayoutHelpers.ScaleNumber(HeaderHeight) + CustomLobbyOneColumnSlots.HeightForCount(math.max(count, 1))
    end,

    ---------------------------------------------------------------------------
    --#region Slot drag coordination (UICustomLobbySlotCoordinator)
    --
    -- A drop resolves to the RequestSwapSlots intent, host-authoritative; the state here is purely
    -- visual. Rows belong to the active layout body, reached via `self.Body.Rows`.

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
            local row = self.Body.Rows[slot]
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
        if self.HighlightedSlot and self.Body.Rows[self.HighlightedSlot] then
            self.Body.Rows[self.HighlightedSlot]:SetDropHighlight(false)
        end
        self.HighlightedSlot = slot
        if slot and self.Body.Rows[slot] then
            self.Body.Rows[slot]:SetDropHighlight(true)
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

---@param parent Control
---@return UICustomLobbySlotsInterface
Create = function(parent)
    return CustomLobbySlotsInterface(parent)
end
