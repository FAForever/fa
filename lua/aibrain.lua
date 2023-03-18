-----------------------------------------------------------------
-- File     :  /lua/aibrain.lua
-- Author(s):
-- Summary  :
-- Copyright Š 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- AIBrain Lua Module
local AIDefaultPlansList = import("/lua/aibrainplans.lua").AIPlansList
local AIUtils = import("/lua/ai/aiutilities.lua")

local Utilities = import("/lua/utilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Behaviors = import("/lua/ai/aibehaviors.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")

local FactoryManager = import("/lua/sim/factorybuildermanager.lua")
local PlatoonFormManager = import("/lua/sim/platoonformmanager.lua")
local BrainConditionsMonitor = import("/lua/sim/brainconditionsmonitor.lua")
local EngineerManager = import("/lua/sim/engineermanager.lua")

local SUtils = import("/lua/ai/sorianutilities.lua")
local StratManager = import("/lua/sim/strategymanager.lua")
local TransferUnitsOwnership = import("/lua/simutils.lua").TransferUnitsOwnership
local TransferUnfinishedUnitsAfterDeath = import("/lua/simutils.lua").TransferUnfinishedUnitsAfterDeath
local CalculateBrainScore = import("/lua/sim/score.lua").CalculateBrainScore
local Factions = import('/lua/factions.lua').GetFactions(true)

-- upvalue for performance
local BrainGetUnitsAroundPoint = moho.aibrain_methods.GetUnitsAroundPoint
local BrainGetListOfUnits = moho.aibrain_methods.GetListOfUnits
local GetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local GetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local GetEconomyTrend = moho.aibrain_methods.GetEconomyTrend
local CategoriesDummyUnit = categories.DUMMYUNIT
local CoroutineYield = coroutine.yield

local TableGetn = table.getn

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

--TODO
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

---@class AIBrain: moho.aibrain_methods
---@field Army number
---@field AIPlansList string[][]
---@field AirAttackPoints? table
---@field AttackData AttackManager
---@field AttackManager AttackManager
---@field AttackPoints? table
---@field BaseMonitor AiBaseMonitor
---@field BrainType BrainType
---@field BuilderManagers table<string, table>
---@field ConditionsMonitor BrainConditionsMonitor
---@field ConstantEval boolean
---@field CurrentPlan string lua file which contains plan
---@field CurrentPlanScript table
---@field EconomyCurrentTick number
---@field EconomyData {EnergyIncome: number, EnergyRequested: number, MassIncome: number, MassRequested: number}[]
---@field EnergyExcessThread thread
---@field EnergyExcessUnitsEnabled table<EntityId, MassFabricationUnit>
---@field EnergyExcessUnitsDisabled table<EntityId, MassFabricationUnit>
---@field EnergyDependingUnits table<EntityId, Unit | Shield>
---@field EnergyDepleted boolean
---@field EconomyTicksMonitor number
---@field HasPlatoonList boolean
---@field HQs table<HqFaction, table<HqLayer, table<HqTech, number>>>
---@field IntelData? table<string, number>
---@field IntelTriggerList table
---@field LayerPref "LAND" | "AIR"
---@field Name string
---@field PBM AiPlatoonBuildManager
---@field PingCallbackList table
---@field PlatoonNameCounter? table<string, number>
---@field Radars table<string, Unit[]>
---@field RepeatExecution boolean
---@field Result? AIResult
---@field SelfMonitor AiSelfMonitor
---@field Sorian boolean
---@field Status BrainState
---@field T4ThreatFound? table
---@field TacticalBases? table
---@field targetoveride boolean
---@field Team number The team this brain's army belongs to. Note that games with unlocked teams behave like free-for-alls.
---@field Trash TrashBag
---@field TriggerList table
---@field UnitBuiltTriggerList table
---@field UnitStats table<EntityId, table<string, number>>
---@field VeterancyTriggerList table
AIBrain = Class(moho.aibrain_methods) {
    -- The state of the brain in the match
    Status = 'InProgress',

    --- HUMAN BRAIN FUNCTIONS HANDLED HERE
    ---@param self AIBrain
    ---@param planName string
    OnCreateHuman = function(self, planName)
        self:CreateBrainShared(planName)
        self.BrainType = 'Human'

        -- human-only behavior
        self.EnergyExcessThread = ForkThread(self.ToggleEnergyExcessUnitsThread, self)
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

    ---@param self AIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        self:CreateBrainShared(planName)

        local civilian = false
        for name, data in ScenarioInfo.ArmySetup do
            if name == self.Name then
                civilian = data.Civilian
                break
            end
        end

        if not civilian then
            local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality

            -- Flag this brain as a possible brain to have skirmish systems enabled on
            self.SkirmishSystems = true

            local cheatPos = string.find(per, 'cheat')
            if cheatPos then
                AIUtils.SetupCheat(self, true)
                ScenarioInfo.ArmySetup[self.Name].AIPersonality = string.sub(per, 1, cheatPos - 1)
            end

            LOG('* OnCreateAI: AIPersonality: ('..per..')')
            if string.find(per, 'sorian') then
                self.Sorian = true
            end
            if DiskGetFileInfo('/lua/AI/altaiutilities.lua') then
                self.Duncan = true
            end

            self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
            self:ForkThread(self.InitialAIThread)

            self.PlatoonNameCounter = {}
            self.PlatoonNameCounter['AttackForce'] = 0
            self.BaseTemplates = {}
            self.RepeatExecution = true
            self.IntelData = {
                ScoutCounter = 0,
            }

            -- Flag enemy starting locations with threat?
            if ScenarioInfo.type == 'skirmish' then
                if self.Sorian then
                    -- Gives the initial threat a type so initial land platoons will actually attack it.
                    self:AddInitialEnemyThreatSorian(200, 0.005, 'Economy')
                else
                    self:AddInitialEnemyThreat(200, 0.005)
                end
            end
        end
        self.UnitBuiltTriggerList = {}
        self.FactoryAssistList = {}
        self.DelayEqualBuildPlattons = {}
        self.BrainType = 'AI'
    end,

    IsBaseAI = function(self)
        return ScenarioInfo.ArmySetup[self.Name].BaseAI
    end,

    --- Adds a HQ so that the engi mod knows we have it
    ---@param self AIBrain
    ---@param faction HqFaction 
    ---@param layer HqLayer 
    ---@param tech HqTech 
    AddHQ = function (self, faction, layer, tech)
        self.HQs[faction][layer][tech] = self.HQs[faction][layer][tech] + 1
    end,

    --- Removes an HQ so that the engi mod knows we lost it for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction
    ---@param layer HqLayer 
    ---@param tech HqTech 
    RemoveHQ = function (self, faction, layer, tech)
        self.HQs[faction][layer][tech] = math.max(0, self.HQs[faction][layer][tech] - 1)
    end,

    --- Completely re evaluates the support factory restrictions of the engi mod
    ---@param self AIBrain
    ReEvaluateHQSupportFactoryRestrictions = function (self)
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
    SetHQSupportFactoryRestrictions = function (self, faction, layer)

        -- localize for performance
        local army = self:GetArmyIndex()

        -- the pessimists we are, restrict everything!
        AddBuildRestriction(army, categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        AddBuildRestriction(army, categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)

        -- lift t2 / t3 support factory restrictions
        if self.HQs[faction][layer]["TECH3"] > 0 then
            RemoveBuildRestriction(army, categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
            RemoveBuildRestriction(army, categories[faction] * categories[layer] * categories["TECH3"] * categories.SUPPORTFACTORY)
        end

        -- lift t2 support factory restrictions
        if self.HQs[faction][layer]["TECH2"] > 0 then
            RemoveBuildRestriction(army, categories[faction] * categories[layer] * categories["TECH2"] * categories.SUPPORTFACTORY)
        end
    end,

    --- Counts all HQs of specific faction, layer and tech for the engi mod.
    ---@param self AIBrain
    ---@param faction HqFaction 
    ---@param layer HqLayer 
    ---@param tech HqTech 
    ---@return number
    CountHQs = function (self, faction, layer, tech)
        return self.HQs[faction][layer][tech]
    end,

    --- Counts all HQs of faction and tech, regardless of layer
    ---@param self AIBrain
    ---@param faction HqFaction 
    ---@param tech HqTech
    ---@return number
    CountHQsAllLayers = function (self, faction, tech)
        local count = self.HQs[faction]["LAND"][tech]
        count = count + self.HQs[faction]["AIR"][tech]
        count = count + self.HQs[faction]["NAVAL"][tech]
        return count
    end,

    ---@param self AIBrain
    ---@param planName string
    CreateBrainShared = function(self, planName)

        -- make sure there is always some storage
        self:GiveStorage('Energy', 100)

        -- make sure the army stats exist
        self:SetArmyStat('Economy_Ratio_Mass', 1.0)
        self:SetArmyStat('Economy_Ratio_Energy', 1.0)
    
        -- add initial trigger and assume we're not depleted
        self:SetArmyStatsTrigger('Economy_Ratio_Energy', 'EnergyDepleted', 'LessThanOrEqual', 0.0)
        self.EnergyDepleted = false 
        self.EnergyDependingUnits = setmetatable({ }, { __mode = 'v' })

        --- Units that we toggle on / off depending on whether we have excess energy
        self.EnergyExcessConsumed = 0
        self.EnergyExcessRequired = 0
        self.EnergyExcessConverted = 0

        self.EnergyExcessUnitsEnabled = { }
        setmetatable(self.EnergyExcessUnitsEnabled, { __mode = 'v' })
        self.EnergyExcessUnitsDisabled = { }
        setmetatable(self.EnergyExcessUnitsDisabled, { __mode = 'v' })

        -- they are capitalized to match category names
        local layers = { "LAND", "AIR", "NAVAL" }
        local techs = { "TECH2", "TECH3" }
    
        self.Jammers = { }
        setmetatable(self.Jammers, { __mode = 'v' })

        self.JammerResetTime = 15

        ForkThread(self.JammingToggleThread, self)

        -- populate the possible HQs per faction, layer and tech
        self.HQs = { }
        for _, facData in Factions do 
            local faction = facData.Category
            self.HQs[faction] = { }
            for _, layer in layers do 
                self.HQs[faction][layer] = { }
                for _, tech in techs do 
                    self.HQs[faction][layer][tech] = 0
                end 
            end
        end

        -- keep track of radars
        self.Radars = { 
            TECH1 = { },
            TECH2 = { },
            TECH3 = { },
            EXPERIMENTAL = { },
        }

        -- restrict all support factories by default
        AddBuildRestriction(self:GetArmyIndex(), (categories.TECH3 + categories.TECH2) * categories.SUPPORTFACTORY)

        -- end of engi mod

        self.Army = self:GetArmyIndex()
        self.Result = nil -- No-op, just to be explicit it starts as nil
        self.StatsSent = false
        self.UnitStats = {}
        self.Trash = TrashBag()

        local aiScenarioPlans = self:ImportScenarioArmyPlans(planName)
        if aiScenarioPlans then
            self.AIPlansList = aiScenarioPlans
        else
            self.DefaultPlan = true
            self.AIPlansList = AIDefaultPlansList
        end
        self.RepeatExecution = false

        if ScenarioInfo.type == 'campaign' then
            self:SetResourceSharing(false)
        end

        self.ConstantEval = true
        self.IgnoreArmyCaps = false
        self.TriggerList = {}
        self.IntelTriggerList = {}
        self.VeterancyTriggerList = {}
        self.PingCallbackList = {}
        self.UnitBuiltTriggerList = {}
        self.VOTable = {}
    end,

    ---@param self AIBrain
    OnSpawnPreBuiltUnits = function(self)
        local factionIndex = self:GetFactionIndex()
        local resourceStructures = nil
        local initialUnits = nil
        local posX, posY = self:GetArmyStartPos()

        if factionIndex == 1 then
            resourceStructures = {'UEB1103', 'UEB1103', 'UEB1103', 'UEB1103'}
            initialUnits = {'UEB0101', 'UEB1101', 'UEB1101', 'UEB1101', 'UEB1101'}
        elseif factionIndex == 2 then
            resourceStructures = {'UAB1103', 'UAB1103', 'UAB1103', 'UAB1103'}
            initialUnits = {'UAB0101', 'UAB1101', 'UAB1101', 'UAB1101', 'UAB1101'}
        elseif factionIndex == 3 then
            resourceStructures = {'URB1103', 'URB1103', 'URB1103', 'URB1103'}
            initialUnits = {'URB0101', 'URB1101', 'URB1101', 'URB1101', 'URB1101'}
        elseif factionIndex == 4 then
            resourceStructures = {'XSB1103', 'XSB1103', 'XSB1103', 'XSB1103'}
            initialUnits = {'XSB0101', 'XSB1101', 'XSB1101', 'XSB1101', 'XSB1101'}
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

    --- Jamming Switch Logic

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

    -- Energy storage callbacks

    --- Adds a unit that is enabled / disabled depending on how much energy storage we have. The unit starts enabled
    ---@param self AIBrain The brain itself
    ---@param unit MassFabricationUnit The unit to keep track of
    AddEnabledEnergyExcessUnit = function (self, unit)
        self.EnergyExcessUnitsEnabled[unit.EntityId] = unit
        self.EnergyExcessUnitsDisabled[unit.EntityId] = nil

        local ecobp = unit.Blueprint.Economy
        self.EnergyExcessConsumed = self.EnergyExcessConsumed + ecobp.MaintenanceConsumptionPerSecondEnergy
        self.EnergyExcessConverted = self.EnergyExcessConverted + ecobp.ProductionPerSecondMass
    end,

    --- Adds a unit that is enabled / disabled depending on how much energy storage we have. The unit starts disabled
    ---@param self AIBrain
    ---@param unit MassFabricationUnit The unit to keep track of
    AddDisabledEnergyExcessUnit = function (self, unit)
        self.EnergyExcessUnitsEnabled[unit.EntityId] = nil
        self.EnergyExcessUnitsDisabled[unit.EntityId] = unit
        self.EnergyExcessRequired = self.EnergyExcessRequired + unit.Blueprint.Economy.MaintenanceConsumptionPerSecondEnergy
    end,

    --- Removes a unit that is enabled / disabled depending on how much energy storage we have
    ---@param self AIBrain
    ---@param unit MassFabricationUnit The unit to forget about
    RemoveEnergyExcessUnit = function (self, unit)
        local ecobp = unit.Blueprint.Economy
        if  self.EnergyExcessUnitsEnabled[unit.EntityId] then
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
    ToggleEnergyExcessUnitsThread = function (self)

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
        local CoroutineYield = CoroutineYield
        
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
                        self.EnergyExcessConsumed = self.EnergyExcessConsumed - ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessRequired = self.EnergyExcessRequired + ecobp.MaintenanceConsumptionPerSecondEnergy
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
                        self.EnergyExcessConsumed = self.EnergyExcessConsumed + ecobp.MaintenanceConsumptionPerSecondEnergy
                        self.EnergyExcessRequired = self.EnergyExcessRequired - ecobp.MaintenanceConsumptionPerSecondEnergy
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

    --- Triggers based on an AiBrain
    ---@param self AIBrain
    ---@param triggerName string
    OnStatsTrigger = function(self, triggerName)

        if triggerName == "EnergyDepleted" or triggerName == "EnergyViable" then 
            self:OnEnergyTrigger(triggerName)
        end

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

    --- ## INTEL TRIGGER SPEC
    --- ```
    --- CallbackFunction = <function>,
    --- Type = 'LOS'/'Radar'/'Sonar'/'Omni',
    --- Blip = true/false,
    --- Value = true/false,
    --- Category: blip category to match
    --- OnceOnly: fire onceonly
    --- TargetAIBrain: AI Brain of the army you want it to trigger off of.
    --- ```
    ---@param self AIBrain
    ---@param triggerSpec TriggerSpec
    SetupArmyIntelTrigger = function(self, triggerSpec)
        table.insert(self.IntelTriggerList, triggerSpec)
    end,

    ---Called when recon data changes for enemy units (e.g. A unit comes into line of sight)
    ---@param self AIBrain
    ---@param blip any the unit (could be fake) in question
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        if not val then
            if reconType == 'LOSNow' or reconType == 'Omni' then
                local unit = blip:GetSource()
                if unit.Blueprint.Intel.JammerBlips > 0 then
                    unit.ResetJammer = self.JammerResetTime
                end
            end
        end

        if self.IntelTriggerList then
            for k, v in self.IntelTriggerList do
                if EntityCategoryContains(v.Category, blip:GetBlueprint().BlueprintId)
                    and v.Type == reconType and (not v.Blip or v.Blip == blip:GetSource())
                    and v.Value == val and v.TargetAIBrain == blip:GetAIBrain() then
                    v.CallbackFunction(blip)
                    if v.OnceOnly then
                        self.IntelTriggerList[k] = nil
                    end
                end
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
        table.insert(self.UnitBuiltTriggerList, {Callback = callback, Category = category, Percent = percent})
    end,

    ---@param self AIBrain
    ---@param triggerSpec TriggerSpec
    SetupBrainVeterancyTrigger = function(self, triggerSpec)
        if not triggerSpec.CallCount then
            triggerSpec.CallCount = 1
        end
        table.insert(self.VeterancyTriggerList, triggerSpec)
    end,

    ---@param self AIBrain
    ---@param unit Unit
    ---@param level number
    OnBrainUnitVeterancyLevel = function(self, unit, level)
        for _, v in self.VeterancyTriggerList do
            if EntityCategoryContains(v.Category, unit) and level == v.Level and v.CallCount > 0 then
                v.CallCount = v.CallCount - 1
                v.CallbackFunction(unit)
            end
        end
    end,

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

    -- AI BRAIN FUNCTIONS HANDLED HERE --

    ---@param self AIBrain
    ---@param planName FileName
    ---@return string[]|nil
    ImportScenarioArmyPlans = function(self, planName)
        if planName and planName ~= '' then
            return import(planName).AIPlansList
        else
            return nil
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
    OnDestroy = function(self)
        if self.BuilderManagers then
            self.ConditionsMonitor:Destroy()
            for _, v in self.BuilderManagers do

                v.EngineerManager:SetEnabled(false)
                v.FactoryManager:SetEnabled(false)
                v.PlatoonFormManager:SetEnabled(false)
                v.FactoryManager:Destroy()
                v.PlatoonFormManager:Destroy()
                v.EngineerManager:Destroy()
            end
        end
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    ---@param self AIBrain
    ---@deprecated 
    ReportScore = function(self)
    end,

    ---@param self AIBrain
    ---@param result AIResult
    ---@deprecated
    SetResult = function(self, result)
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
            local BrainCategories = {Enemies = {}, Civilians = {}, Allies = {}}

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
                            brain.rating = - (1 / brain.score)
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
                        IssueStop({unit})
                        IssueClearCommands({unit})
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
                for k, v in self.BuilderManagers do
                    v.EngineerManager:SetEnabled(false)
                    v.FactoryManager:SetEnabled(false)
                    v.PlatoonFormManager:SetEnabled(false)
                    v.EngineerManager:Destroy()
                    v.FactoryManager:Destroy()
                    v.PlatoonFormManager:Destroy()
                    if v.StrategyManager then
                        v.StrategyManager:SetEnabled(false)
                        v.StrategyManager:Destroy()
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

    ---@param self AIBrain
    OnVictory = function(self)
        self.Status = 'Victory'
    end,

    ---@param self AIBrain
    OnDraw = function(self)
        self.Status = 'Draw'
    end,

    ---@param self AIBrain
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

       -- Kill all units left over
       local tokill = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
       if tokill then
            for _, unit in tokill do
                unit:Kill()
            end
        end

        local trash = self.Trash
        if trash then
            trash:Destroy()
        end
    end,

    ---@param self AIBrain
    IsDefeated = function(self)
        local status = self.Status
        return status == "Defeat" or status == "Recalled" or ArmyIsOutOfGame(self.Army)
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

    ---@param self AIBrain
    ---@param bestPlan string
    SetCurrentPlan = function(self, bestPlan)
        if not bestPlan then
            self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
        else
            self.CurrentPlan = bestPlan
        end
        if not self.CurrentPlan then
            error('*AI ERROR: Invalid plan list for army - '..self.Name, 2)
        end
    end,

    ---@param self AIBrain
    ---@param eval boolean
    SetConstantEvaluate = function(self, eval)
        if eval == true and self.ConstantEval == false then
            self.ConstantEval = eval
            self:ForkThread(self.EvaluateAIThread)
        end
        self.ConstantEval = eval
    end,

    ---@param self AIBrain
    InitialAIThread = function(self)
        -- delay the AI so it can't reclaim the start area before it's cleared from the ACU landing blast.
        WaitTicks(30)
        self.EvaluateThread = self:ForkThread(self.EvaluateAIThread)
        self.ExecuteThread = self:ForkThread(self.ExecuteAIThread)
    end,

    ---@param self AIBrain
    EvaluateAIThread = function(self)
        local personality = self:GetPersonality()
        local factionIndex = self:GetFactionIndex()

        if not self.LayerPref then
            self:CalculateLayerPreference()
        end

        while self.ConstantEval do
            self:EvaluateAIPlanList()
            local delay = personality:AdjustDelay(100, 2)
            WaitTicks(delay)
        end
    end,

    ---@param self AIBrain
    EvaluateAIPlanList = function(self)
        local factionIndex = self:GetFactionIndex()
        local bestPlan = nil
        local bestValue = 0
        for _, v in self.AIPlansList[factionIndex] do
            local value = self:EvaluatePlan(v)
            if value > bestValue then
                bestPlan = v
                bestValue = value
            end
        end
        if bestPlan then
            self:SetCurrentPlan(bestPlan)
            local bPlan = import(bestPlan)
            if bPlan ~= self.CurrentPlanScript then
                self.CurrentPlanScript = import(bestPlan)
                self:SetRepeatExecution(true)
                self:ExecutePlan(self.CurrentPlan)
            end
        end
    end,

    ---@param self AIBrain
    ExecuteAIThread = function(self)
        local personality = self:GetPersonality()

        while true do
            if self.CurrentPlan and self.RepeatExecution then
                self:ExecutePlan(self.CurrentPlan)
            end
            local delay = personality:AdjustDelay(20, 4)
            WaitTicks(delay)
        end
    end,

    ---@param self AIBrain
    ---@param planName FileName
    ---@return number
    EvaluatePlan = function(self, planName)
        local plan = import(planName)
        if plan then
            return plan.EvaluatePlan(self)
        else
            LOG('*WARNING: TRIED TO IMPORT PLAN NAME ', repr(planName), ' BUT IT ERRORED OUT IN THE AI BRAIN.')
            return 0
        end
    end,

    ---@param self AIBrain
    ExecutePlan = function(self)
        self.CurrentPlanScript.ExecutePlan(self)
    end,

    ---@param self AIBrain
    SetRepeatExecution = function(self, repeatEx)
        self.RepeatExecution = repeatEx
    end,

    ---@param self AIBrain
    GetCurrentPlanScript = function(self)
        return self.CurrentPlanScript
    end,

    ---@param self AIBrain
    ---@param val number
    IgnoreArmyUnitCap = function(self, val)
        self.IgnoreArmyCaps = val
        SetIgnoreArmyCap(self, val)
    end,

    -- System for playing VOs to the Player
    VOSounds = {
        -- {timeout delay, default cue, observers}
        NuclearLaunchDetected =        {timeout = 1, bank = nil, obs = true},
        OnTransportFull =              {timeout = 1, bank = nil},
        OnFailedUnitTransfer =         {timeout = 10, bank = 'Computer_Computer_CommandCap_01298'},
        OnPlayNoStagingPlatformsVO =   {timeout = 5, bank = 'XGG_Computer_CV01_04756'},
        OnPlayBusyStagingPlatformsVO = {timeout = 5, bank = 'XGG_Computer_CV01_04755'},
        OnPlayCommanderUnderAttackVO = {timeout = 15, bank = 'Computer_Computer_Commanders_01314'},
    },

    ---@param self AIBrain
    ---@param string string
    ---@param sound SoundHandle
    PlayVOSound = function(self, string, sound)
        if not self.VOTable then self.VOTable = {} end

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
        import('/lua/SimSyncUtils.lua').SyncVoice({Cue = cue, Bank = bank})

        local timeout = VO['timeout']
        ForkThread(function()
            WaitSeconds(timeout)
            self.VOTable[string] = nil
        end)
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

        self:PlayVOSound('OnTransportFull', Sound {Bank = 'XGG', Cue = cue})
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

    ---SKIRMISH AI HELPER SYSTEMS
    ---@param self AIBrain
    InitializeSkirmishSystems = function(self)
        -- Make sure we don't do anything for the human player!!!
        if self.BrainType == 'Human' then
            return
        end

        -- TURNING OFF AI POOL PLATOON, I MAY JUST REMOVE THAT PLATOON FUNCTIONALITY LATER
        local poolPlatoon = self:GetPlatoonUniquelyNamed('ArmyPool')
        if poolPlatoon then
            poolPlatoon.ArmyPool = true
            poolPlatoon:TurnOffPoolAI()
        end

        -- Stores handles to all builders for quick iteration and updates to all
        self.BuilderHandles = {}

        -- Condition monitor for the whole brain
        self.ConditionsMonitor = BrainConditionsMonitor.CreateConditionsMonitor(self)

        -- Economy monitor for new skirmish - stores out econ over time to get trend over 10 seconds
        self.EconomyData = {}
        self.EconomyOverTimeCurrent = {}
        self.EconomyTicksMonitor = 300
        self.EconomyMonitorThread = self:ForkThread(self.EconomyMonitor)
        self.LowEnergyMode = false

        -- Add default main location and setup the builder managers
        self.NumBases = 0 -- AddBuilderManagers will increase the number
        
        -- Set the map center point
        self.MapCenterPoint = { (ScenarioInfo.size[1] / 2), GetSurfaceHeight((ScenarioInfo.size[1] / 2), (ScenarioInfo.size[2] / 2)) ,(ScenarioInfo.size[2] / 2) }

        self.BuilderManagers = {}
        SUtils.AddCustomUnitSupport(self)
        self:AddBuilderManagers(self:GetStartVector3f(), 100, 'MAIN', false)

        -- Begin the base monitor process
        if self.Sorian then
            local spec = {
                DefaultDistressRange = 200,
                AlertLevel = 8,
            }
            self:BaseMonitorInitializationSorian(spec)
        else
            self:BaseMonitorInitialization()
        end

        local plat = self:GetPlatoonUniquelyNamed('ArmyPool')
        if self.Sorian then
            plat:ForkThread(plat.BaseManagersDistressAISorian)
        else
            plat:ForkThread(plat.BaseManagersDistressAI)
        end

        self.DeadBaseThread = self:ForkThread(self.DeadBaseMonitor)
        if self.Sorian then
            self.EnemyPickerThread = self:ForkThread(self.PickEnemySorian)
        else
            self.EnemyPickerThread = self:ForkThread(self.PickEnemy)
        end
        
        self.IMAPConfig = {
            OgridRadius = 0,
            IMAPSize = 0,
            Rings = 0,
        }

        self:IMAPConfiguration()
        if self:IsBaseAI() then
            self:ForkThread(self.MapAnalysis)
            self:ForkThread(self.InitializeIntelFramework)
        end
    end,

    ---@param self AIBrain
    ---@param amount number
    ---@param decay number
    ---@param threatType string
    AddInitialEnemyThreatSorian = function(self, amount, decay, threatType)
        local aiBrain = self
        local myArmy = ScenarioInfo.ArmySetup[self.Name]

        if ScenarioInfo.Options.TeamSpawn == 'fixed' then
            -- Spawn locations were fixed. We know exactly where our opponents are.
            for i = 1, 16 do
                local token = 'ARMY_' .. i
                local army = ScenarioInfo.ArmySetup[token]

                if army then
                    if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                        local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position
                        if startPos then
                            self:AssignThreatAtPosition(startPos, amount, decay, threatType or 'Overall')
                        end
                    end
                end
            end
        end
    end,

    ---Removes bases that have no engineers or factories.  This is a sorian AI function
    ---Helps reduce the load on the game.
    ---@param self AIBrain
    DeadBaseMonitor = function(self)
        while true do
            WaitSeconds(5)
            local needSort = false
            for k, v in self.BuilderManagers do
                if k ~= 'MAIN' and v.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) <= 0 and v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) <= 0 then
                    v.EngineerManager:SetEnabled(false)
                    v.EngineerManager:Destroy()
                    v.FactoryManager:SetEnabled(false)
                    v.FactoryManager:Destroy()
                    v.PlatoonFormManager:SetEnabled(false)
                    v.PlatoonFormManager:Destroy()
                    if v.StrategyManager then
                        v.StrategyManager:SetEnabled(false)
                        v.StrategyManager:Destroy()
                    end
                    self.BuilderManagers[k] = nil
                    self.NumBases = self.NumBases - 1
                    needSort = true
                end
            end
            if needSort then
                self.BuilderManagers = self:RebuildTable(self.BuilderManagers)
            end
        end
    end,

    ---Used to get rid of nil table entries. Sorian ai function
    ---@param self AIBrain
    ---@param oldtable table
    ---@return table
    RebuildTable = function(self, oldtable)
        local temptable = {}
        for k, v in oldtable do
            if v ~= nil then
                if type(k) == 'string' then
                    temptable[k] = v
                else
                    table.insert(temptable, v)
                end
            end
        end
        return temptable
    end,

    ---@param self AIBrain
    ---@param locationType string
    ---@return boolean
    GetLocationPosition = function(self, locationType)
        if not self.BuilderManagers[locationType] then
            WARN('*AI ERROR: Invalid location type - ' .. locationType)
            return false
        end
        return self.BuilderManagers[locationType].Position
    end,

    ---@param self AIBrain
    ---@param position Vector
    ---@return Vector
    FindClosestBuilderManagerPosition = function(self, position)
        local distance, closest
        for k, v in self.BuilderManagers do
            if v.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) <= 0 and v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) <= 0 then
                continue
            end
            if position and v.Position then
                if not closest then
                    distance = VDist3(position, v.Position)
                    closest = v.Position
                else
                    local tempDist = VDist3(position, v.Position)
                    if tempDist < distance then
                        distance = tempDist
                        closest = v.Position
                    end
                end
            end
        end
        return closest
    end,

    ---@param self AIBrain
    ForceManagerSort = function(self)
        for _, v in self.BuilderManagers do
            v.EngineerManager:SortBuilderList('Any')
            v.FactoryManager:SortBuilderList('Land')
            v.FactoryManager:SortBuilderList('Air')
            v.FactoryManager:SortBuilderList('Sea')
            v.PlatoonFormManager:SortBuilderList('Any')
        end
    end,

    ---@param self AIBrain
    ---@param type string
    ---@return integer
    GetManagerCount = function(self, type)
        local count = 0
        for k, v in self.BuilderManagers do
            if not v.BaseType then
                continue
            end
            if type then
                if type == 'Start Location' and v.BaseType ~= 'MAIN' and v.BaseType ~= 'Blank Marker' then
                    continue
                elseif type == 'Naval Area' and v.BaseType ~= 'Naval Area' then
                    continue
                elseif type == 'Expansion Area' and v.BaseType ~= 'Expansion Area' and v.BaseType ~= 'Large Expansion Area' then
                    continue
                end
            end

            if v.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) <= 0 and v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) <= 0 then
                continue
            end

            count = count + 1
        end
        return count
    end,

    ---@param self AIBrain
    ---@param spec any
    BaseMonitorInitializationSorian = function(self, spec)
        ---@class AiBaseMonitor
        self.BaseMonitor = {
            BaseMonitorStatus = 'ACTIVE',
            BaseMonitorPoints = {},
            AlertSounded = false,
            AlertsTable = {},
            AlertLocation = false,
            AlertSoundedThreat = 0,
            ActiveAlerts = 0,

            PoolDistressRange = 75,
            PoolReactionTime = 7,

            -- Variables for checking a radius for enemy units
            UnitRadiusThreshold = spec.UnitRadiusThreshold or 3,
            UnitCategoryCheck = spec.UnitCategoryCheck or (categories.MOBILE - (categories.SCOUT + categories.ENGINEER)),
            UnitCheckRadius = spec.UnitCheckRadius or 40,

            -- Threat level must be greater than this number to sound a base alert
            AlertLevel = spec.AlertLevel or 0,

            -- Delay time for checking base
            BaseMonitorTime = spec.BaseMonitorTime or 11,

            -- Default distance a platoon will travel to help around the base
            DefaultDistressRange = spec.DefaultDistressRange or 75,

            -- Default how often platoons will check if the base is under duress
            PlatoonDefaultReactionTime = spec.PlatoonDefaultReactionTime or 5,

            -- Default duration for an alert to time out
            DefaultAlertTimeout = spec.DefaultAlertTimeout or 10,

            PoolDistressThreshold = 1,

            -- Monitor platoons for help
            PlatoonDistressTable = {},
            PlatoonDistressThread = false,
            PlatoonAlertSounded = false,
        }
        ---@class AiSelfMonitor
        self.SelfMonitor = {
            CheckRadius = spec.SelfCheckRadius or 150,
            ArtyCheckRadius = spec.SelfArtyCheckRadius or 300,
            ThreatRadiusThreshold = spec.SelfThreatRadiusThreshold or 8,
        }
        self:ForkThread(self.BaseMonitorThreadSorian)
    end,

    ---@param self AIBrain
    BaseMonitorThreadSorian = function(self)
        while true do
            if self.BaseMonitor.BaseMonitorStatus == 'ACTIVE' then
                self:SelfMonitorCheck()
                self:BaseMonitorCheck()
            end
            WaitSeconds(self.BaseMonitor.BaseMonitorTime)
        end
    end,

    ---@param self AIBrain
    SelfMonitorCheck = function(self)
        if not self.BaseMonitor.AlertSounded then
            local startlocx, startlocz = self:GetArmyStartPos()
            local threatTable = self:GetThreatsAroundPosition({startlocx, 0, startlocz}, 16, true, 'AntiSurface')
            local artyThreatTable = self:GetThreatsAroundPosition({startlocx, 0, startlocz}, 16, true, 'Artillery')
            local highThreat = false
            local highThreatPos = false
            local radius = self.SelfMonitor.CheckRadius * self.SelfMonitor.CheckRadius
            local artyRadius = self.SelfMonitor.ArtyCheckRadius * self.SelfMonitor.ArtyCheckRadius

            for tIndex, threat in threatTable do
                local enemyThreat = self:GetThreatAtPosition({threat[1], 0, threat[2]}, 0, true, 'AntiSurface')
                local dist = VDist2Sq(threat[1], threat[2], startlocx, startlocz)
                if (not highThreat or enemyThreat > highThreat) and enemyThreat > self.SelfMonitor.ThreatRadiusThreshold and dist < radius then
                    highThreat = enemyThreat
                    highThreatPos = {threat[1], 0, threat[2]}
                end
            end

            if highThreat then
                table.insert(self.BaseMonitor.AlertsTable,
                    {
                    Position = highThreatPos,
                    Threat = highThreat,
                   }
                )
                self:ForkThread(self.BaseMonitorAlertTimeout, highThreatPos)
                self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts + 1
                self.BaseMonitor.AlertSounded = true
            end

            highThreat = false
            highThreatPos = false
            for tIndex, threat in artyThreatTable do
                local enemyThreat = self:GetThreatAtPosition({threat[1], 0, threat[2]}, 0, true, 'Artillery')
                local dist = VDist2Sq(threat[1], threat[2], startlocx, startlocz)
                if (not highThreat or enemyThreat > highThreat) and enemyThreat > self.SelfMonitor.ThreatRadiusThreshold and dist < artyRadius then
                    highThreat = enemyThreat
                    highThreatPos = {threat[1], 0, threat[2]}
                end
            end

            if highThreat then
                table.insert(self.BaseMonitor.AlertsTable,
                    {
                        Position = highThreatPos,
                        Threat = highThreat,
                    }
                )
                self:ForkThread(self.BaseMonitorAlertTimeout, highThreatPos, 'Artillery')
                self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts + 1
                self.BaseMonitor.AlertSounded = true
            end
        end
    end,

    ---@param self AIBrain
    ---@param position Vector
    ---@param radius number
    ---@param baseName string
    ---@param useCenter boolean
    AddBuilderManagers = function(self, position, radius, baseName, useCenter)

        local baseLayer = 'Land'
        position[2] = GetTerrainHeight( position[1], position[3] )
        if GetSurfaceHeight( position[1], position[3] ) > position[2] then
            position[2] = GetSurfaceHeight( position[1], position[3] )
            baseLayer = 'Water'
        end

        self.BuilderManagers[baseName] = {
            FactoryManager = FactoryManager.CreateFactoryBuilderManager(self, baseName, position, radius, useCenter),
            PlatoonFormManager = PlatoonFormManager.CreatePlatoonFormManager(self, baseName, position, radius, useCenter),
            EngineerManager = EngineerManager.CreateEngineerManager(self, baseName, position, radius),
            StrategyManager = StratManager.CreateStrategyManager(self, baseName, position, radius),
            BuilderHandles = {},
            Position = position,
            BaseType = Scenario.MasterChain._MASTERCHAIN_.Markers[baseName].type or 'MAIN',
            Layer = baseLayer,
        }
        self.NumBases = self.NumBases + 1
    end,

    ---@param self AIBrain
    ---@param category EntityCategory
    ---@return integer
    GetEngineerManagerUnitsBeingBuilt = function(self, category)
        local unitCount = 0
        for k, v in self.BuilderManagers do
            unitCount = unitCount + TableGetn(v.EngineerManager:GetEngineersBuildingCategory(category, categories.ALLUNITS))
        end
        return unitCount
    end,

    ---@param self AIBrain
    GetFactoriesBeingBuilt = function(self)
        local unitCount = 0

        -- Units queued up
        for k, v in self.BuilderManagers do
            unitCount = unitCount + TableGetn(v.EngineerManager:GetEngineersQueued('T1LandFactory'))
        end
        return unitCount
    end,

    ---@param self AIBrain
    UnderEnergyThreshold = function(self)
        self:SetupOverEnergyStatTrigger(0.1)
        for k, v in self.BuilderManagers do
           v.EngineerManager:LowEnergy()
        end
    end,

    ---@param self AIBrain
    OverEnergyThreshold = function(self)
        self:SetupUnderEnergyStatTrigger(0.05)
        for k, v in self.BuilderManagers do
            v.EngineerManager:RestoreEnergy()
        end
    end,

    ---@param self AIBrain
    UnderMassThreshold = function(self)
        self:SetupOverMassStatTrigger(0.1)
        for k, v in self.BuilderManagers do
            v.EngineerManager:LowMass()
        end
    end,

    ---@param self AIBrain
    OverMassThreshold = function(self)
        self:SetupUnderMassStatTrigger(0.05)
        for k, v in self.BuilderManagers do
            v.EngineerManager:RestoreMass()
        end
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderEnergyStatTrigger = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderEnergyThreshold, self, 'SkirmishUnderEnergyThreshold',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverEnergyStatTrigger = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverEnergyThreshold, self, 'SkirmishOverEnergyThreshold',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderMassStatTrigger = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderMassThreshold, self, 'SkirmishUnderMassThreshold',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverMassStatTrigger = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverMassThreshold, self, 'SkirmishOverMassThreshold',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    GetStartVector3f = function(self)
        local startX, startZ = self:GetArmyStartPos()
        return {startX, 0, startZ}
    end,

    ---@param self AIBrain
    CalculateLayerPreference = function(self)
        local personality = self:GetPersonality()
        local factionIndex = self:GetFactionIndex()

        -- SET WHAT THE AI'S LAYER PREFERENCE IS
        local airpref = personality:GetAirUnitsEmphasis() * 100
        local tankpref = personality:GetTankUnitsEmphasis() * 100
        local botpref = personality:GetBotUnitsEmphasis() * 100
        local seapref = personality:GetSeaUnitsEmphasis() * 100
        local landpref = tankpref
        if tankpref < botpref then
            landpref = botpref
        end

        -- SEA PREF COMMENTED OUT FOR NOW
        local totalpref = landpref + airpref  + seapref
        totalpref = totalpref
        local random = Random(0, totalpref)
        if random < landpref then
            self.LayerPref = 'LAND'
        elseif random < (landpref + airpref) then
            self.LayerPref = 'AIR'
        else
            self.LayerPref = 'LAND'
        end
    end,

    ---@param self AIBrain
    AIGetLayerPreference = function(self)
        return self.LayerPref
    end,

    --- ## ECONOMY MONITOR
    --- Monitors the economy over time for skirmish; allows better trend analysis
    ---@param self AIBrain
    EconomyMonitor = function(self)
        -- This over time thread is based on Sprouto's LOUD AI.
        self.EconomyData = { ['EnergyIncome'] = {}, ['EnergyRequested'] = {}, ['EnergyStorage'] = {}, ['EnergyTrend'] = {}, ['MassIncome'] = {}, ['MassRequested'] = {}, ['MassStorage'] = {}, ['MassTrend'] = {}, ['Period'] = self.EconomyTicksMonitor }
        -- number of sample points
        -- local point
        local samplerate = 10
        local samples = self.EconomyData['Period'] / samplerate

        -- create the table to store the samples
        for point = 1, samples do
            self.EconomyData['EnergyIncome'][point] = 0
            self.EconomyData['EnergyRequested'][point] = 0
            self.EconomyData['EnergyStorage'][point] = 0
            self.EconomyData['EnergyTrend'][point] = 0
            self.EconomyData['MassIncome'][point] = 0
            self.EconomyData['MassRequested'][point] = 0
            self.EconomyData['MassStorage'][point] = 0
            self.EconomyData['MassTrend'][point] = 0
        end    

        -- array totals
        local eIncome = 0
        local mIncome = 0
        local eRequested = 0
        local mRequested = 0
        local eStorage = 0
        local mStorage = 0
        local eTrend = 0
        local mTrend = 0

        -- this will be used to multiply the totals
        -- to arrive at the averages
        local samplefactor = 1/samples

        local EcoData = self.EconomyData

        local EcoDataEnergyIncome = EcoData['EnergyIncome']
        local EcoDataMassIncome = EcoData['MassIncome']
        local EcoDataEnergyRequested = EcoData['EnergyRequested']
        local EcoDataMassRequested = EcoData['MassRequested']
        local EcoDataEnergyTrend = EcoData['EnergyTrend']
        local EcoDataMassTrend = EcoData['MassTrend']
        local EcoDataEnergyStorage = EcoData['EnergyStorage']
        local EcoDataMassStorage = EcoData['MassStorage']

        local e,m

        while true do

            for point = 1, samples do

                -- remove this point from the totals
                eIncome = eIncome - EcoDataEnergyIncome[point]
                mIncome = mIncome - EcoDataMassIncome[point]
                eRequested = eRequested - EcoDataEnergyRequested[point]
                mRequested = mRequested - EcoDataMassRequested[point]
                eTrend = eTrend - EcoDataEnergyTrend[point]
                mTrend = mTrend - EcoDataMassTrend[point]

                -- insert the new data --
                EcoDataEnergyIncome[point] = GetEconomyIncome( self, 'ENERGY')
                EcoDataMassIncome[point] = GetEconomyIncome( self, 'MASS')
                EcoDataEnergyRequested[point] = GetEconomyRequested( self, 'ENERGY')
                EcoDataMassRequested[point] = GetEconomyRequested( self, 'MASS')

                e = GetEconomyTrend( self, 'ENERGY')
                m = GetEconomyTrend( self, 'MASS')

                if e then
                    EcoDataEnergyTrend[point] = e
                else
                    EcoDataEnergyTrend[point] = 0.1
                end

                if m then
                    EcoDataMassTrend[point] = m
                else
                    EcoDataMassTrend[point] = 0.1
                end

                -- add the new data to totals
                eIncome = eIncome + EcoDataEnergyIncome[point]
                mIncome = mIncome + EcoDataMassIncome[point]
                eRequested = eRequested + EcoDataEnergyRequested[point]
                mRequested = mRequested + EcoDataMassRequested[point]
                eTrend = eTrend + EcoDataEnergyTrend[point]
                mTrend = mTrend + EcoDataMassTrend[point]

                -- calculate new OverTime values --
                self.EconomyOverTimeCurrent.EnergyIncome = eIncome * samplefactor
                self.EconomyOverTimeCurrent.MassIncome = mIncome * samplefactor
                self.EconomyOverTimeCurrent.EnergyRequested = eRequested * samplefactor
                self.EconomyOverTimeCurrent.MassRequested = mRequested * samplefactor
                self.EconomyOverTimeCurrent.EnergyEfficiencyOverTime = math.min( (eIncome * samplefactor) / (eRequested * samplefactor), 2)
                self.EconomyOverTimeCurrent.MassEfficiencyOverTime = math.min( (mIncome * samplefactor) / (mRequested * samplefactor), 2)
                self.EconomyOverTimeCurrent.EnergyTrendOverTime = eTrend * samplefactor
                self.EconomyOverTimeCurrent.MassTrendOverTime = mTrend * samplefactor

                coroutine.yield(samplerate)
            end
        end
    end,

    ---@param self AIBrain
    ---@return table
    GetEconomyOverTime = function(self)

        local retTable = {}
        retTable.EnergyIncome = self.EconomyOverTimeCurrent.EnergyIncome or 0
        retTable.MassIncome = self.EconomyOverTimeCurrent.MassIncome or 0
        retTable.EnergyRequested = self.EconomyOverTimeCurrent.EnergyRequested or 0
        retTable.MassRequested = self.EconomyOverTimeCurrent.MassRequested or 0

        return retTable
    end,

    ---@param self AIBrain
    ---@param attackDataTable table
    InitializeAttackManager = function(self, attackDataTable)
        self.AttackManager = import("/lua/ai/attackmanager.lua").AttackManager(self, attackDataTable)
        self.AttackData = self.AttackManager
    end,

    ---@param self AIBrain
    ---@param spec any
    AMAddPlatoon = function(self, spec)
        self.AttackManager:AddPlatoon(spec)
    end,

    ---@param self AIBrain
    AMPauseAttackManager = function(self)
        self.AttackManager:PauseAttackManager()
    end,

    ---## AI PLATOON MANAGEMENT
    ---### New PlatoonBuildManager
    ---This system is meant to be able to give some data about the platoon you want and have them
    ---built and formed into platoons at will.
    ---@param self AIBrain
    InitializePlatoonBuildManager = function(self)
        if not self.PBM then
            ---@class AiPlatoonBuildManager
            self.PBM = {
                BuildCheckInterval = nil,
                Platoons = {
                    Air = {},
                    Land = {},
                    Sea = {},
                    Gate = {},
                },
                Locations = {
                    -- {
                    --  Location,
                    --  Radius,
                    --  LocType, ('MAIN', 'EXPANSION')
                    --  PrimaryFactories = {Air = X, Land = Y, Sea = Z}
                    --  UseCenterPoint, - Bool
                    --}
                },
                PlatoonTypes = {'Air', 'Land', 'Sea', 'Gate'},
                NeedSort = {
                    ['Air'] = false,
                    ['Land'] = false,
                    ['Sea'] = false,
                    ['Gate'] = false,
                },
                RandomSamePriority = false,
                BuildConditionsTable = {},
            }
            -- Create basic starting area
            local strtX, strtZ = self:GetArmyStartPos()
            self:PBMAddBuildLocation({strtX, 20, strtZ}, 100, 'MAIN')

            -- TURNING OFF AI POOL PLATOON, I MAY JUST REMOVE THAT PLATOON FUNCTIONALITY LATER
            local poolPlatoon = self:GetPlatoonUniquelyNamed('ArmyPool')
            if poolPlatoon then
                poolPlatoon:TurnOffPoolAI()
            end
            self.HasPlatoonList = false
            self:PBMSetEnabled(true)
        end
    end,

    ---@param self AIBrain
    ---@param enable boolean
    PBMSetEnabled = function(self, enable)
        if not self.PBMThread and enable then
            self.PBMThread = self:ForkThread(self.PlatoonBuildManagerThread)
        else
            KillThread(self.PBMThread)
            self.PBMThread = nil
        end
    end,

    --- # Platoon Spec
    ---```lua 
    ---{
    ---PlatoonTemplate = platoon template,
    ---InstanceCount = number of duplicates to place in the platoon list
    ---Priority = integer,
    ---BuildConditions = list of functions that return true/false, list of args, {< function>, {<args>}}
    ---LocationType = string for type of location, setup via addnewlocation function,
    ---BuildTimeOut = how long it'll try to form this platoon after it's been told to build.,
    ---PlatoonType = 'Air'/'Land'/'Sea' basic type of unit, used for finding what type of factory to build from,
    ---RequiresConstruction = true/false do I need to build this from a factory or should I just try to form it?,
    ---PlatoonBuildCallbacks = {FunctionsToCallBack when the platoon starts to build}
    ---PlatoonAIFunction = if nil uses function in platoon.lua, function for the main AI thread
    ---PlatoonAddFunctions = {<other threads to be forked on this platoon>}
    ---
    ---PlatoonData = {
    ---    Construction = {
    ---        BaseTemplate = basetemplates, must contain templates for all 3 factions it will be viewed by faction index,
    ---        BuildingTemplate = building templates, contain templates for all 3 factions it will be viewed by faction index,
    ---        BuildClose = true/false do I follow the table order or do build the best spot near me?
    ---        BuildRelative = true/false are the build coordinates relative to the starting location or absolute coords?,
    ---        BuildStructures = {List of structure types and the order to build them.}
    ---     }
    ---}
    ---},
    --- ```
    ---@param self AIBrain
    ---@param pltnTable PlatoonTable
    PBMAddPlatoon = function(self, pltnTable)
        if not pltnTable.PlatoonTemplate then
            local stng = '*AI ERROR: INVALID PLATOON LIST IN '.. self.CurrentPlan.. ' - MISSING TEMPLATE.  '
            error(stng, 1)
            return
        end

        if pltnTable.RequiresConstruction == nil then
            error('*AI ERROR: INVALID PLATOON LIST IN ' .. self.CurrentPlan .. ' - MISSING RequiresConstruction', 1)
            return
        end

        if not pltnTable.Priority then
            error('*AI ERROR: INVALID PLATOON LIST IN ' .. self.CurrentPlan .. ' - MISSING PRIORITY', 1)
            return
        end

        if not pltnTable.BuildConditions then
            pltnTable.BuildConditions = {}
        end

        if not pltnTable.BuildTimeOut or pltnTable.BuildTimeOut == 0 then
            pltnTable.GenerateTimeOut = true
        end

        local num = 1
        if pltnTable.InstanceCount and pltnTable.InstanceCount > 1 then
            num = pltnTable.InstanceCount
        end

        if not ScenarioInfo.BuilderTable[self.CurrentPlan] then
            ScenarioInfo.BuilderTable[self.CurrentPlan] = {Air = {}, Sea = {}, Land = {}, Gate = {}}
        end

        if pltnTable.PlatoonType ~= 'Any' then
            if not ScenarioInfo.BuilderTable[self.CurrentPlan][pltnTable.PlatoonType][pltnTable.BuilderName] then
                ScenarioInfo.BuilderTable[self.CurrentPlan][pltnTable.PlatoonType][pltnTable.BuilderName] = pltnTable
            elseif not pltnTable.Inserted then
                error('AI DEBUG: BUILDER DUPLICATE NAME FOUND - ' .. pltnTable.BuilderName, 2)
            end
            local insertTable = {BuilderName = pltnTable.BuilderName, PlatoonHandles = {}, Priority = pltnTable.Priority, LocationType = pltnTable.LocationType, PlatoonTemplate = pltnTable.PlatoonTemplate}
            for i = 1, num do
                table.insert(insertTable.PlatoonHandles, false)
            end

            table.insert(self.PBM.Platoons[pltnTable.PlatoonType], insertTable)
            self.PBM.NeedSort[pltnTable.PlatoonType] = true
        else
            local insertTable = {BuilderName = pltnTable.BuilderName, PlatoonHandles = {}, Priority = pltnTable.Priority, LocationType = pltnTable.LocationType, PlatoonTemplate = pltnTable.PlatoonTemplate}
            for i = 1, num do
                table.insert(insertTable.PlatoonHandles, false)
            end
            local types = {'Air', 'Land', 'Sea'}
            for num, pType in types do
                if not ScenarioInfo.BuilderTable[self.CurrentPlan][pType][pltnTable.BuilderName] then
                    ScenarioInfo.BuilderTable[self.CurrentPlan][pType][pltnTable.BuilderName] = pltnTable
                elseif not pltnTable.Inserted then
                    error('AI DEBUG: BUILDER DUPLICATE NAME FOUND - ' .. pltnTable.BuilderName, 2)
                end
                table.insert(self.PBM.Platoons[pType], insertTable)
                self.PBM.NeedSort[pType] = true
            end
        end

        self.HasPlatoonList = true
    end,

    ---@param self AIBrain
    ---@param builderName string
    PBMRemoveBuilder = function(self, builderName)
        for pType, builders in self.PBM.Platoons do
            for num, data in builders do
                if data.BuilderName == builderName then
                    self.PBM.Platoons[pType][num] = nil
                    ScenarioInfo.BuilderTable[self.CurrentPlan][pType][builderName] = nil
                    break
                end
            end
        end
    end,

    --- Function to clear all the platoon lists so you can feed it a bunch more.
    --- - formPlatoons - Gives you the option to form all the platoons in the list before its cleaned up so that you don't have units hanging around.
    ---@param self AIBrain
    ---@param formPlatoons? Platoon
    PBMClearPlatoonList = function(self, formPlatoons)
        if formPlatoons then
            for _, v in self.PBM.PlatoonTypes do
                self:PBMFormPlatoons(false, v)
            end
        end
        self.PBM.NeedSort['Air'] = false
        self.PBM.NeedSort['Land'] = false
        self.PBM.NeedSort['Sea'] = false
        self.PBM.NeedSort['Gate'] = false
        self.HasPlatoonList = false
        self.PBM.Platoons = {
            Air = {},
            Land = {},
            Sea = {},
            Gate = {},
        }
    end,

    ---@param self AIBrain
    ---@param location string
    ---@return boolean
    PBMFormAllPlatoons = function(self, location)
        local locData = self:PBMGetLocation(location)
        if not locData then
            return false
        end
        for _, v in self.PBM.PlatoonTypes do
            self:PBMFormPlatoons(true, v, locData)
        end
    end,

    ---@param self AIBrain
    ---@return boolean
    PBMHasPlatoonList = function(self)
        return self.HasPlatoonList
    end,

    ---@param self AIBrain
    PBMResetPrimaryFactories = function(self)
        for _, v in self.PBM.Locations do
            v.PrimaryFactories.Air = nil
            v.PrimaryFactories.Land = nil
            v.PrimaryFactories.Sea = nil
            v.PrimaryFactories.Gate = nil
        end
    end,

    ---Goes through the location areas, finds the factories, sets a primary then tells all the others to guard.
    ---@param self AIBrain
    PBMSetPrimaryFactories = function(self)
        for _, v in self.PBM.Locations do
            local factories = self:GetAvailableFactories(v.Location, v.Radius)
            local airFactories = {}
            local landFactories = {}
            local seaFactories = {}
            local gates = {}
            for ek, ev in factories do
                if EntityCategoryContains(categories.FACTORY * categories.AIR, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(airFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.LAND, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(landFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.NAVAL, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(seaFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.GATE, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(gates, ev)
                end
            end

            local afac, lfac, sfac, gatefac
            if not table.empty(airFactories) then
                if not v.PrimaryFactories.Air or v.PrimaryFactories.Air.Dead
                    or v.PrimaryFactories.Air:IsUnitState('Upgrading')
                    or self:PBMCheckHighestTechFactory(airFactories, v.PrimaryFactories.Air) then
                        afac = self:PBMGetPrimaryFactory(airFactories)
                        v.PrimaryFactories.Air = afac
                end
                self:PBMAssistGivenFactory(airFactories, v.PrimaryFactories.Air)
            end

            if not table.empty(landFactories) then
                if not v.PrimaryFactories.Land or v.PrimaryFactories.Land.Dead
                    or v.PrimaryFactories.Land:IsUnitState('Upgrading')
                    or self:PBMCheckHighestTechFactory(landFactories, v.PrimaryFactories.Land) then
                        lfac = self:PBMGetPrimaryFactory(landFactories)
                        v.PrimaryFactories.Land = lfac
                end
                self:PBMAssistGivenFactory(landFactories, v.PrimaryFactories.Land)
            end

            if not table.empty(seaFactories) then
                if not v.PrimaryFactories.Sea or v.PrimaryFactories.Sea.Dead
                    or v.PrimaryFactories.Sea:IsUnitState('Upgrading')
                    or self:PBMCheckHighestTechFactory(seaFactories, v.PrimaryFactories.Sea) then
                        sfac = self:PBMGetPrimaryFactory(seaFactories)
                        v.PrimaryFactories.Sea = sfac
                end
                self:PBMAssistGivenFactory(seaFactories, v.PrimaryFactories.Sea)
            end

            if not table.empty(gates) then
                if not v.PrimaryFactories.Gate or v.PrimaryFactories.Gate.Dead then
                    gatefac = self:PBMGetPrimaryFactory(gates)
                    v.PrimaryFactories.Gate = gatefac
                end
                self:PBMAssistGivenFactory(gates, v.PrimaryFactories.Gate)
            end

            if not v.RallyPoint or table.empty(v.RallyPoint) then
                self:PBMSetRallyPoint(airFactories, v, nil)
                self:PBMSetRallyPoint(landFactories, v, nil)
                self:PBMSetRallyPoint(seaFactories, v, nil)
                self:PBMSetRallyPoint(gates, v, nil)
            end
        end
    end,

    ---@param self AIBrain
    ---@param factories Unit
    ---@param primary Unit
    PBMAssistGivenFactory = function(self, factories, primary)
        for _, v in factories do
            if not v.Dead and not (v:IsUnitState('Building') or v:IsUnitState('Upgrading')) then
                local guarded = v:GetGuardedUnit()
                if not guarded or guarded.EntityId ~= primary.EntityId then
                    IssueClearCommands({v})
                    IssueFactoryAssist({v}, primary)
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param factories Unit
    ---@param location Vector
    ---@param rallyLoc Vector
    ---@param markerType string
    ---@return boolean
    PBMSetRallyPoint = function(self, factories, location, rallyLoc, markerType)
        if not table.empty(factories) then
            local rally
            local position = factories[1]:GetPosition()
            for facNum, facData in factories do
                if facNum > 1 then
                    position[1] = position[1] + facData:GetPosition()[1]
                    position[3] = position[3] + facData:GetPosition()[3]
                end
            end

            position[1] = position[1] / TableGetn(factories)
            position[3] = position[3] / TableGetn(factories)
            if not rallyLoc and not location.UseCenterPoint then
                local pnt
                if not markerType then
                    pnt = AIUtils.AIGetClosestMarkerLocation(self, 'Rally Point', position[1], position[3])
                else
                    pnt = AIUtils.AIGetClosestMarkerLocation(self, markerType, position[1], position[3])
                end
                if pnt and TableGetn(pnt) == 3 then
                    rally = Vector(pnt[1], pnt[2], pnt[3])
                end
            elseif not rallyLoc and location.UseCenterPoint then
                rally = location.Location
            elseif rallyLoc then
                rally = rallyLoc
            else
                error('*ERROR: PBMSetRallyPoint - Missing Rally Location and Marker Type', 2)
                return false
            end

            if rally then
                for _, v in factories do
                    IssueClearFactoryCommands({v})
                    IssueFactoryRallyPoint({v}, rally)
                end
            end
        end
        return true
    end,

    ---@param self AIBrain
    ---@param factory Unit
    ---@param location Vector
    ---@return boolean
    PBMFactoryLocationCheck = function(self, factory, location)
        -- If passed in a PBM Location table or location type name
        local locationName = location
        local locationPosition
        if type(location) == 'table' then
            locationName = location.LocationType
        end
        if not factory.PBMData then
            factory.PBMData = {}
        end
        -- Calculate distance to a location type if it doesn't exist yet
        if not factory.PBMData[locationName] then
            -- Location of the factory
            local pos = factory:GetPosition()
            -- Find location of the PBM Location Type
            local locationPosition
            if type(location) == 'table' then
                locationPosition = location.Location
            else
                locationPosition = self:PBMGetLocationCoords(locationName)
            end
            factory.PBMData[locationName] = VDist2(locationPosition[1], locationPosition[3], pos[1], pos[3])
        end

        local closest, distance
        for k, v in factory.PBMData do
            if not distance or v < distance then
                distance = v
                closest = k
            end
        end

        if closest and closest == locationName then
            return true
        else
            return false
        end
    end,

    ---@param self AIBrain
    ---@param factories Unit
    ---@param primary Unit[]
    ---@return boolean
    PBMCheckHighestTechFactory = function(self, factories, primary)
        local catTable = {categories.TECH1, categories.TECH2, categories.TECH3}
        local catLevel = 1
        if EntityCategoryContains(categories.TECH3, primary) then
            catLevel = 3
        elseif EntityCategoryContains(categories.TECH2, primary) then
            catLevel = 2
        end

        for catNum, cat in catTable do
            if catNum > catLevel then
                for unitNum, unit in factories do
                    if not unit.Dead and EntityCategoryContains(cat, unit) and not unit:IsUnitState('Upgrading') then
                        return true
                    end
                end
            end
        end
        return false
    end,

    ---Picks the first tech 3, tech 2 or tech 1 factory to make primary
    ---@param self AIBrain
    ---@param factories Unit
    ---@return Unit
    PBMGetPrimaryFactory = function(self, factories)
        local categoryTable = {categories.TECH3, categories.TECH2, categories.TECH1}
        for kc, vc in categoryTable do
            for k, v in factories do
                if EntityCategoryContains(vc, v) and not v:IsUnitState('Upgrading') then
                    return v
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@return number
    PBMGetPriority = function(self, platoon)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if v.PlatoonHandles then
                    for num, plat in v.PlatoonHandles do
                        if plat and plat == platoon then
                            return v.Priority
                        end
                    end
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@param amount number
    ---@return boolean
    PBMAdjustPriority = function(self, platoon, amount)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
                    return false
                end
                for num, plat in v.PlatoonHandles do
                    if plat == platoon then
                        if typev == 'Any' then
                            self.PBM.NeedSort['Air'] = true
                            self.PBM.NeedSort['Sea'] = true
                            self.PBM.NeedSort['Land'] = true
                        else
                            self.PBM.NeedSort[typev] = true
                        end
                        v.Priority = v.Priority + amount
                    end
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@param amount number
    ---@return boolean
    PBMSetPriority = function(self, platoon, amount)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
                    return false
                end
                for num, plat in v.PlatoonHandles do
                    if plat == platoon then
                        if typev == 'Any' then
                            self.PBM.NeedSort['Air'] = true
                            self.PBM.NeedSort['Sea'] = true
                            self.PBM.NeedSort['Land'] = true
                        else
                            self.PBM.NeedSort[typev] = true
                        end
                        v.Priority = amount
                    end
                end
            end
        end
    end,

    ---Adds a new build location
    ---@param self AIBrain
    ---@param loc Vector
    ---@param radius number
    ---@param locType string
    ---@param useCenterPoint? boolean
    ---@return boolean
    PBMAddBuildLocation = function(self, loc, radius, locType, useCenterPoint)
        if not radius or not loc or not locType then
            error('*AI ERROR: INVALID BUILD LOCATION FOR PBM', 2)
            return false
        end
        if type(loc) == 'string' then
            loc = ScenarioUtils.MarkerToPosition(loc)
        end

        useCenterPoint = useCenterPoint or false
        local spec = {
            Location = loc,
            Radius = radius,
            LocationType = locType,
            PrimaryFactories = {Air = nil, Land = nil, Sea = nil, Gate = nil},
            UseCenterPoint = useCenterPoint,
        }

        local found = false
        for num, loc in self.PBM.Locations do
            if loc.LocationType == spec.LocationType then
                found = true
                break
            end
        end

        if not found then
            table.insert(self.PBM.Locations, spec)
        else
            error('*AI  ERROR: Attempting to add a build location with a duplicate name: '..spec.LocationType, 2)
            return
        end
    end,

    ---@param self AIBrain
    ---@param locationName string
    ---@return boolean
    PBMGetLocation = function(self, locationName)
        if self.HasPlatoonList then
            for _, v in self.PBM.Locations do
                if v.LocationType == locationName then
                    return v
                end
            end
        end
        return false
    end,

    ---@param self AIBrain
    ---@param loc Vector
    ---@return Vector | false
    PBMGetLocationCoords = function(self, loc)
        if not loc then
            return false
        end
        if self.HasPlatoonList then
            for _, v in self.PBM.Locations do
                if v.LocationType == loc then
                    local height = GetTerrainHeight(v.Location[1], v.Location[3])
                    if GetSurfaceHeight(v.Location[1], v.Location[3]) > height then
                        height = GetSurfaceHeight(v.Location[1], v.Location[3])
                    end
                    return {v.Location[1], height, v.Location[3]}
                end
            end
        elseif self.BuilderManagers[loc] then
            return self.BuilderManagers[loc].FactoryManager:GetLocationCoords()
        end
        return false
    end,

    ---@param self AIBrain
    ---@param loc Vector
    ---@return boolean
    PBMGetLocationRadius = function(self, loc)
        if not loc then
            return false
        end
        if self.HasPlatoonList then
            for k, v in self.PBM.Locations do
                if v.LocationType == loc then
                   return v.Radius
                end
            end
        elseif self.BuilderManagers[loc] then
            return self.BuilderManagers[loc].FactoryManager.Radius
        end
        return false
    end,

    ---@param self AIBrain
    ---@param location Vector
    ---@return boolean
    PBMGetLocationFactories = function(self, location)
        if not location then
            return false
        end
        for k, v in self.PBM.Locations do
            if v.LocationType == location then
                return v.PrimaryFactories
            end
        end
        return false
    end,

    ---@param self AIBrain
    ---@param location Vector
    ---@return FactoryUnit[] | false
    PBMGetAllFactories = function(self, location)
        if not location then
            return false
        end
        for num, loc in self.PBM.Locations do
            if loc.LocationType == location then
                local facs = {}
                for k, v in loc.PrimaryFactories do
                    table.insert(facs, v)
                    if not v.Dead then
                        for fNum, fac in v:GetGuards() do
                            if EntityCategoryContains(categories.FACTORY, fac) then
                                table.insert(facs, fac)
                            end
                        end
                    end
                end
                return facs
            end
        end
        return false
    end,

    --- Removes a build location based on it area
    --- IF either is nil, then it will do the other.
    --- This way you can remove all of one type or all of one rectangle
    ---@param self AIBrain
    ---@param loc Vector
    ---@param locType string
    PBMRemoveBuildLocation = function(self, loc, locType)
        for k, v in self.PBM.Locations do
            if (loc and v.Location == loc) or (locType and v.LocationType == locType) then
                table.remove(self.PBM.Locations, k)
            end
        end
    end,

    --- Sort platoon list
    ---@param self AIBrain
    ---@param platoonType PlatoonType
    ---@return boolean
    PBMSortPlatoonsViaPriority = function(self, platoonType)
         if platoonType ~= 'Air' and platoonType ~= 'Land' and platoonType ~= 'Sea' and platoonType ~= 'Gate' then
            local strng = '*AI ERROR: TRYING TO SORT PLATOONS VIA PRIORITY BUT AN INVALID TYPE (', repr(platoonType), ') WAS PASSED IN.'
            error(strng, 2)
            return false
        end
        local sortedList = {}
        -- Simple selection sort, this can be made faster later if we decide we need it.
        for i = 1, TableGetn(self.PBM.Platoons[platoonType]) do
            local highest = 0
            local key, value
            for k, v in self.PBM.Platoons[platoonType] do
                if v.Priority > highest then
                    highest = v.Priority
                    value = v
                    key = k
                end
            end
            sortedList[i] = value
            table.remove(self.PBM.Platoons[platoonType], key)
        end
        self.PBM.Platoons[platoonType] = sortedList
        self.PBM.NeedSort[platoonType] = false
    end,

    ---@param self AIBrain
    ---@param interval number
    PBMSetCheckInterval = function(self, interval)
        self.PBM.BuildCheckInterval = interval
    end,

    ---@param self AIBrain
    PBMEnableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = true
    end,

    ---@param self AIBrain
    PBMDisableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = false
    end,

    ---@param self AIBrain
    PBMCheckBusyFactories = function(self)
        local busyPlat = self:GetPlatoonUniquelyNamed('BusyFactories')
        if not busyPlat then
            busyPlat = self:MakePlatoon('', '')
            busyPlat:UniquelyNamePlatoon('BusyFactories')
        end

        local poolPlat = self:GetPlatoonUniquelyNamed('ArmyPool')
        local poolTransfer = {}
        for _, v in poolPlat:GetPlatoonUnits() do
            if not v.Dead and EntityCategoryContains(categories.FACTORY - categories.MOBILE, v) then
                if v:IsUnitState('Building') or v:IsUnitState('Upgrading') then
                    table.insert(poolTransfer, v)
                end
            end
        end

        local busyTransfer = {}
        for _, v in busyPlat:GetPlatoonUnits() do
            if not v.Dead and not v:IsUnitState('Building') and not v:IsUnitState('Upgrading') then
                table.insert(busyTransfer, v)
            end
        end

        self:AssignUnitsToPlatoon(poolPlat, busyTransfer, 'Unassigned', 'None')
        self:AssignUnitsToPlatoon(busyPlat, poolTransfer, 'Unassigned', 'None')
    end,

    ---@param self AIBrain
    PBMUnlockStartThread = function(self)
        WaitSeconds(1)
        ScenarioInfo.PBMStartLock = false
    end,

    ---@param self AIBrain
    PBMUnlockStart = function(self)
        while ScenarioInfo.PBMStartLock do
            WaitTicks(1)
        end
        ScenarioInfo.PBMStartLock = true

        -- Fork a separate thread that unlocks after a second, but this brain continues on
        self:ForkThread(self.PBMUnlockStartThread)
    end,

    ---@param self AIBrain
    ---@param builderData table
    ---@return boolean
    PBMHandleAvailable = function(self, builderData)
        if not builderData.PlatoonHandles then
            return false
        end
        for _, v in builderData.PlatoonHandles do
            if not v then
                return true
            end
        end
        return false
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@param builderData table
    ---@return boolean
    PBMStoreHandle = function(self, platoon, builderData)
        if not builderData.PlatoonHandles then
            return false
        end
        for k, v in builderData.PlatoonHandles do
            if v == 'BUILDING' then
                builderData.PlatoonHandles[k] = platoon
                return true
            end
        end
        for k, v in builderData.PlatoonHandles do
            if not v then
                builderData.PlatoonHandles[k] = platoon
                return true
            end
        end
        error('*AI DEBUG: Error trying to store a PBM platoon')

        return false
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@return boolean
    PBMRemoveHandle = function(self, platoon)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
                    return false
                end
                for num, plat in v.PlatoonHandles do
                    if plat == platoon then
                        v.PlatoonHandles[num] = false
                    end
                end
            end
        end
    end,

    ---@param self AIBrain
    ---@param builder Unit
    ---@return boolean
    PBMSetHandleBuilding = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
            return false
        end
        for k, v in builder.PlatoonHandles do
            if not v then
                builder.PlatoonHandles[k] = 'BUILDING'
                return true
            end
        end
        error('*AI DEBUG: No handle spot empty! - ' .. builder.BuilderName)

        return false
    end,

    ---@param self AIBrain
    ---@param builder Unit
    ---@return boolean
    PBMCheckHandleBuilding = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
            return false
        end
        for k, v in builder.PlatoonHandles do
            if v == 'BUILDING' then
                return true
            end
        end
        return false
    end,

    ---@param self AIBrain
    ---@param builder Unit
    ---@return boolean
    PBMSetBuildingHandleFalse = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
            return false
        end
        for k, v in builder.PlatoonHandles do
            if v == 'BUILDING' then
                builder.PlatoonHandles[k] = false
                return true
            end
        end
        return false
    end,

    ---@param self AIBrain
    ---@param builder Unit
    ---@return integer
    PBMNumHandlesAvailable = function(self, builder)
        local numAvail = 0
        for k, v in builder.PlatoonHandles do
            if v == false then
                numAvail = numAvail + 1
            end
        end
        return numAvail
    end,

    -- Main building and forming platoon thread for the Platoon Build Manager
    ---@param self AIBrain
    PlatoonBuildManagerThread = function(self)
        local personality = self:GetPersonality()
        local armyIndex = self:GetArmyIndex()

        -- Split the brains up a bit so they aren't all doing the PBM thread at the same time
        if not self.PBMStartUnlocked then
            self:PBMUnlockStart()
        end

        while true do
            self:PBMCheckBusyFactories()
            if self.BrainType == 'AI' then
                self:PBMSetPrimaryFactories()
            end
            local platoonList = self.PBM.Platoons
            -- clear the cache so we can get fresh new responses!
            self:PBMClearBuildConditionsCache()
            -- Go through the different types of platoons
            for typek, typev in self.PBM.PlatoonTypes do
                -- First go through the list of locations and see if we can build stuff there.
                for k, v in self.PBM.Locations do
                    -- See if we have platoons to build in that type
                    if not table.empty(platoonList[typev]) then
                        -- Sort the list of platoons via priority
                        if self.PBM.NeedSort[typev] then
                            self:PBMSortPlatoonsViaPriority(typev)
                        end
                        -- FORM PLATOONS
                        self:PBMFormPlatoons(true, typev, v)
                        -- BUILD PLATOONS
                        -- See if our primary factory is busy.
                        if v.PrimaryFactories[typev] then
                            local priFac = v.PrimaryFactories[typev]
                            local numBuildOrders = nil
                            if priFac and not priFac.Dead then
                                numBuildOrders = priFac:GetNumBuildOrders(categories.ALLUNITS)
                                if numBuildOrders == 0 then
                                    local guards = priFac:GetGuards()
                                    if guards and not table.empty(guards) then
                                        for kg, vg in guards do
                                            numBuildOrders = numBuildOrders + vg:GetNumBuildOrders(categories.ALLUNITS)
                                            if numBuildOrders == 0 and vg:IsUnitState('Building') then
                                                numBuildOrders = 1
                                            end
                                            if numBuildOrders > 0 then
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            if numBuildOrders and numBuildOrders == 0 then
                                local possibleTemplates = {}
                                local priorityLevel = false
                                -- Now go through the platoon templates and see which ones we can build.
                                for kp, vp in platoonList[typev] do
                                    -- Don't try to build things that are higher pri than 0
                                    -- This platoon requires construction and isn't just a form-only platoon.
                                    local globalBuilder = ScenarioInfo.BuilderTable[self.CurrentPlan][typev][vp.BuilderName]
                                    if priorityLevel and (vp.Priority ~= priorityLevel or not self.PBM.RandomSamePriority) then
                                            break
                                    elseif (not priorityLevel or priorityLevel == vp.Priority)
                                            and vp.Priority > 0 and globalBuilder.RequiresConstruction and
                                            -- The location we're looking at is an allowed location
                                            (vp.LocationType == v.LocationType or not vp.LocationType) and
                                            -- Make sure there is a handle slot available
                                            (self:PBMHandleAvailable(vp)) then
                                        -- Fix up the primary factories to fit the proper table required by CanBuildPlatoon
                                        local suggestedFactories = {v.PrimaryFactories[typev]}
                                        local factories = self:CanBuildPlatoon(vp.PlatoonTemplate, suggestedFactories)
                                        if factories and self:PBMCheckBuildConditions(globalBuilder.BuildConditions, armyIndex) then
                                            priorityLevel = vp.Priority
                                            for i = 1, self:PBMNumHandlesAvailable(vp) do
                                                table.insert(possibleTemplates, {Builder = vp, Index = kp, Global = globalBuilder})
                                            end
                                        end
                                    end
                                end
                                if priorityLevel then
                                    local builderData = possibleTemplates[ Random(1, TableGetn(possibleTemplates)) ]
                                    local vp = builderData.Builder
                                    local kp = builderData.Index
                                    local globalBuilder = builderData.Global
                                    local suggestedFactories = {v.PrimaryFactories[typev]}
                                    local factories = self:CanBuildPlatoon(vp.PlatoonTemplate, suggestedFactories)
                                    vp.BuildTemplate = self:PBMBuildNumFactories(vp.PlatoonTemplate, v, typev, factories)
                                    local template = vp.BuildTemplate
                                    local factionIndex = self:GetFactionIndex()
                                    -- Check all the requirements to build the platoon
                                    -- The Primary Factory can actually build this platoon
                                    -- The platoon build condition has been met
                                    local ptnSize = personality:GetPlatoonSize()
                                     -- Finally, build the platoon.
                                    self:BuildPlatoon(template, factories, ptnSize)
                                    self:PBMSetHandleBuilding(self.PBM.Platoons[typev][kp])
                                    if globalBuilder.GenerateTimeOut then
                                        vp.BuildTimeOut = self:PBMGenerateTimeOut(globalBuilder, factories, v, typev)
                                    else
                                        vp.BuildTimeOut = globalBuilder.BuildTimeOut
                                    end
                                    vp.PlatoonTimeOutThread = self:ForkThread(self.PBMPlatoonTimeOutThread, vp)
                                    if globalBuilder.PlatoonBuildCallbacks then
                                        for cbk, cbv in globalBuilder.PlatoonBuildCallbacks do
                                            import(cbv[1])[cbv[2]](self, globalBuilder.PlatoonData)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                WaitSeconds(.1)
            end
            -- Do it all over again in 13 seconds.
            WaitSeconds(self.PBM.BuildCheckInterval or 13)
        end
    end,

    --- ## Form platoons
    --- Extracted as it's own function so you can call this to try and form platoons to clean up the pool
    ---@param self AIBrain
    ---@param requireBuilding boolean `true` = platoon must have `'BUILDING'` has its handle, `false` = it'll form any platoon it can
    ---@param platoonType PlatoonType Platoontype is just `'Air'/'Land'/'Sea'`, those are found in the platoon build manager table template.
    ---@param location Vector Location/Radius are where to do this.  If they aren't specified they will grab from anywhere.
    PBMFormPlatoons = function(self, requireBuilding, platoonType, location)
        local platoonList = self.PBM.Platoons
        local personality = self:GetPersonality()
        local armyIndex = self:GetArmyIndex()
        local numBuildOrders = nil
        if location.PrimaryFactories[platoonType] and not location.PrimaryFactories[platoonType].Dead then
            numBuildOrders = location.PrimaryFactories[platoonType]:GetNumBuildOrders(categories.ALLUNITS)
            if numBuildOrders == 0 then
                local guards = location.PrimaryFactories[platoonType]:GetGuards()
                if guards and not table.empty(guards) then
                    for kg, vg in guards do
                        numBuildOrders = numBuildOrders + vg:GetNumBuildOrders(categories.ALLUNITS)
                        if numBuildOrders == 0 and vg:IsUnitState('Building') then
                            numBuildOrders = 1
                        end
                        if numBuildOrders > 0 then
                            break
                        end
                    end
                end
            end
        end
        -- Go through the platoon list to form a platoon
        for kp, vp in platoonList[platoonType] do
            local globalBuilder = ScenarioInfo.BuilderTable[self.CurrentPlan][platoonType][vp.BuilderName]
            -- To build we need to accept the following:
            -- The platoon is required to be in the building state and it is
            -- or The platoon doesn't have a handle and either doesn't require to be building state or doesn't require construction
            -- all that and passes it's build condition function.
            if vp.Priority > 0 and (requireBuilding and self:PBMCheckHandleBuilding(vp)
                    and numBuildOrders and numBuildOrders == 0
                    and (not vp.LocationType or vp.LocationType == location.LocationType))
                    or (((self:PBMHandleAvailable(vp)) and (not requireBuilding or not globalBuilder.RequiresConstruction))
                    and (not vp.LocationType or vp.LocationType == location.LocationType)
                    and self:PBMCheckBuildConditions(globalBuilder.BuildConditions, armyIndex)) then
                local poolPlatoon = self:GetPlatoonUniquelyNamed('ArmyPool')
                local formIt = false
                local template = vp.BuildTemplate
                if not template then
                    template = vp.PlatoonTemplate
                end

                local flipTable = {}
                local squadNum = 3
                while squadNum <= table.getn(template) do
                    if template[squadNum][2] < 0 then
                        table.insert(flipTable, {Squad = squadNum, Value = template[squadNum][2]})
                        template[squadNum][2] = 1
                    end
                    squadNum = squadNum + 1
                end

                if location.Location and location.Radius and vp.LocationType then
                    formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize(), location.Location, location.Radius)
                elseif not vp.LocationType then
                    formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize())
                end

                local ptnSize = personality:GetPlatoonSize()
                if formIt then
                    local hndl
                    if location.Location and location.Radius and vp.LocationType then
                        hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize(), location.Location, location.Radius)
                        self:PBMStoreHandle(hndl, vp)
                        if vp.PlatoonTimeOutThread then
                            vp.PlatoonTimeOutThread:Destroy()
                        end
                    elseif not vp.LocationType then
                        hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize())
                        self:PBMStoreHandle(hndl, vp)
                        if vp.PlatoonTimeOutThread then
                            vp.PlatoonTimeOutThread:Destroy()
                        end
                    end
                    hndl.PlanName = template[2]

                    -- If we have specific AI, fork that AI thread
                    local pltn = self.PBM.Platoons[platoonType][kp]
                    if globalBuilder.PlatoonAIFunction then
                        hndl:StopAI()
                        hndl:ForkAIThread(import(globalBuilder.PlatoonAIFunction[1])[globalBuilder.PlatoonAIFunction[2]])
                    end

                    if globalBuilder.PlatoonAIPlan then
                        hndl:SetAIPlan(globalBuilder.PlatoonAIPlan)
                    end

                    -- If we have additional threads to fork on the platoon, do that as well.
                    if globalBuilder.PlatoonAddPlans then
                        for papk, papv in globalBuilder.PlatoonAddPlans do
                            hndl:ForkThread(hndl[papv])
                        end
                    end

                    if globalBuilder.PlatoonAddFunctions then
                        for pafk, pafv in globalBuilder.PlatoonAddFunctions do
                            hndl:ForkThread(import(pafv[1])[pafv[2]])
                        end
                    end

                    if globalBuilder.PlatoonAddBehaviors then
                        for pafk, pafv in globalBuilder.PlatoonAddBehaviors do
                            hndl:ForkThread(Behaviors[pafv])
                        end
                    end

                    if vp.BuilderName then
                        if self.PlatoonNameCounter[vp.BuilderName] then
                            self.PlatoonNameCounter[vp.BuilderName] = self.PlatoonNameCounter[vp.BuilderName] + 1
                        else
                            self.PlatoonNameCounter[vp.BuilderName] = 1
                        end
                    end

                    hndl:AddDestroyCallback(self.PBMPlatoonDestroyed)
                    hndl.BuilderName = vp.BuilderName
                    if globalBuilder.PlatoonData then
                        hndl:SetPlatoonData(globalBuilder.PlatoonData)
                        if globalBuilder.PlatoonData.AMPlatoons then
                            for _, v in globalBuilder.PlatoonData.AMPlatoons do
                                hndl:SetPartOfAttackForce()
                                break
                            end
                        end
                    end
                end

                for _, v in flipTable do
                    template[v.Squad][2] = v.Value
                end
            end
        end
    end,

    --- Get the primary factory with the lowest order count
    --- This is used for the 'Any' platoon type so we can find any primary factory to build from.
    ---@param self AIBrain
    ---@param location Vector
    ---@return Vector
    GetLowestOrderPrimaryFactory = function(self, location)
        local num
        local fac
        for _, v in self.PBM.PlatoonTypes do
            local priFac = location.PrimaryFactories[v]
            if priFac then
                local ord = priFac:GetNumBuildOrders(categories.ALLUNITS)
                if not num or num > ord then
                    num = ord
                    fac = location.PrimaryFactories[v]
                end
            end
        end
        return fac
    end,

    ---Set number of units to be built as the number of factories in a location
    ---@param self AIBrain
    ---@param template any
    ---@param location Vector
    ---@param pType PlatoonType
    ---@param factory Unit
    ---@return table
    PBMBuildNumFactories = function (self, template, location, pType, factory)
        local retTemplate = table.deepcopy(template)
        local assistFacs = factory[1]:GetGuards()
        table.insert(assistFacs, factory[1])
        local facs = {T1 = 0, T2 = 0, T3 = 0}
        for _, v in assistFacs do
            if EntityCategoryContains(categories.TECH3 * categories.FACTORY, v) then
                facs.T3 = facs.T3 + 1
            elseif EntityCategoryContains(categories.TECH2 * categories.FACTORY, v) then
                facs.T2 = facs.T2 + 1
            elseif EntityCategoryContains(categories.FACTORY, v) then
                facs.T1 = facs.T1 + 1
            end
        end

        -- Handle any squads with a specified build quantity
        local squad = 3
        while squad <= table.getn(retTemplate) do
            if retTemplate[squad][2] > 0 then
                local bp = self:GetUnitBlueprint(retTemplate[squad][1])
                local buildLevel = AIBuildUnits.UnitBuildCheck(bp)
                local remaining = retTemplate[squad][3]
                while buildLevel <= 3 do
                    if facs['T'..buildLevel] > 0 then
                        if facs['T'..buildLevel] < remaining then
                            remaining = remaining - facs['T'..buildLevel]
                            facs['T'..buildLevel] = 0
                            buildLevel = buildLevel + 1
                        else
                            facs['T'..buildLevel] = facs['T'..buildLevel] - remaining
                            buildLevel = 10
                        end
                    else
                        buildLevel = buildLevel + 1
                    end
                end
            end
            squad = squad + 1
        end

        -- Handle squads with programatic build quantity
        squad = 3
        local remainingIds = {T1 = {}, T2 = {}, T3 = {}}
        while squad <= table.getn(retTemplate) do
            if retTemplate[squad][2] < 0 then
                table.insert(remainingIds['T'..AIBuildUnits.UnitBuildCheck(self:GetUnitBlueprint(retTemplate[squad][1])) ], retTemplate[squad][1])
            end
            squad = squad + 1
        end
        local rTechLevel = 3
        while rTechLevel >= 1 do
            for num, unitId in remainingIds['T'..rTechLevel] do
                for tempRow = 3, table.getn(retTemplate) do
                    if retTemplate[tempRow][1] == unitId and retTemplate[tempRow][2] < 0 then
                        retTemplate[tempRow][3] = 0
                        for fTechLevel = rTechLevel, 3 do
                            retTemplate[tempRow][3] = retTemplate[tempRow][3] + (facs['T'..fTechLevel] * math.abs(retTemplate[tempRow][2]))
                            facs['T'..fTechLevel] = 0
                        end
                    end
                end
            end
            rTechLevel = rTechLevel - 1
        end

        -- Remove any IDs with 0 as a build quantity.
        for i = 1, table.getn(retTemplate) do
            if i >= 3 then
                if retTemplate[i][3] == 0 then
                    table.remove(retTemplate, i)
                end
            end
        end

        return retTemplate
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@param factories Unit
    ---@param location Vector
    ---@param pType PlatoonType
    ---@return integer
    PBMGenerateTimeOut = function(self, platoon, factories, location, pType)
        local retBuildTime = 0
        local i = 3
        local numFactories = TableGetn(factories[1]:GetGuards()) + 1
        if numFactories == 0 then
            numFactories = 1
        end

        local template = platoon.PlatoonTemplate
        while i <= TableGetn(template) do
            local unitBuildTime, factoryBuildRate
            local bp = self:GetUnitBlueprint(template[i][1])
            if bp then
                unitBuildTime = self:GetUnitBlueprint(template[i][1]).Economy.BuildTime
            end
            if not unitBuildTime then
                unitBuildTime = 1000
            end
            if not factoryBuildRate then
                factoryBuildRate = 10
            end
            retBuildTime = retBuildTime + (math.ceil(template[i][3] / numFactories) * ((unitBuildTime/factoryBuildRate) * 1.5))
            i = i + 1
        end

        local buildCheck = self.PBM.BuildCheckInterval or 13
        if retBuildTime > 0 then
            return (math.floor(retBuildTime / buildCheck) + 2) * buildCheck + 1
        else
            return 0
        end
    end,

    ---@param self AIBrain
    ---@param location Vector
    ---@param pType PlatoonType
    ---@return integer
    PBMGetNumFactoriesAtLocation = function(self, location, pType)
        local airFactories = {}
        local landFactories = {}
        local seaFactories = {}
        local gates = {}
        local factories = self:GetAvailableFactories(location.Location, location.Radius)
        local numFactories = 0
        for ek, ev in factories do
            if EntityCategoryContains(categories.FACTORY * categories.AIR, ev) then
                table.insert(airFactories, ev)
            elseif EntityCategoryContains(categories.FACTORY * categories.LAND, ev) then
                table.insert(landFactories, ev)
            elseif EntityCategoryContains(categories.FACTORY * categories.NAVAL, ev) then
                table.insert(seaFactories, ev)
            elseif EntityCategoryContains(categories.FACTORY * categories.GATE, ev) then
                table.insert(gates, ev)
            end
        end

        local retFacs = {}
        if pType == 'Air' then
            numFactories = TableGetn(airFactories)
        elseif pType == 'Land' then
            numFactories = TableGetn(landFactories)
        elseif pType == 'Sea' then
            numFactories = TableGetn(seaFactories)
        elseif pType == 'Gate' then
            numFactories = TableGetn(gates)
        end

        return numFactories
    end,

    ---@param self AIBrain
    ---@param platoon any
    PBMPlatoonTimeOutThread = function(self, platoon)
        local minWait = 5 -- 240 CAMPAIGNS
        if platoon.BuildTimeOut and platoon.BuildTimeOut < minWait then
            WaitSeconds(minWait)
        else
            WaitSeconds(platoon.BuildTimeOut or 600)
        end
        self:PBMSetBuildingHandleFalse(platoon)
    end,

    ---@param self AIBrain
    ---@param platoonTemplate any
    ---@param factory Unit
    ---@return boolean
    PBMFactoryCanBuildPlatoon = function(self, platoonTemplate, factory)
        for i = 3, TableGetn(platoonTemplate) do
            if not factory:CanBuild(platoonTemplate[i][1]) then
                return false
            end
        end
        return true
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    PBMPlatoonDestroyed = function(self, platoon)
        self:PBMRemoveHandle(platoon)
        if platoon.PlatoonData.BuilderName then
            self.PlatoonNameCounter[platoon.PlatoonData.BuilderName] = self.PlatoonNameCounter[platoon.PlatoonData.BuilderName] - 1
        end
    end,

    ---@param self AIBrain
    ---@param bCs table
    ---@param index number
    ---@return boolean
    PBMCheckBuildConditions = function(self, bCs, index)
        for _, v in bCs do
            if not v.LookupNumber[index] then
                local found = false
                if v[3][1] == "default_brain" then
                    table.remove(v[3], 1)
                end

                for num, bcData in self.PBM.BuildConditionsTable do
                    if bcData[1] == v[1] and bcData[2] == v[2] and TableGetn(bcData[3]) == TableGetn(v[3]) then
                        local tablePos = 1
                        found = num
                        while tablePos <= TableGetn(v[3]) do
                            if bcData[3][tablePos] ~= v[3][tablePos] then
                                found = false
                                break
                            end
                            tablePos = tablePos + 1
                        end
                    end
                end

                if found then
                    if not v.LookupNumber then
                        v.LookupNumber = {}
                    end
                    v.LookupNumber[index] = found
                else
                    if not v.LookupNumber then
                        v.LookupNumber = {}
                    end
                    table.insert(self.PBM.BuildConditionsTable, v)
                    v.LookupNumber[index] = TableGetn(self.PBM.BuildConditionsTable)
                end
            end
            if not self.PBM.BuildConditionsTable[v.LookupNumber[index]].Cached[index] then
                if not self.PBM.BuildConditionsTable[v.LookupNumber[index]].Cached then
                    self.PBM.BuildConditionsTable[v.LookupNumber[index]].Cached = {}
                    self.PBM.BuildConditionsTable[v.LookupNumber[index]].CachedVal = {}
                end
                self.PBM.BuildConditionsTable[v.LookupNumber[index]].Cached[index] = true

                local d = self.PBM.BuildConditionsTable[v.LookupNumber[index]]
                self.PBM.BuildConditionsTable[v.LookupNumber[index]].CachedVal[index] = import(d[1])[d[2]](self, unpack(d[3]))
                if not self.BCFuncCalls then
                    self.BCFuncCalls = 0
                end

                if index == 3 then
                    self.BCFuncCalls = self.BCFuncCalls + 1
                end
            end

            if not self.PBM.BuildConditionsTable[v.LookupNumber[index]].CachedVal[index] then
                return false
            end
        end
        return true
    end,

    ---@param self AIBrain
    PBMClearBuildConditionsCache = function(self)
        for k, v in self.PBM.BuildConditionsTable do
            v.Cached[self:GetArmyIndex()] = false
        end
    end,

    ---@param self AIBrain
    ---@param platoonList Platoon[]
    ---@param ai AIBrain
    ---@return nil|Platoon
    CombinePlatoons = function(self, platoonList, ai)
        local squadTypes = {'Unassigned', 'Attack', 'Artillery', 'Support', 'Scout', 'Guard'}
        local returnPlatoon
        if not ai then
            returnPlatoon = self:MakePlatoon(' ', 'None')
        else
            returnPlatoon = self:MakePlatoon(' ', ai)
        end

        for k, platoon in platoonList do
            for j, type in squadTypes do
                local squadUnits = platoon:GetSquadUnits(type)
                local formation = 'GrowthFormation'
                if squadUnits then
                    self:AssignUnitsToPlatoon(returnPlatoon, squadUnits, type, formation)
                end
            end
            self:DisbandPlatoon(platoon)
        end
        return returnPlatoon
    end,

    ---# BASE MONITORING SYSTEM
    ---@param self AIBrain
    ---@param spec any
    BaseMonitorInitialization = function(self, spec)
        ---@class AiBaseMonitor
        self.BaseMonitor = {
            BaseMonitorStatus = 'ACTIVE',
            BaseMonitorPoints = {},
            AlertSounded = false,
            AlertsTable = {},
            AlertLocation = false,
            AlertSoundedThreat = 0,
            ActiveAlerts = 0,

            PoolDistressRange = 75,
            PoolReactionTime = 7,

            -- Variables for checking a radius for enemy units
            UnitRadiusThreshold = spec.UnitRadiusThreshold or 3,
            UnitCategoryCheck = spec.UnitCategoryCheck or (categories.MOBILE - (categories.SCOUT + categories.ENGINEER)),
            UnitCheckRadius = spec.UnitCheckRadius or 40,

            -- Threat level must be greater than this number to sound a base alert
            AlertLevel = spec.AlertLevel or 0,
            -- Delay time for checking base
            BaseMonitorTime = spec.BaseMonitorTime or 11,
            -- Default distance a platoon will travel to help around the base
            DefaultDistressRange = spec.DefaultDistressRange or 75,
            -- Default how often platoons will check if the base is under duress
            PlatoonDefaultReactionTime = spec.PlatoonDefaultReactionTime or 5,
            -- Default duration for an alert to time out
            DefaultAlertTimeout = spec.DefaultAlertTimeout or 10,

            PoolDistressThreshold = 1,

            -- Monitor platoons for help
            PlatoonDistressTable = {},
            PlatoonDistressThread = false,
            PlatoonAlertSounded = false,
        }
        self:ForkThread(self.BaseMonitorThread)
        if self:IsBaseAI() then
            self:ForkThread(self.CanPathToCurrentEnemy)
        end
    end,

    ---@param self AIBrain
    ---@param platoon Platoon
    ---@param threat number
    BaseMonitorPlatoonDistress = function(self, platoon, threat)
        if not self.BaseMonitor then
            return
        end

        local found = false
        for k, v in self.BaseMonitor.PlatoonDistressTable do
            -- If already calling for help, don't add another distress call
            if v.Platoon == platoon then
                found = true
                break
            end
        end
        if not found then
            -- Add platoon to list desiring aid
            table.insert(self.BaseMonitor.PlatoonDistressTable, {Platoon = platoon, Threat = threat})
        end
        -- Create the distress call if it doesn't exist
        if not self.BaseMonitor.PlatoonDistressThread then
            self.BaseMonitor.PlatoonDistressThread = self:ForkThread(self.BaseMonitorPlatoonDistressThread)
        end
    end,

    ---@param self AIBrain
    BaseMonitorPlatoonDistressThread = function(self)
        self.BaseMonitor.PlatoonAlertSounded = true
        while true do
            local numPlatoons = 0
            for k, v in self.BaseMonitor.PlatoonDistressTable do
                if self:PlatoonExists(v.Platoon) then
                    local threat = self:GetThreatAtPosition(v.Platoon:GetPlatoonPosition(), 0, true, 'AntiSurface')
                    local myThreat = self:GetThreatAtPosition(v.Platoon:GetPlatoonPosition(), 0, true, 'Overall', self:GetArmyIndex())
                    -- Platoons still threatened
                if threat and threat > (myThreat * 1.5) then
                        v.Threat = threat
                        numPlatoons = numPlatoons + 1
                    -- Platoon not threatened
                    else
                        self.BaseMonitor.PlatoonDistressTable[k] = nil
                        v.Platoon.DistressCall = false
                    end
                else
                    self.BaseMonitor.PlatoonDistressTable[k] = nil
                end
            end

            -- If any platoons still want help; continue sounding
            if numPlatoons > 0 then
                self.BaseMonitor.PlatoonAlertSounded = true
            else
                self.BaseMonitor.PlatoonAlertSounded = false
            end
            WaitSeconds(self.BaseMonitor.BaseMonitorTime)
        end
    end,

    ---@param self AIBrain
    ---@param position Vector
    ---@param radius number
    ---@param threshold number
    ---@return boolean|table
    BaseMonitorDistressLocation = function(self, position, radius, threshold)
        local returnPos = false
        local highThreat = false
        local distance
        if self.BaseMonitor.CDRDistress
                and Utilities.XZDistanceTwoVectors(self.BaseMonitor.CDRDistress, position) < radius
                and self.BaseMonitor.CDRThreatLevel > threshold then
            -- Commander scared and nearby; help it
            return self.BaseMonitor.CDRDistress
        end
        if self.BaseMonitor.AlertSounded then
            for k, v in self.BaseMonitor.AlertsTable do
                local tempDist = Utilities.XZDistanceTwoVectors(position, v.Position)

                -- Too far away
                if tempDist > radius then
                    continue
                end

                -- Not enough threat in location
                if v.Threat < threshold then
                    continue
                end

                -- Threat lower than or equal to a threat we already have
                if v.Threat <= highThreat then
                    continue
                end

                -- Get real height
                local height = GetTerrainHeight(v.Position[1], v.Position[3])
                local surfHeight = GetSurfaceHeight(v.Position[1], v.Position[3])
                if surfHeight > height then
                    height = surfHeight
                end

                -- currently our winner in high threat
                returnPos = {v.Position[1], height, v.Position[3]}
                distance = tempDist
            end
        end
        if self.BaseMonitor.PlatoonAlertSounded then
            for k, v in self.BaseMonitor.PlatoonDistressTable do
                if self:PlatoonExists(v.Platoon) then
                    local platPos = v.Platoon:GetPlatoonPosition()
                    local tempDist = Utilities.XZDistanceTwoVectors(position, platPos)

                    -- Platoon too far away to help
                    if tempDist > radius then
                        continue
                    end

                    -- Area not scary enough
                    if v.Threat < threshold then
                        continue
                    end

                    -- Further away than another call for help
                    if tempDist > distance then
                        continue
                    end

                    -- Our current winners
                    returnPos = platPos
                    distance = tempDist
                end
            end
        end
        return returnPos
    end,

    ---@param self AIBrain
    BaseMonitorThread = function(self)
        while true do
            if self.BaseMonitor.BaseMonitorStatus == 'ACTIVE' then
                self:BaseMonitorCheck()
            end
            WaitSeconds(self.BaseMonitor.BaseMonitorTime)
        end
    end,

    ---@param self AIBrain
    ---@param pos Vector
    ---@param threattype string
    BaseMonitorAlertTimeout = function(self, pos, threattype)
        local timeout = self.BaseMonitor.DefaultAlertTimeout
        local threat
        local threshold = self.BaseMonitor.AlertLevel
        local myThreat
        repeat
            WaitSeconds(timeout)
            threat = self:GetThreatAtPosition(pos, 0, true, threattype or 'AntiSurface')
            myThreat = self:GetThreatAtPosition(pos, 0, true, 'Overall', self:GetArmyIndex())
            if threat - myThreat < 1 then
                local eEngies = self:GetNumUnitsAroundPoint(categories.ENGINEER, pos, 10, 'Enemy')
                if eEngies > 0 then
                    threat = threat + (eEngies * 10)
                end
            end
        until threat - myThreat <= threshold

        for k, v in self.BaseMonitor.AlertsTable do
            if pos[1] == v.Position[1] and pos[3] == v.Position[3] then
                table.remove(self.BaseMonitor.AlertsTable, k)
                break
            end
        end

        for k, v in self.BaseMonitor.BaseMonitorPoints do
            if pos[1] == v.Position[1] and pos[3] == v.Position[3] then
                v.Alert = false
                break
            end
        end

        self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts - 1
        if self.BaseMonitor.ActiveAlerts == 0 then
            self.BaseMonitor.AlertSounded = false
        end
    end,

    ---@param self AIBrain
    BaseMonitorCheck = function(self)
        local vecs = self:GetStructureVectors()
        if not table.empty(vecs) then
            -- Find new points to monitor
            for k, v in vecs do
                local found = false
                for subk, subv in self.BaseMonitor.BaseMonitorPoints do
                    if v[1] == subv.Position[1] and v[3] == subv.Position[3] then
                        found = true
                        -- if we found this point already stored, we don't need to continue searching the rest
                        break
                    end
                end
                if not found then
                    table.insert(self.BaseMonitor.BaseMonitorPoints,
                        {
                            Position = v,
                            Threat = self:GetThreatAtPosition(v, 0, true, 'Overall'),
                            Alert = false
                        }
                    )
                end
            end
            -- Remove any points that we dont monitor anymore
            for k, v in self.BaseMonitor.BaseMonitorPoints do
                local found = false
                for subk, subv in vecs do
                    if v.Position[1] == subv[1] and v.Position[3] == subv[3] then
                        found = true
                        break
                    end
                end
                -- If point not in list and the num units around the point is small
                if not found and self:GetNumUnitsAroundPoint(categories.STRUCTURE, v.Position, 16, 'Ally') <= 1 then
                    table.remove(self.BaseMonitor.BaseMonitorPoints, k)
                end
            end
            -- Check monitor points for change
            local alertThreat = self.BaseMonitor.AlertLevel
            for k, v in self.BaseMonitor.BaseMonitorPoints do
                if not v.Alert then
                    v.Threat = self:GetThreatAtPosition(v.Position, 0, true, 'Overall')
                    if v.Threat > alertThreat then
                        v.Alert = true
                        table.insert(self.BaseMonitor.AlertsTable,
                            {
                                Position = v.Position,
                                Threat = v.Threat,
                            }
                        )
                        self.BaseMonitor.AlertSounded = true
                        self:ForkThread(self.BaseMonitorAlertTimeout, v.Position)
                        self.BaseMonitor.ActiveAlerts = self.BaseMonitor.ActiveAlerts + 1
                    end
                end
            end
        end
    end,

    ---@param self AIBrain
    ParseIntelThreadSorian = function(self)
        if not self.InterestList or not self.InterestList.MustScout then
            error('Scouting areas must be initialized before calling AIBrain:ParseIntelThread.', 2)
        end
        if not self.T4ThreatFound then
            self.T4ThreatFound = {}
        end
        if not self.AttackPoints then
            self.AttackPoints = {}
        end
        if not self.AirAttackPoints then
            self.AirAttackPoints = {}
        end
        if not self.TacticalBases then
            self.TacticalBases = {}
        end

        local intelChecks = {
            -- ThreatType    = {max dist to merge points, threat minimum, timeout (-1 = never timeout), try for exact pos, category to use for exact pos}
            StructuresNotMex = {100, 0, 60, true, categories.STRUCTURE - categories.MASSEXTRACTION},
            Commander = {50, 0, 120, true, categories.COMMAND},
            Experimental = {50, 0, 120, true, categories.EXPERIMENTAL},
            Artillery = {50, 1150, 120, true, categories.ARTILLERY * categories.TECH3},
            Land = {100, 50, 120, false, nil},
        }

        local numchecks = 0
        local checkspertick = 5
        while true do
            local changed = false
            for threatType, v in intelChecks do
                local threats = self:GetThreatsAroundPosition(self.BuilderManagers.MAIN.Position, 16, true, threatType)
                for _, threat in threats do
                    local dupe = false
                    local newPos = {threat[1], 0, threat[2]}
                    numchecks = numchecks + 1
                    for _, loc in self.InterestList.HighPriority do
                        if loc.Type == threatType and VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < v[1] * v[1] then
                            dupe = true
                            loc.LastUpdate = GetGameTimeSeconds()
                            break
                        end
                    end

                    if not dupe then
                        -- Is it in the low priority list?
                        for i = 1, TableGetn(self.InterestList.LowPriority) do
                            local loc = self.InterestList.LowPriority[i]
                            if VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < v[1] * v[1] and threat[3] > v[2] then
                                -- Found it in the low pri list. Remove it so we can add it to the high priority list.
                                table.remove(self.InterestList.LowPriority, i)
                                break
                            end
                        end
                        -- Check for exact position?
                        if threat[3] > v[2] and v[4] and v[5] then
                            local nearUnits = self:GetUnitsAroundPoint(v[5], newPos, v[1], 'Enemy')
                            if not table.empty(nearUnits) then
                                local unitPos = nearUnits[1]:GetPosition()
                                if unitPos then
                                    newPos = {unitPos[1], 0, unitPos[3]}
                                end
                            end
                        end
                        -- Threat high enough?
                        if threat[3] > v[2] then
                            changed = true
                            table.insert(self.InterestList.HighPriority,
                                {
                                    Position = newPos,
                                    Type = threatType,
                                    Threat = threat[3],
                                    LastUpdate = GetGameTimeSeconds(),
                                    LastScouted = GetGameTimeSeconds(),
                                }
                            )
                        end
                    end
                    -- Reduce load on game
                    if numchecks > checkspertick then
                        WaitTicks(1)
                        numchecks = 0
                    end
                end
            end
            numchecks = 0

            -- Get rid of outdated intel
            for k, v in self.InterestList.HighPriority do
                if not v.Permanent and intelChecks[v.Type][3] > 0 and v.LastUpdate + intelChecks[v.Type][3] < GetGameTimeSeconds() then
                    self.InterestList.HighPriority[k] = nil
                    changed = true
                end
            end

            -- Rebuild intel table if there was a change
            if changed then
                self.InterestList.HighPriority = self:RebuildTable(self.InterestList.HighPriority)
            end

            -- Sort the list based on low long it has been since it was scouted
            table.sort(self.InterestList.HighPriority, function(a, b)
                if a.LastScouted == b.LastScouted then
                    local MainPos = self.BuilderManagers.MAIN.Position
                    local distA = VDist2(MainPos[1], MainPos[3], a.Position[1], a.Position[3])
                    local distB = VDist2(MainPos[1], MainPos[3], b.Position[1], b.Position[3])

                    return distA < distB
                else
                    return a.LastScouted < b.LastScouted
                end
            end)

            -- Draw intel data on map
            -- if not self.IntelDebugThread then
            --   self.IntelDebugThread = self:ForkThread(SUtils.DrawIntel)
            -- end
            -- Handle intel data if there was a change
            if changed then
                SUtils.AIHandleIntelData(self)
            end
            SUtils.AICheckForWeakEnemyBase(self)

            WaitSeconds(5)
        end
    end,

    ---@param self AIBrain
    ---@param threattypes string
    T4ThreatMonitorTimeout = function(self, threattypes)
        WaitSeconds(180)
        for _, v in threattypes do
            self.T4ThreatFound[v] = false
        end
    end,

    ---@param self AIBrain
    ---@return Vector[]
    GetBaseVectors = function(self)
        local enemy = self:GetCurrentEnemy()
        local index = self:GetArmyIndex()
        self:SetCurrentEnemy(self)
        self:SetUpAttackVectorsToArmy(categories.STRUCTURE - (categories.MASSEXTRACTION))
        self:SetCurrentEnemy(enemy)
        if enemy then
            self:SetUpAttackVectorsToArmy()
        end

        local vecs = self:GetAttackVectors()
        local returnPoints = {}
        if vecs then
            for _, v in vecs do
                local loc = {v.px, v.py, v.pz}
                local found = false
                for subk, subv in returnPoints do
                    if subv[1] == loc[1] and subv[3] == loc[3] then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(returnPoints, loc)
                end
            end
        end
        return returnPoints
    end,

    ---@param self AIBrain
    ---@return table
    GetStructureVectors = function(self)
        local structures = self:GetListOfUnits(categories.STRUCTURE - categories.WALL, false)
        -- Add all points around location
        local tempGridPoints = {}
        local indexChecker = {}

        for k, v in structures do
            if not v.Dead then
                local pos = AIUtils.GetUnitBaseStructureVector(v)
                if pos then
                    if not indexChecker[pos[1]] then
                        indexChecker[pos[1]] = {}
                    end
                    if not indexChecker[pos[1]][pos[3]] then
                        indexChecker[pos[1]][pos[3]] = true
                        table.insert(tempGridPoints, pos)
                    end
                end
            end
        end

        return tempGridPoints
    end,

    -- ENEMY PICKER AI
    ---@param self AIBrain
    PickEnemy = function(self)
        while true do
            self:PickEnemyLogic()
            WaitSeconds(120)
        end
    end,

    ---@param self AIBrain
    ---@param strengthTable table
    ---@return boolean
    GetAllianceEnemy = function(self, strengthTable)
        local returnEnemy = false
        local myIndex = self:GetArmyIndex()
        local highStrength = strengthTable[myIndex].Strength
        for k, v in strengthTable do
            -- It's an enemy, ignore
            if k ~= myIndex and not v.Enemy and not ArmyIsCivilian(k) and not v.Brain:IsDefeated() then
                -- Ally too weak
                if v.Strength < highStrength then
                    continue
                end
                -- If the brain has an enemy, it's our new enemy
                local enemy = v.Brain:GetCurrentEnemy()
                if enemy then
                    highStrength = v.Strength
                    returnEnemy = v.Brain:GetCurrentEnemy()
                end
            end
        end
        return returnEnemy
    end,

    ---@param self AIBrain
    PickEnemyLogic = function(self)
        local armyStrengthTable = {}
        local selfIndex = self:GetArmyIndex()
        for _, v in ArmyBrains do
            local insertTable = {
                Enemy = true,
                Strength = 0,
                Position = false,
                Brain = v,
            }
            local armyIndex = v:GetArmyIndex()
            -- Share resources with friends but don't regard their strength
            if IsAlly(selfIndex, armyIndex) then
                self:SetResourceSharing(true)
                insertTable.Enemy = false
            elseif not IsEnemy(selfIndex, armyIndex) then
                insertTable.Enemy = false
            end

            if insertTable.Enemy then
                insertTable.Position, insertTable.Strength = self:GetHighestThreatPosition(self.IMAPConfig.Rings, true, 'Structures', armyIndex)
            else
                local startX, startZ = v:GetArmyStartPos()
                local ecoStructures = self:GetUnitsAroundPoint(categories.STRUCTURE * (categories.MASSEXTRACTION + categories.MASSPRODUCTION), {startX, 0 ,startZ}, 120, 'Ally')
                local ecoThreat = 0
                for _, v in ecoStructures do
                    ecoThreat = ecoThreat + v.Blueprint.Defense.EconomyThreatLevel
                end
                insertTable.Position = {startX, 0, startZ}
                insertTable.Strength = ecoThreat
            end
            armyStrengthTable[armyIndex] = insertTable
        end

        local allyEnemy = self:GetAllianceEnemy(armyStrengthTable)
        if allyEnemy  then
            self:SetCurrentEnemy(allyEnemy)
        else
            local findEnemy = false
            if not self:GetCurrentEnemy() then
                findEnemy = true
            else
                local cIndex = self:GetCurrentEnemy():GetArmyIndex()
                -- If our enemy has been defeated or has less than 20 strength, we need a new enemy
                if self:GetCurrentEnemy():IsDefeated() or armyStrengthTable[cIndex].Strength < 20 then
                    findEnemy = true
                end
            end
            if findEnemy then
                local enemyStrength = false
                local enemy = false

                for k, v in armyStrengthTable do
                    -- Dont' target self and ignore allies
                    if k ~= selfIndex and v.Enemy and not v.Brain:IsDefeated() then
                        
                        -- If we have a better candidate; ignore really weak enemies
                        if enemy and v.Strength < 20 then
                            continue
                        end

                        -- The closer targets are worth more because then we get their mass spots
                        local distanceWeight = 0.1
                        local distance = VDist3(self:GetStartVector3f(), v.Position)
                        local threatWeight = (1 / (distance * distanceWeight)) * v.Strength

                        if not enemy or threatWeight > enemyStrength then
                            enemy = v.Brain
                        end
                    end
                end

                if enemy then
                    self:SetCurrentEnemy(enemy)
                end
            end
        end
    end,

    ---@param self AIBrain
    GetNewAttackVectors = function(self)
        if not self.AttackVectorsThread then
            self.AttackVectorsThread = self:ForkThread(self.SetupAttackVectorsThread)
        end
    end,

    ---@param self AIBrain
    SetupAttackVectorsThread = function(self)
        self.AttackVectorUpdate = 0
        while true do
            self:SetUpAttackVectorsToArmy(categories.STRUCTURE - (categories.MASSEXTRACTION))
            while self.AttackVectorUpdate < 30 do
                WaitSeconds(1)
                self.AttackVectorUpdate = self.AttackVectorUpdate + 1
            end
            self.AttackVectorUpdate = 0
        end
    end,

    -- Skirmish expansion help
    ---@param self AIBrain
    ---@param eng Unit
    ---@param reference string
    ExpansionHelp = function(self, eng, reference)
        self:ForkThread(self.ExpansionHelpThread, eng, reference)
    end,

    ---@param self AIBrain
    ---@param eng Unit
    ---@param reference string
    ExpansionHelpThread = function(self, eng, reference)
        local pool = self:GetPlatoonUniquelyNamed('ArmyPool')
        local landHelp = {}
        local val = 0
        for _, v in pool:GetPlatoonUnits() do
            if val == 0 and EntityCategoryContains((categories.LAND * categories.MOBILE) - categories.CONSTRUCTION, v) then
                table.insert(landHelp, v)
            end

            val = val + 1
            if val == 4 then
                val = 0
            end
        end
        self:ForkThread(self.GroupHelpThread, landHelp, reference)
    end,

    ---@param self AIBrain
    ---@param units Unit
    ---@param reference string
    GroupHelpThread = function(self, units, reference)
        local plat = self:MakePlatoon('', '')
        self:AssignUnitsToPlatoon(plat, units, 'Attack', 'GrowthFormation')
        local cmd = plat:MoveToLocation(reference, false)
        while self:PlatoonExists(plat) and plat:IsCommandsActive(cmd) do
            WaitSeconds(5)
        end
        WaitSeconds(30)

        if self:PlatoonExists(plat) then
            local x, z = self:GetArmyStartPos()
            plat:MoveToLocation({x, 0, z}, false)
            self:DisbandPlatoon(plat)
        end
    end,

    ---@param self AIBrain
    AbandonedByPlayer = function(self)
        if not IsGameOver() then
            if ScenarioInfo.Options.AIReplacement == 'On' then
                ForkThread(function()
                    local oldName = ArmyBrains[self:GetArmyIndex()].Nickname

                    WaitSeconds(1)

                    SUtils.AISendChat('all', ArmyBrains[self:GetArmyIndex()].Nickname, 'takingcontrol')

                    -- Reassign all Army attributes to better suit the AI.
                    self.BrainType = 'AI'

                    if self.EnergyExcessThread then 
                        KillThread(self.EnergyExcessThread)
                    end

                    self.ConditionsMonitor = BrainConditionsMonitor.CreateConditionsMonitor(self)
                    self.NumBases = 0 -- AddBuilderManagers will increase the number
                    self.BuilderManagers = {}
                    self:AddBuilderManagers(self:GetStartVector3f(), 100, 'MAIN', false)
                    SUtils.AddCustomUnitSupport(self)

                    ArmyBrains[self:GetArmyIndex()].Nickname = 'CMDR Sorian..(was '..oldName..')'
                    ScenarioInfo.ArmySetup[self.Name].AIPersonality = 'sorianadaptive'

                    local cmdUnits = self:GetListOfUnits(categories.COMMAND, true)
                    if cmdUnits then
                        cmdUnits[1]:SetCustomName(ArmyBrains[self:GetArmyIndex()].Nickname)
                    end

                    self:InitializeSkirmishSystems()
                    self:OnCreateAI()
                end)
            else -- If ScenarioInfo.Options.AIReplacement return nil or any other value, make sure the ACU explodes.
                self:OnDefeat()
            end
        end
    end,

    ---## Scouting help...
    --- Creates an influence map threat at enemy bases so the AI will start sending attacks before scouting gets up.
    ---@param self AIBrain
    ---@param amount number amount of threat to add to each enemy start area
    ---@param decay number rate that the threat should decay
    ---@return nil
    AddInitialEnemyThreat = function(self, amount, decay)
        local aiBrain = self
        local myArmy = ScenarioInfo.ArmySetup[self.Name]

        if ScenarioInfo.Options.TeamSpawn == 'fixed' then
            -- Spawn locations were fixed. We know exactly where our opponents are.
            for i = 1, 16 do
                local token = 'ARMY_' .. i
                local army = ScenarioInfo.ArmySetup[token]

                if army then
                    if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                        local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position
                        if startPos then
                          self:AssignThreatAtPosition(startPos, amount, decay)
                        end
                    end
                end
            end
        end
    end,

    ---##  Function: ParseIntelThread
    ---Once per second, checks imap for enemy expansion bases.
    ---@param self AIBrain
    ---@return nil  #loops forever
    ParseIntelThread = function(self)
        if not self.InterestList or not self.InterestList.MustScout then
            error('Scouting areas must be initialized before calling AIBrain:ParseIntelThread.', 2)
        end

        while true do
            local structures = self:GetThreatsAroundPosition(self.BuilderManagers.MAIN.Position, 16, true, 'StructuresNotMex')
            for _, struct in structures do
                local dupe = false
                local newPos = {struct[1], 0, struct[2]}

                for _, loc in self.InterestList.HighPriority do
                    if VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < 10000 then
                        dupe = true
                        break
                    end
                end

                if not dupe then
                    -- Is it in the low priority list?
                    for i = 1, TableGetn(self.InterestList.LowPriority) do
                        local loc = self.InterestList.LowPriority[i]
                        if VDist2Sq(newPos[1], newPos[3], loc.Position[1], loc.Position[3]) < 10000 then
                            -- Found it in the low pri list. Remove it so we can add it to the high priority list.
                            table.remove(self.InterestList.LowPriority, i)
                            break
                        end
                    end

                    table.insert(self.InterestList.HighPriority,
                        {
                            Position = newPos,
                            LastScouted = GetGameTimeSeconds(),
                        }
                    )

                    -- Sort the list based on low long it has been since it was scouted
                    table.sort(self.InterestList.HighPriority, function(a, b)
                        if a.LastScouted == b.LastScouted then
                            local MainPos = self.BuilderManagers.MAIN.Position
                            local distA = VDist2(MainPos[1], MainPos[3], a.Position[1], a.Position[3])
                            local distB = VDist2(MainPos[1], MainPos[3], b.Position[1], b.Position[3])

                            return distA < distB
                        else
                            return a.LastScouted < b.LastScouted
                        end
                    end)
                end
            end

            WaitSeconds(5)
        end
    end,

    ---## Function: GetUntaggedMustScoutArea
    --- Gets an area that has been flagged with the AddScoutArea function that does not have a unit heading to scout it already.
    ---@param self AIBrain
    ---@return Vector location
    ---@return number index
    GetUntaggedMustScoutArea = function(self)
        -- If any locations have been specifically tagged for scouting
        if not self.InterestList or not self.InterestList.MustScout then
            error('Scouting areas must be initialized before calling AIBrain:GetUntaggedMustScoutArea.', 2)
        end

        for idx, loc in self.InterestList.MustScout do
            if not loc.TaggedBy or loc.TaggedBy.Dead then
                return loc, idx
            end
        end
    end,

    ---## Function: AddScoutArea
    --- Sets an area to be scouted once by air scouts at the next opportunity.
    ---@param self AIBrain
    ---@param location Vector
    ---@return nil
    AddScoutArea = function(self, location)
        if not self.InterestList or not self.InterestList.MustScout then
            error('Scouting areas must be initialized before calling AIBrain:AddScoutArea.', 2)
        end

        -- If there's already a location to scout within 20 ogrids of this one, don't add it.
        for _, loc in self.InterestList.MustScout do
            if VDist2Sq(loc.Position[1], loc.Position[3], location[1], location[3]) < 400 then
                return
            end
        end

        table.insert(self.InterestList.MustScout,
            {
                Position = location,
                TaggedBy = false,
            }
        )
    end,

    ---##  Function: BuildScoutLocations
    ---  Sets up the initial low-priority scouting areas. If playing with fixed starting locations,
    ---  also sets up high-priority scouting areas. This function may be called multiple times, but only
    ---  has an effect the first time it is called per brain.
    ---@param self AIBrain
    ---@return nil
    BuildScoutLocations = function(self)
        local aiBrain = self
        local opponentStarts = {}
        local allyStarts = {}

        if not aiBrain.InterestList then
            aiBrain.InterestList = {}
            aiBrain.IntelData.HiPriScouts = 0
            aiBrain.IntelData.AirHiPriScouts = 0
            aiBrain.IntelData.AirLowPriScouts = 0

            -- Add each enemy's start location to the InterestList as a new sub table
            aiBrain.InterestList.HighPriority = {}
            aiBrain.InterestList.LowPriority = {}
            aiBrain.InterestList.MustScout = {}

            local myArmy = ScenarioInfo.ArmySetup[self.Name]

            if ScenarioInfo.Options.TeamSpawn == 'fixed' then
                -- Spawn locations were fixed. We know exactly where our opponents are.
                -- Don't scout areas owned by us or our allies.
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position
                    if army and startPos then
                        if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                        -- Add the army start location to the list of interesting spots.
                        opponentStarts['ARMY_' .. i] = startPos
                        numOpponents = numOpponents + 1
                        table.insert(aiBrain.InterestList.HighPriority,
                            {
                                Position = startPos,
                                LastScouted = 0,
                            }
                        )
                        else
                            allyStarts['ARMY_' .. i] = startPos
                        end
                    end
                end

                aiBrain.NumOpponents = numOpponents

                -- For each vacant starting location, check if it is closer to allied or enemy start locations (within 100 ogrids)
                -- If it is closer to enemy territory, flag it as high priority to scout.
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not opponentStarts[loc.Name] and not allyStarts[loc.Name] then
                        local closestDistSq = 999999999
                        local closeToEnemy = false

                        for _, pos in opponentStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            -- Make sure to scout for bases that are near equidistant by giving the enemies 100 ogrids
                            if distSq-10000 < closestDistSq then
                                closestDistSq = distSq-10000
                                closeToEnemy = true
                            end
                        end

                        for _, pos in allyStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            if distSq < closestDistSq then
                                closestDistSq = distSq
                                closeToEnemy = false
                                break
                            end
                        end

                        if closeToEnemy then
                            table.insert(aiBrain.InterestList.LowPriority,
                                {
                                    Position = loc.Position,
                                    LastScouted = 0,
                                }
                            )
                        end
                    end
                end

            else -- Spawn locations were random. We don't know where our opponents are. Add all non-ally start locations to the scout list
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position

                    if army and startPos then
                        if army.ArmyIndex == myArmy.ArmyIndex or (army.Team == myArmy.Team and army.Team ~= 1) then
                            allyStarts['ARMY_' .. i] = startPos
                        else
                            numOpponents = numOpponents + 1
                        end
                    end
                end

                aiBrain.NumOpponents = numOpponents

                -- If the start location is not ours or an ally's, it is suspicious
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not allyStarts[loc.Name] then
                        table.insert(aiBrain.InterestList.LowPriority,
                            {
                                Position = loc.Position,
                                LastScouted = 0,
                            }
                        )
                    end
                end
            end
            aiBrain:ForkThread(self.ParseIntelThread)
        end
    end,

    ---## Function: SortScoutingAreas
    --- Sorts the brain's list of scouting areas by time since scouted, and then distance from main base.
    ---@param self AIBrain
    ---@param list table
    ---@return nil
    SortScoutingAreas = function(self, list)
        table.sort(list, function(a, b)
            if a.LastScouted == b.LastScouted then
                local MainPos = self.BuilderManagers.MAIN.Position
                local distA = VDist2(MainPos[1], MainPos[3], a.Position[1], a.Position[3])
                local distB = VDist2(MainPos[1], MainPos[3], b.Position[1], b.Position[3])

                return distA < distB
            else
                return a.LastScouted < b.LastScouted
            end
        end)
    end,

    ---@param self AIBrain
    BuildScoutLocationsSorian = function(self)
        local aiBrain = self
        local opponentStarts = {}
        local allyStarts = {}
        if not aiBrain.InterestList then
            aiBrain.InterestList = {}
            aiBrain.IntelData.HiPriScouts = 0
            aiBrain.IntelData.AirHiPriScouts = 0
            aiBrain.IntelData.AirLowPriScouts = 0

            -- Add each enemy's start location to the InterestList as a new sub table
            aiBrain.InterestList.HighPriority = {}
            aiBrain.InterestList.LowPriority = {}
            aiBrain.InterestList.MustScout = {}

            local myArmy = ScenarioInfo.ArmySetup[self.Name]

            if ScenarioInfo.Options.TeamSpawn == 'fixed' then
                -- Spawn locations were fixed. We know exactly where our opponents are.
                -- Don't scout areas owned by us or our allies.
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position

                    if army and startPos then
                        if army.ArmyIndex ~= myArmy.ArmyIndex and (army.Team ~= myArmy.Team or army.Team == 1) then
                            -- Add the army start location to the list of interesting spots.
                            opponentStarts['ARMY_' .. i] = startPos
                            numOpponents = numOpponents + 1
                            table.insert(aiBrain.InterestList.HighPriority,
                                {
                                    Position = startPos,
                                    Type = 'StructuresNotMex',
                                    LastScouted = 0,
                                    LastUpdate = 0,
                                    Threat = 75,
                                    Permanent = true,
                                }
                            )
                        else
                            allyStarts['ARMY_' .. i] = startPos
                        end
                    end
                end
                aiBrain.NumOpponents = numOpponents

                -- For each vacant starting location, check if it is closer to allied or enemy start locations (within 100 ogrids)
                -- If it is closer to enemy territory, flag it as high priority to scout.
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not opponentStarts[loc.Name] and not allyStarts[loc.Name] then
                        local closestDistSq = 999999999
                        local closeToEnemy = false

                        for _, pos in opponentStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            -- Make sure to scout for bases that are near equidistant by giving the enemies 100 ogrids
                            if distSq-10000 < closestDistSq then
                                closestDistSq = distSq-10000
                                closeToEnemy = true
                            end
                        end

                        for _, pos in allyStarts do
                            local distSq = VDist2Sq(pos[1], pos[3], loc.Position[1], loc.Position[3])
                            if distSq < closestDistSq then
                                closestDistSq = distSq
                                closeToEnemy = false
                                break
                            end
                        end

                        if closeToEnemy then
                            table.insert(aiBrain.InterestList.LowPriority,
                                {
                                    Position = loc.Position,
                                    Type = 'StructuresNotMex',
                                    LastScouted = 0,
                                    LastUpdate = 0,
                                    Threat = 0,
                                    Permanent = true,
                                }
                            )
                        end
                    end
                end
            else -- Spawn locations were random. We don't know where our opponents are. Add all non-ally start locations to the scout list
                local numOpponents = 0
                for i = 1, 16 do
                    local army = ScenarioInfo.ArmySetup['ARMY_' .. i]
                    local startPos = ScenarioUtils.GetMarker('ARMY_' .. i).position

                    if army and startPos then
                        if army.ArmyIndex == myArmy.ArmyIndex or (army.Team == myArmy.Team and army.Team ~= 1) then
                            allyStarts['ARMY_' .. i] = startPos
                        else
                            numOpponents = numOpponents + 1
                        end
                    end
                end
                aiBrain.NumOpponents = numOpponents

                -- If the start location is not ours or an ally's, it is suspicious
                local starts = AIUtils.AIGetMarkerLocations(aiBrain, 'Start Location')
                for _, loc in starts do
                    -- If vacant
                    if not allyStarts[loc.Name] then
                        table.insert(aiBrain.InterestList.LowPriority,
                            {
                                Position = loc.Position,
                                LastScouted = 0,
                                LastUpdate = 0,
                                Threat = 0,
                                Permanent = true,
                            }
                        )
                    end
                end
            end

            aiBrain:ForkThread(self.ParseIntelThreadSorian)
        end
    end,

    ---@param self AIBrain
    PickEnemySorian = function(self)
        self.targetoveride = false
        while true do
            self:PickEnemyLogicSorian(true)
            WaitSeconds(120)
        end
    end,

    ---@param self AIBrain
    ---@param brainbool boolean
    PickEnemyLogicSorian = function(self, brainbool)
        local armyStrengthTable = {}
        local selfIndex = self:GetArmyIndex()
        for _, v in ArmyBrains do
            local insertTable = {
                Enemy = true,
                Strength = 0,
                Position = false,
                Brain = v,
            }
            -- Share resources with friends but don't regard their strength
            if IsAlly(selfIndex, v:GetArmyIndex()) then
                self:SetResourceSharing(true)
                insertTable.Enemy = false
            elseif not IsEnemy(selfIndex, v:GetArmyIndex()) then
                insertTable.Enemy = false
            end

            insertTable.Position, insertTable.Strength = self:GetHighestThreatPosition(2, true, 'Structures', v:GetArmyIndex())
            armyStrengthTable[v:GetArmyIndex()] = insertTable
        end

        local allyEnemy = self:GetAllianceEnemy(armyStrengthTable)
        if allyEnemy and not self.targetoveride then
            self:SetCurrentEnemy(allyEnemy)
        else
            local findEnemy = false
            if (not self:GetCurrentEnemy() or brainbool) and not self.targetoveride then
                findEnemy = true
            elseif self:GetCurrentEnemy() then
                local cIndex = self:GetCurrentEnemy():GetArmyIndex()
                -- If our enemy has been defeated or has less than 20 strength, we need a new enemy
                if self:GetCurrentEnemy():IsDefeated() or armyStrengthTable[cIndex].Strength < 20 then
                    findEnemy = true
                end
            end
            if findEnemy then
                local enemyStrength = false
                local enemy = false

                for k, v in armyStrengthTable do
                    -- Dont' target self
                    if k == selfIndex then
                        continue
                    end

                    -- Ignore allies
                    if not v.Enemy then
                        continue
                    end

                    -- If we have a better candidate; ignore really weak enemies
                    if enemy and v.Strength < 20 then
                        continue
                    end

                    -- The closer targets are worth more because then we get their mass spots
                    local distanceWeight = 0.1
                    local distance = VDist3(self:GetStartVector3f(), v.Position)
                    local threatWeight = (1 / (distance * distanceWeight)) * v.Strength
                    if not enemy or threatWeight > enemyStrength then
                        enemyStrength = threatWeight
                        enemy = v.Brain
                    end
                end

                if enemy then
                    if not self:GetCurrentEnemy() or self:GetCurrentEnemy() ~= enemy then
                        SUtils.AISendChat('allies', ArmyBrains[self:GetArmyIndex()].Nickname, 'targetchat', ArmyBrains[enemy:GetArmyIndex()].Nickname)
                    end
                    self:SetCurrentEnemy(enemy)
                end
            end
        end
    end,

    ---@param self AIBrain
    UnderEnergyThresholdSorian = function(self)
        self:SetupOverEnergyStatTriggerSorian(0.15)
        self.LowEnergyMode = true
    end,

    ---@param self AIBrain
    OverEnergyThresholdSorian = function(self)
        self:SetupUnderEnergyStatTriggerSorian(0.1)
        self.LowEnergyMode = false
    end,

    ---@param self AIBrain
    UnderMassThresholdSorian = function(self)
        self:SetupOverMassStatTriggerSorian(0.15)
        self.LowMassMode = true
    end,

    ---@param self AIBrain
    OverMassThresholdSorian = function(self)
        self:SetupUnderMassStatTriggerSorian(0.1)
        self.LowMassMode = false
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderEnergyStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderEnergyThresholdSorian, self, 'SkirmishUnderEnergyThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverEnergyStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverEnergyThresholdSorian, self, 'SkirmishOverEnergyThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Energy',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupUnderMassStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.UnderMassThresholdSorian, self, 'SkirmishUnderMassThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'LessThanOrEqual',
                    Value = threshold,
                },
            }
        )
    end,

    ---@param self AIBrain
    ---@param threshold number
    SetupOverMassStatTriggerSorian = function(self, threshold)
        import("/lua/scenariotriggers.lua").CreateArmyStatTrigger(self.OverMassThresholdSorian, self, 'SkirmishOverMassThresholdSorian',
            {
                {
                    StatType = 'Economy_Ratio_Mass',
                    CompareType = 'GreaterThanOrEqual',
                    Value = threshold,
                },
            }
        )
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

    ---@param self AIBrain
    ---@param pos Vector
    AttackPointsTimeout = function(self, pos)
        WaitSeconds(300)
        for k, v in self.AttackPoints do
            if pos[1] == v.Position[1] and pos[3] == v.Position[3] then
                self.AttackPoints[k] = nil
                break
            end
        end
    end,

    ---@param self AIBrain
    ---@param pos Vector
    ---@param enemy Army
    AirAttackPointsTimeout = function(self, pos, enemy)
        local threat
        local myThreat
        local overallThreat
        repeat
            WaitSeconds(30)
            myThreat = 0
            threat = self:GetThreatAtPosition(pos, 1, true, 'AntiAir', enemy:GetArmyIndex())
            overallThreat = self:GetThreatAtPosition(pos, 1, true, 'Overall', enemy:GetArmyIndex())
            local bombers = AIUtils.GetOwnUnitsAroundPoint(self, categories.AIR * (categories.BOMBER + categories.GROUNDATTACK), pos, 10000)
            for _, unit in bombers do
                myThreat = myThreat + unit:GetBlueprint().Defense.SurfaceThreatLevel
            end
        until threat > myThreat or overallThreat <= 0

        for k, v in self.AirAttackPoints do
            if pos[1] == v.Position[1] and pos[3] == v.Position[3] then
                self.AirAttackPoints[k] = nil
                break
            end
        end
    end,

    --- Retrieves all units that fit the criteria around some point. Excludes dummy units.
    ---@param self AIBrain
    ---@param category EntityCategory The categories the units should fit.
    ---@param position Vector The center point to start looking for units.
    ---@param radius number The radius of the circle we look for units in.
    ---@param alliance AllianceStatus 
    ---@return nil 
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

    ---@param self AIBrain
    ---@return CommandUnit | nil
    GetCommander = function(self)
        local cdr = self.CDR
        if cdr and cdr:IsDead() then
            cdr = nil
        end
        if not cdr then
            local commanders = self:GetListOfUnits(categories.COMMANDER, false)
            table.shuffle(commanders)
            for _, commander in commanders do
                if not commander:IsDead() then
                    cdr = commander
                    break
                end
            end
        end
        return cdr
    end,

    --- Monitors pathing from each AI base to the current enemy start position. Used for determining which movement layers can attack an enemy.
    ---@param self AIBrain
    CanPathToCurrentEnemy = function(self)
        -- Validate Pathing to enemies based on navmesh queries
        -- Removed from build conditions so it can run on a slower loop
        -- added amphib vs air results so we can tell when we are trapped on a plateu
        WaitTicks(Random(5,20))
        local NavUtils = import("/lua/sim/navutils.lua")
        if not self.CanPathToEnemy then
            self.CanPathToEnemy = {}
        end

        while true do
            --We are getting the current base position rather than the start position so we can use this for expansions.
            for k, v in self.BuilderManagers do
                local locPos = v.Position 
                -- added this incase the position came back nil
                local enemyX, enemyZ
                if self:GetCurrentEnemy() then
                    enemyX, enemyZ = self:GetCurrentEnemy():GetArmyStartPos()
                    -- if we don't have an enemy position then we can't search for a path. Return until we have an enemy position
                    if not enemyX then
                        WaitTicks(30)
                        break
                    end
                else
                    WaitTicks(30)
                    break
                end

                -- Get the armyindex from the enemy
                local EnemyIndex = self:GetCurrentEnemy():GetArmyIndex()
                local OwnIndex = self:GetArmyIndex()
                -- create a table for the enemy index in case it's nil
                self.CanPathToEnemy[OwnIndex] = self.CanPathToEnemy[OwnIndex] or {}
                self.CanPathToEnemy[OwnIndex][EnemyIndex] = self.CanPathToEnemy[OwnIndex][EnemyIndex] or {}
                -- Check if we have already done a path search to the current enemy
                if self.CanPathToEnemy[OwnIndex][EnemyIndex][k] == 'Land' then
                    WaitTicks(5)
                    continue
                elseif self.CanPathToEnemy[OwnIndex][EnemyIndex][k] == 'Amphibious' then
                    WaitTicks(5)
                    continue
                elseif self.CanPathToEnemy[OwnIndex][EnemyIndex][k] == 'Air' then
                    WaitTicks(5)
                    continue
                end
                -- Check land path to current enemy
                local path, reason = NavUtils.CanPathTo('Land', locPos, {enemyX,0,enemyZ})
                
                -- if we have a true path from the nav mesh....
                if path then
                    self.CanPathToEnemy[OwnIndex][EnemyIndex][k] = 'Land'
                else
                    -- we have no path from the nav mesh....
                    local amphibPath, amphibReason = NavUtils.CanPathTo('Amphibious', locPos, {enemyX,0,enemyZ})
                    if not amphibPath then
                        -- No land or amphib path, we are likely on a plateu and cant go anywhere without transports.
                        self.CanPathToEnemy[OwnIndex][EnemyIndex][k] = 'Air'
                    else
                        self.CanPathToEnemy[OwnIndex][EnemyIndex][k] = 'Amphibious'
                    end
                end
                WaitTicks(5)
            end
            WaitTicks(100)
        end
    end,

    IMAPConfiguration = function(self)
        -- Used to configure imap values, used for setting threat ring sizes depending on map size to try and get a somewhat decent radius
        local maxmapdimension = math.max(ScenarioInfo.size[1],ScenarioInfo.size[2])

        if maxmapdimension == 256 then
            self.IMAPConfig.OgridRadius = 22.5
            self.IMAPConfig.IMAPSize = 32
            self.IMAPConfig.Rings = 2
        elseif maxmapdimension == 512 then
            self.IMAPConfig.OgridRadius = 22.5
            self.IMAPConfig.IMAPSize = 32
            self.IMAPConfig.Rings = 2
        elseif maxmapdimension == 1024 then
            self.IMAPConfig.OgridRadius = 45.0
            self.IMAPConfig.IMAPSize = 64
            self.IMAPConfig.Rings = 1
        elseif maxmapdimension == 2048 then
            self.IMAPConfig.OgridRadius = 89.5
            self.IMAPConfig.IMAPSize = 128
            self.IMAPConfig.Rings = 0
        else
            self.IMAPConfig.OgridRadius = 180.0
            self.IMAPConfig.IMAPSize = 256
            self.IMAPConfig.Rings = 0
        end
    end,

    MapAnalysis = function(self)
        -- This function will provide various means of the AI populating intel data
        -- Due to it potentially influencing buider/base template decisions it needs to run before the AI creates its first buildermanager
        WaitTicks(10)
        self.IntelData.MapWaterRatio = self:GetMapWaterRatio()
        local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
        AIAttackUtils.NavalAttackCheck(self)

    end,

    ---@param self AIBrain
    ---@param grid AIGridReclaim
    ---@param cell AIGridReclaimCell
    OnReclaimUpdate = function(self, grid, cell)
        if self.IntelFramework.IntelGrid then
            local intelFrameworkCell = self.IntelFramework.IntelGrid[cell.X][cell.Z]
            intelFrameworkCell.MassReclaim = cell.TotalMass
            intelFrameworkCell.EnergyReclaim = cell.TotalEnergy
            --LOG('IntelGridCell '..repr(intelFrameworkCell))
        end
    end,

    InitializeIntelFramework = function(self)
        if not self.IntelFramework then
            self.IntelFramework = {}
            self.IntelFramework.PlayableArea = ScenarioInfo.MapData.PlayableRect or {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
            self.IntelFramework.StartPosition = self:GetStartVector3f()
        end
        --AIUtils.CreateIntelGrid(self, self.IntelFramework.PlayableArea)
        self.IntelFramework.IntelGrid = import("/lua/ai/gridintel.lua").Setup(self)
        LOG('IntelGrid '..repr(self.IntelFramework.IntelGrid))
        --self:ForkThread(self.IntelFrameworkThread)
        local massPoints, massCount = import("/lua/sim/markerutilities.lua").GetMarkersByType('Mass')
        local teamCount, teamStarts, allyCount, enemyCount = AIUtils.CalculateTeamdata(self)
        self.IntelFramework.TeamCount = teamCount
        self.IntelFramework.StartPositions = teamStarts
        self.IntelFramework.AllyCount = allyCount
        self.IntelFramework.EnemyCount = enemyCount
        if massCount > 0 and enemyCount > 0 then
            self.IntelFramework.TeamMassShare = math.floor(massCount / teamCount)
        else
            self.IntelFramework.TeamMassShare = massCount
        end
        if allyCount > 0 and enemyCount > 0 and massCount > 0 then
            self.IntelFramework.PlayerMassShare = math.floor(massCount / (allyCount + enemyCount))
        else
            self.IntelFramework.PlayerMassShare = massCount
        end
        LOG('Total Mass Count '..massCount)
        LOG('Team Count '..self.IntelFramework.TeamCount)
        LOG('StartPositions '..repr(self.IntelFramework.StartPositions))
        LOG('Ally Count '..self.IntelFramework.AllyCount)
        LOG('Enemy Count '..self.IntelFramework.EnemyCount)
        LOG('Team Mass Share '..self.IntelFramework.TeamMassShare)
        LOG('Player Mass Share '..self.IntelFramework.PlayerMassShare)
        import("/lua/ai/gridreclaim.lua").Setup(self)
    end,

    IntelFrameworkThread = function(self)
        LOG('Starting Intel Thread')
        WaitTicks(math.random(10,30))
        local intelFramework = self.IntelFramework
        while not self.Status ~= 'defeat' do
            local threatTypes = {
                'Land',
                'AntiAir',
                'Naval',
                'StructuresNotMex',
                'Experimental',
                'AntiSurface'
            }
            local gameTick = GetGameTick()
            for _, t in threatTypes do
                local rawThreats = self:GetThreatsAroundPosition( self.BuilderManagers.MAIN.Position, 16, true, t)
                for _, raw in rawThreats do
                    local gridx, gridz = AIUtils.GetIntelGrid(self.IntelFramework, {raw[1], 0, raw[2]})
                    if self.IntelFramework.IntelGrid[gridx][gridz][t] then
                        self.IntelFramework.IntelGrid[gridx][gridz][t] = raw[3]
                        self.IntelFramework.IntelGrid[gridx][gridz].LastThreatCheck = gameTick
                    end
                end
            end
            for x=intelFramework.IntelGrid.IntelGridXMin, intelFramework.IntelGrid.IntelGridXMax do
                for z=intelFramework.IntelGrid.IntelGridZMin, intelFramework.IntelGrid.IntelGridZMax do
                    if intelFramework.IntelGrid[x][z].LastThreatCheck > 0 and intelFramework.IntelGrid[x][z].LastThreatCheck + 1200 > gameTick then
                        intelFramework.IntelGrid[x][z].Land = 0
                        intelFramework.IntelGrid[x][z].AntiAir = 0
                        intelFramework.IntelGrid[x][z].AntiSurface = 0
                    end
                end
            end
            WaitTicks(60)
        end
    end,
}

-- kept for mod backwards compatibility
local PCBC = import("/lua/editor/platooncountbuildconditions.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")