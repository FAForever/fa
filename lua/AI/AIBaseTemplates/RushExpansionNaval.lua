--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushExpansionNaval.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushExpansionNaval',
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
        'EngineerFactoryConstruction',

        -- Build Mass high pri at this base
        'EngineerMassBuildersLowerPri',

        -- Extractors
        'Time Exempt Extractor Upgrades Expansion',

        -- ==== DEFENSES ==== --
        'T2MissileDefenses',
        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders HighPri',

        -- ==== LAND UNIT BUILDERS ==== --
        'T2LandFactoryAmphibiousBuilders', --DUNCAN - added
        'T3LandFactoryBuilders',

        'FrequentLandAttackFormBuilders',
        'MassHunterLandFormBuilders',
        'MiscLandFormBuilders',
        'UnitCapLandAttackFormBuilders',

        'T1LandAA',
        'T2LandAA',
        'T3LandResponseBuilders',

        'T1ReactionDF',
        'T2ReactionDF',
        'T3ReactionDF',

        -- ==== AIR UNIT BUILDERS ==== --
        --'T1AirFactoryBuilders',
        --'T2AirFactoryBuilders',
        --'T3AirFactoryBuilders',
        --'FrequentAirAttackFormBuilders',
        --'MassHunterAirFormBuilders',

        'UnitCapAirAttackFormBuilders',
        'ACUHunterAirFormBuilders',

        'TransportFactoryBuilders',

        'T1AntiAirBuilders',
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuildersNaval',

        -- ==== EXPERIMENTALS ==== --
        'MobileAirExperimentalEngineers',
        'MobileAirExperimentalForm',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',

        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersMain',

        'CounterIntelBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 10,
            SCU = 2,
        },
        FactoryCount = {
            Land = 1,
            Air = 0,
            Sea = 0,
            Gate = 0,
        },
        MassToFactoryValues = {
            T1Value = 8,
            T2Value = 20,
            T3Value = 30,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Start Location' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'rushnaval') then
            return 0
        end

        if personality == 'rushnaval' then
            return 100
        end

        local threatCutoff = 10 -- value of overall threat that determines where enemy bases are
        local distance = import("/lua/ai/aiutilities.lua").GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 75
        elseif distance > 500 then
            return 100
        elseif distance > 250 then
            return 50
        else -- within 250
            return 10
        end

        return 0
    end,
}
