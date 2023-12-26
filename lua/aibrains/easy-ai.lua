-- load builder systems
doscript '/lua/aibrains/templates/base/base-template.lua'
doscript '/lua/aibrains/templates/builder-groups/builder-group-template.lua'
doscript '/lua/aibrains/templates/builders/builder-template.lua'

local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent
local BaseManager = import("/lua/aibrains/managers/base-manager.lua")

local SimpleEnergyTasks = import("/lua/aibrains/tasks/brain/simple-energy.lua")

local StandardBrain = import("/lua/aibrain.lua").AIBrain
local StandardBrainOnUnitDestroy = StandardBrain.OnUnitDestroy
local StandardBrainOnUnitHealthChanged = StandardBrain.OnUnitHealthChanged
local StandardBrainOnUnitStopReclaim = StandardBrain.OnUnitStopReclaim
local StandardBrainOnUnitStartReclaim = StandardBrain.OnUnitStartReclaim
local StandardBrainOnUnitStartRepair = StandardBrain.OnUnitStartRepair
local StandardBrainOnUnitStopRepair = StandardBrain.OnUnitStopRepair
local StandardBrainOnUnitKilled = StandardBrain.OnUnitKilled
local StandardBrainOnUnitReclaimed = StandardBrain.OnUnitReclaimed
local StandardBrainOnUnitStartCapture = StandardBrain.OnUnitStartCapture
local StandardBrainOnUnitStopCapture = StandardBrain.OnUnitStopCapture
local StandardBrainOnUnitFailedCapture = StandardBrain.OnUnitFailedCapture
local StandardBrainOnUnitStartBeingCaptured = StandardBrain.OnUnitStartBeingCaptured
local StandardBrainOnUnitStopBeingCaptured = StandardBrain.OnUnitStopBeingCaptured
local StandardBrainOnUnitFailedBeingCaptured = StandardBrain.OnUnitFailedBeingCaptured
local StandardBrainOnUnitSiloBuildStart = StandardBrain.OnUnitSiloBuildStart
local StandardBrainOnUnitSiloBuildEnd = StandardBrain.OnUnitSiloBuildEnd
local StandardBrainOnUnitStartBuild = StandardBrain.OnUnitStartBuild
local StandardBrainOnUnitStopBuild = StandardBrain.OnUnitStopBuild
local StandardBrainOnUnitBuildProgress = StandardBrain.OnUnitBuildProgress
local StandardBrainOnUnitPaused = StandardBrain.OnUnitPaused
local StandardBrainOnUnitUnpaused = StandardBrain.OnUnitUnpaused
local StandardBrainOnUnitBeingBuiltProgress = StandardBrain.OnUnitBeingBuiltProgress
local StandardBrainOnUnitFailedToBeBuilt = StandardBrain.OnUnitFailedToBeBuilt
local StandardBrainOnUnitTransportAttach = StandardBrain.OnUnitTransportAttach
local StandardBrainOnUnitTransportDetach = StandardBrain.OnUnitTransportDetach
local StandardBrainOnUnitTransportAborted = StandardBrain.OnUnitTransportAborted
local StandardBrainOnUnitTransportOrdered = StandardBrain.OnUnitTransportOrdered
local StandardBrainOnUnitAttachedKilled = StandardBrain.OnUnitAttachedKilled
local StandardBrainOnUnitStartTransportLoading = StandardBrain.OnUnitStartTransportLoading
local StandardBrainOnUnitStopTransportLoading = StandardBrain.OnUnitStopTransportLoading
local StandardBrainOnUnitStartTransportBeamUp = StandardBrain.OnUnitStartTransportBeamUp
local StandardBrainOnUnitStoptransportBeamUp = StandardBrain.OnUnitStoptransportBeamUp
local StandardBrainOnUnitAttachedToTransport = StandardBrain.OnUnitAttachedToTransport
local StandardBrainOnUnitDetachedFromTransport = StandardBrain.OnUnitDetachedFromTransport
local StandardBrainOnUnitAddToStorage = StandardBrain.OnUnitAddToStorage
local StandardBrainOnUnitRemoveFromStorage = StandardBrain.OnUnitRemoveFromStorage
local StandardBrainOnUnitTeleportUnit = StandardBrain.OnUnitTeleportUnit
local StandardBrainOnUnitFailedTeleport = StandardBrain.OnUnitFailedTeleport
local StandardBrainOnUnitShieldEnabled = StandardBrain.OnUnitShieldEnabled
local StandardBrainOnUnitShieldDisabled = StandardBrain.OnUnitShieldDisabled
local StandardBrainOnUnitNukeArmed = StandardBrain.OnUnitNukeArmed
local StandardBrainOnUnitNukeLaunched = StandardBrain.OnUnitNukeLaunched
local StandardBrainOnUnitWorkBegin = StandardBrain.OnUnitWorkBegin
local StandardBrainOnUnitWorkEnd = StandardBrain.OnUnitWorkEnd
local StandardBrainOnUnitWorkFail = StandardBrain.OnUnitWorkFail
local StandardBrainOnUnitMissileImpactShield = StandardBrain.OnUnitMissileImpactShield
local StandardBrainOnUnitMissileImpactTerrain = StandardBrain.OnUnitMissileImpactTerrain
local StandardBrainOnUnitMissileIntercepted = StandardBrain.OnUnitMissileIntercepted
local StandardBrainOnUnitStartSacrifice = StandardBrain.OnUnitStartSacrifice
local StandardBrainOnUnitStopSacrifice = StandardBrain.OnUnitStopSacrifice
local StandardBrainOnUnitConsumptionActive = StandardBrain.OnUnitConsumptionActive
local StandardBrainOnUnitConsumptionInActive = StandardBrain.OnUnitConsumptionInActive
local StandardBrainOnUnitProductionActive = StandardBrain.OnUnitProductionActive
local StandardBrainOnUnitProductionInActive = StandardBrain.OnUnitProductionInActive
local StandardBrainOnUnitStartBeingBuilt = StandardBrain.OnUnitStartBeingBuilt
local StandardBrainOnUnitStopBeingBuilt = StandardBrain.OnUnitStopBeingBuilt

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
            BaseManager.CreateBaseManager(self, { 0, 10 })
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

    ---@param self EasyAIBrain
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
        elseif squad == 'Scout' then
            platoon:OnUnitsAddedToScoutSquad(units)
        elseif squad == 'Support' then
            platoon:OnUnitsAddedToSupportSquad(units)
        end
    end,

    --#endregion
    ---------------------------------------------------------------------------
    --#region Unit events

    --- Represents a list of unit events that are communicated to the brain. It makes it
    --- easier to respond to conditions that are happening on the battlefield. The following
    --- unit events are not communicated to the brain:
    ---
    --- - OnStorageChange (use OnAddToStorage and OnRemoveFromStorage instead)
    --- - OnAnimCollision
    --- - OnTerrainTypeChange
    --- - OnMotionVertEventChange
    --- - OnMotionHorzEventChange
    --- - OnLayerChange
    --- - OnPrepareArmToBuild
    --- - OnStartBuilderTracking
    --- - OnStopBuilderTracking
    --- - OnStopRepeatQueue
    --- - OnStartRepeatQueue
    --- - OnAssignedFocusEntity
    ---
    --- If you're interested for one of these events then you're encouraged to make a pull
    --- request to add the event!

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        StandardBrainOnUnitStartBeingBuilt(self, unit, builder, layer)

        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnStartBeingBuilt(unit, builder, layer)

        -- for debugging
        LOG("OnUnitStartBeingBuilt")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        StandardBrainOnUnitStopBeingBuilt(self, unit, builder, layer)

        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnStopBeingBuilt(unit, builder, layer)

        if EntityCategoryContains(categories.ENGINEER * categories.TECH1, unit) then
            local platoon = self:MakePlatoon('', '')
            platoon.Base = nearestBase
            platoon.Brain = self
            setmetatable(platoon, import("/lua/aibrains/platoons/platoon-simple-engineer.lua").AIPlatoonEngineerSimple)
            self:AssignUnitsToPlatoon(platoon, { unit }, 'Support', 'GrowthFormation')
            ChangeState(platoon, platoon.Start)
        end

        -- for debugging
        LOG("OnUnitStopBeingBuilt")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitDestroy = function(self, unit)
        StandardBrainOnUnitDestroy(self, unit)

        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitDestroy(unit)

        LOG("OnUnitDestroy")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param new number # 0.25 / 0.50 / 0.75 / 1.0
    ---@param old number # 0.25 / 0.50 / 0.75 / 1.0
    OnUnitHealthChanged = function(self, unit, new, old)
        StandardBrainOnUnitHealthChanged(self, unit, new, old)

        -- pass the event to the platoon
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnHealthChanged(unit, new, old)
        end

        LOG("OnUnitHealthChanged")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit | Prop | nil      # is nil when the prop or unit is completely reclaimed
    OnUnitStopReclaim = function(self, unit, target)
        StandardBrainOnUnitStopReclaim(self, unit, target)

        -- pass the event to the platoon
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStopReclaim(unit, target)
        end

        LOG("OnUnitStopReclaim")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit | Prop
    OnUnitStartReclaim = function(self, unit, target)
        StandardBrainOnUnitStartReclaim(self, unit, target)

        -- pass the event to the platoon
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStartReclaim(unit, target)
        end

        LOG("OnUnitStartReclaim")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStartRepair = function(self, unit, target)
        StandardBrainOnUnitStartRepair(self, unit, target)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStartRepair(unit, target)
        end

        LOG("OnUnitStartRepair")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStopRepair = function(self, unit, target)
        StandardBrainOnUnitStopRepair(self, unit, target)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStopRepair(unit, target)
        end

        LOG("OnUnitStopRepair")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param instigator Unit | Projectile | nil
    ---@param damageType DamageType
    ---@param overkillRatio number
    OnUnitKilled = function(self, unit, instigator, damageType, overkillRatio)
        StandardBrainOnUnitKilled(self, unit, instigator, damageType, overkillRatio)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnKilled(unit, instigator, damageType, overkillRatio)
        end

        LOG("OnUnitKilled")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param reclaimer Unit
    OnUnitReclaimed = function(self, unit, reclaimer)
        StandardBrainOnUnitReclaimed(self, unit, reclaimer)

        LOG("OnUnitReclaimed")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStartCapture = function(self, unit, target)
        StandardBrainOnUnitStartCapture(self, unit, target)

        LOG("OnUnitStartCapture")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStopCapture = function(self, unit, target)
        StandardBrainOnUnitStopCapture(self, unit, target)

        LOG("OnUnitStopCapture")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitFailedCapture = function(self, unit, target)
        StandardBrainOnUnitFailedCapture(self, unit, target)

        LOG("OnUnitFailedCapture")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param captor Unit
    OnUnitStartBeingCaptured = function(self, unit, captor)
        StandardBrainOnUnitStartBeingCaptured(self, unit, captor)

        LOG("OnUnitStartBeingCaptured")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param captor Unit
    OnUnitStopBeingCaptured = function(self, unit, captor)
        StandardBrainOnUnitStopBeingCaptured(self, unit, captor)

        LOG("OnUnitStopBeingCaptured")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param captor Unit
    OnUnitFailedBeingCaptured = function(self, unit, captor)
        StandardBrainOnUnitFailedBeingCaptured(self, unit, captor)

        LOG("OnUnitFailedBeingCaptured")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param weapon Weapon
    OnUnitSiloBuildStart = function(self, unit, weapon)
        StandardBrainOnUnitSiloBuildStart(self, unit, weapon)

        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnSiloBuildStart(unit, weapon)
        end

        LOG("OnUnitSiloBuildStart")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param weapon Weapon
    OnUnitSiloBuildEnd = function(self, unit, weapon)
        StandardBrainOnUnitSiloBuildEnd(self, unit, weapon)

        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnSiloBuildEnd(unit, weapon)
        end

        LOG("OnUnitSiloBuildEnd")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    ---@param order string
    OnUnitStartBuild = function(self, unit, target, order)
        StandardBrainOnUnitStartBuild(self, unit, target, order)

        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitStartBuild(unit, target)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStartBuild(unit, target, order)
        end

        LOG("OnUnitStartBuild")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    ---@param order string
    OnUnitStopBuild = function(self, unit, target, order)
        StandardBrainOnUnitStopBuild(self, unit, target, order)

        local nearestBase = self:FindNearestBase(unit:GetPosition())
        nearestBase:OnUnitStopBuild(unit, target)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStopBuild(unit, target)
        end

        LOG("OnUnitStopBuild")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    ---@param old number
    ---@param new number
    OnUnitBuildProgress = function(self, unit, target, old, new)
        StandardBrainOnUnitBuildProgress(self, unit, target, old, new)

        LOG("OnUnitBuildProgress")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitPaused = function(self, unit)
        StandardBrainOnUnitPaused(self, unit)

        LOG("OnUnitPaused")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitUnpaused = function(self, unit)
        StandardBrainOnUnitUnpaused(self, unit)

        LOG("OnUnitUnpaused")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param old number
    ---@param new number
    OnUnitBeingBuiltProgress = function(self, unit, builder, old, new)
        StandardBrainOnUnitBeingBuiltProgress(self, unit, builder, old, new)
        LOG(builder.Blueprint.BlueprintId)
        LOG(old)
        LOG(new)
        LOG("OnUnitBeingBuiltProgress")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitFailedToBeBuilt = function(self, unit)
        StandardBrainOnUnitFailedToBeBuilt(self, unit)

        LOG("OnUnitFailedToBeBuilt")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param attachBone Bone
    ---@param attachedUnit Unit
    OnUnitTransportAttach = function(self, unit, attachBone, attachedUnit)
        StandardBrainOnUnitTransportAttach(self, unit, attachBone, attachedUnit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnTransportAttach(unit, attachBone, attachedUnit)
        end

        LOG("OnUnitTransportAttach")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param attachBone Bone
    ---@param detachedUnit Unit
    OnUnitTransportDetach = function(self, unit, attachBone, detachedUnit)
        StandardBrainOnUnitTransportDetach(self, unit, attachBone, detachedUnit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnTransportDetach(unit, attachBone, detachedUnit)
        end

        LOG("OnUnitTransportDetach")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitTransportAborted = function(self, unit)
        StandardBrainOnUnitTransportAborted(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnTransportAborted(unit)
        end

        LOG("OnUnitTransportAborted")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitTransportOrdered = function(self, unit)
        StandardBrainOnUnitTransportOrdered(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnTransportOrdered(unit)
        end

        LOG("OnUnitTransportOrdered")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param attachedUnit Unit
    OnUnitAttachedKilled = function(self, unit, attachedUnit)
        StandardBrainOnUnitAttachedKilled(self, unit, attachedUnit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnAttachedKilled(unit)
        end

        LOG("OnUnitAttachedKilled")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitStartTransportLoading = function(self, unit)
        StandardBrainOnUnitStartTransportLoading(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStartTransportLoading(unit)
        end

        LOG("OnUnitStartTransportLoading")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitStopTransportLoading = function(self, unit)
        StandardBrainOnUnitStopTransportLoading(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnStopTransportLoading(unit)
        end

        LOG("OnUnitStopTransportLoading")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param transport Unit
    ---@param bone Bone
    OnUnitStartTransportBeamUp = function(self, unit, transport, bone)
        StandardBrainOnUnitStartTransportBeamUp(self, unit, transport, bone)

        LOG("OnUnitStartTransportBeamUp")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitStoptransportBeamUp = function(self, unit)
        StandardBrainOnUnitStoptransportBeamUp(self, unit)

        LOG("OnUnitStoptransportBeamUp")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param transport Unit
    ---@param bone Bone
    OnUnitAttachedToTransport = function(self, unit, transport, bone)
        StandardBrainOnUnitAttachedToTransport(self, unit, transport, bone)

        LOG("OnUnitAttachedToTransport")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param transport Unit
    ---@param bone Bone
    OnUnitDetachedFromTransport = function(self, unit, transport, bone)
        StandardBrainOnUnitDetachedFromTransport(self, unit, transport, bone)

        LOG("OnUnitDetachedFromTransport")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param carrier Unit
    OnUnitAddToStorage = function(self, unit, carrier)
        StandardBrainOnUnitAddToStorage(self, unit, carrier)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnAddToStorage(unit, carrier)
        end

        LOG("OnUnitAddToStorage")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param carrier Unit
    OnUnitRemoveFromStorage = function(self, unit, carrier)
        StandardBrainOnUnitRemoveFromStorage(self, unit, carrier)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnRemoveFromStorage(unit, carrier)
        end

        LOG("OnUnitRemoveFromStorage")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param teleporter any
    ---@param location Vector
    ---@param orientation Quaternion
    OnUnitTeleportUnit = function(self, unit, teleporter, location, orientation)
        StandardBrainOnUnitTeleportUnit(self, unit, teleporter, location, orientation)

        LOG("OnUnitTeleportUnit")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitFailedTeleport = function(self, unit)
        StandardBrainOnUnitFailedTeleport(self, unit)

        LOG("OnUnitFailedTeleport")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitShieldEnabled = function(self, unit)
        StandardBrainOnUnitShieldEnabled(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnShieldEnabled(unit)
        end

        LOG("OnUnitShieldEnabled")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitShieldDisabled = function(self, unit)
        StandardBrainOnUnitShieldDisabled(self, unit)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnShieldDisabled(unit)
        end

        LOG("OnUnitShieldDisabled")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitNukeArmed = function(self, unit)
        StandardBrainOnUnitNukeArmed(self, unit)

        LOG("OnUnitNukeArmed")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitNukeLaunched = function(self, unit)
        StandardBrainOnUnitNukeLaunched(self, unit)

        LOG("OnUnitNukeLaunched")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param work any
    OnUnitWorkBegin = function(self, unit, work)
        StandardBrainOnUnitWorkBegin(self, unit, work)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnWorkBegin(unit, work)
        end

        LOG("OnUnitWorkBegin")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param work any
    OnUnitWorkEnd = function(self, unit, work)
        StandardBrainOnUnitWorkEnd(self, unit, work)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnWorkEnd(unit, work)
        end

        LOG("OnUnitWorkEnd")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param work any
    OnUnitWorkFail = function(self, unit, work)
        StandardBrainOnUnitWorkFail(self, unit, work)

        LOG("OnUnitWorkFail")
    end,

    ---@param self EasyAIBrain
    ---@param target Vector
    ---@param shield Unit
    ---@param position Vector
    OnUnitMissileImpactShield = function(self, unit, target, shield, position)
        StandardBrainOnUnitMissileImpactShield(self, unit, target, shield, position)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnMissileImpactShield(unit, target, shield, position)
        end

        LOG("OnUnitMissileImpactShield")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Vector
    ---@param position Vector
    OnUnitMissileImpactTerrain = function(self, unit, target, position)
        StandardBrainOnUnitMissileImpactTerrain(self, unit, target, position)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnMissileImpactTerrain(unit, target, position)
        end

        LOG("OnUnitMissileImpactTerrain")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Vector
    ---@param defense Unit
    ---@param position Vector
    OnUnitMissileIntercepted = function(self, unit, target, defense, position)
        StandardBrainOnUnitMissileIntercepted(self, unit, target, defense, position)

        -- awareness of event for AI
        local aiPlatoon = unit.AIPlatoonReference
        if aiPlatoon then
            aiPlatoon:OnMissileIntercepted(unit, target, defense, position)
        end

        LOG("OnUnitMissileIntercepted")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStartSacrifice = function(self, unit, target)
        StandardBrainOnUnitStartSacrifice(self, unit, target)

        LOG("OnUnitStartSacrifice")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param target Unit
    OnUnitStopSacrifice = function(self, unit, target)
        StandardBrainOnUnitStopSacrifice(self, unit, target)

        LOG("OnUnitStopSacrifice")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitConsumptionActive = function(self, unit)
        StandardBrainOnUnitConsumptionActive(self, unit)

        LOG("OnUnitConsumptionActive")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitConsumptionInActive = function(self, unit)
        StandardBrainOnUnitConsumptionInActive(self, unit)

        LOG("OnUnitConsumptionInActive")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitProductionActive = function(self, unit)
        StandardBrainOnUnitProductionActive(self, unit)

        LOG("OnUnitProductionActive")
    end,

    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitProductionInActive = function(self, unit)
        StandardBrainOnUnitProductionInActive(self, unit)

        LOG("OnUnitProductionInActive")
    end,

    --#endregion
    ---------------------------------------------------------------------------

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
    ---@param self EasyAIBrain
    SetConstantEvaluate = function(self)
    end,

    ---@deprecated
    ---@param self EasyAIBrain
    InitializeSkirmishSystems = function(self)
    end,

    ---@deprecated
    ---@param self EasyAIBrain
    ForceManagerSort = function(self)
    end,

    ---@deprecated
    ---@param self EasyAIBrain
    InitializePlatoonBuildManager = function(self)
    end,

    --#endregion

}
