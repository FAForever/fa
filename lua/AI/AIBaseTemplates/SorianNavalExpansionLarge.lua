--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/SorianNavalExpansionSmall.lua
--**  Author(s): Michael Robbins aka Sorian
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianNavalExpansionLarge',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'SorianT1NavalUpgradeBuilders',
        'SorianT2NavalUpgradeBuilders',

        -- Pass engineers to main as needed
        --'Engineer Transfers',

        -- Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerNavalFactoryBuilder',

        -- Mass
        'SorianEngineerMassBuildersLowerPri',

        -- ==== EXPANSION ==== --
        'SorianEngineerExpansionBuildersFull',

        -- ==== DEFENSES ==== --
        'SorianT1NavalDefenses',
        'SorianT2NavalDefenses',
        'SorianT3NavalDefenses',

        -- ==== ATTACKS ==== --
        'SorianT1SeaFactoryBuilders',
        'SorianT2SeaFactoryBuilders',
        'SorianT3SeaFactoryBuilders',

        'SorianT2SeaStrikeForceBuilders',

        'SorianSeaHunterFormBuilders',
        'SorianBigSeaAttackFormBuilders',
        'SorianMassHunterSeaFormBuilders',

        -- ===== STRATEGIES ====== --

        'SorianParagonStrategyExp',

        -- == STRATEGY PLATOONS == --

        'SorianBalancedUpgradeBuildersExpansionStrategy',

        -- ==== NAVAL EXPANSION ==== --
        'SorianNavalExpansionBuildersFast',

        -- ==== EXPERIMENTALS ==== --
        --'SorianMobileNavalExperimentalEngineers',
        --'SorianMobileNavalExperimentalForm',
    },
    NonCheatBuilders = {
        'SorianSonarEngineerBuilders',
        'SorianSonarUpgradeBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 3,
            Tech2 = 3,
            Tech3 = 3,
            SCU = 0,
        },
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 2,
            Gate = 0,
        },
        MassToFactoryValues = {
            T1Value = 8, --6
            T2Value = 20, --15
            T3Value = 30, --22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if not aiBrain.Sorian then
            return -1
        end
        if markerType ~= 'Naval Area' then
            return 0
        end

        local isIsland = false
        local startX, startZ = aiBrain:GetArmyStartPos()
        local islandMarker = import('/lua/AI/AIUtilities.lua').AIGetClosestMarkerLocation(aiBrain, 'Island', startX, startZ)
        if islandMarker then
            isIsland = true
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        local base = ScenarioInfo.ArmySetup[aiBrain.Name].AIBase

        if personality == 'sorianadaptive' and base == 'SorianMainWater' then
            return 250
        end

        if personality == 'sorianwater' then
            return 200
        end

        return 0
    end,
}
