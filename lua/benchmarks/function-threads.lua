
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms | Min ms | Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Function Call"         |      30 |  0.2650 |     0.0063 |      2.36 | 0.0168 |  6.32 |    0.2594 | 0.2441 | 0.3204 |  2.44 |
-- | "No Call"               |     122 |  0.0463 |     0.0020 |      4.25 | 0.0111 | 23.96 |    0.0458 | 0.0305 | 0.1068 |  2.90 |
-- | "Thread Call"           |      32 |  4.1876 |     0.2084 |      4.98 | 0.5833 | 13.93 |    4.2953 | 3.0365 | 5.2032 | -0.33 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
-- | "Baseline, 1 parameter" |     176 |  0.0374 |     0.0011 |      3.01 | 0.0076 | 20.37 |    0.0305 | 0.0305 | 0.0458 |  0.20 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|--------|--------|-------|
--
-- These are too short for the timer, so they mostly show its step: "No Call".

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