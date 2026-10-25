
-- Results with loop count 100000:
--
-- |--------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|
-- | Name                           | Samples |   Mean ms | +/- 95% ms | +/- 95% % |  Dev ms | CV % | Median ms |    Min ms |    Max ms |  Skew |
-- |--------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|
-- | "Add Constants (x2)"           |      65 |    0.8831 |     0.0078 |      0.89 |  0.0319 | 3.61 |    0.8850 |    0.8240 |    0.9766 |  0.77 |
-- | "Add Globals (x2)"             |      29 |    3.1675 |     0.0247 |      0.78 |  0.0649 | 2.05 |    3.1433 |    3.0518 |    3.3264 |  0.50 |
-- | "Add Locals (x2)"              |      56 |    0.8768 |     0.0059 |      0.68 |  0.0222 | 2.53 |    0.8850 |    0.8545 |    0.9155 |  0.44 |
-- | "Add Upvalues (x2)"            |      27 |    1.8876 |     0.0179 |      0.95 |  0.0453 | 2.40 |    1.8921 |    1.8005 |    1.9531 | -0.57 |
-- | "Circle Chebyshev (x2)"        |       6 | 1584.2285 |    18.4631 |      1.17 | 17.5905 | 1.11 | 1577.9877 | 1570.6787 | 1618.3777 |  1.09 |
-- | "Circle Global (x2)"           |       5 | 2920.2637 |    64.9416 |      2.22 | 52.3104 | 1.79 | 2899.4751 | 2872.8943 | 2996.4600 |  0.42 |
-- | "Circle Local (x2)"            |       5 | 2494.0063 |    13.8598 |      0.56 | 11.1641 | 0.45 | 2499.5422 | 2478.6682 | 2504.1199 | -0.35 |
-- | "Circle Local Precompute (x2)" |       5 | 2540.2161 |    12.1212 |      0.48 |  9.7637 | 0.38 | 2542.0532 | 2528.5950 | 2553.1311 |  0.05 |
-- | "Circle Optimal (x2)"          |       5 | 1988.3179 |     5.7676 |      0.29 |  4.6458 | 0.23 | 1985.5347 | 1984.0088 | 1994.0796 |  0.28 |
-- | "Circle Upvalued (x2)"         |       5 | 2606.7444 |    19.2576 |      0.74 | 15.5120 | 0.60 | 2603.5767 | 2589.7827 | 2628.1738 |  0.24 |
-- |--------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|
-- | "Baseline, 1 parameter (x2)"   |     190 |    0.7530 |     0.0032 |      0.42 |  0.0222 | 2.94 |    0.7629 |    0.7324 |    0.7935 |  0.58 |
-- |--------------------------------|---------|-----------|------------|-----------|---------|------|-----------|-----------|-----------|-------|

-- Conclusion:
-- - Locals are the fastest, then upvalues, then globals. Each "Add" iteration reads two values and
--   writes one. With upvalues it takes about 5 ns longer than with locals, and with globals about
--   11 ns longer. Locals cost about the same as constants.
-- - In the circle benchmarks, upvaluing the functions is 11% faster than using them as globals.
--   Making them locals and inlining `ComputePoint` is 15% faster. Precomputing the angle step is
--   13% faster, but it computes 31 points instead of 30, so per point it is 1.5% faster than the
--   local version. Replacing `table.insert` with a counter is 32% faster, and also replacing
--   `math.cos` and `math.sin` with a recurrence (Chebyshev) 46%, both with 31 points.
-- - Each circle iteration allocates 31 tables, so longer runs collect more garbage. Per iteration,
--   they are about 20% slower with 200000 loops than with 10000.
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
