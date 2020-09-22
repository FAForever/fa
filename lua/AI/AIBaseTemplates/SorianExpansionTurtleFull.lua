#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianExpansionTurtleFull.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianExpansionTurtleFull',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1BalancedUpgradeBuildersExpansion',
        'SorianT2BalancedUpgradeBuildersExpansion',
        'SorianSupportFactoryUpgrades',
        'SorianSupportFactoryUpgradesNAVY',

        # Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerFactoryConstruction',
        'SorianEngineerFactoryConstruction Balance',

        # SCU Upgrades
        'SorianSCUUpgrades',

        # Build Mass low pri at this base
        'SorianEngineerMassBuildersLowerPri',

        # Build some power, but not much
        'SorianEngineerEnergyBuildersExpansions',

        # ==== EXPANSION ==== #
        'SorianEngineerExpansionBuildersFull',
        'SorianEngineerExpansionBuildersSmall',

        # ==== DEFENSES ==== #
        'SorianT1LightDefenses',
        'SorianT2LightDefenses',
        'SorianT3LightDefenses',

        'SorianT2ArtilleryFormBuilders',
        'SorianT3ArtilleryFormBuilders',
        'SorianT4ArtilleryFormBuilders',
        'SorianT3NukeDefensesExp',
        'SorianT3NukeDefenseBehaviors',
        'SorianT2ShieldsExpansion',
        'SorianShieldUpgrades',
        'SorianT3ShieldsExpansion',
        'SorianAirStagingExpansion',
        'SorianT2MissileDefenses',

        'SorianMassAdjacencyDefenses',

        # ==== NAVAL EXPANSION ==== #
        'SorianNavalExpansionBuilders',

        # ==== LAND UNIT BUILDERS ==== #
        'SorianT1LandFactoryBuilders',
        'SorianT2LandFactoryBuilders',
        'SorianT3LandFactoryBuilders',
        'SorianFrequentLandAttackFormBuilders',
        'SorianMassHunterLandFormBuilders',
        'SorianMiscLandFormBuilders',
        'SorianUnitCapLandAttackFormBuilders',

        'SorianT1ReactionDF',
        'SorianT2ReactionDF',
        'SorianT3ReactionDF',

        # ==== AIR UNIT BUILDERS ==== #
        'SorianT1AirFactoryBuilders',
        'SorianT2AirFactoryBuilders',
        'SorianT3AirFactoryBuilders',
        'SorianFrequentAirAttackFormBuilders',
        'SorianMassHunterAirFormBuilders',

        'SorianUnitCapAirAttackFormBuilders',
        'SorianACUHunterAirFormBuilders',

        #'SorianTransportFactoryBuilders',

        'SorianExpResponseFormBuilders',

        'SorianT1AntiAirBuilders',
        'SorianT2AntiAirBuilders',
        'SorianT3AntiAirBuilders',
        'SorianBaseGuardAirFormBuilders',

        # ===== STRATEGIES ====== #

        'SorianParagonStrategyExp',
        'SorianWaterMapLowLand',

        # == STRATEGY PLATOONS == #

        'SorianBalancedUpgradeBuildersExpansionStrategy',

        # ==== EXPERIMENTALS ==== #
        'SorianMobileLandExperimentalEngineers',
        'SorianMobileLandExperimentalForm',

        'SorianMobileAirExperimentalEngineers',
        'SorianMobileAirExperimentalForm',

        # ==== ARTILLERY BUILDERS ==== #
        'SorianT3ArtilleryGroupExp',
    },
    NonCheatBuilders = {
        #'SorianAirScoutFactoryBuilders',
        #'SorianAirScoutFormBuilders',

        'SorianLandScoutFactoryBuilders',
        'SorianLandScoutFormBuilders',

        'SorianRadarEngineerBuilders',
        'SorianRadarUpgradeBuildersExpansion',

        'SorianCounterIntelBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 10,
            Tech2 = 15,
            Tech3 = 20,
            SCU = 2,
        },
        FactoryCount = {
            Land = 1,
            Air = 1,
            Sea = 0,
            Gate = 0, #1,
        },
        MassToFactoryValues = {
            T1Value = 6, #8
            T2Value = 15, #20
            T3Value = 22.5, #27.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if not aiBrain.Sorian then
            return -1
        end
        if markerType != 'Start Location' and markerType != 'Expansion Area' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not (personality == 'sorianturtle' or personality == 'sorianadaptive') then
            return 0
        end

        local threatCutoff = 10 # value of overall threat that determines where enemy bases are
        local distance = import('/lua/ai/AIUtilities.lua').GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 1000
        elseif distance > 500 then
            return 750
        elseif distance > 250 then
            return 250
        else # within 250
            return 100
        end

        return 0
    end,
}
