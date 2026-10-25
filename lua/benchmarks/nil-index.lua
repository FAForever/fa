---@diagnostic disable: need-check-nil

-- LuaPlus returns nil when indexing nil instead of raising an error, so `if t.a.b then` is safe
-- when `t` or `t.a` is nil. A lot of code relies on this instead of writing explicit nil checks.
-- This benchmark measures the cost of indexing nil, and compares implicit nil checks in access
-- chains against explicit ones.

-- Results with 10000 loops of 50, before the inner loop moved into the loop count of 500000. Each
-- loop does 10 accesses. ns/access includes about 3.2 ns of loop overhead (the missing root guards).
--
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | Name                                  | Expression                      | Samples |   Mean ms | +/- 95% ms | +/- 95% % |  Dev ms | CV % | Median ms |    Min ms |    Max ms |  Skew | ns/access |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Index table"                         | t.a                             |      28 |  18.80210 |    0.08998 |      0.48 | 0.23202 | 1.23 |  18.76831 |  18.49365 |  19.28711 |  0.77 |      3.76 |
-- | "Index nil"                           | t.a                             |      24 |  40.42943 |    0.16527 |      0.41 | 0.39133 | 0.97 |  40.51208 |  39.67285 |  41.10718 | -0.41 |      8.09 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Chain, present"                      | t.a.b.c                         |      27 |  61.87835 |    0.26894 |      0.43 | 0.67971 | 1.10 |  61.85913 |  60.86731 |  63.55286 |  0.48 |     12.38 |
-- | "Chain, missing middle"               | t.a.b.c                         |      27 |  77.40614 |    0.32396 |      0.42 | 0.81874 | 1.06 |  77.48413 |  76.08032 |  78.97949 |  0.07 |     15.48 |
-- | "Chain, missing root"                 | t.a.b.c                         |      26 | 102.92992 |    0.18457 |      0.18 | 0.45687 | 0.44 | 102.98157 | 102.09656 | 103.68347 | -0.23 |     20.59 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Guarded chain, present"              | t and t.a and t.a.b and t.a.b.c |      25 | 138.04810 |    0.29834 |      0.22 | 0.72272 | 0.52 | 138.06152 | 136.81030 | 139.43481 | -0.06 |     27.61 |
-- | "Guarded chain, missing middle"       | t and t.a and t.a.b and t.a.b.c |      26 |  90.16712 |    0.30176 |      0.33 | 0.74693 | 0.83 |  90.22522 |  88.71460 |  91.52222 | -0.07 |     18.03 |
-- | "Guarded chain, missing root"         | t and t.a and t.a.b and t.a.b.c |      25 |  16.06689 |    0.13178 |      0.82 | 0.31924 | 1.99 |  15.96069 |  15.68604 |  16.99829 |  1.33 |      3.21 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Root guarded chain, present"         | t and t.a.b.c                   |      27 |  69.19352 |    0.16928 |      0.24 | 0.42783 | 0.62 |  69.09180 |  68.45093 |  70.34302 |  0.72 |     13.84 |
-- | "Root guarded chain, missing middle"  | t and t.a.b.c                   |      27 |  84.90329 |    0.31042 |      0.37 | 0.78453 | 0.92 |  84.93042 |  83.28247 |  86.18164 | -0.25 |     16.98 |
-- | "Root guarded chain, missing root"    | t and t.a.b.c                   |      26 |  15.87149 |    0.02895 |      0.18 | 0.07166 | 0.45 |  15.86914 |  15.71655 |  15.99121 |  0.07 |      3.17 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
-- | "Local guarded chain, present"        | if t then local a = t.a         |      24 |  86.23505 |    0.26354 |      0.31 | 0.62401 | 0.72 |  86.24268 |  85.29663 |  87.73804 |  0.61 |     17.25 |
-- | "Local guarded chain, missing middle" | if a then local b = a.b         |      26 |  73.05204 |    0.35119 |      0.48 | 0.86929 | 1.19 |  73.01331 |  71.56372 |  74.67651 |  0.18 |     14.61 |
-- | "Local guarded chain, missing root"   | if b then v = b.c               |      24 |  15.99503 |    0.04169 |      0.26 | 0.09871 | 0.62 |  15.99121 |  15.80811 |  16.20483 |  0.15 |      3.20 |
-- |---------------------------------------|---------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|-----------|
--
-- Analysis:
-- - Indexing nil is 2.2x slower than indexing a table.
-- - Guarding every link with `and` re-reads `t.a` and `t.a.b` at each step. It is 2.2x slower than
--   the unguarded chain when the chain is present and 1.2x slower when it breaks in the middle. It
--   is only faster when `t` is nil, by 6.4x.
-- - Guarding only `t` is 1.1x slower than the unguarded chain when `t` exists and 6.5x faster when
--   `t` is nil. It breaks even when `t` is nil in about 8% of calls.
-- - Nested `if`s with a local per link are 1.2x slower than guarding only `t` when the chain is
--   present, and 1.06x faster than the unguarded chain when it breaks in the middle. The gain does
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
