--****************************************************************************
--**
--**  File     :  /lua/aeonunits.lua
--**  Author(s): John Comes, Gordon Duclos
--**
--**  Summary  :
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
----------------------------------------------------------------------------
-- AEON DEFAULT UNITS
----------------------------------------------------------------------------
local ipairs = ipairs
local unit_methodsIsUnitState = moho.unit_methods.IsUnitState
local RotateManipulatorSetSpinDown = moho.RotateManipulator.SetSpinDown
local unit_methodsGetBlueprint = moho.unit_methods.GetBlueprint
local AnimationManipulatorPlayAnim = moho.AnimationManipulator.PlayAnim
local CreateAttachedEmitter = CreateAttachedEmitter
local AnimationManipulatorSetRate = moho.AnimationManipulator.SetRate
local CreateAnimator = CreateAnimator
local CreateRotator = CreateRotator
local RotateManipulatorSetTargetSpeed = moho.RotateManipulator.SetTargetSpeed
local next = next
local unit_methodsGetFocusUnit = moho.unit_methods.GetFocusUnit

local DefaultUnitsFile = import('defaultunits.lua')
local FactoryUnit = DefaultUnitsFile.FactoryUnit
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local AirStagingPlatformUnit = DefaultUnitsFile.AirStagingPlatformUnit
local AirUnit = DefaultUnitsFile.AirUnit
local ConcreteStructureUnit = DefaultUnitsFile.ConcreteStructureUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyCreationUnit = DefaultUnitsFile.EnergyCreationUnit
local EnergyStorageUnit = DefaultUnitsFile.EnergyStorageUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local MassCollectionUnit = DefaultUnitsFile.MassCollectionUnit
local MassFabricationUnit = DefaultUnitsFile.MassFabricationUnit
local MassStorageUnit = DefaultUnitsFile.MassStorageUnit
local RadarUnit = DefaultUnitsFile.RadarUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local ShieldHoverLandUnit = DefaultUnitsFile.ShieldHoverLandUnit
local ShieldLandUnit = DefaultUnitsFile.ShieldLandUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local SonarUnit = DefaultUnitsFile.SonarUnit
local StructureUnit = DefaultUnitsFile.StructureUnit
local QuantumGateUnit = DefaultUnitsFile.QuantumGateUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local TransportBeaconUnit = DefaultUnitsFile.TransportBeaconUnit
local WalkingLandUnit = DefaultUnitsFile.WalkingLandUnit
local WallStructureUnit = DefaultUnitsFile.WallStructureUnit

local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateAeonFactoryBuildingEffects = EffectUtil.CreateAeonFactoryBuildingEffects


---------------------------------------------------------------
--  FACTORIES
---------------------------------------------------------------
AFactoryUnit = Class(FactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    OnPaused = function(self)
        -- When factory is paused take some action
        if unit_methodsIsUnitState(self, 'Building') and self.unitBeingBuilt then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StartBuildFx(unit_methodsGetFocusUnit(self))
        end
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)
        if unit_methodsIsUnitState(self, 'Building') and self.unitBeingBuilt then
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StartBuildFx(unit_methodsGetFocusUnit(self))
        end
    end,
}

---------------------------------------------------------------
--  AIR STRUCTURES
---------------------------------------------------------------
AAirFactoryUnit = Class(AirFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        AFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
AAirUnit = Class(AirUnit) {}

---------------------------------------------------------------
--  AIR STAGING STRUCTURES
---------------------------------------------------------------
AAirStagingPlatformUnit = Class(AirStagingPlatformUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
AConcreteStructureUnit = Class(ConcreteStructureUnit) {
    AdjacencyBeam = false,
}

---------------------------------------------------------------
--  Construction Units
---------------------------------------------------------------
AConstructionUnit = Class(ConstructionUnit) {
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonConstructionUnitBuildingEffects(self, unitBeingBuilt, self.BuildEffectsBag)
    end,
}

---------------------------------------------------------------
--  ENERGY CREATION UNITS
---------------------------------------------------------------
AEnergyCreationUnit = Class(EnergyCreationUnit) {
    OnCreate = function(self)
        EnergyCreationUnit.OnCreate(self)
        self.NumUsedAdjacentUnits = 0
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        EnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        if self.AmbientEffects then
            for k, v in EffectTemplate[self.AmbientEffects] do
                CreateAttachedEmitter(self, 0, self.Army, v)
            end
        end
    end,
}

---------------------------------------------------------------
-- ENERGY STORAGE STRUCTURES
---------------------------------------------------------------
AEnergyStorageUnit = Class(EnergyStorageUnit) {}

---------------------------------------------------------------
--  HOVERING LAND UNITS
---------------------------------------------------------------
AHoverLandUnit = Class(DefaultUnitsFile.HoverLandUnit) {
    FxHoverScale = 1,
    HoverEffects = nil,
    HoverEffectBones = nil,
}

---------------------------------------------------------------
--  LAND FACTORY STRUCTURES
---------------------------------------------------------------
ALandFactoryUnit = Class(LandFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        AFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  LAND UNITS
---------------------------------------------------------------
ALandUnit = Class(DefaultUnitsFile.LandUnit) {}

---------------------------------------------------------------
--  MASS COLLECTION UNITS
---------------------------------------------------------------
AMassCollectionUnit = Class(MassCollectionUnit) {}

---------------------------------------------------------------
--  MASS FABRICATION STRUCTURES
---------------------------------------------------------------
AMassFabricationUnit = Class(MassFabricationUnit) {}

---------------------------------------------------------------
--  MASS STORAGE UNITS
---------------------------------------------------------------
AMassStorageUnit = Class(MassStorageUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
ARadarUnit = Class(RadarUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
ASonarUnit = Class(SonarUnit) {}

---------------------------------------------------------------
--  SEA FACTORY STRUCTURES
---------------------------------------------------------------
ASeaFactoryUnit = Class(SeaFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint01', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  SEA UNITS
---------------------------------------------------------------
ASeaUnit = Class(DefaultUnitsFile.SeaUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
AShieldHoverLandUnit = Class(ShieldHoverLandUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
AShieldLandUnit = Class(ShieldLandUnit) {}

---------------------------------------------------------------
--  SHIELD STRUCTURES
---------------------------------------------------------------
AShieldStructureUnit = Class(ShieldStructureUnit) {
    RotateSpeed = 60,

    OnShieldEnabled = function(self)
        ShieldStructureUnit.OnShieldEnabled(self)
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'Pod', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        RotateManipulatorSetSpinDown(self.Rotator, false)
        RotateManipulatorSetTargetSpeed(self.Rotator, self.RotateSpeed)
    end,

    OnShieldDisabled = function(self)
        ShieldStructureUnit.OnShieldDisabled(self)
        if self.Rotator then
            RotateManipulatorSetTargetSpeed(self.Rotator, 0)
        end
    end,
}

---------------------------------------------------------------
--  STRUCTURES
---------------------------------------------------------------
AStructureUnit = Class(StructureUnit) {}

---------------------------------------------------------------
--  SUBMARINE UNITS
---------------------------------------------------------------
ASubUnit = Class(DefaultUnitsFile.SubUnit) {
    IdleSubBones = {},
    IdleSubEffects = {}
}

---------------------------------------------------------------
--  TRANSPORT BEACON UNITS
---------------------------------------------------------------
ATransportBeaconUnit = Class(TransportBeaconUnit) {}

---------------------------------------------------------------
--  WALKING LAND UNITS
---------------------------------------------------------------
AWalkingLandUnit = Class(WalkingLandUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
AWallStructureUnit = Class(WallStructureUnit) {}

---------------------------------------------------------------
--  CIVILIAN STRUCTURES
---------------------------------------------------------------
ACivilianStructureUnit = Class(AStructureUnit) {}

---------------------------------------------------------------
--  QUANTUM GATE UNITS
---------------------------------------------------------------
AQuantumGateUnit = Class(QuantumGateUnit) {}

---------------------------------------------------------------
--  RADAR JAMMER UNITS
---------------------------------------------------------------
ARadarJammerUnit = Class(RadarJammerUnit) {
    RotateSpeed = 60,

    OnStopBeingBuilt = function(self, builder, layer)
        RadarJammerUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = unit_methodsGetBlueprint(self)
        local bpAnim = bp.Display.AnimationOpen
        if not bpAnim then return end
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            AnimationManipulatorPlayAnim(self.OpenAnim, bpAnim)
            self.Trash:Add(self.OpenAnim)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
    end,

    OnIntelEnabled = function(self)
        RadarJammerUnit.OnIntelEnabled(self)
        if self.OpenAnim then
            AnimationManipulatorSetRate(self.OpenAnim, 1)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        RotateManipulatorSetSpinDown(self.Rotator, false)
        RotateManipulatorSetTargetSpeed(self.Rotator, self.RotateSpeed)
    end,

    OnIntelDisabled = function(self)
        RadarJammerUnit.OnIntelDisabled(self)
        if self.OpenAnim then
            AnimationManipulatorSetRate(self.OpenAnim, -1)
        end
        if self.Rotator then
            RotateManipulatorSetTargetSpeed(self.Rotator, 0)
        end
    end,
}
