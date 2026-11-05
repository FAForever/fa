
-- Results with loop count 10000, inner loop count 45:
--
-- |--------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | Name                     | Params | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms | Skew |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Call Colon"             |      2 |      26 |   9.960 |      0.027 |      0.27 |  0.066 | 0.66 |     9.941 |  9.865 | 10.117 | 0.72 |
-- | "Call Global"            |      2 |      29 |  14.302 |      0.039 |      0.27 |  0.101 | 0.71 |    14.297 | 14.130 | 14.503 | 0.30 |
-- | "Call Local"             |      2 |      29 |   8.568 |      0.025 |      0.29 |  0.065 | 0.76 |     8.575 |  8.461 |  8.682 | 0.01 |
-- | "String concat"          |      1 |      27 |   4.272 |      0.016 |      0.38 |  0.041 | 0.96 |     4.265 |  4.211 |  4.372 | 0.72 |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Baseline, 1 parameter"  |      1 |      18 |   0.038 |      0.000 |      0.00 |  0.000 | 0.00 |     0.038 |  0.038 |  0.038 | 0.00 |
-- | "Baseline, 2 parameters" |      2 |      88 |   1.878 |      0.015 |      0.80 |  0.071 | 3.79 |     1.865 |  1.747 |  2.029 | 0.31 |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|

-- Conclusion: `str:len()` is 1.16x slower than calling a local `string.len`, and `string.len(str)`
-- is 1.67x slower, since it looks up `string` every call. Concatenating a number to a string costs
-- about 430 ns.

ModuleName = "Strings"
BenchmarkData = {
    EachIterationString = "String concat",
    CallColon = "Call Colon",
    CallGlobal = "Call Global",
    CallLocal = "Call Local",
}

function EachIterationString(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local test
    local string = "to-test-this-long-string"
    local start = timer()

    for k = 1, loop do
        test = string .. k
    end

    local final = timer()
    return final - start
end

function CallColon(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            str:len()
        end
    end

    local final = timer()
    return final - start
end

function CallGlobal(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            string.len(str)
        end
    end

    local final = timer()
    return final - start
end

function CallLocal(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local str = "str"
    local start = timer()

    for _ = 1, outerLoop do
        local StringLen = string.len
        for _ = 1, innerLoop do
            StringLen(str)
        end
    end

    local final = timer()
    return final - start
end