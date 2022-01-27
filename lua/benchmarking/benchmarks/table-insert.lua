
-- AddInsertGlobal:     46 ms
-- AddInsertLocal:      16.35 ms
-- AddIndex:            2.19 ms
-- AddGetnLocal:        34699.70 ms
-- AddGetnGlobal:       34751.95 ms
-- AddCount:            2.68 ms
-- AddCountAlt:         2.19 ms

-- Conclusion: avoiding the table operations is always a benefit, especially when
-- you cache the function call directly to prevent the table operation. 

-- The difference between AddCount and AddCountAlt can be explained by understanding
-- how the processor works. Internally the processor is one large pipeline, where
-- an instructions keep being fed on one side. It passes through various phases,
-- such as decoding and executing. However - if there is a functional dependency
-- then an instruction has to wait (stall the pipeline) because it needs the result
-- of the previous instruction to know what to do. 

-- That is what happens when we first add and then use the value, instead of using 
-- the value and then adding to it.

function AddInsertGlobal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = { }
    for k = 1, 100000 do
        table.insert(a, k)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end


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

function AddIndex()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local a = { }
    for k = 1, 100000 do
        a[k] = k 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

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