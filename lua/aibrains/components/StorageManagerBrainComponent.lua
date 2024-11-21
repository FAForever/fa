--******************************************************************************************************
--** Copyright (c) 2024  Willem 'Jip' Wijnia
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

local Debug = false

--- Enable debugging functionality for this module.
function EnableDebugging()
    Debug = true
end

--- Disable debugging functionality for this module.
function DisableDebugging()
    Debug = false
end

local WeakValueTable = { __mode = 'v' }

---@alias AIBrainMassStorageState 'EconLowMassStore' | 'EconMidMassStore' | 'EconFullMassStore'
---@alias AIBrainEnergyStorageState 'EconLowEnergyStore' | 'EconMidEnergyStore' | 'EconFullEnergyStore'

---@class StorageManagerBrainComponent
---@field MassStorageState AIBrainMassStorageState
---@field EnergyStorageState AIBrainEnergyStorageState
---@field UnitMassStorage table<EntityId, Unit>
---@field UnitEnergyStorage table<EntityId, Unit>
StorageManagerBrainComponent = ClassSimple {

    ---@param self StorageManagerBrainComponent | AIBrain
    CreateBrainShared = function(self)
        self.MassStorageState = 'EconFullMassStore'
        self.EnergyStorageState = 'EconFullEnergyStore'
        self.UnitMassStorage = setmetatable({}, WeakValueTable)
        self.UnitEnergyStorage = setmetatable({}, WeakValueTable)

        self.Trash:Add(ForkThread(self.EconomyStorageThread, self))
    end,

    --- Register a unit to be able to blink depending on mass state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    RegisterUnitMassStorage = function(self, unit)
        if not unit.OnMassStorageStateChange then
            -- WARN("")

            return
        end

        self.UnitMassStorage[unit.EntityId] = unit
    end,

    --- Register a unit to be able to blink depending on energy state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    UnregisterUnitMassStorage = function(self, unit)
        self.UnitMassStorage[unit.EntityId] = nil
    end,

    --- Register a unit to be able to blink depending on energy state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    RegisterUnitEnergyStorage = function(self, unit)
        if not unit.OnEnergyStorageStateChange then
            -- WARN("")

            return
        end

        self.UnitEnergyStorage[unit.EntityId] = unit
    end,

    --- Register a unit to be able to blink depending on energy state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    UnregisterUnitEnergyStorage = function(self, unit)
        self.UnitEnergyStorage[unit.EntityId] = nil
    end,

    --- Transforms the stored ratio into a discrete state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@return AIBrainMassStorageState
    GetMassStorageState = function(self)
        local ratio = self:GetEconomyStoredRatio('MASS')

        ---@type AIBrainMassStorageState
        local state = 'EconFullMassStore'
        if ratio < 0.10 then
            state = 'EconLowMassStore'
        elseif ratio < 0.9 then
            state = 'EconMidMassStore'
        end

        return state
    end,

    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param state AIBrainMassStorageState
    ApplyMassStorageState = function(self, state)
        local state = self:GetMassStorageState()
        if state ~= self.MassStorageState then
            if Debug then
                LOG(string.format('Mass storage state changed from %s to %s', tostring(self.MassStorageState),
                    tostring(state)))
            end

            self.MassStorageState = state

            for _, unit in self.UnitMassStorage do
                if not IsDestroyed(unit) then
                    local onMassStorageStateChange = unit.OnMassStorageStateChange
                    if onMassStorageStateChange then
                        local ok, msg = pcall(onMassStorageStateChange, unit, state)
                        if not ok then
                            -- WARN("")
                        end
                    end
                end
            end
        end
    end,

    --- Transforms the stored ratio into a discrete state
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@return AIBrainEnergyStorageState
    GetEnergyStorageState = function(self)
        local ratio = self:GetEconomyStoredRatio('ENERGY')

        ---@type AIBrainEnergyStorageState
        local state = 'EconFullEnergyStore'
        if ratio < 0.10 then
            state = 'EconLowEnergyStore'
        elseif ratio < 0.9 then
            state = 'EconMidEnergyStore'
        end

        return state
    end,

    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param state AIBrainEnergyStorageState
    ApplyEnergyStorageState = function(self, state)
        if state ~= self.EnergyStorageState then
            if Debug then
                LOG(string.format('Energy storage state changed from %s to %s', tostring(self.EnergyStorageState),
                    tostring(state)))
            end

            self.EnergyStorageState = state

            for _, unit in self.UnitEnergyStorage do
                if not IsDestroyed(unit) then
                    local onEnergyStorageStateChange = unit.OnEnergyStorageStateChange
                    if onEnergyStorageStateChange then
                        local ok, msg = pcall(onEnergyStorageStateChange, unit, state)
                        if not ok then
                            -- WARN("")
                        end
                    end
                end
            end
        end
    end,

    ---@param self StorageManagerBrainComponent | AIBrain
    EconomyStorageThread = function(self)
        local WaitTicks = WaitTicks

        while true do
            local massStorageState = self:GetMassStorageState()
            self:ApplyMassStorageState(massStorageState)

            local energyStorageState = self:GetEnergyStorageState()
            self:ApplyEnergyStorageState(energyStorageState)

            WaitTicks(6)
        end
    end,

    ---------------------------------------------------------------------------
    --#region Backwards compatibility

    --- Use `StorageManagerBrainComponent:RegisterUnitMassStorage` instead
    ---@deprecated
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    ESRegisterUnitMassStorage = function(self, unit)
        self:RegisterUnitMassStorage(unit)
    end,

    --- Use `StorageManagerBrainComponent:RegisterUnitMassStorage` instead
    ---@deprecated
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    ESRegisterUnitEnergyStorage = function(self, unit)
        self:RegisterUnitEnergyStorage(unit)
    end,

    --- Use `StorageManagerBrainComponent:UnregisterUnitMassStorage` and/or `StorageManagerBrainComponent:UnregisterUnitEnergyStorage` instead
    ---@deprecated
    ---@param self StorageManagerBrainComponent | AIBrain
    ---@param unit StructureUnit
    ESUnregisterUnit = function(self, unit)
        self:UnregisterUnitMassStorage(unit)
        self:UnregisterUnitEnergyStorage(unit)
    end

    --#endregion

}
