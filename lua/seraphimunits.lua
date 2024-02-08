-----------------------------------------------------------------
-- File     :  /cdimage/lua/seraphimunits.lua
-- Author(s): Dru Staltman, Jessica St. Croix
-- Summary  : Units for Seraphim
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
SFactoryUnit = import('/lua/sim/units/seraphim/SFactoryUnit.lua').SFactoryUnit
SAirFactoryUnit = import('/lua/sim/units/seraphim/SAirFactoryUnit.lua').SAirFactoryUnit
SAirUnit = import('/lua/sim/units/seraphim/SAirUnit.lua').SAirUnit
SAirStagingPlatformUnit = import('/lua/sim/units/seraphim/SAirStagingPlatformUnit.lua').SAirStagingPlatformUnit
SConcreteStructureUnit = import('/lua/sim/units/seraphim/SConcreteStructureUnit.lua').SConcreteStructureUnit
SConstructionUnit = import('/lua/sim/units/seraphim/SConstructionUnit.lua').SConstructionUnit
SEnergyCreationUnit = import('/lua/sim/units/seraphim/SEnergyCreationUnit.lua').SEnergyCreationUnit
SEnergyStorageUnit = import('/lua/sim/units/seraphim/SEnergyStorageUnit.lua').SEnergyStorageUnit
SHoverLandUnit = import('/lua/sim/units/seraphim/SHoverLandUnit.lua').SHoverLandUnit
SLandFactoryUnit = import('/lua/sim/units/seraphim/SLandFactoryUnit.lua').SLandFactoryUnit
SLandUnit = import('/lua/sim/units/seraphim/SLandUnit.lua').SLandUnit
SMassCollectionUnit = import('/lua/sim/units/seraphim/SMassCollectionUnit.lua').SMassCollectionUnit
SMassFabricationUnit = import('/lua/sim/units/seraphim/SMassFabricationUnit.lua').SMassFabricationUnit
SMassStorageUnit = import('/lua/sim/units/seraphim/SMassStorageUnit.lua').SMassStorageUnit
SRadarUnit = import('/lua/sim/units/seraphim/SRadarUnit.lua').SRadarUnit
SSeaFactoryUnit = import('/lua/sim/units/seraphim/SSeaFactoryUnit.lua').SSeaFactoryUnit
SSeaUnit = import('/lua/sim/units/seraphim/SSeaUnit.lua').SSeaUnit
SShieldHoverLandUnit = import('/lua/sim/units/seraphim/SShieldHoverLandUnit.lua').SShieldHoverLandUnit
SShieldLandUnit = import('/lua/sim/units/seraphim/SShieldLandUnit.lua').SShieldLandUnit
SShieldStructureUnit = import('/lua/sim/units/seraphim/SShieldStructureUnit.lua').SShieldStructureUnit
SStructureUnit = import('/lua/sim/units/seraphim/SStructureUnit.lua').SStructureUnit
SSubUnit = import('/lua/sim/units/seraphim/SSubUnit.lua').SSubUnit
STransportBeaconUnit = import('/lua/sim/units/seraphim/STransportBeaconUnit.lua').STransportBeaconUnit
SWalkingLandUnit = import('/lua/sim/units/seraphim/SWalkingLandUnit.lua').SWalkingLandUnit
SWallStructureUnit = import('/lua/sim/units/seraphim/SWallStructureUnit.lua').SWallStructureUnit
SCivilianStructureUnit = import('/lua/sim/units/seraphim/SCivilianStructureUnit.lua').SCivilianStructureUnit
SQuantumGateUnit = import('/lua/sim/units/seraphim/SQuantumGateUnit.lua').SQuantumGateUnit
SRadarJammerUnit = import('/lua/sim/units/seraphim/SRadarJammerUnit.lua').SRadarJammerUnit
SEnergyBallUnit = import('/lua/sim/units/seraphim/SEnergyBallUnit.lua').SEnergyBallUnit
SSonarUnit = import('/lua/sim/units/seraphim/SSonarUnit.lua').SSonarUnit

--- Kept for backwards compatibility
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
local WeaponFile = import("/lua/sim/defaultweapons.lua")
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CreateSeraphimFactoryBuildingEffects = EffectUtil.CreateSeraphimFactoryBuildingEffects
