--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushMainLand.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SetonsCustom',
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
        'Land Rush Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
        'ACUUpgrades - Gun improvements',
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
        --'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        'T2MissileDefenses',
        'T2ArtilleryFormBuilders',

        --'T1DefensivePoints',
        --'T2DefensivePoints',
        --'T3DefensivePoints',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        --'MiscDefensesEngineerBuilders',

        -- ==== NAVAL EXPANSION ==== --
        --'NavalExpansionBuilders', --DUNCAN - commented out for setons

        -- ==== LAND UNIT BUILDERS ==== --
        'T1LandFactoryBuilders',
        'T2LandFactoryBuilders',
        'T3LandFactoryBuilders',

        'FrequentLandAttackFormBuilders',
        'MassHunterLandFormBuilders',
        --'MiscLandFormBuilders', --DUNCAN - commented out for setons

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
            --DUNCAN - was 15, 10, 10, 1
            Tech1 = 25,
            Tech2 = 10,
            Tech3 = 25,
            SCU = 1,
        },
        FactoryCount = {
            --DUNCAN - Factory number tweaks, was 5, 1, 0, 1
            Land = 8,
            Air = 2,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 5,
            T2Value = 14,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then
           return 0, 'setons'
        end

        if (per == 'rush' or per == 'adaptive') and ScenarioInfo.name == 'Seton\'s Clutch' then
            return 1000, 'setons'
        end

        return 0, 'setons'
    end,
}
