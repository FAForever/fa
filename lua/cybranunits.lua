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
local AmphibiousStructureUnit = DefaultUnitsFile.AmphibiousStructureUnit

local Util = import('utilities.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('EffectUtilities.lua')
local CreateCybranBuildBeams = EffectUtil.CreateCybranBuildBeams

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
CConstructionUnit = Class(ConstructionUnit){
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        -- If created with F2 on land, then play the transform anim.
        if self:GetCurrentLayer() == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
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

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        local buildbots = EffectUtil.SpawnBuildBots(self, unitBeingBuilt, self.BuildEffectsBag)
        EffectUtil.CreateCybranBuildBeams(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag)
    end,
}

-- ENERGY CREATION UNITS
CEnergyCreationUnit = Class(DefaultUnitsFile.EnergyCreationUnit) {
    OnStopBeingBuilt = function(self, builder, layer)
        DefaultUnitsFile.EnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        if self.AmbientEffects then
            for k, v in EffectTemplate[self.AmbientEffects] do
                CreateAttachedEmitter(self, 0, self:GetArmy(), v)
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
    StartBuildingEffects = function(self, unitBeingBuilt, order)
        self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateCybranBuildBeams, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag))
    end,

    OnPaused = function(self)
        SeaFactoryUnit.OnPaused(self)
        if not self.Dead and self:GetFractionComplete() == 1 then
            self:StopArmsMoving()
        end
    end,

    OnUnpaused = function(self)
        SeaFactoryUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') and self:IsUnitState('Building') then
            self:StartArmsMoving()
        end
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

CAmphibiousStructureUnit = Class(AmphibiousStructureUnit) {}

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
        ForkThread(function()
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
CConstructionStructureUnit = Class(CStructureUnit) {
    OnCreate = function(self)
        -- Structure stuff
        CStructureUnit.OnCreate(self)

        -- Construction stuff
        self.EffectsBag = {}
        if self:GetBlueprint().General.BuildBones then
            self:SetupBuildBones()
        end

        if self:GetBlueprint().Display.AnimationBuild then
            self.BuildingOpenAnim = self:GetBlueprint().Display.AnimationBuild
        end

        if self.BuildingOpenAnim then
            self.BuildingOpenAnimManip = CreateAnimator(self)
            self.BuildingOpenAnimManip:SetPrecedence(1)
            self.BuildingOpenAnimManip:PlayAnim(self.BuildingOpenAnim, false):SetRate(0)
            if self.BuildArmManipulator then
                self.BuildArmManipulator:Disable()
            end
        end
        self.BuildingUnit = false
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        local unitid = self:GetBlueprint().General.UpgradesTo

        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true

        CStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CStructureUnit.OnStopBeingBuilt(self, builder, layer)
        -- If created with F2 on land, then play the transform anim.
        if self:GetCurrentLayer() == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        local buildbots = EffectUtil.SpawnBuildBots(self, unitBeingBuilt, table.getn(self:GetBlueprint().General.BuildBones.BuildEffectBones), self.BuildEffectsBag)
        if buildbots then
            EffectUtil.CreateCybranEngineerBuildEffects(self, self:GetBlueprint().General.BuildBones.BuildEffectBones, buildbots, self.BuildEffectsBag)
        else
            EffectUtil.CreateCybranBuildBeams(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    -- This will only be called if not in StructureUnit's upgrade state
    OnStopBuild = function(self, unitBeingBuilt)
        CStructureUnit.OnStopBuild(self, unitBeingBuilt)

        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil

        if self.BuildingOpenAnimManip and self.BuildArmManipulator then
            self.StoppedBuilding = true
        elseif self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(-1)
        end

        self.BuildingUnit = false
    end,

    OnPaused = function(self)
        -- When factory is paused take some action
        self:StopUnitAmbientSound('ConstructLoop')
        CStructureUnit.OnPaused(self)
        if self.BuildingUnit then
            CStructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound('ConstructLoop')
            CStructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        CStructureUnit.OnUnpaused(self)
    end,

    StartBuildingEffects = function(self, unitBeingBuilt, order)
        CStructureUnit.StartBuildingEffects(self, unitBeingBuilt, order)
    end,

    StopBuildingEffects = function(self, unitBeingBuilt)
        CStructureUnit.StopBuildingEffects(self, unitBeingBuilt)
    end,

    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if (enable) then
                self.BuildArmManipulator:Enable()
            end
        end
    end,

    OnPrepareArmToBuild = function(self)
        CStructureUnit.OnPrepareArmToBuild(self)

        if self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(self:GetBlueprint().Display.AnimationBuildRate or 1)
            if self.BuildArmManipulator then
                self.StoppedBuilding = false
                ForkThread(self.WaitForBuildAnimation, self, true)
            end
        end
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
        EffectUtil.PlayReclaimEffects(self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0, }, self.ReclaimEffectsBag)
    end,

    CreateReclaimEndEffects = function(self, target)
        EffectUtil.PlayReclaimEndEffects(self, target)
    end,

    CreateCaptureEffects = function(self, target)
        EffectUtil.PlayCaptureEffects(self, target, self:GetBlueprint().General.BuildBones.BuildEffectBones or {0, }, self.CaptureEffectsBag)
    end,
}

-- CCommandUnit
-- Cybran Command Units (ACU and SCU) have stealth and cloak enhancements, toggles can be handled in one class
CCommandUnit = Class(CommandUnit) {
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
