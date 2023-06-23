--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/RushExpansionAirSmall.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushExpansionAirSmall',
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
        'AirInitialFactoryConstruction',

        -- Build Mass low pri at this base
        'EngineerMassBuildersLowerPri',

        -- ==== UNIT CAP BUILDERS ==== --
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        -- ==== AIR UNIT BUILDERS ==== --
        'T1AirFactoryBuilders',
        'T2AirFactoryBuilders',
        'T3AirFactoryBuilders',
        'FrequentAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'ACUHunterAirFormBuilders',

        'T1AntiAirBuilders',
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 8,
            Tech2 = 8,
            Tech3 = 8,
            SCU = 1,
        },

        FactoryCount = {
            Land = 0, --DUNCAN - was 0
            Air = 3, --DUNCAN - was 5
            Sea = 0,
            Gate = 0,
        },

        MassToFactoryValues = {
            T1Value = 6.5,
            T2Value = 15,
            T3Value = 22.5
        },

        NoGuards = true,
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Expansion Area' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'rushair') then
            return 0
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

        return 1
    end,
}
