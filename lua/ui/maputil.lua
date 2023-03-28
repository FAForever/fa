--*****************************************************************************
--* File: lua/modules/ui/maputil.lua
--* Author: Chris Blackwell
--* Summary: Functions for loading maps and map info
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

---@class UIScenarioConfiguration
---@field teams {name: string, armies: string[]}
---@field customprops table<string, string>

---@class UIScenarioInfo
---@field AdaptiveMap boolean
---@field description string
---@field map string
---@field map_version number
---@field name string
---@field norushradius number
---@field norushoffsetX_ARMY_1? number
---@field norushoffsetY_ARMY_1? number
---@field norushoffsetX_ARMY_2? number
---@field norushoffsetY_ARMY_2? number
---@field norushoffsetX_ARMY_3? number
---@field norushoffsetY_ARMY_3? number
---@field norushoffsetX_ARMY_4? number
---@field norushoffsetY_ARMY_4? number
---@field norushoffsetX_ARMY_5? number
---@field norushoffsetY_ARMY_5? number
---@field norushoffsetX_ARMY_6? number
---@field norushoffsetY_ARMY_6? number
---@field norushoffsetX_ARMY_7? number
---@field norushoffsetY_ARMY_7? number
---@field norushoffsetX_ARMY_8? number
---@field norushoffsetY_ARMY_8? number
---@field norushoffsetX_ARMY_9? number
---@field norushoffsetY_ARMY_9? number
---@field norushoffsetX_ARMY_10? number
---@field norushoffsetY_ARMY_10? number
---@field norushoffsetX_ARMY_11? number
---@field norushoffsetY_ARMY_11? number
---@field norushoffsetX_ARMY_12? number
---@field norushoffsetY_ARMY_12? number
---@field norushoffsetX_ARMY_13? number
---@field norushoffsetY_ARMY_13? number
---@field norushoffsetX_ARMY_14? number
---@field norushoffsetY_ARMY_14? number
---@field norushoffsetX_ARMY_15? number
---@field norushoffsetY_ARMY_15? number
---@field norushoffsetX_ARMY_16? number
---@field norushoffsetY_ARMY_16? number
---@field preview string
---@field save string
---@field script string
---@field size {[1]: number, [2]: number}
---@field starts boolean
---@field type string
---@field Configurations table<string, UIScenarioConfiguration>
---@field file string
---@field Outdated boolean
--- Additional map options supplied by the map `options.lua` file, if it exists.
--- These are the lobby option-factory type of options, not the actual `<key, value>` pairs
--- that the lobby ends up defining.
---@field options? ScenarioOption[]
--- These are the actual `<key, value>` pairs that the lobby defines, not the option-factory type
--- objects the lobby uses
---@field Options? GameOptions
---
---@field PlayableAreaWidth number
---@field PlayableAreaHeight number


local OutdatedMaps = import("/etc/faf/mapblacklist.lua").MapBlacklist
local Utils = import("/lua/system/utils.lua")

-- load a scenario based on a scenario file name
---@param scenName string
---@return UIScenarioInfo
function LoadScenario(scenName)
    -- TODO - expose FILE_IsAbsolute and if it's not, add the path and the _scenario.lua

    if not DiskGetFileInfo(scenName) then
        return nil
    end

    local env = {}
    doscript('/lua/dataInit.lua', env)
    doscript(scenName, env)

    if not env.ScenarioInfo then
        return nil
    end

    -- Backward compatibility
    if env.version == 1 then
        local temp = env
        env = {
            ScenarioInfo = temp,
        }
    end

    local optionsFileName = string.sub(scenName, 1, string.len(scenName) - string.len("scenario.lua")) .. "options.lua"
    if DiskGetFileInfo(optionsFileName) then
        local optionsEnv = {}
        doscript(optionsFileName, optionsEnv)
        if optionsEnv.options ~= nil then
            env.ScenarioInfo.options = optionsEnv.options
        end
    end

    -- Check if the map has mission briefing data
    local stringsFileName = string.sub(scenName, 1, string.len(scenName) - string.len("scenario.lua")) .. "strings.lua"
    if DiskGetFileInfo(stringsFileName) then
        local stringsEnv = {}
        doscript(stringsFileName, stringsEnv)
        if stringsEnv.BriefingData ~= nil then
            env.ScenarioInfo.hasBriefing = true
        end
    end

    -- Is this map flagged out of date? *CACKLES INSANELY*
    local pathBits = Utils.StringSplit(scenName, '/')
    env.ScenarioInfo.Outdated = OutdatedMaps[pathBits[2]]

    env.ScenarioInfo.file = scenName -- stuff the file name in so we have that
    return env.ScenarioInfo
end

-- the default scenario enumerator sort method
local function DefaultScenarioSorter(compa, compb)
    return string.upper(compa) < string.upper(compb)
end

-- given a scenario, determines if it can be played in skirmish mode
function IsScenarioPlayable(scenario)
    if not scenario.Configurations.standard.teams[1].armies then
        return false
    end

    return true
end

-- EnumerateScenarios returns an array of scenario names
--  nameFilter can be passed in to narrow the enumaration, for example
--      EnumerateScenarios("SCMP*") will find all maps that start with SCMP
--      if nameFilter is nil, all maps will be returned
--  sortFunc is a function which, given two scenario names, will return true for the file name to come first
--      if no sortFunc is defined the default sorter will be used
function EnumerateSkirmishScenarios(nameFilter, sortFunc)
    nameFilter = nameFilter or '*'
    sortFunc = sortFunc or DefaultScenarioSorter

    -- retrieve the map file names
    local scenFiles = DiskFindFiles('/maps', nameFilter .. '_scenario.lua')

    -- load each map in to a table and store in our data structure
    local scenarios = {}
    for index, fileName in scenFiles do
        local scen = LoadScenario(fileName)
        if IsScenarioPlayable(scen) and scen.type == "skirmish" then
            table.insert(scenarios, scen)
        end
    end

    -- sort based on name
    table.sort(scenarios, function(a, b) return sortFunc(a.name, b.name) end)

    return scenarios
end

-- given a scenario table, loads the save file and puts all the start positions in a table
-- I've made this function so it works with the old data format and the new
-- Returning an empty table means scenario data was ill formed
function GetStartPositions(scenario)
    local saveData = {}
    doscript('/lua/dataInit.lua', saveData)
    doscript(scenario.save, saveData)

    local armyPositions = {}

    -- try new data first
    if scenario.Configurations.standard and scenario.Configurations.standard.teams then
        -- find the "FFA" team
        for index, teamConfig in scenario.Configurations.standard.teams do
            if teamConfig.name and (teamConfig.name == 'FFA') then
                for armyIndex, armyName in teamConfig.armies do
                    armyPositions[armyName] = {}
                end
                break
            end
        end
        if table.empty(armyPositions) then
            WARN("Unable to find FFA configuration in " .. scenario.file)
        end
    end

    -- try old data if nothing added to army positions
    if table.empty(armyPositions) then
        -- figure out all the armies in this map
        -- make sure old data is there
        if scenario.Games then
            for index, game in scenario.Games do
                for k, army in game do
                    armyPositions[army] = {}
                end
            end
        end
    end

    -- if we found armies, then get the positions
    if not table.empty(armyPositions) then
        for army, position in armyPositions do
            if saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers[army] then
                local pos = saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers[army].position
                -- x and z value are of interest so ignore y (index 2)
                position[1] = pos[1]
                position[2] = pos[3]
            else
                WARN("No initial position marker for army " .. army .. " found in " .. scenario.save)
                position[1] = 0
                position[2] = 0
            end
        end
    else
        WARN("No start positions defined in " .. scenario.file)
    end

    return armyPositions
end

-- enumerates and returns to key name for all the armies for this map
function GetArmies(scenario)
    local retArmies = nil

    if scenario.Configurations.standard and scenario.Configurations.standard.teams then
        -- find the "FFA" team
        for index, teamConfig in scenario.Configurations.standard.teams do
            if teamConfig.name and (teamConfig.name == 'FFA') then
                retArmies = teamConfig.armies
            end
            break
        end
    end

    if (retArmies == nil) or (table.empty(retArmies)) then
        WARN("No starting armies defined in " .. scenario.file)
    end

    return retArmies
end
function GetExtraArmies(scenario)
    if scenario.Configurations.standard and scenario.Configurations.standard.teams then
        local teams = scenario.Configurations.standard.teams
        if teams.ExtraArmies then
            local armies = STR_GetTokens(teams.ExtraArmies,' ')
            return armies
        end
    end
end

--- Validate options provided by the scenario file.
-- This function prints warnings about any defects and attempts to correct them with sane defaults.
function ValidateScenarioOptions(scenarioOptions)
    -- Most maps just don't have any options.
    if not scenarioOptions then
        return true
    end

    local passed = true
    for k, optData in scenarioOptions do
        -- Verify that all options have a sane default.
        if not optData.default then
            optData.default = 1
            WARN("No default option specified for this option:")
            table.print(optData)
            passed = false
        elseif type(optData.default) ~= "number" or
                optData.default <= 0 or
                optData.default > table.getn(optData.values) then
            WARN("Invalid default option value " .. tostring(optData.default))
            WARN("Remember: option defaults are 1-based indices into the `values' table, not values themselves")
            WARN("Offending option table:")
            table.print(optData)
            passed = false

            -- Nearly everyone who gets here has just been a dipshit and used the value they want as
            -- their default value: something we can recover from gracefully.
            local replacementValue = 1
            for k, v in optData.values do
                if v.key == optData.default then
                    -- Huzzah, we found it!
                    replacementValue = k
                    break
                end
            end

            optData.default = replacementValue
        end
    end

    return passed
end

--- Checks a map for Land Path nodes.
--
-- @param scenario Scenario info
-- @return true if the map has Land Path nodes, false otherwise.
function CheckMapHasMarkers(scenario)
    if not DiskGetFileInfo(scenario.save) then
        return false
    end
    local saveData = {}
    doscript('/lua/dataInit.lua', saveData)
    doscript(scenario.save, saveData)


    local markers = saveData and
                    saveData.Scenario and
                    saveData.Scenario.MasterChain and
                    saveData.Scenario.MasterChain['_MASTERCHAIN_'] and
                    saveData.Scenario.MasterChain['_MASTERCHAIN_'].Markers or false

    if not markers then
       WARN('Map '.. scenario.name..' has no markers') return false
    else
       for marker, data in markers do
          if data.adjacentTo and string.find(data.adjacentTo, ' ') then
             return true
          end
       end
    end
    return false
end
