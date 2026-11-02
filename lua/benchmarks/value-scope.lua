
-- AddGlobal:               2.29 ms
-- AddUpval:                1.22 ms
-- AddLocal:                0.63 ms

-- CircleGlobal:            2391.11 ms
-- CircleUpval:             2020.50 ms
-- CircleLocal:             2042.96 ms
-- CircleLocalPreCompute:   1985.35 ms
-- CircleOptimal:           1288.08 ms

ModuleName = "Value Scope"
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
