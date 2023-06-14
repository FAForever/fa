
-- ForGetn:         259 ms
-- ForPairs:        372 ms
-- Foreach:         370 ms
-- ForiPairs:       405 ms
-- WhileGetNCached: 293 ms
-- WhileGetn:       8140 ms

-- Whenever table.insert is used for a table then you can use the cheaper
-- looping structure. However, when typical hashes are involved this cheaper
-- version will not reach all the elements of the table.

ModuleName = "Table Loops"
BenchmarkData = {
    ForGetn = "For table.getn",
    ForPairs = "For pairs",
    ForiPairs = "For ipairs",
    Foreach = "For each",
    WhileGetn = "While table.getn",
    WhileGetnCached = "While cache table.getn",
}

-- prepare data
local data = {}

for k = 1, 20 do
    data[k] = 1
end

function ForGetn(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        for k = 1, table.getn(data) do
        end
    end

    local final = timer()
    return final - start
end

function ForPairs(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        for k, v in pairs(data) do
        end
    end

    local final = timer()
    return final - start
end

function ForiPairs(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        for k, v in ipairs(data) do
        end
    end

    local final = timer()
    return final - start
end

function Foreach(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        for k, v in data do
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function WhileGetn(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        local k = 1
        while k < table.getn(data) do
            k = k + 1
        end
    end

    local final = timer()
    return final - start
end

function WhileGetnCached(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        local k = 1
        local n = table.getn(data)
        while k < n do
            k = k + 1
        end
    end

    local final = timer()
    return final - start
end