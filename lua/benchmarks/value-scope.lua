
-- Results with parameters 10000:
--
-- |---------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | Name                      | Samples |  Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |   Min ms |   Max ms |  Skew |
-- |---------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | "Add Constants"           |     210 |   0.0437 |     0.0021 |      4.69 | 0.0152 | 34.65 |    0.0305 |   0.0305 |   0.0610 |  0.27 |
-- | "Add Globals"             |      30 |   0.1811 |     0.0042 |      2.30 | 0.0111 |  6.15 |    0.1831 |   0.1526 |   0.2136 | -0.83 |
-- | "Add Locals"              |     182 |   0.0448 |     0.0022 |      4.95 | 0.0153 | 34.10 |    0.0305 |   0.0305 |   0.0610 |  0.13 |
-- | "Add Upvalues"            |      30 |   0.0977 |     0.0046 |      4.75 | 0.0124 | 12.71 |    0.0916 |   0.0916 |   0.1221 |  1.43 |
-- | "Circle Chebyshev"        |      28 |  53.6597 |     0.2177 |      0.41 | 0.5613 |  1.05 |   53.6957 |  52.5513 |  54.9622 |  0.07 |
-- | "Circle Global"           |      27 | 120.6846 |     0.3210 |      0.27 | 0.8113 |  0.67 |  120.6665 | 119.2322 | 122.5281 |  0.32 |
-- | "Circle Local"            |      28 | 105.8786 |     0.3375 |      0.32 | 0.8702 |  0.82 |  105.8655 | 104.4006 | 107.9102 |  0.38 |
-- | "Circle Local Precompute" |      29 | 104.8205 |     0.3783 |      0.36 | 0.9946 |  0.95 |  104.9194 | 103.3020 | 106.9031 |  0.48 |
-- | "Circle Optimal"          |      27 |  76.8026 |     0.2464 |      0.32 | 0.6228 |  0.81 |   76.6296 |  75.9888 |  78.1250 |  0.67 |
-- | "Circle Upvalued"         |      29 | 110.7956 |     0.4362 |      0.39 | 1.1471 |  1.04 |  110.8093 | 108.8257 | 113.2202 |  0.20 |
-- |---------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | "Baseline, 1 parameter"   |     630 |   0.0382 |     0.0010 |      2.71 | 0.0133 | 34.71 |    0.0305 |   0.0305 |   0.0610 |  1.14 |
-- |---------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Add Constants", "Add Globals",
-- "Add Locals", "Add Upvalues".

-- Conclusion:
-- - Locals are the fastest, then upvalues, then globals. Each "Add" iteration reads two values and
--   writes one. With upvalues it takes about 5 ns longer than with locals, and with globals about
--   14 ns longer. Locals cost about the same as constants. These figures are rough, since the timer
--   was too coarse for the "Add" benchmarks.
-- - In the circle benchmarks, upvaluing the functions is 8% faster than using them as globals.
--   Making them locals and inlining `ComputePoint` is 12% faster, and also precomputing the angle
--   step 13%. Replacing `table.insert` with a counter is 36% faster, and also replacing `math.cos`
--   and `math.sin` with a recurrence (Chebyshev) 56%. The last three compute 31 points instead of
--   30, so they are slightly faster than shown.
-- - This agrees with function-scope, where the cost of the call hides most of the difference
--   between locals and upvalues.

ModuleName = "Value Scope"
ModuleLoopCount = 100000
BenchmarkData = {
    AddGlobal = "Add Globals",
    AddUpval = "Add Upvalues",
    AddLocal = "Add Locals",
    AddConst = "Add Constants",
    CircleGlobal = "Circle Global",
    CircleUpval = "Circle Upvalued",
    CircleLocal = "Circle Local",
    CircleLocalPreCompute = "Circle Local Precompute",
    CircleOptimal = "Circle Optimal",
    CircleChebyshev = "Circle Chebyshev",
}
Exclude = {
    ComputePoint = true,
}

ProfilerA = 10
ProfilerB = 20
ProfilerC = 0
function AddGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    ProfilerA = 10
    ProfilerB = 20
    ProfilerC = 0

    local start = timer()

    for _ = 1, loop do
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = timer()
    return final - start

end

local ProfilerA = 10
local ProfilerB = 20
local ProfilerC = 0

function AddUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    ProfilerA = 10
    ProfilerB = 20
    ProfilerC = 0

    local start = timer()

    for _ = 1, loop do
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = timer()
    return final - start
end

function AddLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local ProfilerA = 10
    local ProfilerB = 20
    local ProfilerC = 0

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = timer()
    return final - start
end


function AddConst(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local ProfilerC = 0

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for _ = 1, loop do
        ProfilerC = 10 + 20
    end

    local final = timer()
    return final - start
end

-- in global scope
function ComputePoint(center, radius, radians)
    return {
        center[1] + radius * math.cos(radians),
        center[2],
        center[3] + radius * math.sin(radians),
    }
end

function CircleGlobal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    for _ = 1, loop do
        local points = {}
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0
            local point = ComputePoint(center, radius, radians + radianOffset)
            point[2] = GetSurfaceHeight(point[1], point[3])
            table.insert(points, point)
        end
    end

    local final = timer()
    return final - start
end

local GetSurfaceHeight = GetSurfaceHeight
local TableInsert = table.insert
local MathCos = math.cos 
local MathSin = math.sin

local function ComputePoint(center, radius, radians)
    return {
        center[1] + radius * MathCos(radians),
        center[2],
        center[3] + radius * MathSin(radians),
    }
end

function CircleUpval(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    for _ = 1, loop do
        local points = {}
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0
            local point = ComputePoint(center, radius, radians + radianOffset)
            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = timer()
    return final - start

end

function CircleLocal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local TableInsert = table.insert
    local MathCos = math.cos
    local MathSin = math.sin

    for _ = 1, loop do
        local points = {}
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0 + radianOffset
            local point = {
                center[1] + radius * MathCos(radians),
                center[2],
                center[3] + radius * MathSin(radians),
            }
            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = timer()
    return final - start
end

function CircleLocalPreCompute(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local TableInsert = table.insert
    local MathCos = math.cos
    local MathSin = math.sin
    -- pre-compute
    local precomputed = 6.28 / (numberOfPieces - 1)

    for _ = 1, loop do
        local points = {}
        for k = 0, numberOfPieces do
            local radians = radianOffset + precomputed * k
            local point = {
                center[1] + radius * MathCos(radians),
                center[2],
                center[3] + radius * MathSin(radians),
            }
            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = timer()
    return final - start
end

function CircleOptimal(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    -- pre-compute
    local combined = 6.28 / (numberOfPieces - 1)
    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local MathCos = math.cos
    local MathSin = math.sin

    for _ = 1, loop do
        -- insert elements manually
        local points = {}
        local count = 0

        for k = 0, numberOfPieces do
            -- compute radians for this piece
            local radians = radianOffset + combined * k

            -- replace function call all together (0.1 seconds)
            local point = {
                center[1] + radius * MathCos(radians),
                center[2],
                center[3] + radius * MathSin(radians),
            }

            point[2] = GetSurfaceHeight(point[1], point[3])

            -- replace table.insert
            count = count + 1
            points[count] = point
        end
    end

    local final = timer()
    return final - start
end


function CircleChebyshev(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    -- parameters
    local center = {100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = timer()

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local MathCos = math.cos
    local MathSqrt = math.sqrt
    -- pre-compute
    local combined = 6.28 / (numberOfPieces - 1)

    for _ = 1, loop do
        -- insert elements manually
        local points = {}
        local count = 0

        local cosAng = MathCos(combined)
        local sinAng = MathSqrt(1 - cosAng*cosAng)
        local cosInit = radius * MathCos(radianOffset)
        local sinInit = radius * MathSqrt(1 - cosInit*cosInit)
        local doubCosAng = 2 * cosAng

        local cos2Ang = cosAng*cosAng - sinAng*sinAng
        local sin2Ang = doubCosAng * sinAng

        local cosNm2 = cosInit * cos2Ang + sinInit * sin2Ang
        local sinNm2 = sinInit * cos2Ang - cosInit * sin2Ang
        local cosNm1 = cosInit * cosAng + sinInit * sinAng
        local sinNm1 = sinInit * cosAng - cosInit * sinAng

        -- replace trig functions
        for k = 0, numberOfPieces do
            -- cos(init + n ang) = 2 cos(ang) cos(init + (n-1) ang) - cos(init + (n-2) ang)
            -- sin(init + n ang) = 2 cos(ang) sin(init + (n-1) ang) - sin(init + (n-2) ang)
            local cosN = doubCosAng * cosNm1 - cosNm2
            local sinN = doubCosAng * sinNm1 - sinNm2
            cosNm2, cosNm1 = cosNm1, cosN
            sinNm2, sinNm1 = sinNm1, sinN

            -- replace function call all together (0.1 seconds)
            local point = {
                center[1] + cosN,
                center[2],
                center[3] + sinN,
            }

            point[2] = GetSurfaceHeight(point[1], point[3])

            -- replace table.insert
            count = count + 1
            points[count] = point
        end
    end

    local final = timer()
    return final - start
end
