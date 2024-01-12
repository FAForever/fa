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

local ScriptTaskStatus = import("/lua/sim/scripttask.lua").TASKSTATUS
local ScriptTaskResult = import("/lua/sim/scripttask.lua").AIRESULT

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
        local unit = self:GetUnit()
        local consumesEnergy = unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy
        local isExtractor = EntityCategoryContains(categories.MASSEXTRACTION, unit)
        if (not consumesEnergy) or isExtractor then
            self.InvalidTask = true
        end
    end,

    ---@param self ExcessEnergyTask
    OnDestroy = function(self)
        ScriptTaskOnDestroy(self)
    end,

    ---@param self ExcessEnergyTask
    ---@return ScriptedTaskStatus
    TaskTick = function(self)
        if self.InvalidTask then
            self:SetAIResult(ScriptTaskResult.Ignored)
            return ScriptTaskStatus.Done
        end

        local unit = self:GetUnit()

        -- We use as a flag to see if the unit is consuming resources and therefore is enabled. 
        local unitEnergyConsumption = unit:GetConsumptionPerSecondEnergy()

        if unitEnergyConsumption > 0 then
            -- check if we should stop maintenance
            local brain = unit.Brain
            local energyIncome = 10 * brain:GetEconomyTrend('ENERGY')
            if energyIncome < 0 then
                DrawCircle(unit:GetPosition(), 2, 'ff0000')
                unit:SetScriptBit('RULEUTC_ProductionToggle', true)
                unit:SetScriptBit('RULEUTC_ShieldToggle', false) -- yes, this is the elephant in the room
                unit:SetScriptBit('RULEUTC_JammingToggle', true)
                unit:SetScriptBit('RULEUTC_IntelToggle', true)
                unit:SetScriptBit('RULEUTC_StealthToggle', true)
                unit:SetScriptBit('RULEUTC_CloakToggle', true)
            end
        else
            -- check if we should start maintenance
            local brain = unit.Brain
            local energyIncome = 10 * brain:GetEconomyTrend('ENERGY')

            -- we need to use the blueprint value because the real value (that may be adjusted due to adjacency) is not known when the unit energy consumption is disabled
            if unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy < energyIncome then
                DrawCircle(unit:GetPosition(), 2, '00ff00')
                unit:SetScriptBit('RULEUTC_ProductionToggle', false)
                unit:SetScriptBit('RULEUTC_ShieldToggle', true) -- yes, this is the elephant in the room
                unit:SetScriptBit('RULEUTC_JammingToggle', false)
                unit:SetScriptBit('RULEUTC_IntelToggle', false)
                unit:SetScriptBit('RULEUTC_StealthToggle', false)
                unit:SetScriptBit('RULEUTC_CloakToggle', false)
            end
        end

        -- give a random wait offset
        return ScriptTaskStatus.Wait + Random(40, 45)
    end,
}
