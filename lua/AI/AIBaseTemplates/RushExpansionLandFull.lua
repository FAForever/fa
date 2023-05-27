--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushExpansionLandFull.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushExpansionLandFull',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1BalancedUpgradeBuildersExpansion',
        'T2BalancedUpgradeBuildersExpansion',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstructionExpansion',
        'LandInitialFactoryConstruction',

        -- Build Mass low pri at this base
        'EngineerMassBuildersLowerPri',

        -- Build some power, but not much
        'EngineerEnergyBuildersExpansions',

        -- ==== DEFENSES ==== --
        'T1LightDefenses',
        'T2LightDefenses',
        'T3LightDefenses',

        'T2MissileDefenses',
        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        -- Extractors
        'Time Exempt Extractor Upgrades Expansion',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',

        -- ==== UNIT CAP BUILDERS ==== --
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

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
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 10,
            SCU = 1,
        },
        FactoryCount = {
            Land = 4,
            Air = 2,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 6.5,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Start Location' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'rushland') then
            return 0
        end

        local threatCutoff = 10 -- value of overall threat that determines where enemy bases are
        local distance = import("/lua/ai/aiutilities.lua").GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 10
        elseif distance > 500 then
            return 25
        elseif distance > 250 then
            return 50
        else
            return 100
        end

        return 1
    end,
}
