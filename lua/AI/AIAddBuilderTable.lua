--***************************************************************************
--**  File     :  /lua/ai/AIAddBuilderTable.lua
--**
--**  Summary  : Default economic builders for skirmish
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@param aiBrain AIBrain
---@param locationType string
---@param baseBuilderName string
function AddGlobalBaseTemplate(aiBrain, locationType, baseBuilderName)
    if not BaseBuilderTemplates[baseBuilderName] then
        error('*AI ERROR: Invalid BaseBuilderTemplate: none found named - ' .. baseBuilderName)
    end

    --SPEW('*AI DEBUG: AddGlobalBaseTemplate(): Loading Base Template '..repr(baseBuilderName))
    for k,v in BaseBuilderTemplates[baseBuilderName].Builders do
        AddGlobalBuilderGroup(aiBrain, locationType, v)
    end
    -- Cheating AI's don't have always OmniView, so we build NonCheaterBuilders for all AI's.
    -- (OmniView is an ACU enhancement. If you lose your ACU, you will also lose OmniView.)
    -- Also we don't need to save resources for cheat AI's since we can simply increase the AI Cheatfactor in options.
    if BaseBuilderTemplates[baseBuilderName].NonCheatBuilders then
        for k,v in BaseBuilderTemplates[baseBuilderName].NonCheatBuilders do
            AddGlobalBuilderGroup(aiBrain, locationType, v)
        end
    end
    aiBrain.BuilderManagers[locationType].BaseSettings = BaseBuilderTemplates[baseBuilderName].BaseSettings
end

---@param aiBrain AIBrain
---@param locationType string
---@param builderGroupName string
function AddGlobalBuilderGroup(aiBrain, locationType, builderGroupName)
    if BuilderGroups[builderGroupName] then
        AddBuilderTable(aiBrain, locationType, BuilderGroups[builderGroupName], builderGroupName)
    else
        WARN('['..string.gsub(debug.getinfo(1).source, ".*\\(.*.lua)", "%1")..', line:'..debug.getinfo(1).currentline..'] *AddGlobalBuilderGroup ERROR: BuilderGroup ' .. repr(builderGroupName) .. ' does not exist!' )
    end
end

---@param aiBrain AIBrain
---@param locationType string
---@param builderTable table
---@param tableName string
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
    elseif builderTable.BuildersType == 'StrategyBuilder' and managers.StrategyManager then
        tableType = 'StrategyManager'
    else
        WARN('*AI ERROR: Invalid BuildersType ('..repr(builderTable.BuildersType)..') for table of builder to add to brain')
        return
    end

    for k,v in builderTable do
        if k != 'BuildersType' and k != 'BuilderGroupName' then
            if type(v) != 'string' then
                error('*AI ERROR: Invalid builder type in BuilderGroup - ' .. tableName)
            end
            if not Builders[v] then
                WARN('*AI ERROR: Invalid Builder named - ' .. v)
            end
            table.insert(builders, managers[tableType]:AddBuilder(Builders[v], locationType))
        end
    end
end
