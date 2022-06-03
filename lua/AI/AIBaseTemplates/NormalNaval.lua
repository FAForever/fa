--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/NormalNaval.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'NormalNaval',
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
        'EngineerNavalFactoryBuilder',
        
        -- Mass
        'EngineerMassBuildersLowerPri',
        
        -- ==== ATTACKS ==== --
        'T1SeaFactoryBuilders',
        'T2SeaFactoryBuilders',
        'T3SeaFactoryBuilders',
        'FrequentSeaAttackFormBuilders',
        'MassHunterSeaFormBuilders',
    },
    NonCheatBuilders = {
        'SonarEngineerBuilders',
        'SonarUpgradeBuilders',
    },
    BaseSettings = {
        EngineerCount = {
            Tech1 = 2,
            Tech2 = 1,
            Tech3 = 2,
            SCU = 0,
        },
        FactoryCount = {
            Land = 0,
            Air = 0,
            Sea = 1,
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
        if personality == 'easy' then
            return 100
        end
        
        return 0
    end,
}