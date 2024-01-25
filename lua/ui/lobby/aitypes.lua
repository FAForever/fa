--*****************************************************************************
--* File: lua/modules/ui/lobby/aitypes.lua
--* Author: Chris Blackwell
--* Summary: Contains a list of AI types and names for the game
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

---@class AILobbyProperties
---@field key string
---@field name string
---@field rating number
---@field ratingCheatMultiplier number
---@field ratingBuildMultiplier number
---@field ratingMapAbsolute number[]
---@field ratingMapMultiplier number[]

function GetAItypes()
    --Table of AI Names to return
    local aitypes = {
        {
            key = 'easy',
            name = "<LOC lobui_0347>AI: Easy",

            rating = 300,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'medium',
            name = "<LOC lobui_0349>AI: Normal",

            rating = 450,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'adaptive',
            name = "<LOC lobui_0368>AI: Adaptive",

            rating = 600,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'rush',
            name = "<LOC lobui_0360>AI: Rush",

            rating = 600,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'turtle',
            name = "<LOC lobui_0372>AI: Turtle",

            rating = 600,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'tech',
            name = "<LOC lobui_0370>AI: Tech",

            rating = 600,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        },
        {
            key = 'random',
            name = "<LOC lobui_0374>AI: Random",

            rating = 600,
            ratingCheatMultiplier = 0.0,
            ratingBuildMultiplier = 0.0,
            ratingOmniMultiplier = 1.0,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
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
        if exists(ModData.location .. '/lua/AI/CustomAIs_v2') then
            -- get all AI files from CustomAIs_v2 folder
            ModAIFiles = DiskFindFiles(ModData.location .. '/lua/AI/CustomAIs_v2', '*.lua')
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
    table.insert(aitypes,
        {
            key = 'adaptivecheat',
            name = "<LOC lobui_0379>AIx: Adaptive",

            rating = 800,
            ratingCheatMultiplier = 100.0,
            ratingBuildMultiplier = 100.0,
            ratingOmniMultiplier = 1.2,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        })
    table.insert(aitypes,
        {
            key = 'rushcheat',
            name = "<LOC lobui_0380>AIx: Rush",

            rating = 800,
            ratingCheatMultiplier = 100.0,
            ratingBuildMultiplier = 100.0,
            ratingOmniMultiplier = 1.2,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        })
    table.insert(aitypes,
        {
            key = 'turtlecheat',
            name = "<LOC lobui_0384>AIx: Turtle",

            rating = 800,
            ratingCheatMultiplier = 100.0,
            ratingBuildMultiplier = 100.0,
            ratingOmniMultiplier = 1.2,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        })
    table.insert(aitypes,
        {
            key = 'techcheat',
            name = "<LOC lobui_0385>AIx: Tech",

            rating = 800,
            ratingCheatMultiplier = 100.0,
            ratingBuildMultiplier = 100.0,
            ratingOmniMultiplier = 1.2,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        })
    table.insert(aitypes,
        {
            key = 'randomcheat',
            name = "<LOC lobui_0395>AIx: Random",

            rating = 800,
            ratingCheatMultiplier = 100.0,
            ratingBuildMultiplier = 100.0,
            ratingOmniMultiplier = 1.2,
            ratingMapMultiplier = {
                [256] = 1.0,   -- 5x5
                [512] = 1.0,   -- 10x10
                [1024] = 0.9,  -- 20x20
                [2048] = 0.75, -- 40x40
                [4096] = 0.6,  -- 80x80
            }
        })

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
        if exists(ModData.location .. '/lua/AI/CustomAIs_v2') then
            -- get all AI files from CustomAIs_v2 folder
            ModAIFiles = DiskFindFiles(ModData.location .. '/lua/AI/CustomAIs_v2', '*.lua')
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
