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

local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CreateAeonFactoryBuildingEffects = EffectUtil.CreateAeonFactoryBuildingEffects


---------------------------------------------------------------
--  FACTORIES
---------------------------------------------------------------
---@class AFactoryUnit : FactoryUnit
AFactoryUnit = Class(FactoryUnit) {

    ---@param self AFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self AFactoryUnit
    OnPaused = function(self)
        -- When factory is paused take some action
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
        StructureUnit.OnPaused(self)
    end,

    ---@param self AFactoryUnit
    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StartBuildFx(self:GetFocusUnit())
        end
    end,
}

---------------------------------------------------------------
--  AIR STRUCTURES
---------------------------------------------------------------
---@class AAirFactoryUnit : AirFactoryUnit
AAirFactoryUnit = Class(AirFactoryUnit) {

    ---@param self AAirFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        AFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    ---@param self AAirFactoryUnit
    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    ---@param self AAirFactoryUnit
    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  AIR UNITS
---------------------------------------------------------------
---@class AAirUnit : AirUnit
AAirUnit = Class(AirUnit) {}

---------------------------------------------------------------
--  AIR STAGING STRUCTURES
---------------------------------------------------------------
---@class AAirStagingPlatformUnit : AirStagingPlatformUnit
AAirStagingPlatformUnit = Class(AirStagingPlatformUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
---@class AConcreteStructureUnit : ConcreteStructureUnit
AConcreteStructureUnit = Class(ConcreteStructureUnit) {
    AdjacencyBeam = false,
}

---------------------------------------------------------------
--  Construction Units
---------------------------------------------------------------
---@class AConstructionUnit : ConstructionUnit
AConstructionUnit = Class(ConstructionUnit) {

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
AEnergyCreationUnit = Class(EnergyCreationUnit) {

    ---@param self AEnergyCreationUnit
    OnCreate = function(self)
        EnergyCreationUnit.OnCreate(self)
        self.NumUsedAdjacentUnits = 0
    end,

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
AEnergyStorageUnit = Class(EnergyStorageUnit) {}

---------------------------------------------------------------
--  HOVERING LAND UNITS
---------------------------------------------------------------
---@class AHoverLandUnit : HoverLandUnit
AHoverLandUnit = Class(DefaultUnitsFile.HoverLandUnit) {
    FxHoverScale = 1,
    HoverEffects = nil,
    HoverEffectBones = nil,
}

---------------------------------------------------------------
--  LAND FACTORY STRUCTURES
---------------------------------------------------------------
---@class ALandFactoryUnit : LandFactoryUnit
ALandFactoryUnit = Class(LandFactoryUnit) {


    ---@param self ALandFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        AFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    ---@param self ALandFactoryUnit
    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    ---@param self ALandFactoryUnit
    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  LAND UNITS
---------------------------------------------------------------
---@class ALandUnit : LandUnit
ALandUnit = Class(DefaultUnitsFile.LandUnit) {}

---------------------------------------------------------------
--  MASS COLLECTION UNITS
---------------------------------------------------------------
---@class AMassCollectionUnit : MassCollectionUnit
AMassCollectionUnit = Class(MassCollectionUnit) {}

---------------------------------------------------------------
--  MASS FABRICATION STRUCTURES
---------------------------------------------------------------
---@class AMassFabricationUnit : MassFabricationUnit
AMassFabricationUnit = Class(MassFabricationUnit) {}

---------------------------------------------------------------
--  MASS STORAGE UNITS
---------------------------------------------------------------
---@class AMassStorageUnit : MassStorageUnit
AMassStorageUnit = Class(MassStorageUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
---@class ARadarUnit : RadarUnit
ARadarUnit = Class(RadarUnit) {}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
---@class ASonarUnit : SonarUnit
ASonarUnit = Class(SonarUnit) {}

---------------------------------------------------------------
--  SEA FACTORY STRUCTURES
---------------------------------------------------------------
---@class ASeaFactoryUnit : SeaFactoryUnit
ASeaFactoryUnit = Class(SeaFactoryUnit) {

    ---@param self ASeaFactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
        local thread = self:ForkThread(CreateAeonFactoryBuildingEffects, unitBeingBuilt, self.BuildEffectBones, 'Attachpoint01', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    ---@param self ASeaFactoryUnit
    OnPaused = function(self)
        AFactoryUnit.OnPaused(self)
    end,

    ---@param self ASeaFactoryUnit
    OnUnpaused = function(self)
        AFactoryUnit.OnUnpaused(self)
    end,
}

---------------------------------------------------------------
--  SEA UNITS
---------------------------------------------------------------
---@class ASeaUnit : SeaUnit
ASeaUnit = Class(DefaultUnitsFile.SeaUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
---@class AShieldHoverLandUnit : ShieldHoverLandUnit
AShieldHoverLandUnit = Class(ShieldHoverLandUnit) {}

---------------------------------------------------------------
--  SHIELD LAND UNITS
---------------------------------------------------------------
---@class AShieldLandUnit : ShieldLandUnit
AShieldLandUnit = Class(ShieldLandUnit) {}

---------------------------------------------------------------
--  SHIELD STRUCTURES
---------------------------------------------------------------
---@class AShieldStructureUnit : ShieldStructureUnit
AShieldStructureUnit = Class(ShieldStructureUnit) {
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
AStructureUnit = Class(StructureUnit) {}

---------------------------------------------------------------
--  SUBMARINE UNITS
---------------------------------------------------------------
---@class ASubUnit : SubUnit
ASubUnit = Class(DefaultUnitsFile.SubUnit) {
    IdleSubBones = {},
    IdleSubEffects = {}
}

---------------------------------------------------------------
--  TRANSPORT BEACON UNITS
---------------------------------------------------------------
---@class ATransportBeaconUnit : TransportBeaconUnit
ATransportBeaconUnit = Class(TransportBeaconUnit) {}

---------------------------------------------------------------
--  WALKING LAND UNITS
---------------------------------------------------------------
---@class AWalkingLandUnit : WalkingLandUnit
AWalkingLandUnit = Class(WalkingLandUnit) {}

---------------------------------------------------------------
--  WALL  STRUCTURES
---------------------------------------------------------------
---@class AWallStructureUnit : WallStructureUnit
AWallStructureUnit = Class(WallStructureUnit) {}

---------------------------------------------------------------
--  CIVILIAN STRUCTURES
---------------------------------------------------------------
---@class ACivilianStructureUnit : AStructureUnit
ACivilianStructureUnit = Class(AStructureUnit) {}

---------------------------------------------------------------
--  QUANTUM GATE UNITS
---------------------------------------------------------------
---@class AQuantumGateUnit : QuantumGateUnit
AQuantumGateUnit = Class(QuantumGateUnit) {}

---------------------------------------------------------------
--  RADAR JAMMER UNITS
---------------------------------------------------------------
---@class ARadarJammerUnit : RadarJammerUnit
ARadarJammerUnit = Class(RadarJammerUnit) {
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
    OnIntelEnabled = function(self)
        RadarJammerUnit.OnIntelEnabled(self)
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
    OnIntelDisabled = function(self)
        RadarJammerUnit.OnIntelDisabled(self)
        if self.OpenAnim then
            self.OpenAnim:SetRate(-1)
        end
        if self.Rotator then
            self.Rotator:SetTargetSpeed(0)
        end
    end,
}