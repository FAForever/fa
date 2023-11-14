-- ****************************************************************************
-- **
-- **  File     :  /lua/terranunits.lua
-- **  Author(s): John Comes, Dave Tomandl, Gordon Duclos
-- **
-- **  Summary  :
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

-- UEF Unit Files
TAirFactoryUnit = import('/lua/sim/units/uef/TAirFactoryUnit.lua').TAirFactoryUnit
TAirStagingPlatformUnit = import('/lua/sim/units/uef/TAirStagingPlatformUnit.lua').TAirStagingPlatformUnit
TAirUnit = import('/lua/sim/units/uef/TAirUnit.lua').TAirUnit
TConcreteStructureUnit = import('/lua/sim/units/uef/TConcreteStructureUnit.lua').TConcreteStructureUnit
TConstructionUnit = import('/lua/sim/units/uef/TConstructionUnit.lua').TConstructionUnit
TEnergyCreationUnit = import('/lua/sim/units/uef/TEnergyCreationUnit.lua').TEnergyCreationUnit
TEnergyStorageUnit = import('/lua/sim/units/uef/TEnergyStorageUnit.lua').TEnergyStorageUnit
THoverLandUnit = import('/lua/sim/units/uef/THoverLandUnit.lua').THoverLandUnit
TLandFactoryUnit = import('/lua/sim/units/uef/TLandFactoryUnit.lua').TLandFactoryUnit
TLandUnit = import('/lua/sim/units/uef/TLandUnit.lua').TLandUnit
TMassCollectionUnit = import('/lua/sim/units/uef/TMassCollectionUnit.lua').TMassCollectionUnit
TMassFabricationUnit = import('/lua/sim/units/uef/TMassFabricationUnit.lua').TMassFabricationUnit
TMassStorageUnit = import('/lua/sim/units/uef/TMassStorageUnit.lua').TMassStorageUnit
TMobileFactoryUnit = import('/lua/sim/units/uef/TMobileFactoryUnit.lua').TMobileFactoryUnit
TRadarUnit = import('/lua/sim/units/uef/TRadarUnit.lua').TRadarUnit
TSonarUnit = import('/lua/sim/units/uef/TSonarUnit.lua').TSonarUnit
TSeaFactoryUnit = import('/lua/sim/units/uef/TSeaFactoryUnit.lua').TSeaFactoryUnit
TShieldLandUnit = import('/lua/sim/units/uef/TShieldLandUnit.lua').TShieldLandUnit
TSeaUnit = import('/lua/sim/units/uef/TSeaUnit.lua').TSeaUnit
TShieldStructureUnit = import('/lua/sim/units/uef/TShieldStructureUnit.lua').TShieldStructureUnit
TStructureUnit = import('/lua/sim/units/uef/TStructureUnit.lua').TStructureUnit
TSubUnit = import('/lua/sim/units/uef/TSubUnit.lua').TSubUnit
TRadarJammerUnit = import('/lua/sim/units/uef/TRadarJammerUnit.lua').TRadarJammerUnit
TTransportBeaconUnit = import('/lua/sim/units/uef/TTransportBeaconUnit.lua').TTransportBeaconUnit
TWalkingLandUnit = import('/lua/sim/units/uef/TWalkingLandUnit.lua').TWalkingLandUnit
TWallStructureUnit = import('/lua/sim/units/uef/TWallStructureUnit.lua').TWallStructureUnit
TCivilianStructureUnit = import('/lua/sim/units/uef/TCivilianStructureUnit.lua').TCivilianStructureUnit
TQuantumGateUnit = import('/lua/sim/units/uef/TQuantumGateUnit.lua').TQuantumGateUnit
TShieldSeaUnit = import('/lua/sim/units/uef/TShieldSeaUnit.lua').TShieldSeaUnit
TPodTowerUnit = import('/lua/sim/units/uef/TPodTowerUnit.lua').TPodTowerUnit

-- kept for mod compatiablilty
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local AmphibiousLandUnit = DefaultUnitsFile.AmphibiousLandUnit
local EffectUtil = import("/lua/effectutilities.lua")
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread
local CreateDefaultBuildBeams = EffectUtil.CreateDefaultBuildBeams
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAttachedEmitter = CreateAttachedEmitter