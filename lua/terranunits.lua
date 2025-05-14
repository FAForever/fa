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
TAirFactoryUnit = import('/lua/sim/units/uef/tairfactoryunit.lua').TAirFactoryUnit
TAirStagingPlatformUnit = import('/lua/sim/units/uef/tairstagingplatformunit.lua').TAirStagingPlatformUnit
TAirUnit = import('/lua/sim/units/uef/tairunit.lua').TAirUnit
TConcreteStructureUnit = import('/lua/sim/units/uef/tconcretestructureunit.lua').TConcreteStructureUnit
TConstructionUnit = import('/lua/sim/units/uef/tconstructionunit.lua').TConstructionUnit
TConstructionPodUnit = import('/lua/sim/units/uef/tconstructionpodunit.lua').TConstructionPodUnit
TEnergyCreationUnit = import('/lua/sim/units/uef/tenergycreationunit.lua').TEnergyCreationUnit
TEnergyStorageUnit = import('/lua/sim/units/uef/tenergystorageunit.lua').TEnergyStorageUnit
THoverLandUnit = import('/lua/sim/units/uef/thoverlandunit.lua').THoverLandUnit
TLandFactoryUnit = import('/lua/sim/units/uef/tlandfactoryunit.lua').TLandFactoryUnit
TLandUnit = import('/lua/sim/units/uef/tlandunit.lua').TLandUnit
TMassCollectionUnit = import('/lua/sim/units/uef/tmasscollectionunit.lua').TMassCollectionUnit
TMassFabricationUnit = import('/lua/sim/units/uef/tmassfabricationunit.lua').TMassFabricationUnit
TMassStorageUnit = import('/lua/sim/units/uef/tmassstorageunit.lua').TMassStorageUnit
TMobileFactoryUnit = import('/lua/sim/units/uef/tmobilefactoryunit.lua').TMobileFactoryUnit
TRadarUnit = import('/lua/sim/units/uef/tradarunit.lua').TRadarUnit
TSonarUnit = import('/lua/sim/units/uef/tsonarunit.lua').TSonarUnit
TSeaFactoryUnit = import('/lua/sim/units/uef/tseafactoryunit.lua').TSeaFactoryUnit
TShieldLandUnit = import('/lua/sim/units/uef/tshieldlandunit.lua').TShieldLandUnit
TSeaUnit = import('/lua/sim/units/uef/tseaunit.lua').TSeaUnit
TShieldStructureUnit = import('/lua/sim/units/uef/tshieldstructureunit.lua').TShieldStructureUnit
TStructureUnit = import('/lua/sim/units/uef/tstructureunit.lua').TStructureUnit
TSubUnit = import('/lua/sim/units/uef/tsubunit.lua').TSubUnit
TRadarJammerUnit = import('/lua/sim/units/uef/tradarjammerunit.lua').TRadarJammerUnit
TTransportBeaconUnit = import('/lua/sim/units/uef/ttransportbeaconunit.lua').TTransportBeaconUnit
TWalkingLandUnit = import('/lua/sim/units/uef/twalkinglandunit.lua').TWalkingLandUnit
TWallStructureUnit = import('/lua/sim/units/uef/twallstructureunit.lua').TWallStructureUnit
TCivilianStructureUnit = import('/lua/sim/units/uef/tcivilianstructureunit.lua').TCivilianStructureUnit
TQuantumGateUnit = import('/lua/sim/units/uef/tquantumgateunit.lua').TQuantumGateUnit
TShieldSeaUnit = import('/lua/sim/units/uef/tshieldseaunit.lua').TShieldSeaUnit
TPodTowerUnit = import('/lua/sim/units/uef/tpodtowerunit.lua').TPodTowerUnit

-- kept for mod compatiablilty
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local AmphibiousLandUnit = DefaultUnitsFile.AmphibiousLandUnit
local EffectUtil = import("/lua/effectutilities.lua")
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread
local CreateDefaultBuildBeams = EffectUtil.CreateDefaultBuildBeams
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAttachedEmitter = CreateAttachedEmitter