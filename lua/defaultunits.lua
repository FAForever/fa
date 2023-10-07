-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

BaseTransport = import("/lua/sim/defaultunitcomponents/transportunitcomponent.lua").BaseTransport

StructureUnit = import("/lua/sim/defaultunits/structureunit.lua").StructureUnit
AirStagingPlatformUnit = import("/lua/sim/defaultunits/airstagingplatformunit.lua").AirStagingPlatformUnit
ConcreteStructureUnit = import("/lua/sim/defaultunits/concretestructureunit.lua").ConcreteStructureUnit
RadarUnit = import("/lua/sim/defaultunits/radarunit.lua").RadarUnit
RadarJammerUnit = import("/lua/sim/defaultunits/radarjammerunit.lua").RadarJammerUnit
SonarUnit = import("/lua/sim/defaultunits/sonarunit.lua").SonarUnit

ShieldStructureUnit = import("/lua/sim/defaultunits/shieldstructureunit.lua").ShieldStructureUnit
TransportBeaconUnit = import("/lua/sim/defaultunits/transportbeaconunit.lua").TransportBeaconUnit
WallStructureUnit = import("/lua/sim/defaultunits/wallstructureunit.lua").WallStructureUnit

FactoryUnit = import("/lua/sim/defaultunits/factoryunit.lua").FactoryUnit
AirFactoryUnit = import("/lua/sim/defaultunits/airfactoryunit.lua").AirFactoryUnit
LandFactoryUnit = import("/lua/sim/defaultunits/landfactoryunit.lua").LandFactoryUnit
SeaFactoryUnit = import("/lua/sim/defaultunits/seafactoryunit.lua").SeaFactoryUnit
QuantumGateUnit = import("/lua/sim/defaultunits/quantumgateunit.lua").QuantumGateUnit

MassCollectionUnit = import("/lua/sim/defaultunits/masscollectionunit.lua").MassCollectionUnit
MassFabricationUnit = import("/lua/sim/defaultunits/massfabricationunit.lua").MassFabricationUnit
MassStorageUnit = import("/lua/sim/defaultunits/massstorageunit.lua").MassStorageUnit

EnergyCreationUnit = import("/lua/sim/defaultunits/energycreationunit.lua").EnergyCreationUnit
EnergyStorageUnit = import("/lua/sim/defaultunits/energystorageunit.lua").EnergyStorageUnit

MobileUnit = import("/lua/sim/defaultunits/mobileunit.lua").MobileUnit
WalkingLandUnit = import("/lua/sim/defaultunits/walkinglandunit.lua").WalkingLandUnit
SubUnit = import("/lua/sim/defaultunits/subunit.lua").SubUnit
AirUnit = import("/lua/sim/defaultunits/airunit.lua").AirUnit
LandUnit = import("/lua/sim/defaultunits/landunit.lua").LandUnit
SeaUnit = import("/lua/sim/defaultunits/seaunit.lua").SeaUnit
HoverLandUnit = import("/lua/sim/defaultunits/hoverlandunit.lua").HoverLandUnit
SlowHoverLandUnit = import("/lua/sim/defaultunits/slowhoverlandunit.lua").SlowHoverLandUnit
ConstructionUnit = import("/lua/sim/defaultunits/constructionunit.lua").ConstructionUnit
AmphibiousLandUnit = import("/lua/sim/defaultunits/amphibiouslandunit.lua").AmphibiousLandUnit
SlowAmphibiousLandUnit = import("/lua/sim/defaultunits/slowamphibiouslandunit.lua").SlowAmphibiousLandUnit
CommandUnit = import("/lua/sim/defaultunits/commandunit.lua").CommandUnit
ACUUnit = import("/lua/sim/defaultunits/acuunit.lua").ACUUnit
AirTransport = import("/lua/sim/defaultunits/airtransportunit.lua").AirTransport
AircraftCarrier = import("/lua/sim/defaultunits/aircraftcarrierunit.lua").AircraftCarrier
ShieldHoverLandUnit = import("/lua/sim/defaultunits/shieldhoverlandunit.lua").ShieldHoverLandUnit
ShieldLandUnit = import("/lua/sim/defaultunits/shieldlandunit.lua").ShieldLandUnit
ShieldSeaUnit = import("/lua/sim/defaultunits/shieldseaunit.lua").ShieldSeaUnit

ExternalFactoryUnit = import("/lua/sim/defaultunits/externalfactoryunit.lua").ExternalFactoryUnit

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
