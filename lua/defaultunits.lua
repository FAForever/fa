-----------------------------------------------------------------
-- File     :  /lua/defaultunits.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Default definitions of units
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

BaseTransport = import("/lua/sim/units/components/transportunitcomponent.lua").BaseTransport

StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
AirStagingPlatformUnit = import("/lua/sim/units/airstagingplatformunit.lua").AirStagingPlatformUnit
ConcreteStructureUnit = import("/lua/sim/units/concretestructureunit.lua").ConcreteStructureUnit
RadarUnit = import("/lua/sim/units/radarunit.lua").RadarUnit
RadarJammerUnit = import("/lua/sim/units/radarjammerunit.lua").RadarJammerUnit
SonarUnit = import("/lua/sim/units/sonarunit.lua").SonarUnit

ShieldStructureUnit = import("/lua/sim/units/shieldstructureunit.lua").ShieldStructureUnit
TransportBeaconUnit = import("/lua/sim/units/transportbeaconunit.lua").TransportBeaconUnit
WallStructureUnit = import("/lua/sim/units/wallstructureunit.lua").WallStructureUnit

FactoryUnit = import("/lua/sim/units/factoryunit.lua").FactoryUnit
AirFactoryUnit = import("/lua/sim/units/airfactoryunit.lua").AirFactoryUnit
LandFactoryUnit = import("/lua/sim/units/landfactoryunit.lua").LandFactoryUnit
SeaFactoryUnit = import("/lua/sim/units/seafactoryunit.lua").SeaFactoryUnit
QuantumGateUnit = import("/lua/sim/units/quantumgateunit.lua").QuantumGateUnit

MassCollectionUnit = import("/lua/sim/units/masscollectionunit.lua").MassCollectionUnit
MassFabricationUnit = import("/lua/sim/units/massfabricationunit.lua").MassFabricationUnit
MassStorageUnit = import("/lua/sim/units/massstorageunit.lua").MassStorageUnit

EnergyCreationUnit = import("/lua/sim/units/energycreationunit.lua").EnergyCreationUnit
EnergyStorageUnit = import("/lua/sim/units/energystorageunit.lua").EnergyStorageUnit

MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit
WalkingLandUnit = import("/lua/sim/units/walkinglandunit.lua").WalkingLandUnit
SubUnit = import("/lua/sim/units/subunit.lua").SubUnit
AirUnit = import("/lua/sim/units/airunit.lua").AirUnit
LandUnit = import("/lua/sim/units/landunit.lua").LandUnit
SeaUnit = import("/lua/sim/units/seaunit.lua").SeaUnit
HoverLandUnit = import("/lua/sim/units/hoverlandunit.lua").HoverLandUnit
SlowHoverLandUnit = import("/lua/sim/units/slowhoverlandunit.lua").SlowHoverLandUnit
ConstructionUnit = import("/lua/sim/units/constructionunit.lua").ConstructionUnit
AmphibiousLandUnit = import("/lua/sim/units/amphibiouslandunit.lua").AmphibiousLandUnit
SlowAmphibiousLandUnit = import("/lua/sim/units/slowamphibiouslandunit.lua").SlowAmphibiousLandUnit
CommandUnit = import("/lua/sim/units/commandunit.lua").CommandUnit
ACUUnit = import("/lua/sim/units/acuunit.lua").ACUUnit
AirTransport = import("/lua/sim/units/airtransportunit.lua").AirTransport
AircraftCarrier = import("/lua/sim/units/aircraftcarrierunit.lua").AircraftCarrier
ShieldHoverLandUnit = import("/lua/sim/units/shieldhoverlandunit.lua").ShieldHoverLandUnit
ShieldLandUnit = import("/lua/sim/units/shieldlandunit.lua").ShieldLandUnit
ShieldSeaUnit = import("/lua/sim/units/shieldseaunit.lua").ShieldSeaUnit

ExternalFactoryUnit = import("/lua/sim/units/externalfactoryunit.lua").ExternalFactoryUnit

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
