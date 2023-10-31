local StandardBrain = import("/lua/aibrain.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent

local AIUtils = import("/lua/ai/aiutilities.lua")

local Utilities = import("/lua/utilities.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local MarkerUtilities = import("/lua/sim/markerutilities.lua")

local FactoryManager = import("/lua/sim/factorybuildermanager.lua")
local PlatoonFormManager = import("/lua/sim/platoonformmanager.lua")
local BrainConditionsMonitor = import("/lua/sim/brainconditionsmonitor.lua")
local EngineerManager = import("/lua/sim/engineermanager.lua")

local SUtils = import("/lua/ai/sorianutilities.lua")

local TableGetn = table.getn

---@class TechAIBrainManagers
---@field FactoryManager AIFactoryManager
---@field EngineerManager AIEngineerManager
---@field StructureManager AIStructureManager

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

---@class TechAIBrain: AIBrain, AIBrainEconomyComponent
---@field GridReclaim AIGridReclaim
---@field GridBrain AIGridBrain
---@field GridRecon AIGridRecon
---@field BuilderManagers table<LocationType, AIBase>

---@class AIBrainTech : AIBrain, AIBrainEconomyComponent
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
---@field IntelData? table<string, number>
---@field IntelTriggerList table
---@field LayerPref "LAND" | "AIR"
---@field Name string
---@field Radars table<string, Unit[]>
---@field Result? AIResult
---@field Sorian boolean
---@field T4ThreatFound? table
---@field TacticalBases? table
---@field targetoveride boolean
---@field GridReclaim AIGridReclaim
---@field GridBrain AIGridBrain
---@field Team number The team this brain's army belongs to. Note that games with unlocked teams behave like free-for-alls.
---@field DelayEqualBuildPlattons table<string, number>     # Used to delay builders, the key is the builder name and the number is the game time in seconds that the builder remains delayed
AIBrain = Class(StandardBrain, EconomyComponent) {

    SkirmishSystems = true,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrainTech
    ---@param planName string
    OnCreateAI = function(self, planName)
        EconomyComponent.OnCreateAI(self)
        StandardBrain.OnCreateAI(self, planName)

        local personality = ScenarioInfo.ArmySetup[self.Name].AIPersonality

        local cheatPos = string.find(personality, 'cheat')
        if cheatPos then
            AIUtils.SetupCheat(self, true)
            ScenarioInfo.ArmySetup[self.Name].AIPersonality = string.sub(personality, 1, cheatPos - 1)
        end

        LOG('* OnCreateAI: AIPersonality: ('..personality..')')

        self.CurrentPlan = self.AIPlansList[self:GetFactionIndex()][1]
        self.RepeatExecution = true
        self:ForkThread(self.InitialAIThread)
        self.IntelData = {
            ScoutCounter = 0,
        }

        -- Flag enemy starting locations with threat?
        if ScenarioInfo.type == 'skirmish' then
            self:AddInitialEnemyThreat(200, 0.005)
        end

        self.UnitBuiltTriggerList = {}
        self.FactoryAssistList = {}
        self.DelayEqualBuildPlattons = {}
        self.ReclaimFailCounter = 0
        self.ReclaimFailTimeStamp = 0

        self:ForkThread(self.GetPlatoonDebugInfoThread)
    end,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point
    ---@param self AIBrainTech
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
        self.ConstantEval = true
    end,

    --- Called after `BeginSession`, at this point all props, resources and initial units exist in the map
    ---@param self AIBrainTech
    OnBeginSession = function(self)
        StandardBrain.OnBeginSession(self)

        -- requires navigational mesh
        import("/lua/sim/NavUtils.lua").Generate()

        -- requires these markers to exist
        import("/lua/sim/MarkerUtilities.lua").GenerateExpansionMarkers()
        import("/lua/sim/MarkerUtilities.lua").GenerateRallyPointMarkers()
        import("/lua/sim/MarkerUtilities.lua").GenerateNavalAreaMarkers()

        -- requires these datastructures to understand the game
        self.GridReclaim = import("/lua/ai/gridreclaim.lua").Setup(self)
        self.GridBrain = import("/lua/ai/gridbrain.lua").Setup()
        self.GridRecon = import("/lua/ai/gridrecon.lua").Setup(self)
        self.GridDeposits = import("/lua/ai/griddeposits.lua").Setup()
        self.GridPresence = import("/lua/AI/GridPresence.lua").Setup(self)
    end,

    ---@param self AIBrainTech
    OnDestroy = function(self)
        StandardBrain.OnDestroy(self)

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
    end,

    ---@param self AIBrainTech
    ---@param planName FileName
    ---@return string[]|nil
    ImportScenarioArmyPlans = function(self, planName)
        if planName and planName ~= '' then
            return import(planName).AIPlansList
        else
            return nil
        end
    end,

    ---@param self AIBrainTech
    InitialAIThread = function(self)
        -- delay the AI so it can't reclaim the start area before it's cleared from the ACU landing blast.
        WaitTicks(30)
        self.EvaluateThread = self:ForkThread(self.EvaluateAIThread)
        self.ExecuteThread = self:ForkThread(self.ExecuteAIThread)
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    ExecutePlan = function(self)
        self.CurrentPlanScript.ExecutePlan(self)
    end,

    ---@param self AIBrainTech
    SetRepeatExecution = function(self, repeatEx)
        self.RepeatExecution = repeatEx
    end,

    ---@param self AIBrainTech
    GetCurrentPlanScript = function(self)
        return self.CurrentPlanScript
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---SKIRMISH AI HELPER SYSTEMS
    ---@param self AIBrainTech
    InitializeSkirmishSystems = function(self)
        -- Make sure we don't do anything for the human player!!!
        if self.BrainType == 'Human' then
            return
        end
        LOG('Initialize Skirmish for '..self.Nickname)

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
        self.LowEnergyMode = false

        -- Add default main location and setup the builder managers
        self.NumBases = 0 -- AddBuilderManagers will increase the number
        
        -- Set the map center point
        self.MapCenterPoint = { (ScenarioInfo.size[1] / 2), GetSurfaceHeight((ScenarioInfo.size[1] / 2), (ScenarioInfo.size[2] / 2)) ,(ScenarioInfo.size[2] / 2) }

        self.BuilderManagers = {}
        SUtils.AddCustomUnitSupport(self)
        self:AddBuilderManagers(self:GetStartVector3f(), 100, 'MAIN', false)

        -- Begin the base monitor process
        self:BaseMonitorInitialization()
        local plat = self:GetPlatoonUniquelyNamed('ArmyPool')
        plat:ForkThread(plat.BaseManagersDistressAI)
        self.DeadBaseThread = self:ForkThread(self.DeadBaseMonitor)
        self.EnemyPickerThread = self:ForkThread(self.PickEnemy)

        
        self.IMAPConfig = {
            OgridRadius = 0,
            IMAPSize = 0,
            Rings = 0,
        }

        self:IMAPConfiguration()
        self:ForkThread(self.MapAnalysis)
    end,

    ---Removes bases that have no engineers or factories.  This is a sorian AI function
    ---Helps reduce the load on the game.
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    ---@param locationType string
    ---@return boolean
    GetLocationPosition = function(self, locationType)
        if not self.BuilderManagers[locationType] then
            WARN('*AI ERROR: Invalid location type - ' .. locationType)
            return false
        end
        return self.BuilderManagers[locationType].Position
    end,

    ---@param self AIBrainTech
    ---@param position Vector
    ---@return Vector
    FindClosestBuilderManagerPosition = function(self, position)
        local distance, closest
        for k, v in self.BuilderManagers do
            if v.EngineerManager and v.EngineerManager:GetNumCategoryUnits('Engineers', categories.ALLUNITS) > 0
            and v.FactoryManager and v.FactoryManager:GetNumCategoryFactories(categories.ALLUNITS) > 0 then
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
        end
        return closest
    end,

    ---@param self AIBrainTech
    ForceManagerSort = function(self)
        for _, v in self.BuilderManagers do
            v.EngineerManager:SortBuilderList('Any')
            v.FactoryManager:SortBuilderList('Land')
            v.FactoryManager:SortBuilderList('Air')
            v.FactoryManager:SortBuilderList('Sea')
            v.PlatoonFormManager:SortBuilderList('Any')
        end
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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
            BuilderHandles = {},
            Position = position,
            BaseType = MarkerUtilities.GetMarker(baseName).Name or 'Main',
            Layer = baseLayer,
        }

        self.NumBases = self.NumBases + 1
    end,

    ---@param self AIBrainTech
    ---@param category EntityCategory
    ---@return integer
    GetEngineerManagerUnitsBeingBuilt = function(self, category)
        local unitCount = 0
        for k, v in self.BuilderManagers do
            unitCount = unitCount + TableGetn(v.EngineerManager:GetEngineersBuildingCategory(category, categories.ALLUNITS))
        end
        return unitCount
    end,

    ---@param self AIBrainTech
    GetStartVector3f = function(self)
        local startX, startZ = self:GetArmyStartPos()
        return {startX, 0, startZ}
    end,

    ---# BASE MONITORING SYSTEM
    ---@param self AIBrainTech
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
        self:ForkThread(self.CanPathToCurrentEnemy)
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    BaseMonitorThread = function(self)
        while true do
            if self.BaseMonitor.BaseMonitorStatus == 'ACTIVE' then
                self:BaseMonitorCheck()
            end
            WaitSeconds(self.BaseMonitor.BaseMonitorTime)
        end
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    ---@param threattypes string
    T4ThreatMonitorTimeout = function(self, threattypes)
        WaitSeconds(180)
        for _, v in threattypes do
            self.T4ThreatFound[v] = false
        end
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
    PickEnemy = function(self)
        while true do
            self:PickEnemyLogic()
            WaitSeconds(120)
        end
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    GetNewAttackVectors = function(self)
        if not self.AttackVectorsThread then
            self.AttackVectorsThread = self:ForkThread(self.SetupAttackVectorsThread)
        end
    end,

    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
    ---@param eng Unit
    ---@param reference string
    ExpansionHelp = function(self, eng, reference)
        self:ForkThread(self.ExpansionHelpThread, eng, reference)
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

                    ArmyBrains[self:GetArmyIndex()].Nickname = 'CMDR Adaptive..(was '..oldName..')'
                    ScenarioInfo.ArmySetup[self.Name].AIPersonality = 'adaptive'

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
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
    ---@param pingData table
    DoAIPing = function(self, pingData)
        if self.Sorian then
            if pingData.Type then
                SUtils.AIHandlePing(self, pingData)
            end
        end
    end,

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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

    ---@param self AIBrainTech
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
    ---@param self AIBrainTech
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

    MapAnalysis = function(self)
        -- This function will provide various means of the AI populating intel data
        -- Due to it potentially influencing buider/base template decisions it needs to run before the AI creates its first buildermanager
        WaitTicks(10)
        self.IntelData.MapWaterRatio = self:GetMapWaterRatio()
        local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
        AIAttackUtils.NavalAttackCheck(self)

    end,

    IMAPConfiguration = function(self)
        -- Used to configure imap values, used for setting threat ring sizes depending on map size to try and get a somewhat decent radius
        local maxmapdimension = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])

        self.IMAPConfig = {
            OgridRadius = 0,
            IMAPSize = 0,
            Rings = 0,
        }

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

    ---@param self AIBrainTech
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

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self TechAIBrain
    ---@return AIBaseDebugInfo
    GetPlatoonDebugInfoThread = function(self)
        while true do
            if GetFocusArmy() == self:GetArmyIndex() then
                local units = DebugGetSelection()
                if units and units[1] then
                    local unit = units[1]
                    if unit.AIPlatoonReference then
                        Sync.AIPlatoonInfo = {
                            PlatoonInfo = unit.AIPlatoonReference:GetDebugInfo(),
                            EntityId = unit.EntityId,
                            BlueprintId = unit.Blueprint.BlueprintId,
                            Position = unit:GetPosition(),
                        }
                    end
                end
            end

            WaitTicks(10)
        end
    end,

    --#endregion

}
