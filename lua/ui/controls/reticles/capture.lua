--******************************************************************************************************
--** Copyright (c) 2024  lL1l1
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
local Layouter = LayoutHelpers.ReusedLayoutFor

local Reticle = import('/lua/ui/controls/reticle.lua').Reticle

local GetBlueprintCaptureCost = import('/lua/shared/capturecost.lua').GetBlueprintCaptureCost

local ObserveSelection = import("/lua/ui/game/gamemain.lua").ObserveSelection
 
-- Local upvalues for performance
local GetRolloverInfo = GetRolloverInfo
local GetSelectedUnits = GetSelectedUnits
local MathFloor = math.floor
local EntityCategoryFilterDown = EntityCategoryFilterDown
local tableEmpty = table.empty

---@param units UserUnit[]
---@return number totalBuildRate
local getBuildRateOfCapturerUnits = function(units)
    local capturerUnits = EntityCategoryFilterDown(categories.CAPTURE, units)
    if not tableEmpty(capturerUnits) then
        local totalBuildRate = 0
        for _, unit in capturerUnits do
            totalBuildRate = totalBuildRate + unit:GetBuildRate()
        end
        return totalBuildRate
    end
    return 0
end

---@type number
local selectionBuildRate
---@param cachedSelection { oldSelection: UserUnit[], newSelection: UserUnit[], added: UserUnit[], removed: UserUnit[] }
local OnSelectionChanged = function(cachedSelection)
    selectionBuildRate = selectionBuildRate + getBuildRateOfCapturerUnits(cachedSelection.added) - getBuildRateOfCapturerUnits(cachedSelection.removed)
end


--- Reticle that displays the capture cost and rate of hovered-over units based on the current selection
---@class CaptureReticle : UIReticle
---@field BuildTimeIcon Bitmap
---@field EnergyCostIcon Bitmap
---@field eText Text
---@field tText Text
---@field focusArmy Army
CaptureReticle = ClassUI(Reticle) {

    ---@param self CaptureReticle
    ---@param parent Control
    ---@param data any
    __init = function(self, parent, data)
        Reticle.__init(self, parent, data)

        self.focusArmy = GetFocusArmy()

        selectionBuildRate = getBuildRateOfCapturerUnits(GetSelectedUnits())
        ObserveSelection:AddObserver(OnSelectionChanged, "CaptureReticleSelectionObserver")
    end,

    ---@param self CaptureReticle
    OnDestroy = function(self)
        ObserveSelection:AddObserver(nil, "CaptureReticleSelectionObserver")
    end,

    ---@param self CaptureReticle
    SetLayout = function(self)
        self.EnergyCostIcon = Layouter(Bitmap(self)):Texture(UIUtil.UIFile('/game/unit_view_icons/energy.dds')):Width(19):Height(19):RightOf(self, 4):End()
        self.BuildTimeIcon = Layouter(Bitmap(self)):Texture(UIUtil.UIFile('/game/unit_view_icons/time.dds')):Width(19):Height(19):Below(self.EnergyCostIcon, 4):End()

        -- eText color is from economy_mini.lua, same color as the energy stored/storage text
        self.eText = Layouter(UIUtil.CreateText(self, "eCost", 16, UIUtil.bodyFont, true)):RightOf(self.EnergyCostIcon, 4):Color('fff7c70f'):End()
        self.tText = Layouter(UIUtil.CreateText(self, "tCost", 16, UIUtil.bodyFont, true)):RightOf(self.BuildTimeIcon, 4):End()
    end,

    ---@param self CaptureReticle
    UpdateDisplay = function(self)
        local rolloverInfo = GetRolloverInfo()
        local isNotAlly, targetBp
        local isCapturable = true
        if rolloverInfo then
            isNotAlly = not IsAlly(self.focusArmy, rolloverInfo.armyIndex + 1)
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
        if isNotAlly and isCapturable then
            if self:IsHidden() then
                self:SetHidden(false)
            end

            local time, energy = GetBlueprintCaptureCost(targetBp, selectionBuildRate)

            local rate
            if time == 0 then
                -- pretend to capture in 1 tick
                rate = energy * 10
            else
                rate = energy/time
            end

            self.eText:SetText(string.format('%.0f (%.0f)', energy, -rate))
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
