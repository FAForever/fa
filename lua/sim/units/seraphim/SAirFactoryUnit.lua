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
local AirFactoryUnitOnStartBuild = AirFactoryUnit.OnStartBuild
local AirFactoryUnitUpgradingStateOnStopBuild = AirFactoryUnit.UpgradingState.OnStopBuild
local AirFactoryUnitUpgradingStateOnFailedToBuild = AirFactoryUnit.UpgradingState.OnFailedToBuild

local SFactoryUnit = import('/lua/seraphimunits.lua').SFactoryUnit

---@class SAirFactoryUnit : AirFactoryUnit
SAirFactoryUnit = ClassUnit(AirFactoryUnit) {
    SyncRotators = SFactoryUnit.SyncRotators,
    StartRotators = SFactoryUnit.StartRotators,
    RestartRotators = SFactoryUnit.RestartRotators,
    CreateBuildEffects = SFactoryUnit.CreateBuildEffects,

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
            local units = { self.UnitBeingBuilt }
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

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                unitBuilding:HideBone(0, true)
            end

            WaitTicks(4)

            if not IsDestroyed(unitBuilding) then
                CreateLightParticle(unitBuilding, -1, unitBuilding.Army, 4, 12, 'glow_02', 'ramp_blue_22')
                unitBuilding:ShowBone(0, true)

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_04_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_05_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_06_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army,
                    '/effects/emitters/seraphim_rifter_mobileartillery_hit_08_emit.bp'):OffsetEmitter(0, -1, 0)
            end

            WaitTicks(8)

            self:SetBusy(false)
            ChangeState(self, self.IdleState)
        end
    end,

    ---@param self SAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        AirFactoryUnitOnStartBuild(self, unitBeingBuilt, order)

        if order == 'Upgrade' then
            self:SyncRotators(unitBeingBuilt)
        end
    end,

    UpgradingState = State(AirFactoryUnit.UpgradingState) {
        ---@param self SAirFactoryUnit
        ---@param unitBuilding SFactoryUnit
        OnStopBuild = function(self, unitBuilding)
            AirFactoryUnitUpgradingStateOnStopBuild(self, unitBuilding)

            if unitBuilding:GetFractionComplete() == 1 then
                self:StartRotators(unitBuilding)
            end
        end,

        ---@param self SAirFactoryUnit
        OnFailedToBuild = function(self)
            AirFactoryUnitUpgradingStateOnFailedToBuild(self)
            self:RestartRotators()
        end,
    },
}
