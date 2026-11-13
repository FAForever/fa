
-- Results with loop count 100000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Array - 1"             |      44 |  2.6176 |     0.0139 |      0.53 | 0.0460 | 1.76 |    2.6245 |  2.5635 |  2.6855 |  0.18 |
-- | "Array - 2"             |      32 |  4.7760 |     0.0359 |      0.75 | 0.1005 | 2.10 |    4.7607 |  4.5776 |  4.9438 | -0.22 |
-- | "Array - 4"             |      30 |  9.6334 |     0.1488 |      1.54 | 0.3985 | 4.14 |    9.7046 |  8.9722 | 10.4980 |  0.09 |
-- | "Array - 8"             |      30 | 18.4102 |     0.1583 |      0.86 | 0.4239 | 2.30 |   18.3105 | 17.8223 | 19.2871 |  0.57 |
-- | "Array - 16"            |      29 | 36.8610 |     0.2511 |      0.68 | 0.6604 | 1.79 |   36.8042 | 35.5835 | 38.2690 |  0.08 |
-- | "Array Cached - 1"      |     116 |  2.6019 |     0.0165 |      0.63 | 0.0898 | 3.45 |    2.6245 |  2.4414 |  2.8076 |  0.03 |
-- | "Array Cached - 2"      |      27 |  3.3841 |     0.0350 |      1.03 | 0.0885 | 2.62 |    3.4180 |  3.2349 |  3.5400 | -0.26 |
-- | "Array Cached - 4"      |      29 |  4.9944 |     0.0346 |      0.69 | 0.0909 | 1.82 |    5.0049 |  4.8218 |  5.1880 |  0.28 |
-- | "Array Cached - 8"      |      25 |  8.3838 |     0.1620 |      1.93 | 0.3924 | 4.68 |    8.3008 |  7.8735 |  9.5215 |  1.18 |
-- | "Array Cached - 16"     |      25 | 15.2979 |     0.0539 |      0.35 | 0.1305 | 0.85 |   15.2588 | 15.0757 | 15.5640 |  0.48 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |     424 |  0.3802 |     0.0035 |      0.93 | 0.0372 | 9.77 |    0.3662 |  0.3052 |  0.6714 |  3.60 |
-- |-------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Caching makes no difference when the values are used once, since both versions read the table
-- four times. Each further use costs about 23 ns when it reads the table again, and about 8.5 ns
-- with the cached locals, so with 16 uses the cached version is 2.4x faster. The hashed part of a
-- table behaves the same way.


ModuleName = "Table Array"
ModuleLoopCount = 100000
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
