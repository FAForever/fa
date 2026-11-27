
-- Results with loop count 200000:
--
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|-------|
-- | Name                          | Samples |  Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |   Min ms |   Max ms |  Skew |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|-------|
-- | "Assign from Head"            |      29 |   2.8476 |     0.0263 |      0.92 | 0.0693 | 2.43 |    2.8381 |   2.7466 |   2.9907 |  0.23 |
-- | "Table index assignment"      |      28 |   2.4523 |     0.0191 |      0.78 | 0.0493 | 2.01 |    2.4719 |   2.3804 |   2.5635 |  0.45 |
-- | "Assign from Count"           |      28 |   2.8730 |     0.0275 |      0.96 | 0.0708 | 2.47 |    2.8687 |   2.7466 |   3.0212 |  0.16 |
-- | "Global table.insert"         |      30 |  22.1924 |     0.1441 |      0.65 | 0.3859 | 1.74 |   22.3389 |  21.6064 |  22.9187 | -0.07 |
-- | "Local table.insert"          |      30 |  19.5811 |     0.1437 |      0.73 | 0.3850 | 1.97 |   19.6533 |  18.9209 |  20.3552 | -0.11 |
-- | "Assign from Head (x50)"      |      28 | 140.6656 |     0.4414 |      0.31 | 1.1381 | 0.81 |  140.3847 | 138.6948 | 142.9901 |  0.52 |
-- | "Assign from Count (x50)"     |      27 | 143.3190 |     0.3570 |      0.25 | 0.9023 | 0.63 |  143.1274 | 141.3879 | 144.9814 |  0.17 |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|-------|
-- | "Baseline, 1 parameter"       |     122 |   0.7387 |     0.0037 |      0.51 | 0.0211 | 2.86 |    0.7324 |   0.7019 |   0.7629 | -0.29 |
-- | "Baseline, 1 parameter (x50)" |      60 |  38.4118 |     0.2923 |      0.76 | 1.1321 | 2.95 |   38.5551 |  36.6592 |  40.7181 |  0.11 |
-- |-------------------------------|---------|----------|------------|-----------|--------|------|-----------|----------|----------|-------|

-- Conclusion: avoiding the table operations is always a benefit, especially when
-- you cache the function call directly to prevent the table operation. Assigning by index is 8x
-- faster than a local `table.insert`, and a global `table.insert` is 1.13x slower than a local one.

-- "Assign from Head" (use the head, then add) is 1.9% faster than "Assign from Count" (add, then use
-- the count) with the x50 multiplier, about 0.3 ns or one CPU cycle per assignment. That fits a short
-- stall from using a value right after computing it, but it is too small to matter.


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