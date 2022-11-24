--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/ChallengeExpansion.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'ChallengeExpansion',
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
        'EngineerFactoryConstructionExpansion',
        
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
    BaseSettings = {
        FactoryCount = {
            Land = 1,
            Air = 1,
            Sea = 0,
            Gate = 1,
        },
        EngineerCount = {
            Tech1 = 4,
            Tech2 = 2,
            Tech3 = 4,
            SCU = 1,
        },
        MassToFactoryValues = {
            T1Value = 6,
            T2Value = 15,
            T3Value = 22.5
        },
    },
    ExpansionFunction = function(aiBrain, location, markerType)
        if markerType != 'Expansion Area' then
            return 0
        end
        
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'medium' then
            return 100
        end
        
        return 0
    end,
}