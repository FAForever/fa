
-- Results with parameters 10000, 45:
--
-- |--------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | Name                     | Params | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Call Colon"             |      2 |      25 |  9.8535 |     0.0270 |      0.27 | 0.0655 |  0.66 |    9.8572 |  9.7351 |  9.9792 | -0.24 |
-- | "Call Global"            |      2 |      27 | 14.5953 |     0.0380 |      0.26 | 0.0960 |  0.66 |   14.6179 | 14.4348 | 14.8010 |  0.01 |
-- | "Call Local"             |      2 |      27 |  8.6726 |     0.0204 |      0.24 | 0.0515 |  0.59 |    8.6670 |  8.5754 |  8.7891 |  0.18 |
-- | "String concat"          |      1 |      30 |  4.3701 |     0.0518 |      1.18 | 0.1387 |  3.17 |    4.3182 |  4.2419 |  4.6997 |  1.16 |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"  |      1 |      32 |  0.0362 |     0.0043 |     11.93 | 0.0121 | 33.39 |    0.0305 |  0.0305 |  0.0610 |  1.53 |
-- | "Baseline, 2 parameters" |      2 |      82 |  1.8366 |     0.0112 |      0.61 | 0.0510 |  2.78 |    1.8311 |  1.7395 |  1.9531 |  0.25 |
-- |--------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|

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

function CallColon(innerLoop, outerLoop)
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