
-- Results with parameters 10000, 45:
--
-- |-------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | Name                    | Params | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms | Skew |
-- |-------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
-- | "Base Line Loop"        |      1 |      30 |  0.0387 |     0.0018 |      4.71 | 0.0049 | 12.63 |    0.0381 | 0.0305 | 0.0610 | 3.01 |
-- | "Base Line Double Loop" |      2 |      29 |  1.8153 |     0.0160 |      0.88 | 0.0422 |  2.32 |    1.8082 | 1.7471 | 1.9073 | 0.29 |
-- |-------------------------|--------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|------|
--
-- These are too short for the timer, so they mostly show its step: "BaseLineLoop".

ModuleName = "Control"
ModuleSort = 1
BenchmarkData = {
    BaseLineLoop = {
        name = "Base Line Loop",
        desc = "Runs an empty loop for",
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
