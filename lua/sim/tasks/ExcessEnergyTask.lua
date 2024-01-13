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

---@class ExcessEnergyTaskData
---@field Ratio number

--- A task that enables/disables energy maintenance depending on the status quo of the energy of a player
---@class ExcessEnergyTask : ScriptTask
---@field CommandData ExcessEnergyTaskData
---@field InvalidTask? boolean
ExcessEnergyTask = Class(ScriptTask) {

    ---@param self ExcessEnergyTask
    ---@param commandData ExcessEnergyTaskData
    OnCreate = function(self, commandData)
        ScriptTaskOnCreate(self, commandData)

        -- check whether the task is valid for this unit
        local unit = ScriptTaskGetUnit(self)
        local consumesEnergy = unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy
        local isExtractor = EntityCategoryContains(categories.MASSEXTRACTION, unit)
        if (not consumesEnergy) or isExtractor then
            self.InvalidTask = true
        end

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

            -- give a random wait offset
            ChangeState(self, self.Applying)
            return ScriptTaskStatus.Wait + Random(40, 45)
        end,
    },

    Applying = State {

        --- This state is where all the magic happens. Note the randomness in the waiting procedure. It
        --- is applied randomly because the return value of `brain:GetEconomyTrend` only updates each tick.

        ---@param self ExcessEnergyTask
        ---@return ScriptedTaskStatus
        TaskTick = function(self)
            local unit = ScriptTaskGetUnit(self)
            local unitSetScriptBit = unit.SetScriptBit

            -- We use as a flag to see if the unit is consuming resources and therefore is enabled.
            local unitEnergyConsumption = unit:GetConsumptionPerSecondEnergy()
            local brainEnergyIncome = 10 * unit.Brain:GetEconomyTrend('ENERGY')

            if unitEnergyConsumption > 0 then
                -- check if we should stop maintenance
                if brainEnergyIncome < 0 then
                    DrawCircle(unit:GetPosition(), 2, 'ff0000')
                    unitSetScriptBit(unit, 'RULEUTC_ProductionToggle', true)
                    unitSetScriptBit(unit, 'RULEUTC_ShieldToggle', false) -- yes, this is the elephant in the room
                    unitSetScriptBit(unit, 'RULEUTC_JammingToggle', true)
                    unitSetScriptBit(unit, 'RULEUTC_IntelToggle', true)
                    unitSetScriptBit(unit, 'RULEUTC_StealthToggle', true)
                    unitSetScriptBit(unit, 'RULEUTC_CloakToggle', true)
                end
            else
                -- check if we should start maintenance

                -- we need to use the blueprint value because the real value (that may be adjusted
                -- due to adjacency) is not known when the unit energy consumption is disabled
                if unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy < brainEnergyIncome then
                    DrawCircle(unit:GetPosition(), 2, '00ff00')
                    unitSetScriptBit(unit, 'RULEUTC_ProductionToggle', false)
                    unitSetScriptBit(unit, 'RULEUTC_ShieldToggle', true) -- yes, this is the elephant in the room
                    unitSetScriptBit(unit, 'RULEUTC_JammingToggle', false)
                    unitSetScriptBit(unit, 'RULEUTC_IntelToggle', false)
                    unitSetScriptBit(unit, 'RULEUTC_StealthToggle', false)
                    unitSetScriptBit(unit, 'RULEUTC_CloakToggle', false)
                end
            end

            -- give a random wait offset.
            return ScriptTaskStatus.Wait + Random(40, 60)
        end,
    },
}
