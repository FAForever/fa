local CreateEmptyProfilerTable = import("/lua/shared/profiler.lua").CreateEmptyProfilerTable

local cache = {}

--- Flattens the profiler data in a single list, can be tweaked using filter parameters
---@param data ProfilerData data as described at the top of this file
---@param growth? ProfilerGrowth
---@param filterSource? ProfilerSource Filter on the source
---@param filterScope? ProfilerScope Filter on the scope
---@param filterName? string Filter on the name of the function
---@return ProfilerFunctionData[]
---@return number
function Format(data, growth, filterSource, filterScope, filterName)
    growth = growth or {}
    if filterName then
        filterName = filterName:lower()
    end

    -- reset cache
    local cache = cache
    local head = 1

    -- loop over data
    -- Lua, C or main
    for source, sourceData in data do
        -- skip content that we're not interested in
        if filterSource and source ~= filterSource then
            continue
        end

        -- global, local, method, field or other (empty)
        for scope, scopeData in sourceData do
            if filterScope and scope ~= filterScope then
                continue
            end
            local scopeGrowth = growth[scope]

            -- name of function and value
            for name, value in scopeData do
                -- skip content that we're not interested in
                if filterName and not name:lower():find(filterName) then
                    continue
                end

                -- may be set to false
                if value then
                    -- attempt to retrieve an element
                    local element = cache[head]
                    if not element then
                        element = {}
                        cache[head] = element
                    end
                    -- element is used
                    head = head + 1

                    -- populate element
                    element.growth = scopeGrowth[name] or 0
                    element.name = name
                    element.nameLower = name:lower()
                    element.scope = scope
                    element.source = source
                    element.value = value
                end
            end
        end
    end

    -- return valid information
    return cache, head - 1
end

--- Applies insertion sort on the cache based on the provided field
--- copied from: https://github.com/akosma/CodeaSort/blob/master/InsertionSort.lua
---@param cache ProfilerScopeData
---@param count number of elements in cache
---@param field ProfilerField Field we want to sort on
---@param reverse? boolean
function Sort(cache, count, field, reverse)
    -- sort only on lowered strings
    if field == "name" then
        field = "nameLower"
    end

    -- numbers are sorted descending by default
    if type(cache[1][field]) == "number" then
        reverse = not reverse
    end

    -- insertion sort
    if reverse then
        for j = 2, count do
            local replacing = cache[j]
            local value = replacing[field]
            local i = j - 1
            local comparing = cache[i]
            while i > 0 and comparing[field] < value do
                cache[i + 1] = comparing
                i = i - 1
                comparing = cache[i]
            end
            cache[i + 1] = replacing
        end
    else
        for j = 2, count do
            local replacing = cache[j]
            local value = replacing[field]
            local i = j - 1
            local comparing = cache[i]
            while i > 0 and comparing[field] > value do
                cache[i + 1] = comparing
                i = i - 1
                comparing = cache[i]
            end
            cache[i + 1] = replacing
        end
    end
    return cache, count
end

local lookupCache = {}
---@param data ProfilerData
---@return ProfilerGrowth
function LookUp(data)
    -- reset the cache
    for key, _ in lookupCache do
        lookupCache[key] = false
    end

    -- populate the lookup cache

    -- Lua, C or main
    for _, sourceData in data do
        -- global, local, method, field or other (empty)
        for scope, scopeData in sourceData do
            local scopeInfo = lookupCache[scope]
            if not scopeInfo then
                scopeInfo = {}
                lookupCache[scope] = scopeInfo
            end
            -- name of function and number of calls
            for name, calls in scopeData do
                if calls then
                    local value = scopeInfo[name]
                    if value then
                        scopeInfo[name] = calls + value
                    else
                        scopeInfo[name] = calls
                    end
                end
            end
        end
    end

    return lookupCache
end

local cachedData = CreateEmptyProfilerTable()
---@param arrays ProfilerData[]
---@return ProfilerData
function Combine(arrays)
    -- reset the cache
    local cachedData = cachedData

    -- Lua, C or main
    for _, sourceData in cachedData do
        -- global, local, method, field or other (empty)
        for _, scopeData in sourceData do
            -- name of function and number of calls
            for name, _ in scopeData do
                scopeData[name] = false
            end
        end
    end

    -- combine the input into one large profile data structure

    for _, info in arrays do
        -- Lua, C or main
        for source, sourceInfo in info.data do
            -- global, local, method, field or other (empty)
            local sourceData = cachedData[source]
            for scope, scopeInfo in sourceInfo do
                -- name of function and number of calls
                local scopeData = sourceData[scope]
                for name, calls in scopeInfo do
                    local value = scopeData[name]
                    if value then
                        scopeData[name] = calls + value
                    else
                        scopeData[name] = calls
                    end
                end
            end
        end
    end

    return cachedData
end