
-- Results with parameters 10000:
--
-- |---------------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | Name                            | Samples | Mean ms | +/- 95% ms | +/- 95% % |  Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |---------------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Global math.abs"               |      29 | 0.27150 |    0.00360 |      1.32 | 0.00946 |  3.48 |   0.27466 | 0.25940 | 0.28992 |  0.14 |
-- | "Local math.abs"                |      30 | 0.16937 |    0.00432 |      2.55 | 0.01158 |  6.84 |   0.16785 | 0.15259 | 0.19836 |  0.76 |
-- | "Local math.abs per iteration"  |      30 | 0.29348 |    0.00387 |      1.32 | 0.01036 |  3.53 |   0.28992 | 0.27466 | 0.30518 | -0.29 |
-- | "Upvalued math.abs"             |      23 | 0.16785 |    0.00000 |      0.00 | 0.00000 |  0.00 |   0.16785 | 0.16785 | 0.16785 |  0.00 |
-- | "Global math.ceil"              |      24 | 1.37647 |    0.00379 |      0.28 | 0.00898 |  0.65 |   1.37329 | 1.35803 | 1.38855 | -0.04 |
-- | "Local math.ceil"               |      27 | 1.26874 |    0.00400 |      0.32 | 0.01011 |  0.80 |   1.26648 | 1.25122 | 1.28174 | -0.15 |
-- | "Local math.ceil per iteration" |      29 | 1.38960 |    0.00408 |      0.29 | 0.01074 |  0.77 |   1.38855 | 1.37329 | 1.40381 | -0.09 |
-- | "Upvalued math.ceil"            |      24 | 1.26521 |    0.00376 |      0.30 | 0.00890 |  0.70 |   1.26648 | 1.25122 | 1.28174 | -0.01 |
-- |---------------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"         |     237 | 0.03786 |    0.00097 |      2.57 | 0.00764 | 20.18 |   0.03052 | 0.03052 | 0.04578 |  0.08 |
-- |---------------------------------|---------|---------|------------|-----------|---------|-------|-----------|---------|---------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Local math.abs", "Upvalued
-- math.abs".

-- Conclusion: we should uplift these functions whenever possible.

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
