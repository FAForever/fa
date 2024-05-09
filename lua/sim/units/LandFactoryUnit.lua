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

local FactoryUnit = import("/lua/sim/units/factoryunit.lua").FactoryUnit

local AssistOverrideThread = function(unit, rollOffPoint, assistTarget)
    WaitTicks(1)
    if unit:IsDead() then
        return
    end
    IssueToUnitClearCommands(unit)
    IssueToUnitMove(unit, rollOffPoint)
    IssueGuard({unit}, assistTarget)
end

---@class LandFactoryUnit : FactoryUnit
LandFactoryUnit = ClassUnit(FactoryUnit) {

        OnStopBuild = function(self, unitBeingBuilt, order)
            local guardTarget = self:GetGuardedUnit()
            if guardTarget then
                LOG('We are guarding something!')
                if EntityCategoryContains(categories.FACTORY * categories.AIR, guardTarget) then
                    LOG('We are guarding an air factory!')
                    if not EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
                        unitBeingBuilt.autoLoadTarget = guardTarget
                    end
                end
            end
            FactoryUnit.OnStopBuild(self, unitBeingBuilt, order)
        end,

        RollOffUnit = function(self)
            LOG('Rolling off unit')

            local unitBeingBuilt = self.UnitBeingBuilt
            local autoLoadTarget = unitBeingBuilt.autoLoadTarget
            if autoLoadTarget then
                LOG('We have an autoLoad target')
                local rollOffPoint, spin = self.RollOffPoint, 0
                unitBeingBuilt.autoLoadTarget = nil
                spin, rollOffPoint.x, rollOffPoint.y, rollOffPoint.z = self:CalculateRollOffPoint(autoLoadTarget:GetPosition())
                --unitBeingBuilt:SetRotation(spin)
                ForkThread(AssistOverrideThread, unitBeingBuilt, rollOffPoint, autoLoadTarget)
            else
                FactoryUnit.RollOffUnit(self)
            end
        end,
}
