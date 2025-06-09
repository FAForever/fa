
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


ModuleName = "Table Insert"
BenchmarkData = {
    AddInsertGlobal = "Global table.insert",
    AddInsertLocal = "Local table.insert",
    AddIndex = "Table index assignment",
    AddCount = "Assign from Count",
    AddCountAlt = "Assign from Head",
}

function AddInsertGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local tbl = {}

    local a = 1
    local start = timer()

    for _ = 1, loop do
        table.insert(tbl, a)
    end

    local final = timer()
    return final - start
end


function AddInsertLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local a = {}

    local start = timer()

    -- to local scope
    local TableInsert = table.insert
    for k = 1, loop do
        TableInsert(a, k)
    end

    local final = timer()
    return final - start
end

function AddIndexReused(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local tbl = {}

    local a = 1
    local start = timer()

    for k = 1, loop do
        tbl[k] = a
    end

    local final = timer()
    return final - start
end

function AddIndexSize(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local tbl = {}

    local a = 1
    local start = timer()

    local tblSize = 0
    for _ = 1, loop do
        tblSize = tblSize + 1
        tbl[tblSize] = a
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function AddIndexHead(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local tbl = {}

    local a = 1
    local start = timer()

    local tblHead = 1
    for _ = 1, loop do
        tbl[tblHead] = a
        tblHead = tblHead + 1
    end

    local final = timer()
    return final - start
end