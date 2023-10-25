--******************************************************************************************************
--** Copyright (c) 2023  clyf
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

---@class OnStopBuildStatToggleComponent
OnStopBuildStatToggleComponent = ClassSimple {

    --- Initializes our default values
    ---@param self Unit | OnStopBuildStatToggleComponent
    OnCreate = function(self)
        -- Set our build toggles to their default values
        -- These will be the default values applied to units we build
        if self.Blueprint.General.StatToggles then
            for stat, toggleData in self.Blueprint.General.StatToggles do
                self:UpdateStat(stat, toggleData.defaultValue or 0)
            end
        end
    end,

    ---@param self Unit | OnStopBuildStatToggleComponent
    ---@param unit Unit
    OnStopBuild = function(self, unit)
        if self.Blueprint.General.StatToggles then
            if unit.Blueprint.General.OnStopBeingBuiltStatToggles then
                for stat, _ in unit.Blueprint.General.OnStopBeingBuiltStatToggles do
                    toggleData = self.Blueprint.General.StatToggles[stat]
                    -- Bail if we have no toggle data for this stat
                    -- shouldn't happen, but good to check
                    if not toggleData then
                        continue
                    end
                    if toggleData.scriptBitName then
                        -- apply the script bit with our stat value
                        local bitValue = (self:GetStat(stat, 0).Value == 1 and true) or false
                        unit:SetScriptBit(toggleData.scriptBitName, bitValue)
                        if not bitValue then
                            -- because script bits default to clear (0), setting them to that state on build will
                            -- not trigger the callback, so we need to do it manually
                            unit:OnScriptBitClear(toggleData.scriptBitNumber)
                        end
                    end
                end
            end
        end
    end,
}