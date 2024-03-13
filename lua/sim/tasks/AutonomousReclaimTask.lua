--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local ScriptTask = import("/lua/sim/scripttask.lua").ScriptTask
local ScriptTaskOnCreate = ScriptTask.OnCreate
local ScriptTaskOnDestroy = ScriptTask.OnDestroy
local ScriptTaskGetUnit = ScriptTask.GetUnit
local ScriptTaskSetAIResult = ScriptTask.SetAIResult

local ScriptTaskStatus = import("/lua/sim/scripttask.lua").TASKSTATUS
local ScriptTaskResult = import("/lua/sim/scripttask.lua").AIRESULT

-- upvalue scope for performance
local Random = Random
local ChangeState = ChangeState
local EntityCategoryContains = EntityCategoryContains

--- A task that enables/disables energy maintenance depending on the status quo of the energy of a player
---@class ExcessEnergyTask : ScriptTask
---@field CommandData ExcessEnergyTaskData
---@field InvalidTask? boolean
AutonomousReclaimTask = Class(ScriptTask) {

    ---@param self ExcessEnergyTask
    ---@param commandData ExcessEnergyTaskData
    OnCreate = function(self, commandData)
        ScriptTaskOnCreate(self, commandData)

        -- check whether the task is valid
        local unit = ScriptTaskGetUnit(self)
        if not EntityCategoryContains(categories.ENGINEER, unit) then
            self.InvalidTask = true
        end


        reprsl(commandData)
        ChangeState(self, self.Initialisation)
    end,

    ---@param self ExcessEnergyTask
    OnDestroy = function(self)
        ScriptTaskOnDestroy(self)
    end,

    Initialisation = State {

        --- This state exists to introduce a delay between applying the order and the behavior kicking in action. It allows players
        --- to cancel the behavior on their first mass fabricators in case they wish to have full control.

        ---@param self ExcessEnergyTask
        ---@return ScriptedTaskStatus
        TaskTick = function(self)
            if self.InvalidTask then
                ScriptTaskSetAIResult(self, ScriptTaskResult.Ignored)
                return ScriptTaskStatus.Done
            end

            local unit = ScriptTaskGetUnit(self)
            DrawCircle(unit:GetPosition(), 2, 'ffffff')

            -- give a random wait offset
            ChangeState(self, self.Applying)
            return ScriptTaskStatus.Wait
        end,
    },

    Applying = State {

        --- This state is where all the magic happens. Note the randomness in the waiting procedure. It
        --- is applied randomly because the return value of `brain:GetEconomyTrend` only updates each tick.

        ---@param self ExcessEnergyTask
        ---@return ScriptedTaskStatus
        TaskTick = function(self)
            local unit = ScriptTaskGetUnit(self)
            local ux, _, uz = unit:GetPositionXYZ()

            local reclaimables = GetReclaimablesInRect(ux - 6, uz - 6, ux + 6, uz + 6)

            if reclaimables then

                for k, reclaimable in reclaimables do
                    
                    DrawCircle(reclaimable:GetPosition(), 1, 'ff0000')
                end

                -- table.sort(reclaimables,
                --     function(a, b)
                --         local ax, _, az = a:GetPositionXYZ()
                --         local bx, _, bz = b:GetPositionXYZ()
                --         return VDist2(ux, uz, ax, az) < VDist2(ux, uz, bx, bz)
                --     end
                -- )

                for k = 1, 10 do
                    local reclaimable = reclaimables[k]
                    if reclaimable and reclaimable.TimeReclaim and reclaimable.TimeReclaim > 0 then
                        IssueToUnitReclaim(unit, reclaimable)
                    end
                end
            end

            IssueToUnitScript(unit, { TaskName = 'AutonomousReclaimTask' })

            return ScriptTaskStatus.Done
        end,
    },
}
