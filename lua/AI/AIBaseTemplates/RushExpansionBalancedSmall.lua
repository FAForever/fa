--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushExpansionBalancedSmall.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushExpansionBalancedSmall',
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

        -- Extractor building
        'EngineerMassBuildersLowerPri',

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
    },
    NonCheatBuilders = {
        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersExpansion',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 8,
            Tech2 = 8,
            Tech3 = 8,
            SCU = 1,
        },

        FactoryCount = {
            Land = 3,
            Air = 1,
            Sea = 0,
            Gate = 1,
        },

        MassToFactoryValues = {
            T1Value = 6.5,
            T2Value = 15,
            T3Value = 22.5
        },

        NoGuards = true,
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Expansion Area' then --DUNCAN - was Start Location
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'rushbalanced') then
            return 0
        end

        local threatCutoff = 10 -- value of overall threat that determines where enemy bases are
        local distance = import("/lua/ai/aiutilities.lua").GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 50
        elseif distance > 500 then
            return 75
        elseif distance > 250 then
            return 100
        else -- within 250
            return 25
        end

        return 1
    end,
}
