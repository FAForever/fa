---@diagnostic disable: need-check-nil
-- No recorded results yet.

-- LuaPlus returns nil when indexing nil instead of raising an error. A lot of code relies on this
-- to write implicit nil checks in access chains, such as `if t.a.b then`. This benchmark compares
-- the cost of those chains against explicit `and` guards, for chains that are present, missing
-- at the root and missing in the middle.

-- A single access is too cheap to measure against the loop baseline, so each outer iteration runs
-- an inner loop of 50 iterations with the access unrolled 10 times: 500 accesses per outer
-- iteration. The inner loop overhead is the same for every benchmark in this file.

ModuleName = "Nil Indexing"
BenchmarkData = {
    IndexTable = "Index table",
    IndexNil = "Index nil",
    ChainPresent = "Chain, present",
    ChainMissingRoot = "Chain, missing root",
    ChainMissingMiddle = "Chain, missing middle",
    GuardedPresent = "Guarded chain, present",
    GuardedMissingRoot = "Guarded chain, missing root",
    GuardedMissingMiddle = "Guarded chain, missing middle",
}

function IndexTable(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = 1 }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
        end
    end

    local final = timer()
    return final - start
end

function IndexNil(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
            v = t.a
        end
    end

    local final = timer()
    return final - start
end

function ChainPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function ChainMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function ChainMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
            v = t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function GuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function GuardedMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function GuardedMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
            v = t and t.a and t.a.b and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end
