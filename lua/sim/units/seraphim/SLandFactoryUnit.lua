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
local SFactoryUnit = import('/lua/seraphimunits.lua').SFactoryUnit

-- LAND FACTORY STRUCTURES
---@class SLandFactoryUnit : LandFactoryUnit
SLandFactoryUnit = ClassUnit(LandFactoryUnit) {
    StartBuildFx = SFactoryUnit.StartBuildFx,
    StartBuildFxUnpause = SFactoryUnit.StartBuildFxUnpause,
    OnPaused = SFactoryUnit.OnPaused,
    OnUnpaused = SFactoryUnit.OnUnpaused,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            -- Stop pods that exist in the upgraded unit
            local savedAngle
            if self.Rotator1 then
                savedAngle = self.Rotator1:GetCurrentAngle()
                self.Rotator1:SetGoal(savedAngle)
                unitBeingBuilt.Rotator1:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator1:SetGoal(savedAngle)
                -- Freeze the next rotator to 0, since that's where it will be
                unitBeingBuilt.Rotator2:SetCurrentAngle(0)
                unitBeingBuilt.Rotator2:SetGoal(0)
            end

            if self.Rotator2 then
                savedAngle = self.Rotator2:GetCurrentAngle()
                self.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator2:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator3:SetCurrentAngle(0)
                unitBeingBuilt.Rotator3:SetGoal(0)
            end
        end
        LandFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    UpgradingState = State(LandFactoryUnit.UpgradingState) {
        OnStopBuild = function(self, unitBuilding)
            if unitBuilding:GetFractionComplete() == 1 then
                -- Start halted rotators on upgraded unit
                if unitBuilding.Rotator1 then
                    unitBuilding.Rotator1:ClearGoal()
                end
                if unitBuilding.Rotator2 then
                    unitBuilding.Rotator2:ClearGoal()
                end
                if unitBuilding.Rotator3 then
                    unitBuilding.Rotator3:ClearGoal()
                end
            end
            LandFactoryUnit.UpgradingState.OnStopBuild(self, unitBuilding)
        end,

        OnFailedToBuild = function(self)
           LandFactoryUnit.UpgradingState.OnFailedToBuild(self)
           -- Failed to build, so resume rotators
           if self.Rotator1 then
               self.Rotator1:ClearGoal()
               self.Rotator1:SetSpeed(5)
           end

            if self.Rotator2 then
               self.Rotator2:ClearGoal()
               self.Rotator2:SetSpeed(5)
           end
        end,
    },
}