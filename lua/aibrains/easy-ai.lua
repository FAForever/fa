local FactoryManager = import("/lua/sim/factorybuildermanager.lua")
local PlatoonFormManager = import("/lua/sim/platoonformmanager.lua")
local BrainConditionsMonitor = import("/lua/sim/brainconditionsmonitor.lua")
local EngineerManager = import("/lua/aibrains/easy-ai-engineer-manager.lua")
local StructureManager = import("/lua/aibrains/easy-ai-structure-manager.lua")

-- upvalue for performance
local GetEconomyIncome = moho.aibrain_methods.GetEconomyIncome
local GetEconomyRequested = moho.aibrain_methods.GetEconomyRequested
local GetEconomyTrend = moho.aibrain_methods.GetEconomyTrend

local StandardBrain = import("/lua/aibrain.lua").AIBrain

---@class TriggerSpec
---@field Callback function
---@field ReconTypes ReconTypes
---@field Blip boolean
---@field Value boolean
---@field Category EntityCategory
---@field OnceOnly boolean
---@field TargetAIBrain AIBrain

---@class EasyAIBrain: AIBrain
AIBrain = Class(StandardBrain) {

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

        -- Economy monitor for new skirmish - stores out econ over time to get trend over 10 seconds
        self.EconomyData = {}
        self.EconomyOverTimeCurrent = {}
        self.EconomyTicksMonitor = 300
        self.EconomyMonitorThread = self:ForkThread(self.EconomyMonitor)
        self.LowEnergyMode = false

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
            function ()
                WaitTicks(30)
                local loader = import("/lua/ai/aiarchetype-managerloader.lua")
                loader.ExecutePlan(self)
            end
        )
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

    --- ## ECONOMY MONITOR
    --- Monitors the economy over time for skirmish; allows better trend analysis
    ---@param self EasyAIBrain
    EconomyMonitor = function(self)
        -- This over time thread is based on Sprouto's LOUD AI.
        self.EconomyData = { ['EnergyIncome'] = {}, ['EnergyRequested'] = {}, ['EnergyStorage'] = {},
            ['EnergyTrend'] = {}, ['MassIncome'] = {}, ['MassRequested'] = {}, ['MassStorage'] = {}, ['MassTrend'] = {},
            ['Period'] = self.EconomyTicksMonitor }
        -- number of sample points
        -- local point
        local samplerate = 10
        local samples = self.EconomyData['Period'] / samplerate

        -- create the table to store the samples
        for point = 1, samples do
            self.EconomyData['EnergyIncome'][point] = 0
            self.EconomyData['EnergyRequested'][point] = 0
            self.EconomyData['EnergyStorage'][point] = 0
            self.EconomyData['EnergyTrend'][point] = 0
            self.EconomyData['MassIncome'][point] = 0
            self.EconomyData['MassRequested'][point] = 0
            self.EconomyData['MassStorage'][point] = 0
            self.EconomyData['MassTrend'][point] = 0
        end

        -- array totals
        local eIncome = 0
        local mIncome = 0
        local eRequested = 0
        local mRequested = 0
        local eStorage = 0
        local mStorage = 0
        local eTrend = 0
        local mTrend = 0

        -- this will be used to multiply the totals
        -- to arrive at the averages
        local samplefactor = 1 / samples

        local EcoData = self.EconomyData

        local EcoDataEnergyIncome = EcoData['EnergyIncome']
        local EcoDataMassIncome = EcoData['MassIncome']
        local EcoDataEnergyRequested = EcoData['EnergyRequested']
        local EcoDataMassRequested = EcoData['MassRequested']
        local EcoDataEnergyTrend = EcoData['EnergyTrend']
        local EcoDataMassTrend = EcoData['MassTrend']
        local EcoDataEnergyStorage = EcoData['EnergyStorage']
        local EcoDataMassStorage = EcoData['MassStorage']

        local e, m

        while true do

            for point = 1, samples do

                -- remove this point from the totals
                eIncome = eIncome - EcoDataEnergyIncome[point]
                mIncome = mIncome - EcoDataMassIncome[point]
                eRequested = eRequested - EcoDataEnergyRequested[point]
                mRequested = mRequested - EcoDataMassRequested[point]
                eTrend = eTrend - EcoDataEnergyTrend[point]
                mTrend = mTrend - EcoDataMassTrend[point]

                -- insert the new data --
                EcoDataEnergyIncome[point] = GetEconomyIncome(self, 'ENERGY')
                EcoDataMassIncome[point] = GetEconomyIncome(self, 'MASS')
                EcoDataEnergyRequested[point] = GetEconomyRequested(self, 'ENERGY')
                EcoDataMassRequested[point] = GetEconomyRequested(self, 'MASS')

                e = GetEconomyTrend(self, 'ENERGY')
                m = GetEconomyTrend(self, 'MASS')

                if e then
                    EcoDataEnergyTrend[point] = e
                else
                    EcoDataEnergyTrend[point] = 0.1
                end

                if m then
                    EcoDataMassTrend[point] = m
                else
                    EcoDataMassTrend[point] = 0.1
                end

                -- add the new data to totals
                eIncome = eIncome + EcoDataEnergyIncome[point]
                mIncome = mIncome + EcoDataMassIncome[point]
                eRequested = eRequested + EcoDataEnergyRequested[point]
                mRequested = mRequested + EcoDataMassRequested[point]
                eTrend = eTrend + EcoDataEnergyTrend[point]
                mTrend = mTrend + EcoDataMassTrend[point]

                -- calculate new OverTime values --
                self.EconomyOverTimeCurrent.EnergyIncome = eIncome * samplefactor
                self.EconomyOverTimeCurrent.MassIncome = mIncome * samplefactor
                self.EconomyOverTimeCurrent.EnergyRequested = eRequested * samplefactor
                self.EconomyOverTimeCurrent.MassRequested = mRequested * samplefactor
                self.EconomyOverTimeCurrent.EnergyEfficiencyOverTime = math.min((eIncome * samplefactor) /
                    (eRequested * samplefactor), 2)
                self.EconomyOverTimeCurrent.MassEfficiencyOverTime = math.min((mIncome * samplefactor) /
                    (mRequested * samplefactor), 2)
                self.EconomyOverTimeCurrent.EnergyTrendOverTime = eTrend * samplefactor
                self.EconomyOverTimeCurrent.MassTrendOverTime = mTrend * samplefactor

                coroutine.yield(samplerate)
            end
        end
    end,

    ---@param self EasyAIBrain
    ---@return table
    GetEconomyOverTime = function(self)

        local retTable = {}
        retTable.EnergyIncome = self.EconomyOverTimeCurrent.EnergyIncome or 0
        retTable.MassIncome = self.EconomyOverTimeCurrent.MassIncome or 0
        retTable.EnergyRequested = self.EconomyOverTimeCurrent.EnergyRequested or 0
        retTable.MassRequested = self.EconomyOverTimeCurrent.MassRequested or 0

        return retTable
    end,

    ---@param self EasyAIBrain
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
