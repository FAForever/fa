--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/NavalExpansionSmall.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'NavalExpansionSmall',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1BalancedUpgradeBuilders',
        'T2BalancedUpgradeBuilders',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        --DUNCAN - Commented out
        --'T2EngineerBuilders',
        --'T3EngineerBuilders',
        'EngineerNavalFactoryBuilder',

        -- Mass
        'EngineerMassBuildersLowerPri',

        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersFull',

        -- ==== DEFENSES ==== --
        'T1NavalDefenses',
        'T2NavalDefenses',
        'T3NavalDefenses',

        -- ==== ATTACKS ==== --
        'T1SeaFactoryBuilders',
        'T2SeaFactoryBuilders',
        'T3SeaFactoryBuilders',
        'FrequentSeaAttackFormBuilders',
        'MassHunterSeaFormBuilders',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',
    },
    NonCheatBuilders = {
        'SonarEngineerBuilders',
        'SonarUpgradeBuildersSmall',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 2, --DUNCAN - was 5
            Tech2 = 1, --DUNCAN - was 5
            Tech3 = 1, --DUNCAN - was 5
            SCU = 0,
        },
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 3,
            Gate = 0,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Naval Area' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not (personality == 'easy' or personality == 'medium') then
            return 50
        end

        return 1
    end,
}
