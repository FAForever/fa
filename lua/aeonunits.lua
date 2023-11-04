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
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local FactoryUnit = DefaultUnitsFile.FactoryUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyCreationUnit = DefaultUnitsFile.EnergyCreationUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit

local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CreateAeonFactoryBuildingEffects = EffectUtil.CreateAeonFactoryBuildingEffects

---------------------------------------------------------------
--  FACTORIES
---------------------------------------------------------------
---@class AFactoryUnit : FactoryUnit
AFactoryUnit = ClassUnit(FactoryUnit) {

    ---@param self AFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self AFactoryUnit
    OnPaused = function(self)
        FactoryUnit.OnPaused(self)

        -- stop the building fx
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            FactoryUnit.StopBuildingEffects(self, unitBeingBuilt)
            self:StopUnitAmbientSound('ConstructLoop')
        end
    end,

    ---@param self AFactoryUnit
    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)

        -- start the building fx
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            FactoryUnit.StopBuildingEffects(self, unitBeingBuilt)
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

---------------------------------------------------------------
--  AIR STRUCTURES
---------------------------------------------------------------
---@class AAirFactoryUnit : AirFactoryUnit
AAirFactoryUnit = ClassUnit(DefaultUnitsFile.AirFactoryUnit) {
    StartBuildFx = AFactoryUnit.StartBuildFx,
    OnPaused = AFactoryUnit.OnPaused,
    OnUnpaused = AFactoryUnit.OnUnpaused,
}

---------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
---@class AAirUnit : AirUnit
AAirUnit = ClassUnit(DefaultUnitsFile.AirUnit) {}

---------------------------------------------------------------
--  AIR STAGING STRUCTURES
---------------------------------------------------------------
---@class AAirStagingPlatformUnit : AirStagingPlatformUnit
AAirStagingPlatformUnit = ClassUnit(DefaultUnitsFile.AirStagingPlatformUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
---@class AConcreteStructureUnit : ConcreteStructureUnit
AConcreteStructureUnit = ClassUnit(DefaultUnitsFile.ConcreteStructureUnit) {}

---------------------------------------------------------------
--  Construction Units
---------------------------------------------------------------
---@class AConstructionUnit : ConstructionUnit
AConstructionUnit = ClassUnit(ConstructionUnit) {

    ---@param self AConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonConstructionUnitBuildingEffects(self, unitBeingBuilt, self.BuildEffectsBag)
    end,
}

---------------------------------------------------------------
--  ENERGY CREATION UNITS
---------------------------------------------------------------
---@class AEnergyCreationUnit : EnergyCreationUnit
AEnergyCreationUnit = ClassUnit(EnergyCreationUnit) {
    ---@param self AEnergyCreationUnit
    ---@param builder Unit
    ---@param layer Layer
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
---@class AEnergyStorageUnit : EnergyStorageUnit
AEnergyStorageUnit = ClassUnit(DefaultUnitsFile.EnergyStorageUnit) {}

---------------------------------------------------------------
--  HOVERING LAND UNITS
---------------------------------------------------------------
---@class AHoverLandUnit : HoverLandUnit
AHoverLandUnit = ClassUnit(DefaultUnitsFile.HoverLandUnit) {}

---------------------------------------------------------------
--  LAND FACTORY STRUCTURES
---------------------------------------------------------------
---@class ALandFactoryUnit : LandFactoryUnit
ALandFactoryUnit = ClassUnit(LandFactoryUnit) {
    StartBuildFx = AFactoryUnit.StartBuildFx,
    OnPaused = AFactoryUnit.OnPaused,
    OnUnpaused = AFactoryUnit.OnUnpaused,
}

---------------------------------------------------------------
--  LAND UNITS
---------------------------------------------------------------
---@class ALandUnit : LandUnit
ALandUnit = ClassUnit(DefaultUnitsFile.LandUnit) {}

---------------------------------------------------------------
--  MASS COLLECTION UNITS
---------------------------------------------------------------
---@class AMassCollectionUnit : MassCollectionUnit
AMassCollectionUnit = ClassUnit(DefaultUnitsFile.MassCollectionUnit) {}

---------------------------------------------------------------
--  MASS FABRICATION STRUCTURES
---------------------------------------------------------------
---@class AMassFabricationUnit : MassFabricationUnit
AMassFabricationUnit = ClassUnit(DefaultUnitsFile.MassFabricationUnit) {}

---------------------------------------------------------------
--  MASS STORAGE UNITS
---------------------------------------------------------------
---@class AMassStorageUnit : MassStorageUnit
AMassStorageUnit = ClassUnit(DefaultUnitsFile.MassStorageUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
---@class ARadarUnit : RadarUnit
ARadarUnit = ClassUnit(DefaultUnitsFile.RadarUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
---@class ASonarUnit : SonarUnit
ASonarUnit = ClassUnit(DefaultUnitsFile.SonarUnit) {}

---------------------------------------------------------------
--  SEA FACTORY STRUCTURES
---------------------------------------------------------------
---@class ASeaFactoryUnit : SeaFactoryUnit
ASeaFactoryUnit = ClassUnit(SeaFactoryUnit) {

    ---@param self ASeaFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint01', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    OnPaused = AFactoryUnit.OnPaused,
    OnUnpaused = AFactoryUnit.OnUnpaused,
}

---------------------------------------------------------------
--  SEA UNITS
---------------------------------------------------------------
---@class ASeaUnit : SeaUnit
ASeaUnit = ClassUnit(DefaultUnitsFile.SeaUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
---@class AShieldHoverLandUnit : ShieldHoverLandUnit
AShieldHoverLandUnit = ClassUnit(DefaultUnitsFile.ShieldHoverLandUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
---@class AShieldLandUnit : ShieldLandUnit
AShieldLandUnit = ClassUnit(DefaultUnitsFile.ShieldLandUnit) {}

---------------------------------------------------------------
--  SHIELD STRUCTURES
---------------------------------------------------------------
---@class AShieldStructureUnit : ShieldStructureUnit
---@field Rotator? moho.RotateManipulator
AShieldStructureUnit = ClassUnit(ShieldStructureUnit) {
    RotateSpeed = 60,

    ---@param self AShieldStructureUnit
    OnShieldEnabled = function(self)
        ShieldStructureUnit.OnShieldEnabled(self)
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'Pod', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(self.RotateSpeed)
    end,

    ---@param self AShieldStructureUnit
    OnShieldDisabled = function(self)
        ShieldStructureUnit.OnShieldDisabled(self)
        if self.Rotator then
            self.Rotator:SetTargetSpeed(0)
        end
    end,
}

---------------------------------------------------------------
--  STRUCTURES
---------------------------------------------------------------
---@class AStructureUnit : StructureUnit
AStructureUnit = ClassUnit(DefaultUnitsFile.StructureUnit) {}

---------------------------------------------------------------
--  SUBMARINE UNITS
---------------------------------------------------------------
---@class ASubUnit : SubUnit
ASubUnit = ClassUnit(DefaultUnitsFile.SubUnit) {}

---------------------------------------------------------------
--  TRANSPORT BEACON UNITS
---------------------------------------------------------------
---@class ATransportBeaconUnit : TransportBeaconUnit
ATransportBeaconUnit = ClassUnit(DefaultUnitsFile.TransportBeaconUnit) {}

---------------------------------------------------------------
--  WALKING LAND UNITS
---------------------------------------------------------------
---@class AWalkingLandUnit : WalkingLandUnit
AWalkingLandUnit = ClassUnit(DefaultUnitsFile.WalkingLandUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
---@class AWallStructureUnit : WallStructureUnit
AWallStructureUnit = ClassUnit(DefaultUnitsFile.WallStructureUnit) {}

---------------------------------------------------------------
--  CIVILIAN STRUCTURES
---------------------------------------------------------------
---@class ACivilianStructureUnit : AStructureUnit
ACivilianStructureUnit = ClassUnit(AStructureUnit) {}

---------------------------------------------------------------
--  QUANTUM GATE UNITS
---------------------------------------------------------------
---@class AQuantumGateUnit : QuantumGateUnit
AQuantumGateUnit = ClassUnit(DefaultUnitsFile.QuantumGateUnit) {}

---------------------------------------------------------------
--  RADAR JAMMER UNITS
---------------------------------------------------------------
---@class ARadarJammerUnit : RadarJammerUnit
---@field Rotator? moho.RotateManipulator
---@field OpenAnim? moho.AnimationManipulator
ARadarJammerUnit = ClassUnit(RadarJammerUnit) {
    RotateSpeed = 60,

    ---@param self ARadarJammerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        RadarJammerUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationOpen
        if not bpAnim then return end
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            self.OpenAnim:PlayAnim(bpAnim)
            self.Trash:Add(self.OpenAnim)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
    end,

    ---@param self ARadarJammerUnit
    OnIntelEnabled = function(self, intel)
        RadarJammerUnit.OnIntelEnabled(self, intel)
        if self.OpenAnim then
            self.OpenAnim:SetRate(1)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'B02', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(self.RotateSpeed)
    end,

    ---@param self ARadarJammerUnit
    OnIntelDisabled = function(self, intel)
        RadarJammerUnit.OnIntelDisabled(self, intel)
        if self.OpenAnim then
            self.OpenAnim:SetRate(-1)
        end
        if self.Rotator then
            self.Rotator:SetTargetSpeed(0)
        end
    end,
}