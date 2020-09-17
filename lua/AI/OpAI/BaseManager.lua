----------------------------------------------------------------------
---- File     :  /lua/ai/OpAI/BaseManager.lua
---- Summary  : Base manager for operations
---- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------

local AIUtils = import('/lua/ai/aiutilities.lua')

local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local BuildingTemplates = import('/lua/BuildingTemplates.lua').BuildingTemplates
local RebuildStructuresTemplate = import('/lua/BuildingTemplates.lua').RebuildStructuresTemplate
local StructureUpgradeTemplates = import('/lua/upgradetemplates.lua').StructureUpgradeTemplates
local Buff = import('/lua/sim/Buff.lua')

local BaseOpAI = import('/lua/ai/opai/baseopai.lua')
local ReactiveAI = import('/lua/ai/opai/ReactiveAI.lua')
local NavalOpAI = import('/lua/ai/opai/NavalOpAI.lua')

local BMBC = '/lua/editor/BaseManagerBuildConditions.lua'
local BMPT = '/lua/ai/opai/BaseManagerPlatoonThreads.lua'

-- Default rebuild numbers for buildings based on type; -1 is infinite
local BuildingCounterDefaultValues = {
    -- Difficulty 1
    {
        Default = 1,
    },

    -- Difficulty 2
    {
        Default = 2,

        Wall = 1,

        T1Sonar = 5,
        T2Sonar = 5,
        T3Sonar = 5,

        T1Radar = 5,
        T2Radar = 5,
        T3Radar = 5,

        T1LandFactory = 5,
        T2LandFactory = 5,
        T3LandFactory = 5,

        T1AirFactory = 10,
        T2AirFactory = 10,
        T3AirFactory = 10,

        T1SeaFactory = 10,
        T2SeaFactory = 10,
        T3SeaFactory = 10,

        T3QuantumGate = 10,

        T1HydroCarbon = 10,
        T1EnergyProduction = 10,
        T2EnergyProduction = 10,
        T3EnergyProduction = 10,

        T1MassExtraction = 10,
        T2MassExtraction = 10,
        T3MassExtraction = 10,

        T3StrategicMissileDefense = 1,
    },

    -- Difficulty 3
    {
        Default = -1,
    },
}

BaseManager = Class {
    -- TO DO LIST:
    -- Expansion at mass positions (Probably a must, but may not fit here - perhaps an OpAI which is enable/disable through bool)
    -- Maybe build T2 shields if no T3 engs are available for Seraphim/UEF
    -- Artillery, Nukes, and TML control (At least toggling nukes and TML required, much want for control of where to attack)
    -- Engineer counts when needing higher tech level engineers (possibly not needed since recovery is hard and not always wanted)

    -- This function just sets up variables local to the new BaseManager Instance
    Create = function(self)
        self.Trash = TrashBag()

        self.Active = false
        self.AIBrain = false
        self.BaseName = false
        self.DefaultEngineerPatrolChain = false
        self.DefaultAirScoutPatrolChain = false
        self.DefaultLandScoutPatrolChain = false
        self.Initialized = false
        self.Position = false
        self.Radius = false
        self.ConstructionAssistBool = false

        self.FactoryBuildRateBuff = nil
        self.EngineerBuildRateBuff = nil

        self.CurrentEngineerCount = 0
        self.EngineerQuantity = 0
        self.EngineersBuilding = 0
        self.NumPermanentAssisting = 0
        self.PermanentAssistCount = 0
        self.MaximumConstructionEngineers = 2

        self.BuildingCounterData = {
            Default = true,
        }

        self.BuildTable = {}
        self.ConstructionEngineers = {}
        self.ExpansionBaseData = {}
        self.FunctionalityStates = {
            AirAttacks = true,
            AirScouting = false,
            AntiAir = true,
            Artillery = true,
            BuildEngineers = true,
            CounterIntel = true,
            EngineerReclaiming = true,
            Engineers = true,
            ExpansionBases = false,
            Fabrication = true,
            GroundDefense = true,
            Intel = true,
            LandAttacks = true,
            LandScouting = false,
            Nukes = false,
            Patrolling = true,
            SeaAttacks = true,
            Shields = true,
            TMLs = true,
            Torpedos = true,
            Walls = true,

            Custom = {},
        }
        self.LevelNames = {}
        self.OpAITable = {}
        self.UnfinishedBuildings = {}
        self.UnfinishedEngineers = {}
        self.UnitUpgrades = {
            DefaultACU = {},
            DefaultSACU = {},
            Shields = {},
        }
        self.UpgradeTable = {}

        -- This table stores data about conditional builds (for experimentals etc...)
        self.ConditionalBuildTable = {} -- Used to build an op unit once the conditions are met

        self.ConditionalBuildData = {
            IsInitiated = false,        -- True if a unit has been issued the build command but has not yet begun building
            IsBuilding = false,        -- True if a conditional build is going on, else false
            NumAssisting = 0,           -- Number of engies assisting the conditional build
            MaxAssisting = 1,           -- Maximum units to assist the current conditional build
            Unit = false,            -- The actual unit being constructed currently
            MainBuilder = false,     -- False if there is currently not a main conditional builder, else the unit building
            Index = 0,               -- Stores the index of the current conditional being built
            WaitSecondsAfterDeath = false, -- Time to wait after conditional build's death before starting a new one.

            IncrementAssisting = function() self.ConditionalBuildData.NumAssisting = self.ConditionalBuildData.NumAssisting + 1 end,
            DecrementAssisting = function() self.ConditionalBuildData.NumAssisting = self.ConditionalBuildData.NumAssisting - 1 end,

            Reset = function()
                self.ConditionalBuildData.IsInitiated = false
                self.ConditionalBuildData.IsBuilding = false
                self.ConditionalBuildData.NumAssisting = 0
                self.ConditionalBuildData.MaxAssisting = 1
                self.ConditionalBuildData.Unit = false
                self.ConditionalBuildData.MainBuilder = false
                self.ConditionalBuildData.Index = 0
                self.ConditionalBuildData.WaitSecondsAfterDeath = false
            end,

            NeedsMoreBuilders = function()
                return self.ConditionalBuildData.IsBuilding and (self.ConditionalBuildData.NumAssisting < self.ConditionalBuildData.MaxAssisting)
            end,
        }
    end,

    -- Level Table format
    -- {
    --     GroupName = Priority, -- Name not in quotes
    -- }
    Initialize = function(self, brain, baseName, markerName, radius, levelTable, diffultySeparate)
        self.Active = true
        if self.Initialized then
            error('*AI ERROR: BaseManager named "' .. baseName .. '" has already been initialized', 2)
        end

        self.Initialized = true
        if not brain.BaseManagers then
            brain.BaseManagers = {}
            brain:PBMRemoveBuildLocation(false, 'MAIN') -- Remove main since we dont use it in ops much
        end

        brain.BaseManagers[baseName] = self -- Store base in table, index by name of base
        self.AIBrain = brain
        self.Position = ScenarioUtils.MarkerToPosition(markerName)
        self.BaseName = baseName
        self.Radius = radius
        for groupName, priority in levelTable do
            if not diffultySeparate then
                self:AddBuildGroup(groupName, priority, false, true) -- Do not spawn units, do not sort
            else
                self:AddBuildGroupDifficulty(groupName, priority, false, true) -- Do not spawn units, do not sort
            end
        end

        self.AIBrain:PBMAddBuildLocation(markerName, radius, baseName) -- Add base to PBM
        self:LoadDefaultBaseCDRs() -- ACU things
        self:LoadDefaultBaseSupportCDRs() -- sACU things
        self:LoadDefaultBaseEngineers() -- All other Engs
        self:LoadDefaultScoutingPlatoons() -- Load in default scouts
        self:LoadDefaultBaseTMLs() -- TMLs
        self:LoadDefaultBaseNukes() -- Nukes
        self:SortGroupNames() -- Force sort since no sorting when adding groups earlier
        self:ForkThread(self.UpgradeCheckThread) -- Start the thread to see if any buildings need upgrades

        -- Check for a default chains for engineers' patrol and scouting
        if Scenario.Chains[baseName..'_EngineerChain'] then
            self:SetDefaultEngineerPatrolChain(baseName..'_EngineerChain')
        end

        if Scenario.Chains[baseName..'_AirScoutChain'] then
            self:SetDefaultAirScoutPatrolChain(baseName..'_AirScoutChain')
        end

        if Scenario.Chains[baseName..'_LandScoutChain'] then
            self:SetDefaultLandScoutPatrolChain(baseName..'_LandScoutChain')
        end
    end,

    InitializedCheck = function(self)
        if not self.Initialized then
            error('*AI ERROR: BaseManager named "'..self.BaseName..'" is not inialized', 2)
        end
    end,

    -- If base is inactive, all functionality at the base manager should stop
    BaseActive = function(self, status)
        self.Active = status
    end,

    -- Allows LD to pass in tables with Difficulty tags at the end of table names ('_D1', '_D2', '_D3')
    InitializeDifficultyTables = function(self, brain, baseName, markerName, radius, levelTable)
        self:Initialize(brain, baseName, markerName, radius, levelTable, true)
    end,

    -- Auto trashbags all threads on a base manager
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    -- When the condition function evaluates to true, the unit with the specified name will be built.
    -- if OnBuilt is specified, that function will be called when the unit is successfully built
    ConditionalBuild = function(self, sUnitName, bRetry, nNumEngineers, tPlatoonAIFunction, tPlatoonData,  fCondition, bKeepAlive)
        if type(fCondition) ~= 'function' then error('Parameter fCondition must be a function.') return end

        table.insert(self.ConditionalBuildTable,
        {
            name = sUnitName,
            data =
            {
                MaxAssist = nNumEngineers,
                BuildCondition = fCondition,
                PlatoonAIFunction = tPlatoonAIFunction,
                PlatoonData = tPlatoonData,
                Retry = bRetry,
                KeepAlive = bKeepAlive,
                Amount = 1,
            },
        })
    end,

    -- Note: if "type" is a unit name, then this creates an AI to build the unit when the conditions are met.
    AddOpAI = function(self, ptype, name, data)
        if not self.AIBrain then
            error('*AI ERROR: No AI Brain for base manager')
            return false
        end

        -- If it's a table of unit names, or a single unit name
        if (type(ptype) == 'table' and not ptype.Platoons)
            or (type(ptype) == 'string' and ScenarioUtils.FindUnit(ptype, Scenario.Armies[self.AIBrain.Name].Units)) then
                table.insert(self.ConditionalBuildTable,
                {
                    name = ptype,
                    data = name,
                })
                return true
        end

        if not self:CheckOpAIName(name) then return false end

        self.OpAITable[name] = BaseOpAI.CreateOpAI(self.AIBrain, self.BaseName, ptype, name, data)

        return self.OpAITable[name]
    end,

    GetOpAI = function(self, name)
        if self.OpAITable[name] then
            return self.OpAITable[name]
        else
            return false
        end
    end,

    -- Make sure name of OpAI doesn't already exist
    CheckOpAIName = function(self, name)
        if self.OpAITable[name] then
            error('*AI ERROR: Duplicate OpAI name: ' .. name .. ' - for base manager: ' .. self.BaseName)
            return false
        end

        return true
    end,

    AddReactiveAI = function(self, triggeringType, reactionType, name, data)
        self:InitializedCheck()
        self.AIBrain:PBMEnableRandomSamePriority()

        if not self:CheckOpAIName(name) then return false end

        self.OpAITable[name] = ReactiveAI.CreateReactiveAI(self.AIBrain, self.BaseName, triggeringType, reactionType, name, data)

        return self.OpAITable[name]
    end,

    -- Add generated naval AI.  Uses different OpAI type because it generates platoon data
    AddNavalAI = function(self, name, data)
        if not self.AIBrain then
            error('*AI ERROR: No AI Brain for base manager')
            return false
        end

        if not self:CheckOpAIName(name) then return false end

        self.OpAITable[name] = NavalOpAI.CreateNavalAI(self.AIBrain, self.BaseName, name, data)
        return self.OpAITable[name]
    end,

    -- Add a group created in the editor to the base manager to be maintained by the manager
    AddBuildGroup = function(self, groupName, priority, spawn, initial)
        -- Make sure the group exists
        if not self:FindGroup(groupName) then
            table.insert(self.LevelNames, {Name = groupName, Priority = priority})

            -- Setup the brain base template for use in the base manager (Don't create so we can get a unitnames table)
            self.AIBrain.BaseTemplates[self.BaseName .. groupName] = {Template={}, List={}, UnitNames = {}, BuildCounter = {}}

            -- Now that we have a group name find it and add data
            self:AddToBuildingTemplate(groupName, self.BaseName .. groupName)

            -- Spawn with SpawnGroup so we can track number of times this unit has existed
            if spawn then
                self:SpawnGroup(groupName)
            end

            if not initial then
                self:SortGroupNames()
            end
        else
            error('*AI DEBUG: Group Name - ' .. groupName .. ' already exists in Base Manager group data', 2)
        end
    end,

    AddBuildGroupDifficulty = function(self, groupName, priority, spawn, initial)
        groupName = groupName .. '_D' .. ScenarioInfo.Options.Difficulty
        self:AddBuildGroup(groupName, priority, spawn, initial)
    end,

    ClearGroupTemplate = function(self, groupName)
        self.AIBrain.BaseTemplate[self.BaseName .. groupLevel] = {Template = {}, List = {}, UnitNames = {}, BuildCounter = {}}
    end,

    -- Find a build group in the class
    FindGroup = function(self, groupName)
        for num, data in self.LevelNames do
            if data.Name == groupName then
                return data
            end
        end
        return false
    end,

    GetPosition = function(self)
        return self.Position
    end,

    GetRadius = function(self)
        return self.Radius
    end,

    SetRadius = function(self, rad)
        self.Radius = rad
    end,

    ---------------------------------------------------------------------------
    -- Functions for tracking the number of engineers working in a base manager
    ---------------------------------------------------------------------------
    AddCurrentEngineer = function(self, num)
        if not num then
            num = 1
        end
        self.CurrentEngineerCount = self.CurrentEngineerCount + num
    end,

    SubtractCurrentEngineer = function(self, num)
        if not num then
            num = 1
        end
        self.CurrentEngineerCount = self.CurrentEngineerCount - 1
    end,

    GetCurrentEngineerCount = function(self)
        return self.CurrentEngineerCount
    end,

    GetMaximumEngineers = function(self)
        return self.EngineerQuantity
    end,

    AddConstructionEngineer = function(self, unit)
        table.insert(self.ConstructionEngineers, unit)
    end,

    RemoveConstructionEngineer = function(self, unit)
        for k, v in self.ConstructionEngineers do
            if v.EntityId == unit.EntityId then
                table.remove(self.ConstructionEngineers, k)
                break
            end
        end
    end,

    SetMaximumConstructionEngineers = function(self, num)
        self.MaximumConstructionEngineers = num
    end,

    GetConstructionEngineerMaximum = function(self)
        return self.MaximumConstructionEngineers
    end,

    GetConstructionEngineerCount = function(self)
        return table.getn(self.ConstructionEngineers)
    end,

    SetConstructionAlwaysAssist = function(self, bool)
        self.ConstructionAssistBool = bool
    end,

    ConstructionAlwaysAssist = function(self)
        return self.ConstructionAssistBool
    end,

    ConstructionNeedsAssister = function(self)
        if not self:ConstructionAlwaysAssist() or self:GetConstructionEngineerCount() == 0 then
            return false
        end
        return true
    end,

    IsConstructionUnit = function(self, unit)
        if not unit or unit.Dead then
            return false
        end

        for k, v in self.ConstructionEngineers do
            if v.EntityId == unit.EntityId then
                return true
            end
        end

        return false
    end,

    SetPermanentAssistCount = function(self, num)
        if num > self.EngineerQuantity then
            error('*Base Manager Error: More permanent assisters than total engineers')
        end
        self.PermanentAssistCount = num
    end,

    GetPermanentAssistCount = function(self)
        return self.PermanentAssistCount
    end,

    SetNumPermanentAssisting = function(self, num)
        self.NumPermanentAssisting = num
    end,

    IncrementPermanentAssisting = function(self)
        self.NumPermanentAssisting = self.NumPermanentAssisting + 1
        return self.NumPermanentAssisting
    end,

    DecrementPermanentAssisting = function(self)
        self.NumPermanentAssisting = self.NumPermanentAssisting - 1
        return self.NumPermanentAssisting
    end,

    GetNumPermanentAssisting = function(self)
        return self.NumPermanentAssisting
    end,

    NeedPermanentFactoryAssist = function(self)
        if table.getn(self:GetAllBaseFactories()) >= 1 and self:GetPermanentAssistCount() > self:GetNumPermanentAssisting() then
            return true
        end
        return false
    end,

    SetEngineerCount = function(self, count)
        -- If we have a table, we have various possible ways of counting engineers
        -- {tNum1, tNum2, tNum3} - This is a difficulty defined total number of engs
        -- {{tNum1, tNum2, tNum3,}, {aNum1, aNum2, aNum3}} - This is a difficulty defined total and permanent assisters
        -- {tNum, aNum} - This is a single defined total with permanent assist
        -- num - this is the number of total engineers
        if type(count) == 'table' then
            -- Table of tables means set the permanent assist count with total count
            if type(count[1]) == 'table' then
                self:SetTotalEngineerCount(count[1][ScenarioInfo.Options.Difficulty])
                self:SetPermanentAssistCount(count[2][ScenarioInfo.Options.Difficulty])
            -- Table with 3 entries is a dificulty table
            elseif table.getn(count) == 3 then
                self:SetTotalEngineerCount(count[ScenarioInfo.Options.Difficulty])
            -- Table with 2 entries means first is total engs, 2nd is num permanent assisting
            elseif table.getn(count) == 2 then
                self:SetTotalEngineerCount(count[1])
                self:SetPermanentAssistCount(count[2])
            -- Unknown number of entries
            else
                error('*Base Manager Error: Unknown number of entries passed to SetEngineerCount')
            end
        else
            self:SetTotalEngineerCount(count)
        end
    end,

    SetTotalEngineerCount = function(self, num)
        self.EngineerQuantity = num
        ScenarioInfo.VarTable[self.BaseName .. '_EngineerNumber'] = num
    end,

    GetEngineersBuilding = function(self)
        return self.EngineersBuilding
    end,

    SetEngineersBuilding = function(self, count)
        self.EngineersBuilding = self.EngineersBuilding + count
    end,

    SetSupportACUCount = function(self, count)
        ScenarioInfo.VarTable[self.BaseName ..'_sACUNumber'] = count
    end,

    SetFactoryBuildRateBuff = function(self, buffName)
        self.FactoryBuildRateBuff = buffName
    end,

    SetEngineerBuildRateBuff = function(self, buffName)
        self.EngineerBuildRateBuff = buffName
    end,

    ---------------------------------------------------
    -- Get/Set of default chains for base funcitonality
    ---------------------------------------------------
    GetDefaultEngineerPatrolChain = function(self)
        return self.DefaultEngineerPatrolChain
    end,

    SetDefaultEngineerPatrolChain = function(self, chainName)
        self.DefaultEngineerPatrolChain = chainName
        return true
    end,

    GetDefaultAirScoutPatrolChain = function(self)
        return self.DefaultAirScoutPatrolChain
    end,

    SetDefaultAirScoutPatrolChain = function(self, chainName)
        self.DefaultAirScoutPatrolChain = chainName
        return true
    end,

    GetDefaultLandScoutPatrolChain = function(self)
        return self.DefaultLandScoutPatrolChain
    end,

    SetDefaultLandScoutPatrolChain = function(self, chainName)
        self.DefaultLandScoutPatrolChain = chainName
        return true
    end,

    -- Returns all factories working at a base manager
    GetAllBaseFactories = function(self, category)
        if not category then
            return self.AIBrain:PBMGetAllFactories(self.BaseName)
        end

        -- Filter factories by category passed in
        local retFacs = {}
        for k, v in self.AIBrain:PBMGetAllFactories(self.BaseName) do
            if EntityCategoryContains(category, v) then
                table.insert(retFacs, v)
            end
        end

        return retFacs
    end,

    -- Add in the ability for an expansion base to move out and help another base manager at another location
    -- Functionality should mean that you simply specifiy the name of the base and it will then send out an
    -- engineer to build it.  You can also specify the number of engineers you would like to support with
    -- baseData is a field that does nothing currently.  If we ever need more data (transports maybe) it would
    -- be housed there.
    AddExpansionBase = function(self, baseName, engQuantity, baseData)
        if not engQuantity then
            engQuantity = 1
        end

        table.insert(self.ExpansionBaseData, {BaseName = baseName, Engineers = engQuantity, IncomingEngineers = 0})
        self.FunctionalityStates.ExpansionBases = true
        if baseData then
            -- Setup base here
        end
    end,

    -----------------------------------------------
    -- Base Manager Unit Upgrade Level functions --
    -----------------------------------------------
    -- Set what type of upgrades you want on what types of units.  Applies to only ACU and SACU right now.
    -- upgradeTable houses the data for upgrades in a table of strings, ex: {'ResourceEnhancement', 'T3Engineering'}
    -- unitName is the unit type, DefaultACU and DefaultSACU use the appropriate unit based on faction
    -- startActive if true the unit will start with the enhancements, if not then they will upgrade to the enhancements.
    SetUnitUpgrades = function(self, upgradeTable, unitName, startActive)
        if not unitName then
            error('*AI Debug: No unit name given for unit upgrades: Base named - ' .. self.BaseName, 2)
            return false
        else
            self.UnitUpgrades[unitName] = upgradeTable
        end

        if startActive then
            local units = {}
            if unitName == 'DefaultACU' then
                for k, v in AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.COMMAND, self.Position, self.Radius) do
                    table.insert(units, v)
                end
            elseif unitName == 'DefaultSACU' then
                for k, v in AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.SUBCOMMANDER, self.Position, self.Radius) do
                    table.insert(units, v)
                end
            end

            for num, unit in units do
                for uNum, upgrade in upgradeTable do
                    unit:CreateEnhancement(upgrade)
                end
            end
        end
    end,

    -- Determines if a specific unit needs upgrades, returns name of upgrade if needed
    UnitNeedsUpgrade = function(self, unit, unitType)
        if unit.Dead then
            return false
        end

        -- Find appropriate data about unit upgrade info
        local upgradeTable = false
        if unitType then
            upgradeTable = self.UnitUpgrades[unitType]
        else
            upgradeTable = self.UnitUpgrades[unit.UnitName]
        end

        if not upgradeTable then
            return false
        end

        local allEnhancements = unit:GetBlueprint().Enhancements
        if not allEnhancements then
            return false
        end

        for _, upgradeName in upgradeTable do
            -- Find the upgrade in the unit's bp
            local bpUpgrade = allEnhancements[upgradeName]
            if bpUpgrade then
                if not unit:HasEnhancement(upgradeName) then
                    -- If we already have upgarde at that slot, remove it first
                    if SimUnitEnhancements and SimUnitEnhancements[unit.EntityId] and SimUnitEnhancements[unit.EntityId][bpUpgrade.Slot] then
                        return SimUnitEnhancements[unit.EntityId][bpUpgrade.Slot] .. 'Remove'
                    -- Check for required upgrades
                    elseif bpUpgrade.Prerequisite and not unit:HasEnhancement(bpUpgrade.Prerequisite) then
                        return bpUpgrade.Prerequisite
                    -- No requirement and stop available, return upgrade name
                    else
                        return upgradeName
                    end
                end
            else
                error('*Base Manager Error: ' .. self.BaseName .. ', enhancement: ' .. upgradeName .. ' was not found in the unit\'s bp.')
            end
        end

        return false
    end,

    SetACUUpgrades = function(self, upgradeTable, startActive)
        self:SetUnitUpgrades(upgradeTable, 'DefaultACU', startActive)
    end,

    SetSACUUpgrades = function(self, upgradeTable, startActive)
        self:SetUnitUpgrades(upgradeTable, 'DefaultSACU', startActive)
    end,

    UpgradeCheckThread = function(self)
        local armyIndex = self.AIBrain:GetArmyIndex()
        while true do
            if self.Active then
                for k, v in self.UpgradeTable do
                    local unit = ScenarioInfo.UnitNames[armyIndex][v.UnitName]
                    if unit and not unit.Dead then
                        -- Cybran engie stations are never in 'Idle' state but in 'AssistingCommander' state 
                        if not EntityCategoryContains(ParseEntityCategory(v.FinalUnit), unit) and (unit:IsIdleState() or unit:IsUnitState('AssistingCommander')) and not unit:IsBeingBuilt() then
                            self:ForkThread(self.BaseManagerUpgrade, unit, v.UnitName)
                        end
                    end
                end
            end
            local waitTime = Random(3, 5)
            WaitSeconds(waitTime)
        end
    end,

    -- Sort build groups by priority
    SortGroupNames = function(self)
        local sortedList = {}
        for i = 1, table.getn(self.LevelNames) do
            local highest, highPos
            for num, data in self.LevelNames do
                if not highest or data.Priority > highest.Priority then
                    highest = data
                    highPos = num
                end
            end
            sortedList[i] = highest
            table.remove(self.LevelNames, highPos)
        end
        self.LevelNames = sortedList
    end,

    -- Sets a group's priority
    SetGroupPriority = function(self, groupName, priority)
        for num, data in self.LevelNames do
            if data.Name == groupName then
                data.Priority = priority
                break
            end
        end
        self:SortGroupNames()
    end,

    -- Spawns a group, tracks number of times it has been built, gives nuke and anti-nukes ammo
    SpawnGroup = function(self, groupName, uncapturable, balance)
        local unitGroup = ScenarioUtils.CreateArmyGroup(self.AIBrain.Name, groupName, nil, balance)

        for _, v in unitGroup do
            if self.FactoryBuildRateBuff then
                Buff.ApplyBuff(v, self.FactoryBuildRateBuff)
            end
            if self.EngineerBuildRateBuff then
                Buff.ApplyBuff(v, self.EngineerBuildRateBuff)
            end
            self:DecrementUnitBuildCounter(v.UnitName)
            if uncapturable then
                v:SetCapturable(false)
                v:SetReclaimable(false)
            end
            if EntityCategoryContains(categories.SILO, v) then
                if ScenarioInfo.Options.Difficulty == 1 then
                    v:GiveNukeSiloAmmo(1)
                    v:GiveTacticalSiloAmmo(1)
                else
                    v:GiveNukeSiloAmmo(2)
                    v:GiveTacticalSiloAmmo(2)
                end
            end
        end
    end,

    -- If we want a group in the base manager to be wreckage, use this function
    SpawnGroupAsWreckage = function(self, groupName)
        local unitGroup = ScenarioUtils.CreateArmyGroup(self.AIBrain.Name, groupName, true)
    end,

    -- Sets Engineer Count, spawns in all groups that have priority greater than zero
    StartNonZeroBase = function(self, engineerNumber, uncapturable)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName ..'_EngineerNumber'] then
            self:SetEngineerCount(0)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end

        for num, data in self.LevelNames do
            if data.Priority and data.Priority > 0 then
                if ScenarioInfo.LoadBalance and ScenarioInfo.LoadBalance.Enabled then
                    table.insert(ScenarioInfo.LoadBalance.SpawnGroups, {self, data.Name, uncapturable})
                else
                    self:SpawnGroup(data.Name, uncapturable)
                end
            end
        end
    end,

    StartDifficultyBase = function(self, groupNames, engineerNumber, uncapturable)
        local newNames = {}
        for k, v in groupNames do
            table.insert(newNames, v .. '_D' .. ScenarioInfo.Options.Difficulty)
        end
        self:StartBase(newNames, engineerNumber, uncapturable)
    end,

    -- Sets engineer count, spawns in all groups passed in in groupNames table
    StartBase = function(self, groupNames, engineerNumber, uncapturable)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName ..'_EngineerNumber'] then
            self:SetEngineerCount(0)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end

        for num, name in groupNames do
            local group = self:FindGroup(name)
            if not group then
                error('*AI DEBUG: Unable to create group - ' .. name .. ' - Data does not exist in Base Manager', 2)
            else
                self:SpawnGroup(group.Name, uncapturable)
            end
        end
    end,

    -- Sets engineer count and spawns in no groups
    StartEmptyBase = function(self, engineerNumber)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName ..'_EngineerNumber'] then
            self:SetEngineerCount(1)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end
    end,

    -- Thread that will upgrade factories, radar, etc to next level
    BaseManagerUpgrade = function(self, unit, unitName)
        local aiBrain = unit:GetAIBrain()
        local factionIndex = aiBrain:GetFactionIndex()
        local armyIndex = aiBrain:GetArmyIndex()
        local upgradeID = aiBrain:FindUpgradeBP(unit.UnitId, StructureUpgradeTemplates[factionIndex])
        if upgradeID then
            IssueClearCommands({unit})
            IssueUpgrade({unit}, upgradeID)
        end

        local upgrading = true
        local newUnit = false
        while not unit.Dead and upgrading do
            WaitSeconds(3)
            upgrading = false
            if unit and not unit.Dead then
                if not newUnit then
                    newUnit = unit.UnitBeingBuilt
                end
                upgrading = true
            end
        end
        ScenarioInfo.UnitNames[armyIndex][unitName] = newUnit
    end,

    CheckStructureBuildable = function(self, buildingType)
        if self.BuildTable[buildingType] == false then
            return false
        end

        return true
    end,

    AddToBuildingTemplate = function(self, groupName, addName)
        local tblUnit = ScenarioUtils.AssembleArmyGroup(self.AIBrain.Name, groupName)
        local factionIndex = self.AIBrain:GetFactionIndex()
        local template = self.AIBrain.BaseTemplates[addName].Template
        local list = self.AIBrain.BaseTemplates[addName].List
        local unitNames = self.AIBrain.BaseTemplates[addName].UnitNames
        local buildCounter = self.AIBrain.BaseTemplates[addName].BuildCounter
        if not tblUnit then
            error('*AI DEBUG - Group: ' .. repr(name) .. ' not found for Army: ' .. repr(army), 2)
        else
            -- Convert building to the proper type to be built if needed (ex: T2 and T3 factories to T1)
            for i, unit in tblUnit do
                for k, unitId in RebuildStructuresTemplate[factionIndex] do
                    if unit.type == unitId[1] then
                        table.insert(self.UpgradeTable, {FinalUnit = unit.type, UnitName = i,})
                        unit.buildtype = unitId[2]
                        break
                    end
                end
                if not unit.buildtype then
                    unit.buildtype = unit.type
                end
            end
            for i, unit in tblUnit do
                self:StoreStructureName(i, unit, unitNames)
                for j, buildList in BuildingTemplates[factionIndex] do -- BuildList[1] is type ("T1LandFactory"); buildList[2] is unitId (ueb0101)
                    local unitPos = {unit.Position[1], unit.Position[3], 0}
                    if unit.buildtype == buildList[2] and buildList[1] ~= 'T3Sonar' then -- If unit to be built is the same id as the buildList unit it needs to be added
                        self:StoreBuildCounter(buildCounter, buildList[1], buildList[2], unitPos, i)

                        local inserted = false
                        for k, section in template do -- Check each section of the template for the right type
                            if section[1][1] == buildList[1] then
                                table.insert(section, unitPos) -- Add position of new unit if found
                                list[unit.buildtype].AmountWanted = list[unit.buildtype].AmountWanted + 1 -- Increment num wanted if found
                                inserted = true
                                break
                            end
                        end
                        if not inserted then -- If section doesn't exist create new one
                            table.insert(template, {{buildList[1]}, unitPos}) -- add new build type to list with new unit
                            list[unit.buildtype] =  {StructureType = buildList[1], StructureCategory = unit.buildtype, AmountNeeded = 0, AmountWanted = 1, CloseToBuilder = nil} -- add new section of build list with new unit type information
                        end
                        break
                    end
                end
            end
        end
    end,

    StoreStructureName = function(self, unitName, unitData, namesTable)
        if not namesTable[unitData.Position[1]] then
            namesTable[unitData.Position[1]] = {}
        end
        namesTable[unitData.Position[1]][unitData.Position[3]] = unitName
    end,

    StoreBuildCounter = function(self, buildCounter, buildingType, buildingId, unitPos, unitName)
        if not buildCounter[unitPos[1]] then
            buildCounter[unitPos[1]] = {}
        end
        buildCounter[unitPos[1]][unitPos[2]] = {}
        buildCounter[unitPos[1]][unitPos[2]].BuildingID = buildingId
        buildCounter[unitPos[1]][unitPos[2]].BuildingType = buildingType
        buildCounter[unitPos[1]][unitPos[2]].Position = unitPos
        if unitName then
            buildCounter[unitPos[1]][unitPos[2]].UnitName = unitName
        end
        if self.BuildingCounterData.Default then
            buildCounter[unitPos[1]][unitPos[2]].Counter = self:BuildingCounterDifficultyDefault(buildingType)
        end
    end,

    BuildingCounterDifficultyDefault = function(self, buildingType)
        local diff = ScenarioInfo.Options.Difficulty
        if not diff then diff = 1 end
        for k, v in BuildingCounterDefaultValues[diff] do
            if buildingType == k then
                return v
            end
        end

        return BuildingCounterDefaultValues[diff].Default
    end,

    CheckUnitBuildCounter = function(self, location, buildCounter)
        for xVal, xData in buildCounter do
            if xVal == location[1] then
                for yVal, yData in xData do
                    if yVal == location[2] then
                        if yData.Counter > 0 or yData.Counter == -1 then
                            return true
                        else
                            return false
                        end
                    end
                end
            end
        end

        return false
    end,

    DecrementUnitBuildCounter = function(self, unitName)
        for levelNum, levelData in self.LevelNames do
            for firstNum, firstData in self.AIBrain.BaseTemplates[self.BaseName .. levelData.Name].BuildCounter do
                for secondNum, secondData in firstData do
                    if secondData.UnitName == unitName then
                        if secondData.Counter > 0 then
                            secondData.Counter = secondData.Counter - 1
                        end
                        return true
                    end
                end
            end
        end

        return false
    end,

    -- Enable/Disable functionality of base parts through functions
    SetActive = function(self, actType, val)
        if self.ActivationFunctions[actType..'Active'] then
            self.ActivationFunctions[actType..'Active'](self, val)
        else
            error('*AI DEBUG: Invalid Activation type type - ' .. actType, 2)
        end
    end,

    ActivationFunctions = {
        ShieldsActive = function(self, val)
            local shields = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.SHIELD * categories.STRUCTURE, self.Position, self.Radius)
            for k, v in shields do
                if val then
                    v:OnScriptBitSet(0) -- If turning on shields
                else
                    v:OnScriptBitClear(0) -- If turning off shields
                end
            end
            self.FunctionalityStates.Shields = val
        end,

        FabricationActive = function(self, val)
            local fabs = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.MASSFABRICATION * categories.STRUCTURE, self.Position, self.Radius)
            for k, v in fabs do
                if val then
                    v:OnScriptBitClear(4) -- If turning on
                else
                    v:OnScriptBitSet(4) -- If turning off
                end
            end
            self.FunctionalityStates.Fabrication = val
        end,

        IntelActive = function(self, val)
            local intelUnits = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, (categories.RADAR + categories.SONAR + categories.OMNI) * categories.STRUCTURE, self.Position, self.Radius)
            for k, v in intelUnits do
                if val then
                    v:OnScriptBitClear(3) -- If turning on
                else
                    v:OnScriptBitSet(3) -- If turning off
                end
            end
            self.FunctionalityStates.Intel = val
        end,

        CounterIntelActive = function(self, val)
            local intelUnits = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.COUNTERINTELLIGENCE * categories.STRUCTURE, self.Position, self.Radius)
            for k, v in intelUnits do
                if val then
                    v:OnScriptBitClear(3) -- If turning on intel
                else
                    v:OnScriptBitSet(2) -- If turning off intel
                end
            end
            self.FunctionalityStates.CounterIntel = val
        end,

        TMLActive = function(self, val)
            self.FunctionalityStates.TMLs = val
        end,

        NukeActive = function(self, val)
            self.FunctionalityStates.Nukes = val
        end,

        PatrolActive = function(self, val)
            self.FunctionalityStates.Patrolling = val
        end,

        ReclaimActive = function(self, val)
            self.FunctionalityStates.EngineerReclaiming = val
        end,

        LandScoutingActive = function(self, val)
            self.FunctionalityStates.LandScouting = val
        end,

        AirScoutingActive = function(self, val)
            self.FunctionalityStates.AirScouting = val
        end,
    },

    -- Enable/Disable building of buildings and stuff
    SetBuild = function(self, buildType, val)
        if not self.Active then
            return false
        end
        if self.BuildFunctions['Build'..buildType] then
            self.BuildFunctions['Build'..buildType](self, val)
        else
            error('*AI DEBUG: Invalid build type - ' .. buildType, 2)
        end
    end,

    -- Disable all buildings
    SetBuildAllStructures = function(self, val)
        for k, v in self.BuildFunctions do
            if k ~= 'BuildEngineers' then
                v(self, val)
            end
        end
    end,

    BuildFunctions = {
        BuildEngineers = function(self, val)
            self.FunctionalityStates.BuildEngineers = val
        end,

        BuildAntiAir = function(self, val)
            self.BuildTable['T1AADefense'] = val
            self.BuildTable['T2AADefense'] = val
            self.BuildTable['T3AADefense'] = val
        end,

        BuildGroundDefense = function(self, val)
            self.BuildTable['T1GroundDefense'] = val
            self.BuildTable['T2GroundDefense'] = val
            self.BuildTable['T3GroundDefense'] = val
        end,

        BuildTorpedo = function(self, val)
            self.BuildTable['T1NavalDefense'] = val
            self.BuildTable['T2NavalDefense'] = val
            self.BuildTable['T3NavalDefense'] = val
        end,

        BuildAirFactories = function(self, val)
            self.BuildTable['T1AirFactory'] = val
            self.BuildTable['T2AirFactory'] = val
            self.BuildTable['T3AirFactory'] = val
        end,

        BuildLandFactories = function(self, val)
            self.BuildTable['T1LandFactory'] = val
            self.BuildTable['T2LandFactory'] = val
            self.BuildTable['T3LandFactory'] = val
        end,

        BuildSeaFactories = function(self, val)
            self.BuildTable['T1Seafactory'] = val
            self.BuildTable['T2Seafactory'] = val
            self.BuildTable['T3Seafactory'] = val
        end,

        BuildFactories = function(self, val)
            self.BuildFunctions['BuildAirFactories'](self, val)
            self.BuildFunctions['BuildSeaFactories'](self, val)
            self.BuildFunctions['BuildLandFactories'](self, val)
        end,

        BuildMissileDefense = function(self, val)
            self.BuildTable['T1StrategicMissileDefense'] = val
            self.BuildTable['T2StrategicMissileDefense'] = val
            self.BuildTable['T3StrategicMissileDefense'] = val
            self.BuildTable['T1MissileDefense'] = val
            self.BuildTable['T2MissileDefense'] = val
            self.BuildTable['T3MissileDefense'] = val
        end,

        BuildShields = function(self, val)
            self.BuildTable['T3ShieldDefense'] = val
            self.BuildTable['T2ShieldDefense'] = val
            self.BuildTable['T1ShieldDefense'] = val
        end,

        BuildArtillery = function(self, val)
            self.BuildTable['T3Artillery'] = val
            self.BuildTable['T2Artillery'] = val
            self.BuildTable['T1Artillery'] = val
        end,

        BuildExperimentals = function(self, val)
            self.BuildTable['T4LandExperimental1'] = val
            self.BuildTable['T4LandExperimental2'] = val
            self.BuildTable['T4AirExperimental1'] = val
            self.BuildTable['T4SeaExperimental1'] = val
        end,

        BuildWalls = function(self, val)
            self.BuildTable['Wall'] = val
        end,

        BuildDefenses = function(self, val)
            self.BuildFunctions['BuildAntiAir'](self, val)
            self.BuildFunctions['BuildGroundDefense'](self, val)
            self.BuildFunctions['BuildTorpedo'](self, val)
            self.BuildFunctions['BuildArtillery'](self, val)
            self.BuildFunctions['BuildShields'](self, val)
            self.BuildFunctions['BuildWalls'](self, val)
        end,

        BuildJammers = function(self, val)
            self.BuildTable['T1RadarJammer'] = val
            self.BuildTable['T2RadarJammer'] = val
            self.BuildTable['T3RadarJammer'] = val
        end,

        BuildRadar = function(self, val)
            self.BuildTable['T3Radar'] = val
            self.BuildTable['T2Radar'] = val
            self.BuildTable['T1Radar'] = val
        end,

        BuildSonar = function(self, val)
            self.BuildTable['T3Sonar'] = val
            self.BuildTable['T2Sonar'] = val
            self.BuildTable['T1Sonar'] = val
        end,

        BuildIntel = function(self, val)
            self.BuildFunctions['BuildSonar'](self, val)
            self.BuildFunctions['BuildRadar'](self, val)
            self.BuildFunctions['BuildJammers'](self, val)
        end,

        BuildMissiles = function(self, val)
            self.BuildTable['T3StrategicMissile'] = val
            self.BuildTable['T2StrategicMissile'] = val
            self.BuildTable['T1StrategicMissile'] = val
        end,

        BuildFabrication = function(self, val)
            self.BuildTable['T3MassCreation'] = val
            self.BuildTable['T2MassCreation'] = val
            self.BuildTable['T1MassCreation'] = val
        end,

        BuildAirStaging = function(self, val)
            self.BuildTable['T1AirStagingPlatform'] = val
            self.BuildTable['T2AirStagingPlatform'] = val
            self.BuildTable['T3AirStagingPlatform'] = val
        end,

        BuildMassExtraction = function(self, val)
            self.BuildTable['T1Resource'] = val
            self.BuildTable['T2Resource'] = val
            self.BuildTable['T3Resource'] = val
        end,

        BuildEnergyProduction = function(self, val)
            self.BuildTable['T1EnergyProduction'] = val
            self.BuildTable['T2EnergyProduction'] = val
            self.BuildTable['T3EnergyProduction'] = val
            self.BuildTable['T1HydroCarbon'] = val
            self.BuildTable['T2HydroCarbon'] = val
            self.BuildTable['T3HydroCarbon'] = val
        end,

        BuildStorage = function(self, val)
            self.BuildTable['MassStorage'] = val
            self.BuildTable['EnergyStorage'] = val
        end,
    },

    -------------------------------------
    -- Default builders for base managers
    -------------------------------------
    LoadDefaultBaseEngineers = function(self)
        local defaultBuilder
        -- The Engineer AI Thread
        for i = 1, 3 do
            defaultBuilder = {
                BuilderName = 'T'..i..'BaseManaqer_EngineersWork_' .. self.BaseName,
                PlatoonTemplate = self:CreateEngineerPlatoonTemplate(i),
                Priority = 1,
                PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerEngineerPlatoonSplit'},
                BuildConditions = {
                    {BMBC, 'BaseManagerNeedsEngineers', {self.BaseName}},
                    {BMBC, 'BaseActive', {self.BaseName}},
                },
                PlatoonData = {
                    BaseName = self.BaseName,
                },
                PlatoonType = 'Any',
                RequiresConstruction = false,
                LocationType = self.BaseName,
            }
            self.AIBrain:PBMAddPlatoon(defaultBuilder)
        end

        -- Disband platoons - engineers built here
        for i = 1, 3 do
            for j = 1, 5 do
                for num, pType in {'Air', 'Land', 'Sea'} do
                    defaultBuilder = {
                        BuilderName = 'T'..i..'BaseManagerEngineerDisband_' .. j .. 'Count_' .. self.BaseName,
                        PlatoonAIPlan = 'DisbandAI',
                        PlatoonTemplate = self:CreateEngineerPlatoonTemplate(i, j),
                        Priority = 300 * i,
                        PlatoonType = pType,
                        RequiresConstruction = true,
                        LocationType = self.BaseName,
                        PlatoonData = {
                            NumBuilding = j,
                            BaseName = self.BaseName,
                        },
                        BuildConditions = {
                            {BMBC, 'BaseEngineersEnabled', {self.BaseName}},
                            {BMBC, 'BaseBuildingEngineers', {self.BaseName}},
                            {BMBC, 'HighestFactoryLevel', {i, self.BaseName}},
                            {BMBC, 'FactoryCountAndNeed', {i, j, pType, self.BaseName}},
                            {BMBC, 'BaseActive', {self.BaseName}},
                        },
                        PlatoonBuildCallbacks = {{BMBC, 'BaseManagerEngineersStarted'},},
                        InstanceCount = 3,
                        BuildTimeOut = 10, -- Timeout really fast because they dont need to really finish
                    }
                    self.AIBrain:PBMAddPlatoon(defaultBuilder)
                end
            end
        end
    end,

    LoadDefaultBaseCDRs = function(self)
        -- CDR Build
        local defaultBuilder = {
            BuilderName = 'BaseManager_CDRPlatoon_' .. self.BaseName,
            PlatoonTemplate = self:CreateCommanderPlatoonTemplate(),
            Priority = 1,
            PlatoonType = 'Any',
            RequiresConstruction = false,
            LocationType = self.BaseName,
            PlatoonAddFunctions = {
                -- {'/lua/ai/opai/OpBehaviors.lua', 'CDROverchargeBehavior'}, -- TODO: Re-add once it doesnt interfere with BM engineer thread
                {BMPT, 'UnitUpgradeBehavior'},
            },
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerSingleEngineerPlatoon'},
            BuildConditions = {
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)
    end,

    LoadDefaultBaseSupportCDRs = function(self)
        -- sCDR Build
        local defaultBuilder = {
            BuilderName = 'BaseManager_sCDRPlatoon_' .. self.BaseName,
            PlatoonTemplate = self:CreateSupportCommanderPlatoonTemplate(),
            Priority = 1,
            PlatoonType = 'Any',
            RequiresConstruction = false,
            LocationType = self.BaseName,
            PlatoonAddFunctions = {
                {BMPT, 'UnitUpgradeBehavior'},
            },
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerSingleEngineerPlatoon'},
            BuildConditions = {
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)

        -- Disband platoon
        defaultBuilder = {
            BuilderName = 'BaseManager_sACUDisband_' .. self.BaseName,
            PlatoonAIPlan = 'DisbandAI',
            PlatoonTemplate = self:CreateSupportCommanderPlatoonTemplate(),
            Priority = 900,
            PlatoonType = 'Gate',
            RequiresConstruction = true,
            LocationType = self.BaseName,
            BuildConditions = {
                    {BMBC, 'BaseEngineersEnabled', {self.BaseName}},
                    {BMBC, 'NumUnitsLessNearBase', {self.BaseName, ParseEntityCategory('SUBCOMMANDER'), self.BaseName ..'_sACUNumber'}},
                    {BMBC, 'BaseActive', {self.BaseName}},
                },
            InstanceCount = 2,
            BuildTimeOut = 10, -- Timeout really fast because they dont need to really finish
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)
    end,

    LoadDefaultScoutingPlatoons = function(self)
        -- Land Scouts
        local defaultBuilder = {
            BuilderName = 'BaseManager_LandScout_' .. self.BaseName,
            PlatoonTemplate = self:CreateLandScoutPlatoon(),
            Priority = 500,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerScoutingAI'},
            BuildConditions = {
                {BMBC, 'LandScoutingEnabled', {self.BaseName,}},
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
            PlatoonType = 'Land',
            RequiresConstruction = true,
            LocationType = self.BaseName,
            InstanceCount = 1,
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)

        -- T1 Air Scouts
        defaultBuilder = {
            BuilderName = 'BaseManager_T1AirScout_' .. self.BaseName,
            PlatoonTemplate = self:CreateAirScoutPlatoon(1),
            Priority = 500,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerScoutingAI'},
            BuildConditions = {
                {BMBC, 'HighestFactoryLevelType', {1, self.BaseName, 'Air'}},
                {BMBC, 'AirScoutingEnabled', {self.BaseName,}},
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
            PlatoonType = 'Air',
            RequiresConstruction = true,
            LocationType = self.BaseName,
            InstanceCount = 1,
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)

        -- T2 Air Scouts
        defaultBuilder = {
            BuilderName = 'BaseManager_T2AirScout_' .. self.BaseName,
            PlatoonTemplate = self:CreateAirScoutPlatoon(2),
            Priority = 750,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerScoutingAI'},
            BuildConditions = {
                {BMBC, 'HighestFactoryLevelType', {2, self.BaseName, 'Air'}},
                {BMBC, 'AirScoutingEnabled', {self.BaseName,}},
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
            PlatoonType = 'Air',
            RequiresConstruction = true,
            LocationType = self.BaseName,
            InstanceCount = 1,
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)

        -- T3 Air Scouts
        defaultBuilder = {
            BuilderName = 'BaseManager_T3AirScout_' .. self.BaseName,
            PlatoonTemplate = self:CreateAirScoutPlatoon(3),
            Priority = 1000,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerScoutingAI'},
            BuildConditions = {
                {BMBC, 'HighestFactoryLevelType', {3, self.BaseName, 'Air'}},
                {BMBC, 'AirScoutingEnabled', {self.BaseName,}},
                {BMBC, 'BaseActive', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
            PlatoonType = 'Air',
            RequiresConstruction = true,
            LocationType = self.BaseName,
            InstanceCount = 1,
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)
    end,

    LoadDefaultBaseTMLs = function(self)
        local defaultBuilder = {
            BuilderName = 'BaseManager_TMLPlatoon_' .. self.BaseName,
            PlatoonTemplate = self:CreateTMLPlatoonTemplate(),
            Priority = 300,
            PlatoonType = 'Any',
            RequiresConstruction = false,
            LocationType = self.BaseName,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerTMLAI'},
            BuildConditions = {
                {BMBC, 'BaseActive', {self.BaseName}},
                {BMBC, 'TMLsEnabled', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)
    end,

    LoadDefaultBaseNukes = function(self)
        local defaultBuilder = {
            BuilderName = 'BaseManager_NukePlatoon_' .. self.BaseName,
            PlatoonTemplate = self:CreateNukePlatoonTemplate(),
            Priority = 400,
            PlatoonType = 'Any',
            RequiresConstruction = false,
            LocationType = self.BaseName,
            PlatoonAIFunction = {'/lua/ai/opai/BaseManagerPlatoonThreads.lua', 'BaseManagerNukeAI'},
            BuildConditions = {
                {BMBC, 'BaseActive', {self.BaseName}},
                {BMBC, 'NukesEnabled', {self.BaseName}},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
        self.AIBrain:PBMAddPlatoon(defaultBuilder)
    end,

    CreateTMLPlatoonTemplate = function(self)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'TMLTemplate',
            'NoPlan',
            {'ueb2108', 1, 1, 'Attack', 'None'},
        }
        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateNukePlatoonTemplate = function(self)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'NukeTemplate',
            'NoPlan',
            {'ueb2305', 1, 1, 'Attack', 'None'},
        }
        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateLandScoutPlatoon = function(self)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'LandScoutTemplate',
            'NoPlan',
            {'uel0101', 1, 1, 'Scout', 'None'},
        }
        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateAirScoutPlatoon = function(self, techLevel)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'AirScoutTemplate',
            'NoPlan',
            {'uea', 1, 1, 'Scout', 'None'},
        }

        if techLevel == 3 then
            template[3][1] = template[3][1] .. '0302'
        else
            template[3][1] = template[3][1] .. '0101'
        end

        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateCommanderPlatoonTemplate = function(self)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'CommanderTemplate',
            'NoPlan',
            {'uel0001', 1, 1, 'Support', 'None'},
        }
        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateSupportCommanderPlatoonTemplate = function(self)
        local faction = self.AIBrain:GetFactionIndex()
        local template = {
            'CommanderTemplate',
            'NoPlan',
            {'uel0301', 1, 1, 'Support', 'None'},
        }
        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,

    CreateEngineerPlatoonTemplate = function(self, techLevel, platoonSize)
        local faction = self.AIBrain:GetFactionIndex()
        local size = platoonSize or 5
        local template = {
            'EngineerThing',
            'NoPlan',
            {'uel', 1, size, 'Support', 'None'},
        }

        if techLevel == 1 then
            template[3][1] = template[3][1] .. '0105'
        elseif techLevel == 2 then
            template[3][1] = template[3][1] .. '0208'
        else
            template[3][1] = template[3][1] .. '0309'
        end

        template = ScenarioUtils.FactionConvert(template, faction)

        return template
    end,
}

function CreateBaseManager(brain, baseName, markerName, radius, levelTable)
    local bManager = BaseManager()
    bManager:Create()
    if brain and baseName and markerName and radius then
        bManager:Initialize(brain, baseName, markerName, radius, levelTable)
    end

    return bManager
end
