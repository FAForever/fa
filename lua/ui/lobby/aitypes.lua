--*****************************************************************************
--* File: lua/modules/ui/lobby/aitypes.lua
--* Author: Chris Blackwell
--* Summary: Contains a list of AI types and names for the game
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

function GetAItypes()
    --Table of AI Names to return
    local aitypes = {
        {
            key = 'easy',
            name = "<LOC lobui_0347>AI: Easy",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'medium',
            name = "<LOC lobui_0349>AI: Normal",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'adaptive',
            name = "<LOC lobui_0368>AI: Adaptive",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'rush',
            name = "<LOC lobui_0360>AI: Rush",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'turtle',
            name = "<LOC lobui_0372>AI: Turtle",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'tech',
            name = "<LOC lobui_0370>AI: Tech",
            requiresNavMesh = true,
            baseAI = true,
        },
        {
            key = 'random',
            name = "<LOC lobui_0374>AI: Random",
            requiresNavMesh = true,
            baseAI = true,
        }
    }

    --Default GPG AIs

    local AIFiles = DiskFindFiles('/lua/AI/CustomAIs_v2', '*.lua')
    local AIFilesold = DiskFindFiles('/lua/AI/CustomAIs', '*.lua')

    --Load Custom AIs - old style
    for i, v in AIFilesold do
        local tempfile = import(v).AIList
        for s, t in tempfile do
            table.insert(aitypes, t)
        end
    end

    --Load Custom AIs
    for i, v in AIFiles do
        local tempfile = import(v).AI
        if tempfile.AIList then
            for s, t in tempfile.AIList do
                table.insert(aitypes, t)
            end
        end
    end

    --Load Custom AIs from Moddirectory
    local CustomAIfile
    local ModAIFiles
    -- get all sim mods installed in /mods/
    local simMods = import("/lua/mods.lua").GetGameMods()
    -- loop over all installed mods
    for Index, ModData in simMods do
        -- check if we have a CustomAIs_v2 folder (then we have an AI mod)
        if exists(ModData.location..'/lua/AI/CustomAIs_v2') then
            -- get all AI files from CustomAIs_v2 folder
            ModAIFiles = DiskFindFiles(ModData.location..'/lua/AI/CustomAIs_v2', '*.lua')
            -- check, if we have found at least 1 file
            if ModAIFiles[1] then
                -- loop over all AI files
                for i, v in ModAIFiles do
                    -- load AI data from file, stored in table AI
                    CustomAIfile = import(v).AI
                    -- Check if we have a table with normal AIs (table AIList)
                    if CustomAIfile.AIList then
                        -- insert every AI into aitypes
                        for s, t in CustomAIfile.AIList do
                            table.insert(aitypes, t)
                        end
                    end
                end
            end
        end
    end

    --Default GPG Cheating AIs
    table.insert(aitypes, { key = 'adaptivecheat', name = "<LOC lobui_0379>AIx: Adaptive", requiresNavMesh = true, baseAI = true })
    table.insert(aitypes, { key = 'rushcheat', name = "<LOC lobui_0380>AIx: Rush", requiresNavMesh = true, baseAI = true })
    table.insert(aitypes, { key = 'turtlecheat', name = "<LOC lobui_0384>AIx: Turtle", requiresNavMesh = true,  baseAI = true})
    table.insert(aitypes, { key = 'techcheat', name = "<LOC lobui_0385>AIx: Tech", requiresNavMesh = true, baseAI = true })
    table.insert(aitypes, { key = 'randomcheat', name = "<LOC lobui_0395>AIx: Random", requiresNavMesh = true, baseAI = true })

    --Load Custom Cheating AIs - old style
    for i, v in AIFilesold do
        local tempfile = import(v).CheatAIList
        for s, t in tempfile do
            table.insert(aitypes, t)
        end
    end

    --Load Custom Cheating AIs
    for i, v in AIFiles do
        local tempfile = import(v).AI
        if tempfile.CheatAIList then
            for s, t in tempfile.CheatAIList do
                table.insert(aitypes, t)
            end
        end
    end

    --Load Custom Cheating AIs from Moddirectory
    ModAIFiles = false
    -- loop over all installed mods
    for Index, ModData in simMods do
        -- check if we have a CustomAIs_v2 folder (then we have an AI mod)
        if exists(ModData.location..'/lua/AI/CustomAIs_v2') then
            -- get all AI files from CustomAIs_v2 folder
            ModAIFiles = DiskFindFiles(ModData.location..'/lua/AI/CustomAIs_v2', '*.lua')
            -- check, if we have found at least 1 file
            if ModAIFiles[1] then
                -- loop over all AI files
                for i, v in ModAIFiles do
                    -- load AI data from file, stored in table AI
                    CustomAIfile = import(v).AI
                    -- Check if we have a table with cheating AIs (table CheatAIList)
                    if CustomAIfile.CheatAIList then
                        -- insert every AI into aitypes
                        for s, t in CustomAIfile.CheatAIList do
                            table.insert(aitypes, t)
                        end
                    end
                end
            end
        end
    end

    return aitypes
end

-- Uveso - aitypes are now available as function. This old table version is for hook compatibility.
aitypes = (function()
    local aitypes = GetAItypes()
    return aitypes
end)()
