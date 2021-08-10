--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/TurtleExpansion.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'TurtleExpansion',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1SpeedUpgradeBuildersExpansions',
        'T2SpeedUpgradeBuildersExpansions',

        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',
        'EngineerFactoryConstructionLandHigherPriority',

        -- Build some power, but not much
        'EngineerEnergyBuildersExpansions',

        -- Build Mass low pri at this base
        'EngineerMassBuildersLowerPri',

        -- Engineer Support buildings
        'EngineeringSupportBuilder',

        -- ACU Builders
        'Default Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',

        -- ==== EXPANSION ==== --
        --DUNCAN - expansions dont build expansions!
        --'EngineerExpansionBuildersFull',
        --'EngineerFirebaseBuilders',

        -- ==== DEFENSES ==== --
        'T1BaseDefenses',
        'T2BaseDefenses',
        'T3BaseDefenses',

        'T1DefensivePoints',
        'T2DefensivePoints',
        'T3DefensivePoints',

        'T1DefensivePoints High Pri',
        'T2DefensivePoints High Pri',
        'T3DefensivePoints High Pri',

        'T1PerimeterDefenses',
        'T2PerimeterDefenses',
        'T3PerimeterDefenses',

        'T2Shields',
        'ShieldUpgrades',
        'T3Shields',

        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

        'MiscDefensesEngineerBuilders',

        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',

        -- ==== UNIT CAP BUILDERS ==== --
        'UnitCapAirAttackFormBuilders',
        'UnitCapLandAttackFormBuilders',

        -- ==== LAND UNIT BUILDERS ==== --
        'T1LandFactoryBuilders',
        'T2LandFactoryBuilders',
        'T3LandFactoryBuilders',
        'BigLandAttackFormBuilders',
        'MassHunterLandFormBuilders',
        'MiscLandFormBuilders',

        'T1LandAA',
        'T2LandAA',
        'T3LandResponseBuilders',

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

        -- ==== ARTILLERY BUILDERS ==== --
        'T3ArtilleryGroup',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',

        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',

        'RadarEngineerBuilders',
        'RadarUpgradeBuildersExpansion',

        'CounterIntelBuilders',

        'CybranOpticsEngineerBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 10,
            Tech2 = 6,
            Tech3 = 10,
            SCU = 4,
        },
        FactoryCount = {
            Land = 1,
            Air = 1,
            Sea = 0,
            Gate = 1,
        },
        MassToFactoryValues = {
            T1Value = 10,
            T2Value = 25,
            T3Value = 37.5,
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not(personality == 'adaptive' or personality == 'turtle') then
            return 0
        end

        local threatCutoff = 10 -- value of overall threat that determines where enemy bases are
        local distance = import('/lua/ai/AIUtilities.lua').GetThreatDistance(aiBrain, location, threatCutoff)
        if not distance or distance > 1000 then
            return 100
        elseif distance > 500 then
            return 75
        elseif distance > 250 then
            return 25
        else -- within 250
            return 10
        end

        return 1
    end,
}
