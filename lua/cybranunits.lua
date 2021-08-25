-----------------------------------------------------------------
-- File     :  /lua/cybranunits.lua
-- Author(s):
-- Summary  :
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DefaultUnitsFile = import('defaultunits.lua')
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

local Util = import('utilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('EffectUtilities.lua')
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

-- upvalued trashbag functions for performance
local TrashBag = _G.TrashBag
local TrashBagAdd = TrashBag.Add

--- A class to managing the build bots. Make sure to call all the relevant functions.
CConstructionTemplate = Class() {

    --- Prepares the values required to support bots
    OnCreate = function(self)
        -- cache the total amount of drones
        self.BuildBotTotal = self:GetBlueprint().BuildBotTotal or math.min(math.ceil((10 + builder:GetBuildRate()) / 15), 10)
    end,

    --- When dying, destroy everything.
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
    OnPaused = function(self, delay)
        -- delay until they move back
        delay = delay or 0.5 + 2 * Random()

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
    CreateBuildEffects = function(self, unitBeingBuilt, order, stationary)
        local builderArmy = self.Army
        local unitBeingBuiltArmy = unitBeingBuilt.Army
        if builderArmy == unitBeingBuiltArmy or ArmyBrains[builderArmy].BrainType == "Human" then
            SpawnBuildBotsOpti(self)
            if stationary then 
                CreateCybranEngineerBuildEffectsOpti(self, self.BuildEffectBones, self.BuildBots, self.BuildBotTotal, self.BuildEffectsBag)
            end
            CreateCybranBuildBeamsOpti(self, self.BuildBots, unitBeingBuilt, self.BuildEffectsBag, stationary)
        end
    end,

    --- When destroyed, destroy the bots too.
    OnDestroy = function(self) 
        -- destroy bots if we have them
        if self.BuildBotsNext > 1 then 

            -- doesn't need to trashbag: threads that are not infinite and stop get found by the garbage collector
            ForkThread(self.DestroyBotsThread, self, self.BuildBots, self.BuildBotTotal)
        end
    end,

    --- Destroys all the bots of a builder. Assumes the bots exist.
    -- @param self The builder in question.
    -- @param bots The bots of the builder.
    -- @param count The maximum number of bots.
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

    --- Destroys all the bots of a builder. Assumes the bots exist.
    -- @param self The builder in question.
    -- @param delay The delay until the bots decide to return.
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
CBuildBotUnit = Class(AirUnit) {

    -- Keep track of the builder that made the bot
    SpawnedBy = false,

    -- do not perform the logic of these functions                      
    OnMotionHorzEventChange = function(self, new, old) end,                     -- called a million times, keep it simple
    OnMotionVertEventChange = function(self, new, old) end,                 
    OnLayerChange = function(self, new, old) end,

    CreateBuildEffects = function(self, unitBeingBuilt, order) end,             -- do not make build effects (engineer / builder takes care of that)
    StartBuildingEffects = function(self, built, order) end,
    CreateBuildEffects = function(self, built, order) end,
    StopBuildingEffects = function(self, built) end,

    OnBuildProgress = function(self, unit, oldProg, newProg) end,               -- do not keep track of progress
    OnStopBuild = function(self, unitBeingBuilt) end,

    EnableUnitIntel = function(self, disabler, intel) end,                      -- do not bother doing intel
    DisableUnitIntel = function(self, disabler, intel) end,
    OnIntelEnabled = function(self) end,
    OnIntelDisabled = function(self) end,
    ShouldWatchIntel = function(self) end,
    IntelWatchThread = function(self) end,

    AddDetectedByHook = function(self, hook) end,                               -- do not bother keeping track of collision beams
    RemoveDetectedByHook = function(self, hook) end,
    OnDetectedBy = function(self, index) end,

    CreateWreckage = function (self, overkillRatio) end,                        -- don't make wreckage
    UpdateConsumptionValues = function(self) end,                               -- avoids junk in resource overlay
    ShouldUseVetSystem = function(self) return false end,                       -- never use vet
    OnStopBeingBuilt = function(self, builder, layer) end,                      -- do not perform this logic when being made
    OnStartRepair = function(self, unit) end,                                   -- do not run this logic
    OnKilled = function(self) end,                                              -- just fall out of the sky

    OnCollisionCheck = function(self, other, firingWeapon) return false end,    -- we never collide
    OnCollisionCheckWeapon = function(self, firingWeapon) return false end,

    OnPrepareArmToBuild = function(self) end,

    OnStartBuilderTracking = function(self) end,                                -- don't track anything
    OnStopBuilderTracking = function(self) end,

    DestroyUnit = function(self) end,                                           -- prevent misscalls
    DestroyAllTrashBags = function(self) end,

    OnStartSacrifice = function(self, target_unit) end,
    OnStopSacrifice = function(self, target_unit) end,

    -- only initialise what we need
    OnPreCreate = function(self) 
        self.Trash = TrashBag()
    end,             

    -- only initialise what we need
    OnCreate = function(self)
        -- prevent drone from consuming anything and remove collision shape
        UnitSetConsumptionActive(self, false)
    end,

    -- short-cut when being destroyed
    OnDestroy = function(self) 
        self.Dead = true 
        self.Trash:Destroy()
        self.SpawnedBy.BuildBotsNext = self.SpawnedBy.BuildBotsNext - 1
    end,

    Kill = function(self)
        -- make it go boom
        if self.PlayDestructionEffects then
            self:CreateDestructionEffects(1.0)
        end

        self:Destroy()
    end,

    -- prevent this type of operations
    OnStartCapture = function(self, target)
        IssueStop({self}) -- You can't capture!
    end,

    OnStartReclaim = function(self, target)
        IssueStop({self}) -- You can't reclaim!
    end,

    -- short cut - just get destroyed
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
CAirFactoryUnit = Class(AirFactoryUnit) {
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitTicks(2)
        EffectUtil.CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones, self.BuildEffectsBag)
    end,

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

    StopBuildFx = function(self)
        if self.BuildAnimManip then
            self.BuildAnimManip:SetRate(0)
        end
    end,

    OnPaused = function(self)
        AirFactoryUnit.OnPaused(self)
        self:StopBuildFx()
    end,

    OnUnpaused = function(self)
        AirFactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

-- AIR STAGING STRUCTURES
CAirStagingPlatformUnit = Class(AirStagingPlatformUnit) {}

-- AIR UNITS
CAirUnit = Class(AirUnit) {}

-- WALL STRUCTURES
CConcreteStructureUnit = Class(ConcreteStructureUnit) {}

-- CONSTRUCTION UNITS
CConstructionUnit = Class(ConstructionUnit, CConstructionTemplate){

    OnCreate = function(self)
        ConstructionUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        -- If created with F2 on land, then play the transform anim.
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    DestroyAllBuildEffects = function(self)
        ConstructionUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    StopBuildingEffects = function(self, built)
        ConstructionUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    OnPaused = function(self)
        ConstructionUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order)
    end,

    OnDestroy = function(self) 
        ConstructionUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    LayerChangeTrigger = function(self, new, old)
        if self:GetBlueprint().Display.AnimationWater then
            if self.TerrainLayerTransitionThread then
                self.TerrainLayerTransitionThread:Destroy()
                self.TerrainLayerTransitionThread = nil
            end
            if old ~= 'None' then
                self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, (new == 'Water'))
            end
        end
    end,

    TransformThread = function(self, water)
        if not self.TransformManipulator then
            self.TransformManipulator = CreateAnimator(self)
            self.Trash:Add(self.TransformManipulator)
        end

        if water then
            self.TransformManipulator:PlayAnim(self:GetBlueprint().Display.AnimationWater)
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
CEnergyCreationUnit = Class(DefaultUnitsFile.EnergyCreationUnit) {
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
CEnergyStorageUnit = Class(EnergyStorageUnit) {}

-- LAND FACTORY STRUCTURES
CLandFactoryUnit = Class(LandFactoryUnit) {
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitSeconds(0.1)
        EffectUtil.CreateCybranFactoryBuildEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones, self.BuildEffectsBag)
    end,

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

    StopBuildFx = function(self)
        if self.BuildAnimManip then
            self.BuildAnimManip:SetRate(0)
        end
    end,

    OnPaused = function(self)
        LandFactoryUnit.OnPaused(self)
        self:StopBuildFx(self:GetFocusUnit())
    end,

    OnUnpaused = function(self)
        LandFactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

-- LAND UNITS
CLandUnit = Class(DefaultUnitsFile.LandUnit) {}

-- MASS COLLECTION UNITS
CMassCollectionUnit = Class(DefaultUnitsFile.MassCollectionUnit) {}

--  MASS FABRICATION UNITS
CMassFabricationUnit = Class(DefaultUnitsFile.MassFabricationUnit) {}

--  MASS STORAGE UNITS
CMassStorageUnit = Class(DefaultUnitsFile.MassStorageUnit) {}

-- RADAR STRUCTURES
CRadarUnit = Class(DefaultUnitsFile.RadarUnit) {}

-- SONAR STRUCTURES
CSonarUnit = Class(DefaultUnitsFile.SonarUnit) {}

-- SEA FACTORY STRUCTURES
CSeaFactoryUnit = Class(SeaFactoryUnit) {

    StartBuildingEffects = function(self, unitBeingBuilt)
        local thread = self:ForkThread(EffectUtil.CreateCybranBuildBeams, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    OnPaused = function(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StopArmsMoving()
        end
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') and self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            self:StartBuildingEffects(self.UnitBeingBuilt)
            self:StartArmsMoving()
        end
        StructureUnit.OnUnpaused(self)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnit.OnStopBuild(self, unitBuilding)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    OnFailedToBuild = function(self)
        SeaFactoryUnit.OnFailedToBuild(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    StartArmsMoving = function(self)
        self.ArmsThread = self:ForkThread(self.MovingArmsThread)
    end,

    MovingArmsThread = function(self)
    end,

    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}

-- SEA UNITS
CSeaUnit = Class(SeaUnit) {}

-- SHIELD LAND UNITS
CShieldLandUnit = Class(ShieldLandUnit) {}

-- SHIELD STRUCTURES
CShieldStructureUnit = Class(ShieldStructureUnit) {}

-- STRUCTURES
CStructureUnit = Class(StructureUnit) {}

-- SUBMARINE UNITS
CSubUnit = Class(DefaultUnitsFile.SubUnit) {}

-- TRANSPORT BEACON UNITS
CTransportBeaconUnit = Class(DefaultUnitsFile.TransportBeaconUnit) {}

-- WALKING LAND UNITS
CWalkingLandUnit = DefaultUnitsFile.WalkingLandUnit

-- WALL STRUCTURES
CWallStructureUnit = Class(DefaultUnitsFile.WallStructureUnit) {}

-- CIVILIAN STRUCTURES
CCivilianStructureUnit = Class(CStructureUnit) {}

-- QUANTUM GATE UNITS
CQuantumGateUnit = Class(QuantumGateUnit) {}

-- RADAR JAMMER UNITS
CRadarJammerUnit = Class(RadarJammerUnit) {}

CConstructionEggUnit = Class(CStructureUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        LandFactoryUnit.OnStopBeingBuilt(self, builder, layer)
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

    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Spawn then overkillRatio = 1.1 end
        CStructureUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}


-- TODO: This should be made more general and put in defaultunits.lua in case other factions get similar buildings
-- CConstructionStructureUnit
CConstructionStructureUnit = Class(CStructureUnit, CConstructionTemplate) {
    OnCreate = function(self)

        -- Initialize the class
        CStructureUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)

        local bp = self:GetBlueprint()

        -- Construction stuff
        self.EffectsBag = {}
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

    DestroyAllBuildEffects = function(self)
        CStructureUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    StopBuildingEffects = function(self, built)
        CStructureUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    OnPaused = function(self)
        CStructureUnit.OnPaused(self)
        CStructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        CConstructionTemplate.OnPaused(self, 0)

        self.AnimationManipulator:SetRate(-0.25)
    end,

    OnUnpaused = function(self)
        CStructureUnit.OnUnpaused(self)
        CStructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)

        self.AnimationManipulator:SetRate(1)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder, true)
    end,

    OnDestroy = function(self) 
        CStructureUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        CStructureUnit.OnStartBuild(self, unitBeingBuilt, order)

        -- play animation of the hive opening
        self.AnimationManipulator:PlayAnim(self.BuildingOpenAnim, false):SetRate(1)

        -- keep track of who we are building
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)

        -- If created with F2 on land, then play the transform anim.
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    -- This will only be called if not in StructureUnit's upgrade state
    OnStopBuild = function(self, unitBeingBuilt)
        CStructureUnit.OnStopBuild(self, unitBeingBuilt)

        -- revert animation
        self.AnimationManipulator:SetRate(-0.25)

        -- lose track of who we are building
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnProductionPaused = function(self)
        if self:IsUnitState('Building') then
            self:SetMaintenanceConsumptionInactive()
        end
        self:SetProductionActive(false)
    end,

    OnProductionUnpaused = function(self)
        if self:IsUnitState('Building') then
            self:SetMaintenanceConsumptionActive()
        end
        self:SetProductionActive(true)
    end,

    OnStopBuilderTracking = function(self)
        CStructureUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self:GetBlueprint().Display.AnimationBuildRate or 1))
        end
    end,

    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,

    CreateReclaimEffects = function(self, target)
        EffectUtil.PlayReclaimEffects(self, target, self.BuildEffectBones or {0, }, self.ReclaimEffectsBag)
    end,

    CreateReclaimEndEffects = function(self, target)
        EffectUtil.PlayReclaimEndEffects(self, target)
    end,

    CreateCaptureEffects = function(self, target)
        EffectUtil.PlayCaptureEffects(self, target, self.BuildEffectBones or {0, }, self.CaptureEffectsBag)
    end,
}

-- CCommandUnit
-- Cybran Command Units (ACU and SCU) have stealth and cloak enhancements, toggles can be handled in one class
CCommandUnit = Class(CommandUnit, CConstructionTemplate) {

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)
    end,

    DestroyAllBuildEffects = function(self)
        CommandUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

    StopBuildingEffects = function(self, built)
        CommandUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    OnPaused = function(self)
        CommandUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order)
    end,

    OnDestroy = function(self) 
        CommandUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

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
