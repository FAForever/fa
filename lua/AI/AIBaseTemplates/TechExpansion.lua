--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/TechExpansion.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'TechExpansion',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T2SpeedUpgradeBuildersExpansions',
        'T2SpeedUpgradeBuildersExpansions',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstructionExpansion',
        'LandInitialFactoryConstruction',

        -- Build some power, but not much
        'EngineerEnergyBuildersExpansions',

        -- Build Mass low pri at this base
        'EngineerMassBuildersLowerPri',

        -- ==== EXPANSION ==== --
        --DUNCAN - expansions dont build more expansions!
        --'EngineerExpansionBuildersFull',
        --'EngineerExpansionBuildersSmall',

        -- ==== DEFENSES ==== --
        'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

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

        -- ==== EXPERIMENTALS ==== --
        'MobileLandExperimentalEngineers',
        'MobileLandExperimentalForm',

        'MobileAirExperimentalEngineers',
        'MobileAirExperimentalForm',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',

        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersExpansion',

        'CounterIntelBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 12,
            Tech2 = 8,
            Tech3 = 8,
            SCU = 2,
        },
        FactoryCount = {
            Land = 3, --DUNCAN - was 4
            Air = 1, --DUNCAN - was 2
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
        if markerType != 'Start Location' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'tech') then
            return 0
        end

        local threatCutoff = 10 -- value of overall threat that determines where enemy bases are
        local distance = import("/lua/ai/aiutilities.lua").GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 100
        elseif distance > 500 then
            return 75
        elseif distance > 250 then
            return 50
        else -- within 250
            return 10
        end

        return 1
    end,
}
