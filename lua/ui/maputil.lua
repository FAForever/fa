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

-- A scenario file path is typically like `/maps/scmp_001/scmp_001_scenario.lua`

--- Given the path to a scenario info file, returns a path with the `_scenario.lua` bit removed.
---@param pathToScenarioInfo any
---@return string
local function GetPathToScenario(pathToScenarioInfo)
    return string.sub(pathToScenarioInfo, 1, string.len(pathToScenarioInfo) - string.len("scenario.lua"))
end

--- Given the path to a scenario info file, returns the path to the folder it resides in.
---@param pathToScenarioInfo any
---@return string
local function GetPathToFolder(pathToScenarioInfo)
    local splits = StringSplit(pathToScenarioInfo, "/")
    -- Remove the length of the last token (filename), and the slash character before it.
    return string.sub(pathToScenarioInfo, 1, string.len(pathToScenarioInfo) - string.len(splits[table.getn(splits)]) - 1)
end

--- Given the path to a scenario info file, returns the path to the scenario options file. The reference to this file is not stored in the _scenario.lua file.
---@param pathToScenarioInfo FileName
---@return FileName
function GetPathToScenarioOptions(pathToScenarioInfo)
    return GetPathToScenario(pathToScenarioInfo) .. "options.lua" --[[@as FileName]]
end

--- Given the path to a scenario info file, returns the path to the scenario strings file.  The reference to this file is not stored in the _scenario.lua file.
---@param pathToScenarioInfo FileName
---@return FileName
function GetPathToScenarioStrings(pathToScenarioInfo)
    return GetPathToScenario(pathToScenarioInfo) .. "strings.lua" --[[@as FileName]]
end

--- Given the path to a scenario info file, returns the path to the scenario water mask. The water mask can help players understand where water is.
---@param pathToScenarioInfo string
---@return FileName
function GetPathToWaterMask(pathToScenarioInfo)
    return GetPathToFolder(pathToScenarioInfo) .. "/lobby/preview-water.dds" --[[@as FileName]]
end

--- Given the path to a scenario info file, returns the path to the scenario cliff mask. The cliffs mask can help players understand where units can go.
---@param pathToScenarioInfo string
---@return FileName
function GetPathToCliffMask(pathToScenarioInfo)
    return GetPathToFolder(pathToScenarioInfo) .. "/lobby/preview-cliffs.dds" --[[@as FileName]]
end

--- Given the path to a scenario info file, returns the path to the scenario buildable mask. The buildable mask can help players understand where they have large, buildable areas.
---@param pathToScenarioInfo string
---@return FileName
function GetPathToBuildableMask(pathToScenarioInfo)
    return GetPathToFolder(pathToScenarioInfo) .. "/lobby/preview-buildable.dds" --[[@as FileName]]
end

--- Loads in the scenario save. This function is expensive and should be used sparingly.
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
    local ok, scenarioOptions = pcall(LoadScenarioOptionsFile, GetPathToScenarioOptions(pathToScenarioInfo)) --[[@as UIScenarioOptionsFile | nil]]
    if ok and scenarioOptions then
        scenarioInfo.options = scenarioOptions
    end

    -- optionally, add in briefing data flag
    local scenarioStrings
    ok, scenarioStrings = pcall(LoadScenarioStringsFile, GetPathToScenarioStrings(pathToScenarioInfo)) --[[@as UIScenarioStringsFile | nil]]
    if ok and scenarioStrings then
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
    
    for id, mod in import("/lua/mods.lua").AllSelectableMods() do
        scenFiles = DiskFindFiles(mod.location .. '/maps', nameFilter .. '_scenario.lua')
        for index, fileName in scenFiles do
            local scen = LoadScenario(fileName)
            if IsScenarioPlayable(scen) and scen.type == "skirmish" then
                table.insert(scenarios, scen)
            end
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

-------------------------------------------------------------------------------
--#region Efficient utility functions

--- Retrieves all of the playable armies for a scenario. Does not allocate new memory.
---@param scenarioInfo UIScenarioInfoFile
---@return string[]?     # If defined, looks like: { 'ARMY_01', 'ARMY_02', ... }. Returns nil when the scenario is malformed.
function GetArmiesFromScenario(scenarioInfo)

    -- Usually the configuration looks like the following:
    -- Configurations = {
    --     ['standard'] = {
    --         teams = {
    --             { name = 'FFA', armies = { 'ARMY_1', 'ARMY_2', 'ARMY_3', 'ARMY_4', } },
    --         },
    --         customprops = {
    --         },
    --     },
    -- }
    --
    -- It is clearly an unfinished design. There's not much we can do about that. We first check
    -- if it looks like that and we just return that accordingly.

    if scenarioInfo.Configurations.standard and scenarioInfo.Configurations.standard.teams then
        for _, teamConfig in scenarioInfo.Configurations.standard.teams do
            if teamConfig.name and (teamConfig.name == 'FFA') then
                return teamConfig.armies
            end
        end
    end

    -- Scenario format is malformed, not much we can do about this.

    return nil
end

--- Retrieves all the starting positions for a scenario. Allocates and returns new tables on each call.
---@param scenarioInfo UIScenarioInfoFile
---@param scenarioSave UIScenarioSaveFile
---@return Vector2[]?
function GetStartPositionsFromScenario(scenarioInfo, scenarioSave)
    local armies = GetArmiesFromScenario(scenarioInfo)
    if not armies then
        return nil
    end

    local markers = scenarioSave.MasterChain._MASTERCHAIN_.Markers
    if not markers then
        return nil
    end

    local output = {}
    for _, army in armies do
        local marker = markers[army]
        if marker then
            table.insert(output, { marker.position[1], marker.position[3] })
        else
            table.insert(output, { 0, 0 })

            WARN(
                "MapUtil - no initial position marker for army", army, "found in",
                scenarioInfo.name, "version", tostring(scenarioInfo.map_version)
            )
        end
    end

    return output
end

--#endregion
