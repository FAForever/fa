--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

---@class EnergyManagerBrainComponent
---@field EnergyDepleted boolean
---@field EnergyDependingUnits table<EntityId, Unit>
---@field EnergyExcessConsumed number
---@field EnergyExcessRequired number
---@field EnergyExcessConverted number
---@field EnergyExcessUnitsEnabled table<EntityId, Unit>
---@field EnergyExcessUnitsDisabled table<EntityId, Unit>
EnergyManagerBrainComponent = ClassSimple {
    CreateBrainShared = function(self)
        -- make sure there is always some storage
        self:GiveStorage('Energy', 100)

        -- make sure the army stats exist
        self:SetArmyStat('Economy_Ratio_Mass', 1.0)
        self:SetArmyStat('Economy_Ratio_Energy', 1.0)

        -- add initial trigger and assume we're not depleted
        self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyDepleted', 'LessThanOrEqual', 0.0)
        self.EnergyDepleted = false
        self.EnergyDependingUnits = setmetatable({}, { __mode = 'v' })

        --- Units that we toggle on / off depending on whether we have excess energy
        self.EnergyExcessConsumed = 0
        self.EnergyExcessRequired = 0
        self.EnergyExcessConverted = 0
        self.EnergyExcessUnitsEnabled = setmetatable({}, { __mode = 'v' })
        self.EnergyExcessUnitsDisabled = setmetatable({}, { __mode = 'v' })
    end,

    --- Adds an entity to the list of entities that receive callbacks when the energy storage is depleted or viable, expects the functions OnEnergyDepleted and OnEnergyViable on the unit
    ---@param self AIBrain
    ---@param entity Unit
    AddEnergyDependingEntity = function(self, entity)
        self.EnergyDependingUnits[entity.EntityId] = entity

        -- guarantee callback when entity is depleted
        if self.EnergyDepleted then
            entity:OnEnergyDepleted()
        end
    end,

    --- Adds a unit that is enabled / disabled depending on how much energy storage we have. The unit starts enabled
    ---@param self AIBrain The brain itself
    ---@param unit MassFabricationUnit The unit to keep track of
    AddEnabledEnergyExcessUnit = function(self, unit)
        self.EnergyExcessUnitsEnabled[unit.EntityId] = unit
        self.EnergyExcessUnitsDisabled[unit.EntityId] = nil

        local ecobp = unit.Blueprint.Economy
        self.EnergyExcessConsumed = self.EnergyExcessConsumed + ecobp.MaintenanceConsumptionPerSecondEnergy
        self.EnergyExcessConverted = self.EnergyExcessConverted + ecobp.ProductionPerSecondMass
    end,

    --- Adds a unit that is enabled / disabled depending on how much energy storage we have. The unit starts disabled
    ---@param self AIBrain
    ---@param unit MassFabricationUnit The unit to keep track of
    AddDisabledEnergyExcessUnit = function(self, unit)
        self.EnergyExcessUnitsEnabled[unit.EntityId] = nil
        self.EnergyExcessUnitsDisabled[unit.EntityId] = unit
        self.EnergyExcessRequired = self.EnergyExcessRequired +
            unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy
    end,

    --- Removes a unit that is enabled / disabled depending on how much energy storage we have
    ---@param self AIBrain
    ---@param unit MassFabricationUnit The unit to forget about
    RemoveEnergyExcessUnit = function(self, unit)
        local ecobp = unit.Blueprint.Economy
        if self.EnergyExcessUnitsEnabled[unit.EntityId] then
            self.EnergyExcessConsumed = self.EnergyExcessConsumed - ecobp.MaintenanceConsumptionPerSecondEnergy
            self.EnergyExcessConverted = self.EnergyExcessConverted - ecobp.ProductionPerSecondMass
            self.EnergyExcessUnitsEnabled[unit.EntityId] = nil
        elseif self.EnergyExcessUnitsDisabled[unit.EntityId] then
            self.EnergyExcessRequired = self.EnergyExcessRequired - ecobp.MaintenanceConsumptionPerSecondEnergy
            self.EnergyExcessUnitsDisabled[unit.EntityId] = nil
        end
    end,

    --- A continious thread that across the life span of the brain. Is the heart and sole of the enabling and disabling of units that are designed to eliminate excess energy.
    ---@param self AIBrain
    ToggleEnergyExcessUnitsThread = function(self)

        -- allow for protected calls without closures
        ---@param unitToProcess MassFabricationUnit
        local function ProtectedOnExcessEnergy(unitToProcess)
            unitToProcess:OnExcessEnergy()
        end

        ---@param unitToProcess MassFabricationUnit
        local function ProtectedOnNoExcessEnergy(unitToProcess)
            unitToProcess:OnNoExcessEnergy()
        end

        local fabricatorParameters = import("/lua/shared/fabricatorbehaviorparams.lua")
        local disableRatio = fabricatorParameters.DisableRatio
        local disableStorage = fabricatorParameters.DisableStorage

        local enableRatio = fabricatorParameters.EnableRatio
        local enableTrend = fabricatorParameters.EnableTrend
        local enableStorage = fabricatorParameters.EnableStorage

        -- localize scope for better performance
        local pcall = pcall
        local TableSize = table.getsize
        local CoroutineYield = coroutine.yield

        local ok, msg


        -- Instead of creating a new sync table each tick, we'll reuse two tables as a double
        -- buffer: one table represents the data from the current tick, the other the data last
        -- synced. We only send the data when one field in the current tick differs from the last
        -- data synced, and then swap the two tables when that happens.
        local syncTable = {
            on = 0,
            off = 0,
            totalEnergyConsumed = 0,
            totalEnergyRequired = 0,
            totalMassProduced = 0,
        }
        local lastSyncTable = {
            on = 0,
            off = 0,
            totalEnergyConsumed = 0,
            totalEnergyRequired = 0,
            totalMassProduced = 0,
        }

        local EnergyExcessUnitsDisabled = self.EnergyExcessUnitsDisabled
        local EnergyExcessUnitsEnabled = self.EnergyExcessUnitsEnabled

        while true do

            local energyStoredRatio = self:GetEconomyStoredRatio('ENERGY')
            local energyStored = self:GetEconomyStored('ENERGY')
            local energyTrend = 10 * self:GetEconomyTrend('ENERGY')

            -- low on storage, start disabling them to fill our storages asap
            if energyStoredRatio < disableRatio and energyStored < disableStorage then

                -- while we have units to disable
                for id, unit in EnergyExcessUnitsEnabled do
                    if not unit:BeenDestroyed() then

                        local ecobp = unit.Blueprint.Economy
                        self.EnergyExcessConsumed = self.EnergyExcessConsumed -
                            ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessRequired = self.EnergyExcessRequired +
                            ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessConverted = self.EnergyExcessConverted - ecobp.ProductionPerSecondMass

                        -- update internal state
                        EnergyExcessUnitsDisabled[id] = unit
                        EnergyExcessUnitsEnabled[id] = nil

                        -- try to disable unit
                        ok, msg = pcall(unit.OnNoExcessEnergy, unit)

                        -- allow for debugging
                        if not ok then
                            WARN(string.format("ToggleEnergyExcessUnitsThread: %s", tostring(msg)))
                        end

                        break
                    end
                end

                -- high on storage and sufficient energy income, enable units
            elseif (energyStoredRatio >= enableRatio and energyTrend > enableTrend) or energyStored > enableStorage then

                -- while we have units to retrieve
                for id, unit in EnergyExcessUnitsDisabled do
                    if not unit:BeenDestroyed() then
                        local ecobp = unit.Blueprint.Economy
                        self.EnergyExcessConsumed = self.EnergyExcessConsumed +
                            ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessRequired = self.EnergyExcessRequired -
                            ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessConverted = self.EnergyExcessConverted + ecobp.ProductionPerSecondMass

                        -- update internal state
                        EnergyExcessUnitsDisabled[id] = nil
                        EnergyExcessUnitsEnabled[id] = unit

                        -- try to enable unit
                        ok, msg = pcall(unit.OnExcessEnergy, unit)

                        -- allow for debugging
                        if not ok then
                            WARN(string.format("ToggleEnergyExcessUnitsThread: %s", tostring(msg)))
                        end

                        break
                    end
                end
            end

            if self.Army == GetFocusArmy() then
                syncTable.on = TableSize(EnergyExcessUnitsEnabled)
                syncTable.off = TableSize(EnergyExcessUnitsDisabled)
                syncTable.totalEnergyConsumed = self.EnergyExcessConsumed
                syncTable.totalEnergyRequired = self.EnergyExcessRequired
                syncTable.totalMassProduced = self.EnergyExcessConverted
                -- only send new data
                if lastSyncTable.on ~= syncTable.on
                    or lastSyncTable.off ~= syncTable.off
                    or lastSyncTable.totalEnergyConsumed ~= syncTable.totalEnergyConsumed
                    or lastSyncTable.totalEnergyRequired ~= syncTable.totalEnergyRequired
                    or lastSyncTable.totalMassProduced ~= syncTable.totalMassProduced
                then
                    Sync.MassFabs = syncTable
                    -- swap the data buffers
                    syncTable, lastSyncTable = lastSyncTable, syncTable
                end
            end
            CoroutineYield(1)
        end
    end,

    OnStatsTrigger = function(self, triggerName)
        if triggerName == "EnergyDepleted" or triggerName == "EnergyViable" then
            self:OnEnergyTrigger(triggerName)
        end
    end,


    ---@param self AIBrain
    ---@param triggerName string
    OnEnergyTrigger = function(self, triggerName)
        if triggerName == "EnergyDepleted" then
            -- add trigger when we can recover units
            self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyViable', 'GreaterThanOrEqual', 0.1)
            self.EnergyDepleted = true

            -- recurse over the list of units and do callbacks accordingly
            for id, entity in self.EnergyDependingUnits do
                if not IsDestroyed(entity) then
                    entity:OnEnergyDepleted()
                end
            end
        else
            -- add trigger when we're depleted
            self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyDepleted', 'LessThanOrEqual', 0.0)
            self.EnergyDepleted = false

            -- recurse over the list of units and do callbacks accordingly
            for id, entity in self.EnergyDependingUnits do
                if not IsDestroyed(entity) then
                    entity:OnEnergyViable()
                end
            end
        end
    end,

}
