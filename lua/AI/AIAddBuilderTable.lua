--------------------------------------------------------------------------*
--
--  File     :  /lua/ai/AIAddBuilderTable.lua
--
--  Summary  : Default economic builders for skirmish
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

function AddGlobalBaseTemplate(aiBrain, locationType, baseBuilderName)
    if not BaseBuilderTemplates[baseBuilderName] then
        ERROR('*AI ERROR: Invalid BaseBuilderTemplate: none found named - ' .. baseBuilderName)
    end
    for k,v in BaseBuilderTemplates[baseBuilderName].Builders do
        AddGlobalBuilderGroup(aiBrain, locationType, v)
    end
    if (not aiBrain.CheatEnabled or (aiBrain.CheatEnabled and ScenarioInfo.Options.OmniCheat == 'off')) and BaseBuilderTemplates[baseBuilderName].NonCheatBuilders then
        for k,v in BaseBuilderTemplates[baseBuilderName].NonCheatBuilders do
            AddGlobalBuilderGroup(aiBrain, locationType, v)
        end
    end
    aiBrain.BuilderManagers[locationType].BaseSettings = BaseBuilderTemplates[baseBuilderName].BaseSettings
end

function AddGlobalBuilderGroup(aiBrain, locationType, builderGroupName)
    if BuilderGroups[builderGroupName] then
        AddBuilderTable(aiBrain, locationType, BuilderGroups[builderGroupName], builderGroupName)
    end
end

function AddBuilderTable(aiBrain, locationType, builderTable, tableName)
    aiBrain.BuilderManagers[locationType].BuilderHandles = aiBrain.BuilderManagers[locationType].BuilderHandles or {}
    aiBrain.BuilderManagers[locationType].BuilderHandles[tableName] = {}
    local builders = aiBrain.BuilderManagers[locationType].BuilderHandles[tableName]
    local managers = aiBrain.BuilderManagers[locationType]
    local tableType, builderFunction
    if builderTable.BuildersType == 'PlatoonFormBuilder' then
        tableType = 'PlatoonFormManager'
    elseif builderTable.BuildersType == 'EngineerBuilder' then
        tableType = 'EngineerManager'
    elseif builderTable.BuildersType == 'FactoryBuilder' then
        tableType = 'FactoryManager'
    elseif builderTable.BuildersType == 'StrategyBuilder' then
        tableType = 'StrategyManager'
    else
        error('*AI ERROR: Invalid BuildersType for table of builder to add to brain')
    end
    for k,v in builderTable do
        if k ~= 'BuildersType' and k ~= 'BuilderGroupName' then
            if type(v) ~= 'string' then
                error('*AI ERROR: Invalid builder type in BuilderGroup - ' .. tableName)
            end
            if not Builders[v] then
                WARN('*AI ERROR: Invalid Builder named - ' .. v)
            end
            table.insert(builders, managers[tableType]:AddBuilder(Builders[v], locationType))
        end
    end
end
