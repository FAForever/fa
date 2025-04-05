
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

ModuleName = "Table Hash"
BenchmarkData = {
    Hash01 = "Hash - 1",
    Hash02 = "Hash - 2",
    Hash04 = "Hash - 4",
    Hash08 = "Hash - 8",
    Hash16 = "Hash - 16",
    HashCached01 = "Hash Cached - 1",
    HashCached02 = "Hash Cached - 2",
    HashCached04 = "Hash Cached - 4",
    HashCached08 = "Hash Cached - 8",
    HashCached16 = "Hash Cached - 16",
    HashCross1 = "Hash Cross - 1",
    HashCross2 = "Hash Cross - 2",
    HashCross4 = "Hash Cross - 4",
    HashCrossCached1 = "Hash Cross Cached - 1",
    HashCrossCached2 = "Hash Cross Cached - 2",
    HashCrossCached4 = "Hash Cross Cached - 4",
    HashDot1 = "Hash Dot - 1",
    HashDot2 = "Hash Dot - 2",
    HashDot4 = "Hash Dot - 4",
    HashDotCached1 = "Hash Dot Cached - 1",
    HashDotCached2 = "Hash Dot Cached - 2",
    HashDotCached4 = "Hash Dot Cached - 4",
}

function Hash01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element.x + element.y + element.z + element.w
    end

    local final = timer()
    return final - start
end
function Hash02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
    end

    local final = timer()
    return final - start
end
function Hash04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
    end

    local final = timer()
    return final - start
end
function Hash08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w

        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
    end

    local final = timer()
    return final - start
end
function Hash16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w

        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w

        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w

        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
        a = 0 + element.x + element.y + element.z + element.w
    end

    local final = timer()
    return final - start
end

function HashCached01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        local x = element.x
        local y = element.y
        local z = element.z
        local w = element.w

        a = 0 + x + y + z + w
    end

    local final = timer()
    return final - start
end
function HashCached02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        local x = element.x
        local y = element.y
        local z = element.z
        local w = element.w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
    end

    local final = timer()
    return final - start
end
function HashCached04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        local x = element.x
        local y = element.y
        local z = element.z
        local w = element.w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
    end

    local final = timer()
    return final - start
end
function HashCached08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        local x = element.x
        local y = element.y
        local z = element.z
        local w = element.w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
    end

    local final = timer()
    return final - start
end
function HashCached16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local element = { x = 1, y = 2, z = 3, w = 4 }

    local a
    local start = timer()

    for _ = 1, loop do
        local x = element.x
        local y = element.y
        local z = element.z
        local w = element.w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w

        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
        a = 0 + x + y + z + w
    end

    local final = timer()
    return final - start
end

-- The following benchmarks represent the following function from /lua/utilities.lua:

-- function Cross(v1, v2)
--     return Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
-- end

function HashCross1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
    end

    local final = timer()
    return final - start
end
function HashCross2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
    end

    local final = timer()
    return final - start
end
function HashCross4(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
        a, b, c = v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y - v2.x
    end

    local final = timer()
    return final - start
end

function HashCrossCached1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
    end

    local final = timer()
    return final - start
end
function HashCrossCached2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
    end

    local final = timer()
    return final - start
end
function HashCrossCached4(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a, b, c
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
        a, b, c = v1y * v2z - v1z * v2y, v1z * v2x - v1x * v2z, v1x * v2y - v1y - v2x
    end

    local final = timer()
    return final - start
end

-- The following benchmarks represent the following function from /lua/utilities.lua:

-- function DotP(v1, v2)
--     return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
-- end

function HashDot1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    end

    local final = timer()
    return final - start
end
function HashDot2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    end

    local final = timer()
    return final - start
end
function HashDot4(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
        a = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    end

    local final = timer()
    return final - start
end

function HashDotCached1(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a = v1x * v2x + v1y * v2y + v1z * v2z
    end

    local final = timer()
    return final - start
end
function HashDotCached2(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a = v1x * v2x + v1y * v2y + v1z * v2z
        a = v1x * v2x + v1y * v2y + v1z * v2z
    end

    local final = timer()
    return final - start
end
function HashDotCached4(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse

    local v1 = Vector(1, 1, 1)
    local v2 = Vector(2, 1, 1)

    local a
    local start = timer()

    for _ = 1, loop do
        local v1x = v1.x
        local v1y = v1.y
        local v1z = v1.z

        local v2x = v2.x
        local v2y = v2.y
        local v2z = v2.z

        a = v1x * v2x + v1y * v2y + v1z * v2z
        a = v1x * v2x + v1y * v2y + v1z * v2z
        a = v1x * v2x + v1y * v2y + v1z * v2z
        a = v1x * v2x + v1y * v2y + v1z * v2z
    end

    local final = timer()
    return final - start
end
