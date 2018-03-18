#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianNavalExpansionSmall.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianNavalExpansionSmall',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1BalancedUpgradeBuilders',
        'SorianT2BalancedUpgradeBuilders',

        # Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerNavalFactoryBuilder',

        # Mass
        'SorianEngineerMassBuildersLowerPri',

        # ==== EXPANSION ==== #
        'SorianEngineerExpansionBuildersFull',

        # ==== DEFENSES ==== #
        'SorianT1NavalDefenses',
        'SorianT2NavalDefenses',
        'SorianT3NavalDefenses',

        # ==== ATTACKS ==== #
        'SorianT1SeaFactoryBuilders',
        'SorianT2SeaFactoryBuilders',
        'SorianT3SeaFactoryBuilders',

        'SorianT2SeaStrikeForceBuilders',

        'SorianSeaHunterFormBuilders',
        'SorianFrequentSeaAttackFormBuilders',
        'SorianMassHunterSeaFormBuilders',

        # ===== STRATEGIES ====== #

        'SorianParagonStrategyExp',

        # == STRATEGY PLATOONS == #

        'SorianBalancedUpgradeBuildersExpansionStrategy',

        # ==== NAVAL EXPANSION ==== #
        'SorianNavalExpansionBuilders',

        # ==== EXPERIMENTALS ==== #
        #'SorianMobileNavalExperimentalEngineers',
        #'SorianMobileNavalExperimentalForm',
    },
    NonCheatBuilders = {
        'SorianSonarEngineerBuilders',
        'SorianSonarUpgradeBuildersSmall',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 1,
            Tech2 = 1,
            Tech3 = 1,
            SCU = 0,
        },
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 2,
            Gate = 0,
        },
        MassToFactoryValues = {
            T1Value = 6, #8
            T2Value = 15, #20
            T3Value = 22.5, #27.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if not aiBrain.Sorian then
            return 0
        end
        if markerType != 'Naval Area' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'sorian' or personality == 'sorianrush' or personality == 'sorianair' or personality == 'sorianturtle' or personality == 'sorianadaptive' then
            return 200
        end

        return 0
    end,
}
