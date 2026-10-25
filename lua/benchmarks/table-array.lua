
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Array - 1"             |      27 |  0.2498 |     0.0058 |      2.34 | 0.0148 |  5.91 |    0.2441 | 0.2136 | 0.2747 |  0.48 |
-- | "Array - 2"             |      28 |  0.5112 |     0.0076 |      1.49 | 0.0197 |  3.85 |    0.5188 | 0.4883 | 0.5493 |  0.25 |
-- | "Array - 4"             |      28 |  0.9624 |     0.0135 |      1.40 | 0.0347 |  3.61 |    0.9460 | 0.9155 | 1.0376 |  0.64 |
-- | "Array - 8"             |      29 |  2.1731 |     0.0994 |      4.57 | 0.2613 | 12.02 |    2.1362 | 1.8616 | 2.8076 |  1.00 |
-- | "Array - 16"            |      28 |  3.7667 |     0.0502 |      1.33 | 0.1293 |  3.43 |    3.7994 | 3.5095 | 4.0283 | -0.09 |
-- | "Array Cached - 1"      |      27 |  0.2622 |     0.0122 |      4.65 | 0.0308 | 11.75 |    0.2441 | 0.2136 | 0.3357 |  1.05 |
-- | "Array Cached - 2"      |      28 |  0.3379 |     0.0064 |      1.89 | 0.0165 |  4.87 |    0.3357 | 0.3052 | 0.3662 |  0.07 |
-- | "Array Cached - 4"      |      31 |  0.5139 |     0.0082 |      1.60 | 0.0224 |  4.36 |    0.5188 | 0.4883 | 0.5493 |  0.24 |
-- | "Array Cached - 8"      |      30 |  0.8596 |     0.0196 |      2.28 | 0.0526 |  6.12 |    0.8545 | 0.7935 | 0.9766 |  0.65 |
-- | "Array Cached - 16"     |      28 |  1.6109 |     0.0248 |      1.54 | 0.0640 |  3.97 |    1.5869 | 1.5259 | 1.7395 |  0.55 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Baseline, 1 parameter" |     312 |  0.0397 |     0.0016 |      3.92 | 0.0140 | 35.32 |    0.0305 | 0.0305 | 0.0610 |  0.86 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Array - 1", "Array - 2", "Array
-- Cached - 1", "Array Cached - 2", "Array Cached - 4".

-- The speed up of just caching is astounding - even in the situation where we cache it for a 
-- single use. When we look at the byte code we see the following pattern:
-- Array:       GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD
-- ArrayCached: GETTABLE, GETTABLE, GETTABLE, GETTABLE, ADD, ADD, ADD, ADD

-- I can not confirm it, but I suspect the get table is optimized to quickly get several 
-- elements in succession. This may be just the cacheline of the CPU, but we see a similar 
-- behavior with the hashed part of a table.


ModuleName = "Table Array"
BenchmarkData = {
    Array01 = "Array - 1",
    Array02 = "Array - 2",
    Array04 = "Array - 4",
    Array08 = "Array - 8",
    Array16 = "Array - 16",
    ArrayCached01 = "Array Cached - 1",
    ArrayCached02 = "Array Cached - 2",
    ArrayCached04 = "Array Cached - 4",
    ArrayCached08 = "Array Cached - 8",
    ArrayCached16 = "Array Cached - 16",
}

function Array01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function Array16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]

        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
        a = 0 + element[1] + element[2] + element[3] + element[4]
    end

    local final = timer()
    return final - start
end

function ArrayCached01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end


function ArrayCached16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { 1, 1, 1, 1 }

    local a
    local start = timer()

    for _ = 1, loop do
        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4

        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
        a = 0 + el1 + el2 + el3 + el4
    end

    local final = timer()
    return final - start
end
