------------------------------------------------------------------------------
-- File     :  /lua/aeonunits.lua
-- Author(s): John Comes, Gordon Duclos
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

--- Aeon UNITS Files
AFactoryUnit = import('/lua/sim/units/aeon/afactoryunit.lua').AFactoryUnit
AAirFactoryUnit = import('/lua/sim/units/aeon/aairfactoryunit.lua').AAirFactoryUnit
AAirUnit = import('/lua/sim/units/aeon/aairunit.lua').AAirUnit
AAirStagingPlatformUnit = import('/lua/sim/units/aeon/aairstagingplatformunit.lua').AAirStagingPlatformUnit
AConcreteStructureUnit = import('/lua/sim/units/aeon/aconcretestructureunit.lua').AConcreteStructureUnit
AConstructionUnit = import('/lua/sim/units/aeon/aconstructionunit.lua').AConstructionUnit
AEnergyCreationUnit = import('/lua/sim/units/aeon/aenergycreationunit.lua').AEnergyCreationUnit
AEnergyStorageUnit = import('/lua/sim/units/aeon/aenergystorageunit.lua').AEnergyStorageUnit
AHoverLandUnit = import('/lua/sim/units/aeon/ahoverlandunit.lua').AHoverLandUnit
ALandFactoryUnit = import('/lua/sim/units/aeon/alandfactoryunit.lua').ALandFactoryUnit
ALandUnit = import('/lua/sim/units/aeon/alandunit.lua').ALandUnit
AMassCollectionUnit = import('/lua/sim/units/aeon/amasscollectionunit.lua').AMassCollectionUnit
AMassFabricationUnit = import('/lua/sim/units/aeon/amassfabricationunit.lua').AMassFabricationUnit
AMassStorageUnit = import('/lua/sim/units/aeon/amassstorageunit.lua').AMassStorageUnit
ARadarUnit = import('/lua/sim/units/aeon/aradarunit.lua').ARadarUnit
ASonarUnit = import('/lua/sim/units/aeon/asonarunit.lua').ASonarUnit
ASeaFactoryUnit = import('/lua/sim/units/aeon/aseafactoryunit.lua').ASeaFactoryUnit
ASeaUnit = import('/lua/sim/units/aeon/aseaunit.lua').ASeaUnit
AShieldHoverLandUnit = import('/lua/sim/units/aeon/ashieldhoverlandunit.lua').AShieldHoverLandUnit
AShieldLandUnit = import('/lua/sim/units/aeon/ashieldlandunit.lua').AShieldLandUnit
AShieldStructureUnit = import('/lua/sim/units/aeon/ashieldstructureunit.lua').AShieldStructureUnit
AStructureUnit = import('/lua/sim/units/aeon/astructureunit.lua').AStructureUnit
ASubUnit = import('/lua/sim/units/aeon/asubunit.lua').ASubUnit
ATransportBeaconUnit = import('/lua/sim/units/aeon/atransportbeaconunit.lua').ATransportBeaconUnit
AWalkingLandUnit = import('/lua/sim/units/aeon/awalkinglandunit.lua').AWalkingLandUnit
AWallStructureUnit = import('/lua/sim/units/aeon/awallstructureunit.lua').AWallStructureUnit
ACivilianStructureUnit = import('/lua/sim/units/aeon/acivilianstructureunit.lua').ACivilianStructureUnit
AQuantumGateUnit = import('/lua/sim/units/aeon/aquantumgateunit.lua').AQuantumGateUnit
ARadarJammerUnit = import('/lua/sim/units/aeon/aradarjammerunit.lua').ARadarJammerUnit

--- Kept for backwards compatibility
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
local CreateAeonConstructionUnitBuildingEffects = EffectUtil.CreateAeonConstructionUnitBuildingEffects