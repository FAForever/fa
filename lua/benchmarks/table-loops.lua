-- |-------------------------------|---------|--------|---------|
-- | Name                          | Mean ms | 3x Dev | Hashes? |
-- |-------------------------------|---------|--------|---------|
-- | "For table.getn upvalued"     |    3.32 |   0.17 |    N    |
-- | "For table.getn"              |    3.42 |   0.14 |    N    |
-- | "While cache table.getn"      |    3.84 |   0.14 |    N    |
-- | "For ipairs upvalued"         |    5.88 |   0.05 |    N    |
-- | "For ipairs"                  |    5.89 |   0.11 |    N    |
-- | "While table.getn"            |   37.22 |   0.89 |    N    |
-- |-------------------------------|---------|--------|---------|
-- | "For next upvalued"           |    4.88 |   0.25 |    Y    |
-- | "For each"                    |    4.91 |   0.20 |    Y    |
-- | "For next"                    |    4.93 |   0.18 |    Y    |
-- | "For each with next upvalued" |    4.96 |   0.19 |    Y    |
-- | "For pairs upvalued"          |    5.21 |   0.70 |    Y    |
-- | "For pairs"                   |    5.23 |   0.17 |    Y    |
-- |-------------------------------|---------|--------|---------|
--
-- Conclusions: 
-- - Use `for i = 1, TableGetN(t) do local v = t[i]` for arrays (1.5x faster than `pairs`)
--   - Don't use `table.insert` when traversing arrays
-- - Use `for k, v in t` for tables

ModuleName = "Table Loops"
BenchmarkData = {
    ForGetn = "For table.getn",
    ForPairs = "For pairs",
    ForiPairs = "For ipairs",
    Foreach = "For each",
    WhileGetn = "While table.getn",
    WhileGetnCached = "While cache table.getn",
    ForGetnUpval = "For table.getn upvalued",
    ForPairsUpval = "For pairs upvalued",
    ForNext = "For next",
    ForNextUpval = "For next upvalued",
    ForEachUpval = "For each with next upvalued",
    ForiPairsUpval = "For ipairs upvalued",
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
            local v = data[k]
        end
    end

    local final = timer()
    return final - start
end
function ForGetnUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    local TableGetN = table.getn
    for _ = 1, loop do
        for k = 1, TableGetN(data) do
            local v = data[k]
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

function ForPairsUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    local pairs = pairs
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

function ForiPairsUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    local ipairs = ipairs
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

    -- engine imports global `next`
    for _ = 1, loop do
        for k, v in data do
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ForEachUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    -- engine imports global `next`
    local next = next
    for _ = 1, loop do
        for k, v in data do
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ForNext(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        for k, v in next, data do
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ForNextUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    local next = next
    for _ = 1, loop do
        for k, v in next, data do
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
            local v = data[k]
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
            local v = data[k]
        end
    end

    local final = timer()
    return final - start
end