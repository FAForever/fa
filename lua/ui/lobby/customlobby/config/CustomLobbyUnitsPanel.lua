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

-- The Units tab panel of the config interface: a placeholder until the unit-restrictions slice
-- lands. A config-interface tab panel: the host creates it when the Units tab is selected and
-- destroys it on switch, and calls `Initialize` after sizing it (same interface as the others).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbyUnitsPanel : Group
---@field Info Text
local CustomLobbyUnitsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyUnitsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyUnitsPanel")

        self.Info = UIUtil.CreateText(self, "Unit restrictions — coming soon.", 14, UIUtil.bodyFont)
        self.Info:SetColor('ff8a909a')
        self.Info:DisableHitTest()
    end,

    ---@param self UICustomLobbyUnitsPanel
    __post_init = function(self)
        Layouter(self.Info):AtHorizontalCenterIn(self):AtTopIn(self, 16):End()
    end,

    --- Nothing deferred (no grid); kept for a uniform panel interface (the host calls it).
    ---@param self UICustomLobbyUnitsPanel
    Initialize = function(self)
    end,
}

---@param parent Control
---@return UICustomLobbyUnitsPanel
Create = function(parent)
    return CustomLobbyUnitsPanel(parent)
end
