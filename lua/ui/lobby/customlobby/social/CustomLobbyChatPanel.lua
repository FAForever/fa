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

-- The Chat tab of the lobby's bottom-left tabbed panel — a placeholder until the lobby-chat slice
-- lands. A bottom-left tab content component: created when its tab is selected and destroyed on
-- switch (see ../CustomLobbyTabs.lua), so it's the live panel for its whole lifetime.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group

local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbyChatPanel : Group
---@field Placeholder Text
local CustomLobbyChatPanel = ClassUI(Group) {

    ---@param self UICustomLobbyChatPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyChatPanel")

        self.Placeholder = UIUtil.CreateText(self, "Chat — coming soon", 14, UIUtil.bodyFont)
        self.Placeholder:SetColor('ff5a606a')
        self.Placeholder:DisableHitTest()
    end,

    ---@param self UICustomLobbyChatPanel
    __post_init = function(self)
        Layouter(self.Placeholder):AtHorizontalCenterIn(self):AtVerticalCenterIn(self):End()
    end,
}

---@param parent Control
---@return UICustomLobbyChatPanel
Create = function(parent)
    return CustomLobbyChatPanel(parent)
end
