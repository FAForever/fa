--******************************************************************************************************
--** Copyright (c) 2024  IL1I1
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

local Bitmap   = import("/lua/maui/bitmap.lua").Bitmap

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Reticle = import('/lua/ui/controls/reticle.lua').Reticle

-- Local upvalues for performance
local GetRolloverInfo = GetRolloverInfo
local GetSelectedUnits = GetSelectedUnits
local MathFloor = math.floor

--- Reticle for capture cost info
---@class CaptureReticle : UIReticle
---@field BuildTimeIcon Bitmap
---@field EnergyCostIcon Bitmap
---@field eText Text
---@field tText Text
---@field selectionBuildRate number
---@field focusArmy Army
CaptureReticle = ClassUI(Reticle) {

    ---@param self CaptureReticle
    SetLayout = function(self)
        local selection = GetSelectedUnits()
        local totalBuildRate = 0
        for _, unit in selection do
            totalBuildRate = totalBuildRate + unit:GetBuildRate()
        end
        self.selectionBuildRate = totalBuildRate
        self.focusArmy = GetArmiesTable().focusArmy

        self.BuildTimeIcon = Bitmap(self)
        self.BuildTimeIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
        LayoutHelpers.SetDimensions(self.BuildTimeIcon, 19, 19)

        self.EnergyCostIcon = Bitmap(self)
        self.EnergyCostIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/energy.dds'))
        LayoutHelpers.SetDimensions(self.EnergyCostIcon, 19, 19)

        self.eText = UIUtil.CreateText(self, "eCost", 16, UIUtil.bodyFont, true)
        self.tText = UIUtil.CreateText(self, "tCost", 16, UIUtil.bodyFont, true)
        LayoutHelpers.RightOf(self.EnergyCostIcon, self, 4)
        LayoutHelpers.RightOf(self.eText, self.EnergyCostIcon, 2)
        LayoutHelpers.Below(self.BuildTimeIcon, self.EnergyCostIcon, 4)
        LayoutHelpers.RightOf(self.tText, self.BuildTimeIcon, 2)

        self.eText:SetColor('fff7c70f') -- from economy_mini.lua, same color as the energy stored/storage text
    end,

    ---@param self CaptureReticle
    UpdateDisplay = function(self)
        local rolloverInfo = GetRolloverInfo()
        local isEnemy, targetBp
        local isCapturable = true
        if rolloverInfo then
            -- armyIndex is 0-indexed, but IsAlly requires 1-indexed armies.
            isEnemy = not IsAlly(self.focusArmy, rolloverInfo.armyIndex + 1)
            targetBp = __blueprints[rolloverInfo.blueprintId]
            -- `Unit:IsCapturable()` is sim-side so we will use what we have in the bp.
            -- May not work with units from mods or changed by script.
            if targetBp.Display.Abilities then
                for _, ability in targetBp.Display.Abilities do
                    if ability == "<LOC ability_notcap>Not Capturable" then
                        isCapturable = false
                        break
                    end
                end
            end
        end
        if isEnemy and isCapturable then
            if self:IsHidden() then
                self:SetHidden(false)
            end

            local targetBpEconomy = targetBp.Economy
            -- Mimic Unit.lua GetCaptureCosts calculations
            local time = ((targetBpEconomy.BuildTime or 10) / self.selectionBuildRate) / 2
            local energy = targetBpEconomy.BuildCostEnergy or 100
            -- This multiplier is sim-side. It would be nice to have, but it is rarely used.
            -- time = time * (self.CaptureTimeMultiplier or 1)
            if time < 0 then
                time = 1
            end

            self.eText:SetText(string.format('%.0f (-%.0f)', energy, energy/time))
            local minutes = MathFloor(time/60)
            local seconds = time - 60 * minutes
            self.tText:SetText(string.format('%02.0f:%02.0f', minutes, seconds))
        else
            if not self:IsHidden() then
                self:Hide()
            end
        end
    end,

}
