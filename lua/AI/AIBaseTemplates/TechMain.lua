--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/TechMain.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'TechMain',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1SpeedUpgradeBuilders',
        'T2SpeedUpgradeBuilders',

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
        --'EngineerFirebaseBuilders',

        -- ==== DEFENSES ==== --
        'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        --'T2MissileDefenses',
        'T2ArtilleryFormBuilders',

        'T1DefensivePoints',
        'T2DefensivePoints',
        'T3DefensivePoints',

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

        'FrequentLandAttackFormBuilders',
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
            SCU = 4,
        },
        FactoryCount = {
            --DUNCAN - Factory number tweaks, was 3, 3, 0, 1
            Land = 4,
            Air = 5,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 10,
            T2Value = 25,
            T3Value = 32.5,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then return 1 end
        if per == 'random' then
            return Random(1, 100), 'tech'
        elseif per != 'tech' and per != 'adaptive' and per != '' then
            return 1, 'tech'
        end

        local mapSizeX, mapSizeZ = GetMapSize()
        local startX, startZ = aiBrain:GetArmyStartPos()

        --If we're playing on a 256 map
        if mapSizeX < 500 and mapSizeZ < 500 then
            return 10, 'tech'
        --If we're playing on a 512 map
        elseif mapSizeX > 500 and mapSizeZ > 500 and mapSizeX < 1000 and mapSizeZ < 1000 then
            return Random(50, 75), 'tech'
        --If we're playing on a 1024 or bigger
        elseif mapSizeX > 1000 and mapSizeZ > 1000 then
            return Random(65, 100), 'tech'
        elseif mapSizeX > 2000 and mapSizeZ > 2000 then
            return Random(80, 100), 'tech'
        end
    end,
}
