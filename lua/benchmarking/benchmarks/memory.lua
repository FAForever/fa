
-- AllocateVectorGlobal:            1050 ms
-- AllocateVectorUpvalue:           960 ms
-- AllocateVectorLocal:             950 ms
-- AllocateVectorCached:            170 ms
-- AllocateVectorGetPosition:       700 ms
-- AllocateVectorGetPositionXYZ:    680 ms

local loops = 2000

-- easily ramps up 160mb in small blocks
function AllocateVectorGlobal()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = false
    for y = 1, loops do 
        for x = 1, loops do
            vector = Vector(x, y, 1)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

local VectorUpvalue = Vector

-- easily ramps up 160mb in small blocks
function AllocateVectorUpvalue()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = false
    for y = 1, loops do 
        for x = 1, loops do
            vector = VectorUpvalue(x, y, 1)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- easily ramps up 160mb in small blocks
function AllocateVectorLocal()

    local Vector = Vector

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = false
    for y = 1, loops do 
        for x = 1, loops do
            vector = Vector(x, y, 1)
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- doesn't use anything
function AllocateVectorCached()

    local VectorCached = Vector(0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = VectorCached
    for y = 1, loops do 
        for x = 1, loops do
            vector[1] = x
            vector[2] = y 
            vector[3] = 1
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

-- doesn't use anything
function AllocateVectorGetPosition()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = false
    for y = 1, loops do 
        for x = 1, loops do
            vector = unit:GetPosition()
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end

-- doesn't use anything
function AllocateVectorGetPositionCached()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local vector = Vector(0, 0, 0)
    for y = 1, loops do 
        for x = 1, loops do
            vector[1], vector[2], vector[3] = unit:GetPositionXYZ()
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    unit:Destroy()

    return final - start
end