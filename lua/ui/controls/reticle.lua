--******************************************************************************************************
--** Copyright (c) 2022  clyf
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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

-- Local upvalues for performance
local GetMouseScreenPos = GetMouseScreenPos
local GetMouseWorldPos = GetMouseWorldPos

--- Reticle base class for displaying images and texts on the cursor
---@class Reticle : Group
---@field parent WorldView
---@field Trash TrashBag
---@field onMap boolean
---@field mapX number
---@field mapZ number
Reticle = ClassUI(Group) {

    __init = function(self, parent, data)
        -- update our basic information
        Group.__init(self, parent)
        self.WorldView = parent
        self.WorldView.Trash:Add(self)
        self.WorldView.CursorTrash:Add(self)
        self.Trash = TrashBag()
        self.onMap = false
        self.changedOnMap = true

        -- get map dimensions for on and off map update check
        local scenarioInfo = SessionGetScenarioInfo()
        self.mapX, self.mapZ = scenarioInfo.PlayableAreaWidth, scenarioInfo.PlayableAreaHeight

        -- set dimensions, default 64x64
        local xDim, yDim = data.xDim or 64, data.yDim or 64
        LayoutHelpers.SetDimensions(self, xDim, yDim)

        -- update our position for the first time
        local pos = GetMouseScreenPos()
        LayoutHelpers.AtLeftIn(self, parent, pos[1] - self.Width()/2)
        LayoutHelpers.AtTopIn(self, parent, pos[2] - self.Height()/2)

        -- create our child elements
        self:SetLayout()

        -- update us on frame
        self:SetNeedsFrameUpdate(true)
        self:DisableHitTest(true)
    end,

    --- create and set the initial position of our child components
    SetLayout = function(self)
        -- override me!
    end,

    --- update all our child components
    UpdateDisplay = function(self, mouseWorldPos, changed)
        -- override me!
    end,

    --- function to update our on/off map state and see if it changed
    ---@param self Reticle
    ---@param mouseWorldPos Vector
    UpdateOnMapStatus = function(self, mouseWorldPos)
        if ((mouseWorldPos[1] < 1 or mouseWorldPos[1] > self.mapX - 1) or
        (mouseWorldPos[3] < 1 or mouseWorldPos[3] > self.mapZ - 1)) == self.onMap then
            self.changedOnMap = true
            self.onMap = not self.onMap
        end
    end,

    --- updates the position of our reticle to align with our mouse
    ---@param self any
    UpdatePosition = function(self)
        local pos = GetMouseScreenPos()
        self.Left:Set(pos[1] - self.Width()/2)
        self.Top:Set(pos[2] - self.Height()/2)
    end,

    --- frame update function
    ---@param self any
    ---@param elapsedTime any
    OnFrame = function(self, elapsedTime)
        -- update if we're over the world, hide it otherwise
        if self.WorldView.CursorOverWorld then

            -- update our on/offMap state and track if it changed
            local mouseWorldPos = GetMouseWorldPos()
            self:UpdateOnMapStatus(mouseWorldPos)

            -- show if hidden
            if self:IsHidden() then
                self:Show()
                self.changedOnMap = true
            end

            -- update our layout
            self:UpdateDisplay(mouseWorldPos)

            -- move our reticle to a position centered on the mouse
            self:UpdatePosition()
        else
            if not self:IsHidden() then
                self:Hide()
            end
        end
    end,

    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- Test display reticle, just displays mouse position and whether we're over the map or not
---@class TestReticle : Reticle
TestReticle = ClassUI(Reticle) {

    SetLayout = function(self)
        self.text = UIUtil.CreateText(self, "Reticle", 10, UIUtil.bodyFont, true)
        self.onMapText = UIUtil.CreateText(self, "On Map", 10, UIUtil.bodyFont, true)
        self.mouseXPrefix = UIUtil.CreateText(self, "MouseX: ", 10, UIUtil.bodyFont, true)
        self.mouseYPrefix = UIUtil.CreateText(self, "MouseY: ", 10, UIUtil.bodyFont, true)
        self.mouseZPrefix = UIUtil.CreateText(self, "MouseZ: ", 10, UIUtil.bodyFont, true)
        self.mouseXText = UIUtil.CreateText(self, "mouseX", 10, UIUtil.bodyFont, true)
        self.mouseYText = UIUtil.CreateText(self, "mouseY", 10, UIUtil.bodyFont, true)
        self.mouseZText = UIUtil.CreateText(self, "mouseZ", 10, UIUtil.bodyFont, true)

        LayoutHelpers.RightOf(self.text, self, 1)
        LayoutHelpers.Below(self.onMapText, self.text, 1)
        LayoutHelpers.Below(self.mouseXPrefix, self.onMapText, 1)
        LayoutHelpers.Below(self.mouseYPrefix, self.mouseXPrefix, 1)
        LayoutHelpers.Below(self.mouseZPrefix, self.mouseYPrefix, 1)

        LayoutHelpers.RightOf(self.mouseXText, self.mouseXPrefix, 0)
        LayoutHelpers.RightOf(self.mouseYText, self.mouseYPrefix, 0)
        LayoutHelpers.RightOf(self.mouseZText, self.mouseZPrefix, 0)
    end,

    UpdateDisplay = function(self, mouseWorldPos)
        if self.onMap then
            if self.changedOnMap then
                self.onMapText:SetText("On Map")
                self.changedOnMap = false
            end
            self.mouseXText:SetText(string.format('%.2f', mouseWorldPos[1]))
            self.mouseYText:SetText(string.format('%.2f', mouseWorldPos[2]))
            self.mouseZText:SetText(string.format('%.2f', mouseWorldPos[3]))
        else
            if self.changedOnMap then
                self.onMapText:SetText("Off Map")
                self.mouseXText:SetText('--')
                self.mouseYText:SetText('--')
                self.mouseZText:SetText('--')
                self.changedOnMap = false
            end
        end
    end,
}