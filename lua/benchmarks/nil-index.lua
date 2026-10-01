---@diagnostic disable: need-check-nil

-- Loop parameter 10000, 5 000 000 accesses per run, outliers removed. ns/access includes the
-- inner loop overhead, about 3.3 ns (the cost of the "missing root" guards, which only test t).
--
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | Name                                | Expression                      | Samples | Mean ms | Dev ms | ns/access |
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Index table"                       | t.a                             |      58 |   18.79 |   0.46 |      3.76 |
-- | "Index nil"                         | t.a                             |      57 |   39.87 |   0.62 |      7.97 |
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Chain, present"                    | t.a.b.c                         |      58 |   62.37 |   1.09 |     12.47 |
-- | "Chain, missing middle"             | t.a.b.c                         |      51 |   76.88 |   0.65 |     15.38 |
-- | "Chain, missing root"               | t.a.b.c                         |      54 |  102.72 |   1.58 |     20.54 |
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Guarded chain, present"            | t and t.a and t.a.b and t.a.b.c |      57 |  138.64 |   1.18 |     27.73 |
-- | "Guarded chain, missing middle"     | t and t.a and t.a.b and t.a.b.c |      55 |   90.00 |   1.33 |     18.00 |
-- | "Guarded chain, missing root"       | t and t.a and t.a.b and t.a.b.c |      50 |   16.86 |   0.43 |      3.37 |
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Root guarded chain, present"       | t and t.a.b.c                   |     150 |   69.80 |   1.10 |     13.96 |
-- | "Root guarded chain, missing middle"| t and t.a.b.c                   |      87 |   84.12 |   1.05 |     16.82 |
-- | "Root guarded chain, missing root"  | t and t.a.b.c                   |     137 |   16.34 |   0.50 |      3.27 |
-- |-------------------------------------|---------------------------------|---------|---------|--------|-----------|
--
-- The profiler's "paired" and "ratio" modes don't apply here: the empty baseline loop of 10000
-- iterations measures as 0, so they report 0 and infinity.
--
-- Conclusions:
-- - Indexing nil works, but costs more than indexing a table: about 4.7 ns against 0.5 ns once the
--   loop overhead is subtracted. Each nil index in a chain adds a few ns over a table index.
-- - A full `and` guard re-reads every prefix of the chain. When the chain is present it costs over
--   twice the unguarded chain (27.7 vs 12.5 ns), and it is still slower when the chain breaks in
--   the middle (18.0 vs 15.4 ns). It only wins when the root is nil (3.4 vs 20.5 ns).
-- - A root-only guard costs about 1.5 ns over the unguarded chain when the root exists (14.0 vs
--   12.5 ns, 16.8 vs 15.4 ns) and saves about 17 ns when the root is nil (3.3 vs 20.5 ns). It
--   breaks even when the root is nil about 8% of the time.
-- - Recommendation: never write full `and` guards for nil safety. Rely on implicit nil-safe chains
--   (`if t.a.b then`) when the root is almost always present. Guard only the root (`t and t.a.b`)
--   when it is nil in more than a few percent of calls. Where a prefix is used more than once, read
--   it into a local (see table-sub.lua).

-- LuaPlus returns nil when indexing nil instead of raising an error. A lot of code relies on this
-- to write implicit nil checks in access chains, such as `if t.a.b then`. This benchmark compares
-- the cost of those chains against explicit `and` guards on every link and on the root only, for
-- chains that are present, missing at the root and missing in the middle.

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
    RootGuardedPresent = "Root guarded chain, present",
    RootGuardedMissingRoot = "Root guarded chain, missing root",
    RootGuardedMissingMiddle = "Root guarded chain, missing middle",
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

function RootGuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function RootGuardedMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end

function RootGuardedMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
            v = t and t.a.b.c
        end
    end

    local final = timer()
    return final - start
end
