
-- load builder systems
doscript '/lua/aibrains/templates/base/base-template.lua'
doscript '/lua/aibrains/templates/builder-groups/builder-group-template.lua'
doscript '/lua/aibrains/templates/builders/builder-template.lua'

local StandardBrain = import("/lua/aibrain.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent
local BaseManager = import("/lua/aibrains/managers/base-manager.lua")

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
---@field BuilderManagers table<LocationType, AIBase>
AIBrain = Class(StandardBrain, EconomyComponent) {

    SkirmishSystems = true,

    --- Called after `SetupSession` but before `BeginSession` - no initial units, props or resources exist at this point and the teams are not yet defined
    ---@param self EasyAIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        StandardBrain.OnCreateAI(self, planName)
        EconomyComponent.OnCreateAI(self)

        self:OnLoadTemplates()


        -- start initial base
        local startX, startZ = self:GetArmyStartPos()
        local main = BaseManager.CreateBaseManager(self, 'main', { startX, 0, startZ }, 60)
        main:AddBaseTemplate(self.AIBaseTemplates.BaseTemplateMain)
        self.BuilderManagers = {
            MAIN = main
        }

        self:ForkThread(self.GetBaseDebugInfoThread)
        self:ForkThread(self.GetPlatoonDebugInfoThread)
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
    OnLoadTemplates = function(self)
        self.AIBaseTemplates = self.AIBaseTemplates or { }

        -- copy over templates from various files
        local templates
        templates = import("/lua/aibrains/templates/base/easy-main.lua")
        for k, template in templates do
            self.AIBaseTemplates[k] = template
        end
    end,

    ---@param self EasyAIBrain
    OnDestroy = function(self)
        StandardBrain.OnDestroy(self)

        if self.BuilderManagers then
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

    ---@param self EasyAIBrain
    ---@param blip Blip
    ---@param reconType ReconTypes
    ---@param val boolean
    OnIntelChange = function(self, blip, reconType, val)
        StandardBrain.OnIntelChange(self, blip, reconType, val)
        local position = blip:GetPosition()
        self.GridRecon:OnIntelChange(position[1], position[3], reconType, val)
    end,

    ---@param self EasyAIBrain
    ---@param position Vector
    ---@param radius number
    ---@param baseName LocationType
    AddBaseManagers = function(self, baseName, position, radius)
        self.BuilderManagers[baseName] = BaseManager.CreateBaseManager(self, baseName, position, radius)
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
    ---@return LocationType
    FindNearestBaseIdentifier = function(self, position)
        local ux, _, uz = position[1], nil, position[3]
        local nearestManagerIdentifier = nil
        local nearestDistance = nil
        for id, managers in self.BuilderManagers do
            if nearestManagerIdentifier then
                local location = managers.Position
                local dx, dz = location[1] - ux, location[3] - uz
                local distance = dx * dx + dz * dz
                if distance < nearestDistance then
                    nearestDistance = distance

                    nearestManagerIdentifier = id
                end
            else
                local location = managers.Position
                local dx, dz = location[1] - ux, location[3] - uz
                nearestDistance = dx * dx + dz * dz
                nearestManagerIdentifier = id
            end
        end

        return nearestManagerIdentifier
    end,

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
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        -- find nearest base
        local nearestBaseIdentifier = builder.AIBaseManager or self:FindNearestBaseIdentifier(unit:GetPosition())
        unit.AIBaseManager = nearestBaseIdentifier

        -- register unit at managers of base
        local baseManager = self.BuilderManagers[nearestBaseIdentifier]
        if baseManager then
            baseManager:OnUnitStartBeingBuilt(unit, builder, layer)
        end
    end,

    --- Called by a unit as it is finished being built
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        local baseIdentifier = unit.AIBaseManager
        if not baseIdentifier then
            baseIdentifier = self:FindNearestBaseIdentifier(unit:GetPosition())
            unit.AIBaseManager = baseIdentifier
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers:OnUnitStopBeingBuilt(unit, builder, layer)
        end
    end,

    --- Called by a unit as it is destroyed
    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local baseIdentifier = unit.AIBaseManager
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers:OnUnitDestroyed(unit)
        end
    end,

    --- Called by a unit as it starts building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        local baseIdentifier = unit.AIBaseManager
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers:OnUnitStartBuilding(unit, built)
        end
    end,

    --- Called by a unit as it stops building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        local baseIdentifier = unit.AIBaseManager
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers:OnUnitStopBuilding(unit, built)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self EasyAIBrain
    ---@return AIBaseDebugInfo
    GetBaseDebugInfoThread = function(self)
        while true do
            if GetFocusArmy() == self:GetArmyIndex() then
                local position = GetMouseWorldPos()
                local identifier = self:FindNearestBaseIdentifier(position)
                if identifier then
                    local base = self.BuilderManagers[identifier]
                    local info = base:GetDebugInfo()
                    Sync.AIBaseInfo = info
                end
            end

            WaitTicks(10)
        end
    end,

    ---@param self EasyAIBrain
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
