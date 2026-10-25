
-- Results with parameters 10000:
--
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | Name                    | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Hash - 1"              |      29 |  0.2631 |     0.0065 |      2.48 | 0.0171 |  6.51 |    0.2747 |  0.2441 |  0.3052 |  0.12 |
-- | "Hash - 2"              |      31 |  0.5021 |     0.0115 |      2.29 | 0.0314 |  6.25 |    0.4883 |  0.4578 |  0.5493 |  0.30 |
-- | "Hash - 4"              |      30 |  1.0447 |     0.0215 |      2.06 | 0.0576 |  5.51 |    1.0376 |  0.9460 |  1.1597 |  0.30 |
-- | "Hash - 8"              |      31 |  1.9669 |     0.0257 |      1.30 | 0.0700 |  3.56 |    1.9836 |  1.8311 |  2.1057 | -0.11 |
-- | "Hash - 16"             |      30 |  3.7506 |     0.0431 |      1.15 | 0.1154 |  3.08 |    3.7231 |  3.5400 |  3.9978 |  0.45 |
-- | "Hash Cached - 1"       |      31 |  0.2678 |     0.0056 |      2.08 | 0.0152 |  5.67 |    0.2747 |  0.2441 |  0.3052 | -0.42 |
-- | "Hash Cached - 2"       |      28 |  0.3477 |     0.0067 |      1.93 | 0.0173 |  4.98 |    0.3357 |  0.3052 |  0.3662 | -0.18 |
-- | "Hash Cached - 4"       |      31 |  0.5208 |     0.0155 |      2.99 | 0.0424 |  8.14 |    0.5188 |  0.4578 |  0.6104 |  0.54 |
-- | "Hash Cached - 8"       |      28 |  0.8458 |     0.0147 |      1.74 | 0.0379 |  4.48 |    0.8240 |  0.7935 |  0.9155 |  0.31 |
-- | "Hash Cached - 16"      |      27 |  1.5779 |     0.0252 |      1.60 | 0.0638 |  4.04 |    1.5564 |  1.4954 |  1.7090 |  0.65 |
-- | "Hash Cross - 1"        |      27 |  3.4960 |     0.0584 |      1.67 | 0.1477 |  4.22 |    3.4485 |  3.3264 |  3.8452 |  1.28 |
-- | "Hash Cross - 2"        |      28 |  7.0539 |     0.0519 |      0.74 | 0.1339 |  1.90 |    7.0190 |  6.8359 |  7.3242 |  0.30 |
-- | "Hash Cross - 4"        |      27 | 13.9205 |     0.1469 |      1.06 | 0.3712 |  2.67 |   13.9771 | 13.1836 | 14.4958 | -0.26 |
-- | "Hash Cross Cached - 1" |      27 |  1.7938 |     0.0277 |      1.54 | 0.0700 |  3.90 |    1.7700 |  1.7395 |  1.9531 |  1.17 |
-- | "Hash Cross Cached - 2" |      28 |  2.0185 |     0.0163 |      0.81 | 0.0421 |  2.09 |    2.0142 |  1.9531 |  2.1057 |  0.57 |
-- | "Hash Cross Cached - 4" |      29 |  2.5214 |     0.0593 |      2.35 | 0.1559 |  6.18 |    2.4414 |  2.3804 |  2.8381 |  1.00 |
-- | "Hash Dot - 1"          |      30 |  1.9155 |     0.0827 |      4.32 | 0.2216 | 11.57 |    1.8921 |  1.6174 |  2.3804 |  0.62 |
-- | "Hash Dot - 2"          |      25 |  3.3875 |     0.0423 |      1.25 | 0.1024 |  3.02 |    3.3569 |  3.2654 |  3.6316 |  0.95 |
-- | "Hash Dot - 4"          |      27 |  6.7240 |     0.0478 |      0.71 | 0.1209 |  1.80 |    6.7139 |  6.5613 |  6.9885 |  0.70 |
-- | "Hash Dot Cached - 1"   |      55 |  1.7417 |     0.0400 |      2.30 | 0.1483 |  8.52 |    1.6785 |  1.6174 |  2.2278 |  1.60 |
-- | "Hash Dot Cached - 2"   |      28 |  1.7657 |     0.0160 |      0.91 | 0.0413 |  2.34 |    1.7395 |  1.7090 |  1.8616 |  1.03 |
-- | "Hash Dot Cached - 4"   |      26 |  1.9555 |     0.0110 |      0.56 | 0.0272 |  1.39 |    1.9531 |  1.9226 |  2.0142 |  0.19 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter" |     711 |  0.0397 |     0.0010 |      2.59 | 0.0140 | 35.29 |    0.0305 |  0.0305 |  0.0610 |  0.86 |
-- |-------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
--
-- These are too short for the timer, so they mostly show its step: "Hash - 1", "Hash - 2", "Hash
-- Cached - 1", "Hash Cached - 2".

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
