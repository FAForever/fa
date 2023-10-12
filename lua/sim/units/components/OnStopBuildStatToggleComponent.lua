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
                self:UpdateStat(stat, toggleData.default or 0)
            end
        end
    end,

    ---@param self Unit | OnStopBuildStatToggleComponent
    ---@param unit Unit
    OnStopBuild = function(self, unit)
        if self.Blueprint.General.StatToggles then
            if unit.Blueprint.General.OnStopBeingBuiltStatToggles then
                for stat, toggleData in unit.Blueprint.General.OnStopBeingBuiltStatToggles do
                    LOG(stat)
                    LOG(repr(toggleData))
                    if toggleData.scriptBit then
                        -- apply the script bit with our stat value
                        unit:SetScriptBit(toggleData.scriptBit, (self:GetStat(stat, 0).Value == 1 and true) or false)
                    end
                end
            end
        end
    end,
}