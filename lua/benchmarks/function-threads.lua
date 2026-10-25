
-- Results with loop count 10000:
--
-- |-------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | Name                          | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms | CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Function Call (x50)"         |      30 |  13.367 |      0.064 |      0.48 |  0.172 | 1.29 |    13.428 |  13.062 |  13.672 | -0.11 |
-- | "No Call (x50)"               |      30 |   2.148 |      0.023 |      1.06 |  0.061 | 2.83 |     2.197 |   2.075 |   2.197 | -0.39 |
-- | "Thread Call (x50)"           |      30 | 313.220 |      3.932 |      1.26 | 10.530 | 3.36 |   318.237 | 292.480 | 326.172 | -0.45 |
-- |-------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter (x50)" |      87 |   1.870 |      0.015 |      0.78 |  0.068 | 3.66 |     1.831 |   1.709 |   1.953 | -0.06 |
-- |-------------------------------|---------|---------|------------|-----------|--------|------|-----------|---------|---------|-------|

-- Launching a thread costs about 620 ns, 28x as much as calling a function (about 22 ns).

-- A disclaimer to these results is that the fork thread doesn't actually do the work, the call only 
-- allocates a new thread and that starts doing the work after the current thread is finished. Therefore 
-- the real work is not part of the benchmark. All that we are seeing here are the costs to launch 
-- a new thread.

-- A conclusion that we can draw here is that conditions that may terminate the thread before it starts
-- doing work should be done before we initialize the thread, instead of at the start of it. This is 
-- commonly done in unit.lua and we can optimize that for sure.

ModuleName = "Function Threads"
BenchmarkData = {
    FunctionCall = "Function Call",
    ThreadCall = "Thread Call",
    NoCall = "No Call",
}

function FunctionCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = timer()

    for _ = 1, loop do
        AddToSum()
    end

    local final = timer()
    return final - start
end

function ThreadCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = timer()

    for _ = 1, loop do
        ForkThread(AddToSum)
    end

    local final = timer()
    return final - start
end

function NoCall(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local sum = 0

    local start = timer()

    for _ = 1, loop do
        sum = sum + 1
    end

    local final = timer()
    return final - start
end