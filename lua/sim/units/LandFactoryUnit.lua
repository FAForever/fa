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

---Because the rally point orders are applied after 1 tick, we need
---to wait 1 tick before clearing them and adding our own
---@param unit Unit
---@param rollOffPoint Vector
---@param assistTarget Unit
local AssistOverrideThread = function(unit, rollOffPoint, assistTarget)
    WaitTicks(1)
    if unit.Dead or assistTarget.Dead then
        return
    end
    IssueToUnitClearCommands(unit)
    IssueToUnitMove(unit, rollOffPoint)
    IssueGuard({unit}, assistTarget)
end

---@class LandFactoryUnit : FactoryUnit
LandFactoryUnit = ClassUnit(FactoryUnit) {

        ---@param self LandFactoryUnit
        ---@param unitBeingBuilt Unit
        ---@param order string
        OnStopBuild = function(self, unitBeingBuilt, order)
            local guardTarget = self:GetGuardedUnit()
            if guardTarget then
                if EntityCategoryContains(categories.FACTORY * categories.AIR, guardTarget) then
                    if not EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
                        unitBeingBuilt.autoLoadTarget = guardTarget
                    end
                end
            end
            FactoryUnit.OnStopBuild(self, unitBeingBuilt, order)
        end,

        ---We need to override our roll off function to point directly to
        ---the location of the factory we are assisting, not its rally point
        ---@param self LandFactoryUnit
        RollOffUnit = function(self)

            local unitBeingBuilt = self.UnitBeingBuilt
            if not unitBeingBuilt then
                return
            end

            local autoLoadTarget = unitBeingBuilt.autoLoadTarget
            if autoLoadTarget then
                local rollOffPoint = self.RollOffPoint
                unitBeingBuilt.autoLoadTarget = nil
                _, rollOffPoint.x, rollOffPoint.y, rollOffPoint.z = self:CalculateRollOffPoint(autoLoadTarget:GetPosition())
                ForkThread(AssistOverrideThread, unitBeingBuilt, rollOffPoint, autoLoadTarget)
            else
                FactoryUnit.RollOffUnit(self)
            end
        end,
}
