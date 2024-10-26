--*****************************************************************************
--* File: lua/modules/ui/maputil.lua
--* Author: Chris Blackwell
--* Summary: Functions for loading maps and map info
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

--- A basic area defined in the scenario.
---@class UIScenarioArea
---@field [1] number    # x0
---@field [2] number    # z0
---@field [3] number    # x1
---@field [4] number    # z1
---@field type 'RECTANGLE'

--- A marker defined in the scenario.
---@class UIScenarioMarker
---@field color string
---@field type string
---@field prop BlueprintId  # path to blueprint
---@field orientation Vector
---@field position Vector

--- A chain of markers defined in the scenario.
---@class UIScenarioChain
---@field Markers string[]  # key of marker in the master chain

--- An army defined in the scenario.
---@class UIScenarioArmy
---@field personality string
---@field plans string
---@field color number
---@field faction number
---@field Economy { mass: number, energy: number }
---@field Alliances table
---@field PlatoonBuilders { Builders: table }

--- Scenario entities of a map that defines all areas, (resource) markers, marker chains and armies as defined in the average _save file.
---@class UIScenarioSaveFile
---@field Props table       # Unknown
---@field Areas table<string, { rectangle: UIScenarioArea }>
---@field MasterChain { _MASTERCHAIN_ : table<string, UIScenarioMarker> }
---@field Chains table<string, UIScenarioChain>
---@field Orders table      # Unknown
---@field Platoons table    # Unknown
---@field Armies table<string, UIScenarioArmy>

--- Scenario options of a map, as defined in the average _options.lua file.
---@class UIScenarioOptionsFile
---@field options ScenarioOption[]

---@class UIScenarioConfiguration
---@field teams {name: string, armies: string[]}
---@field customprops table<string, string>

--- The scenario information as defined in the average _scenario file.
---@class UIScenarioInfoFile
---@field AdaptiveMap boolean
---@field description string
---@field map string
---@field map_version? number
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
---@field preview? FileName
---@field save FileName
---@field script FileName
---@field size {[1]: number, [2]: number}
---@field reclaim? {[1]: number, [2]: number } # mass/energy
---@field starts boolean
---@field type 'skirmish' | 'campaign_coop'
---@field Configurations table<string, UIScenarioConfiguration>

---@class UIScenarioBriefingData
---@field text table
---@field movies string[]
---@field voice table
---@field bgsound table
---@field style string

--- The scenario strings as defined in the average _strings file.
---@class UIScenarioStringsFile: table
---@field BriefingData? UIScenarioBriefingData
---@field OPERATION_NAME? string
---@field OPERATION_DESCRIPTION? string

--- The full scenario information with additional fields
---@class UILobbyScenarioInfo: UIScenarioInfoFile
---@field file FileName             # reference to the _scenario.lua file
---@field options ScenarioOption[]  # options from optional _options.lua file
---@field hasBriefing boolean       # flag whether the _strings.lua file has briefing data in it

--- The scenario information with additional fields, as defined once in a session
---@class UISessionSenarioInfo : UIScenarioInfoFile
--- These are the actual `<key, value>` pairs that the lobby defines, not the option-factory type
--- objects the lobby uses
---@field Options? GameOptions
---
---@field PlayableAreaWidth number Syncs when the playable area changes
---@field PlayableAreaHeight number Syncs when the playable area changes
---@field PlayableRect { [1]: number, [2]: number, [3]: number, [4]: number } Coordinates `{x0, y0, x1, y1}` of the playable area Rectangle. Syncs when the playable area changes.

--- Given the path to a scenario info file, returns the path to the scenario options file. The reference to this file is not stored in the _scenario.lua file.
---@param pathToScenarioInfo FileName
---@return FileName
function GetPathToScenarioOptions(pathToScenarioInfo)
    return string.sub(pathToScenarioInfo, 1, string.len(pathToScenarioInfo) - string.len("scenario.lua")) ..
        "options.lua" --[[@as FileName]]
end

--- Given the path to a scenario info file, returns the path to the scenario strings file.  The reference to this file is not stored in the _scenario.lua file.
---@param pathToScenarioInfo FileName
---@return FileName
function GetPathToScenarioStrings(pathToScenarioInfo)
    return string.sub(pathToScenarioInfo, 1, string.len(pathToScenarioInfo) - string.len("scenario.lua")) ..
        "strings.lua" --[[@as FileName]]
end

--- Loads in the scenario save.
---@param pathToScenarioSave FileName
---@return UIScenarioSaveFile | nil
function LoadScenarioSaveFile(pathToScenarioSave)
    if not DiskGetFileInfo(pathToScenarioSave) then
        return nil
    end

    local data = {}
    doscript('/lua/dataInit.lua', data)
    doscript(pathToScenarioSave, data)

    return data.Scenario
end

--- Loads in the scenario options.
---@param pathToScenarioOptions FileName
---@return UIScenarioOptionsFile | nil
function LoadScenarioOptionsFile(pathToScenarioOptions)
    if not DiskGetFileInfo(pathToScenarioOptions) then
        return nil
    end

    local data = {}
    doscript('/lua/dataInit.lua', data)
    doscript(pathToScenarioOptions, data)

    return data.options
end

--- Loads in the scenario strings.
---@param pathToScenarioStrings FileName
---@return UIScenarioStringsFile | nil
function LoadScenarioStringsFile(pathToScenarioStrings)
    if not DiskGetFileInfo(pathToScenarioStrings) then
        return nil
    end

    local data = {}
    doscript('/lua/dataInit.lua', data)
    doscript(pathToScenarioStrings, data)

    return data
end

--- Loads in the scenario information.
---@param pathToScenarioInfo FileName
---@return UIScenarioInfoFile | nil
function LoadScenarioInfoFile(pathToScenarioInfo)
    if not DiskGetFileInfo(pathToScenarioInfo) then
        return nil
    end

    local data = {}
    doscript('/lua/dataInit.lua', data)
    doscript(pathToScenarioInfo, data)

    -- Backward compatibility
    if data.version == 1 then
        local temp = data
        data = {
            ScenarioInfo = temp,
        }
    end

    return data.ScenarioInfo
end

--- Loads in the entire scenario including the save and optional files such as _options.lua and _strings.lua.
---@param pathToScenarioInfo FileName
---@return UILobbyScenarioInfo?
function LoadScenario(pathToScenarioInfo)
    local scenarioInfo = LoadScenarioInfoFile(pathToScenarioInfo)
    if not scenarioInfo then
        return nil
    end

    -- optionally, add in the options
    local scenarioOptions = LoadScenarioOptionsFile(GetPathToScenarioOptions(pathToScenarioInfo))
    if scenarioOptions then
        scenarioInfo.options = scenarioOptions
    end

    -- optionally, add in briefing data flag
    local scenarioStrings = LoadScenarioStringsFile(GetPathToScenarioStrings(pathToScenarioInfo))
    if scenarioStrings then
        if scenarioStrings.BriefingData then
            scenarioInfo.hasBriefing = true
        end
    end

    scenarioInfo.file = pathToScenarioInfo
    return scenarioInfo --[[@as UILobbyScenarioInfo]]
end

--- the default scenario enumerator sort method
---@param compa string
---@param compb string
---@return boolean
local function DefaultScenarioSorter(compa, compb)
    return string.upper(compa) < string.upper(compb)
end

--- given a scenario, determines if it can be played in skirmish mode
---@param scenario UIScenarioInfoFile
---@return boolean
function IsScenarioPlayable(scenario)
    if not scenario.Configurations.standard.teams[1].armies then
        return false
    end

    return true
end

--- EnumerateScenarios returns an array of scenario names
---  nameFilter can be passed in to narrow the enumaration, for example
---      EnumerateScenarios("SCMP*") will find all maps that start with SCMP
---      if nameFilter is nil, all maps will be returned
---  sortFunc is a function which, given two scenario names, will return true for the file name to come first
---      if no sortFunc is defined the default sorter will be used
---@param nameFilter? string            # defaults to '*'
---@param sortFunc? fun(a, b): boolean  # defaults to alphabetical on name of map
---@return table
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
---@param scenario UIScenarioInfoFile
---@return Vector2[]
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

-- Retrieves all of the playable armies for a scenario
---@param scenario UIScenarioInfoFile
---@return string[] | nil
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

---@param scenario UIScenarioInfoFile
---@return string[]
function GetExtraArmies(scenario)
    if scenario.Configurations.standard and scenario.Configurations.standard.teams then
        local teams = scenario.Configurations.standard.teams
        if teams.ExtraArmies then
            local armies = STR_GetTokens(teams.ExtraArmies, ' ')
            return armies
        end
    end
end

--- Validate options provided by the scenario file.
-- This function prints warnings about any defects and attempts to correct them with sane defaults.
---@param scenarioOptions ScenarioOption[]
---@return boolean
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
---@param scenario UIScenarioInfoFile
---@return boolean
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
        WARN('Map ' .. scenario.name .. ' has no markers')
        return false
    else
        for marker, data in markers do
            if data.adjacentTo and string.find(data.adjacentTo, ' ') then
                return true
            end
        end
    end
    return false
end
