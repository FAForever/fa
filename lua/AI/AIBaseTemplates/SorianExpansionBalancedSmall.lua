#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/SorianExpansionBalancedSmall.lua
#**  Author(s): Michael Robbins aka Sorian
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'SorianExpansionBalancedSmall',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'SorianT1BalancedUpgradeBuildersExpansion',
        'SorianT2BalancedUpgradeBuildersExpansion',
        'SorianEditSupportFactoryUpgrades',
        'SorianEditSupportFactoryUpgradesNAVY',

        # Engineer Builders
        'SorianEngineerFactoryBuilders',
        'SorianT1EngineerBuilders',
        'SorianT2EngineerBuilders',
        'SorianT3EngineerBuilders',
        'SorianEngineerFactoryConstruction',
        'SorianLandInitialFactoryConstruction',

        # SCU Upgrades
        'SorianSCUUpgrades',

        # Extractor building
        'SorianEngineerMassBuildersLowerPri - Rush',

        # Build some power, but not much
        'SorianEngineerEnergyBuildersExpansions',

        # ==== DEFENSES ==== #
        'SorianT1LightDefenses',
        'SorianT2LightDefenses',
        'SorianT3LightDefenses',

        'SorianT2ArtilleryFormBuilders',
        #'SorianT3ArtilleryFormBuilders',
        #'SorianT4ArtilleryFormBuilders',
        'SorianAirStagingExpansion',
        'SorianT2MissileDefenses',

        'SorianMassAdjacencyDefenses',

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
    },
    NonCheatBuilders = {
        'SorianLandScoutFactoryBuilders',
        'SorianLandScoutFormBuilders',

        'SorianRadarEngineerBuilders',
        'SorianRadarUpgradeBuildersExpansion',
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
            Air = 1,
            Sea = 0,
            Gate = 0,
        },

        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5,
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
        if not (personality == 'sorianrush' or personality == 'sorianadaptive') then
            return 0
        end

        local threatCutoff = 10 # value of overall threat that determines where enemy bases are
        local distance = import('/lua/ai/AIUtilities.lua').GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 500
        elseif distance > 500 then
            return 750
        elseif distance > 250 then
            return 1000
        else # within 250
            return 250
        end

        return 0
    end,
}
