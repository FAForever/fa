--***************************************************************************
--*
--**  File     :  /lua/ai/AIBaseTemplates/ChallengeExpansion.lua
--**
--**  Summary  : Manage engineers for a location
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

BaseBuilderTemplate {
    BaseTemplateName = 'EasyMain',
    Builders = {
        "EasyEngineerFactoryBuilders",
        "EasyEngineerExtractorBuilders",
        "EasyEngineerPowerBuilders",
        "EasyFactoryUnitBuilders",
    },
    BaseSettings = {
        FactoryCount = {
            Land = 10,
            Air = 10,
            Sea = 10,
            Gate = 10,
        },
        EngineerCount = {
            Tech1 = 10,
            Tech2 = 10,
            Tech3 = 10,
            SCU = 10,
        },
    },
    FirstBaseFunction = function(aiBrain, location, markerType)
        WARN("FirstBaseFunction!")
        local personality = ScenarioInfo.ArmySetup[aiBrain.Name].AIPersonality
        if personality == 'easy' then
            return 200, 'easy'
        end

        return 0
    end,
    ExpansionFunction = function(aiBrain, location, markerType)
        return 0
    end,
}