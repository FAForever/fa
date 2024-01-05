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
local Reticle = import('/lua/ui/controls/reticle.lua').Reticle

-- Local upvalues for performance
local GetSelectedUnits = GetSelectedUnits

--- Reticle for teleport cost info
---@class UITeleportReticle : UIReticle
---@field ePrefix Text
---@field tPrefix Text
---@field eText Text
---@field tText Text
TeleportReticle = ClassUI(Reticle) {

    ---@param self UITeleportReticle
    SetLayout = function(self)
        self.ePrefix = UIUtil.CreateText(self, "Eng Cost: ", 16, UIUtil.bodyFont, true)
        self.tPrefix = UIUtil.CreateText(self, "Max Time: ", 16, UIUtil.bodyFont, true)
        self.eText = UIUtil.CreateText(self, "eCost", 16, UIUtil.bodyFont, true)
        self.tText = UIUtil.CreateText(self, "tCost", 16, UIUtil.bodyFont, true)
        LayoutHelpers.RightOf(self.ePrefix, self, 4)
        LayoutHelpers.RightOf(self.eText, self.ePrefix, 0)
        LayoutHelpers.Below(self.tPrefix, self.ePrefix, 4)
        LayoutHelpers.RightOf(self.tText, self.tPrefix, 0)

        self.ePrefix:SetColor('654bc2')
        self.tPrefix:SetColor('654bc2')
        self.eText:SetColor('ffff00')
    end,

    ---@param self UITeleportReticle
    ---@param mouseWorldPos Vector
    UpdateDisplay = function(self, mouseWorldPos)
        if self.onMap then
            local eCost, tCost = 0., 0.
            -- add up our teleport energy costs and find the max time
            for _, unit in GetSelectedUnits() do
                local eCache, tCache = import('/lua/shared/teleport.lua').TeleportCostFunction(unit, mouseWorldPos)
                eCost = eCost + eCache
                if tCache > tCost then
                    tCost = tCache
                end
            end
            -- update our text
            self.eText:SetText(string.format('%.0f', eCost))
            self.tText:SetText(string.format('%.2f', tCost))
        else
            if self.changedOnMap then
                self.eText:SetText('--')
                self.tText:SetText('--')
                self.changedOnMap = false
            end
        end
    end,

}
