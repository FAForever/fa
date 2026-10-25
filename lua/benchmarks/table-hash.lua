
-- Results with loop count 100000:
--
-- |-------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | Name                    | Samples |  Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |   Min ms |   Max ms |  Skew |
-- |-------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | "Hash - 1"              |      29 |   2.6329 |     0.0315 |      1.20 | 0.0827 |  3.14 |    2.6245 |   2.4414 |   2.7466 | -0.41 |
-- | "Hash - 2"              |      31 |   4.8336 |     0.0430 |      0.89 | 0.1173 |  2.43 |    4.8828 |   4.5776 |   5.0659 | -0.51 |
-- | "Hash - 4"              |      30 |   9.8226 |     0.1207 |      1.23 | 0.3233 |  3.29 |    9.8572 |   9.0332 |  10.5591 | -0.10 |
-- | "Hash - 8"              |      30 |  18.7134 |     0.2173 |      1.16 | 0.5820 |  3.11 |   18.4631 |  17.9443 |  19.7144 |  0.51 |
-- | "Hash - 16"             |      28 |  37.9203 |     0.2277 |      0.60 | 0.5870 |  1.55 |   37.8418 |  36.8652 |  39.0625 |  0.18 |
-- | "Hash Cached - 1"       |      30 |   2.6123 |     0.0257 |      0.98 | 0.0688 |  2.63 |    2.6245 |   2.5024 |   2.7466 |  0.38 |
-- | "Hash Cached - 2"       |      29 |   3.3738 |     0.0303 |      0.90 | 0.0797 |  2.36 |    3.3569 |   3.2349 |   3.5400 |  0.34 |
-- | "Hash Cached - 4"       |      32 |   4.9362 |     0.0252 |      0.51 | 0.0706 |  1.43 |    4.9438 |   4.7607 |   5.0659 | -0.37 |
-- | "Hash Cached - 8"       |      32 |   8.5449 |     0.1282 |      1.50 | 0.3589 |  4.20 |    8.5449 |   7.6904 |   9.1553 | -0.16 |
-- | "Hash Cached - 16"      |      26 |  16.4725 |     0.1447 |      0.88 | 0.3581 |  2.17 |   16.4795 |  15.6860 |  16.9678 | -0.43 |
-- | "Hash Cross - 1"        |      24 |  33.6533 |     0.3446 |      1.02 | 0.8161 |  2.42 |   33.5693 |  32.4707 |  35.7666 |  1.14 |
-- | "Hash Cross - 2"        |      29 |  67.0334 |     0.5323 |      0.79 | 1.3996 |  2.09 |   66.6504 |  64.9414 |  69.8853 |  0.81 |
-- | "Hash Cross - 4"        |      30 | 131.5898 |     0.5309 |      0.40 | 1.4218 |  1.08 |  131.6223 | 129.3945 | 134.9487 |  0.34 |
-- | "Hash Cross Cached - 1" |      26 |  18.6087 |     0.3591 |      1.93 | 0.8889 |  4.78 |   18.4326 |  17.7002 |  20.9961 |  0.86 |
-- | "Hash Cross Cached - 2" |      26 |  20.1792 |     0.0604 |      0.30 | 0.1496 |  0.74 |   20.1416 |  19.8975 |  20.3857 | -0.07 |
-- | "Hash Cross Cached - 4" |      29 |  24.8687 |     0.2490 |      1.00 | 0.6549 |  2.63 |   24.6582 |  23.8037 |  26.2451 |  0.46 |
-- | "Hash Dot - 1"          |      30 |  17.1509 |     0.1876 |      1.09 | 0.5025 |  2.93 |   17.3340 |  16.2354 |  17.9443 | -0.37 |
-- | "Hash Dot - 2"          |      26 |  33.5130 |     0.0687 |      0.20 | 0.1700 |  0.51 |   33.4473 |  33.2031 |  33.9355 |  0.48 |
-- | "Hash Dot - 4"          |      25 |  65.3564 |     0.1243 |      0.19 | 0.3011 |  0.46 |   65.3076 |  64.8193 |  66.0400 |  0.39 |
-- | "Hash Dot Cached - 1"   |      29 |  16.5595 |     0.0378 |      0.23 | 0.0994 |  0.60 |   16.4795 |  16.4795 |  16.7236 |  0.66 |
-- | "Hash Dot Cached - 2"   |      28 |  17.6915 |     0.0717 |      0.41 | 0.1848 |  1.04 |   17.7002 |  17.3340 |  18.0664 |  0.05 |
-- | "Hash Dot Cached - 4"   |      27 |  19.7211 |     0.0978 |      0.50 | 0.2473 |  1.25 |   19.6533 |  19.4092 |  20.2637 |  0.46 |
-- |-------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|
-- | "Baseline, 1 parameter" |     666 |   0.3814 |     0.0034 |      0.89 | 0.0446 | 11.69 |    0.3662 |   0.2441 |   0.7935 |  4.14 |
-- |-------------------------|---------|----------|------------|-----------|--------|-------|-----------|----------|----------|-------|

-- Caching makes no difference when the values are used once, since both versions read the table
-- four times. Each further use costs about 24 ns when it reads the table again, and about 9 ns with
-- the cached locals, so with 16 uses the cached version is 2.3x faster. The array part of a table
-- behaves the same way.

-- Reading `x`, `y` or `z` from a vector costs about 27 ns, far more than a plain table field.
-- Caching them pays off quickly: with four cross products the cached version is 5.3x faster, and
-- with four dot products 3.3x. Indexing a vector with `[1]`, `[2]` and `[3]` is much cheaper (see
-- VDist3).

ModuleName = "Table Hash"
ModuleLoopCount = 100000
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
