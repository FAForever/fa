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

local WaitTicks = coroutine.yield

CConstructionTemplate = Class() {

    --- Prepares the values required to support bots
    OnCreate = function(self)
        -- cache the total amount of drones
        self.BuildBotTotal = self:GetBlueprint().BuildBotTotal or  math.min(math.ceil((10 + builder:GetBuildRate()) / 15), 10)
    end,

    --- When dying, destroy everything.
    DestroyAllBuildEffects = function(self)
        -- make sure we're not dead (then bots are destroyed)
        if not self.Dead then 

            -- check if we ever had bots
            local bots = self.BuildBots 
            if bots then
                -- check if we still have active bots
                local buildBotCount = self.BuildBotsNext - 1
                if buildBotCount > 0 then 
                    -- return the active bots
                    self.ReturnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                    self.Trash:Add(self.ReturnBotsThreadInstance)
                end
            end
        end
    end,

    --- When stopping to build, send the bots back after a bit.
    StopBuildingEffects = function(self, built)
        -- make sure we're not dead (then bots are destroyed)
        if not self.Dead then 

            -- check if we had bots
            local bots = self.BuildBots 
            if bots then

                -- check if we still have active bots
                local buildBotCount = self.BuildBotsNext - 1
                if buildBotCount > 0 then 
                    -- return the active bots
                    self.ReturnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, 0.2)
                    self.Trash:Add(self.ReturnBotsThreadInstance)
                end
            end
        end
    end,

    --- When pausing, send the bots back after a bit.
    OnPaused = function(self, delay)
        -- delay until they move back
        delay = delay or 0.5 + 2 * Random()

        -- thread is not already running
        if not self.ReturnBotsThreadInstance then 
            -- check if we have bots
            local bots = self.BuildBots 
            if bots and self.BuildBotsNext > 1 then
                -- return the active bots
                self.ReturnBotsThreadInstance = ForkThread(self.ReturnBotsThread, self, delay)
                self.Trash:Add(self.ReturnBotsThreadInstance)
            end
        end
    end,

    --- When making build effects, try and make the bots.
    CreateBuildEffects = function(self, unitBeingBuilt, order, stationary)
        EffectUtil.CreateCybranEngineerBuildDrones(self)
        if stationary then 
            EffectUtil.CreateCybranBuildBotTrackers(self, self.BuildEffectBones, self.BuildBots, self.BuildBotTotal, self.BuildEffectsBag)
        end
        EffectUtil.CreateCybranEngineerBuildBeams(self, self.BuildBots, unitBeingBuilt, self.BuildEffectsBag, stationary)
    end,

    --- When destroyed, destroy the bots too.
    OnDestroy = function(self) 
        -- destroy bots if we have them
        if self.BuildBotsNext > 1 then 
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
                WaitTicks(Random(1, 10))
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
            IssueMove(bots, self:GetPosition())

            -- check if they're there yet
            for l = 1, 4 do 
                WaitSeconds(0.2)

                local tx, ty, tz = self:GetPositionXYZ()
                for k = 1, buildBotTotal do 
                    local bot = bots[k]
                    if bot and not bot.Dead then
                        local bx, by, bz = bot:GetPositionXYZ()
                        local distance = VDist2Sq(tx, tz, bx, bz)

                        -- if close enough, just remove it
                        threshold = threshold + 0.1
                        if distance < threshold then 
                            -- destroy bot
                            bot:Destroy()

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

-- AIR FACTORY STRUCTURES
CAirFactoryUnit = Class(AirFactoryUnit) {
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        if not unitBeingBuilt then return end
        WaitSeconds(0.1)
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
