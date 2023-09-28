
local AIUtils = import("/lua/ai/aiutilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Behaviors = import("/lua/ai/aibehaviors.lua")
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")

-- upvalue scope for performance
local TableGetn = table.getn

local StandardBrain = import("/lua/aibrain.lua").AIBrain

--- A basic campaign brain. Contains all the functionality that a campaign brain requires. This
--- brain is a 'blunt' copy of the functionality that is required to run various campaign maps.
---@class CampaignAIBrain: AIBrain
---@field PBM AiPlatoonBuildManager
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
    ---@param planName string
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
        import("/lua/sim/NavUtils.lua").Generate()

        -- requires these datastructures to understand the game
        self.GridReclaim = import("/lua/ai/gridreclaim.lua").Setup(self)
        self.GridBrain = import("/lua/ai/gridbrain.lua").Setup()
        self.GridRecon = import("/lua/ai/gridrecon.lua").Setup(self)
        self.GridPresence = import("/lua/AI/GridPresence.lua").Setup(self)
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
    --- campaign functionality

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
                self:ExecutePlan(self.CurrentPlan)
            end
        end
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ExecutePlan = function(self)
        self.CurrentPlanScript.ExecutePlan(self)
    end,

    ---@param self CampaignAIBrain
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
            error('*AI ERROR: Invalid plan list for army - '..self.Name, 2)
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
    ---@param attackDataTable table
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

    ---## AI PLATOON MANAGEMENT
    ---### New PlatoonBuildManager
    ---This system is meant to be able to give some data about the platoon you want and have them
    ---built and formed into platoons at will.
    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---Goes through the location areas, finds the factories, sets a primary then tells all the others to guard.
    ---@param self CampaignAIBrain
    PBMSetPrimaryFactories = function(self)
        for _, v in self.PBM.Locations do
            local factories = self:GetAvailableFactories(v.Location, v.Radius)
            local airFactories = {}
            local landFactories = {}
            local seaFactories = {}
            local gates = {}
            for ek, ev in factories do
                if EntityCategoryContains(categories.FACTORY * categories.AIR - categories.EXTERNALFACTORYUNIT, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(airFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.LAND - categories.EXTERNALFACTORYUNIT, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(landFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.NAVAL - categories.EXTERNALFACTORYUNIT, ev) and self:PBMFactoryLocationCheck(ev, v) then
                    table.insert(seaFactories, ev)
                elseif EntityCategoryContains(categories.FACTORY * categories.GATE - categories.EXTERNALFACTORYUNIT, ev) and self:PBMFactoryLocationCheck(ev, v) then
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
                self:PBMSetRallyPoint(seaFactories, v, nil, "Naval Rally Point")
                self:PBMSetRallyPoint(gates, v, nil)
            end
        end
    end,

    ---@param self CampaignAIBrain
    ---@param factories Unit
    ---@param primary Unit
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
                -- Get the specified marker type, or fall back to the default 'Rally Point'
                local pnt = AIUtils.AIGetClosestMarkerLocation(self, markerType or 'Rally Point', position[1], position[3])
                
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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
        end
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    ---@param interval number
    PBMSetCheckInterval = function(self, interval)
        self.PBM.BuildCheckInterval = interval
    end,

    ---@param self CampaignAIBrain
    PBMEnableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = true
    end,

    ---@param self CampaignAIBrain
    PBMDisableRandomSamePriority = function(self)
        self.PBM.RandomSamePriority = false
    end,

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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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
    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
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
        if platoon.PlatoonData.BuilderName then
            self.PlatoonNameCounter[platoon.PlatoonData.BuilderName] = self.PlatoonNameCounter[platoon.PlatoonData.BuilderName] - 1
        end
    end,

    ---@param self CampaignAIBrain
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

    ---@param self CampaignAIBrain
    PBMClearBuildConditionsCache = function(self)
        for k, v in self.PBM.BuildConditionsTable do
            v.Cached[self:GetArmyIndex()] = false
        end
    end,

    ---@param self CampaignAIBrain
    ---@param platoonList Platoon[]
    ---@param ai BaseAIBrain
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

    ----------------------------------------------------------------------------------------
    --- legacy functionality
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

}
