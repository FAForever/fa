
-- Results with loop count 200000:
--
-- |---------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                            | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |---------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Global math.abs"               |      29 |  5.4511 |     0.0311 |      0.57 | 0.0817 | 1.50 |    5.4932 |  5.3711 |  5.6152 |  0.48 |
-- | "Local math.abs"                |      30 |  3.3000 |     0.0189 |      0.57 | 0.0505 | 1.53 |    3.2959 |  3.1738 |  3.4180 |  0.24 |
-- | "Local math.abs per iteration"  |      32 |  5.8670 |     0.0246 |      0.42 | 0.0689 | 1.17 |    5.8594 |  5.7373 |  5.9814 |  0.02 |
-- | "Upvalued math.abs"             |      30 |  3.3936 |     0.0185 |      0.55 | 0.0497 | 1.46 |    3.4180 |  3.2959 |  3.4180 | -1.43 |
-- | "Global math.ceil"              |      29 | 28.1730 |     0.0827 |      0.29 | 0.2173 | 0.77 |   28.0762 | 27.8320 | 28.6865 |  0.63 |
-- | "Local math.ceil"               |      30 | 25.4191 |     0.0595 |      0.23 | 0.1593 | 0.63 |   25.3906 | 25.1465 | 25.7568 |  0.30 |
-- | "Local math.ceil per iteration" |      30 | 27.9134 |     0.0590 |      0.21 | 0.1581 | 0.57 |   27.9541 | 27.7100 | 28.1982 |  0.06 |
-- | "Upvalued math.ceil"            |      29 | 25.7063 |     0.0780 |      0.30 | 0.2051 | 0.80 |   25.6348 | 25.3906 | 26.1230 |  0.55 |
-- |---------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"         |     244 |  0.7559 |     0.0072 |      0.95 | 0.0575 | 7.61 |    0.7324 |  0.6104 |  1.0986 |  1.73 |
-- |---------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Conclusion: we should uplift these functions whenever possible. A global `math.abs` is 1.6x
-- slower than a local or upvalued one, and a global `math.ceil` 1.1x. Localizing the function in
-- each iteration is as slow as using the global, since it still looks it up every time.

---@diagnostic disable: discard-returns

ModuleName = "Generic math"
ModuleLoopCount = 200000
BenchmarkData = {
    AbsGlobal = "Global math.abs",
    AbsUpvalue = "Upvalued math.abs",
    AbsLocal = "Local math.abs",
    AbsLocalPerIteration = "Local math.abs per iteration",
    CeilGlobal = "Global math.ceil",
    CeilUpvalue = "Upvalued math.ceil",
    CeilLocal = "Local math.ceil",
    CeilLocalPerIteration = "Local math.ceil per iteration",
}

function AbsGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.abs(a)
    end

    local final = timer()
    return final - start
end

local MathAbs = math.abs

function AbsUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function AbsLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathAbs = math.abs
    for _ = 1, loop do
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function AbsLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathAbs = math.abs
        MathAbs(a)
    end

    local final = timer()
    return final - start
end

function CeilGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        math.ceil(a)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local MathCeil = math.ceil

function CeilUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        MathCeil(a)
    end

    local final = timer()
    return final - start
end

function CeilLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    local MathCeil = math.ceil
    for _ = 1, loop do
        MathCeil(a)
    end

    local final = timer()
    return final - start
end

function CeilLocalPerIteration(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a = 1
    local start = timer()

    for _ = 1, loop do
        local MathCeil = math.ceil
        MathCeil(a)
    end

    local final = timer()
    return final - start
end
