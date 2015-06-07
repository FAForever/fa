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
local AirFactoryUnit = import('/lua/sim/units/AirFactoryUnit.lua').AirFactoryUnit
local AirStagingPlatformUnit = import('/lua/sim/units/AirStagingPlatformUnit.lua').AirStagingPlatformUnit
local AirUnit = import('/lua/sim/units/AirUnit.lua').AirUnit
local ConcreteStructureUnit = import('/lua/sim/units/ConcreteStructureUnit.lua').ConcreteStructureUnit
local ConstructionUnit = import('/lua/sim/units/ConstructionUnit.lua').ConstructionUnit
local EnergyCreationUnit = import('/lua/sim/units/EnergyCreationUnit.lua').EnergyCreationUnit
local EnergyStorageUnit = import('/lua/sim/units/EnergyStorageUnit.lua').EnergyStorageUnit
local HoverLandUnit = import('/lua/sim/units/HoverLandUnit.lua').HoverLandUnit
local LandUnit = import('/lua/sim/units/LandUnit.lua').LandUnit
local LandFactoryUnit = import('/lua/sim/units/LandFactoryUnit.lua').LandFactoryUnit
local MassCollectionUnit = import('/lua/sim/units/MassCollectionUnit.lua').MassCollectionUnit
local MassFabricationUnit = import('/lua/sim/units/MassFabricationUnit.lua').MassFabricationUnit
local MassStorageUnit = import('/lua/sim/units/MassStorageUnit.lua').MassStorageUnit
local RadarUnit = import('/lua/sim/units/RadarUnit.lua').RadarUnit
local SeaUnit = import('/lua/sim/units/SeaUnit.lua').SeaUnit
local SeaFactoryUnit = import('/lua/sim/units/SeaFactoryUnit.lua').SeaFactoryUnit
local ShieldHoverLandUnit = import('/lua/sim/units/ShieldHoverLandUnit.lua').ShieldHoverLandUnit
local ShieldLandUnit = import('/lua/sim/units/ShieldLandUnit.lua').ShieldLandUnit
local ShieldStructureUnit = import('/lua/sim/units/ShieldStructureUnit.lua').ShieldStructureUnit
local SonarUnit = import('/lua/sim/units/SonarUnit.lua').SonarUnit
local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit
local SubUnit = import('/lua/sim/units/SubUnit.lua').SubUnit
local TransportBeaconUnit = import('/lua/sim/units/TransportBeaconUnit.lua').TransportBeaconUnit
local QuantumGateUnit = import('/lua/sim/units/QuantumGateUnit.lua').QuantumGateUnit
local RadarJammerUnit = import('/lua/sim/units/RadarJammerUnit.lua').RadarJammerUnit
local WallStructureUnit = import('/lua/sim/units/WallStructureUnit.lua').WallStructureUnit
local WalkingLandUnit = import('/lua/sim/units/WalkingLandUnit.lua').WalkingLandUnit

local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateAeonFactoryBuildingEffects = EffectUtil.CreateAeonFactoryBuildingEffects

---------------------------------------------------------------
--  AIR STRUCTURES
---------------------------------------------------------------
AAirFactoryUnit = Class(AirFactoryUnit) {
    StartBuildFx = function( self, unitBeingBuilt )
        local thread = self:ForkThread( EffectUtil.CreateAeonFactoryBuildingEffects, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag )
        unitBeingBuilt.Trash:Add( thread )        
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
    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateAeonConstructionUnitBuildingEffects( self, unitBeingBuilt, self.BuildEffectsBag )
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
        local army =  self:GetArmy()
        if self.AmbientEffects then
            for k, v in EffectTemplate[self.AmbientEffects] do
                CreateAttachedEmitter(self, 0, army, v)
            end
        end
    end,
}

---------------------------------------------------------------
-- ENERGY STORAGE STRUCTURES
---------------------------------------------------------------
AEnergyStorageUnit = Class(EnergyStorageUnit) {
}

---------------------------------------------------------------
--  HOVERING LAND UNITS
---------------------------------------------------------------
AHoverLandUnit = Class(HoverLandUnit) {
    FxHoverScale = 1,
    HoverEffects = nil,
    HoverEffectBones = nil,
}

---------------------------------------------------------------
--  LAND FACTORY STRUCTURES
---------------------------------------------------------------
ALandFactoryUnit = Class(LandFactoryUnit) {
    StartBuildFx = function( self, unitBeingBuilt )
        local thread = self:ForkThread( EffectUtil.CreateAeonFactoryBuildingEffects, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, 'Attachpoint', self.BuildEffectsBag )
        unitBeingBuilt.Trash:Add( thread )
    end,
}

---------------------------------------------------------------
--  LAND UNITS
---------------------------------------------------------------
ALandUnit = Class(LandUnit) { }

---------------------------------------------------------------
--  MASS COLLECTION UNITS
---------------------------------------------------------------
AMassCollectionUnit = Class(MassCollectionUnit) {
}

---------------------------------------------------------------
--  MASS FABRICATION STRUCTURES
---------------------------------------------------------------
AMassFabricationUnit = Class(MassFabricationUnit) {
}

---------------------------------------------------------------
--  MASS STORAGE UNITS
---------------------------------------------------------------
AMassStorageUnit = Class(MassStorageUnit) {
}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
ARadarUnit = Class(RadarUnit) {
}

---------------------------------------------------------------
--  RADAR STRUCTURES
---------------------------------------------------------------
ASonarUnit = Class(SonarUnit) {}

---------------------------------------------------------------
--  SEA FACTORY STRUCTURES
---------------------------------------------------------------
ASeaFactoryUnit = Class(SeaFactoryUnit) {
    StartBuildFx = function( self, unitBeingBuilt )
        local thread = self:ForkThread( EffectUtil.CreateAeonFactoryBuildingEffects, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, 'Attachpoint01', self.BuildEffectsBag )
        unitBeingBuilt.Trash:Add( thread )    
    end,	
}

---------------------------------------------------------------
--  SEA UNITS
---------------------------------------------------------------
ASeaUnit = Class(SeaUnit) {}

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
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationOpen
        if not bpAnim then return end
        if not self.OpenAnim then
            self.OpenAnim = CreateAnimator(self)
            self.OpenAnim:PlayAnim(bpAnim)
            self.Trash:Add(self.OpenAnim)
        end
        if not self.Rotator then
            self.Rotator = CreateRotator(self, 'Pod', 'z', nil, 0, 50, 0)
            self.Trash:Add(self.Rotator)
        end
        self.Rotator:SetSpinDown(false)
        self.Rotator:SetTargetSpeed(self.RotateSpeed)
        self.OpenAnim:SetRate(1)
    end,

    OnShieldDisabled = function(self)
        ShieldStructureUnit.OnShieldDisabled(self)
        if self.OpenAnim then
            self.OpenAnim:SetRate(-1)
        end
        if self.Rotator then
            
            self.Rotator:SetTargetSpeed(0)
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
ASubUnit = Class(SubUnit) {
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
AWalkingLandUnit = WalkingLandUnit

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
