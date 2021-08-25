
-- AddGlobal:               2.29 ms
-- AddUpval:                1.22 ms
-- AddLocal:                0.63 ms

-- CircleGlobal:            2391.11 ms
-- CircleUpval:             2020.50 ms
-- CircleLocal:             2042.96 ms
-- CircleLocalPreCompute:   1985.35 ms
-- CircleOptimal:           1288.08 ms

local outerLoop = 10000000

ProfilerA = 10
ProfilerB = 20
ProfilerC = 0

function AddGlobal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

local ProfilerA = ProfilerA
local ProfilerB = ProfilerB
local ProfilerC = ProfilerC

function AddUpval()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end


function AddLocal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, outerLoop do 
        local ProfilerA = ProfilerA 
        local ProfilerB = ProfilerB
        local ProfilerC = ProfilerC
        ProfilerC = ProfilerA + ProfilerB
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- in global scope
function ComputePoint(center, radius, radians)
    return {
        center[1] + radius * math.cos(radians),
        center[2] + 0,
        center[3] + radius * math.sin(radians),
    }
end

function CircleGlobal()

    -- parameters
    local center = { 100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30


    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local points = { }
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0
            local point = ComputePoint(center, radius, radians + radianOffset)
            point[2] = GetSurfaceHeight(point[1], point[3])
            table.insert(points, point)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local GetSurfaceHeight = GetSurfaceHeight
local TableInsert = table.insert
local MathCos = math.cos 
local MathSin = math.sin

local function ComputePoint(center, radius, radians)
    return {
        center[1] + radius * MathCos(radians),
        center[2] + 0,
        center[3] + radius * MathSin(radians),
    }
end

function CircleUpval()

    -- parameters
    local center = { 100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local points = { }
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0
            local point = ComputePoint(center, radius, radians + radianOffset)
            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function CircleLocal()

    -- parameters
    local center = { 100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local TableInsert = table.insert
    local MathCos = math.cos 
    local MathSin = math.sin
    
    local function ComputePoint(center, radius, radians)
        return {
            center[1] + radius * MathCos(radians),
            center[2] + 0,
            center[3] + radius * MathSin(radians),
        }
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local points = { }
        for k = 1, numberOfPieces do
            local radians = (k - 1) / (numberOfPieces - 1) * 3.14 * 2.0
            local point = ComputePoint(center, radius, radians + radianOffset)
            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CircleLocalPreCompute()

    -- parameters
    local center = { 100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local TableInsert = table.insert
    local MathCos = math.cos 
    local MathSin = math.sin

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- pre-compute
    local twoPi = 3.14 * 2.0
    local n = numberOfPieces - 1
    local inv = 1 / n 
    local combined = twoPi * inv 

    for k = 1, 100000 do 
        local points = { }
        for k = 0, numberOfPieces do
            local radians = radianOffset + combined * k
            local point = {
                center[1] + radius * MathCos(radians),
                0,
                center[3] + radius * MathSin(radians),
            }

            point[2] = GetSurfaceHeight(point[1], point[3])
            TableInsert(points, point)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function CircleOptimal()

    -- parameters
    local center = { 100, 0, 100}
    local radius = 15
    local radianOffset = 1
    local numberOfPieces = 30

    -- in local scope
    local GetSurfaceHeight = GetSurfaceHeight
    local MathCos = math.cos 
    local MathSin = math.sin

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    -- pre-compute
    local twoPi = 3.14 * 2.0
    local n = numberOfPieces - 1
    local inv = 1 / n 
    local combined = twoPi * inv 

    -- re-use table - we can do this because we keep a separate count
    -- local count = 0
    local points = { }

    for k = 1, 100000 do 

        -- insert elements manually
        local count = 0

        for k = 0, numberOfPieces do

            -- compute radians for this piece
            local radians = radianOffset + combined * k

            -- replace function call all together (0.1 seconds)
            local point = {
                center[1] + radius * MathCos(radians),
                0,
                center[3] + radius * MathSin(radians),
            }

            point[2] = GetSurfaceHeight(point[1], point[3])

            -- replace table.insert
            count = count + 1
            points[count] = point
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end