--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/ChallengeMain.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'ChallengeMain',
    Builders = {
        -- ==== ECONOMY ==== --
        -- Factory upgrades
        'T1SlowUpgradeBuilders',
        'T2SlowUpgradeBuilders',
        
        -- Engineer Builders
        'EngineerFactoryBuilders',
        'T1EngineerBuilders',
        'T2EngineerBuilders',
        'T3EngineerBuilders',
        'EngineerFactoryConstruction',
        
        -- Engineer Support buildings
        'EngineeringSupportBuilder',
        
        -- Build energy at this base
        'EngineerEnergyBuilders',
        
        -- Build Mass low pri at this base
        'EngineerMassBuildersHighPri',
                
        -- Extractors
        'ExtractorUpgrades',

        -- ACU Builders
        'Easy Initial ACU Builders',
        'ACUBuilders',
        'ACUUpgrades',
                        
        -- ==== NAVAL EXPANSION ==== --
        'NavalExpansionBuilders',
        
        -- ==== EXPANSION ==== --
        'EngineerExpansionBuildersSmall',
        
        -- ==== DEFENSES ==== --
        'T3NukeDefenses',
        'T3NukeDefenseBehaviors',

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
        
        'TransportFactoryBuilders',
    },
    NonCheatBuilders = {
        'AirScoutFactoryBuilders',
        'AirScoutFormBuilders',
        
        'LandScoutFactoryBuilders',
        'LandScoutFormBuilders',
        
        'RadarEngineerBuilders',
        'RadarUpgradeBuildersMain',
        
        'CounterIntelBuilders',
    },
    BaseSettings = {
        FactoryCount = {
            Land = 4,
            Air = 2,
            Sea = 0,
            Gate = 1,
        },
        EngineerCount = {
            Tech1 = 8,
            Tech2 = 4,
            Tech3 = 6,
            SCU = 1,
        },
        MassToFactoryValues = {
            T1Value = 5,
            T2Value = 14,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
    FirstBaseFunction = function(aiBrain)
        local per = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if not per then return 1 end
        if per == 'medium' then
            return 150, 'medium'
        end
        return 1, 'medium'
    end,
}