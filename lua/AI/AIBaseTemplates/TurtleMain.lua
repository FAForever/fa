--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/TurtleMain.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'TurtleMain',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1BalancedUpgradeBuilders',
        'T2BalancedUpgradeBuilders',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',

        -- Engineer Support buildings
        'EngineeringSupportBuilder',

        -- Build energy at this base
        'EngineerEnergyBuilders',

        -- Build Mass high pri at this base
        'EngineerMassBuildersHighPri',

        -- Extractors
        'Time Exempt Extractor Upgrades',

        -- ACU Builders
        'Default Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
        'ACUUpgrades - Tech 2 Engineering',
        'ACUUpgrades - Shields',

        -- ACU Defense
        'T1ACUDefenses',
        'T2ACUDefenses',
        'T2ACUShields',
        'T3ACUShields',
        'T3ACUNukeDefenses',

        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersFull',
        'EngineerExpansionBuildersSmall',
        'EngineerFirebaseBuilders',

        -- ==== DEFENSES ==== --
        'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        'T2MissileDefenses',
        'T2ArtilleryFormBuilders',

        'T1DefensivePoints',
        'T2DefensivePoints',
        'T3DefensivePoints',

        'T1PerimeterDefenses',
        'T2PerimeterDefenses',
        'T3PerimeterDefenses',

        'T1DefensivePoints High Pri',
        'T2DefensivePoints High Pri',
        'T3DefensivePoints High Pri',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        'MiscDefensesEngineerBuilders',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',

        -- ==== LAND UNIT BUILDERS ==== --
        'T1LandFactoryBuilders',
        'T2LandFactoryBuilders',
        'T3LandFactoryBuilders',
        'BigLandAttackFormBuilders',
        'MassHunterLandFormBuilders',
        'MiscLandFormBuilders',

        'T1LandAA',
        'T2LandAA',
        'T3LandResponseBuilders',

        'T1ReactionDF',
        'T2ReactionDF',
        'T3ReactionDF',

        -- ==== AIR UNIT BUILDERS ==== --
        'T1AirFactoryBuilders',
        'T2AirFactoryBuilders',
        'T3AirFactoryBuilders',
        'FrequentAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'ACUHunterAirFormBuilders',

        'TransportFactoryBuilders',

        'T1AntiAirBuilders',
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuilders',

        -- ==== UNIT CAP BUILDERS ==== --
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        -- ==== ARTILLERY BUILDERS ==== --
        'T3ArtilleryGroup',
        'T3ArtilleryFormBuilders',

        'ExperimentalArtillery',

        'NukeBuildersEngineerBuilders',
        'NukeFormBuilders',

        -- ==== EXPERIMENTALS ==== --
        'MobileLandExperimentalEngineers',
        'MobileLandExperimentalForm',

        'MobileAirExperimentalEngineers',
        'MobileAirExperimentalForm',

        'SatelliteExperimentalEngineers',
        'SatelliteExperimentalForm',

        'EconomicExperimentalEngineers',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',

        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersMain',

        'CounterIntelBuilders',

        'AeonOpticsEngineerBuilders',
        'CybranOpticsEngineerBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 25,
            SCU = 3,
        },
        FactoryCount = {
            --DUNCAN - was 3,1,0,1
            Land = 7,
            Air = 4,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 6, --10
            T2Value = 15, --25
            T3Value = 22.5, --37.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then return 1 end
        if per == 'random' then
            return Random(1, 100), 'turtle'
        elseif per != 'turtle' and per != 'adaptive' and per != '' then
            return 1, 'turtle'
        elseif per == 'turtle' then
            return 150, 'turtle'
        end

        local mapSizeX, mapSizeZ = GetMapSize()
        local isIsland = false
        local startX, startZ = aiBrain:GetArmyStartPos()
        local islandMarker = import("/lua/ai/aiutilities.lua").AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end
        --If we're playing on an island map,  use this plan
        if isIsland then
            return Random(50, 100), 'turtle'
        --If we're playing on a 256 map, do not turtle
        elseif mapSizeX < 500 and mapSizeZ < 500 then
            return 10, 'turtle'
        --If we're playing on a 512 map, possibly go rush, possibly go turtle
        elseif mapSizeX > 500 and mapSizeZ > 500 and mapSizeX < 1000 and mapSizeZ < 1000 then
            return 50, 'turtle'
        --If we're playing on a 1024 or bigger, turtling is best.
        elseif mapSizeX > 1000 and mapSizeZ > 1000 then
            return Random(60, 100), 'turtle'
        elseif mapSizeX > 2000 and mapSizeZ > 2000 then
            return Random(70, 100), 'turtle'
        end
    end,
}
