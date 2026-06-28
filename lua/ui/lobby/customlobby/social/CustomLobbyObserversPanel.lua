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

-- The Observers tab of the lobby's bottom-left tabbed panel: the observer list plus a "Become
-- observer" button. Everyone may drop to observers; the move is host-authoritative — a client's
-- click asks the host through the `RequestMoveToObserver` intent.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch
-- (see ../CustomLobbyTabs.lua).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor
local Debug = true

--- The local player's slot (the one this peer owns), or nil if they're an observer / unseated.
---@return number | nil
local function FindLocalSlot()
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local localId = CustomLobbyLocalModel.GetSingleton().LocalPeerId()
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        local player = launch.Players[slot]()
        if player and player.OwnerID == localId then
            return slot
        end
    end
    return nil
end

---@class UICustomLobbyObserversPanel : Bitmap
---@field ObserveButton Button
---@field Header Text
---@field Names Text
---@field Trash TrashBag
---@field ObserversObserver LazyVar
local CustomLobbyObserversPanel = ClassUI(Bitmap) {

    ---@param self UICustomLobbyObserversPanel
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self:SetSolidColor(Debug and '303080ff' or '00000000')
        self:DisableHitTest()

        self.Trash = TrashBag()

        self.Header = UIUtil.CreateText(self, "Observers (0)", 14, UIUtil.titleFont)
        self.Names = UIUtil.CreateText(self, "—", 12, UIUtil.bodyFont)
        self.Names:SetColor('ff9aa0a8')

        self.ObserveButton = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Become observer")
        self.ObserveButton.OnClick = function(button, modifiers)
            local slot = FindLocalSlot()
            if slot then
                CustomLobbyController.RequestMoveToObserver(slot)
            end
        end
        Tooltip.AddControlTooltipManual(self.ObserveButton, "Become observer", "Leave your slot and watch as an observer.")

        local model = CustomLobbyLaunchModel.GetSingleton()
        self.ObserversObserver = self.Trash:Add(
            LazyVarDerive(model.Observers, function(observersLazy)
                self:OnObserversChanged(observersLazy())
            end))
    end,

    ---@param self UICustomLobbyObserversPanel
    __post_init = function(self, parent)
        Layouter(self):Fill(parent):End()
        Layouter(self.Header):AtLeftTopIn(self):End()
        Layouter(self.Names):AtLeftIn(self):AnchorToBottom(self.Header, 4):End()
        Layouter(self.ObserveButton):AtHorizontalCenterIn(self):AnchorToBottom(self.Names, 8):End()
    end,

    --- Renders the observer count + names.
    ---@param self UICustomLobbyObserversPanel
    ---@param observers UICustomLobbyPlayer[]
    OnObserversChanged = function(self, observers)
        local count = table.getn(observers)
        self.Header:SetText("Observers (" .. count .. ")")

        if count == 0 then
            self.Names:SetText("—")
            return
        end

        local names = {}
        for i = 1, count do
            names[i] = observers[i].PlayerName or "?"
        end
        self.Names:SetText(table.concat(names, ", "))
    end,

    ---@param self UICustomLobbyObserversPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyObserversPanel
Create = function(parent)
    return CustomLobbyObserversPanel(parent)
end
