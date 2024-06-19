------------------------------------------------------------------------------
-- File     :  /lua/aeonunits.lua
-- Author(s): John Comes, Gordon Duclos
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

--- Aeon UNITS Files
AFactoryUnit = import('/lua/sim/units/aeon/AFactoryUnit.lua').AFactoryUnit
AAirFactoryUnit = import('/lua/sim/units/aeon/AAirFactoryUnit.lua').AAirFactoryUnit
AAirUnit = import('/lua/sim/units/aeon/AAirUnit.lua').AAirUnit
AAirStagingPlatformUnit = import('/lua/sim/units/aeon/AAirStagingPlatformUnit.lua').AAirStagingPlatformUnit
AConcreteStructureUnit = import('/lua/sim/units/aeon/AConcreteStructureUnit.lua').AConcreteStructureUnit
AConstructionUnit = import('/lua/sim/units/aeon/AConstructionUnit.lua').AConstructionUnit
AEnergyCreationUnit = import('/lua/sim/units/aeon/AEnergyCreationUnit.lua').AEnergyCreationUnit
AEnergyStorageUnit = import('/lua/sim/units/aeon/AEnergyStorageUnit.lua').AEnergyStorageUnit
AHoverLandUnit = import('/lua/sim/units/aeon/AHoverLandUnit.lua').AHoverLandUnit
ALandFactoryUnit = import('/lua/sim/units/aeon/ALandFactoryUnit.lua').ALandFactoryUnit
ALandUnit = import('/lua/sim/units/aeon/ALandUnit.lua').ALandUnit
AMassCollectionUnit = import('/lua/sim/units/aeon/AMassCollectionUnit.lua').AMassCollectionUnit
AMassFabricationUnit = import('/lua/sim/units/aeon/AMassFabricationUnit.lua').AMassFabricationUnit
AMassStorageUnit = import('/lua/sim/units/aeon/AMassStorageUnit.lua').AMassStorageUnit
ARadarUnit = import('/lua/sim/units/aeon/ARadarUnit.lua').ARadarUnit
ASonarUnit = import('/lua/sim/units/aeon/ASonarUnit.lua').ASonarUnit
ASeaFactoryUnit = import('/lua/sim/units/aeon/ASeaFactoryUnit.lua').ASeaFactoryUnit
ASeaUnit = import('/lua/sim/units/aeon/ASeaUnit.lua').ASeaUnit
AShieldHoverLandUnit = import('/lua/sim/units/aeon/AShieldHoverLandUnit.lua').AShieldHoverLandUnit
AShieldLandUnit = import('/lua/sim/units/aeon/AShieldLandUnit.lua').AShieldLandUnit
AShieldStructureUnit = import('/lua/sim/units/aeon/AShieldStructureUnit.lua').AShieldStructureUnit
AStructureUnit = import('/lua/sim/units/aeon/AStructureUnit.lua').AStructureUnit
ASubUnit = import('/lua/sim/units/aeon/ASubUnit.lua').ASubUnit
ATransportBeaconUnit = import('/lua/sim/units/aeon/ATransportBeaconUnit.lua').ATransportBeaconUnit
AWalkingLandUnit = import('/lua/sim/units/aeon/AWalkingLandUnit.lua').AWalkingLandUnit
AWallStructureUnit = import('/lua/sim/units/aeon/AWallStructureUnit.lua').AWallStructureUnit
ACivilianStructureUnit = import('/lua/sim/units/aeon/ACivilianStructureUnit.lua').ACivilianStructureUnit
AQuantumGateUnit = import('/lua/sim/units/aeon/AQuantumGateUnit.lua').AQuantumGateUnit
ARadarJammerUnit = import('/lua/sim/units/aeon/ARadarJammerUnit.lua').ARadarJammerUnit

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