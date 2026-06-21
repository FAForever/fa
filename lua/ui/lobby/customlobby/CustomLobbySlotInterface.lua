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

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyModel = import("/lua/ui/lobby/customlobby/customlobbymodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

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

---@class UICustomLobbySlotInterface : Group
---@field Trash TrashBag
---@field SlotIndex number
---@field Background Bitmap
---@field ClickArea Bitmap
---@field SlotNumber Text
---@field ColorSwatch Bitmap
---@field Name Text
---@field Faction Text
---@field Team Text
---@field Ready Text
---@field PlayerObserver LazyVar
---@field CurrentPlayer UICustomLobbyPlayer | false
local CustomLobbySlotInterface = Class(Group) {

    ---@param self UICustomLobbySlotInterface
    ---@param parent Control
    ---@param slotIndex number
    __init = function(self, parent, slotIndex)
        Group.__init(self, parent, "CustomLobbySlot" .. tostring(slotIndex))

        self.Trash = TrashBag()
        self.SlotIndex = slotIndex
        self.CurrentPlayer = false

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('22ffffff')
        self.Background:DisableHitTest()

        self.SlotNumber = UIUtil.CreateText(self, tostring(slotIndex), 14, UIUtil.bodyFont)
        self.ColorSwatch = Bitmap(self)
        self.ColorSwatch:SetSolidColor('00000000')
        self.Name = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Faction = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Team = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Ready = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)

        -- transparent overlay that catches clicks on the whole row; for now a click
        -- on your own slot toggles ready (the one interactive message this far)
        self.ClickArea = Bitmap(self)
        self.ClickArea:SetSolidColor('00000000')
        self.ClickArea.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                self:OnClicked()
                return true
            end
            return false
        end

        local model = CustomLobbyModel.GetSingleton()
        self.PlayerObserver = self.Trash:Add(
            LazyVarDerive(model.Players[slotIndex], function(playerLazy)
                self:OnPlayerChanged(playerLazy())
            end))
    end,

    ---@param self UICustomLobbySlotInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self.Background):Fill(self):End()
        Layouter(self.ClickArea):Fill(self):Over(self, 10):End()

        Layouter(self.SlotNumber):AtLeftIn(self, 6):AtVerticalCenterIn(self):End()
        Layouter(self.ColorSwatch):AnchorToRight(self.SlotNumber, 8):AtVerticalCenterIn(self):Width(14):Height(14):End()
        Layouter(self.Name):AnchorToRight(self.ColorSwatch, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Ready):AtRightIn(self, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Team):AnchorToLeft(self.Ready, 12):AtVerticalCenterIn(self):End()
        Layouter(self.Faction):AnchorToLeft(self.Team, 12):AtVerticalCenterIn(self):End()
    end,

    --- Renders the slot from its player (or the empty state).
    ---@param self UICustomLobbySlotInterface
    ---@param player UICustomLobbyPlayer | false
    OnPlayerChanged = function(self, player)
        self.CurrentPlayer = player

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

    --- Click on the row. For now, clicking your own slot toggles your ready flag
    --- (a controller intent — the host applies and broadcasts it).
    ---@param self UICustomLobbySlotInterface
    OnClicked = function(self)
        local player = self.CurrentPlayer
        if not player then
            return
        end
        if player.OwnerID == CustomLobbyModel.GetSingleton().LocalPeerId() then
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
---@return UICustomLobbySlotInterface
Create = function(parent, slotIndex)
    return CustomLobbySlotInterface(parent, slotIndex)
end
