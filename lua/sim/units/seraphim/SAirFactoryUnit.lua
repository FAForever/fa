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

local AirFactoryUnit = import('/lua/defaultunits.lua').AirFactoryUnit
local SFactoryUnit = import('/lua/seraphimunits.lua').SFactoryUnit


-- AIR STRUCTURES
---@class SAirFactoryUnit : AirFactoryUnit
SAirFactoryUnit = ClassUnit(AirFactoryUnit) {
    StartBuildFx = SFactoryUnit.StartBuildFx,
    StartBuildFxUnpause = SFactoryUnit.StartBuildFxUnpause,
    OnPaused = SFactoryUnit.OnPaused,
    OnUnpaused = SFactoryUnit.OnUnpaused,

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        if unitBeingBuilt and not unitBeingBuilt.Dead and EntityCategoryContains(categories.AIR, unitBeingBuilt) then
            unitBeingBuilt:DetachFrom(true)
            local bp = self:GetBlueprint()
            self:DetachAll(bp.Display.BuildAttachBone or 0)
        end
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end
    end,

    CreateRollOffEffects = function(self)
    end,

    DestroyRollOffEffects = function(self)
    end,

    RollOffUnit = function(self)
        if EntityCategoryContains(categories.AIR, self.UnitBeingBuilt) then
            local spin, x, y, z = self:CalculateRollOffPoint()
            local units = {self.UnitBeingBuilt}
            self.MoveCommand = IssueMove(units, Vector(x, y, z))
        end
    end,

    RolloffBody = function(self)
        self:SetBusy(true)
        local unitBuilding = self.UnitBeingBuilt

        -- If the unit being built isn't an engineer use normal rolloff
        if not EntityCategoryContains(categories.LAND, unitBuilding) then
            AirFactoryUnit.RolloffBody(self)
        else

            if not IsDestroyed(unitBuilding) then
                unitBuilding:DetachFrom(true)
                self:DetachAll(self.Blueprint.Display.BuildAttachBone or 0)

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                unitBuilding:HideBone(0, true)
            end

            WaitTicks(4)

            if not IsDestroyed(unitBuilding) then
                CreateLightParticle(unitBuilding, -1, unitBuilding.Army, 4, 12, 'glow_02', 'ramp_blue_22')
                unitBuilding:ShowBone(0, true)

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_04_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_05_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_06_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_08_emit.bp'):OffsetEmitter(0, -1, 0)
            end

            WaitTicks(8)

            self:SetBusy(false)
            ChangeState(self, self.IdleState)
        end
    end,

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
        AirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    UpgradingState = State(AirFactoryUnit.UpgradingState) {
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
            AirFactoryUnit.UpgradingState.OnStopBuild(self, unitBuilding)
        end,

        OnFailedToBuild = function(self)
           AirFactoryUnit.UpgradingState.OnFailedToBuild(self)
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