local FactoryManager = import("/lua/sim/factorybuildermanager.lua")
local PlatoonFormManager = import("/lua/sim/platoonformmanager.lua")
local BrainConditionsMonitor = import("/lua/sim/brainconditionsmonitor.lua")
local EngineerManager = import("/lua/aibrains/managers/engineer.lua")
local StructureManager = import("/lua/aibrains/managers/structure.lua")

local StandardBrain = import("/lua/aibrain.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

---@class EasyAIBrain: AIBrain, AIBrainEconomyComponent
AIBrain = Class(StandardBrain, EconomyComponent) {

    SkirmishSystems = true,

    ---@param self EasyAIBrain
    ---@param planName string
    OnCreateAI = function(self, planName)
        StandardBrain.OnCreateAI(self, planName)

        local civilian = false
        for name, data in ScenarioInfo.ArmySetup do
            if name == self.Name then
                civilian = data.Civilian
                break
            end
        end

        if civilian then
            return
        end

        self.GridReclaim = import("/lua/ai/gridreclaim.lua").Setup(self)
        self.GridBrain = import("/lua/ai/gridbrain.lua").Setup()

        -- TODO: do things with this mess below

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

        -- Add default main location and setup the builder managers
        self.NumBases = 0 -- AddBuilderManagers will increase the number

        -- Set the map center point
        self.MapCenterPoint = { (ScenarioInfo.size[1] / 2),
            GetSurfaceHeight((ScenarioInfo.size[1] / 2), (ScenarioInfo.size[2] / 2)), (ScenarioInfo.size[2] / 2) }

        LOG("Running!")

        local startX, startZ = self:GetArmyStartPos()
        self.BuilderManagers = {}
        self:AddBuilderManagers({ startX, 0, startZ }, 100, 'MAIN', false)
        self:IMAPConfiguration()

        ForkThread(
            function()
                WaitTicks(30)
                local loader = import("/lua/ai/aiarchetype-managerloader.lua")
                loader.ExecutePlan(self)
            end
        )

        EconomyComponent.OnCreateAI(self)
    end,

    ---@param self EasyAIBrain
    ---@param planName string
    CreateBrainShared = function(self, planName)
        StandardBrain.CreateBrainShared(self, planName)
    end,

    ---@param self EasyAIBrain
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

    ---@param self EasyAIBrain
    ---@param position Vector
    ---@param radius number
    ---@param baseName string
    ---@param useCenter boolean
    AddBuilderManagers = function(self, position, radius, baseName, useCenter)

        local baseLayer = 'Land'
        position[2] = GetTerrainHeight(position[1], position[3])
        if GetSurfaceHeight(position[1], position[3]) > position[2] then
            position[2] = GetSurfaceHeight(position[1], position[3])
            baseLayer = 'Water'
        end

        self.BuilderManagers[baseName] = {
            FactoryManager = FactoryManager.CreateFactoryBuilderManager(self, baseName, position, radius, useCenter),
            PlatoonFormManager = PlatoonFormManager.CreatePlatoonFormManager(self, baseName, position, radius, useCenter),
            EngineerManager = EngineerManager.CreateEngineerManager(self, baseName, position, radius),
            BuilderHandles = {},
            Position = position,
            BaseType = Scenario.MasterChain._MASTERCHAIN_.Markers[baseName].type or 'MAIN',
            Layer = baseLayer,
        }
        self.NumBases = self.NumBases + 1
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

    ---------------------------------------------
    -- Unit events

    --- Retrieves the nearest base for the given position
    ---@param self EasyAIBrain
    ---@param position Vector
    ---@return string?
    FindNearestBaseIdentifier = function(self, position)
        local ux, _, uz = position[1], nil, position[3]
        local nearestManagerIdentifier = nil
        local nearestDistance = nil
        for id, managers in self.BuilderManagers do
            if nearestManagerIdentifier then
                local location = managers.FactoryManager.Location
                local dx, dz = location[1] - ux, location[3] - uz
                local distance = dx * dx + dz * dz
                if distance < nearestDistance then
                    nearestDistance = distance

                    nearestManagerIdentifier = id
                end
            else
                local location = managers.FactoryManager.Location
                local dx, dz = location[1] - ux, location[3] - uz
                nearestDistance = dx * dx + dz * dz
                nearestManagerIdentifier = id
            end
        end

        return nearestManagerIdentifier
    end,

    --- Called by a unit as it starts being built
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        StandardBrain.OnUnitStartBeingBuilt(self, unit, builder, layer)

        -- find nearest base
        local nearestBaseIdentifier = builder.AIManagerIdentifier or self:FindNearestBaseIdentifier(unit:GetPosition())
        unit.AIManagerIdentifier = nearestBaseIdentifier

        -- register unit at managers of base
        local managers = self.BuilderManagers[nearestBaseIdentifier]
        if managers then
            managers.EngineerManager:OnUnitStartBeingBuilt(unit, builder, layer)
        end
    end,

    --- Called by a unit as it is finished being built
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        StandardBrain.OnUnitStopBeingBuilt(self, unit, builder, layer)

        local baseIdentifier = unit.AIManagerIdentifier
        if not baseIdentifier then
            baseIdentifier = self:FindNearestBaseIdentifier(unit:GetPosition())
            unit.AIManagerIdentifier = baseIdentifier
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers.EngineerManager:OnUnitStopBeingBuilt(unit, builder, layer)
        end
    end,

    --- Called by a unit as it is destroyed
    ---@param self EasyAIBrain
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        StandardBrain.OnUnitDestroyed(self, unit)

        local baseIdentifier = unit.AIManagerIdentifier
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers.EngineerManager:OnUnitStopBeingBuilt(unit)
        end
    end,

    --- Called by a unit as it starts building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        StandardBrain.OnUnitStartBuilding(self, unit, built)

        local baseIdentifier = unit.AIManagerIdentifier
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers.EngineerManager:OnUnitStartBuilding(unit)
        end
    end,

    --- Called by a unit as it stops building
    ---@param self EasyAIBrain
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        StandardBrain.OnUnitStopBuilding(self, unit, built)

        local baseIdentifier = unit.AIManagerIdentifier
        if not baseIdentifier then
            return
        end

        local managers = self.BuilderManagers[baseIdentifier]
        if managers then
            managers.EngineerManager:OnUnitStopBuilding(unit)
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
