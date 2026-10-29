
-- Results with loop count 500000, inner loop count 45:
--
-- |-------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | Name                    | Params | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|
-- | "Base Line Loop"        |      1 |      27 |   1.854 |      0.018 |      0.99 |  0.046 | 2.50 |     1.835 |  1.801 |  1.949 | 0.76 |
-- | "Base Line Double Loop" |      2 |      30 |  91.879 |      0.861 |      0.94 |  2.307 | 2.51 |    91.997 | 88.955 | 96.104 | 0.23 |
-- |-------------------------|--------|---------|---------|------------|-----------|--------|------|-----------|--------|--------|------|

ModuleName = "Control"
ModuleSort = 1
ModuleLoopCount = 500000
BenchmarkData = {
    BaseLineLoop = {
        name = "Base Line Loop",
        desc = "Runs an empty loop",
        __loop_baseline = 1,
    },
    BaseLineLoop2 = {
        name = "Base Line Double Loop",
        desc = "Runs an empty loop nested in a loop",
        __loop_baseline = 2,
    },
}

function BaseLineLoop(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, loop do
        local a = 0 -- needed or else the forloop instruction jumps to itself and terminates early
    end

    local final = timer()
    return final - start
end

function BaseLineLoop2(outerLoop, innerLoop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local start = timer()

    for _ = 1, outerLoop do
        for _ = 1, innerLoop do
            local a = 0
        end
    end

    local final = timer()
    return final - start
end
