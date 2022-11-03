----------------------------------------------------------------------
---- File     :  /lua/ai/OpAI/BaseManager.lua
---- Summary  : Base manager for operations
---- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------

---@alias SaveFile
---| "AirAttacks"
---| "AirScout"
---| "BasicLandAttack"
---| "BomberEscort"
---| "HeavyLandAttack"
---| "LandAssualt"
---| "LeftoverCleanup"
---| "LightAirAttack"
---| "NavalAttacks"
---| "NavalFleet"

---@alias UpgradeUnitType "DefaultACU" | "DefaultSACU"

-- types that originate from the map

---@class MarkerChain : string  name reference to a marker chain as defined in the map
---@class Area : string         name reference to a area as defined in the map
---@class Marker : string       name reference to a marker as defined in the map
---@class UnitGroup : string    name reference to a unit group as defined in the map

-- types commonly used in repository

---@class FileName : string
---@class FunctionName : string

---@class BuildCondition
---@field [1] FileName
---@field [2] FunctionName
---@field [3] any

---@class FileFunctionRef
---@field [1] FileName
---@field [2] FunctionName

---@class BuildGroup
---@field Name UnitGroup
---@field Priority number


---@class PlatoonTemplateItem
---@field [1] UnitId
---@field [2] number count
---@field [3] number size
---@field [4] string
---@field [5] string

---@class PlatoonTemplate
---@field [1] string
---@field [2] string
---@field [3] PlatoonTemplateItem

-- types used by AddOpAI

---@class MasterPlatoonFunction
---@field [1] FileName
---@field [2] FunctionName

---@class PlatoonData
---@field TransportReturn Marker       location for transports to return to
---@field PatrolChains MarkerChain[]   selection of patrol chains to guide the constructed units
---@field PatrolChain MarkerChain      patrol chain to guide the construced units
---@field AttackChain MarkerChain      attack chain to guide the constructed units
---@field LandingChain MarkerChain     landing chain to guide the transports carrying the constructed units
---@field Area Area                    an area, use depends on master platoon function
---@field Location Marker              a location, use depends on master platoon function

---@class AddOpAIData
---@field MasterPlatoonFunction FileFunctionRef   behavior of instances upon completion
---@field PlatoonData PlatoonData                 parameters of the master platoon function
---@field Priority number                         priority over other builders

-- types used by AddUnitAI

---@class AddUnitAIData
---@field Amount number                         number of engineers that can assist building
---@field KeepAlive boolean                     
---@field BuildCondition BuildCondition[]       build conditions that must be met before building can start, can be empty
---@field PlatoonAIFunction FileFunctionRef     a `{file, function}` reference to the platoon AI function
---@field MaxAssist number                      number of engineers that can assist construction
---@field Retry boolean                         flag that allows the AI to retry
---@field PlatoonData PlatoonData               parameters of the platoon AI function


---@class LevelName
---@field Name UnitGroup
---@field Priority number

---@alias DifficultyVar<T> {[1]: T, [2]: T, [3]: T}
---@alias DifficultyNum {[1]: number, [2]: number, [3]: number}
---@alias DifficultyInt {[1]: integer, [2]: integer, [3]: integer}
---@alias DifficultyString {[1]: string, [2]: string, [3]: string}

---@alias EngineerCount
---| integer    # the number of total engineers
---| DifficultyInt # the number of engineers for each difficulty
---| {[1]: integer, [2]: integer}  # the number of total engineer and the permanently assisting engineers
---| {[1]: DifficultyInt, [2]: DifficultyInt} # the number of total engineer and the permanently assisting engineers for each difficulty

---@alias Enhancement string --TODO


local AIUtils = import("/lua/ai/aiutilities.lua")
local BaseOpAI = import("/lua/ai/opai/baseopai.lua")
local Buff = import("/lua/sim/Buff.lua")
local NavalOpAI = import("/lua/ai/opai/NavalOpAI.lua")
local ReactiveAI = import("/lua/ai/opai/ReactiveAI.lua")
local ScenarioUtils = import("/lua/sim/ScenarioUtilities.lua")

local BuildingTemplates = import("/lua/buildingtemplates.lua").BuildingTemplates
local RebuildStructuresTemplate = import("/lua/buildingtemplates.lua").RebuildStructuresTemplate
local StructureUpgradeTemplates = import("/lua/upgradetemplates.lua").StructureUpgradeTemplates


local BMBC = "/lua/editor/BaseManagerBuildConditions.lua"
local BMPT = "/lua/ai/opai/BaseManagerPlatoonThreads.lua"

local intelCategory = (categories.RADAR + categories.SONAR + categories.OMNI) * categories.STRUCTURE

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

        T2AirStagingPlatform = 3,

        T2EngineerSupport = 5,

        T1LandFactory = 10,
        T2LandFactory = 10,
        T3LandFactory = 10,
        T2SupportLandFactory = 10,
        T3SupportLandFactory = 10,

        T1AirFactory = 10,
        T2AirFactory = 10,
        T3AirFactory = 10,
        T2SupportAirFactory = 10,
        T3SupportAirFactory = 10,

        T1SeaFactory = 10,
        T2SeaFactory = 10,
        T3SeaFactory = 10,
        T2SupportSeaFactory = 10,
        T3SupportSeaFactory = 10,

        T3QuantumGate = 5,

        T1HydroCarbon = 10,
        T1EnergyProduction = 10,
        T2EnergyProduction = 10,
        T3EnergyProduction = 10,

        T1Resource = 10,
        T2Resource = 10,
        T3Resource = 10,

        MassStorage = 5,
        EnergyStorage = 5,

        T1GroundDefense = 3,
        T2GroundDefense = 3,
        T3GroundDefense = 3,

        T1AADefense = 3,
        T2AADefense = 3,
        T3AADefense = 3,

        T1NavalDefense = 3,
        T2NavalDefense = 3,
        T3NavalDefense = 3,

        T2ShieldDefense = 3,
        T3ShieldDefense = 3,

        T2MissileDefense = 3,
        T3StrategicMissileDefense = 1,
    },

    -- Difficulty 3
    {
        Default = -1,
    },
}


---@class BaseManager
---@field Active boolean
---@field AIBrain AIBrain
---@field BaseName UnitGroup
---@field ConditionalBuildTable table[]
---@field ConditionalBuildData ConditionalBuildData
---@field ConstructionEngineers Unit[]
---@field CurrentEngineerCount integer
---@field EngineerQuantity integer
---@field EngineersBuilding integer
---@field Initialized boolean
---@field LevelNames LevelName[]
---@field MaximumConstructionEngineers integer
---@field NumPermanentAssisting integer
---@field OpAITable table<string, OpAI>
---@field PermanentAssistCount integer
---@field Position Vector
---@field Radius number
---@field Trash TrashBag
---@field UpgradeTable table<string|"DefaultACU"|"DefaultSACU", Enhancement[]>
BaseManager = ClassSimple {
    --- Introduces all the relevant fields to the base manager, internally called by the engine
    ---@param self BaseManager
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
        self.PermanentAssisters = {}
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

        ---@class ConditionalBuildData
        ---@field Index number         stores the index of the current conditional being built
        ---@field IsBuilding  boolean  if a conditional build is going on
        ---@field IsInitiated boolean  if a unit has been issued the build command but has not yet begun building
        ---@field NumAssisting number  number of engies assisting the conditional build
        ---@field MaxAssisting number  maximum units to assist the current conditional build
        ---@field MainBuilder Unit|false  the unit building, or `false` if there is currently not a main conditional builder
        ---@field Unit Unit|false      the actual unit being constructed currently
        ---@field WaitSecondsAfterDeath number|false  time to wait after conditional build's death before starting a new one
        self.ConditionalBuildData = {
            Index = 0,
            IsInitiated = false,
            IsBuilding = false,
            NumAssisting = 0,
            MaxAssisting = 1,
            Unit = false,
            MainBuilder = false,
            WaitSecondsAfterDeath = false,

            IncrementAssisting = function()
                local buildData = self.ConditionalBuildData
                buildData.NumAssisting = buildData.NumAssisting + 1
            end;
            DecrementAssisting = function()
                local buildData = self.ConditionalBuildData
                buildData.NumAssisting = buildData.NumAssisting - 1
            end;

            Reset = function()
                local buildData = self.ConditionalBuildData
                buildData.Index = 0
                buildData.IsInitiated = false
                buildData.IsBuilding = false
                buildData.NumAssisting = 0
                buildData.MaxAssisting = 1
                buildData.MainBuilder = false
                buildData.Unit = false
                buildData.WaitSecondsAfterDeath = false
            end;

            NeedsMoreBuilders = function()
                local buildData = self.ConditionalBuildData
                return buildData.IsBuilding and buildData.NumAssisting < buildData.MaxAssisting
            end;
        }
    end;

    --- Initializes the base manager
    ---@see See the functions StartNonZeroBase, StartDifficultyBase, StartBase or StartEmptyBase to the initial state of the base
    ---@param self BaseManager
    ---@param brain AIBrain       an instance of the Brain class that we're managing a base for
    ---@param baseName UnitGroup  name reference to a unit group as defined in the map that represnts the base, usually appended with _D1, _D2 or _D3
    ---@param markerName Marker   name reference to a marker as defined in the map that represents the center of the base
    ---@param radius number       radius of the base - any structure that is within this distance to the center of the base is considered part of the base
    ---@param levelTable table<UnitGroup, number> a table that represents the priority of various sections of the base
    ---@param difficultySeparate? boolean flag that indicates we have a base that expands based on difficulty
    Initialize = function(self, brain, baseName, markerName, radius, levelTable, difficultySeparate)
        self.Active = true
        if self.Initialized then
            error('*AI ERROR: BaseManager named "' .. baseName .. '" has already been initialized', 2)
        end

        self.Initialized = true
        if not brain.BaseManagers then
            brain.BaseManagers = {}
            brain:PBMRemoveBuildLocation(nil, "MAIN") -- remove main since we don't use it in ops much
        end

        brain.BaseManagers[baseName] = self -- store base in table, index by name of base
        self.AIBrain = brain
        self.Position = ScenarioUtils.MarkerToPosition(markerName)
        self.BaseName = baseName
        self.Radius = radius
        for groupName, priority in levelTable do
            if not difficultySeparate then
                self:AddBuildGroup(groupName, priority, false, true) -- do not spawn units, do not sort
            else
                self:AddBuildGroupDifficulty(groupName, priority, false, true) -- do not spawn units, do not sort
            end
        end

        self.AIBrain:PBMAddBuildLocation(markerName, radius, baseName) -- add base to PBM
        self:LoadDefaultBaseCDRs()        -- ACU things
        self:LoadDefaultBaseSupportCDRs() -- sACU things
        self:LoadDefaultBaseEngineers()   -- all other engineers
        self:LoadDefaultScoutingPlatoons()  -- load in default scouts
        self:LoadDefaultBaseTMLs()  -- TML's
        self:LoadDefaultBaseNukes() -- nukes
        self:SortGroupNames() -- force sort since no sorting when adding groups earlier
        self:ForkThread(self.UpgradeCheckThread) -- start the thread to see if any buildings need upgrades

        -- check for a default chains for engineers' patrol and scouting
        local chains = Scenario.Chains
        local chainName = baseName .. "_EngineerChain"
        if chains[chainName] then
            self:SetDefaultEngineerPatrolChain(chainName)
        end

        chainName = baseName .. "_AirScoutChain"
        if chains[chainName] then
            self:SetDefaultAirScoutPatrolChain(chainName)
        end

        chainName = baseName .. "_LandScoutChain"
        if chains[chainName] then
            self:SetDefaultLandScoutPatrolChain(chainName)
        end
    end;

    --- Throws an error if this base manager has not been initialized
    ---@param self BaseManager
    InitializedCheck = function(self)
        if not self.Initialized then
            error('*AI ERROR: BaseManager named "' .. self.BaseName .. '" is not initialized', 2)
        end
    end;

    --- Enables or disables the base entirely, it may take a while before all base functionality is stopped
    ---@param self BaseManager
    ---@param status boolean
    BaseActive = function(self, status)
        self.Active = status
    end;

    --- Initializes the base manager using the _D1, _D2 and _D3 difficulty tables
    ---@see See the functions StartNonZeroBase, StartDifficultyBase, StartBase or StartEmptyBase to the initial state of the base
    ---@param self BaseManager
    ---@param brain AIBrain      an instance of the Brain class that we're managing a base for
    ---@param baseName UnitGroup name reference to a unit group as defined in the map that represnts the base, usually appended with _D1, _D2 or _D3
    ---@param markerName Marker  name reference to a marker as defined in the map that represents the center of the base
    ---@param radius number      radius of the base - any structure that is within this distance to the center of the base is considered part of the base
    ---@param levelTable table<UnitGroup, number>  a table that represents the priority of various sections of the base
    InitializeDifficultyTables = function(self, brain, baseName, markerName, radius, levelTable)
        return self:Initialize(brain, baseName, markerName, radius, levelTable, true)
    end;

    -- Auto trashbags all threads on a base manager

    --- Allocates a thread running the function where the base manager is prepended as the first
    --- argument. The thread is inserted in the trashbag of the base manager.
    ---@param self BaseManager
    ---@param fn? function
    ---@param ... any
    ---@return thread?
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        end
    end;

    --- Instructs the base to attempt to build a specific unit group as defined in the map.
    --- These are usually experimentals.
    ---@param self BaseManager
    ---@param unitName UnitGroup                name reference to a unit group as defined in the map
    ---@param retry boolean                     whether or not we should retry after failing to build
    ---@param numEngineers number               number of engineers that can assist building
    ---@param platoonAIFunction FileFunctionRef a `{file, function}` table of reference name to the platoon AI function
    ---@param platoonData PlatoonData           parameters of the platoon AI function
    ---@param condition function                build conditions that must be met before building can start, can be empty
    ---@param keepAlive boolean
    ConditionalBuild = function(self, unitName, retry, numEngineers, platoonAIFunction, platoonData, condition, keepAlive)
        if type(condition) ~= "function" then
            error("Parameter `condition` must be a function")
            return
        end

        table.insert(self.ConditionalBuildTable, {
            name = unitName,
            data = {
                MaxAssist = numEngineers,
                BuildCondition = condition,
                PlatoonAIFunction = platoonAIFunction,
                PlatoonData = platoonData,
                Retry = retry,
                KeepAlive = keepAlive,
                Amount = 1,
            },
        })
    end;

    --- Instructs the base to attempt to build a specific unit group as defined in the map.
    --- These are usually experimentals.
    ---@see Functionally the same as AddOpAI
    ---@param self BaseManager
    ---@param unit UnitGroup      name reference to a unit group as defined in the map
    ---@param data AddUnitAIData  parameters that describe the build conditions, the platoon function and the data of the platoon function
    ---@return OpAI | boolean
    AddUnitAI = function(self, unit, data)
        return self:AddOpAI(unit, data)
    end;

    --- Attaches an OpAI instance to the base manager that uses the base to build platoons.
    --- Throws an error if the base manager doesn't have an AI brain or the name is already used.
    ---@param self BaseManager
    ---@param ptype SaveFile | UnitGroup   save file that is used to find child quantities
    ---@param name string | AddUnitAIData  a name set by you to allow you to retrieve the returned AI instance
    ---@param data AddOpAIData? parameters that describe the build conditions, the platoon function and the data of the platoon function
    ---@return OpAI | boolean
    AddOpAI = function(self, ptype, name, data)
        local brain = self.AIBrain
        if not brain then
            error("*AI ERROR: No AI Brain for base manager")
            return false
        end

        -- if it's a table of unit names, or a single unit name
        if  type(ptype) == "table" and not ptype.Platoons or
            type(ptype) == "string" and ScenarioUtils.FindUnit(ptype, Scenario.Armies[brain.Name].Units)
        then
            table.insert(self.ConditionalBuildTable, {
                name = ptype,
                data = name,
            })
            return true
        end

        if not self:CheckOpAIName(name) then return false end

        local opAi = BaseOpAI.CreateOpAI(brain, self.BaseName, ptype, name, data)
        self.OpAITable[name] = opAi
        return opAi
    end;

    --- Retrieves a previously made `OpAI` instance
    ---@param self BaseManager
    ---@param name string
    ---@return OpAI | false
    GetOpAI = function(self, name)
        local opAi = self.OpAITable[name]
        if opAi then
            return opAi
        end
        return false
    end;

    --- Raises an error if the intended OpAI name is not unique.
    --- Only useful when hooking / modding an existing mission.
    ---@param self BaseManager
    ---@param name string
    ---@return boolean
    CheckOpAIName = function(self, name)
        if self.OpAITable[name] then
            error("*AI ERROR: Duplicate OpAI name: " .. name .. " - for base manager: " .. self.BaseName)
            return false
        end
        return true
    end;

    ---@param self BaseManager
    ---@param triggeringType any
    ---@param reactionType any
    ---@param name any
    ---@param data any
    ---@return OpAI | false
    AddReactiveAI = function(self, triggeringType, reactionType, name, data)
        self:InitializedCheck()
        self.AIBrain:PBMEnableRandomSamePriority()

        if not self:CheckOpAIName(name) then return false end

        local opAi = ReactiveAI.CreateReactiveAI(self.AIBrain, self.BaseName,
            triggeringType, reactionType, name, data)
        self.OpAITable[name] = opAi
        return opAi
    end;

    --- Add generated naval AI. Uses different OpAI type because it generates platoon data.
    --- Throws an error if the base manager doesn't have an AI brain.
    ---@param self BaseManager
    ---@param name string
    ---@param data any
    ---@return OpAI | false
    AddNavalAI = function(self, name, data)
        if not self.AIBrain then
            error("*AI ERROR: No AI Brain for base manager")
            return false
        end

        if not self:CheckOpAIName(name) then return false end

        local opAi = NavalOpAI.CreateNavalAI(self.AIBrain, self.BaseName, name, data)
        self.OpAITable[name] =  opAi
        return opAi
    end;

    --- Adds a build group to the base manager that it needs to maintain. Throws an error if
    --- it the group name is already being used.
    ---@param self BaseManager
    ---@param groupName UnitGroup  name reference to a unit group as defined in the map that represents the unit group to build
    ---@param priority number      priority that indicates how important this build group is in comparison to others
    ---@param spawn? boolean       flag that indicates whether the build group is immediately spawned
    ---@param dontSort? boolean    defaults to `false`, meaning it always sorts if not set to `true`
    AddBuildGroup = function(self, groupName, priority, spawn, dontSort)
        -- make sure the group is unique
        if self:FindGroup(groupName) then
            error("*AI DEBUG: Group Name - " .. groupName .. " already exists in Base Manager group data", 2)
            return
        end
        table.insert(self.LevelNames, {
            Name = groupName,
            Priority = priority,
        })

        -- setup the brain base template for use in the base manager
        -- (Don't create so we can get a unitnames table)
        self:ClearGroupTemplate(groupName)
        -- now that we have a group name find it and add data
        self:AddToBuildingTemplate(groupName, self.BaseName .. groupName)

        -- spawn with SpawnGroup so we can track number of times this unit has existed
        if spawn then
            self:SpawnGroup(groupName)
        end
        if not dontSort then
            self:SortGroupNames()
        end
    end;

    --- Adds a build group based based on difficult to the base manager that it needs to maintain
    ---@see AddBuildGroup
    ---@param self BaseManager
    ---@param groupName UnitGroup  name reference to a unit group as defined in the map that represents the unit group to build, appends the _D1, _D2 or _D3 to indicate difficulty
    ---@param priority number      priority that indicates how important this build group is in comparison to others
    ---@param spawn? boolean       flag that indicates whether the build group is immediately spawned
    ---@param dontSort? boolean
    AddBuildGroupDifficulty = function(self, groupName, priority, spawn, dontSort)
        groupName = groupName .. "_D" .. ScenarioInfo.Options.Difficulty
        self:AddBuildGroup(groupName, priority, spawn, dontSort)
    end;

    --- Removes a build group from the base manager
    ---@param self BaseManager
    ---@param groupName UnitGroup name reference to a unit group as defined in the map that represents the unit group to be removed
    ClearGroupTemplate = function(self, groupName)
        self.AIBrain.BaseTemplate[self.BaseName .. groupName] = {
            Template = {},
            List = {},
            UnitNames = {},
            BuildCounter = {},
        }
    end;

    --- Finds a build group from the base manager
    ---@param self BaseManager
    ---@param groupName UnitGroup name reference to a unit group as defined in the map that represents the unit group to be removed
    ---@return BuildGroup | false
    FindGroup = function(self, groupName)
        for _, data in self.LevelNames do
            if data.Name == groupName then
                return data
            end
        end
        return false
    end;

    --- Retrieves the center of the base manager
    ---@param self BaseManager
    ---@return Vector
    GetPosition = function(self)
        return self.Position
    end;

    --- Retrieves the radius of the base manager, which is used to search for factories and engineers
    ---@param self BaseManager
    ---@return number
    GetRadius = function(self)
        return self.Radius
    end;

    --- Defines the radius of the base manager, which is used to search for factories and engineers
    ---@param self BaseManager
    ---@param rad number
    SetRadius = function(self, rad)
        self.Radius = rad
    end;


    ---------------------------------------------------------------------------
    -- Functions for tracking the number of engineers working in a base manager
    ---------------------------------------------------------------------------

    --- Adds to the engineer count, useful when gifting the base engineers
    ---@param self BaseManager
    ---@param num? integer defaults to `1`
    AddCurrentEngineer = function(self, num)
        self.CurrentEngineerCount = self.CurrentEngineerCount + (num or 1)
    end;

    --- Subtracts from the engineer count
    ---@param self BaseManager
    ---@param num? integer defaults to `1`
    SubtractCurrentEngineer = function(self, num)
        self.CurrentEngineerCount = self.CurrentEngineerCount - (num or 1)
    end;

    --- Retrieves the number of active engineers
    ---@param self BaseManager
    ---@return integer
    GetCurrentEngineerCount = function(self)
        return self.CurrentEngineerCount
    end;

    --- Retrieves the maximum number of engineers, the base manager won't build more engineers than this
    ---@param self BaseManager
    ---@return integer
    GetMaximumEngineers = function(self)
        return self.EngineerQuantity
    end;

    --- Adds an engineer to the engineer pool of the base manager
    ---@param self BaseManager
    ---@param unit Unit
    AddConstructionEngineer = function(self, unit)
        table.insert(self.ConstructionEngineers, unit)
    end;

    --- Removes an engineer from the engineer pool of the base manager
    ---@param self BaseManager
    ---@param unit Unit
    RemoveConstructionEngineer = function(self, unit)
        for k, v in self.ConstructionEngineers do
            if v.EntityId == unit.EntityId then
                table.remove(self.ConstructionEngineers, k)
                return
            end
        end
    end;

    --- Defines the maximum number of construction engineers
    ---@param self BaseManager
    ---@param num integer
    SetMaximumConstructionEngineers = function(self, num)
        self.MaximumConstructionEngineers = num
    end;

    --- Retrieves the maximum number of construction engineers
    ---@param self BaseManager
    ---@return integer
    GetConstructionEngineerMaximum = function(self)
        return self.MaximumConstructionEngineers
    end;

    ---@param self BaseManager
    ---@return integer
    GetConstructionEngineerCount = function(self)
        return table.getn(self.ConstructionEngineers)
    end;

    ---@param self BaseManager
    ---@param bool boolean
    SetConstructionAlwaysAssist = function(self, bool)
        self.ConstructionAssistBool = bool
    end;

    ---@param self BaseManager
    ---@return boolean
    ConstructionAlwaysAssist = function(self)
        return self.ConstructionAssistBool
    end;

    ---@param self BaseManager
    ---@return boolean
    ConstructionNeedsAssister = function(self)
        return self:ConstructionAlwaysAssist() or self:GetConstructionEngineerCount() == 0
    end;

    ---@param self BaseManager
    ---@param unit Unit
    ---@return boolean
    IsConstructionUnit = function(self, unit)
        if not unit or unit.Dead then
            return false
        end

        for _, v in self.ConstructionEngineers do
            if v.EntityId == unit.EntityId then
                return true
            end
        end
        return false
    end;

    --- Raises an error if the new number is greater than the current number of engineers
    ---@param self BaseManager
    ---@param num integer
    SetPermanentAssistCount = function(self, num)
        if num > self.EngineerQuantity then
            error("*Base Manager Error: More permanent assisters than total engineers")
        end
        self.PermanentAssistCount = num
    end;

    ---@param self BaseManager
    ---@return integer
    GetPermanentAssistCount = function(self)
        return self.PermanentAssistCount
    end;

    ---@param self BaseManager
    ---@param num integer
    SetNumPermanentAssisting = function(self, num)
        self.NumPermanentAssisting = num
    end;

    ---@param self BaseManager
    ---@return integer
    IncrementPermanentAssisting = function(self)
        local perm = self.NumPermanentAssisting + 1
        self.NumPermanentAssisting = perm
        return perm
    end;

    ---@param self BaseManager
    ---@return integer
    DecrementPermanentAssisting = function(self)
        local perm = self.NumPermanentAssisting - 1
        self.NumPermanentAssisting = perm
        return perm
    end;

    ---@param self BaseManager
    ---@return integer
    GetNumPermanentAssisting = function(self)
        return self.NumPermanentAssisting
    end;

    ---@param self BaseManager
    ---@return boolean
    NeedPermanentFactoryAssist = function(self)
        return table.getn(self:GetAllBaseFactories()) >= 1 and
            self:GetPermanentAssistCount() > self:GetNumPermanentAssisting()
    end;

    SetEngineerCountByDifficulty = function(self, count)
    end;

    SetEngineerCountAlt = function(self, count)
    end;

    --- Sets the engineer counts. If `count` is a number, the total engineer count is set it.
    --- If `count` is a pair of numbers, the first is the total engineer count and the second is
    --- the permanent assist count. In either case, a table of 3 numbers describing the value for
    --- each difficulty can used in place of the number.
    --- Raises an error if it can't detect the counting pattern. 
    ---@param self BaseManager
    ---@param count EngineerCount
    SetEngineerCount = function(self, count)
        if type(count) == "table" then
            local difficulty = ScenarioInfo.Options.Difficulty
            -- table of tables means set the total and permanent assist count by difficulty
            if type(count[1]) == "table" then
                self:SetTotalEngineerCount(count[1][difficulty])
                self:SetPermanentAssistCount(count[2][difficulty])
            -- table with 3 entries is a difficulty table
            elseif table.getn(count) == 3 then
                self:SetTotalEngineerCount(count[difficulty])
            -- table with 2 entries means 1st is total engs, 2nd is num permanent assisting
            elseif table.getn(count) == 2 then
                self:SetTotalEngineerCount(count[1])
                self:SetPermanentAssistCount(count[2])
                -- Unknown number of entries
            else
                error("*Base Manager Error: Unknown number of entries passed to SetEngineerCount")
            end
        else
            self:SetTotalEngineerCount(count)
        end
    end;

    --- Defines the total engineer count of this base manager
    ---@param self BaseManager
    ---@param num integer
    SetTotalEngineerCount = function(self, num)
        self.EngineerQuantity = num
        ScenarioInfo.VarTable[self.BaseName .. "_EngineerNumber"] = num
    end;

    --- Retrieves the amount of engineers that are building
    ---@param self BaseManager
    ---@return integer
    GetEngineersBuilding = function(self)
        return self.EngineersBuilding
    end;

    --- Does not set the number of engineers that are building, but adds to or subtracts from that number
    ---@param self BaseManager
    ---@param count integer
    SetEngineersBuilding = function(self, count)
        self.EngineersBuilding = self.EngineersBuilding + count
    end;

    --- Defines the number of support command units this base manager should maintain
    ---@param self BaseManager
    ---@param count number
    SetSupportACUCount = function(self, count)
        ScenarioInfo.VarTable[self.BaseName .. "_sACUNumber"] = count
    end;

    --- Defines the factory build rate buff that is applied to all factories
    ---@param self BaseManager
    ---@param buffName string
    SetFactoryBuildRateBuff = function(self, buffName)
        self.FactoryBuildRateBuff = buffName
    end;

    --- Defines the engineer build rate buff that is applied to all engineers
    ---@param self BaseManager
    ---@param buffName string
    SetEngineerBuildRateBuff = function(self, buffName)
        self.EngineerBuildRateBuff = buffName
    end;


    ---------------------------------------------------
    -- Get/Set of default chains for base funcitonality
    ---------------------------------------------------

    ---@param self BaseManager
    ---@return MarkerChain
    GetDefaultEngineerPatrolChain = function(self)
        return self.DefaultEngineerPatrolChain
    end;

    ---@param self BaseManager
    ---@param chainName MarkerChain
    ---@return true
    SetDefaultEngineerPatrolChain = function(self, chainName)
        self.DefaultEngineerPatrolChain = chainName
        return true
    end;

    ---@param self BaseManager
    ---@return MarkerChain
    GetDefaultAirScoutPatrolChain = function(self)
        return self.DefaultAirScoutPatrolChain
    end;

    ---@param self BaseManager
    ---@param chainName MarkerChain
    ---@return true
    SetDefaultAirScoutPatrolChain = function(self, chainName)
        self.DefaultAirScoutPatrolChain = chainName
        return true
    end;

    ---@param self BaseManager
    ---@return MarkerChain
    GetDefaultLandScoutPatrolChain = function(self)
        return self.DefaultLandScoutPatrolChain
    end;

    ---@param self BaseManager
    ---@param chainName MarkerChain
    ---@return true
    SetDefaultLandScoutPatrolChain = function(self, chainName)
        self.DefaultLandScoutPatrolChain = chainName
        return true
    end;

    --- Returns all factories working at a base manager
    ---@param self BaseManager
    ---@param category? EntityCategory
    ---@return Unit[]
    GetAllBaseFactories = function(self, category)
        local allFactories = self.AIBrain:PBMGetAllFactories(self.BaseName)
        if not category then
            return allFactories
        end

        -- Filter factories by category passed in
        local factories = {}
        local factoryCount = 0
        for _, fac in allFactories do
            if EntityCategoryContains(category, fac) then
                factoryCount = factoryCount + 1
                factories[factoryCount] = fac
            end
        end
        return factories
    end;

    --- ***Incomplete***
    ---
    --- Adds the ability for an expansion base to move out and help another base manager at
    --- another location. Functionality should mean that you simply specifiy the name of the base
    --- and it will then send out an engineer to build it. You can also specify the number of
    --- engineers you would like to support with.
    ---@param self BaseManager
    ---@param baseName string
    ---@param engQuantity? number defaults to `1`
    ---@param baseData? any Unused. If we ever need more data (transports maybe) it would be housed here.
    AddExpansionBase = function(self, baseName, engQuantity, baseData)
        table.insert(self.ExpansionBaseData, {
            BaseName = baseName,
            Engineers = engQuantity or 1,
            IncomingEngineers = 0,
        })
        self.FunctionalityStates.ExpansionBases = true
        if baseData then
            -- Setup base here
        end
    end;


    -----------------------------------------
    -- Base Manager Unit Upgrade Level functions
    -----------------------------------------

    --- Sets what type of upgrades you want on what types of units. Applies to only ACU and SACU
    --- right now.
    ---@param upgradeTable Enhancement[] list of enhancements to apply to each unit
    ---@param unitType UpgradeUnitType raises an error if absent
    ---@param startActive? boolean if true, the unit will start with the enhancements, if not then they will upgrade to the enhancements.
    SetUnitUpgrades = function(self, upgradeTable, unitType, startActive)
        if not unitType then
            error("*AI Debug: No unit name given for unit upgrades: Base named - " .. self.BaseName, 2)
            return false
        end
        self.UnitUpgrades[unitType] = upgradeTable
        if not startActive then
            return
        end

        local category
        if unitType == "DefaultACU" then
            category = categories.COMMAND
        elseif unitType == "DefaultSACU" then
            category = categories.SUBCOMMANDER
        end
        if category then
            for _, unit in AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, category, self.Position, self.Radius) do
                for _, upgrade in upgradeTable do
                    unit:CreateEnhancement(upgrade)
                end
            end
        end
    end;

    --- Determines if a specific unit needs upgrades, and returns the name of upgrade if needed
    ---@param self BaseManager
    ---@param unit Unit
    ---@param unitType? UpgradeUnitType defaults to `unit.UnitName`
    ---@return string | false
    UnitNeedsUpgrade = function(self, unit, unitType)
        if unit.Dead then
            return false
        end

        -- Find appropriate data about unit upgrade info
        local upgradeTable = self.UnitUpgrades[unitType or unit.UnitName]
        if not upgradeTable then
            return false
        end

        local allEnhancements = unit.Blueprint.Enhancements
        if not allEnhancements then
            return false
        end
        local unitEnhancements = SimUnitEnhancements[unit.EntityId]

        for _, upgradeName in upgradeTable do
            -- Find the upgrade in the unit's bp
            local bpUpgrade = allEnhancements[upgradeName]
            if not bpUpgrade then
                error("*Base Manager Error: " .. self.BaseName .. ", enhancement: " .. upgradeName .. ' was not found in the unit\'s bp.')
                continue
            end
            if unit:HasEnhancement(upgradeName) then
                continue
            end

            -- If we already have upgarde at that slot, remove it first
            local existingEnhancement = unitEnhancements[bpUpgrade.Slot]
            if existingEnhancement then
                return existingEnhancement .. "Remove"
            end
            -- Check for required upgrades
            local prereq = bpUpgrade.Prerequisite
            if prereq and not unit:HasEnhancement(prereq) then
                return prereq
            end
            -- No requirement and stop available, return upgrade name
            return upgradeName
        end
        return false
    end;

    ---@param self BaseManager
    ---@param upgradeTable string[]
    ---@param startActive? boolean
    SetACUUpgrades = function(self, upgradeTable, startActive)
        self:SetUnitUpgrades(upgradeTable, "DefaultACU", startActive)
    end;

    ---@param self BaseManager
    ---@param upgradeTable string[]
    ---@param startActive? boolean
    SetSACUUpgrades = function(self, upgradeTable, startActive)
        self:SetUnitUpgrades(upgradeTable, "DefaultSACU", startActive)
    end;

    ---@param self BaseManager
    UpgradeCheckThread = function(self)
        local armyIndex = self.AIBrain:GetArmyIndex()
        while true do
            if self.Active then
                local unitNames = ScenarioInfo.UnitNames[armyIndex]
                for _, v in self.UpgradeTable do
                    local unit = unitNames[v.UnitName]
                    if unit and not unit.Dead then
                        -- Cybran engie stations are never in "Idle" state but in the
                        -- "AssistingCommander" state
                        -- Factories are not in Idle state when assisting other factories (so check
                        -- against unit.UnitBeingBuilt to make sure they're not building anything),
                        -- so if the base manager grabbed a factories for assistance before this
                        -- upgrade thread, then it would never get upgraded
                        if  unit.UnitId ~= v.FinalUnit and
                            (unit:IsIdleState() or unit:IsUnitState("AssistingCommander") or not unit.UnitBeingBuilt) and
                            not unit:IsBeingBuilt()
                        then
                            self:ForkThread(self.BaseManagerUpgrade, unit, v.UnitName)
                        end
                    end
                end
            end
            WaitSeconds(Random(3, 5))

        end
    end;

    --- Sorts build groups by priority
    ---@param self BaseManager
    SortGroupNames = function(self)
        table.sort(self.LevelNames, self.GroupSorter)
    end;
    GroupSorter = function(a, b)
        return a.Priority < b.Priority
    end;

    --- Sets a group's priority and re-sorts all groups
    ---@param self BaseManager
    ---@param groupName string
    ---@param priority number
    SetGroupPriority = function(self, groupName, priority)
        for _, data in self.LevelNames do
            if data.Name == groupName then
                data.Priority = priority
                self:SortGroupNames()
                return
            end
        end
    end;

    --- Spawns a group, tracks number of times it has been built, gives nuke and anti-nukes ammo
    ---@param self BaseManager
    ---@param groupName string
    ---@param uncapturable boolean
    ---@param balance boolean
    SpawnGroup = function(self, groupName, uncapturable, balance)
        local facBuildBuff = self.FactoryBuildRateBuff
        local engBuildBuff = self.EngineerBuildRateBuff
        local ApplyBuff = Buff.ApplyBuff
        local difficulty = ScenarioInfo.Options.Difficulty
        for _, unit in ScenarioUtils.CreateArmyGroup(self.AIBrain.Name, groupName, nil, balance) do
            if facBuildBuff then
                ApplyBuff(unit, facBuildBuff)
            end
            if engBuildBuff then
                ApplyBuff(unit, engBuildBuff)
            end
            if uncapturable then
                unit:SetCapturable(false)
                unit:SetReclaimable(false)
            end
            if EntityCategoryContains(categories.SILO, unit) then
                if difficulty == 1 then
                    unit:GiveNukeSiloAmmo(1)
                    unit:GiveTacticalSiloAmmo(1)
                else
                    unit:GiveNukeSiloAmmo(2)
                    unit:GiveTacticalSiloAmmo(2)
                end
            end
        end
    end;

    --- If we want a group in the base manager to be wreckage, use this function
    ---@param self BaseManager
    ---@param groupName string
    SpawnGroupAsWreckage = function(self, groupName)
        ScenarioUtils.CreateArmyGroup(self.AIBrain.Name, groupName, true)
    end;

    --- Sets engineer count and spawns in all groups that have priority greater than zero
    ---@param self BaseManager
    ---@param engineerNumber EngineerCount
    ---@param uncapturable boolean
    StartNonZeroBase = function(self, engineerNumber, uncapturable)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName .. "_EngineerNumber"] then
            self:SetEngineerCount(0)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end

        for _, data in self.LevelNames do
            if data.Priority and data.Priority > 0 then
                if ScenarioInfo.LoadBalance.Enabled then
                    table.insert(ScenarioInfo.LoadBalance.SpawnGroups, {self, data.Name, uncapturable})
                else
                    self:SpawnGroup(data.Name, uncapturable)
                end
            end
        end
    end;

    --- Calls `StartBase` with the difficulty suffixed to each group name
    ---@param self BaseManager
    ---@param groupNames string[]
    ---@param engineerNumber EngineerCount
    ---@param uncapturable boolean
    StartDifficultyBase = function(self, groupNames, engineerNumber, uncapturable)
        local newNames = {}
        local newNameSize = 0
        local suffix = "_D" .. ScenarioInfo.Options.Difficulty
        for _, group in groupNames do
            newNameSize = newNameSize + 1
            newNames[newNameSize] = group .. suffix
        end
        return self:StartBase(newNames, engineerNumber, uncapturable)
    end;

    --- Sets engineer count and spawns in all groups passed in in `groupNames` table.
    --- Throws an error if the group name cannot be found.
    ---@param self BaseManager
    ---@param groupNames string[]
    ---@param engineerNumber EngineerCount
    ---@param uncapturable boolean
    StartBase = function(self, groupNames, engineerNumber, uncapturable)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName .. "_EngineerNumber"] then
            self:SetEngineerCount(0)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end

        for _, name in groupNames do
            local group = self:FindGroup(name)
            if not group then
                error("*AI DEBUG: Unable to create group - " .. name .. " - Data does not exist in Base Manager", 2)
            else
                self:SpawnGroup(group.Name, uncapturable)
            end
        end
    end;

    --- Sets the engineer count for a new base and spawns in no groups
    ---@param self BaseManager
    ---@param engineerNumber EngineerCount
    StartEmptyBase = function(self, engineerNumber)
        if not engineerNumber and not ScenarioInfo.VarTable[self.BaseName .. "_EngineerNumber"] then
            self:SetEngineerCount(1)
        elseif engineerNumber then
            self:SetEngineerCount(engineerNumber)
        end
    end;

    --- Thread that will upgrade factories, radar, etc to next level
    ---@param self BaseManager
    ---@param unit Unit
    ---@param unitName string
    BaseManagerUpgrade = function(self, unit, unitName)
        local aiBrain = unit:GetAIBrain()
        local factionIndex = aiBrain:GetFactionIndex()
        local armyIndex = aiBrain:GetArmyIndex()
        local upgradeID = aiBrain:FindUpgradeBP(unit.UnitId, StructureUpgradeTemplates[factionIndex])
        if upgradeID then
            local tblUnit = {unit}
            IssueClearCommands(tblUnit)
            IssueUpgrade(tblUnit, upgradeID)
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
    end;

    ---@param self BaseManager
    ---@param buildingType string
    ---@return boolean
    CheckStructureBuildable = function(self, buildingType)
        if self.BuildTable[buildingType] == false then
            return false
        end
        return true
    end;

    ---@param self BaseManager
    ---@param groupName string
    ---@param addName string
    AddToBuildingTemplate = function(self, groupName, addName)
        local brain = self.AIBrain
        local tblUnit = ScenarioUtils.AssembleArmyGroup(brain.Name, groupName)
        if not tblUnit then
            error("*AI DEBUG - Group: " .. repr(groupName) .. " not found for Brain: " .. repr(brain.Name), 2)
            return
        end
        local factionIndex = brain:GetFactionIndex()
        local baseTemplates = brain.BaseTemplates[addName]
        local template = baseTemplates.Template
        local list = baseTemplates.List
        local unitNames = baseTemplates.UnitNames
        local buildCounter = baseTemplates.BuildCounter
        -- Convert building to the proper type to be built if needed (ex: T2 and T3 factories to T1)
        for i, unit in tblUnit do
            for _, unitId in RebuildStructuresTemplate[factionIndex] do
                if unit.type == unitId[1] then
                    table.insert(self.UpgradeTable, {
                        FinalUnit = unit.type,
                        UnitName = i,
                    })
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
            for _, buildList in BuildingTemplates[factionIndex] do -- BuildList[1] is type ("T1LandFactory"); buildList[2] is unitId (ueb0101)
                local unitPos = { unit.Position[1], unit.Position[3], 0 }
                if unit.buildtype == buildList[2] and buildList[1] ~= "T3Sonar" then -- If unit to be built is the same id as the buildList unit it needs to be added
                    self:StoreBuildCounter(buildCounter, buildList[1], buildList[2], unitPos, i)

                    local inserted = false
                    for _, section in template do -- Check each section of the template for the right type
                        if section[1][1] == buildList[1] then
                            table.insert(section, unitPos) -- Add position of new unit if found
                            list[unit.buildtype].AmountWanted = list[unit.buildtype].AmountWanted + 1 -- Increment num wanted if found
                            inserted = true
                            break
                        end
                    end
                    if not inserted then -- If section doesn't exist create new one
                        -- add new build type to list with new unit
                        table.insert(template, {{buildList[1]}, unitPos})
                         -- add new section of build list with new unit type information
                        list[unit.buildtype] = {
                            StructureType = buildList[1],
                            StructureCategory = unit.buildtype,
                            AmountNeeded = 0,
                            AmountWanted = 1,
                            --CloseToBuilder = nil
                        }
                    end
                    break
                end
            end
        end
    end;

    ---@param self BaseManager
    ---@param unitName any
    ---@param unitData any
    ---@param namesTable any
    StoreStructureName = function(self, unitName, unitData, namesTable)
        local pos = unitData.Position
        local pos1 = pos[1]
        local names = namesTable[pos1]
        if not names then
            names = {}
            namesTable[pos1] = names
        end
        names[pos[3]] = unitName
    end;

    ---@param self BaseManager
    ---@param buildCounter any
    ---@param buildingType any
    ---@param buildingId any
    ---@param unitPos any
    ---@param unitName any
    StoreBuildCounter = function(self, buildCounter, buildingType, buildingId, unitPos, unitName)
        local pos1 = unitPos[1]
        local counter = buildCounter[pos1]
        if not counter then
            counter = {}
            buildCounter[pos1] = counter
        end
        local data = {
            BuildingID = buildingId,
            BuildingType = buildingType,
            Position = unitPos,
            UnitName = unitName,
        }
        if self.BuildingCounterData.Default then
            data.Counter = self:BuildingCounterDifficultyDefault(buildingType)
        end
        counter[unitPos[2]] = data
    end;

    ---@param self BaseManager
    ---@param buildingType string
    ---@return any
    BuildingCounterDifficultyDefault = function(self, buildingType)
        local difficulty = ScenarioInfo.Options.Difficulty or 2
        local defaults = BuildingCounterDefaultValues[difficulty]
        for k, v in defaults do
            if buildingType == k then
                return v
            end
        end
        return defaults.Default
    end;

    ---@param self BaseManager
    ---@param location Vector
    ---@param buildCounter any
    ---@return boolean
    CheckUnitBuildCounter = function(self, location, buildCounter)
        local xLoc, yLoc = location[1], location[2]
        for xVal, xData in buildCounter do
            if xVal == xLoc then
                for yVal, yData in xData do
                    if yVal == yLoc then
                        local ctr = yData.Counter
                        return ctr > 0 or ctr == -1
                    end
                end
            end
        end
        return false
    end;

    ---@param self BaseManager
    ---@param unitName string
    ---@return boolean
    DecrementUnitBuildCounter = function(self, unitName)
        local templates = self.AIBrain.BaseTemplates
        for _, levelData in self.LevelNames do
            for _, firstData in templates[self.BaseName .. levelData.Name].BuildCounter do
                for _, secondData in firstData do
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
    end;

    --- Enable/Disable functionality of base parts through functions.
    --- Throws an error if the function isn't found.
    ---@param self BaseManager
    ---@param actType string
    ---@param val boolean
    SetActive = function(self, actType, val)
        local fn = self.ActivationFunctions[actType .. "Active"]
        if fn then
            fn(self, val)
        else
            error("*AI DEBUG: Invalid Activation type type - " .. actType, 2)
        end
    end;

    ActivationFunctions = {
        ---@param self BaseManager
        ---@param val boolean
        ShieldsActive = function(self, val)
            local shields = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.SHIELD * categories.STRUCTURE,
                self.Position, self.Radius)
            for _, v in shields do
                if val then
                    v:OnScriptBitSet(0) -- If turning on shields
                else
                    v:OnScriptBitClear(0) -- If turning off shields
                end
            end
            self.FunctionalityStates.Shields = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        FabricationActive = function(self, val)
            local fabs = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, categories.MASSFABRICATION * categories.STRUCTURE,
                self.Position, self.Radius)
            for k, v in fabs do
                if val then
                    v:OnScriptBitClear(4) -- If turning on
                else
                    v:OnScriptBitSet(4) -- If turning off
                end
            end
            self.FunctionalityStates.Fabrication = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        IntelActive = function(self, val)
            local intelUnits = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain, intelCategory, self.Position, self.Radius)
            for _, v in intelUnits do
                if val then
                    v:OnScriptBitClear(3) -- If turning on
                else
                    v:OnScriptBitSet(3) -- If turning off
                end
            end
            self.FunctionalityStates.Intel = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        CounterIntelActive = function(self, val)
            local intelUnits = AIUtils.GetOwnUnitsAroundPoint(self.AIBrain,
                categories.COUNTERINTELLIGENCE * categories.STRUCTURE, self.Position, self.Radius)
            for _, v in intelUnits do
                if val then
                    v:OnScriptBitClear(3) -- If turning on intel
                else
                    v:OnScriptBitSet(2) -- If turning off intel
                end
            end
            self.FunctionalityStates.CounterIntel = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        TMLActive = function(self, val)
            self.FunctionalityStates.TMLs = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        NukeActive = function(self, val)
            self.FunctionalityStates.Nukes = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        PatrolActive = function(self, val)
            self.FunctionalityStates.Patrolling = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        ReclaimActive = function(self, val)
            self.FunctionalityStates.EngineerReclaiming = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        LandScoutingActive = function(self, val)
            self.FunctionalityStates.LandScouting = val
        end;

        ---@param self BaseManager
        ---@param val boolean
        AirScoutingActive = function(self, val)
            self.FunctionalityStates.AirScouting = val
        end;
    },

    --- Enable/Disable building of buildings and stuff.
    --- Throws an error if the build type function can't be found.
    ---@param self BaseManager
    ---@param buildType string
    ---@param val string
    ---@return false?
    SetBuild = function(self, buildType, val)
        if not self.Active then
            return false
        end
        local fn = self.BuildFunctions["Build" .. buildType]
        if fn then
            fn(self, val)
        else
            error("*AI DEBUG: Invalid build type - " .. buildType, 2)
        end
    end;

    --- Disable all buildings
    ---@param self BaseManager
    ---@param val string
    SetBuildAllStructures = function(self, val)
        for key, fn in self.BuildFunctions do
            if key ~= "BuildEngineers" then
                fn(self, val)
            end
        end
    end;

    BuildFunctions = {
        ---@param self BaseManager
        ---@param val string
        BuildEngineers = function(self, val)
            self.FunctionalityStates.BuildEngineers = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildAntiAir = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1AADefense = val
            buildTable.T2AADefense = val
            buildTable.T3AADefense = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildGroundDefense = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1GroundDefense = val
            buildTable.T2GroundDefense = val
            buildTable.T3GroundDefense = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildTorpedo = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1NavalDefense = val
            buildTable.T2NavalDefense = val
            buildTable.T3NavalDefense = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildAirFactories = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1AirFactory = val
            buildTable.T2AirFactory = val
            buildTable.T3AirFactory = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildLandFactories = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1LandFactory = val
            buildTable.T2LandFactory = val
            buildTable.T3LandFactory = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildSeaFactories = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1Seafactory = val
            buildTable.T2Seafactory = val
            buildTable.T3Seafactory = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildFactories = function(self, val)
            local buildFunctions = self.BuildFunctions
            buildFunctions.BuildAirFactories(self, val)
            buildFunctions.BuildSeaFactories(self, val)
            buildFunctions.BuildLandFactories(self, val)
        end;

        ---@param self BaseManager
        ---@param val string
        BuildMissileDefense = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1StrategicMissileDefense = val
            buildTable.T2StrategicMissileDefense = val
            buildTable.T3StrategicMissileDefense = val
            buildTable.T1MissileDefense = val
            buildTable.T2MissileDefense = val
            buildTable.T3MissileDefense = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildShields = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3ShieldDefense = val
            buildTable.T2ShieldDefense = val
            buildTable.T1ShieldDefense = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildArtillery = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3Artillery = val
            buildTable.T2Artillery = val
            buildTable.T1Artillery = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildExperimentals = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T4LandExperimental1 = val
            buildTable.T4LandExperimental2 = val
            buildTable.T4AirExperimental1 = val
            buildTable.T4SeaExperimental1 = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildWalls = function(self, val)
            self.BuildTable.Wall = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildDefenses = function(self, val)
            local buildFunctions = self.BuildFunctions
            buildFunctions.BuildAntiAir(self, val)
            buildFunctions.BuildGroundDefense(self, val)
            buildFunctions.BuildTorpedo(self, val)
            buildFunctions.BuildArtillery(self, val)
            buildFunctions.BuildShields(self, val)
            buildFunctions.BuildWalls(self, val)
        end;

        ---@param self BaseManager
        ---@param val string
        BuildJammers = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1RadarJammer = val
            buildTable.T2RadarJammer = val
            buildTable.T3RadarJammer = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildRadar = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3Radar = val
            buildTable.T2Radar = val
            buildTable.T1Radar = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildSonar = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3Sonar = val
            buildTable.T2Sonar = val
            buildTable.T1Sonar = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildIntel = function(self, val)
            local buildFunctions = self.BuildFunctions
            buildFunctions.BuildSonar(self, val)
            buildFunctions.BuildRadar(self, val)
            buildFunctions.BuildJammers(self, val)
        end;

        ---@param self BaseManager
        ---@param val string
        BuildMissiles = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3StrategicMissile = val
            buildTable.T2StrategicMissile = val
            buildTable.T1StrategicMissile = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildFabrication = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T3MassCreation = val
            buildTable.T2MassCreation = val
            buildTable.T1MassCreation = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildAirStaging = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1AirStagingPlatform = val
            buildTable.T2AirStagingPlatform = val
            buildTable.T3AirStagingPlatform = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildMassExtraction = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1Resource = val
            buildTable.T2Resource = val
            buildTable.T3Resource = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildEnergyProduction = function(self, val)
            local buildTable = self.BuildTable
            buildTable.T1EnergyProduction = val
            buildTable.T2EnergyProduction = val
            buildTable.T3EnergyProduction = val
            buildTable.T1HydroCarbon = val
            buildTable.T2HydroCarbon = val
            buildTable.T3HydroCarbon = val
        end;

        ---@param self BaseManager
        ---@param val string
        BuildStorage = function(self, val)
            local buildTable = self.BuildTable
            buildTable.MassStorage = val
            buildTable.EnergyStorage = val
        end;
    },


    -------------------------------------
    -- Default builders for base managers
    -------------------------------------

    ---@param self BaseManager
    LoadDefaultBaseEngineers = function(self)
        -- The Engineer AI Thread
        local brain = self.AIBrain
        local name = self.BaseName
        local tblName = {name}
        local aiFun = {
            "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
            "BaseManagerEngineerPlatoonSplit",
        }
        local condActive = {BMBC, "BaseActive", tblName}
        local condNeedsEngies = {BMBC, "BaseManagerNeedsEngineers", tblName}
        local suffix = "BaseManager_EngineersWork_" .. name
        for i = 1, 3 do
            brain:PBMAddPlatoon {
                BuilderName = 'T' .. i .. suffix,
                PlatoonTemplate = self:CreateEngineerPlatoonTemplate(i),
                Priority = 1,
                PlatoonAIFunction = aiFun,
                BuildConditions = {
                    condNeedsEngies,
                    condActive,
                },
                PlatoonData = {BaseName = name},
                PlatoonType = "Any",
                RequiresConstruction = false,
                LocationType = name,
            }
        end
        local platTypes = {"Air", "Land", "Sea"}

        local condEngiesEnabled = {BMBC, "BaseEngineersEnabled", tblName}
        local condBuildingEngies = {BMBC, "BaseBuildingEngineers", tblName}
        local platBuildCallbacks = {
            {BMBC, "BaseManagerEngineersStarted"},
        }
        suffix = "Count_" .. name
        -- Disband platoons - engineers built here
        for i = 1, 3 do
            local prefix = 'T' .. i .. "BaseManagerEngineerDisband_"
            local condHighestLevel = {BMBC, "HighestFactoryLevel", {i, name}}
            for j = 1, 5 do
                local builderName = prefix .. j .. suffix
                for _, pType in platTypes do
                    brain:PBMAddPlatoon {
                        BuilderName = builderName,
                        PlatoonAIPlan = "DisbandAI",
                        PlatoonTemplate = self:CreateEngineerPlatoonTemplate(i, j),
                        Priority = 300 * i,
                        PlatoonType = pType,
                        RequiresConstruction = true,
                        LocationType = name,
                        PlatoonData = {
                            NumBuilding = j,
                            BaseName = name,
                        },
                        BuildConditions = {
                            condEngiesEnabled,
                            condBuildingEngies,
                            condHighestLevel,
                            {BMBC, "FactoryCountAndNeed", {i, j, pType, name}},
                            condActive,
                        },
                        PlatoonBuildCallbacks = platBuildCallbacks,
                        InstanceCount = 3,
                        BuildTimeOut = 10, -- Timeout really fast because they don't need to really finish
                    }
                end
            end
        end
    end;

    ---@param self BaseManager
    LoadDefaultBaseCDRs = function(self)
        local name = self.BaseName
        local tblName = {name}

        -- CDR Build
        self.AIBrain:PBMAddPlatoon {
            BuilderName = "BaseManager_CDRPlatoon_" .. name,
            PlatoonTemplate = self:CreateCommanderPlatoonTemplate(),
            Priority = 1,
            PlatoonType = "Any",
            RequiresConstruction = false,
            LocationType = name,
            PlatoonAddFunctions = {
                -- TODO: Re-add once it doesn't interfere with BM engineer thread
                --{"/lua/ai/opai/OpBehaviors.lua", "CDROverchargeBehavior"},
                {BMPT, "UnitUpgradeBehavior"},
            },
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerSingleEngineerPlatoon",
            },
            BuildConditions = {
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
        }
    end;

    ---@param self BaseManager
    LoadDefaultBaseSupportCDRs = function(self)
        local name = self.BaseName
        local tblName = {name}
        local brain = self.AIBrain

        -- sCDR Build
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_sCDRPlatoon_" .. name,
            PlatoonTemplate = self:CreateSupportCommanderPlatoonTemplate(),
            Priority = 1,
            PlatoonType = "Any",
            RequiresConstruction = false,
            LocationType = name,
            PlatoonAddFunctions = {
                {BMPT, "UnitUpgradeBehavior"},
            },
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerSingleEngineerPlatoon",
            },
            BuildConditions = {
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
        }

        -- Disband platoon
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_sACUDisband_" .. name,
            PlatoonAIPlan = "DisbandAI",
            PlatoonTemplate = self:CreateSupportCommanderPlatoonTemplate(),
            Priority = 900,
            PlatoonType = "Gate",
            RequiresConstruction = true,
            LocationType = name,
            BuildConditions = {
                {BMBC, "BaseEngineersEnabled", tblName},
                {BMBC, "NumUnitsLessNearBase", {
                    name, categories.SUBCOMMANDER, name .. "_sACUNumber",
                }},
                {BMBC, "BaseActive", tblName},
            },
            InstanceCount = 2,
            BuildTimeOut = 10, -- Timeout really fast because they dont need to really finish
        }
    end;

    ---@param self BaseManager
    LoadDefaultScoutingPlatoons = function(self)
        local name = self.BaseName
        local tblName = {name}
        local brain = self.AIBrain

        -- Land Scouts
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_LandScout_" .. name,
            PlatoonTemplate = self:CreateLandScoutPlatoon(),
            Priority = 500,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerScoutingAI",
            },
            BuildConditions = {
                {BMBC, "LandScoutingEnabled", tblName},
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
            PlatoonType = "Land",
            RequiresConstruction = true,
            LocationType = name,
            InstanceCount = 1,
        }

        -- T1 Air Scouts
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_T1AirScout_" .. name,
            PlatoonTemplate = self:CreateAirScoutPlatoon(1),
            Priority = 500,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerScoutingAI",
            },
            BuildConditions = {
                {BMBC, "HighestFactoryLevelType", {1, name, "Air"}},
                {BMBC, "AirScoutingEnabled", tblName},
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
            PlatoonType = "Air",
            RequiresConstruction = true,
            LocationType = name,
            InstanceCount = 1,
        }

        -- T2 Air Scouts
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_T2AirScout_" .. name,
            PlatoonTemplate = self:CreateAirScoutPlatoon(2),
            Priority = 750,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerScoutingAI",
            },
            BuildConditions = {
                {BMBC, "HighestFactoryLevelType", {2, name, "Air"}},
                {BMBC, "AirScoutingEnabled", tblName},
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
            PlatoonType = "Air",
            RequiresConstruction = true,
            LocationType = name,
            InstanceCount = 1,
        }

        -- T3 Air Scouts
        brain:PBMAddPlatoon {
            BuilderName = "BaseManager_T3AirScout_" .. name,
            PlatoonTemplate = self:CreateAirScoutPlatoon(3),
            Priority = 1000,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerScoutingAI",
            },
            BuildConditions = {
                {BMBC, "HighestFactoryLevelType", {3, name, "Air"}},
                {BMBC, "AirScoutingEnabled", tblName},
                {BMBC, "BaseActive", tblName},
            },
            PlatoonData = {
                BaseName = name,
            },
            PlatoonType = "Air",
            RequiresConstruction = true,
            LocationType = name,
            InstanceCount = 1,
        }
    end;

    ---@param self BaseManager
    LoadDefaultBaseTMLs = function(self)
        local name = self.BaseName
        local tblName = {name}

        self.AIBrain:PBMAddPlatoon {
            BuilderName = "BaseManager_TMLPlatoon_" .. name,
            PlatoonTemplate = self:CreateTMLPlatoonTemplate(),
            Priority = 300,
            PlatoonType = "Any",
            RequiresConstruction = false,
            LocationType = name,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerTMLAI",
            },
            BuildConditions = {
                {BMBC, "BaseActive", tblName},
                {BMBC, "TMLsEnabled", tblName},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
    end;

    ---@param self BaseManager
    LoadDefaultBaseNukes = function(self)
        local name = self.BaseName
        local tblName = {name}

        self.AIBrain:PBMAddPlatoon {
            BuilderName = "BaseManager_NukePlatoon_" .. name,
            PlatoonTemplate = self:CreateNukePlatoonTemplate(),
            Priority = 400,
            PlatoonType = "Any",
            RequiresConstruction = false,
            LocationType = name,
            PlatoonAIFunction = {
                "/lua/ai/opai/BaseManagerPlatoonThreads.lua",
                "BaseManagerNukeAI",
            },
            BuildConditions = {
                {BMBC, "BaseActive", tblName},
                {BMBC, "NukesEnabled", tblName},
            },
            PlatoonData = {
                BaseName = self.BaseName,
            },
        }
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateTMLPlatoonTemplate = function(self)
        ---@type PlatoonTemplate
        local template = {
            "TMLTemplate",
            "NoPlan",
            {"ueb2108", 1, 1, "Attack", "None"},
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateNukePlatoonTemplate = function(self)
        ---@type PlatoonTemplate
        local template = {
            "NukeTemplate",
            "NoPlan",
            {"ueb2305", 1, 1, "Attack", "None"},
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateLandScoutPlatoon = function(self)
        ---@type PlatoonTemplate
        local template = {
            "LandScoutTemplate",
            "NoPlan",
            {"uel0101", 1, 1, "Scout", "None"},
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateAirScoutPlatoon = function(self, techLevel)
        local platItem = {nil, 1, 1, "Scout", "None"}
        if techLevel == 3 then
            platItem[1] = "uea0302"
        else
            platItem[1] = "uea0101"
        end

        ---@type PlatoonTemplate
        local template = {
            "AirScoutTemplate",
            "NoPlan",
            platItem,
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateCommanderPlatoonTemplate = function(self)
        ---@type PlatoonTemplate
        local template = {
            "CommanderTemplate",
            "NoPlan",
            {"uel0001", 1, 1, "Support", "None"},
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@return PlatoonTemplate
    CreateSupportCommanderPlatoonTemplate = function(self)
        ---@type PlatoonTemplate
        local template = {
            "CommanderTemplate",
            "NoPlan",
            {"uel0301", 1, 1, "Support", "None"},
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;

    ---@param self BaseManager
    ---@param techLevel number
    ---@param platoonSize? number defaults to `5`
    ---@return PlatoonTemplate
    CreateEngineerPlatoonTemplate = function(self, techLevel, platoonSize)
        ---@type PlatoonTemplateItem
        local platItem = {nil, 1, platoonSize or 5, "Support", "None"}
        if techLevel == 1 then
            platItem[1] = "uel0105"
        elseif techLevel == 2 then
            platItem[1] = "uel0208"
        else
            platItem[1] = "uel0309"
        end

        ---@type PlatoonTemplate
        local template = {
            "EngineerThing",
            "NoPlan",
            platItem,
        }
        return ScenarioUtils.FactionConvert(template, self.AIBrain:GetFactionIndex())
    end;
}

--- Prepares a base manager, note that you still need to call one of the Start functions
---@param brain AIBrain
---@param baseName string
---@param markerName Marker
---@param radius number
---@param levelTable any
---@return BaseManager
function CreateBaseManager(brain, baseName, markerName, radius, levelTable)
    ---@type BaseManager
    local bManager = BaseManager()
    bManager:Create()

    if brain and baseName and markerName and radius then
        bManager:Initialize(brain, baseName, markerName, radius, levelTable)
    end

    return bManager
end
