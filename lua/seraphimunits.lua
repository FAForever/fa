-----------------------------------------------------------------
-- File     :  /cdimage/lua/seraphimunits.lua
-- Author(s): Dru Staltman, Jessica St. Croix
-- Summary  : Units for Seraphim
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
SFactoryUnit = import('/lua/sim/units/seraphim/sfactoryunit.lua').SFactoryUnit
SAirFactoryUnit = import('/lua/sim/units/seraphim/sairfactoryunit.lua').SAirFactoryUnit
SAirUnit = import('/lua/sim/units/seraphim/sairunit.lua').SAirUnit
SAirStagingPlatformUnit = import('/lua/sim/units/seraphim/sairstagingplatformunit.lua').SAirStagingPlatformUnit
SConcreteStructureUnit = import('/lua/sim/units/seraphim/sconcretestructureunit.lua').SConcreteStructureUnit
SConstructionUnit = import('/lua/sim/units/seraphim/sconstructionunit.lua').SConstructionUnit
SEnergyCreationUnit = import('/lua/sim/units/seraphim/senergycreationunit.lua').SEnergyCreationUnit
SEnergyStorageUnit = import('/lua/sim/units/seraphim/senergystorageunit.lua').SEnergyStorageUnit
SHoverLandUnit = import('/lua/sim/units/seraphim/shoverlandunit.lua').SHoverLandUnit
SLandFactoryUnit = import('/lua/sim/units/seraphim/slandfactoryunit.lua').SLandFactoryUnit
SLandUnit = import('/lua/sim/units/seraphim/slandunit.lua').SLandUnit
SMassCollectionUnit = import('/lua/sim/units/seraphim/smasscollectionunit.lua').SMassCollectionUnit
SMassFabricationUnit = import('/lua/sim/units/seraphim/smassfabricationunit.lua').SMassFabricationUnit
SMassStorageUnit = import('/lua/sim/units/seraphim/smassstorageunit.lua').SMassStorageUnit
SRadarUnit = import('/lua/sim/units/seraphim/sradarunit.lua').SRadarUnit
SSeaFactoryUnit = import('/lua/sim/units/seraphim/sseafactoryunit.lua').SSeaFactoryUnit
SSeaUnit = import('/lua/sim/units/seraphim/sseaunit.lua').SSeaUnit
SShieldHoverLandUnit = import('/lua/sim/units/seraphim/sshieldhoverlandunit.lua').SShieldHoverLandUnit
SShieldLandUnit = import('/lua/sim/units/seraphim/sshieldlandunit.lua').SShieldLandUnit
SShieldStructureUnit = import('/lua/sim/units/seraphim/sshieldstructureunit.lua').SShieldStructureUnit
SStructureUnit = import('/lua/sim/units/seraphim/sstructureunit.lua').SStructureUnit
SSubUnit = import('/lua/sim/units/seraphim/ssubunit.lua').SSubUnit
STransportBeaconUnit = import('/lua/sim/units/seraphim/stransportbeaconunit.lua').STransportBeaconUnit
SWalkingLandUnit = import('/lua/sim/units/seraphim/swalkinglandunit.lua').SWalkingLandUnit
SWallStructureUnit = import('/lua/sim/units/seraphim/swallstructureunit.lua').SWallStructureUnit
SCivilianStructureUnit = import('/lua/sim/units/seraphim/scivilianstructureunit.lua').SCivilianStructureUnit
SQuantumGateUnit = import('/lua/sim/units/seraphim/squantumgateunit.lua').SQuantumGateUnit
SRadarJammerUnit = import('/lua/sim/units/seraphim/sradarjammerunit.lua').SRadarJammerUnit
SEnergyBallUnit = import('/lua/sim/units/seraphim/senergyballunit.lua').SEnergyBallUnit
SSonarUnit = import('/lua/sim/units/seraphim/ssonarunit.lua').SSonarUnit

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
