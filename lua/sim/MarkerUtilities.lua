
-----------------------------------------------------------------
-- File     : /lua/sim/MarkerUtilities.lua
-- Summary  : Aim of this file is to work with markers without
-- worrying about unneccesary table allocations. All base game
-- functionality allocates a new table when you wish to retrieve
-- a sequence of markers. This file implicitly stores a sequence
-- of markers and returns a reference, unless you explicitly
-- want a new table with unique values.

-- Contains various debug facilities to help understand the
-- state that is stored in this file.

-- Supports crazyrush-like maps.
-----------------------------------------------------------------

-- MARKERS --

--- Contains all the markers that are part of the map, including markers of chains
local AllMarkers = Scenario.MasterChain._MASTERCHAIN_.Markers

--- Retrieves all markers of the map.
-- returns A table of all the markers of the map.
function GetAllMarkers()
    return AllMarkers
end

--- Retrieves a single marker on the map.
-- @param name The name or key of the marker.
-- returns A marker of the map or nil.
function GetMarker(name)
    return AllMarkers[name]
end

--- Represents a cache of markers to prevent re-populating tables
local MarkerCache = { }

--- Retrieves all markers of a given type. This is a shallow copy,
-- which means the reference is copied but the values are not. If you
-- need a copy with unique values use GetMarkerByTypeDeep instead.
-- @param type The type of marker to retrieve.
-- returns A table with markers and its length.
function GetMarkersByType(type)

    -- check if it is cached and return that
    local cache = MarkerCache[type]
    if cache then 
        return cache.Markers, cache.Count
    end

    -- prepare cache population
    ms = { }
    n = 1

    -- find all the relevant markers
    for k, marker in AllMarkers do 
        if marker.type == type then 
            ms[n] = marker 
            n = n + 1 
        end
    end

    -- tell us about it, for now
    LOG("Caching " .. n - 1 .. " markers of type " .. type .. "!")

    -- construct the cache
    cache = {
        Count = n - 1,
        Markers = ms 
    }

    -- cache it and return it
    MarkerCache[type] = cache 
    return cache.Markers, cache.Count
end

--- Retrieves all markers of a given type. This is a deep copy
-- and involves a lot of additional allocations. Do not use this
-- unless you strictly need to.
-- @param type The type of marker to retrieve.
-- returns A table with markers and its length.
function GetMarkersByTypeDeep(type)
    local cache = GetMarkersByType(type)
    return table.deepcopy(cache.Markers), cache.Count
end

--- Flushes the cache of a certain type. Does not remove
-- existing references.
-- @param type The type to flush.
function FlushMarkerCacheByType(type)
    MarkerCache[type] = false
end

--- Flushes the entire marker cache. Does not remove existing references.
function FlushMarkerCache()
    MarkerCache = { }
end

-- CHAINS --

--- Contains all the chains that are part of the map
local AllChains = Scenario.Chains

--- Represents a cache of chains to prevent re-populating tables
local ChainCache = { }

--- Retrieves a chain of markers. Throws an error if the chain
-- does not exist. This is a shallow copy, which means the
-- reference is copied but the values are not. If you need a
-- copy with unique values use GetMarkerByTypeDeep instead.
-- @param type The type of marker to retrieve.
-- returns A table with markers and its length.
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
    ms = { }
    n = 1

    -- find all the relevant markers
    for k, elem in chain.Markers do 
        ms[n] = marker.position
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
-- @param type The type of marker to retrieve.
-- returns A table with markers and its length.
function GetMarkersInChainDeep(type)
    local cache = GetMarkersInChain(type)
    return table.deepcopy(cache.Markers), cache.Count
end

--- Flushes the chain cache of a certain type. Does not 
-- remove existing references.
-- @param type The type to flush.
function FlushChainCacheByName(name)
    ChainCache[name] = false 
end

--- Flushes the chain cache. Does not remove existing references.
-- @param type The type to flush.
function FlushChainCache()
    ChainCache = { }
end

-- DEBUGGING -- 

--- Retrieves the name / key values of the marker types that are in
-- the cache. This returns a new table in each call - do not use in 
-- production code. Useful in combination with ToggleDebugMarkersByType.
-- returns Table with names and the number of names.
function DebugGetMarkerTypesInCache()

    -- allocate a table
    local next = 1 
    local types = { }

    -- retrieve all names
    for k, cache in MarkerCache do 
        types[next] = k 
        next = next + 1
    end

    return types, next - 1
end

--- Keeps track of all marker debugging threads
local DebugMarkerThreads = { }
local DebugMarkerSuspend = { }

--- Debugs the marker cache of a given type by drawing it on-screen. Useful
-- to check for errors. Can be toggled on and off by calling it again.
-- @param type The type of markers you wish to debug.
function ToggleDebugMarkersByType(type)

    -- get the thread if it exists
    local thread = DebugMarkerThreads[type]
    if not thread then 

        -- make the thread if it did not exist yet
        thread = ForkThread(
            function()
                while true do 

                    -- check if we should sleep or not
                    if DebugMarkerSuspend[type] then 
                        SuspendCurrentThread()
                    end

                    -- draw out all markers
                    local markers, count = GetMarkersByType(type)
                    for k = 1, count do 
                        local marker = markers[k]
                        DrawCircle(marker.position, marker.size, marker.color)
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
-- returns Table with names and the number of names.
function DebugGetChainNamesInCache()

    -- allocate a table
    local next = 1 
    local types = { }

    -- retrieve all names
    for k, cache in ChainCache do 
        types[next] = k 
        next = next + 1
    end

    return types, next - 1
end

--- Keeps track of all chain debugging threads
local DebugChainThreads = { }
local DebugChainSuspend = { }

--- Debugs the chain cache of a given type by drawing it on-screen. Useful
-- to check for errors. Can be toggled on and off by calling it again.
-- @param type The name of the chain you wish to debug.
function ToggleDebugChainByName(name)

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
                            DrawCircle(marker.position, marker.size, marker.color)
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

-- HOOKING --

ForkThread(
    function()

        -- wait a few ticks to ensure all markers are loaded 

        WaitTicks(11) -- one second

        -- hook to cache markers created on the fly by crazy rush type of games
        local OldCreateResourceDeposit = _G.CreateResourceDeposit
        _G.CreateResourceDeposit = function (type, x, y, z, size)

            -- fix to terrain height for debugging purposes
            y = GetTerrainHeight(x, z)
            OldCreateResourceDeposit(type, x, y, z, size)

            -- commented values are used by the editor and not by the game
            local marker = false 
            if type == 'Mass' then 
                marker = {
                    size = size,
                    resource = true,
                    -- amount = 100,
                    color = 'ff808080',
                    -- editorIcon = '/textures/editor/marker_mass.bmp',
                    type = type,
                    -- prop = '/env/common/props/markers/M_Mass_prop.bp',
                    orientation = Vector(0, -0, 0),
                    position = Vector(x, y, z),
                }
            else 
                marker = {
                    size = size,
                    resource = true,
                    -- amount = 100,
                    color = 'ff008000',
                    -- editorIcon = '/textures/editor/marker_mass.bmp',
                    type = type,
                    -- prop = '/env/common/props/markers/M_Mass_prop.bp',
                    orientation = Vector(0, -0, 0),
                    position = Vector(x, y, z),
                }
            end

            -- add it to global table (on the array part of the table)
            table.insert(AllMarkers, marker)

            -- make sure cache exists
            local markers, count = GetMarkersByType(type)
            MarkerCache[type].Count = count + 1
            MarkerCache[type].Markers[count + 1] = marker
        end
    end
)