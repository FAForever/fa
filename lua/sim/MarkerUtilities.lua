--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local StringSplit = import("/lua/system/utils.lua").StringSplit
local TableDeepCopy = table.deepcopy

---@alias MarkerType 'Mass' | 'Hydrocarbon' | 'Spawn' | 'Start Location' | 'Air Path Node' | 'Land Path Node' | 'Water Path Node' | 'Ampibious Path Node' | 'Transport Marker' | 'Naval Area' | 'Naval Link' | 'Rally Point' | 'Large Expansion Area' | 'Expansion Area' | 'Protected Experimental Construction'

---@class MarkerDataLegacy
---@field size number           # Legacy name used by the GPG editor, same as `Size`
---@field resource boolean      # Legacy name used by the GPG editor, same as `Resource`
---@field type string           # Legacy name used by the GPG editor, same as `Type`
---@field orientation Vector    # Legacy name used by the GPG editor, same as `Orientation`
---@field position Vector       # Legacy name used by the GPG editor, same as `Position`
---@field color? Color          # Legacy name used by the GPG editor, same as `Color`
---@field adjacentTo? string    # Legacy name used by the Ozonex editor

---@class MarkerDataModSupport
---@field Size number           # Field exists for mod support, same as `size` 
---@field Resource boolean      # Field exists for mod support, same as `resource` 
---@field Type string           # Field exists for mod support, same as `type` 
---@field Orientation Vector    # Field exists for mod support, same as `orientation` 
---@field Position Vector       # Field exists for mod support, same as `position` 
---@field Color? Color          # Field exists for mod support, same as `color` 

---@class MarkerData : MarkerDataLegacy, MarkerDataModSupport
---@field Name string               # Unique name for marker
---@field NavLayer? NavLayers       # Navigational layer that this marker is on, only defined for resources
---@field NavLabel? number | nil    # Navigational label of the graph this marker is on, only defined for resources and when AIs are in-game

---@class MarkerResource : MarkerData
---@field NavLayer NavLayers 
---@field NavLabel number
-- ---@field Island MarkerIsland

---@class MarkerExpansion : MarkerData
---@field NavLabel number
-- ---@field Island MarkerIsland
---@field Extractors MarkerResource[]
-- ---@field Hydrocarbons MarkerResource[]

-- ---@class MarkerIsland
-- ---@field NavLabel number
-- ---@field Expansions MarkerExpansion[]
-- ---@field Extractors MarkerResource[]
-- ---@field Hydrocarbons MarkerResource[]

-- easier access to all markers and all chains
---@type table<string, MarkerData>
local AllMarkers = { }

---@type table<string, MarkerChain>
local AllChains = { }

--- Represents a cache of markers to prevent re-populating tables
local MarkerCache = {
    Mass = { Count = 0, Markers = {} },
    Hydrocarbon = { Count = 0, Markers = {} },
    Spawn = { Count = 0, Markers = {} },
}

--- Represents a cache of chains to prevent re-populating tables
local ChainCache = {}

--- Converts the marker type to add support for legacy names
---@param type MarkerType
---@return MarkerType
local function MapMarkerType(type)
    if type == 'Start Location' then
        return 'Spawn'
    end

    return type
end

---@return MarkerData[]
function GetAllMarkers()
    return AllMarkers
end

--- Retrieves a single marker on the map.
---@param name string
---@return MarkerData
function GetMarker(name)
    return AllMarkers[name]
end

---@param type MarkerType
---@return MarkerData[]
---@return number
function GetMarkersByType(type)
    type = MapMarkerType(type)

    -- check if it is cached and return that
    local cache = MarkerCache[type]
    if cache then
        return cache.Markers, cache.Count
    end

    -- prepare cache population
    local ms = {}
    local n = 1

    -- find all the relevant markers
    for k, marker in AllMarkers do
        if marker.type == type then
            -- mod support syntax
            marker.Name = k
            marker.Size = marker.size
            marker.Resource = marker.resource
            marker.Type = marker.type
            marker.Orientation = marker.orientation
            marker.Position = marker.position
            marker.Color = marker.color

            ms[n] = marker
            n = n + 1
        end
    end

    -- tell us about it, for now
    SPEW("Caching " .. n - 1 .. " markers of type " .. type .. "!")

    -- construct the cache
    cache = {
        Count = n - 1,
        Markers = ms
    }

    -- cache it and return it
    MarkerCache[type] = cache
    return cache.Markers, cache.Count
end

---@param type MarkerType
---@param markers any
function OverwriteMarkerByType(type, markers)
    type = MapMarkerType(type)

    local ms = {}
    local n = 1

    for k, marker in markers do
        -- mod support syntax
        marker.Name = marker.Name or k
        marker.Size = marker.size
        marker.Resource = marker.resource
        marker.Type = marker.type
        marker.Orientation = marker.orientation
        marker.Position = marker.position
        marker.Color = marker.color

        ms[n] = marker
        n = n + 1
    end

    MarkerCache[type] = {
        Count = n - 1,
        Markers = ms
    }

    SPEW("Overwriting " .. n - 1 .. " markers of type " .. type .. " in cache!")
end

--- Flushes the cache of a certain type. Does not remove
-- existing references.
---@param type MarkerType The type to flush.
function FlushMarkerCacheByType(type)
    type = MapMarkerType(type)

    -- give developer a warning, you can't do this
    if type == "Mass" or type == "Hydrocarbon" or type == "Spawn" then
        WARN("Unable to flush resource markers from the cache - it can cause issues for adaptive maps.")
        return
    end

    MarkerCache[type] = nil
end

--- Flushes the entire marker cache. Does not remove existing references.
function FlushMarkerCache()

    -- copy over for consistency
    local cache = {}
    cache.Mass = MarkerCache.Mass
    cache.Hydrocarbon = MarkerCache.Hydrocarbon
    cache.Spawn = MarkerCache.Spawn

    MarkerCache = cache
end

--- Retrieves a chain of markers. Throws an error if the chain
-- does not exist. This is a shallow copy, which means the
-- reference is copied but the values are not. If you need a
-- copy with unique values use GetMarkerByTypeDeep instead.
---@param name MarkerChain The type of marker to retrieve.
---@return MarkerData
---@return number
function GetMarkersInChain(name)
    -- check if it is cached and return that
    local cache = ChainCache[name]
    if cache then
        return cache.Markers, cache.Count
    end

    -- check if chain exists
    local chain = AllChains[name]
    if not chain then
        error('ERROR: Invalid Chain Named- ' .. name, 2)
    end

    -- prepare cache population
    local ms = {}
    local n = 1

    -- find all the relevant markers
    for k, elem in chain.Markers do
        ms[n] = elem.position
        n = n + 1
    end

    -- construct the cache
    cache = {
        Count = n - 1,
        Markers = ms
    }

    -- cache it and return it
    ChainCache[name] = cache
    return cache.Markers, cache.Count
end

--- Retrieves a chain of markers. Throws an error if the
-- chain does not exist. This is a deep copy and involves
-- a lot of additional allocations. Do not use this unless
-- you strictly need to.
---@param name MarkerChain The name of chain to retrieve.
---@return MarkerData[]
---@return number
function GetMarkersInChainDeep(name)
    local markers, count = GetMarkersInChain(name)
    return TableDeepCopy(markers), count
end

--- Flushes the chain cache of a certain type. Does not
-- remove existing references.
---@param name MarkerChain The type to flush.
function FlushChainCacheByName(name)
    ChainCache[name] = false
end

--- Flushes the chain cache. Does not remove existing references.
-- @param type The type to flush.
function FlushChainCache()
    ChainCache = {}
end

--- Retrieves the name / key values of the marker types that are in
-- the cache. This returns a new table in each call - do not use in
-- production code. Useful in combination with ToggleDebugMarkersByType.
-- returns Table with names and the number of names.
function DebugGetMarkerTypesInCache()

    -- allocate a table
    local next = 1
    local types = {}

    -- retrieve all names
    for k, cache in MarkerCache do
        types[next] = k
        next = next + 1
    end

    return types, next - 1
end

--- Keeps track of all marker debugging threads
local DebugMarkerThreads = {}
local DebugMarkerSuspend = {}

--- Debugs the marker cache of a given type by drawing it on-screen. Useful
-- to check for errors. Can be toggled on and off by calling it again.
---@param type MarkerChain The type of markers you wish to debug.
function ToggleDebugMarkersByType(type)

    SPEW("Toggled type to debug: " .. type)

    -- get the thread if it exists
    local thread = DebugMarkerThreads[type]
    if not thread then

        -- make the thread if it did not exist yet
        thread = ForkThread(
            function()

                local labelToColor = import("/lua/shared/navgenerator.lua").LabelToColor

                while true do

                    -- check if we should sleep or not
                    if DebugMarkerSuspend[type] then
                        SuspendCurrentThread()
                    end

                    -- draw out all markers
                    local markers = GetMarkersByType(type)
                    for k, marker in markers do
                        DrawCircle(marker.Position, marker.Size or 1, marker.Color or 'ffffffff')

                        if marker.NavLabel then
                            DrawCircle(marker.Position, (marker.Size or 1) + 1, labelToColor(marker.NavLabel))
                        end

                        -- useful for pathing markers
                        if marker.adjacentTo then
                            for _, neighbour in StringSplit(marker.adjacentTo, " ") do
                                local neighbour = AllMarkers[neighbour]
                                if neighbour then
                                    DrawLine(marker.Position, neighbour.Position, marker.Color or 'ffffffff')
                                end
                            end
                        end

                        if marker.Extractors then
                            for _, neighbour in marker.Extractors do
                                DrawLine(marker.Position, neighbour.Position, neighbour.Color or 'ffffffff')
                            end
                        end
                    end

                    WaitTicks(2)
                end
            end
        )

        -- store it and return
        DebugMarkerSuspend[type] = false
        DebugMarkerThreads[type] = thread
        return
    end

    -- enable the thread if it should not be suspended
    DebugMarkerSuspend[type] = not DebugMarkerSuspend[type]
    if not DebugMarkerSuspend[type] then
        ResumeThread(thread)
    end

    -- keep track of it
    DebugMarkerThreads[type] = thread
end

--- Retrieves the name / key values of the chains that are in the
-- cache. This returns a new table in each call - do not use in
-- production code.  Useful in combination with ToggleDebugMarkersByType.
---@return string[]
---@return number
function DebugGetChainNamesInCache()

    -- allocate a table
    local next = 1
    local types = {}

    -- retrieve all names
    for k, cache in ChainCache do
        types[next] = k
        next = next + 1
    end

    return types, next - 1
end

--- Keeps track of all chain debugging threads
local DebugChainThreads = {}
local DebugChainSuspend = {}

--- Debugs the chain cache of a given type by drawing it on-screen. Useful
-- to check for errors. Can be toggled on and off by calling it again.
---@param name MarkerChain The name of the chain you wish to debug.
function ToggleDebugChainByName(name)
    
    SPEW("Toggled chain to debug: " .. name)

    -- get the thread if it exists
    local thread = DebugChainThreads[name]
    if not thread then

        -- make the thread if it did not exist yet
        thread = ForkThread(
            function()
                while true do

                    -- check if we should suspend ourselves
                    if DebugChainSuspend[name] then
                        SuspendCurrentThread()
                    end

                    -- draw out all markers
                    local markers, count = GetMarkersInChain(name)
                    if count > 1 then
                        for k = 1, count - 1 do
                            local curr = markers[k]
                            local next = markers[k + 1]
                            DrawLinePop(curr.position, next.position, curr.color or next.color or 'ffffffff')
                        end

                        -- draw out a single marker
                    else
                        if count == 1 then
                            local marker = markers[1]
                            DrawCircle(marker.position, marker.size or 1, marker.color or 'ffffffff')
                        else
                            WARN("Trying to debug draw an empty chain: " .. name)
                        end
                    end

                    WaitTicks(2)
                end
            end
        )

        -- store it and return
        DebugChainSuspend[name] = false
        DebugChainThreads[name] = thread
        return
    end

    -- resume thread it is should not be suspended
    DebugChainSuspend[name] = not DebugChainSuspend[name]
    if not DebugChainSuspend[name] then
        ResumeThread(thread)
    end

    -- keep track of it
    DebugChainThreads[name] = thread
end

function Setup()
    AllMarkers = Scenario.MasterChain._MASTERCHAIN_.Markers
    AllChains = Scenario.Chains

    -- prepare spawn markers
    local armies = table.hash(ListArmies())
    for k, marker in AllMarkers do
        if armies[k] then
            marker.Name = k
            marker.size = 50
            MarkerCache["Spawn"].Count = MarkerCache["Spawn"].Count + 1
            MarkerCache["Spawn"].Markers[MarkerCache["Spawn"].Count] = marker
        end
    end

    -- hook to catch created resources
    local OldCreateResourceDeposit = _G.CreateResourceDeposit
    _G.CreateResourceDeposit = function(type, x, y, z, size)

        local NavUtils = import("/lua/sim/navutils.lua")

        -- fix to terrain height
        y = GetTerrainHeight(x, z)
        OldCreateResourceDeposit(type, x, y, z, size)

        local position = Vector(x, y, z)
        local orientation = Vector(0, -0, 0)

        ---@type NavLayers
        local layer = 'Land'
        if y < GetSurfaceHeight(x, z) then
            layer = 'Amphibious'
        end

        ---@type number | nil
        local label = nil
        if NavUtils.IsGenerated() then
            label = NavUtils.GetLabel(layer, { x, y, z })
        end

        -- commented values are used by the editor and not by the game
        ---@type MarkerData
        local marker = nil
        if type == 'Mass' then
            marker = {
                NavLayer = layer,
                NavLabel = label,

                -- mod support syntax
                Size = size,
                Resource = true,
                Type = type,
                Orientation = orientation,
                Position = position,

                -- legacy syntax for markers
                size = size,
                resource = true,
                type = type,
                orientation = orientation,
                position = position,
            }
        else
            marker = {

                NavLayer = layer,
                NavLabel = label,

                -- mod support syntax
                Size = size,
                Resource = true,
                Type = type,
                Orientation = orientation,
                Position = position,

                -- legacy syntax for markers
                size = size,
                resource = true,
                type = type,
                orientation = orientation,
                position = position,
            }
        end

        -- make sure cache exists
        local markers, count = GetMarkersByType(type)

        -- add name
        marker.Name = string.format("%s %d", type, count + 1)

        -- add to cache
        MarkerCache[type].Count = count + 1
        MarkerCache[type].Markers[count + 1] = marker
    end
end

GenerateExpansionMarkers = import("/lua/sim/MarkerUtilities/Expansions.lua").Generate
GenerateRallyPointMarkers = import("/lua/sim/MarkerUtilities/RallyPoints.lua").Generate

function __moduleinfo.OnReload(newModule)
    -- add existing markers to new module
    for key, info in MarkerCache do 
        newModule.OverwriteMarkerByType(key, info.Markers)
    end
end
