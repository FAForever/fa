--**********************************************************************************
--** Copyright (c) 2023 FAForever
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
--**********************************************************************************

local LandFactoryUnit = import('/lua/defaultunits.lua').LandFactoryUnit
local LandFactoryUnitOnStartBuild = LandFactoryUnit.OnStartBuild
local LandFactoryUnitUpgradingStateOnStopBuild = LandFactoryUnit.UpgradingState.OnStopBuild
local LandFactoryUnitUpgradingStateOnFailedToBuild = LandFactoryUnit.UpgradingState.OnFailedToBuild

local SFactoryUnit = import('/lua/seraphimunits.lua').SFactoryUnit

-- LAND FACTORY STRUCTURES
---@class SLandFactoryUnit : LandFactoryUnit
SLandFactoryUnit = ClassUnit(LandFactoryUnit) {
    SyncRotators = SFactoryUnit.SyncRotators,
    StartRotators = SFactoryUnit.StartRotators,
    RestartRotators = SFactoryUnit.RestartRotators,
    CreateBuildEffects = SFactoryUnit.CreateBuildEffects,

    ---@param self SLandFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        LandFactoryUnitOnStartBuild(self, unitBeingBuilt, order)

        if order == 'Upgrade' then
            self:SyncRotators(unitBeingBuilt)
        end
    end,

    UpgradingState = State(LandFactoryUnit.UpgradingState) {
        ---@param self SLandFactoryUnit
        ---@param unitBuilding SFactoryUnit
        OnStopBuild = function(self, unitBuilding)
            LandFactoryUnitUpgradingStateOnStopBuild(self, unitBuilding)

            if unitBuilding:GetFractionComplete() == 1 then
                self:StartRotators(unitBuilding)
            end
        end,

        ---@param self SLandFactoryUnit
        OnFailedToBuild = function(self)
            LandFactoryUnitUpgradingStateOnFailedToBuild(self)
            self:RestartRotators()
        end,
    },
}
