
-- structure of data
-- data = {
--     -- what
--     Lua = {
--         -- namewhat
--           ["global"]    = { }
--         , ["upval"]     = { }
--         , ["local"]     = { }
--         , ["method"]    = { }
--         , ["field"]     = { }
--         , ["other"]     = { }
--     },

--     -- what
--     C = {
--         -- namewhat
--           ["global"]    = { }
--         , ["upval"]     = { }
--         , ["local"]     = { }
--         , ["method"]    = { }
--         , ["field"]     = { }
--         , ["other"]     = { }
--     },

--     -- what
--     main = {
--         -- namewhat
--           ["global"]    = { }
--         , ["upval"]     = { }
--         , ["local"]     = { }
--         , ["method"]    = { }
--         , ["field"]     = { }
--         , ["other"]     = { }
--     },
-- }

local CreateEmptyProfilerTable = import("/lua/shared/profiler.lua").CreateEmptyProfilerTable

-- upvalue for performance
local StringFind = string.find

local cache = { }
local head = 1

--- Flattens the profiler data in a single list, can be tweaked using filter parameters
-- @param data Profiler data as described at the top of this file
-- @param fSource Filter on the source: "Lua", "C" or "main"
-- @param fScope Filter on the scope: "global", "upvalue", "local", "method", "field" or "other"
-- @param fName Filter on the name of the function
function Format(data, growth, fSource, fScope, fName)

    -- default to no filtering
    fSource = fSource or false
    fScope = fScope or false 
    fName = fName or false 
    growth = growth or { }

    if fName then 
        fName = string.lower(fName)
    end

    -- reset cache
    head = 1

    -- loop over data
    -- Lua, C or main
    for source, i1 in data do 

        -- skip content that we're not interested in
        if fSource then 
            if source ~= fSource then 
                continue 
            end
        end

        -- global, local, method, field or other (empty)
        for scope, i2 in i1 do 

            -- skip content that we're not interested in
            if fScope then 
                if scope ~= fScope then 
                    continue 
                end
            end

            -- name of function and value
            for name, value in i2 do 

                -- skip content that we're not interested in
                if fName then 
                    if not StringFind(string.lower(name), fName) then 
                        continue 
                    end
                end

                -- may be set to false
                if data[source][scope][name] then 

                    -- attempt to retrieve an element
                    local element = cache[head]
                    if not element then 
                        element = { source = false, scope = false, name = false, value = false, growth = false  }
                        cache[head] = element
                    end

                    -- element is used
                    head = head + 1

                    -- populate element
                    element.source = source 
                    element.scope = scope
                    element.name = name 
                    element.k = string.lower(name)
                    element.value = value 
                    element.growth = growth[scope][name] or 0
                end
            end
        end
    end

    -- return valid information
    return cache, head - 1
end

--- Applies insertion sort on the cache based on the provided field
-- copied from: https://github.com/akosma/CodeaSort/blob/master/InsertionSort.lua
-- @param cache Table with elements of type { source :: string, scope :: string, name :: string, value :: string }
-- @param count Number of elements in cache
-- @param field Field we want to sort on: source, scope, name or value
function Sort(cache, count, field)

    -- sort only on lowered strings
    if field == "name" then 
        field = "k"
    end

    -- numbers are ordered different
    reverse = type(cache[1][field]) == "number"

    -- insertion sort
    if reverse then 
        for j = 2, count do
            local key = cache[j]
            local i = j - 1
            while i > 0 and cache[i][field] < key[field] do
                cache[i + 1] = cache[i]
                i = i - 1
            end
            cache[i + 1] = key
        end
    else 
        for j = 2, count do
            local key = cache[j]
            local i = j - 1
            while i > 0 and cache[i][field] > key[field] do
                cache[i + 1] = cache[i]
                i = i - 1
            end
            cache[i + 1] = key
        end
    end
    return cache, count
end

--- A function name / value look up cache
local lCache = { }

function LookUp(data)

    -- reset the cache

    for k, element in lCache do 
        lCache[k] = false
    end

    -- populate the lookup cache

    -- Lua, C or main
    for source, i1 in data do 
        -- global, local, method, field or other (empty)
        for scope, i2 in i1 do 
            -- name of function and number of calls
            for name, calls in i2 do 

                if calls then 
                    local check = lCache[scope]
                    if not check then 
                        lCache[scope] = { } 
                    end

                    check = lCache[scope][name]
                    if not check then 
                        lCache[scope][name] = calls
                    else
                        lCache[scope][name] = check + calls
                    end
                end
            end
        end
    end

    return lCache
end

--- A cache that shares the profile data structure
local cachedData = CreateEmptyProfilerTable()

function Combine(arrays)

    -- reset the cache

    local cachedData = cachedData

    -- Lua, C or main
    for source, i1 in cachedData do 
        -- global, local, method, field or other (empty)
        for scope, i2 in i1 do 
            -- name of function and number of calls
            for name, calls in i2 do 
                cachedData[source][scope][name] = false
            end
        end
    end

    -- combine the input into one large profile data structure

    for k, info in arrays do 
        -- Lua, C or main
        for source, i1 in info.data do 
            -- global, local, method, field or other (empty)
            for scope, i2 in i1 do 
                -- name of function and number of calls
                for name, calls in i2 do 
                    local value = cachedData[source][scope][name]
                    if not value then 
                        cachedData[source][scope][name] = calls
                    else
                        cachedData[source][scope][name] = value + calls
                    end
                end
            end
        end
    end

    return cachedData
end