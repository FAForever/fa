
-- AllocateVectorGlobal:            1050 ms
-- AllocateVectorUpvalue:           960 ms
-- AllocateVectorLocal:             950 ms
-- AllocateVectorCached:            170 ms
-- AllocateVectorGetPosition:       700 ms
-- AllocateVectorGetPositionXYZ:    680 ms

ModuleName = "Memory"
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local vector = Vector(0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        vector[1], vector[2], vector[3] = unit:GetPositionXYZ()
    end

    local final = timer()
    unit:Destroy()
    return final - start
end