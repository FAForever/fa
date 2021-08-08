
-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.046

function AddInsertGlobal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = { }
    for k = 1, 100000 do
        table.insert(a, k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.016357421875

function AddInsertLocal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- to local scope
    local TableInsert = table.insert

    local a = { }
    for k = 1, 100000 do
        TableInsert(a, k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.002197265625

function AddIndex()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = { }
    for k = 1, 100000 do
        a[k] = k 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 34.751953125

-- function AddGetnGlobal()

--     local start = GetSystemTimeSecondsOnlyForProfileUse()

--     local TableGetn = table.getn

--     local a = { }
--     for k = 1, 100000 do
--         a[table.getn(a) + 1] = k 
--     end

--     local final = GetSystemTimeSecondsOnlyForProfileUse()

--     return final - start

-- end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 34.69970703125

-- function AddGetnLocal()

--     local start = GetSystemTimeSecondsOnlyForProfileUse()

--     local TableGetn = table.getn

--     local a = { }
--     for k = 1, 100000 do
--         a[TableGetn(a) + 1] = k 
--     end

--     local final = GetSystemTimeSecondsOnlyForProfileUse()

--     return final - start

-- end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.002685546875

function AddCount()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local count = 0

    local a = { }
    for k = 1, 100000 do
        count = count + 1
        a[count] = k 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.002197265625

function AddCountAlt()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local count = 1

    local a = { }
    for k = 1, 100000 do
        a[count] = k 
        count = count + 1
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end