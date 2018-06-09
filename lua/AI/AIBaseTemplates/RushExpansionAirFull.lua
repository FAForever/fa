#***************************************************************************
#*
#**  File     :  /lua/ai/AIBaseTemplates/RushExpansionAirFull.lua
#**
#**  Summary  : Manage engineers for a location
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'RushExpansionAirFull',
    Builders = {
        # ==== ECONOMY ==== #
        # Factory upgrades
        'T1BalancedUpgradeBuildersExpansion',
        'T2BalancedUpgradeBuildersExpansion',

        # Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',
        'EngineerFactoryConstructionAirHigherPriority',
        'AirInitialFactoryConstruction',

        # Build Mass low pri at this base
        'EngineerMassBuildersLowerPri',

        # Build some power, but not much
        'EngineerEnergyBuildersExpansions',

        # ==== EXPANSION ==== #
        #DUNCAN - expansions dont build more expansions!
        #'EngineerExpansionBuildersFull',
        #'EngineerExpansionBuildersSmall',

        # ==== DEFENSES ==== #
        'T1LightDefenses',
        'T2LightDefenses',
        'T3LightDefenses',

        'T2MissileDefenses',
        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        'MiscDefensesEngineerBuilders',

        # ==== NAVAL EXPANSION ==== #
        'NavalExpansionBuilders',

        # ==== LAND UNIT BUILDERS ==== #
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

        # ==== UNIT CAP BUILDERS ==== #
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        # ==== AIR UNIT BUILDERS ==== #
        'T1AirFactoryBuilders',
        'T2AirFactoryBuilders',
        'T3AirFactoryBuilders',
        'BigAirAttackFormBuilders',
        'MassHunterAirFormBuilders',

        'ACUHunterAirFormBuilders',

        #'TransportFactoryBuilders', #DUNCAN - taked out

        'T1AntiAirBuilders',
        'T2AntiAirBuilders',
        'T3AntiAirBuilders',
        'BaseGuardAirFormBuilders',

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
        FactoryCount = {
            Land = 1, #DUNCAN - was 1
            Air = 3, #DUNCAN - was 4
            Sea = 0,
            Gate = 0,
        },
        EngineerCount = {
            Tech1 = 15,
            Tech2 = 10,
            Tech3 = 10,
            SCU = 1,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Start Location' then
            return 0
        end

        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'rushair') then
            return 0
        end

        local threatCutoff = 10 # value of overall threat that determines where enemy bases are
        local distance = import('/lua/ai/AIUtilities.lua').GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 75
        elseif distance > 500 then
            return 100
        elseif distance > 250 then
            return 50
        else # within 250
            return 10
        end

        return 0
    end,
}
