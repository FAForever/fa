local BaseManager = import("/lua/aibrains/managers/base-manager.lua")

local StandardBrain = import("/lua/aibrain.lua").AIBrain
local EconomyComponent = import("/lua/aibrains/components/economy.lua").AIBrainEconomyComponent

-- TO GET RID OF
local BrainConditionsMonitor = import("/lua/sim/brainconditionsmonitor.lua")

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
---@field GridReclaim AIGridReclaim
---@field GridBrain AIGridBrain
---@field BuilderManagers table<LocationType, AIBase>
---@field BuilderManagers table<LocationType, AIBase>
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

        -- Condition monitor for the whole brain
        self.ConditionsMonitor = BrainConditionsMonitor.CreateConditionsMonitor(self)

        -- Set the map center point
        self.MapCenterPoint = { (ScenarioInfo.size[1] / 2),
            GetSurfaceHeight((ScenarioInfo.size[1] / 2), (ScenarioInfo.size[2] / 2)), (ScenarioInfo.size[2] / 2) }

        -- start initial base
        local startX, startZ = self:GetArmyStartPos()
        local main = BaseManager.CreateBaseManager(self, 'main', { startX, 0, startZ }, 60)
        self.BuilderManagers = {
            MAIN = main
        }

        ForkThread(
            function()
                WaitTicks(30)
                main:AddBaseTemplate('AIBaseTemplate - Easy main')
            end
        )

        self:IMAPConfiguration()
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

    ---------------------------------------------
    -- Unit events

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
