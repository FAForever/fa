---------------------------------------------------------------------------------------------------
-- File     :  /lua/aibrain.lua
-- Author(s):
-- Summary  :
-- Copyright Š 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------

-- AIBrain Lua Module

local SUtils = import("/lua/ai/sorianutilities.lua")
local TransferUnitsOwnership = import("/lua/simutils.lua").TransferUnitsOwnership
local TransferUnfinishedUnitsAfterDeath = import("/lua/simutils.lua").TransferUnfinishedUnitsAfterDeath
local CalculateBrainScore = import("/lua/sim/score.lua").CalculateBrainScore
local Factions = import('/lua/factions.lua').GetFactions(true)

local CoroutineYield = coroutine.yield

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

---@class PlatoonTable
---@alias AIResult "defeat" | "draw" | "victor"
---@alias HqTech "TECH2" | "TECH3"
---@alias HqLayer "AIR" | "LAND" | "NAVY"
---@alias HqFaction "UEF" | "AEON" | "CYBRAN" | "SERAPHIM" | "NOMADS"
---@alias BrainState "Defeat" | "Draw" | "InProgress" | "Recalled" | "Victory"
---@alias BrainType "AI" | "Human"
---@alias ReconTypes 'Radar' | 'Sonar' | 'Omni' | 'LOSNow'
---@alias PlatoonType 'Air' | 'Land' | 'Sea'
---@alias AllianceStatus 'Ally' | 'Enemy' | 'Neutral'

---@class AIBrainHQComponent
---@field HQs table
local AIBrainHQComponent = ClassSimple {

    ---@param self AIBrainHQComponent | AIBrain
    CreateBrainShared = function(self)
        local layers = { "LAND", "AIR", "NAVAL" }
        local techs = { "TECH2", "TECH3" }

        self.HQs = {}
        for _, facData in Factions do
            local faction = facData.Category
            self.HQs[faction] = {}
            for _, layer in layers do
                self.HQs[faction][layer] = {}
                for _, tech in techs do
                    self.HQs[faction][layer][tech] = 0
                end
            end
        end

        -- restrict all support factories by default
        AddBuildRestriction(self:GetArmyIndex(), (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)
    end,

    --- Adds a HQ so that the engi mod knows we have it
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    AddHQ = function(self, faction, layer, tech)
        self.HQs[faction][layer][tech] = self.HQs[faction][layer][tech] + 1
    end,

    --- Removes an HQ so that the engi mod knows we lost it for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    RemoveHQ = function(self, faction, layer, tech)
        self.HQs[faction][layer][tech] = math.max(0, self.HQs[faction][layer][tech] - 1)
    end,

    --- Completely re evaluates the support factory restrictions of the engi mod
    ---@param self AIBrain
    ReEvaluateHQSupportFactoryRestrictions = function(self)
        local layers = { "AIR", "LAND", "NAVAL" }
        local factions = { "UEF", "AEON", "CYBRAN", "SERAPHIM" }

        if categories.NOMADS then
            table.insert(factions, 'NOMADS')
        end

        for _, faction in factions do
            for _, layer in layers do
                self:SetHQSupportFactoryRestrictions(faction, layer)
            end
        end
    end,

    --- Manages the support factory restrictions of the engi mod
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    SetHQSupportFactoryRestrictions = function(self, faction, layer)

        -- localize for performance
        local army = self:GetArmyIndex()

        -- the pessimists we are, restrict everything!
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        AddBuildRestriction(army,
            categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)

        -- lift t2 / t3 support factory restrictions
        if self.HQs[faction][layer]["TECH3"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)
        end

        -- lift t2 support factory restrictions
        if self.HQs[faction][layer]["TECH2"] > 0 then
            RemoveBuildRestriction(army,
                categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        end
    end,

    --- Counts all HQs of specific faction, layer and tech for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer
    ---@param tech HqTech
    ---@return number
    CountHQs = function(self, faction, layer, tech)
        return self.HQs[faction][layer][tech]
    end,

    --- Counts all HQs of faction and tech, regardless of layer
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param tech HqTech
    ---@return number
    CountHQsAllLayers = function(self, faction, tech)
        local count = self.HQs[faction]["LAND"][tech]
        count = count + self.HQs[faction]["AIR"][tech]
        count = count + self.HQs[faction]["NAVAL"][tech]
        return count
    end,
}

---@class AIBrainStatisticsComponent
---@field UnitStats table<UnitId, table<string, number>>
local AIBrainStatisticsComponent = ClassSimple {

    ---@param self AIBrainHQComponent | AIBrain
    CreateBrainShared = function(self)
        self.UnitStats = {}
    end,

    ---@param self AIBrain
    ---@param unitId UnitId
    ---@param statName string
    ---@param value number
    AddUnitStat = function(self, unitId, statName, value)
        if self.UnitStats[unitId] == nil then
            self.UnitStats[unitId] = {}
        end

        if self.UnitStats[unitId][statName] == nil then
            self.UnitStats[unitId][statName] = value
        else
            self.UnitStats[unitId][statName] = self.UnitStats[unitId][statName] + value
        end
    end,

    ---@param self AIBrain
    ---@param unitId EntityId
    ---@param statName string
    ---@param value number
    SetUnitStat = function(self, unitId, statName, value)
        if self.UnitStats[unitId] == nil then
            self.UnitStats[unitId] = {}
        end

        self.UnitStats[unitId][statName] = value
    end,

    ---@param self AIBrain
    ---@param unitId EntityId
    ---@param statName string
    ---@return number
    GetUnitStat = function(self, unitId, statName)
        if self.UnitStats[unitId] == nil or self.UnitStats[unitId][statName] == nil then
            return 0
        end

        return self.UnitStats[unitId][statName]
    end,

    ---@param self AIBrain
    GetUnitStats = function(self)
        return self.UnitStats
    end,
}

---@class AIBrainJammerComponent
---@field Jammers table<EntityId, Unit>
local AIBrainJammerComponent = ClassSimple {

    ---@param self AIBrainHQComponent | AIBrain
    CreateBrainShared = function(self)
        self.JammerResetTime = 15
        self.Jammers = {}
        setmetatable(self.Jammers, { __mode = 'v' })
        ForkThread(self.JammingToggleThread, self)
    end,

    --- Adds a unit to a list of all units with jammers
    ---@param self AIBrain
    ---@param unit Unit Jammer unit
    TrackJammer = function(self, unit)
        self.Jammers[unit.EntityId] = unit
    end,

    --- Removes a unit to a list of all units with jammers
    ---@param self AIBrain
    ---@param unit Unit Jammer unit
    UntrackJammer = function(self, unit)
        self.Jammers[unit.EntityId] = nil
    end,

    --- Creates a thread that interates over all jammer units to reset them when vision is lost on them
    ---@param self AIBrain
    JammingToggleThread = function(self)
        while true do
            for i, jammer in self.Jammers do
                if jammer.ResetJammer == 0 then
                    self:ForkThread(self.JammingFollowUpThread, jammer)
                    jammer.ResetJammer = -1
                else
                    if jammer.ResetJammer > 0 then
                        jammer.ResetJammer = jammer.ResetJammer - 1
                    end
                end
            end
            WaitSeconds(1)
        end
    end,

    --- Toggles a given unit's jammer
    ---@param self AIBrain
    ---@param unit Unit Jammer to be toggled
    JammingFollowUpThread = function(self, unit)
        unit:DisableUnitIntel('AutoToggle', 'Jammer')
        WaitSeconds(1)
        if not unit:BeenDestroyed() then
            unit:EnableUnitIntel('AutoToggle', 'Jammer')
            unit.ResetJammer = -1
        end
    end,

    ---@param self AIBrain
    ---@param blip Blip
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        if reconType == 'LOSNow' or reconType == 'Omni' then
            if not val then
                local unit = blip:GetSource()
                if unit.Blueprint.Intel.JammerBlips > 0 then
                    unit.ResetJammer = self.JammerResetTime
                end
            end
        end
    end,
}

---@class AIBrainEnergyComponent
---@field EnergyDepleted boolean
---@field EnergyDependingUnits table<EntityId, Unit>
---@field EnergyExcessConsumed number
---@field EnergyExcessRequired number
---@field EnergyExcessConverted number
---@field EnergyExcessUnitsEnabled table<EntityId, Unit>
---@field EnergyExcessUnitsDisabled table<EntityId, Unit>
local AIBrainEnergyComponent = ClassSimple {
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
    ---@param entity Unit | Shield
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
                            WARN("ToggleEnergyExcessUnitsThread: " .. repr(msg))
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
                            WARN("ToggleEnergyExcessUnitsThread: " .. repr(msg))
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

local BrainGetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
local BrainGetListOfUnits = moho.aibrain_methods.GetListOfUnits
local CategoriesDummyUnit = categories.DUMMYUNIT

---@class AIBrain: AIBrainHQComponent, AIBrainStatisticsComponent, AIBrainJammerComponent, AIBrainEnergyComponent, moho.aibrain_methods
---@field AI boolean
---@field Name string           # Army name
---@field Nickname string       # Player / AI / character name
---@field Status BrainState
---@field Human boolean
---@field Civilian boolean
---@field Trash TrashBag
---@field PingCallbackList { CallbackFunction: fun(pingData: any), PingType: string }[]
---@field BrainType 'Human' | 'AI'
AIBrain = Class(AIBrainHQComponent, AIBrainStatisticsComponent, AIBrainJammerComponent, AIBrainEnergyComponent,
    moho.aibrain_methods) {

    Status = 'InProgress',

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrain
    ---@param planName string
    OnCreateHuman = function(self, planName)
        self.BrainType = 'Human'
        self:CreateBrainShared(planName)

        self.EnergyExcessThread = ForkThread(self.ToggleEnergyExcessUnitsThread, self)
    end,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        self.BrainType = 'AI'
        self:CreateBrainShared(planName)
    end,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrain
    ---@param planName string
    CreateBrainShared = function(self, planName)
        self.Army = self:GetArmyIndex()
        self.Trash = TrashBag()
        self.TriggerList = {}

        -- local notInteresting = {
        --     GetArmyStat = true,
        --     GetBlueprintStat = true,
        --     GetEconomyStored = true,
        --     IsDefeated = true,
        --     Status = true,
        --     GetEconomyTrend = true,
        --     GetEconomyRatio = true,
        --     GetEconomyStoredRatio = true,
        -- }
        -- local meta = getmetatable(self)
        -- meta.__index = function(t, key)
        --     if not notInteresting[key] then
        --         LOG("BrainAccess: " .. tostring(key))
        --     end
        --     return meta[key]
        -- end

        -- keep track of radars
        self.Radars = {
            TECH1 = {},
            TECH2 = {},
            TECH3 = {},
            EXPERIMENTAL = {},
        }

        self.PingCallbackList = { }

        AIBrainEnergyComponent.CreateBrainShared(self)
        AIBrainHQComponent.CreateBrainShared(self)
        AIBrainStatisticsComponent.CreateBrainShared(self)
        AIBrainJammerComponent.CreateBrainShared(self)
    end,

    --- Called after `BeginSession`, at this point all props, resources and initial units exist
    ---@param self AIBrain
    OnBeginSession = function(self)
    end,

    ---@param self AIBrain
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    ---@param self AIBrain
    OnSpawnPreBuiltUnits = function(self)
        local factionIndex = self:GetFactionIndex()
        local resourceStructures = nil
        local initialUnits = nil
        local posX, posY = self:GetArmyStartPos()

        if factionIndex == 1 then
            resourceStructures = { 'UEB1103', 'UEB1103', 'UEB1103', 'UEB1103' }
            initialUnits = { 'UEB0101', 'UEB1101', 'UEB1101', 'UEB1101', 'UEB1101' }
        elseif factionIndex == 2 then
            resourceStructures = { 'UAB1103', 'UAB1103', 'UAB1103', 'UAB1103' }
            initialUnits = { 'UAB0101', 'UAB1101', 'UAB1101', 'UAB1101', 'UAB1101' }
        elseif factionIndex == 3 then
            resourceStructures = { 'URB1103', 'URB1103', 'URB1103', 'URB1103' }
            initialUnits = { 'URB0101', 'URB1101', 'URB1101', 'URB1101', 'URB1101' }
        elseif factionIndex == 4 then
            resourceStructures = { 'XSB1103', 'XSB1103', 'XSB1103', 'XSB1103' }
            initialUnits = { 'XSB0101', 'XSB1101', 'XSB1101', 'XSB1101', 'XSB1101' }
        end

        if resourceStructures then
            -- Place resource structures down
            for k, v in resourceStructures do
                local unit = self:CreateResourceBuildingNearest(v, posX, posY)
            end
        end

        if initialUnits then
            -- Place initial units down
            for k, v in initialUnits do
                local unit = self:CreateUnitNearSpot(v, posX, posY)
            end
        end

        self.PreBuilt = true
    end,

    ---@param self AIBrain
    OnUnitCapLimitReached = function(self) end,

    ---@param self AIBrain
    OnFailedUnitTransfer = function(self)
        self:PlayVOSound('OnFailedUnitTransfer')
    end,

    ---@param self AIBrain
    OnPlayNoStagingPlatformsVO = function(self)
        self:PlayVOSound('OnPlayNoStagingPlatformsVO')
    end,

    ---@param self AIBrain
    OnPlayBusyStagingPlatformsVO = function(self)
        self:PlayVOSound('OnPlayBusyStagingPlatformsVO')
    end,

    ---@param self AIBrain
    OnPlayCommanderUnderAttackVO = function(self)
        self:PlayVOSound('OnPlayCommanderUnderAttackVO')
    end,

    ---@param self AIBrain
    ---@param sound SoundHandle
    NuclearLaunchDetected = function(self, sound)
        self:PlayVOSound('NuclearLaunchDetected', sound)
    end,

    ---@param self AIBrain
    ---@param triggerSpec TriggerSpec
    SetupArmyIntelTrigger = function(self, triggerSpec)
        local intelTriggerList = self.IntelTriggerList
        if not intelTriggerList then
            intelTriggerList = {}
            self.IntelTriggerList = intelTriggerList
        end

        table.insert(intelTriggerList, triggerSpec)
    end,

    ---@param self AIBrain
    ---@param blip any the unit (could be fake) in question
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        local intelTriggerList = self.IntelTriggerList
        if intelTriggerList then
            for k, v in intelTriggerList do
                if EntityCategoryContains(v.Category, blip:GetBlueprint().BlueprintId)
                    and v.Type == reconType and (not v.Blip or v.Blip == blip:GetSource())
                    and v.Value == val and v.TargetAIBrain == blip:GetAIBrain() then
                    v.CallbackFunction(blip)
                    if v.OnceOnly then
                        intelTriggerList[k] = nil
                    end
                end
            end
        end

        AIBrainJammerComponent.OnIntelChange(self, blip, reconType, val)
    end,

    -- System for playing VOs to the Player
    VOSounds = {
        NuclearLaunchDetected = { timeout = 1, bank = nil, obs = true },
        OnTransportFull = { timeout = 1, bank = nil },
        OnFailedUnitTransfer = { timeout = 10, bank = 'Computer_Computer_CommandCap_01298' },
        OnPlayNoStagingPlatformsVO = { timeout = 5, bank = 'XGG_Computer_CV01_04756' },
        OnPlayBusyStagingPlatformsVO = { timeout = 5, bank = 'XGG_Computer_CV01_04755' },
        OnPlayCommanderUnderAttackVO = { timeout = 15, bank = 'Computer_Computer_Commanders_01314' },
    },

    ---@param self AIBrain
    ---@param string string
    ---@param sound SoundHandle
    PlayVOSound = function(self, string, sound)
        if not self.VOTable then
            self.VOTable = {}
        end

        local VO = self.VOSounds[string]
        if not VO then
            WARN('PlayVOSound: ' .. string .. " not found")
            return
        end

        if not self.VOTable[string] and VO['obs'] and GetFocusArmy() == -1 and self:GetArmyIndex() == 1 then
            -- Don't stop sound IF not repeated AND sound is flagged as 'obs' AND i'm observer AND only from PlayerIndex = 1
        elseif self.VOTable[string] or GetFocusArmy() ~= self:GetArmyIndex() then
            return
        end

        local cue, bank
        if sound then
            cue, bank = GetCueBank(sound)
        else
            cue, bank = VO['bank'], 'XGG'
        end

        if not (bank and cue) then
            WARN('PlayVOSound: No valid bank/cue for ' .. string)
            return
        end

        self.VOTable[string] = true
        import('/lua/SimSyncUtils.lua').SyncVoice({ Cue = cue, Bank = bank })

        local timeout = VO['timeout']
        ForkThread(function()
            WaitSeconds(timeout)
            self.VOTable[string] = nil
        end)
    end,

    --- Triggers based on an AiBrain
    ---@param self AIBrain
    ---@param triggerName string
    OnStatsTrigger = function(self, triggerName)
        AIBrainEnergyComponent.OnStatsTrigger(self, triggerName)

        for k, v in self.TriggerList do
            if v.Name == triggerName then
                if v.CallingObject then
                    if not v.CallingObject:BeenDestroyed() then
                        v.CallbackFunction(v.CallingObject)
                    end
                else
                    v.CallbackFunction(self)
                end
                table.remove(self.TriggerList, k)
            end
        end
    end,

    ---@param self AIBrain
    ---@param triggerName string
    RemoveEconomyTrigger = function(self, triggerName)
        for k, v in self.TriggerList do
            if v.Name == triggerName then
                table.remove(self.TriggerList, k)
            end
        end
    end,

    ---@param self AIBrain
    ---@param callback fun(unit:Unit)
    ---@param category EntityCategory
    ---@param percent number
    AddUnitBuiltPercentageCallback = function(self, callback, category, percent)
        if not callback or not category or not percent then
            error('*ERROR: Attempt to add UnitBuiltPercentageCallback but invalid data given', 2)
        end

        local unitBuiltTriggerList = self.UnitBuiltTriggerList
        if not unitBuiltTriggerList then
            unitBuiltTriggerList = {}
            self.UnitBuiltTriggerList = unitBuiltTriggerList
        end

        table.insert(unitBuiltTriggerList, {
            Callback = callback,
            Category = category,
            Percent = percent
        })
    end,

    ---@param self AIBrain
    ---@param triggerSpec TriggerSpec
    SetupBrainVeterancyTrigger = function(self, triggerSpec)
        if not triggerSpec.CallCount then
            triggerSpec.CallCount = 1
        end

        local veterancyTriggerList = self.VeterancyTriggerList
        if not veterancyTriggerList then
            veterancyTriggerList = {}
            self.VeterancyTriggerList = veterancyTriggerList
        end

        table.insert(veterancyTriggerList, triggerSpec)
    end,

    ---@param self AIBrain
    ---@param unit Unit
    ---@param level number
    OnBrainUnitVeterancyLevel = function(self, unit, level)
        local veterancyTriggerList = self.VeterancyTriggerList
        if veterancyTriggerList then
            for _, v in veterancyTriggerList do
                if v.CallCount > 0 and
                    level == v.Level and
                    EntityCategoryContains(v.Category, unit)
                then
                    v.CallCount = v.CallCount - 1
                    v.CallbackFunction(unit)
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param fn function
    ---@param ... any
    ---@return thread|nil
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    ---@param self AIBrain
    IsDefeated = function(self)
        local status = self.Status
        return status == "Defeat" or status == "Recalled" or ArmyIsOutOfGame(self.Army)
    end,

    ---@param self AIBrain
    OnTransportFull = function(self)
        if not self.loadingTransport or self.loadingTransport.full then return end

        local cue
        self.loadingTransport.transData.full = true
        if EntityCategoryContains(categories.uaa0310, self.loadingTransport) then
            -- "CZAR FULL"
            cue = 'XGG_Computer_CV01_04753'
        elseif EntityCategoryContains(categories.NAVALCARRIER, self.loadingTransport) then
            -- "Aircraft Carrier Full"
            cue = 'XGG_Computer_CV01_04751'
        else
            cue = 'Computer_TransportIsFull'
        end

        self:PlayVOSound('OnTransportFull', Sound { Bank = 'XGG', Cue = cue })
    end,

    ---@param self AIBrain
    OnDraw = function(self)
        self.Status = 'Draw'
    end,

    ---@param self AIBrain
    OnVictory = function(self)
        self.Status = 'Victory'
    end,

    ---@param self AIBrain
    OnDefeat = function(self)
        self.Status = 'Defeat'

        import("/lua/simutils.lua").UpdateUnitCap(self:GetArmyIndex())
        import("/lua/simping.lua").OnArmyDefeat(self:GetArmyIndex())

        local function KillArmy()
            local shareOption = ScenarioInfo.Options.Share

            local function KillWalls()
                -- Kill all walls while the ACU is blowing up
                local tokill = self:GetListOfUnits(categories.WALL, false)
                if tokill and not table.empty(tokill) then
                    for index, unit in tokill do
                        unit:Kill()
                    end
                end
            end

            if shareOption == 'ShareUntilDeath' then
                ForkThread(KillWalls)
            end

            WaitSeconds(10) -- Wait for commander explosion, then transfer units.
            local selfIndex = self:GetArmyIndex()
            local shareOption = ScenarioInfo.Options.Share
            local victoryOption = ScenarioInfo.Options.Victory
            local BrainCategories = { Enemies = {}, Civilians = {}, Allies = {} }

            -- Used to have units which were transferred to allies noted permanently as belonging to the new player
            local function TransferOwnershipOfBorrowedUnits(brains)
                for index, brain in brains do
                    local units = brain:GetListOfUnits(categories.ALLUNITS, false)
                    if units and not table.empty(units) then
                        for _, unit in units do
                            if unit.oldowner == selfIndex then
                                unit.oldowner = nil
                            end
                        end
                    end
                end
            end

            -- Transfer our units to other brains. Wait in between stops transfer of the same units to multiple armies.
            -- Optional Categories input (defaults to all units except wall and command)
            local function TransferUnitsToBrain(brains, categoriesToTransfer)
                if not table.empty(brains) then
                    local units
                    if shareOption == 'FullShare' then
                        local indexes = {}
                        for _, brain in brains do
                            table.insert(indexes, brain.index)
                        end
                        units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
                        TransferUnfinishedUnitsAfterDeath(units, indexes)
                    end

                    for k, brain in brains do
                        if categoriesToTransfer then
                            units = self:GetListOfUnits(categoriesToTransfer, false)
                        else
                            units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
                        end
                        if units and not table.empty(units) then
                            local givenUnitCount = table.getn(TransferUnitsOwnership(units, brain.index))

                            -- only show message when we actually gift that player some units
                            if givenUnitCount > 0 then
                                Sync.ArmyTransfer = { { from = selfIndex, to = brain.index, reason = "fullshare" } }
                            end

                            WaitSeconds(1)
                        end
                    end
                end
            end

            -- Sort the destiniation brains (armies/players) by rating (and if rating does not exist (such as with regular AI's), by score, after players with positive rating)
            -- optional category input (default of everything but walls and command)
            local function TransferUnitsToHighestBrain(brains, categoriesToTransfer)
                if not table.empty(brains) then
                    local ratings = ScenarioInfo.Options.Ratings
                    for i, brain in brains do
                        if ratings[brain.Nickname] then
                            brain.rating = ratings[brain.Nickname]
                        else
                            -- if there is no rating, create a fake negative rating based on score
                            brain.rating = -(1 / brain.score)
                        end
                    end
                    -- sort brains by rating
                    table.sort(brains, function(a, b) return a.rating > b.rating end)
                    TransferUnitsToBrain(brains, categoriesToTransfer)
                end
            end

            -- Transfer units to the player who killed me
            local function TransferUnitsToKiller()
                local KillerIndex = 0
                local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
                if units and not table.empty(units) then
                    if victoryOption == 'demoralization' then
                        KillerIndex = ArmyBrains[selfIndex].CommanderKilledBy or selfIndex
                        TransferUnitsOwnership(units, KillerIndex)
                    else
                        KillerIndex = ArmyBrains[selfIndex].LastUnitKilledBy or selfIndex
                        TransferUnitsOwnership(units, KillerIndex)
                    end
                end
                WaitSeconds(1)
            end

            -- Return units transferred during the game to me
            local function ReturnBorrowedUnits()
                local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
                local borrowed = {}
                for index, unit in units do
                    local oldowner = unit.oldowner
                    if oldowner and oldowner ~= self:GetArmyIndex() and not GetArmyBrain(oldowner):IsDefeated() then
                        if not borrowed[oldowner] then
                            borrowed[oldowner] = {}
                        end
                        table.insert(borrowed[oldowner], unit)
                    end
                end

                for owner, units in borrowed do
                    TransferUnitsOwnership(units, owner)
                end

                WaitSeconds(1)
            end

            -- Return units I gave away to my control. Mainly needed to stop EcoManager mods bypassing all this stuff with auto-give
            local function GetBackUnits(brains)
                local given = {}
                for index, brain in brains do
                    local units = brain:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
                    if units and not table.empty(units) then
                        for _, unit in units do
                            if unit.oldowner == selfIndex then -- The unit was built by me
                                table.insert(given, unit)
                                unit.oldowner = nil
                            end
                        end
                    end
                end

                TransferUnitsOwnership(given, selfIndex)
            end

            -- Sort brains out into mutually exclusive categories
            for index, brain in ArmyBrains do
                brain.index = index
                brain.score = CalculateBrainScore(brain)

                if not brain:IsDefeated() and selfIndex ~= index then
                    if ArmyIsCivilian(index) then
                        table.insert(BrainCategories.Civilians, brain)
                    elseif IsEnemy(selfIndex, brain:GetArmyIndex()) then
                        table.insert(BrainCategories.Enemies, brain)
                    else
                        table.insert(BrainCategories.Allies, brain)
                    end
                end
            end

            local KillSharedUnits = import("/lua/simutils.lua").KillSharedUnits

            -- This part determines the share condition
            if shareOption == 'ShareUntilDeath' then
                KillSharedUnits(self:GetArmyIndex()) -- Kill things I gave away
                ReturnBorrowedUnits() -- Give back things I was given by others
            elseif shareOption == 'FullShare' then
                TransferUnitsToHighestBrain(BrainCategories.Allies) -- Transfer things to allies, highest rating first
                TransferOwnershipOfBorrowedUnits(BrainCategories.Allies) -- Give stuff away permanently
            elseif shareOption == 'PartialShare' then
                KillSharedUnits(self:GetArmyIndex(), categories.ALLUNITS - categories.STRUCTURE - categories.ENGINEER) -- Kill some things I gave away
                ReturnBorrowedUnits() -- Give back things I was given by others
                TransferUnitsToHighestBrain(BrainCategories.Allies, categories.STRUCTURE + categories.ENGINEER) -- Transfer some things to allies, highest rating first
                TransferOwnershipOfBorrowedUnits(BrainCategories.Allies) -- Give stuff away permanently
            else
                GetBackUnits(BrainCategories.Allies) -- Get back units I gave away
                if shareOption == 'CivilianDeserter' then
                    TransferUnitsToBrain(BrainCategories.Civilians)
                elseif shareOption == 'TransferToKiller' then
                    TransferUnitsToKiller()
                elseif shareOption == 'Defectors' then
                    TransferUnitsToHighestBrain(BrainCategories.Enemies)
                else -- Something went wrong in settings. Act like share until death to avoid abuse
                    WARN('Invalid share condition was used for this game. Defaulting to killing all units')
                    KillSharedUnits(self:GetArmyIndex()) -- Kill things I gave away
                    ReturnBorrowedUnits() -- Give back things I was given by other
                end
            end

            -- Kill all units left over
            local tokill = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
            if tokill and not table.empty(tokill) then
                for index, unit in tokill do
                    unit:Kill()
                end
            end
        end

        -- AI
        if self.BrainType == 'AI' then
            -- print AI "ilost" text to chat
            SUtils.AISendChat('enemies', ArmyBrains[self:GetArmyIndex()].Nickname, 'ilost')
            -- remove PlatoonHandle from all AI units before we kill / transfer the army
            local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
            if units and not table.empty(units) then
                for _, unit in units do
                    if not unit.Dead then
                        if unit.PlatoonHandle and self:PlatoonExists(unit.PlatoonHandle) then
                            unit.PlatoonHandle:Stop()
                            unit.PlatoonHandle:PlatoonDisbandNoAssign()
                        end
                        IssueStop({ unit })
                        IssueToUnitClearCommands(unit)
                    end
                end
            end
            -- Stop the AI from executing AI plans
            self.RepeatExecution = false
            -- removing AI BrainConditionsMonitor
            if self.ConditionsMonitor then
                self.ConditionsMonitor:Destroy()
            end
            -- removing AI BuilderManagers
            if self.BuilderManagers then
                for k, manager in self.BuilderManagers do
                    if manager.EngineerManager then
                        manager.EngineerManager:SetEnabled(false)
                    end

                    if manager.FactoryManager then
                        manager.FactoryManager:SetEnabled(false)
                    end

                    if manager.PlatoonFormManager then
                        manager.PlatoonFormManager:SetEnabled(false)
                    end

                    if manager.EngineerManager then
                        manager.EngineerManager:Destroy()
                    end

                    if manager.FactoryManager then
                        manager.FactoryManager:Destroy()
                    end

                    if manager.PlatoonFormManager then
                        manager.PlatoonFormManager:Destroy()
                    end
                    if manager.StrategyManager then
                        manager.StrategyManager:SetEnabled(false)
                        manager.StrategyManager:Destroy()
                    end
                    self.BuilderManagers[k].EngineerManager = nil
                    self.BuilderManagers[k].FactoryManager = nil
                    self.BuilderManagers[k].PlatoonFormManager = nil
                    self.BuilderManagers[k].BaseSettings = nil
                    self.BuilderManagers[k].BuilderHandles = nil
                    self.BuilderManagers[k].Position = nil
                end
            end
            -- delete the AI pathcache
            self.PathCache = nil
        end

        ForkThread(KillArmy)

        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    AbandonedByPlayer = function(self)
        if not IsGameOver() then
            self:OnDefeat()
        end
    end,

    ---@param self AIBrain
    RecallAllCommanders = function(self)
        local commandCat = categories.COMMAND + categories.SUBCOMMANDER
        self:ForkThread(self.RecallArmyThread, self:GetListOfUnits(commandCat, false))
    end,

    ---@param self AIBrain
    ---@param recallingUnits Unit[]
    RecallArmyThread = function(self, recallingUnits)
        if recallingUnits then
            import("/lua/scenarioframework.lua").FakeTeleportUnits(recallingUnits, true)
        end
        self:OnRecalled()
    end,

    OnRecalled = function(self)
        self.Status = "Recalled"

        local army = self.Army
        import("/lua/simutils.lua").UpdateUnitCap(army)
        import("/lua/simping.lua").OnArmyDefeat(army)

        -- AI
        if self.BrainType == "AI" then
            -- print AI "ilost" text to chat
            SUtils.AISendChat("enemies", ArmyBrains[army].Nickname, "ilost")
            -- remove PlatoonHandle from all AI units before we kill / transfer the army
            local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
            if units and units[1] then
                local halt = 0
                local haltUnits = {}
                for _, unit in units do
                    if not unit.Dead then
                        local handle = unit.PlatoonHandle
                        if handle and self:PlatoonExists(handle) then
                            handle:Stop()
                            handle:PlatoonDisbandNoAssign()
                        end
                        halt = halt + 1
                        haltUnits[halt] = unit
                    end
                end
                IssueStop(haltUnits)
                IssueClearCommands(haltUnits)
            end

            -- Stop the AI from executing AI plans
            self.RepeatExecution = false

            -- removing AI BrainConditionsMonitor
            if self.ConditionsMonitor then
                self.ConditionsMonitor:Destroy()
            end

            -- removing AI BuilderManagers
            if self.BuilderManagers then
                for _, v in self.BuilderManagers do
                    local manager = v.EngineerManager
                    manager:SetEnabled(false)
                    manager:Destroy()
                    manager = v.FactoryManager
                    manager:SetEnabled(false)
                    manager:Destroy()
                    manager = v.PlatoonFormManager
                    manager:SetEnabled(false)
                    manager:Destroy()
                    manager = v.StrategyManager
                    if manager then
                        manager:SetEnabled(false)
                        manager:Destroy()
                    end
                    v.EngineerManager = nil
                    v.FactoryManager = nil
                    v.PlatoonFormManager = nil
                    v.BaseSettings = nil
                    v.BuilderHandles = nil
                    v.Position = nil
                end
            end
            -- delete the AI pathcache
            self.PathCache = nil
        end

        local enemies, civilians = {}, {}

        -- Transfer our units to other brains. Wait in between stops transfer of the same units to multiple armies.
        local function TransferUnitsToBrain(brains)
            if brains[1] then
                local cat = categories.ALLUNITS - categories.WALL - categories.COMMAND - categories.SUBCOMMANDER
                for _, brain in brains do
                    local units = self:GetListOfUnits(cat, false)
                    if units and units[1] then
                        local givenUnitCount = table.getn(TransferUnitsOwnership(units, brain.index))

                        -- only show message when we actually gift that player some units
                        if givenUnitCount > 0 then
                            Sync.ArmyTransfer = { {
                                from = army,
                                to = brain.index,
                                reason = "fullshare",
                            } }
                        end

                        WaitSeconds(1)
                    end
                end
            end
        end

        -- Sort the destiniation brains (armies/players) by rating (and if rating does not exist (such as with regular AI's), by score, after players with positive rating)
        local function TransferUnitsToHighestBrain(brains)
            if not table.empty(brains) then
                local ratings = ScenarioInfo.Options.Ratings
                for _, brain in brains do
                    if ratings[brain.Nickname] then
                        brain.rating = ratings[brain.Nickname]
                    else
                        -- if there is no rating, create a fake negative rating based on score
                        brain.rating = -1 / brain.score
                    end
                end
                -- sort brains by rating
                table.sort(brains, function(a, b) return a.rating > b.rating end)
                TransferUnitsToBrain(brains)
            end
        end

        -- Sort brains out into mutually exclusive categories
        for index, brain in ArmyBrains do
            brain.index = index
            brain.score = CalculateBrainScore(brain)

            if not brain:IsDefeated() and army ~= index then
                if ArmyIsCivilian(index) then
                    table.insert(civilians, brain)
                elseif IsEnemy(army, brain:GetArmyIndex()) then
                    table.insert(enemies, brain)
                end
            end
        end

        -- This part determines the share condition
        local shareOption = ScenarioInfo.Options.Share
        if shareOption == 'CivilianDeserter' then
            TransferUnitsToBrain(civilians)
        elseif shareOption == 'Defectors' then
            TransferUnitsToHighestBrain(enemies)
        end

        -- let the average, team vs team game end first
        WaitSeconds(10.0)

        -- Kill all units left over
        local tokill = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
        if tokill then
            for _, unit in tokill do
                if not IsDestroyed(unit) then
                    unit:Kill()
                end
            end
        end

        local trash = self.Trash
        if trash then
            trash:Destroy()
        end
    end,

    --------------------------------------------------------------------------------
    --#region ping functionality

    ---@param self AIBrain
    ---@param callback function
    ---@param pingType string
    AddPingCallback = function(self, callback, pingType)
        if callback and pingType then
            table.insert(self.PingCallbackList, {CallbackFunction = callback, PingType = pingType})
        end
    end,

    ---@param self AIBrain
    ---@param pingData table
    DoPingCallbacks = function(self, pingData)
        for _, v in self.PingCallbackList do
            v.CallbackFunction(self, pingData)
        end
    end,

    ---@param self AIBrain
    ---@param pingData table
    DoAIPing = function(self, pingData)
        if self.Sorian then
            if pingData.Type then
                SUtils.AIHandlePing(self, pingData)
            end
        end
    end,

    --#endregion
    -------------------------------------------------------------------------------

    -------------------------------------------------------------------------------
    --#region overwritten c-functionality

    --- Retrieves all units that fit the criteria around some point. Excludes dummy units.
    ---@param self AIBrain
    ---@param category EntityCategory The categories the units should fit.
    ---@param position Vector The center point to start looking for units.
    ---@param radius number The radius of the circle we look for units in.
    ---@param alliance AllianceStatus
    ---@return Unit[]
    GetUnitsAroundPoint = function(self, category, position, radius, alliance)
        if alliance then
            -- call where we do care about alliance
            return BrainGetUnitsAroundPoint(self, category - CategoriesDummyUnit, position, radius, alliance)
        else
            -- call where we do not, which is different from providing nil (as there would be a fifth argument then)
            return BrainGetUnitsAroundPoint(self, category - CategoriesDummyUnit, position, radius)
        end
    end,

    --- Returns list of units by category. Excludes dummy units.
    ---@param self AIBrain
    ---@param cats EntityCategory Unit's category, example: categories.TECH2 .
    ---@param needToBeIdle boolean true/false Unit has to be idle (appears to be not functional).
    ---@param requireBuilt? boolean true/false defaults to false which excludes units that are NOT finished (appears to be not functional).
    ---@return table
    GetListOfUnits = function(self, cats, needToBeIdle, requireBuilt)
        -- defaults to false, prevent sending nil
        requireBuilt = requireBuilt or false

        -- retrieve units, excluding insignificant units
        return BrainGetListOfUnits(self, cats - CategoriesDummyUnit, needToBeIdle, requireBuilt)
    end,

    --#endregion
    -------------------------------------------------------------------------------

    -------------------------------------------------------------------------------
    --#region Unit callbacks

    --- Called by a unit as it starts being built
    ---@param self AIBrain
    ---@param unit Unit
    ---@param builder Unit  
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        -- LOG(string.format('OnUnitStartBeingBuilt: %s', unit.Blueprint.BlueprintId or ''))
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        -- LOG(string.format('OnUnitStopBeingBuilt: %s', unit.Blueprint.BlueprintId or ''))
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIBrain
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        -- LOG(string.format('OnUnitDestroyed: %s', unit.Blueprint.BlueprintId or ''))
    end,

    --- Called by a unit as it starts building
    ---@param self AIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        -- LOG(string.format('OnUnitStartBuilding: %s -> %s', unit.Blueprint.BlueprintId or '', built.Blueprint.BlueprintId or ''))
    end,

    --- Called by a unit as it stops building
    ---@param self AIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        -- LOG(string.format('OnUnitStopBuilding: %s -> %s', unit.Blueprint.BlueprintId or '', built.Blueprint.BlueprintId or ''))
    end,

    --#endregion
    -------------------------------------------------------------------------------

    -------------------------------------------------------------------------------
    --#region deprecated

    --- All functions in this region exist because they may still be called from
    --- unmaintained mods. They no longer serve any purpose.

    ---@deprecated
    ---@param self AIBrain
    ReportScore = function(self)
    end,

    ---@deprecated
    ---@param self AIBrain
    ---@param result AIResult
    SetResult = function(self, result)
    end,

    --#endregion
    -------------------------------------------------------------------------------

    -------------------------------------------------------------------------------
    --#region legacy functionality

    --- All functions below solely exist because the code is too tightly coupled. 
    --- We can't remove them without drastically changing how the code base works. 
    --- We can't do that because it would break mod compatibility

    ---@deprecated
    ---@param self AIBrain
    SetConstantEvaluate = function(self)
    end,

    ---@deprecated
    ---@param self AIBrain
    InitializeSkirmishSystems = function(self)
    end,

    ---@deprecated
    ---@param self AIBrain
    ForceManagerSort = function(self)
    end,

    ---@deprecated
    ---@param self AIBrain
    InitializePlatoonBuildManager = function(self)
    end,

    --#endregion
    -------------------------------------------------------------------------------
}
