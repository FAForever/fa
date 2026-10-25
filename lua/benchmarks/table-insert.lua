
-- Results with loop count 200000:
--
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                     | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Assign from Head"       |      30 |  2.8035 |     0.0260 |      0.93 | 0.0697 | 2.49 |    2.8076 |  2.6245 |  2.9907 | -0.14 |
-- | "Table index assignment" |      29 |  2.4393 |     0.0181 |      0.74 | 0.0475 | 1.95 |    2.4414 |  2.3804 |  2.5635 |  0.49 |
-- | "Assign from Count"      |      30 |  2.8442 |     0.0303 |      1.06 | 0.0811 | 2.85 |    2.8076 |  2.6855 |  2.9907 | -0.04 |
-- | "Global table.insert"    |      28 | 21.5977 |     0.0530 |      0.25 | 0.1367 | 0.63 |   21.6064 | 21.3623 | 21.8506 |  0.08 |
-- | "Local table.insert"     |      29 | 19.0030 |     0.0719 |      0.38 | 0.1890 | 0.99 |   18.9819 | 18.7378 | 19.4092 |  0.45 |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"  |     145 |  0.7547 |     0.0052 |      0.69 | 0.0320 | 4.24 |    0.7324 |  0.6714 |  0.7935 |  0.12 |
-- |--------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Conclusion: avoiding the table operations is always a benefit, especially when
-- you cache the function call directly to prevent the table operation. Assigning by index is 7.8x
-- faster than a local `table.insert`, and a global `table.insert` is 1.14x slower than a local one.

-- "Assign from Count" (add, then use the count) and "Assign from Head" (use the head, then add) are
-- within 2% of each other, so the order doesn't matter. Older results suggested that using the value
-- before adding to it avoids a pipeline stall, but each Lua instruction costs far more than a stall.


ModuleName = "Table Insert"
ModuleLoopCount = 200000
BenchmarkData = {
    AddInsertGlobal = "Global table.insert",
    AddInsertLocal = "Local table.insert",
    AddIndexReused = "Table index assignment",
    AddIndexSize = "Assign from Count",
    AddIndexHead = "Assign from Head",
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