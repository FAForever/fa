---@diagnostic disable: need-check-nil

-- LuaPlus returns nil when indexing nil instead of raising an error, so `if t.a.b then` is safe
-- when `t` or `t.a` is nil. A lot of code relies on this instead of writing explicit nil checks.
-- This benchmark measures the cost of indexing nil, and compares implicit nil checks in access
-- chains against explicit ones.

-- Results with loop count 500000, with 10 accesses per loop. ns/access includes about 3.1 ns of
-- loop overhead (the missing root guards).
--
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | Name                                  | Expression                      | Samples |   Mean ms | +/- 95% ms | +/- 95% % |  Dev ms | CV % | Median ms |    Min ms |    Max ms |  Skew | ns/access |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Index table"                         | t.a                             |      27 |   18.6898 |     0.1638 |      0.88 |  0.4139 | 2.21 |   18.7073 |   18.0359 |   19.6304 |  0.49 |      3.74 |
-- | "Index nil"                           | t.a                             |      26 |   40.7474 |     0.3031 |      0.74 |  0.7501 | 1.84 |   40.7295 |   39.1846 |   42.3584 | -0.07 |      8.15 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Chain, present"                      | t.a.b.c                         |      28 |   60.9491 |     0.4007 |      0.66 |  1.0334 | 1.70 |   60.9970 |   59.1812 |   63.1256 |  0.35 |     12.19 |
-- | "Chain, missing middle"               | t.a.b.c                         |      27 |   75.4864 |     0.2765 |      0.37 |  0.6988 | 0.93 |   75.4318 |   73.9746 |   76.9501 | -0.09 |     15.10 |
-- | "Chain, missing root"                 | t.a.b.c                         |      28 |  101.2358 |     0.2719 |      0.27 |  0.7010 | 0.69 |  101.1658 |  100.1892 |  102.5009 |  0.04 |     20.25 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Guarded chain, present"              | t and t.a and t.a.b and t.a.b.c |      27 |  137.9700 |     0.2125 |      0.15 |  0.5371 | 0.39 |  137.8632 |  137.1460 |  139.3204 |  0.59 |     27.59 |
-- | "Guarded chain, missing middle"       | t and t.a and t.a.b and t.a.b.c |      26 |   89.0832 |     0.6866 |      0.77 |  1.6995 | 1.91 |   89.1380 |   86.0596 |   93.0862 |  0.25 |     17.82 |
-- | "Guarded chain, missing root"         | t and t.a and t.a.b and t.a.b.c |      27 |   15.7239 |     0.0798 |      0.51 |  0.2016 | 1.28 |   15.7318 |   15.3503 |   16.1285 |  0.18 |      3.14 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Root guarded chain, present"         | t and t.a.b.c                   |      25 |   68.0365 |     0.1652 |      0.24 |  0.4002 | 0.59 |   68.0389 |   67.4744 |   69.1528 |  0.92 |     13.61 |
-- | "Root guarded chain, missing middle"  | t and t.a.b.c                   |      28 |   83.5555 |     0.3165 |      0.38 |  0.8162 | 0.98 |   83.7097 |   82.4127 |   85.2966 |  0.20 |     16.71 |
-- | "Root guarded chain, missing root"    | t and t.a.b.c                   |      26 |   15.4073 |     0.0831 |      0.54 |  0.2057 | 1.34 |   15.3809 |   14.9231 |   15.8997 |  0.38 |      3.08 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Local guarded chain, present"        | if t then local a = t.a         |      23 |   84.6233 |     0.3305 |      0.39 |  0.7642 | 0.90 |   84.6405 |   83.1451 |   86.6089 |  0.47 |     16.92 |
-- | "Local guarded chain, missing middle" | if a then local b = a.b         |      26 |   71.9701 |     0.2595 |      0.36 |  0.6422 | 0.89 |   71.7926 |   70.6711 |   73.1812 |  0.13 |     14.39 |
-- | "Local guarded chain, missing root"   | if b then v = b.c               |      30 |   15.4912 |     0.0666 |      0.43 |  0.1784 | 1.15 |   15.4648 |   15.2130 |   15.8157 |  0.17 |      3.10 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
--
-- Analysis:
-- - Indexing nil is 2.2x slower than indexing a table.
-- - Guarding every link with `and` re-reads `t.a` and `t.a.b` at each step. It is 2.3x slower than
--   the unguarded chain when the chain is present and 1.2x slower when it breaks in the middle. It
--   is only faster when `t` is nil, by 6.4x.
-- - Guarding only `t` is 1.1x slower than the unguarded chain when `t` exists and 6.6x faster when
--   `t` is nil. It breaks even when `t` is nil in about 8% of calls.
-- - Nested `if`s with a local per link are 1.2x slower than guarding only `t` when the chain is
--   present, and 1.05x faster than the unguarded chain when it breaks in the middle. The gain does
--   not justify the harder to read code.
--
-- Conclusion:
-- - Don't guard every link with `and` for nil safety.
-- - Write `if t.a.b then` when `t` is almost always present.
-- - Write `if t and t.a.b then` when `t` is nil in more than about 8% of calls.

-- The access is repeated 10 times per iteration so the loop instructions are a smaller part
-- of each measurement.

ModuleName = "Nil Indexing"
ModuleLoopCount = 500000
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
    LocalGuardedPresent = "Local guarded chain, present",
    LocalGuardedMissingRoot = "Local guarded chain, missing root",
    LocalGuardedMissingMiddle = "Local guarded chain, missing middle",
}

function IndexTable(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = 1 }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function IndexNil(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function ChainPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function ChainMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function ChainMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function GuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function GuardedMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function GuardedMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function RootGuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function RootGuardedMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function RootGuardedMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
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

    local final = timer()
    return final - start
end

function LocalGuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
    end

    local final = timer()
    return final - start
end

function LocalGuardedMissingRoot(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = nil
    local v
    local start = timer()

    for _ = 1, loop do
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
    end

    local final = timer()
    return final - start
end

function LocalGuardedMissingMiddle(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = {} }
    local v
    local start = timer()

    for _ = 1, loop do
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
        if t then
            local a = t.a
            if a then
                local b = a.b
                if b then
                    v = b.c
                end
            end
        end
    end

    local final = timer()
    return final - start
end
