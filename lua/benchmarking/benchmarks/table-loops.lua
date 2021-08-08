
-- prepare data
local data = { }

for k = 1, 100 do 
    data[k] = k
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.21369934082031

function ForGetn()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local x = 0
        for k = 1, table.getn(data) do 
            x = x + data[k]
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.37042236328125

function ForPairs()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local x = 0
        for k, v in pairs(data) do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.39227294921875

function ForiPairs()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local x = 0
        for k, v in ipairs(data) do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.3626708984375

function Foreach()
    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local x = 0
        for k, v in data do 
            x = x + v
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 8.1476287841797 

-- function WhileGetn()

--     local start = GetSystemTimeSecondsOnlyForProfileUse()

--     for k = 1, 100000 do 
--         local k = 1
--         local x = 0
--         while k < table.getn(data) do 
--             x = x + data[k]
--             k = k + 1
--         end
--     end

--     local final = GetSystemTimeSecondsOnlyForProfileUse()

--     return final - start
-- end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.257568359375

function WhileGetnCached()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
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