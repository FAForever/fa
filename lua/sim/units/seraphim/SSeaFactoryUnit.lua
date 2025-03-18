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

local SeaFactoryUnit = import('/lua/defaultunits.lua').SeaFactoryUnit
local SeaFactoryUnitOnStartBuild = SeaFactoryUnit.OnStartBuild
local SeaFactoryUnitUpgradingStateOnStopBuild = SeaFactoryUnit.UpgradingState.OnStopBuild
local SeaFactoryUnitUpgradingStateOnFailedToBuild = SeaFactoryUnit.UpgradingState.OnFailedToBuild

local SFactoryUnit = import('/lua/seraphimunits.lua').SFactoryUnit

-- SEA FACTORY STRUCTURES
---@class SSeaFactoryUnit : SeaFactoryUnit
SSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {
    SyncRotators = SFactoryUnit.SyncRotators,
    StartRotators = SFactoryUnit.StartRotators,
    RestartRotators = SFactoryUnit.RestartRotators,
    CreateBuildEffects = SFactoryUnit.CreateBuildEffects,

    ---@param self SSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnitOnStartBuild(self, unitBeingBuilt, order)

        if order == 'Upgrade' then
            self:SyncRotators(unitBeingBuilt)
        end
    end,

    UpgradingState = State(SeaFactoryUnit.UpgradingState) {
        ---@param self SSeaFactoryUnit
        ---@param unitBuilding SFactoryUnit
        OnStopBuild = function(self, unitBuilding)
            SeaFactoryUnitUpgradingStateOnStopBuild(self, unitBuilding)

            if unitBuilding:GetFractionComplete() == 1 then
                self:StartRotators(unitBuilding)
            end
        end,

        ---@param self SSeaFactoryUnit
        OnFailedToBuild = function(self)
            SeaFactoryUnitUpgradingStateOnFailedToBuild(self)
            self:RestartRotators()
        end,
    },
}
