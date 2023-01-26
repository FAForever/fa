
-- ForGetn:         259 ms
-- ForPairs:        372 ms
-- Foreach:         370 ms
-- ForiPairs:       405 ms
-- WhileGetNCached: 293 ms
-- WhileGetn:       8140 ms

-- Whenever table.insert is used for a table then you can use the cheaper
-- looping structure. However, when typical hashes are involved this cheaper
-- version will not reach all the elements of the table.

local outerLoop = 100000

-- prepare data
local data = { }

for k = 1, 20 do 
    data[k] = k
end

function ForGetn()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local x = 0
        for k = 1, table.getn(data) do 
            x = x + data[k]
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function ForPairs()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local x = 0
        for k, v in pairs(data) do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ForiPairs()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local x = 0
        for k, v in ipairs(data) do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function Foreach()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local x = 0
        for k, v in data do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function WhileGetn()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local k = 1
        local x = 0
        while k < table.getn(data) do 
            x = x + data[k]
            k = k + 1
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function WhileGetnCached()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local k = 1
        local x = 0
        local n = table.getn(data)
        while k < n do 
            x = x + data[k]
            k = k + 1
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end