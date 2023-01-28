--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/NavalExpansionLarge.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'NavalExpansionLarge',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1NavalUpgradeBuilders',
        'T2NavalUpgradeBuilders',

        -- Pass engineers to main as needed
        'Engineer Transfers',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerNavalFactoryBuilder',

        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersFull - Naval',

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

        -- ==== EXPERIMENTALS ==== --
        'MobileNavalExperimentalEngineers',
        'MobileNavalExperimentalForm',
    },
    NonCheatBuilders = {
        'SonarEngineerBuilders',
        'SonarUpgradeBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 0,
            Tech2 = 2, --DUNCAN - was 5
            Tech3 = 2, --DUNCAN - was 5
            SCU = 0,
        },
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 6, --DUNCAN - was 12!
            Gate = 0,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Naval Area' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'rushnaval' or personality == 'adaptive' then
            return 100
        end

        return 1
    end,
}
