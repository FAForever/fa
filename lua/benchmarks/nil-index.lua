---@diagnostic disable: need-check-nil

-- LuaPlus returns nil when indexing nil instead of raising an error, so `if t.a.b then` is safe
-- when `t` or `t.a` is nil. A lot of code relies on this instead of writing explicit nil checks.

-- Loop parameter: 10000. ns/access includes about 3.3 ns of loop overhead (the missing root guards).
--
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | Name                                  | Expression                      | Samples | Mean ms | Dev ms | ns/access |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Index table"                         | t.a                             |      58 |   18.79 |   0.46 |      3.76 |
-- | "Index nil"                           | t.a                             |      57 |   39.87 |   0.62 |      7.97 |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Chain, present"                      | t.a.b.c                         |      58 |   62.37 |   1.09 |     12.47 |
-- | "Chain, missing middle"               | t.a.b.c                         |      51 |   76.88 |   0.65 |     15.38 |
-- | "Chain, missing root"                 | t.a.b.c                         |      54 |  102.72 |   1.58 |     20.54 |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Guarded chain, present"              | t and t.a and t.a.b and t.a.b.c |      57 |  138.64 |   1.18 |     27.73 |
-- | "Guarded chain, missing middle"       | t and t.a and t.a.b and t.a.b.c |      55 |   90.00 |   1.33 |     18.00 |
-- | "Guarded chain, missing root"         | t and t.a and t.a.b and t.a.b.c |      50 |   16.86 |   0.43 |      3.37 |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Root guarded chain, present"         | t and t.a.b.c                   |     150 |   69.80 |   1.10 |     13.96 |
-- | "Root guarded chain, missing middle"  | t and t.a.b.c                   |      87 |   84.12 |   1.05 |     16.82 |
-- | "Root guarded chain, missing root"    | t and t.a.b.c                   |     137 |   16.34 |   0.50 |      3.27 |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
-- | "Local guarded chain, present"        | if t then local a = t.a         |      55 |   85.83 |   1.58 |     17.17 |
-- | "Local guarded chain, missing middle" | if a then local b = a.b         |      59 |   73.03 |   1.41 |     14.61 |
-- | "Local guarded chain, missing root"   | if b then v = b.c               |      59 |   16.60 |   0.00 |      3.32 |
-- |---------------------------------------|---------------------------------|---------|---------|--------|-----------|
--
-- Analysis:
-- - Indexing nil is 2.1x slower than indexing a table.
-- - Guarding every link with `and` re-reads `t.a` and `t.a.b` at each step. It is 2.2x slower than
--   the unguarded chain when the chain is present and 1.2x slower when it breaks in the middle. It
--   is only faster when `t` is nil, by 6.1x.
-- - Guarding only `t` is 1.1x slower than the unguarded chain when `t` exists and 6.3x faster when
--   `t` is nil. It breaks even when `t` is nil in about 8% of calls.
-- - Nested `if`s with a local per link are 1.2x slower than guarding only `t` when the chain is
--   present, and 1.05x faster than the unguarded chain when it breaks in the middle. The gain does
--   not justify the harder to read code.
--
-- Conclusion:
-- - Don't guard every link with `and` for nil safety.
-- - Write `if t.a.b then` when `t` is almost always present.
-- - Write `if t and t.a.b then` when `t` is nil in more than about 8% of calls.
-- - When the same `t.a` is read more than once, read it into a local (see table-sub.lua).

-- The access is repeated 10 times per inner iteration so the loop instructions are a smaller part
-- of each measurement.

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

function LocalGuardedPresent(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local t = { a = { b = { c = 1 } } }
    local v
    local start = timer()

    for _ = 1, loop do
        for _ = 1, 50 do
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
        for _ = 1, 50 do
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
        for _ = 1, 50 do
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
    end

    local final = timer()
    return final - start
end
