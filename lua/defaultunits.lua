-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

BaseTransport = import("/lua/defaultunitcomponents/transport.lua").BaseTransport

StructureUnit = import("/lua/defaultunits/structure.lua").StructureUnit
AirStagingPlatformUnit = import("/lua/defaultunits/airstagingplatform.lua").AirStagingPlatformUnit
ConcreteStructureUnit = import("/lua/defaultunits/concretestructure.lua").ConcreteStructureUnit
RadarUnit = import("/lua/defaultunits/radar.lua").RadarUnit
RadarJammerUnit = import("/lua/defaultunits/radarjammer.lua").RadarJammerUnit
SonarUnit = import("/lua/defaultunits/sonar.lua").SonarUnit

ShieldStructureUnit = import("/lua/defaultunits/shieldstructure.lua").ShieldStructureUnit
TransportBeaconUnit = import("/lua/defaultunits/transportbeacon.lua").TransportBeaconUnit
WallStructureUnit = import("/lua/defaultunits/wallstructure.lua").WallStructureUnit

FactoryUnit = import("/lua/defaultunits/factory.lua").FactoryUnit
AirFactoryUnit = import("/lua/defaultunits/airfactory.lua").AirFactoryUnit
LandFactoryUnit = import("/lua/defaultunits/landfactory.lua").LandFactoryUnit
SeaFactoryUnit = import("/lua/defaultunits/seafactory.lua").SeaFactoryUnit
QuantumGateUnit = import("/lua/defaultunits/quantumgate.lua").QuantumGateUnit

MassCollectionUnit = import("/lua/defaultunits/masscollection.lua").MassCollectionUnit
MassFabricationUnit = import("/lua/defaultunits/massfabrication.lua").MassFabricationUnit
MassStorageUnit = import("/lua/defaultunits/massstorage.lua").MassStorageUnit

EnergyCreationUnit = import("/lua/defaultunits/energycreation.lua").EnergyCreationUnit
EnergyStorageUnit = import("/lua/defaultunits/energystorage.lua").EnergyStorageUnit

MobileUnit = import("/lua/defaultunits/mobile.lua").MobileUnit
WalkingLandUnit = import("/lua/defaultunits/walkingland.lua").WalkingLandUnit
SubUnit = import("/lua/defaultunits/sub.lua").SubUnit
AirUnit = import("/lua/defaultunits/air.lua").AirUnit
LandUnit = import("/lua/defaultunits/land.lua").LandUnit
SeaUnit = import("/lua/defaultunits/sea.lua").SeaUnit
HoverLandUnit = import("/lua/defaultunits/hoverland.lua").HoverLandUnit
SlowHoverLandUnit = import("/lua/defaultunits/slowhoverland.lua").SlowHoverLandUnit
ConstructionUnit = import("/lua/defaultunits/construction.lua").ConstructionUnit
AmphibiousLandUnit = import("/lua/defaultunits/amphibiousland.lua").AmphibiousLandUnit
SlowAmphibiousLandUnit = import("/lua/defaultunits/slowamphibiousland.lua").SlowAmphibiousLandUnit
CommandUnit = import("/lua/defaultunits/command.lua").CommandUnit
ACUUnit = import("/lua/defaultunits/acu.lua").ACUUnit
AirTransport = import("/lua/defaultunits/airtransport.lua").AirTransport
AircraftCarrier = import("/lua/defaultunits/aircraftcarrier.lua").AircraftCarrier
ShieldHoverLandUnit = import("/lua/defaultunits/shieldhoverland.lua").ShieldHoverLandUnit
ShieldLandUnit = import("/lua/defaultunits/shieldland.lua").ShieldLandUnit
ShieldSeaUnit = import("/lua/defaultunits/shieldsea.lua").ShieldSeaUnit

ExternalFactoryUnit = import("/lua/defaultunits/externalfactory.lua").ExternalFactoryUnit

-------------------------------------------------------------------------------
--#region Backwards compatibility

local Entity = import("/lua/sim/entity.lua").Entity
local Unit = import("/lua/sim/unit.lua").Unit
local explosion = import("/lua/defaultexplosions.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local TerrainUtils = import("/lua/sim/terrainutils.lua")
local Buff = import("/lua/sim/buff.lua")
local AdjacencyBuffs = import("/lua/sim/adjacencybuffs.lua")
local FireState = import("/lua/game.lua").FireState
local ScenarioFramework = import("/lua/scenarioframework.lua")
local Quaternion = import("/lua/shared/quaternions.lua").Quaternion

local MathAbs = math.abs

local FactionToTarmacIndex = {
    UEF = 1,
    AEON = 2,
    CYBRAN = 3,
    SERAPHIM = 4,
    NOMADS = 5,
}

local GetTarmac = import("/lua/tarmacs.lua").GetTarmacType
local TreadComponent = import("/lua/defaultcomponents.lua").TreadComponent


local RolloffUnitTable = { nil }
local RolloffPositionTable = { 0, 0, 0 }

-- allows us to skip ai-specific functionality
local GameHasAIs = ScenarioInfo.GameHasAIs

-- compute once and store as upvalue for performance
local StructureUnitRotateTowardsEnemiesLand = categories.STRUCTURE + categories.LAND + categories.NAVAL
local StructureUnitRotateTowardsEnemiesArtillery = categories.ARTILLERY * (categories.TECH2 + categories.TECH3 + categories.EXPERIMENTAL)
local StructureUnitOnStartBeingBuiltRotateBuildings = categories.STRUCTURE * (categories.DIRECTFIRE + categories.INDIRECTFIRE) * (categories.DEFENSE + (categories.ARTILLERY - (categories.TECH3 + categories.EXPERIMENTAL)))

--#endregion