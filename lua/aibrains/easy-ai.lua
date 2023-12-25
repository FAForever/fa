
-- load builder systems
doscript '/lua/aibrains/templates/base/base-template.lua'
doscript '/lua/aibrains/templates/builder-groups/builder-group-template.lua'
doscript '/lua/aibrains/templates/builders/builder-template.lua'

local StandardBrain = import("/lua/aibrain.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent
local BaseManager = import("/lua/aibrains/managers/base-manager.lua")

local SimpleEnergyTasks = import("/lua/aibrains/tasks/brain/simple-energy.lua")

---@class EasyAIBrainBaseTemplates
---@field BaseTemplateMain AIBaseTemplate

---@class EasyAIBrainManagers
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

---@class EasyAIBrain: AIBrain, AIBrainEconomyComponent
---@field AIBaseTemplates EasyAIBrainBaseTemplates
---@field GridReclaim AIGridReclaim
---@field GridBrain AIGridBrain
---@field GridRecon AIGridRecon
---@field BaseManagers AIBase[]
AIBrain = Class(StandardBrain, EconomyComponent) {

    SkirmishSystems = true,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point and the teams are not yet defined
    ---@param self EasyAIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        StandardBrain.OnCreateAI(self, planName)
        EconomyComponent.OnCreateAI(self)

        self.BaseManagers = {
            BaseManager.CreateBaseManager(self, { 0, 10} )
        }

        self.BaseManagers[1]:AddBrainTask(SimpleEnergyTasks.EnergyTech1)
        self.BaseManagers[1]:AddBrainTask(SimpleEnergyTasks.EnergyTech1)
        self.BaseManagers[1]:AddBrainTask(SimpleEnergyTasks.EnergyTech1)
        self.BaseManagers[1]:AddBrainTask(SimpleEnergyTasks.EnergyTech1)

        self:ForkThread(self.GetBaseDebugInfoThread)
        self:IMAPConfiguration()
    end,

    --- Called after `BeginSession`, at this point all props, resources and initial units exist in the map and the teams are defined
    ---@param self EasyAIBrain
    OnBeginSession = function(self)
        StandardBrain.OnBeginSession(self)

        -- requires navigational mesh
        import("/lua/sim/navutils.lua").Generate()

        -- requires these markers to exist
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()
        import("/lua/sim/markerutilities.lua").GenerateNavalAreaMarkers()
        import("/lua/sim/markerutilities.lua").GenerateRallyPointMarkers()

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
        local position = blip:GetPosition()
        self.GridRecon:OnIntelChange(position[1], position[3], reconType, val)
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

    --- Retrieves the nearest base for the given position
    ---@param self EasyAIBrain
    ---@param position Vector
    ---@return AIBase
    FindNearestBase = function(self, position)
        return self.BaseManagers[1]
    end,

    ---------------------------------------------------------------------------
    --#region Brain evaluation

    --- Delay in is game ticks
    EvaluateDelay = 11,

    ---@param self EasyAIBrain
    EvaluateBrainThread = function(self)
        while true do
            -- evaluate the Brain in a protected call to guarantee we can keep evaluating it in the future
            local ok, msg = pcall(self.EvaluateBrain, self)
            if not ok then
                WARN(msg)
            end

            local evaluateDelay = self.EvaluateDelay
            if evaluateDelay < 0 then
                evaluateDelay = 1
            end

            WaitTicks(evaluateDelay)
        end
    end,

    ---@param self EasyAIBrain
    EvaluateStructureTasks = function(self)
        local brain = self.Brain
        local structureTasks = self.StructureTasks

        for k = 1, table.getn(structureTasks) do
            local structureTask = structureTasks[k]

            -- todo: evaluate if we still need this task
        end
    end,


    ---@param self EasyAIBrain
    EvaluateBrain = function(self)
        local brain = self.Brain

        local engineeringTasks = self.EngineeringTasks
        local factoryTasks = self.FactoryTasks


        self:EvaluateStructureTasks()

        for k = 1, table.getn(engineeringTasks) do
            local engineeringTask = engineeringTasks[k]
        end

        for k = 1, table.getn(factoryTasks) do
            local factoryTask = factoryTasks[k]
        end


    end,

    --#region

    ---------------------------------------------------------------------------
    --#region C hooks

    ---@param platoon AIPlatoon
    ---@param units Unit[]
    ---@param squad PlatoonSquads
    ---@param formation UnitFormations
    AssignUnitsToPlatoon = function(self, platoon, units, squad, formation)
        StandardBrain.AssignUnitsToPlatoon(self, platoon, units, squad, formation)

        if squad == 'Attack' then
            platoon:OnUnitsAddedToAttackSquad(units)
        elseif squad == 'Artillery' then
            platoon:OnUnitsAddedToArtillerySquad(units)
        elseif squad == 'Guard' then
            platoon:OnUnitsAddedToGuardSquad(units)
        elseif squad =='Scout' then
            platoon:OnUnitsAddedToScoutSquad(units)
        elseif squad == 'Support' then
            platoon:OnUnitsAddedToSupportSquad(units)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Unit events

    --- Called by a unit as it starts being built
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnStartBeingBuilt = function(self, unit, builder, layer)
        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnStartBeingBuilt(unit, builder, layer)
    end,

    --- Called by a unit as it is finished being built
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, unit, builder, layer)
        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnStopBeingBuilt(unit, builder, layer)

        if EntityCategoryContains(categories.ENGINEER * categories.TECH1, unit) then
            local platoon = self:MakePlatoon('', '')
            platoon.Base = nearestBase
            platoon.Brain = self
            setmetatable(platoon, import("/lua/aibrains/platoons/platoon-simple-engineer.lua").AIPlatoonEngineerSimple)
            self:AssignUnitsToPlatoon(platoon, {unit}, 'Support', 'GrowthFormation')
            ChangeState(platoon, platoon.Start)
        end
    end,

    --- Called by a unit as it is destroyed
    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitDestroy = function(self, unit)
        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitDestroy(unit)
    end,

    --- Called by a unit as it starts building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuild = function(self, unit, built)
        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitStartBuild(unit, built)
    end,

    --- Called by a unit as it stops building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuild = function(self, unit, built)
        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitStopBuild(unit, built)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self EasyAIBrain
    ---@return AIBaseDebugInfo
    GetBaseDebugInfoThread = function(self)
        while true do
            -- if GetFocusArmy() == self:GetArmyIndex() then
            --     local position = GetMouseWorldPos()
            --     local identifier = self:FindNearestBase(position)
            --     if identifier then
            --         local base = self.BuilderManagers[identifier]
            --         local info = base:GetDebugInfo()
            --         Sync.AIBaseInfo = info
            --     end
            -- end

            WaitTicks(10)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Legacy functionality
    
    -- All functions below solely exist because the code is too tightly coupled. We can't
    -- remove them without drastically changing how the code base works. We can't do that
    -- because it would break mod compatibility

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

}
