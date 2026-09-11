
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Behaviors = import("/lua/ai/aibehaviors.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")
local Utilities = import("/lua/utilities.lua")

-- upvalue scope for performance
local TableGetn = table.getn
local TableInsert = table.insert
local TableRandom = table.random
local TableEmpty = table.empty
local TableRemove = table.remove
local TableSort = table.sort

local sortDownByPriority = sort_down_by("Priority")
local EntityCategoryContains = EntityCategoryContains

local StandardBrain = import("/lua/aibrain.lua").AIBrain

-- Cached categories used in this file.
local airFactoryCategories = categories.FACTORY * categories.AIR - categories.EXTERNALFACTORYUNIT
local landFactoryCategories = categories.FACTORY * categories.LAND - categories.EXTERNALFACTORYUNIT
local navalFactoryCategories = categories.FACTORY * categories.NAVAL - categories.EXTERNALFACTORYUNIT
local gateFactoryCategories = categories.FACTORY * categories.GATE - categories.EXTERNALFACTORYUNIT
local techCategoryTableAsc = {categories.TECH1, categories.TECH2, categories.TECH3}
local techCategoryTableDesc = {categories.TECH3, categories.TECH2, categories.TECH1}
local immobileFactories = categories.FACTORY - categories.MOBILE
local tech2factoriesCategory = categories.TECH2 * categories.FACTORY
local tech3factoriesCategory = categories.TECH3 * categories.FACTORY
local allUnitsCategories = categories.ALLUNITS
local factoryCategories = categories.FACTORY
local tech2categories = categories.TECH2
local tech3categories = categories.TECH3

---@alias PMBPlatoonType "Air" | "Land" | "Sea" | "Gate"

---@class PBMPlatoonBuilder
---@field BuilderName string
---@field PlatoonTemplate PlatoonTemplate
---@field Priority integer
---@field InstanceCount integer? How many platoons will this builder produce. Defaults to 1.
---@field LocationType LocationType Name of the location this builder belongs to
---@field BuildTimeOut integer? How long it'll try to form this platoon after it's been told to build.
---@field PlatoonType BuilderType
---@field RequiresConstruction boolean Do I need to build this from a factory or should I just try to form it?
---@field BuildConditions BuildCondition[]? List of build conditions to build / form the platoon
---@field PlatoonData table?
---@field PlatoonBuildCallbacks FileFunctionRef[]?
---@field PlatoonAIPlan string? AI plan function defined directly on the `Platoon` class.
---@field PlatoonAddPlans string[]? Additional AI plan functions (defined directly on the `Platoon` class) to run.
---@field PlatoonAIFunction FileFunctionRef Main AI function to run on the platoon.
---@field PlatoonAddFunctions FileFunctionRef[]? Any additional functions to run on the platoon.
---@field PlatoonAddBehaviors string[]? Name of the behaviour functions to run from "/lua/ai/aibehaviors.lua".

---@class PBMPlatoonBuilderFull: PBMPlatoonBuilder
---@field BuildConditions BuildCondition[]
---@field InstanceCount integer
---@field GenerateTimeOut boolean? This flag is set when the builder is added and and doesn't specify `BuildTimeOut`.

---@class PBMBuildLocation
---@field Location Vector Position of the build location
---@field Radius number
---@field LocationType string Name of the location
---@field PrimaryFactories table<PMBPlatoonType, FactoryUnit?>
---@field UseCenterPoint boolean If its `true` and no specific rally point is specified, `Location`` is used as the rally position.

---@class PBMPossiblePlatoon
---@field Builder PBMPlatoonBuilderTask
---@field Index integer Index to the platoon in `PBM.Platoons`
---@field Global PBMPlatoonBuilderFull

--- A basic campaign brain. Contains all the functionality that a campaign brain requires. This
--- brain is a 'blunt' copy of the functionality that is required to run various campaign maps.
---@class CampaignAIBrain: AIBrain
---@field AIPlansList string[][]
---@field AttackManager AttackManager
---@field AttackData AttackManager references same class as `self.AttackManager`
---@field BaseManagers table<string, BaseManager>
---@field BaseTemplates table<string, BmBaseTemplates> List of templates for the base manager to maintain
---@field ConstantEval boolean
---@field CurrentPlan string lua file which contains plan
---@field CurrentPlanScript table
---@field HasPlatoonList boolean
---@field IgnoreArmyCaps boolean Allows spawning more units than the set unit capacity with `ScenarioUtilities` functions
---@field LayerPref "LAND" | "AIR"
---@field PBM AiPlatoonBuildManager
---@field PlatoonNameCounter table<string, integer> Tracks number of active platoons by builder name
---@field RepeatExecution boolean
AIBrain = Class(StandardBrain) {

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self CampaignAIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        StandardBrain.OnCreateAI(self, planName)

        local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality

        local cheatPos = string.find(per, 'cheat')
        if cheatPos then
            AIUtils.SetupCheat(self, true)
            ScenarioInfo.ArmySetup[self.Name].AIPersonality = string.sub(per, 1, cheatPos - 1)
        end

        LOG('* OnCreateAI: AIPersonality: ('..per..')')

        self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
        self:ForkThread(self.InitialAIThread)

        self.BaseTemplates = { }
        self.PlatoonNameCounter = {}
        self.PlatoonNameCounter['AttackForce'] = 0
        self.RepeatExecution = true

        self.FactoryAssistList = {}
        self.DelayEqualBuildPlattons = {}
    end,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self CampaignAIBrain
    ---@param planName FileName
    CreateBrainShared = function(self, planName)
        StandardBrain.CreateBrainShared(self, planName)

        local aiScenarioPlans = self:ImportScenarioArmyPlans(planName)
        if aiScenarioPlans then
            self.AIPlansList = aiScenarioPlans
        else
            self.DefaultPlan = true
            self.AIPlansList = import("/lua/aibrainplans.lua").AIPlansList
        end
        self.RepeatExecution = false

        if ScenarioInfo.type == 'campaign' then
            self:SetResourceSharing(false)
        end

        self.ConstantEval = true
        self.IgnoreArmyCaps = false
    end,

    --- Called after `BeginSession`, at this point all props, resources and initial units exist in the map and the teams are defined
    ---@param self EasyAIBrain
    OnBeginSession = function(self)
        StandardBrain.OnBeginSession(self)

        -- requires navigational mesh
        import("/lua/sim/navutils.lua").Generate()

        -- requires these datastructures to understand the game
        self.GridReclaim = import("/lua/ai/gridreclaim.lua").Setup(self)
        self.GridBrain = import("/lua/ai/gridbrain.lua").Setup()
        self.GridRecon = import("/lua/ai/gridrecon.lua").Setup(self)
        self.GridPresence = import("/lua/ai/gridpresence.lua").Setup(self)
    end,

    ---@param self EasyAIBrain
    OnDestroy = function(self)
        StandardBrain.OnDestroy(self)
    end,

    ---@param self EasyAIBrain
    ---@param blip Blip
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        StandardBrain.OnIntelChange(self, blip, reconType, val)
    end,

    ----------------------------------------------------------------------------------------
    --#region campaign functionality

    ---@param self CampaignAIBrain
    ---@param planName FileName
    ---@return string[]|nil
    ImportScenarioArmyPlans = function(self, planName)
        if planName and planName ~= '' then
            return import(planName).AIPlansList
        else
            return nil
        end
    end,

    ---@param self CampaignAIBrain
    InitialAIThread = function(self)
        -- delay the AI so it can't reclaim the start area before it's cleared from the ACU landing blast.
        WaitTicks(30)
        self.EvaluateThread = self:ForkThread(self.EvaluateAIThread)
        self.ExecuteThread = self:ForkThread(self.ExecuteAIThread)
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
                self:ExecutePlan()
            end
        end
    end,

    ---@param self CampaignAIBrain
    ExecuteAIThread = function(self)
        local personality = self:GetPersonality()

        while true do
            if self.CurrentPlan and self.RepeatExecution then
                self:ExecutePlan()
            end
            local delay = personality:AdjustDelay(20, 4)
            WaitTicks(delay)
        end
    end,

    ---@param self CampaignAIBrain
    ---@param planName FileName
    ---@return number
    EvaluatePlan = function(self, planName)
        local plan = import(planName)
        if plan then
            return plan.EvaluatePlan(self)
        else
            WARN('*WARNING: TRIED TO IMPORT PLAN NAME: ' .. tostring(planName) .. ', BUT IT ERRORED OUT IN THE AI BRAIN.')
            return 0
        end
    end,

    ---@param self CampaignAIBrain
    ExecutePlan = function(self)
        self.CurrentPlanScript.ExecutePlan(self)
    end,

    ---@param self CampaignAIBrain
    ---@param repeatEx boolean
    SetRepeatExecution = function(self, repeatEx)
        self.RepeatExecution = repeatEx
    end,

    ---@param self CampaignAIBrain
    GetCurrentPlanScript = function(self)
        return self.CurrentPlanScript
    end,

    ---@param self CampaignAIBrain
    ---@param bestPlan string
    SetCurrentPlan = function(self, bestPlan)
        if not bestPlan then
            self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
        else
            self.CurrentPlan = bestPlan
        end
        if not self.CurrentPlan then
            error('*AI ERROR: Invalid plan list for army - ' .. self.Name, 2)
        end
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ---@param attackDataTable? table
    InitializeAttackManager = function(self, attackDataTable)
        self.AttackManager = import("/lua/ai/attackmanager.lua").AttackManager(self, attackDataTable)
        self.AttackData = self.AttackManager
    end,

    ---@param self CampaignAIBrain
    ---@param spec any
    AMAddPlatoon = function(self, spec)
        self.AttackManager:AddPlatoon(spec)
    end,

    ---@param self CampaignAIBrain
    AMPauseAttackManager = function(self)
        self.AttackManager:PauseAttackManager()
    end,

    --- AI PLATOON MANAGEMENT
    --- SC1's PlatoonBuildManager, used as its base AI even for skirmish, and also for FA's campaign
    --- This system is meant to be able to give some data about the platoon you want and have them built and formed into platoons at will.
    ---@param self CampaignAIBrain
    InitializePlatoonBuildManager = function(self)
        if not self.PBM then
            ---@class AiPlatoonBuildManager
            ---@field Locations PBMBuildLocation[]
            ---@field Platoons {[PMBPlatoonType]: PBMPlatoonBuilderTask[]}
            self.PBM = {
                BuildCheckInterval = nil,
                Platoons = {
                    Air = {},
                    Land = {},
                    Sea = {},
                    Gate = {},
                },
                Locations = {},
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
			
			-- Create the global builder table where most of the builder data will be stored, I have no idea why GPG didn't define it here to begin with
			-- They defined it in self:PBMAddPlatoon() for whatever reason
            ScenarioInfo.BuilderTable[self.CurrentPlan] = {Air = {}, Sea = {}, Land = {}, Gate = {}}
        end
    end,


    ---@param self CampaignAIBrain
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
    ---    PlatoonTemplate = platoon template,
    ---    InstanceCount = number of duplicates to place in the platoon list
    ---    Priority = integer,
    ---    BuildConditions = list of functions that return true/false, list of args, {< function>, {<args>}}
    ---    LocationType = string for type of location, setup via addnewlocation function,
    ---    BuildTimeOut = how long it'll try to form this platoon after it's been told to build.,
    ---    PlatoonType = 'Air'/'Land'/'Sea' basic type of unit, used for finding what type of factory to build from,
    ---    RequiresConstruction = true/false do I need to build this from a factory or should I just try to form it?,
    ---    PlatoonBuildCallbacks = {FunctionsToCallBack when the platoon starts to build}
    ---    PlatoonAIFunction = if nil uses function in platoon.lua, function for the main AI thread
    ---    PlatoonAddFunctions = {<other threads to be forked on this platoon>}
    ---    
    ---    PlatoonData = {
    ---        Construction = {
    ---            BaseTemplate = basetemplates, must contain templates for all 3 factions it will be viewed by faction index,
    ---            BuildingTemplate = building templates, contain templates for all 3 factions it will be viewed by faction index,
    ---            BuildClose = true/false do I follow the table order or do build the best spot near me?
    ---            BuildRelative = true/false are the build coordinates relative to the starting location or absolute coords?,
    ---            BuildStructures = {List of structure types and the order to build them.}
    ---         }
    ---    }
    ---},
    --- ```
    ---@param self CampaignAIBrain
    ---@param pltnTable PBMPlatoonBuilder
    PBMAddPlatoon = function(self, pltnTable)
        if not pltnTable.PlatoonTemplate then
            error('*AI ERROR: INVALID PLATOON LIST IN '.. self.CurrentPlan.. ' - MISSING TEMPLATE', 1)
        elseif pltnTable.RequiresConstruction == nil then
            error('*AI ERROR: INVALID PLATOON LIST IN ' .. self.CurrentPlan .. ' - MISSING RequiresConstruction', 1)
        elseif not pltnTable.Priority then
            error('*AI ERROR: INVALID PLATOON LIST IN ' .. self.CurrentPlan .. ' - MISSING PRIORITY', 1)
        end

        if not pltnTable.BuildConditions then
            pltnTable.BuildConditions = {}
        end

        -- Remove `"default_brain"` param from all conditions. It's a remnant of GPG code that got refactored,
        -- as the AIBrain is always the first param passed to the build condition
        for _, v in pairs(pltnTable.BuildConditions) do
            if v[3][1] == "default_brain" then
                TableRemove(v[3], 1)
            end
        end

        if not pltnTable.BuildTimeOut or pltnTable.BuildTimeOut == 0 then
            pltnTable.GenerateTimeOut = true
        end

        local num = 1
        if pltnTable.InstanceCount and pltnTable.InstanceCount > 1 then
            num = pltnTable.InstanceCount
        end

        local builderTable = ScenarioInfo.BuilderTable
        if not builderTable[self.CurrentPlan] then
            builderTable[self.CurrentPlan] = {Air = {}, Sea = {}, Land = {}, Gate = {}}
        end

        local planBuilderTable = builderTable[self.CurrentPlan]
        local builderName = pltnTable.BuilderName
        local platoonType = pltnTable.PlatoonType

        ---@class PBMPlatoonBuilderTask
        ---@field PlatoonHandles (false|"BUILDING"|Platoon)[] State of the platoon instances. `false` - can be built
        ---@field BuildTemplate PlatoonTemplate? Platoon templates with adjusted unit counts based on the number of factories.
        ---@field PlatoonTimeOutThread thread?
        local insertTable = {
            BuilderName = builderName,
            PlatoonHandles = {},
            Priority = pltnTable.Priority,
            LocationType = pltnTable.LocationType,
            PlatoonTemplate = pltnTable.PlatoonTemplate
        }
        for _ = 1, num do
            TableInsert(insertTable.PlatoonHandles, false)
        end

        local platoonList = self.PBM.Platoons
        for _, pType in pairs(self.PBM.PlatoonTypes) do
            -- `Any` type builders go into all types except `Gate`
            if pType == platoonType or (platoonType == "Any" and pType ~= "Gate") then
                if not planBuilderTable[pType][builderName] then
                    planBuilderTable[pType][builderName] = pltnTable
                elseif not pltnTable.Inserted then
                    error('AI DEBUG: BUILDER DUPLICATE NAME FOUND - ' .. builderName, 2)
                end
                TableInsert(platoonList[pType], insertTable)
                self.PBM.NeedSort[pType] = true
            end
        end

        self.HasPlatoonList = true
    end,

    ---@param self CampaignAIBrain
    ---@param builderName string
    PBMRemoveBuilder = function(self, builderName)
        for pType, builders in pairs(self.PBM.Platoons) do
            for num, data in pairs(builders) do
                if data.BuilderName == builderName then
                    TableRemove(self.PBM.Platoons[pType], num)
                    ScenarioInfo.BuilderTable[self.CurrentPlan][pType][builderName] = nil
                    break
                end
            end
        end
    end,

    --- Function to clear all the platoon lists so you can feed it a bunch more.
    --- - formPlatoons - Gives you the option to form all the platoons in the list before its cleaned up so that you don't have units hanging around.
    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ---@param location string
    PBMFormAllPlatoons = function(self, location)
        local locData = self:PBMGetLocation(location)
        if not locData then
            return
        end
        for _, v in self.PBM.PlatoonTypes do
            self:PBMFormPlatoons(true, v, locData)
        end
    end,

    ---@param self CampaignAIBrain
    ---@return boolean
    PBMHasPlatoonList = function(self)
        return self.HasPlatoonList
    end,

    ---@param self CampaignAIBrain
    PBMResetPrimaryFactories = function(self)
        for _, v in self.PBM.Locations do
            v.PrimaryFactories.Air = nil
            v.PrimaryFactories.Land = nil
            v.PrimaryFactories.Sea = nil
            v.PrimaryFactories.Gate = nil
        end
    end,

    ---@param self CampaignAIBrain
    ---@param loc PBMBuildLocation
    ---@param type PMBPlatoonType
    ---@param factories FactoryUnit[]
    PBMUpdatePrimaryFactory = function(self, loc, type, factories)
        local primaries = loc.PrimaryFactories
        local current = primaries[type]
        if not current or current.Dead or current:IsUnitState('Upgrading') or self:PBMCheckHighestTechFactory(factories, current) then
            current = self:PBMGetPrimaryFactory(factories)
            primaries[type] = current
        end
        self:PBMAssistGivenFactory(factories, current)
    end,

    ---Goes through the location areas, finds the factories, sets a primary then tells all the others to guard.
    ---@param self CampaignAIBrain
    PBMSetPrimaryFactories = function(self)
        for _, v in self.PBM.Locations do
            local factories = self:GetAvailableFactories(v.Location, v.Radius)
            local airFactories = {}
            local landFactories = {}
            local seaFactories = {}
            local gates = {}
            for _, factory in factories do
                if EntityCategoryContains(airFactoryCategories, factory) and self:PBMFactoryLocationCheck(factory, v) then
                    TableInsert(airFactories, factory)
                elseif EntityCategoryContains(landFactoryCategories, factory) and self:PBMFactoryLocationCheck(factory, v) then
                    TableInsert(landFactories, factory)
                elseif EntityCategoryContains(navalFactoryCategories, factory) and self:PBMFactoryLocationCheck(factory, v) then
                    TableInsert(seaFactories, factory)
                elseif EntityCategoryContains(gateFactoryCategories, factory) and self:PBMFactoryLocationCheck(factory, v) then
                    TableInsert(gates, factory)
                end
            end

            if not TableEmpty(airFactories) then
                self:PBMUpdatePrimaryFactory(v, "Air", airFactories)
            end

            if not TableEmpty(landFactories) then
                self:PBMUpdatePrimaryFactory(v, "Land", landFactories)
            end

            if not TableEmpty(seaFactories) then
                self:PBMUpdatePrimaryFactory(v, "Sea", seaFactories)
            end

            if not TableEmpty(gates) then
                if not v.PrimaryFactories.Gate or v.PrimaryFactories.Gate.Dead then
                    v.PrimaryFactories.Gate = self:PBMGetPrimaryFactory(gates)
                end
                self:PBMAssistGivenFactory(gates, v.PrimaryFactories.Gate)
            end

            if not v.RallyPoint or TableEmpty(v.RallyPoint) then
                self:PBMSetRallyPoint(airFactories, v, nil)
                self:PBMSetRallyPoint(landFactories, v, nil)
                self:PBMSetRallyPoint(seaFactories, v, nil, "Naval Rally Point")
                self:PBMSetRallyPoint(gates, v, nil)
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param factories FactoryUnit[]
    ---@param primary FactoryUnit
    PBMAssistGivenFactory = function(self, factories, primary)
        for _, v in factories do
            if not v.Dead and not (v:IsUnitState('Building') or v:IsUnitState('Upgrading')) then
                local guarded = v:GetGuardedUnit()
                if not guarded or guarded.EntityId ~= primary.EntityId then
                    IssueToUnitClearCommands(v)
                    IssueFactoryAssist({v}, primary)
                end
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param factories FactoryUnit[]
    ---@param location PBMBuildLocation
    ---@param rallyLoc? Vector
    ---@param markerType? string Marker type to use. Defaults to `Rally Point`
    ---@return boolean
    PBMSetRallyPoint = function(self, factories, location, rallyLoc, markerType)
        if not TableEmpty(factories) then
            local rally

            local x, z = 0, 0
            for _, factory in pairs(factories) do
                local pos = factory:GetPosition()
                x = x + pos[1]
                z = z + pos[3]
            end

            local numFactories = TableGetn(factories)
            x = x / numFactories
            z = z / numFactories

            if not rallyLoc and not location.UseCenterPoint then
                -- Get the specified marker type, or fall back to the default 'Rally Point'
                local pnt = AIUtils.AIGetClosestMarkerLocation(self, markerType or 'Rally Point', x, z)
                if pnt and TableGetn(pnt) == 3 then
                    rally = Vector(pnt[1], pnt[2], pnt[3])
                end
            elseif not rallyLoc and location.UseCenterPoint then
                rally = location.Location
            elseif rallyLoc then
                rally = rallyLoc
            else
                error('*ERROR: PBMSetRallyPoint - Missing Rally Location and Marker Type', 2)
            end

            if rally then
                IssueClearFactoryCommands(factories)
                IssueFactoryRallyPoint(factories, rally)
            end
        end
        return true
    end,

    ---@param self CampaignAIBrain
    ---@param factory Unit
    ---@param location PBMBuildLocation|string
    ---@return boolean
    PBMFactoryLocationCheck = function(self, factory, location)
        -- If passed in a PBM Location table or location type name
        local locationName = location
        if type(location) == 'table' then
            locationName = location.LocationType
        end
        ---@cast locationName -PBMBuildLocation
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
            ---@cast locationPosition -nil
            factory.PBMData[locationName] = Utilities.GetDistanceBetweenTwoPoints2(locationPosition[1], locationPosition[3], pos[1], pos[3])
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

    ---@param self CampaignAIBrain
    ---@param factories Unit
    ---@param primary Unit
    ---@return boolean
    PBMCheckHighestTechFactory = function(self, factories, primary)
        local catLevel = 1
        if EntityCategoryContains(tech3categories, primary) then
            catLevel = 3
        elseif EntityCategoryContains(tech2categories, primary) then
            catLevel = 2
        end

        for catNum, cat in techCategoryTableAsc do
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
    ---@param self CampaignAIBrain
    ---@param factories Unit
    ---@return FactoryUnit
    PBMGetPrimaryFactory = function(self, factories)
        for kc, vc in techCategoryTableDesc do
            for k, v in factories do
                if EntityCategoryContains(vc, v) and not v:IsUnitState('Upgrading') then
                    return v
                end
            end
        end---@diagnostic disable-line: missing-return
    end,

    ---Returns true when `factory` and all factory assisting it are not building anything.
    ---@param self CampaignAIBrain
    ---@param factory FactoryUnit
    ---@return boolean
    PBMCanFactoryBuildNextPlatoon = function(self, factory)
        if factory:GetNumBuildOrders(allUnitsCategories) > 0 then
            return false
        end

        local guards = factory:GetGuards()
        for _, fac in pairs(guards) do
            if fac:GetNumBuildOrders(allUnitsCategories) > 0 or fac:IsUnitState('Building') then
                return false
            end
        end

        return true
    end,

    ---@param self CampaignAIBrain
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
        end---@diagnostic disable-line: missing-return
    end,

    ---@param self CampaignAIBrain
    ---@param platoon Platoon
    ---@param amount number
    PBMAdjustPriority = function(self, platoon, amount)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
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

    ---@param self CampaignAIBrain
    ---@param platoon Platoon
    ---@param amount number
    PBMSetPriority = function(self, platoon, amount)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
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
    ---@param self CampaignAIBrain
    ---@param loc MarkerName|Vector
    ---@param radius number
    ---@param locType string
    ---@param useCenterPoint? boolean
    PBMAddBuildLocation = function(self, loc, radius, locType, useCenterPoint)
        if not radius or not loc or not locType then
            error('*AI ERROR: INVALID BUILD LOCATION FOR PBM', 2)
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
            TableInsert(self.PBM.Locations, spec)
        else
            error('*AI  ERROR: Attempting to add a build location with a duplicate name: '..spec.LocationType, 2)
        end
    end,

    ---@param self CampaignAIBrain
    ---@param locationName string
    ---@return PBMBuildLocation?
    PBMGetLocation = function(self, locationName)
        if self.HasPlatoonList then
            for _, v in self.PBM.Locations do
                if v.LocationType == locationName then
                    return v
                end
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param loc string
    ---@return Vector?
    PBMGetLocationCoords = function(self, loc)
        if not loc then
            return
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
        end
    end,

    ---@param self CampaignAIBrain
    ---@param loc string
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
        end
        return false
    end,

    ---@param self CampaignAIBrain
    ---@param location string
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

    ---@param self CampaignAIBrain
    ---@param location string
    ---@return FactoryUnit[] | false
    PBMGetAllFactories = function(self, location)
        if not location then
            return false
        end
        for num, loc in self.PBM.Locations do
            if loc.LocationType == location then
                local facs = {}
                for k, v in loc.PrimaryFactories do
                    TableInsert(facs, v)
                    if not v.Dead then
                        for fNum, fac in v:GetGuards() do
                            if EntityCategoryContains(factoryCategories, fac) then
                                TableInsert(facs, fac)
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
    ---@param self CampaignAIBrain
    ---@param loc? Vector
    ---@param locType? string
    PBMRemoveBuildLocation = function(self, loc, locType)
        for k, v in self.PBM.Locations do
            if (loc and v.Location == loc) or (locType and v.LocationType == locType) then
                TableRemove(self.PBM.Locations, k)
            end
        end
    end,

    ---Sets how often will the thread with building and forming platoons run.
    ---
    ---**Do NOT change this value unless you really know why you're changing it.**
    ---
    ---Set this value lower (2) to to nudge the AI into starting building the base in intro cinematics,
    ---but don't forget to reset it later to not cause lags running too often on large bases.
    ---@param self CampaignAIBrain
    ---@param seconds number Defaults is 10 seconds.
    PBMSetCheckInterval = function(self, seconds)
        self.PBM.BuildCheckInterval = seconds
    end,

    ---A random platoon will be picked from all platoons that have the same (highest) priority and are passing build conditions.
    ---@see CampaignAIBrain:PBMDisableRandomSamePriority()
    ---@param self CampaignAIBrain
    PBMEnableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = true
    end,

    ---First highest priority platoon with passing build conditions will be built.
    ---@see CampaignAIBrain:PBMEnableRandomSamePriority()
    ---@param self CampaignAIBrain
    PBMDisableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = false
    end,

    ---Transfer factories between `BusyFactories` and `ArmyPool` platoons.
    ---
    ---Factories that are building or upgrading will get assigned to `BusyFactories` and those that don't to `ArmyPool`.
    ---@param self CampaignAIBrain
    PBMCheckBusyFactories = function(self)
        local busyPlat = self:GetPlatoonUniquelyNamed('BusyFactories')
        if not busyPlat then
            busyPlat = self:MakePlatoon('', '')
            busyPlat:UniquelyNamePlatoon('BusyFactories')
        end

        local poolPlat = self:GetPlatoonUniquelyNamed('ArmyPool')
        local poolTransfer = {}
        for _, v in poolPlat:GetPlatoonUnits() do
            if not v.Dead and EntityCategoryContains(immobileFactories, v) then
                if v:IsUnitState('Building') or v:IsUnitState('Upgrading') then
                    TableInsert(poolTransfer, v)
                end
            end
        end

        local busyTransfer = {}
        for _, v in busyPlat:GetPlatoonUnits() do
            if not v.Dead and not v:IsUnitState('Building') and not v:IsUnitState('Upgrading') then
                TableInsert(busyTransfer, v)
            end
        end

        self:AssignUnitsToPlatoon(poolPlat, busyTransfer, 'Unassigned', 'None')
        self:AssignUnitsToPlatoon(busyPlat, poolTransfer, 'Unassigned', 'None')
    end,

    ---@param self CampaignAIBrain
    PBMUnlockStartThread = function(self)
        WaitSeconds(1)
        ScenarioInfo.PBMStartLock = false
    end,

    ---@param self CampaignAIBrain
    PBMUnlockStart = function(self)
        while ScenarioInfo.PBMStartLock do
            WaitTicks(1)
        end
        ScenarioInfo.PBMStartLock = true

        -- Fork a separate thread that unlocks after a second, but this brain continues on
        self:ForkThread(self.PBMUnlockStartThread)
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ---@param platoon Platoon
    ---@param builderData PBMPlatoonBuilderTask
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
    end,

    ---@param self CampaignAIBrain
    ---@param platoon Platoon
    PBMRemoveHandle = function(self, platoon)
        for typek, typev in self.PBM.PlatoonTypes do
            for k, v in self.PBM.Platoons[typev] do
                if not v.PlatoonHandles then
                    error('*AI DEBUG: No PlatoonHandles for builder - ' .. v.BuilderName)
                end
                for num, plat in v.PlatoonHandles do
                    if plat == platoon then
                        v.PlatoonHandles[num] = false
                    end
                end
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param builder PBMPlatoonBuilderTask
    PBMSetHandleBuilding = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
        end
        for k, v in builder.PlatoonHandles do
            if not v then
                builder.PlatoonHandles[k] = 'BUILDING'
                return
            end
        end
        error('*AI DEBUG: No handle spot empty! - ' .. builder.BuilderName)
    end,

    ---@param self CampaignAIBrain
    ---@param builder PBMPlatoonBuilderTask
    ---@return boolean
    PBMCheckHandleBuilding = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
        end
        for k, v in builder.PlatoonHandles do
            if v == 'BUILDING' then
                return true
            end
        end
        return false
    end,

    ---@param self CampaignAIBrain
    ---@param builder PBMPlatoonBuilderTask
    ---@return boolean
    PBMSetBuildingHandleFalse = function(self, builder)
        if not builder.PlatoonHandles then
            error('*AI DEBUG: No PlatoonHandles for builder - ' .. builder.BuilderName)
        end
        for k, v in builder.PlatoonHandles do
            if v == 'BUILDING' then
                builder.PlatoonHandles[k] = false
                return true
            end
        end
        return false
    end,

    ---@param self CampaignAIBrain
    ---@param builder PBMPlatoonBuilderTask
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

    ---Returns a list of platoon builder entries to pick from for building.
    ---
    ---Entry with the highest priority and passing checks (primary factory can build it, build conditions pass,
    ---platoon count for this builder hasn't been reached yet.) will be picked. This can be multiple entries when
    ---`PBM.RandomSamePriority` is enabled. Platoons with `0` priority or those that don't require construction
    ---will be skipped.
    ---@param self CampaignAIBrain
    ---@param location PBMBuildLocation
    ---@param list PBMPlatoonBuilderTask[]
    ---@param pType PMBPlatoonType
    ---@return PBMPossiblePlatoon[]
    PBMGetPossibleBuilders = function(self, location, list, pType)
        local armyIndex = self:GetArmyIndex()
        local builderTable = ScenarioInfo.BuilderTable[self.CurrentPlan][pType]
        local RandomSamePriority = self.PBM.RandomSamePriority
        local suggestedFactories = {location.PrimaryFactories[pType]}

        ---@type PBMPossiblePlatoon[]
        local possibleTemplates = {}
        local priorityLevel

        for i, entry in ipairs(list) do
            local globalBuilder = builderTable[entry.BuilderName]
            -- Break if we already have a possible platoon and `RandomSamePriority` is off
            if priorityLevel and (entry.Priority ~= priorityLevel or not RandomSamePriority) then
                break
            elseif (not priorityLevel or priorityLevel == entry.Priority) and entry.Priority > 0 and globalBuilder.RequiresConstruction
                    -- The location we're looking at is an allowed location
                    and (entry.LocationType == location.LocationType or not entry.LocationType)
                    -- Make sure there is a handle slot available
                    and self:PBMHandleAvailable(entry) then
                -- Fix up the primary factories to fit the proper table required by CanBuildPlatoon
                local factories = self:CanBuildPlatoon(entry.PlatoonTemplate, suggestedFactories)
                if factories and self:PBMCheckBuildConditions(globalBuilder.BuildConditions, armyIndex) then
                    priorityLevel = entry.Priority
                    for _ = 1, self:PBMNumHandlesAvailable(entry) do
                        TableInsert(possibleTemplates, {Builder = entry, Index = i, Global = globalBuilder})
                    end
                end
            end
        end

        return possibleTemplates
    end,

    --- Main building and forming platoon thread for the Platoon Build Manager
    ---@param self CampaignAIBrain
    PlatoonBuildManagerThread = function(self)
        local personality = self:GetPersonality()

        -- Split the brains up a bit so they aren't all doing the PBM thread at the same time
        if not self.PBMStartUnlocked then
            self:PBMUnlockStart()
        end

        while true do
            self:PBMCheckBusyFactories()
            if self.BrainType == 'AI' then
                self:PBMSetPrimaryFactories()
            end
            local PBM = self.PBM
            local platoons = PBM.Platoons
            -- Clear the cache so we can get fresh new responses!
            self:PBMClearBuildConditionsCache()
            -- Go through the different types of platoons
            for _, platoonType in pairs(PBM.PlatoonTypes) do
                -- First go through the list of locations and see if we can build stuff there.
                for _, location in pairs(PBM.Locations) do
                    -- See if we have platoons to build in that type
                    local platoonList = platoons[platoonType]
                    if TableEmpty(platoonList) then
                        continue
                    end

                    -- Sort the list of platoons via priority
                    if PBM.NeedSort[platoonType] then
                        TableSort(platoonList, sortDownByPriority)
                        PBM.NeedSort[platoonType] = false
                    end
                    -- FORM PLATOONS
                    self:PBMFormPlatoons(true, platoonType, location)
                    -- BUILD PLATOONS
                    -- Check if we can build next platoon
                    local priFac = location.PrimaryFactories[platoonType]
                    if not priFac or priFac.Dead or not self:PBMCanFactoryBuildNextPlatoon(priFac) then
                        continue
                    end

                    ---@type PBMPossiblePlatoon[]
                    local possibleTemplates = self:PBMGetPossibleBuilders(location, platoonList, platoonType)
                    -- No builder met the conditions
                    if TableEmpty(possibleTemplates) then
                        continue
                    end

                    local builderData = TableRandom(possibleTemplates)
                    local builderEntry = builderData.Builder
                    local globalBuilder = builderData.Global
                    local suggestedFactories = {priFac}
                    local factories = self:CanBuildPlatoon(builderEntry.PlatoonTemplate, suggestedFactories)
                    builderEntry.BuildTemplate = self:PBMBuildNumFactories(builderEntry.PlatoonTemplate, location, platoonType, factories)

                    -- Check all the requirements to build the platoon
                    -- The Primary Factory can actually build this platoon
                    -- The platoon build condition has been met
                    -- Finally, build the platoon.
                    self:BuildPlatoon(builderEntry.BuildTemplate, factories, personality:GetPlatoonSize())
                    self:PBMSetHandleBuilding(PBM.Platoons[platoonType][builderData.Index])
                    if globalBuilder.GenerateTimeOut then
                        builderEntry.BuildTimeOut = self:PBMGenerateTimeOut(globalBuilder, factories, location, platoonType)
                    else
                        builderEntry.BuildTimeOut = globalBuilder.BuildTimeOut
                    end
                    builderEntry.PlatoonTimeOutThread = self:ForkThread(self.PBMPlatoonTimeOutThread, builderEntry)
                    if globalBuilder.PlatoonBuildCallbacks then
                        for _, cb in pairs(globalBuilder.PlatoonBuildCallbacks) do
                            import(cb[1])[cb[2]](self, globalBuilder.PlatoonData)
                        end
                    end
                end
                WaitTicks(1)
            end
            -- Do it all over again in 10 seconds.
            WaitSeconds(self.PBM.BuildCheckInterval or 10)
        end
    end,

    ---This function checks if all conditions that allow trying to form the platoon are passing. If the platoon gets actually
    ---formed will depend on the `ArmyPool` and if it has enough units.
    ---
    ---To form we need to accept the following:
    --- - The platoon is required to be in the building state and it is
    ---
    ---or
    --- - The platoon doesn't have a handle and either doesn't require to be building state or doesn't require construction
    ---all that and passes it's build condition function.
    ---@param self CampaignAIBrain
    ---@param task PBMPlatoonBuilderTask
    ---@param requireBuilding boolean
    ---@param numBuildOrders integer
    ---@param location PBMBuildLocation
    ---@param globalBuilder PBMPlatoonBuilderFull
    ---@return boolean
    PBMCanTryFormingPlatoon = function(self, task, requireBuilding, numBuildOrders, location, globalBuilder)
        local armyIndex = self:GetArmyIndex()

        if task.Priority > 0 and (requireBuilding and self:PBMCheckHandleBuilding(task)
                and numBuildOrders and numBuildOrders == 0
                and (not task.LocationType or task.LocationType == location.LocationType))
                or (((self:PBMHandleAvailable(task)) and (not requireBuilding or not globalBuilder.RequiresConstruction))
                and (not task.LocationType or task.LocationType == location.LocationType)
                and self:PBMCheckBuildConditions(globalBuilder.BuildConditions, armyIndex)) then
            return true
        end
        return false
    end,
    --- Form platoons
    --- Extracted as it's own function so you can call this to try and form platoons to clean up the pool
    ---@param self CampaignAIBrain
    ---@param requireBuilding boolean `true` = platoon must have `'BUILDING'` has its handle, `false` = it'll form any platoon it can
    ---@param platoonType PlatoonType Platoontype is just `'Air'/'Land'/'Sea'`, those are found in the platoon build manager table template.
    ---@param location PBMBuildLocation Specific build location where to do this.  If they aren't specified they will grab from anywhere.
    PBMFormPlatoons = function(self, requireBuilding, platoonType, location)
        local platoonList = self.PBM.Platoons
        local personality = self:GetPersonality()
        local ptnSize = personality:GetPlatoonSize()
        local numBuildOrders = nil

        local primFac = location.PrimaryFactories[platoonType]
        if primFac and not primFac.Dead then
            numBuildOrders = primFac:GetNumBuildOrders(allUnitsCategories)
            if numBuildOrders == 0 then
                local guards = primFac:GetGuards()
                if guards and not TableEmpty(guards) then
                    for kg, vg in guards do
                        numBuildOrders = numBuildOrders + vg:GetNumBuildOrders(allUnitsCategories)
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

        local globalBuilders = ScenarioInfo.BuilderTable[self.CurrentPlan]
        -- Go through the platoon list to form a platoon
        for _, task in ipairs(platoonList[platoonType]) do
            local globalBuilder = globalBuilders[platoonType][task.BuilderName]
            if not self:PBMCanTryFormingPlatoon(task, requireBuilding, numBuildOrders, location, globalBuilder) then
                continue
            end

            --if not string.find(task.BuilderName, "BaseManager") then
            --    LOG(string.format("Trying to form platoon: %s, num: %d", task.BuilderName, numBuildOrders or -1))
            --end

            local poolPlatoon = self:GetPlatoonUniquelyNamed('ArmyPool')
            local formIt = false
            local template = task.BuildTemplate or task.PlatoonTemplate

            ---@type table<integer, integer> Squad index to cached minSize
            local flipTable = {}
            local squadNum = 3
            while squadNum <= TableGetn(template) do
                ---@type PlatoonSquadTemplate
                local squadTemplate = template[squadNum]
                if squadTemplate[2] < 0 then
                    flipTable[squadNum] = squadTemplate[2]
                    squadTemplate[2] = 1
                end
                squadNum = squadNum + 1
            end

            if location.Location and location.Radius and task.LocationType then
                formIt = poolPlatoon:CanFormPlatoon(template, ptnSize, location.Location, location.Radius)
            elseif not task.LocationType then
                formIt = poolPlatoon:CanFormPlatoon(template, ptnSize)
            end

            if formIt then
                self:PBMFormPlatoon(location, task, poolPlatoon, template, ptnSize, globalBuilder)
            end

            for squadIndex, minSIze in flipTable do
                template[squadIndex][2] = minSIze
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param location PBMBuildLocation
    ---@param task PBMPlatoonBuilderTask
    ---@param poolPlatoon Platoon
    ---@param template PlatoonTemplate
    ---@param ptnSize integer
    ---@param globalBuilder PBMPlatoonBuilderFull
    PBMFormPlatoon = function(self, location, task, poolPlatoon, template, ptnSize, globalBuilder)
        ---@type Platoon
        local platoon
        if location.Location and location.Radius and task.LocationType then
            platoon = poolPlatoon:FormPlatoon(template, ptnSize, location.Location, location.Radius)
        elseif not task.LocationType then
            platoon = poolPlatoon:FormPlatoon(template, ptnSize)
        end

        self:PBMStoreHandle(platoon, task)
        if task.PlatoonTimeOutThread then
            task.PlatoonTimeOutThread:Destroy()
        end

        platoon.PlanName = template[2]

        -- If we have specific AI, fork that AI thread
        if globalBuilder.PlatoonAIFunction then
            platoon:StopAI()
            platoon:ForkAIThread(import(globalBuilder.PlatoonAIFunction[1])[globalBuilder.PlatoonAIFunction[2]])
        end

        -- If we have an AI from "platoon.lua", use that
        if globalBuilder.PlatoonAIPlan then
            platoon:SetAIPlan(globalBuilder.PlatoonAIPlan)
        end

        -- If we have additional threads to fork on the platoon, do that as well.
        -- Note: These are platoon AI functions from "platoon.lua"
        if globalBuilder.PlatoonAddPlans then
            for _, planName in globalBuilder.PlatoonAddPlans do
                platoon:ForkThread(platoon[planName])
            end
        end

        -- If we have additional functions to fork on the platoon, do that as well
        if globalBuilder.PlatoonAddFunctions then
            for _, addFnRef in globalBuilder.PlatoonAddFunctions do
                platoon:ForkThread(import(addFnRef[1])[addFnRef[2]])
            end
        end

        -- If we have additional behaviours to fork on the platoon, do that as well
        -- Note: These are platoon AI functions from "AIBehaviors.lua"
        if globalBuilder.PlatoonAddBehaviors then
            for _, fnName in globalBuilder.PlatoonAddBehaviors do
                platoon:ForkThread(Behaviors[fnName])
            end
        end

        local builderName = task.BuilderName
        if builderName then
            local nameCounter = self.PlatoonNameCounter
            if nameCounter[builderName] then
                nameCounter[builderName] = nameCounter[builderName] + 1
            else
                nameCounter[builderName] = 1
            end
        end

        platoon:AddDestroyCallback(self.PBMPlatoonDestroyed)
        platoon.BuilderName = builderName

        -- Set the platoon data
        -- Also set the platoon to be part of the attack force if specified in the platoon data, used for AttackManager platoon forming
        if globalBuilder.PlatoonData then
            platoon:SetPlatoonData(globalBuilder.PlatoonData)
            if globalBuilder.PlatoonData.AMPlatoons and not TableEmpty(globalBuilder.PlatoonData.AMPlatoons) then
                platoon:SetPartOfAttackForce()
            end
        end
    end,

    --- Get the primary factory with the lowest order count
    --- This is used for the 'Any' platoon type so we can find any primary factory to build from.
    ---@param self CampaignAIBrain
    ---@param location PBMBuildLocation
    ---@return FactoryUnit?
    GetLowestOrderPrimaryFactory = function(self, location)
        local num
        local fac
        for _, v in self.PBM.PlatoonTypes do
            local priFac = location.PrimaryFactories[v]
            if priFac then
                local ord = priFac:GetNumBuildOrders(allUnitsCategories)
                if not num or num > ord then
                    num = ord
                    fac = location.PrimaryFactories[v]
                end
            end
        end
        return fac
    end,

    ---Set number of units to be built as the number of factories in a location
    ---@param self CampaignAIBrain
    ---@param template PlatoonTemplate
    ---@param location PBMBuildLocation
    ---@param pType PlatoonType
    ---@param factory Unit
    ---@return PlatoonTemplate
    PBMBuildNumFactories = function (self, template, location, pType, factory)
        local retTemplate = table.deepcopy(template)
        local assistFacs = factory[1]:GetGuards()
        TableInsert(assistFacs, factory[1])
        local facs = {T1 = 0, T2 = 0, T3 = 0}
        for _, v in assistFacs do
            if EntityCategoryContains(tech3factoriesCategory, v) then
                facs.T3 = facs.T3 + 1
            elseif EntityCategoryContains(tech2factoriesCategory, v) then
                facs.T2 = facs.T2 + 1
            elseif EntityCategoryContains(factoryCategories, v) then
                facs.T1 = facs.T1 + 1
            end
        end

        -- Handle any squads with a specified build quantity
        local squad = 3
        while squad <= TableGetn(retTemplate) do
            ---@type PlatoonSquadTemplate
            local squadTemplate = retTemplate[squad]
            if squadTemplate[2] > 0 then
                local bp = self:GetUnitBlueprint(squadTemplate[1])
                local buildLevel = AIBuildUnits.UnitBuildCheck(bp)
                local remaining = squadTemplate[3]
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
        while squad <= TableGetn(retTemplate) do
            ---@type PlatoonSquadTemplate
            local squadTemplate = retTemplate[squad]
            if squadTemplate[2] < 0 then
                local bpId = squadTemplate[1]
                TableInsert(remainingIds['T'..AIBuildUnits.UnitBuildCheck(self:GetUnitBlueprint(bpId)) ], bpId)
            end
            squad = squad + 1
        end
        local rTechLevel = 3
        while rTechLevel >= 1 do
            for num, unitId in remainingIds['T'..rTechLevel] do
                for tempRow = 3, TableGetn(retTemplate) do
                    ---@type PlatoonSquadTemplate
                    local squadTemplate = retTemplate[tempRow]
                    if squadTemplate[1] == unitId and squadTemplate[2] < 0 then
                        squadTemplate[3] = 0
                        for fTechLevel = rTechLevel, 3 do
                            ---@diagnostic disable-next-line: assign-type-mismatch
                            squadTemplate[3] = squadTemplate[3] + (facs['T'..fTechLevel] * math.abs(squadTemplate[2]))
                            facs['T'..fTechLevel] = 0
                        end
                    end
                end
            end
            rTechLevel = rTechLevel - 1
        end

        -- Remove any IDs with 0 as a build quantity.
        local size = TableGetn(retTemplate)
        if size >= 3 then
            for i = size, 3, -1 do
                if retTemplate[i][3] == 0 then
                    TableRemove(retTemplate, i)
                end
            end
        end

        return retTemplate
    end,

    ---@param self CampaignAIBrain
    ---@param builder PBMPlatoonBuilder
    ---@param factories Unit
    ---@param location PBMBuildLocation
    ---@param pType PlatoonType
    ---@return integer
    PBMGenerateTimeOut = function(self, builder, factories, location, pType)
        local retBuildTime = 0
        local i = 3
        local numFactories = TableGetn(factories[1]:GetGuards()) + 1
        if numFactories == 0 then
            numFactories = 1
        end

        local template = builder.PlatoonTemplate
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

    ---@param self CampaignAIBrain
    ---@param location PBMBuildLocation
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
            if EntityCategoryContains(airFactoryCategories, ev) then
                TableInsert(airFactories, ev)
            elseif EntityCategoryContains(landFactoryCategories, ev) then
                TableInsert(landFactories, ev)
            elseif EntityCategoryContains(navalFactoryCategories, ev) then
                TableInsert(seaFactories, ev)
            elseif EntityCategoryContains(gateFactoryCategories, ev) then
                TableInsert(gates, ev)
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ---@param platoon Platoon
    PBMPlatoonDestroyed = function(self, platoon)
        self:PBMRemoveHandle(platoon)
        local builderName = platoon.PlatoonData.BuilderName
        if builderName then
            self.PlatoonNameCounter[builderName] = self.PlatoonNameCounter[builderName] - 1
        end
    end,

    ---@param self CampaignAIBrain
    ---@param bCs table
    ---@param index number
    ---@return boolean
    PBMCheckBuildConditions = function(self, bCs, index)
        local buildConditionsTable = self.PBM.BuildConditionsTable
        for _, v in pairs(bCs) do
            if not v.LookupNumber[index] then
                local found = false

                for num, bcData in pairs(buildConditionsTable) do
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
                    TableInsert(buildConditionsTable, v)
                    v.LookupNumber[index] = TableGetn(buildConditionsTable)
                end
            end
            if not buildConditionsTable[v.LookupNumber[index]].Cached[index] then
                if not buildConditionsTable[v.LookupNumber[index]].Cached then
                    buildConditionsTable[v.LookupNumber[index]].Cached = {}
                    buildConditionsTable[v.LookupNumber[index]].CachedVal = {}
                end
                buildConditionsTable[v.LookupNumber[index]].Cached[index] = true

                local d = buildConditionsTable[v.LookupNumber[index]]
                buildConditionsTable[v.LookupNumber[index]].CachedVal[index] = import(d[1])[d[2]](self, unpack(d[3]))
                if not self.BCFuncCalls then
                    self.BCFuncCalls = 0
                end

                if index == 3 then
                    self.BCFuncCalls = self.BCFuncCalls + 1
                end
            end

            if not buildConditionsTable[v.LookupNumber[index]].CachedVal[index] then
                return false
            end
        end
        return true
    end,

    ---@param self CampaignAIBrain
    PBMClearBuildConditionsCache = function(self)
        local armyIndex = self:GetArmyIndex()
        for _, v in pairs(self.PBM.BuildConditionsTable) do
            v.Cached[armyIndex] = false
        end
    end,

    ---@param self CampaignAIBrain
    ---@param platoonList Platoon[]
    ---@param ai? string
    ---@return Platoon
    CombinePlatoons = function(self, platoonList, ai)
        local squadTypes = {'Unassigned', 'Attack', 'Artillery', 'Support', 'Scout', 'Guard'}
        local returnPlatoon
        if not ai then
            returnPlatoon = self:MakePlatoon('', 'None')
        else
            returnPlatoon = self:MakePlatoon('', ai)
        end

        for k, platoon in platoonList do
            for j, type in squadTypes do
                local squadUnits = platoon:GetSquadUnits(type)
                local formation = 'AttackFormation'
                if squadUnits then
                    self:AssignUnitsToPlatoon(returnPlatoon, squadUnits, type, formation)
                end
            end
            self:DisbandPlatoon(platoon)
        end
        return returnPlatoon
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

    --#endregion
    ----------------------------------------------------------------------------------------
    --#region legacy functionality
    ---
    --- All functions below solely exist because the code is too tightly coupled. We can't
    --- remove them without drastically changing how the code base works. We can't do that
    --- because it would break mod compatibility

    ---@param self EasyAIBrain
    SetConstantEvaluate = function(self)
    end,

    ---@param self EasyAIBrain
    InitializeSkirmishSystems = function(self)
    end,

    ForceManagerSort = function(self)
    end,

    --#endregion
}
