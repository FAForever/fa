
-- Results with loop count 100000:
--
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | Name                           | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Cached Vector"                |      30 |  2.1464 |     0.0232 |      1.08 | 0.0623 |  2.90 |    2.1362 |  2.0142 |  2.2583 | -0.51 |
-- | "GetPosition Vector"           |      28 | 12.5558 |     0.0352 |      0.28 | 0.0908 |  0.72 |   12.5732 | 12.3901 | 12.7563 |  0.22 |
-- | "GetPositionXYZ Cached Vector" |      30 | 12.5448 |     0.0521 |      0.42 | 0.1395 |  1.11 |   12.5732 | 12.3291 | 12.8784 |  0.39 |
-- | "Global Vector"                |      27 | 15.2882 |     0.1868 |      1.22 | 0.4720 |  3.09 |   15.1367 | 14.8315 | 16.4185 |  1.48 |
-- | "Local Vector"                 |      28 | 14.7313 |     0.1607 |      1.09 | 0.4144 |  2.81 |   14.5569 | 14.1602 | 15.5640 |  0.58 |
-- | "Upvalued Vector"              |      28 | 14.4523 |     0.0813 |      0.56 | 0.2097 |  1.45 |   14.4043 | 14.1602 | 14.8315 |  0.47 |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"        |     180 |  0.3788 |     0.0062 |      1.63 | 0.0422 | 11.13 |    0.3662 |  0.3052 |  0.7935 |  5.98 |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|

-- Conclusion: allocating a vector costs about 140 to 150 ns, however `Vector` is looked up. Reusing
-- a cached vector is 7x faster. `GetPosition` and `GetPositionXYZ` into a vector cost about the
-- same as allocating one (about 122 ns).

ModuleName = "Memory"
ModuleLoopCount = 100000
BenchmarkData = {
    AllocateVectorGlobal = "Global Vector",
    AllocateVectorUpvalue = "Upvalued Vector",
    AllocateVectorLocal = "Local Vector",
    AllocateVectorCached = "Cached Vector",
    AllocateVectorGetPosition = "GetPosition Vector",
    AllocateVectorGetPositionCached = "GetPositionXYZ Cached Vector",
}

-- easily ramps up 160mb in small blocks
function AllocateVectorGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a, b, c = 1, 1, 1
    local start = timer()

    for _ = 1, loop do
        Vector(a, b, c)
    end

    local final = timer()
    return final - start
end

local VectorUpvalue = Vector

-- easily ramps up 160mb in small blocks
function AllocateVectorUpvalue(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a, b, c = 1, 1, 1
    local start = timer()

    for _ = 1, loop do
        VectorUpvalue(a, b, c)
    end

    local final = timer()
    return final - start
end

-- easily ramps up 160mb in small blocks
function AllocateVectorLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local a, b, c = 1, 1, 1
    local start = timer()

    local Vector = Vector
    for _ = 1, loop do
        Vector(a, b, c)
    end

    local final = timer()
    return final - start
end

-- doesn't use anything
function AllocateVectorCached(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    local vector = Vector(0, 0, 0)
    local a, b, c = 1, 1, 1
    local start = timer()

    for _ = 1, loop do
        vector[1] = a
        vector[2] = b
        vector[3] = c
    end

    local final = timer()
    return final - start
end

-- doesn't use anything
function AllocateVectorGetPosition(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
    local vector
    local start = timer()

    for _ = 1, loop do
        vector = unit:GetPosition()
    end

    local final = timer()
    unit:Destroy()
    return final - start
end

-- doesn't use anything
function AllocateVectorGetPositionCached(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
    local vector = Vector(0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        vector[1], vector[2], vector[3] = unit:GetPositionXYZ()
    end

    local final = timer()
    unit:Destroy()
    return final - start
end