
-- summary of findings

-- Hash01:              0.00488
-- Hash02:              0.00830
-- Hash04:              0.01416
-- Hash08:              0.03173
-- Hash16:              0.05249
-- HashCached01:        0.00341
-- HashCached02:        0.00634
-- HashCached04:        0.00830
-- HashCached08:        0.01269
-- HashCached16:        0.02246

-- HashCross1:          0.08498
-- HashCross2:          0.16759
-- HashCross4:          0.33935

-- HashCrossCached1:    0.05175
-- HashCrossCached2:    0.08886
-- HashCrossCached4:    0.13671

-- HashDot1:            0.03125
-- HashDot2:            0.05957
-- HashDot4:            0.11914

-- HashDotCached1:      0.02539
-- HashDotCached2:      0.02743
-- HashDotCached4:      0.03125

-- The speed up of just caching is astounding - even in the situation where we cache   
-- it for a single use. When we look at the byte code we see the following pattern:
-- Hash:        GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD
-- HashCached:  GETTABLE, GETTABLE, GETTABLE, GETTABLE, ADD, ADD, ADD, ADD

-- I can not confirm it, but I suspect the get table is optimized to quickly get several 
-- elements in succession. You see patterns such as 'table.subtable.x' quite common in code and
-- that may have been optmized. This may be just the cacheline of the CPU, but we see a similar 
-- behavior with the array part of a table.

function Hash01()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element.x -- GETABLE, ADD
        sum = sum + element.y -- GETABLE, ADD
        sum = sum + element.z -- GETABLE, ADD
        sum = sum + element.w -- GETABLE, ADD
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function Hash02()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function Hash04()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function Hash08()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function Hash16()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w

        sum = sum + element.x
        sum = sum + element.y
        sum = sum + element.z
        sum = sum + element.w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCached01()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local x = element.x 
        local y = element.y 
        local z = element.z
        local w = element.w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCached02()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local x = element.x -- GETTABLE
        local y = element.y -- GETTABLE
        local z = element.z -- GETTABLE
        local w = element.w -- GETTABLE

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCached04()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local x = element.x 
        local y = element.y 
        local z = element.z
        local w = element.w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCached08()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local x = element.x 
        local y = element.y 
        local z = element.z
        local w = element.w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCached16()

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local x = element.x 
        local y = element.y 
        local z = element.z
        local w = element.w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w

        sum = sum + x
        sum = sum + y
        sum = sum + z
        sum = sum + w
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- The following benchmarks represent the following function from /lua/utilities.lua:

-- function Cross(v1, v2)
--     return Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
-- end

function HashCross1()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local cross = 0
    for k = 1, 100000 do 
        -- do the cross product
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCross2()

    -- initialize two vectors
    local v1 = Vector(1, 0, 1)
    local v2 = Vector(0, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local cross = 0
    for k = 1, 100000 do 
        -- do the cross product
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCross4()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local cross = 0
    for k = 1, 100000 do 
        -- do the cross product
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
        cross = Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCrossCached1()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()
    
    local cross = 0
    for k = 1, 100000 do 

        -- cache it
        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the cross product
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCrossCached2()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()
    
    local cross = 0
    for k = 1, 100000 do 

        -- cache it
        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the cross product
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashCrossCached4()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()
    
    local cross = 0
    for k = 1, 100000 do 

        -- cache it
        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the cross product
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
        cross = Vector((v1y * v2z) - (v1z * v2y), (v1z * v2x) - (v1x * v2z), (v1x * v2y) - (v1y - v2x))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- The following benchmarks represent the following function from /lua/utilities.lua:

-- function DotP(v1, v2)
--     return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
-- end

function HashDot1()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 
        -- do the dot product
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashDot2()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 
        -- do the dot product
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashDot4()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 
        -- do the dot product
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
        dot = ((v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashDotCached1()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 

        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the dot product
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashDotCached2()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 

        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the dot product
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function HashDotCached4()

    -- initialize two vectors
    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local dot = 0
    for k = 1, 100000 do 

        local v1x = v1.x 
        local v1y = v1.y
        local v1z = v1.z 

        local v2x = v2.x 
        local v2y = v2.y 
        local v2z = v2.z 

        -- do the dot product
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
        dot = ((v1x * v2x) + (v1y * v2y) + (v1z * v2z))
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end