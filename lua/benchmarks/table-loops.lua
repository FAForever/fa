-- |-------------------------------|---------|--------|---------|
-- | Name                          | Mean ms | 3x Dev | Hashes? |
-- |-------------------------------|---------|--------|---------|
-- | "For table.getn upvalued"     |   8.02  | 0.22   |    N    |
-- | "For table.getn"              |   8.06  | 0.36   |    N    |
-- | "While cache table.getn"      |   8.43  | 0.26   |    N    |
-- | "For ipairs upvalued"         | 146.    | 4.0    |    N    |
-- | "For ipairs"                  | 146.    | 2.3    |    N    |
-- | "While table.getn"            | 162.    | 7.1    |    N    |
-- |-------------------------------|---------|--------|---------|
-- | "For each with next upvalued" | 231.    | 4.6    |    Y    |
-- | "For each"                    | 232.    | 5.1    |    Y    |
-- | "For next upvalued"           | 232.    | 5.8    |    Y    |
-- | "For next"                    | 233.    | 4.2    |    Y    |
-- | "For pairs upvalued"          | 238.    | 5.2    |    Y    |
-- | "For pairs"                   | 238.    | 4.5    |    Y    |
-- |-------------------------------|---------|--------|---------|
--
-- Conclusions: 
-- - Use `for i = 1, TableGetN({})` for arrays 
--   - Don't use `table.insert` when traversing arrays
-- - Use `for k, v in {}` for tables

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