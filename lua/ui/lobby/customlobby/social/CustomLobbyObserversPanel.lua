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

-- The Observers tab of the lobby's bottom-left tabbed panel: the observer list (the shared
-- CustomLobbyObserversInterface, which self-subscribes to the model's `Observers`) plus a "Become
-- observer" button. Everyone may drop to observers; the move is host-authoritative — a client's
-- click asks the host through the `RequestMoveToObserver` intent.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch
-- (see ../CustomLobbyTabs.lua).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyObserversInterface = import("/lua/ui/lobby/customlobby/customlobbyobserversinterface.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

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

---@class UICustomLobbyObserversPanel : Group
---@field List UICustomLobbyObserversInterface
---@field ObserveButton Button
local CustomLobbyObserversPanel = ClassUI(Group) {

    ---@param self UICustomLobbyObserversPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyObserversPanel")

        self.ObserveButton = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Become observer")
        self.ObserveButton.OnClick = function(button, modifiers)
            local slot = FindLocalSlot()
            if slot then
                CustomLobbyController.RequestMoveToObserver(slot)
            end
        end
        Tooltip.AddControlTooltipManual(self.ObserveButton, "Become observer", "Leave your slot and watch as an observer.")

        self.List = CustomLobbyObserversInterface.Create(self)
    end,

    ---@param self UICustomLobbyObserversPanel
    __post_init = function(self)
        Layouter(self.ObserveButton):AtHorizontalCenterIn(self):AtBottomIn(self, 4):End()
        Layouter(self.List)
            :AtLeftIn(self):AtRightIn(self):AtTopIn(self)
            :AnchorToTop(self.ObserveButton, 6)
            :End()
    end,
}

---@param parent Control
---@return UICustomLobbyObserversPanel
Create = function(parent)
    return CustomLobbyObserversPanel(parent)
end
