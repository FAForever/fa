-----------------------------------------------------------------
-- File     :  /lua/cybranunits.lua
-- Author(s):
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DummyUnit = import("/lua/sim/unit.lua").DummyUnit
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local AirStagingPlatformUnit = DefaultUnitsFile.AirStagingPlatformUnit
local AirUnit = DefaultUnitsFile.AirUnit
local ConcreteStructureUnit = DefaultUnitsFile.ConcreteStructureUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyStorageUnit = DefaultUnitsFile.EnergyStorageUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local SeaUnit = DefaultUnitsFile.SeaUnit
local ShieldLandUnit = DefaultUnitsFile.ShieldLandUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local StructureUnit = DefaultUnitsFile.StructureUnit
local QuantumGateUnit = DefaultUnitsFile.QuantumGateUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local CommandUnit = DefaultUnitsFile.CommandUnit
local RadarUnit = DefaultUnitsFile.RadarUnit
local MassCollectionUnit = DefaultUnitsFile.MassCollectionUnit

local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CreateCybranBuildBeams = false

-- upvalued effect utility functions for performance
local SpawnBuildBotsOpti = EffectUtil.SpawnBuildBotsOpti
local CreateCybranEngineerBuildEffectsOpti = EffectUtil.CreateCybranEngineerBuildEffectsOpti
local CreateCybranBuildBeamsOpti = EffectUtil.CreateCybranBuildBeamsOpti

-- upvalued globals for performance
local Random = Random
local VDist2Sq = VDist2Sq
local ArmyBrains = ArmyBrains
local KillThread = KillThread
local ForkThread = ForkThread
local WaitTicks = coroutine.yield

local IssueMove = IssueMove
local IssueClearCommands = IssueClearCommands

-- upvalued moho functions for performance
local EntityFunctions = _G.moho.entity_methods 
local EntityDestroy = EntityFunctions.Destroy
local EntityGetPosition = EntityFunctions.GetPosition
local EntityGetPositionXYZ = EntityFunctions.GetPositionXYZ
EntityFunctions = nil

local UnitFunctions = _G.moho.unit_methods 
local UnitSetConsumptionActive = UnitFunctions.SetConsumptionActive
UnitFunctions = nil 

-- upvalied math functions for performance
MathMax = math.max

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

--- A class to managing the build bots. Make sure to call all the relevant functions.
---@class CConstructionTemplate
---@field BotBlueprintId? string
CConstructionTemplate = ClassSimple {

    BotBlueprintId = false,
    BotBone = 0,

    --- Prepares the values required to support bots
    ---@param self CConstructionTemplate
    OnCreate = function(self)
        -- cache the total amount of drones
        self.BuildBotTotal = self:GetBlueprint().BuildBotTotal or math.min(math.ceil((10 + self:GetBuildRate()) / 15), 10)
    end,

    --- When dying, destroy everything.
    ---@param self CConstructionTemplate
    DestroyAllBuildEffects = function(self)
        -- make sure we're not dead (then bots are destroyed by trashbag)
        if self.Dead then 
            return 
        end

        -- check if we ever had bots
        local bots = self.BuildBots 
        if bots then
            -- check if we still have active bots
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then 
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When stopping to build, send the bots back after a bit.
    ---@param self CConstructionTemplate
    ---@param built Unit
    StopBuildingEffects = function(self, built)
        -- make sure we're not dead (then bots are destroyed by trashbag)
        if self.Dead then 
            return 
        end

        -- check if we had bots
        local bots = self.BuildBots 
        if bots then

            -- check if we still have active bots
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then 
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When pausing, send the bots back after a bit.
    ---@param self CConstructionTemplate
    ---@param delay? number
    OnPaused = function(self, delay)
        -- delay until they move back
        delay = delay or (0.5 + 2) * Random()

        -- make sure thread is not running already
        if self.ReturnBotsThreadInstance then 
            return 
        end

        -- check if we have bots
        local bots = self.BuildBots 
        if bots then
            local buildBotCount = self.BuildBotsNext - 1
            if buildBotCount > 0 then
                -- return the active bots
                local returnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                TrashBagAdd(self.Trash, returnBotsThreadInstance)

                -- save thread so that we can kill it if the bots suddenly get an additional task.
                self.ReturnBotsThreadInstance = returnBotsThreadInstance
            end
        end
    end,

    --- When making build effects, try and make the bots.
    ---@param self CConstructionTemplate
    ---@param unitBeingBuilt Unit
    ---@param order number
    ---@param stationary boolean
    CreateBuildEffects = function(self, unitBeingBuilt, order, stationary)
        -- check if the unit still exists, this can happen when: 
        -- pause during construction, constructing unit dies, unpause
        if unitBeingBuilt then 

            -- Prevent an AI from (ab)using the bots for other purposes than building
            local builderArmy = self.Army
            local unitBeingBuiltArmy = unitBeingBuilt.Army
            if builderArmy == unitBeingBuiltArmy or ArmyBrains[builderArmy].BrainType == "Human" then
                SpawnBuildBotsOpti(self, self.BotBlueprintId, self.BotBone)
                if stationary then 
                    CreateCybranEngineerBuildEffectsOpti(self, self.BuildEffectBones, self.BuildBots, self.BuildBotTotal, self.BuildEffectsBag)
                end
                CreateCybranBuildBeamsOpti(self, self.BuildBots, unitBeingBuilt, self.BuildEffectsBag, stationary)
            end
        end
    end,

    --- When destroyed, destroy the bots too.
    ---@param self CConstructionTemplate
    OnDestroy = function(self) 
        -- destroy bots if we have them
        if self.BuildBotsNext > 1 then 

            -- doesn't need to trashbag: threads that are not infinite and stop get found by the garbage collector
            ForkThread(self.DestroyBotsThread, self, self.BuildBots, self.BuildBotTotal)
        end
    end,

    --- Destroys all the bots of a builder. Assumes the bots exist
    ---@param self CConstructionTemplate
    ---@param bots Unit[]
    ---@param count number
    DestroyBotsThread = function(self, bots, count)

        -- kill potential return thread
        if self.ReturnBotsThreadInstance then 
            KillThread(self.ReturnBotsThreadInstance)
            self.ReturnBotsThreadInstance = nil
        end

        -- slowly kill the drones
        for k = 1, count do 
            local bot = bots[k]
            if bot and not bot.Dead then
                WaitTicks(Random(1, 10) + 1)
                if bot and not bot.Dead then
                    bot:Kill()
                end
            end
        end
    end,

    --- Destroys all the bots of a builder. Assumes the bots exist
    ---@param self CConstructionTemplate
    ---@param delay number
    ReturnBotsThread = function(self, delay)

        -- hold up a bit in case we just switch target
        WaitSeconds(delay)

        -- cache for speed
        local bots = self.BuildBots 
        local buildBotTotal = self.BuildBotTotal
        local threshold = delay

        -- lower bot elevation
        for k = 1, buildBotTotal do 
            local bot = bots[k]
            if bot and not bot.Dead then
                bot:SetElevation(1)
            end
        end

        -- keep sending drones back
        while self.BuildBotsNext > 1 do 

            -- instruct bots to move back
            IssueClearCommands(bots)
            IssueMove(bots, EntityGetPosition(self))

            -- check if they're there yet
            for l = 1, 4 do 
                WaitTicks(3)

                local tx, ty, tz = EntityGetPositionXYZ(self)
                for k = 1, buildBotTotal do 
                    local bot = bots[k]
                    if bot and not bot.Dead then
                        local bx, by, bz = EntityGetPositionXYZ(bot)
                        local distance = VDist2Sq(tx, tz, bx, bz)

                        -- if close enough, just remove it
                        threshold = threshold + 0.1
                        if distance < threshold then 
                            -- destroy bot without effects
                            EntityDestroy(bot)

                            -- move destroyed bots up
                            for m = k, buildBotTotal do 
                                bots[m] = bots[m + 1]
                            end
                        end
                    end
                end
            end
        end

        -- clean up state
        self.ReturnBotsThreadInstance = nil
        self.BeamEndBuilder = nil 
        self.BeamEndBots = nil
    end,
}

--- The build bot class for drones. It removes a lot of
-- the basic functionality of a unit to save on performance.
---@class CBuildBotUnit : DummyUnit
CBuildBotUnit = ClassDummyUnit(DummyUnit) {

    -- Keep track of the builder that made the bot
    SpawnedBy = false,

    --- only initialise what we need (drones typically have some aim functionality)
    ---@param self CBuildBotUnit
    OnPreCreate = function(self) 
        self.Trash = TrashBag()
    end,         

    --- only initialise what we need
    ---@param self CBuildBotUnit
    OnCreate = function(self)
        DummyUnit.OnCreate(self)

        -- prevent drone from consuming anything
        UnitSetConsumptionActive(self, false)
    end,

    --- short-cut when being destroyed
    ---@param self CBuildBotUnit
    OnDestroy = function(self) 
        self.Dead = true
        self.Trash:Destroy()

        if self.SpawnedBy then 
            self.SpawnedBy.BuildBotsNext = self.SpawnedBy.BuildBotsNext - 1
        end
    end,

    ---@param self CBuildBotUnit
    Kill = function(self)
        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        self:Destroy()
    end,

    --- prevent this type of operations
    ---@param self CBuildBotUnit
    ---@param target Unit
    OnStartCapture = function(self, target)
        IssueStop({self}) -- You can't capture!
    end,
    
    ---@param self CBuildBotUnit
    ---@param target Unit
    OnStartReclaim = function(self, target)
        IssueStop({self}) -- You can't reclaim!
    end,

    --- short cut - just get destroyed
    ---@param self CBuildBotUnit
    ---@param with any
    OnImpact = function(self, with)

        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        -- make it sound boom
        self:PlayUnitSound('Destroyed')

        -- make it gone
        self:Destroy()
    end,
}

-- AIR FACTORY STRUCTURES
---@class CAirFactoryUnit : AirFactoryUnit
CAirFactoryUnit = ClassUnit(AirFactoryUnit) {

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitTicks(2)
        EffectUtil.CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones, self.BuildEffectsBag)
    end,

    ---@param self CAirFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then return end

        -- Start build process
        if not self.BuildAnimManip then
            self.BuildAnimManip = CreateAnimator(self)
            self.BuildAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationBuild, true):SetRate(0)
            self.Trash:Add(self.BuildAnimManip)
        end
        self.BuildAnimManip:SetRate(1)
    end,

    ---@param self CAirFactoryUnit
    StopBuildFx = function(self)
        if self.BuildAnimManip then
            self.BuildAnimManip:SetRate(0)
        end
    end,

    ---@param self CAirFactoryUnit
    OnPaused = function(self)
        AirFactoryUnit.OnPaused(self)
        self:StopBuildFx()
    end,

    ---@param self CAirFactoryUnit
    OnUnpaused = function(self)
        AirFactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

-- AIR STAGING STRUCTURES
---@class CAirStagingPlatformUnit : AirStagingPlatformUnit
CAirStagingPlatformUnit = ClassUnit(AirStagingPlatformUnit) {}

-- AIR UNITS
---@class CAirUnit : AirUnit
CAirUnit = ClassUnit(AirUnit) {}

-- WALL STRUCTURES
---@class CConcreteStructureUnit : ConcreteStructureUnit
CConcreteStructureUnit = ClassUnit(ConcreteStructureUnit) {}

-- CONSTRUCTION UNITS
---@class CConstructionUnit : ConstructionUnit, CConstructionTemplate
CConstructionUnit = ClassUnit(ConstructionUnit, CConstructionTemplate){

    ---@param self CConstructionUnit
    OnCreate = function(self)
        ConstructionUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)
    end,

    ---@param self CConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    ---@param self CConstructionUnit
    DestroyAllBuildEffects = function(self)
        ConstructionUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    ---@param self CConstructionUnit
    ---@param built boolean
    StopBuildingEffects = function(self, built)
        ConstructionUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    ---@param self CConstructionUnit
    OnPaused = function(self)
        ConstructionUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    ---@param self CConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order)
    end,

    ---@param self CConstructionUnit
    OnDestroy = function(self) 
        ConstructionUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    ---@param self CConstructionUnit
    ---@param new Layer
    ---@param old Layer
    LayerChangeTrigger = function(self, new, old)
        if self.Blueprint.Display.AnimationWater then
            if self.TerrainLayerTransitionThread then
                self.TerrainLayerTransitionThread:Destroy()
                self.TerrainLayerTransitionThread = nil
            end
            if old ~= 'None' then
                self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, (new == 'Water'))
            end
        end
    end,

    ---@param self CConstructionUnit
    ---@param water boolean
    TransformThread = function(self, water)
        if not self.TransformManipulator then
            self.TransformManipulator = CreateAnimator(self)
            self.Trash:Add(self.TransformManipulator)
        end

        if water then
            self.TransformManipulator:PlayAnim(self.Blueprint.Display.AnimationWater)
            self.TransformManipulator:SetRate(1)
            self.TransformManipulator:SetPrecedence(0)
        else
            self.TransformManipulator:SetRate(-1)
            self.TransformManipulator:SetPrecedence(0)
            WaitFor(self.TransformManipulator)
            self.TransformManipulator:Destroy()
            self.TransformManipulator = nil
        end
    end,
}

-- ENERGY CREATION UNITS
---@class CEnergyCreationUnit : EnergyCreationUnit
CEnergyCreationUnit = ClassUnit(DefaultUnitsFile.EnergyCreationUnit) {

    ---@param self CEnergyCreationUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        DefaultUnitsFile.EnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        if self.AmbientEffects then
            for k, v in EffectTemplate[self.AmbientEffects] do
                CreateAttachedEmitter(self, 0, self.Army, v)
            end
        end
    end,
}

-- ENERGY STORAGE STRUCTURES
---@class CEnergyStorageUnit : EnergyStorageUnit
CEnergyStorageUnit = ClassUnit(EnergyStorageUnit) {}

-- LAND FACTORY STRUCTURES
---@class CLandFactoryUnit : LandFactoryUnit
CLandFactoryUnit = ClassUnit(LandFactoryUnit) {

    ---@param self CLandFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitSeconds(0.1)
        EffectUtil.CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones, self.BuildEffectsBag)
    end,

    ---@param self CLandFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        if not unitBeingBuilt then
            unitBeingBuilt = self:GetFocusUnit()
        end

        -- Start build process
        if not self.BuildAnimManip then
            self.BuildAnimManip = CreateAnimator(self)
            self.BuildAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationBuild, true):SetRate(0)
            self.Trash:Add(self.BuildAnimManip)
        end

        self.BuildAnimManip:SetRate(1)
    end,

    ---@param self CLandFactoryUnit
    StopBuildFx = function(self)
        if self.BuildAnimManip then
            self.BuildAnimManip:SetRate(0)
        end
    end,

    ---@param self CLandFactoryUnit
    OnPaused = function(self)
        LandFactoryUnit.OnPaused(self)
        self:StopBuildFx(self:GetFocusUnit())
    end,

    ---@param self CLandFactoryUnit
    OnUnpaused = function(self)
        LandFactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

-- LAND UNITS
---@class CLandUnit : LandUnit
CLandUnit = ClassUnit(DefaultUnitsFile.LandUnit) {}

-- MASS COLLECTION UNITS
---@class CMassCollectionUnit : MassCollectionUnit
---@field AnimationManipulator moho.AnimationManipulator
CMassCollectionUnit = ClassUnit(MassCollectionUnit) {

    OnStartBuild = function(self, unitBeingBuilt, order)
        MassCollectionUnit.OnStartBuild(self, unitBeingBuilt, order)
        if not self.AnimationManipulator then return end
        self.AnimationManipulator:SetRate(0)
        self.AnimationManipulator:Destroy()
        self.AnimationManipulator = nil
    end,

    ---@param self CMassCollectionUnit
    PlayActiveAnimation = function(self)
        MassCollectionUnit.PlayActiveAnimation(self)

        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then
            animationManipulator = CreateAnimator(self)
            self.Trash:Add(animationManipulator)
            self.AnimationManipulator = animationManipulator
        end

        animationManipulator:PlayAnim(self.Blueprint.Display.AnimationOpen, true)
    end,

    ---@param self CMassCollectionUnit
    OnProductionPaused = function(self)
        MassCollectionUnit.OnProductionPaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(0)
    end,

    ---@param self CMassCollectionUnit
    OnProductionUnpaused = function(self)
        MassCollectionUnit.OnProductionUnpaused(self)
        local animationManipulator = self.AnimationManipulator
        if not animationManipulator then return end
        animationManipulator:SetRate(1)
    end,

}

--  MASS FABRICATION UNITS
---@class CMassFabricationUnit : MassFabricationUnit
CMassFabricationUnit = ClassUnit(DefaultUnitsFile.MassFabricationUnit) {}

--  MASS STORAGE UNITS
---@class CMassStorageUnit : MassStorageUnit
CMassStorageUnit = ClassUnit(DefaultUnitsFile.MassStorageUnit) {}

-- RADAR STRUCTURES

---@class CRadarUnit : RadarUnit
---@field Thread1 thread
---@field Thread2 thread
---@field Thread3 thread
---@field Dish1Rotator moho.RotateManipulator
---@field Dish2Rotator moho.RotateManipulator
---@field Dish3Rotator moho.RotateManipulator
CRadarUnit = ClassUnit(RadarUnit) {

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        RadarUnit.OnIntelDisabled(self, intel)

        local rotator, thread

        thread = self.Thread1
        if (thread) then
            KillThread(thread)
            self.Thread1 = nil

        end

        rotator = self.Dish1Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end

        thread = self.Thread2
        if (thread) then
            KillThread(thread)
            self.Thread2 = nil
        end

        rotator = self.Dish2Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end

        thread = self.Thread3
        if (thread) then
            KillThread(thread)
            self.Thread3 = nil
        end

        rotator = self.Dish3Rotator
        if rotator then
            rotator:SetTargetSpeed(0)
        end
    end,

    ---@param self CRadarUnit
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        RadarUnit.OnIntelEnabled(self, intel)

        local thread
        local trash = self.Trash

        thread = self.Thread1
        if not thread then
            thread = ForkThread(self.Dish1Behavior, self)
            self.Thread1 = thread
            trash:Add(thread)
        end

        thread = self.Thread2 
        if not thread then
            thread = ForkThread(self.Dish2Behavior, self)
            self.Thread2 = thread
            trash:Add(thread)
        end

        thread = self.Thread3
        if not thread then
            thread = ForkThread(self.Dish3Behavior, self)
            self.Thread3 = thread
            trash:Add(thread)
        end
    end,

    ---@param self CRadarUnit
    Dish1Behavior = function(self)
        local rotator = self.Dish1Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish01', 'x')
            self.Dish1Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.5) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.5) then
                WaitTicks(11)
            end
        end
    end,

    ---@param self CRadarUnit
    Dish2Behavior = function(self)
        local rotator = self.Dish2Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish02', 'x')
            self.Dish2Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        WaitTicks(21)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.4) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.4) then
                WaitTicks(11)
            end
        end
    end,

    ---@param self CRadarUnit
    Dish3Behavior = function(self)
        local rotator = self.Dish3Rotator
        if not rotator then
            rotator = CreateRotator(self, 'Dish03', 'x')
            self.Dish3Rotator = rotator
            self.Trash:Add(rotator)
        end

        -- local scope for performance
        local WaitFor = WaitFor
        local WaitTicks = WaitTicks
        local Random = Random

        rotator:SetSpeed(5):SetGoal(0)
        WaitFor(rotator)
        WaitTicks(51)
        rotator:SetSpeed(0)
        rotator:ClearGoal()
        rotator:SetAccel(5)

        while true do
            rotator:SetTargetSpeed(-15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.6) then
                WaitTicks(11)
            end

            rotator:SetTargetSpeed(15)
            WaitFor(rotator)
            rotator:SetTargetSpeed(0)
            WaitFor(rotator)

            if (Random() < 0.6) then
                WaitTicks(11)
            end
        end
    end,


}

-- SONAR STRUCTURES
---@class CSonarUnit : SonarUnit
CSonarUnit = ClassUnit(DefaultUnitsFile.SonarUnit) {}

-- SEA FACTORY STRUCTURES
---@class CSeaFactoryUnit : SeaFactoryUnit
CSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self CSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildingEffects = function(self, unitBeingBuilt)
        local thread = self:ForkThread(EffectUtil.CreateCybranBuildBeamsOpti, nil, unitBeingBuilt, self.BuildEffectsBag, false)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self CSeaFactoryUnit
    OnPaused = function(self)
        StructureUnit.OnPaused(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') and self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            self:StartBuildingEffects(self.UnitBeingBuilt)
            self:StartArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    ---@param unitBuilding boolean
    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnit.OnStopBuild(self, unitBuilding)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnit.OnFailedToBuild(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    ---@param self CSeaFactoryUnit
    StartArmsMoving = function(self)
        self.ArmsThread = self:ForkThread(self.MovingArmsThread)
    end,

    ---@param self CSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self CSeaFactoryUnit
    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}

-- SEA UNITS
---@class CSeaUnit : SeaUnit
CSeaUnit = ClassUnit(SeaUnit) {}

-- SHIELD LAND UNITS
---@class CShieldLandUnit : ShieldLandUnit
CShieldLandUnit = ClassUnit(ShieldLandUnit) {}

-- SHIELD STRUCTURES
---@class CShieldStructureUnit : ShieldStructureUnit
CShieldStructureUnit = ClassUnit(ShieldStructureUnit) {}

-- STRUCTURES
---@class CStructureUnit : StructureUnit
CStructureUnit = ClassUnit(StructureUnit) {}

-- SUBMARINE UNITS
---@class CSubUnit : SubUnit
CSubUnit = ClassUnit(DefaultUnitsFile.SubUnit) {}

-- TRANSPORT BEACON UNITS
---@class CTransportBeaconUnit : TransportBeaconUnit
CTransportBeaconUnit = ClassUnit(DefaultUnitsFile.TransportBeaconUnit) {}

-- WALKING LAND UNITS
---@class CWalkingLandUnit : WalkingLandUnit
CWalkingLandUnit = DefaultUnitsFile.WalkingLandUnit

-- WALL STRUCTURES
---@class CWallStructureUnit : WallStructureUnit
CWallStructureUnit = ClassUnit(DefaultUnitsFile.WallStructureUnit) {}

-- CIVILIAN STRUCTURES
---@class CCivilianStructureUnit : CStructureUnit
CCivilianStructureUnit = ClassUnit(CStructureUnit) {}

-- QUANTUM GATE UNITS
---@class CQuantumGateUnit : QuantumGateUnit
CQuantumGateUnit = ClassUnit(QuantumGateUnit) {}

-- RADAR JAMMER UNITS
---@class CRadarJammerUnit : RadarJammerUnit
CRadarJammerUnit = ClassUnit(RadarJammerUnit) {}

---@class CConstructionEggUnit : CStructureUnit
CConstructionEggUnit = ClassUnit(CStructureUnit) {

    ---@param self CConstructionEggUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        LandFactoryUnit.OnStopBeingBuilt(self, builder, layer)

        -- prevent the unit from being reclaimed
        self:SetReclaimable(false)

        local bp = self:GetBlueprint()
        local buildUnit = bp.Economy.BuildUnit
        local pos = self:GetPosition()
        local aiBrain = self:GetAIBrain()


        self.Spawn = CreateUnitHPR(
            buildUnit,
            aiBrain.Name,
            pos[1], pos[2], pos[3],
            0, 0, 0
        )

        self:ForkThread(function()
                self.OpenAnimManip = CreateAnimator(self)
                self.Trash:Add(self.OpenAnimManip)
                self.OpenAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationOpen, false):SetRate(0.1)
                self:PlaySound(bp.Audio['EggOpen'])

                WaitFor(self.OpenAnimManip)

                self.EggSlider = CreateSlider(self, 0, 0, -20, 0, 5)
                self.Trash:Add(self.EggSlider)
                self:PlaySound(bp.Audio['EggSink'])

                WaitFor(self.EggSlider)

                self:Destroy()
            end
        )
    end,

    ---@param self CConstructionEggUnit
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Spawn then overkillRatio = 1.1 end
        CStructureUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}

-- TODO: This should be made more general and put in defaultunits.lua in case other factions get similar buildings
-- CConstructionStructureUnit
---@class CConstructionStructureUnit : CStructureUnit, CConstructionTemplate
CConstructionStructureUnit = ClassUnit(CStructureUnit, CConstructionTemplate) {

    ---@param self CConstructionStructureUnit
    OnCreate = function(self)

        -- Initialize the class
        CStructureUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)

        local bp = self:GetBlueprint()

        -- Construction stuff
        if bp.General.BuildBones then
            self:SetupBuildBones()
        end

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = bp.General.BuildBones.BuildEffectBones

        -- Set up building animation
        if bp.Display.AnimationOpen then
            self.BuildingOpenAnim = bp.Display.AnimationOpen
        end

        self.AnimationManipulator = CreateAnimator(self)
        self.Trash:Add(self.AnimationManipulator)

        self.BuildingUnit = false
    end,

    ---@param self CConstructionStructureUnit
    DestroyAllBuildEffects = function(self)
        CStructureUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    ---@param self CConstructionStructureUnit
    ---@param built boolean
    StopBuildingEffects = function(self, built)
        CStructureUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    ---@param self CConstructionStructureUnit
    OnPaused = function(self)
        CStructureUnit.OnPaused(self)
        CStructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        CConstructionTemplate.OnPaused(self, 0)

        self.AnimationManipulator:SetRate(-0.25)
    end,

    ---@param self CConstructionStructureUnit
    OnUnpaused = function(self)
        CStructureUnit.OnUnpaused(self)

        -- make sure the unit is still there
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt then 
            CStructureUnit.StartBuildingEffects(self, unitBeingBuilt, self.UnitBuildOrder)
            self.AnimationManipulator:SetRate(1)
        end
    end,

    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder, true)
    end,

    ---@param self CConstructionStructureUnit
    OnDestroy = function(self) 
        CStructureUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        CStructureUnit.OnStartBuild(self, unitBeingBuilt, order)

        -- play animation of the hive opening
        self.AnimationManipulator:PlayAnim(self.BuildingOpenAnim, false):SetRate(1)

        -- keep track of who we are building
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
    end,

    ---@param self CConstructionStructureUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)

        -- If created with F2 on land, then play the transform anim.
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    --- This will only be called if not in StructureUnit's upgrade state
    ---@param self CConstructionStructureUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        CStructureUnit.OnStopBuild(self, unitBeingBuilt)

        -- revert animation
        self.AnimationManipulator:SetRate(-0.25)

        -- lose track of who we are building
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    ---@param self CConstructionStructureUnit
    OnProductionPaused = function(self)
        if self:IsUnitState('Building') then
            self:SetMaintenanceConsumptionInactive()
        end
        self:SetProductionActive(false)
    end,

    ---@param self CConstructionStructureUnit
    OnProductionUnpaused = function(self)
        if self:IsUnitState('Building') then
            self:SetMaintenanceConsumptionActive()
        end
        self:SetProductionActive(true)
    end,

    ---@param self CConstructionStructureUnit
    OnStopBuilderTracking = function(self)
        CStructureUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self:GetBlueprint().Display.AnimationBuildRate or 1))
        end
    end,

    ---@param self CConstructionStructureUnit
    ---@param target_bp UnitBlueprint
    ---@return boolean
    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,
}

---# CCommandUnit
---Cybran Command Units (ACU and SCU) have stealth and cloak enhancements, toggles can be handled in one class
---@class CCommandUnit : CommandUnit
CCommandUnit = ClassUnit(CommandUnit, CConstructionTemplate) {

    ---@param self CCommandUnit
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)
    end,

    ---@param self CCommandUnit
    DestroyAllBuildEffects = function(self)
        CommandUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    ---@param self CCommandUnit
    ---@param built boolean
    StopBuildingEffects = function(self, built)
        CommandUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    ---@param self CCommandUnit
    OnPaused = function(self)
        CommandUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    ---@param self CCommandUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order)
    end,

    ---@param self CCommandUnit
    OnDestroy = function(self) 
        CommandUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    ---@param self CCommandUnit
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        if bit == 8 then -- Cloak toggle
            self:StopUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionInactive()
            self:DisableUnitIntel('ToggleBit8', 'Cloak')
            self:DisableUnitIntel('ToggleBit8', 'RadarStealth')
            self:DisableUnitIntel('ToggleBit8', 'RadarStealthField')
            self:DisableUnitIntel('ToggleBit8', 'SonarStealth')
            self:DisableUnitIntel('ToggleBit8', 'SonarStealthField')
        end
    end,

    ---@param self CCommandUnit
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        if bit == 8 then -- Cloak toggle
            self:PlayUnitAmbientSound('ActiveLoop')
            self:SetMaintenanceConsumptionActive()
            self:EnableUnitIntel('ToggleBit8', 'Cloak')
            self:EnableUnitIntel('ToggleBit8', 'RadarStealth')
            self:EnableUnitIntel('ToggleBit8', 'RadarStealthField')
            self:EnableUnitIntel('ToggleBit8', 'SonarStealth')
            self:EnableUnitIntel('ToggleBit8', 'SonarStealthField')
        end
    end,
}

-- kept for mod backwards compatibility
local Util = import("/lua/utilities.lua")
