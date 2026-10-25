
-- Results with parameters 10000:
--
-- |--------------------------------|---------|----------|------------|-----------|---------|-------|-----------|----------|----------|-------|
-- | Name                           | Samples |  Mean ms | +/- 95% ms | +/- 95% % |  Dev ms |  CV % | Median ms |   Min ms |   Max ms |  Skew |
-- |--------------------------------|---------|----------|------------|-----------|---------|-------|-----------|----------|----------|-------|
-- | "GetPosition local - 1"        |      30 |  1.28733 |    0.00648 |      0.50 | 0.01734 |  1.35 |   1.28174 |  1.25885 |  1.31989 |  0.25 |
-- | "GetPosition local - 2"        |      30 |  2.47294 |    0.01139 |      0.46 | 0.03050 |  1.23 |   2.47192 |  2.42615 |  2.51770 |  0.04 |
-- | "GetPosition local - 4"        |      30 |  4.82686 |    0.01382 |      0.29 | 0.03702 |  0.77 |   4.82178 |  4.76074 |  4.91333 |  0.62 |
-- | "GetPosition local - 8"        |      28 |  9.42775 |    0.03097 |      0.33 | 0.07985 |  0.85 |   9.42993 |  9.27734 |  9.55200 | -0.37 |
-- | "GetPosition local - 16"       |      24 | 18.41545 |    0.03657 |      0.20 | 0.08659 |  0.47 |  18.40210 | 18.26477 | 18.56995 |  0.16 |
-- | "GetPosition method - 1"       |      29 |  1.21860 |    0.00553 |      0.45 | 0.01455 |  1.19 |   1.22070 |  1.19019 |  1.23596 | -0.21 |
-- | "GetPosition method - 2"       |      27 |  2.51318 |    0.00945 |      0.38 | 0.02387 |  0.95 |   2.51770 |  2.47192 |  2.56348 | -0.10 |
-- | "GetPosition method - 4"       |      28 |  4.95856 |    0.01362 |      0.27 | 0.03511 |  0.71 |   4.94385 |  4.91333 |  5.05066 |  0.87 |
-- | "GetPosition method - 8"       |      28 |  9.96181 |    0.04997 |      0.50 | 0.12886 |  1.29 |   9.95636 |  9.75037 | 10.26917 |  0.53 |
-- | "GetPosition method - 16"      |      28 | 19.66531 |    0.09620 |      0.49 | 0.24808 |  1.26 |  19.58466 | 19.34814 | 20.24841 |  1.02 |
-- | "GetPosition manual self - 1"  |      24 |  1.20417 |    0.00376 |      0.31 | 0.00890 |  0.74 |   1.20544 |  1.19019 |  1.22070 | -0.01 |
-- | "GetPosition manual self - 2"  |      30 |  2.48108 |    0.00893 |      0.36 | 0.02391 |  0.96 |   2.48718 |  2.44141 |  2.53296 |  0.08 |
-- | "GetPosition manual self - 4"  |      30 |  4.91079 |    0.01619 |      0.33 | 0.04336 |  0.88 |   4.91333 |  4.82178 |  5.00488 |  0.03 |
-- | "GetPosition manual self - 8"  |      28 |  9.71113 |    0.01692 |      0.17 | 0.04364 |  0.45 |   9.69696 |  9.64355 |  9.81140 |  0.63 |
-- | "GetPosition manual self - 16" |      29 | 19.52178 |    0.11211 |      0.57 | 0.29479 |  1.51 |  19.50073 | 19.16504 | 20.20264 |  0.72 |
-- | "GetPosition upvalue - 1"      |      27 |  1.16023 |    0.01078 |      0.93 | 0.02726 |  2.35 |   1.15967 |  1.11389 |  1.22070 |  0.41 |
-- | "GetPosition upvalue - 2"      |      27 |  2.33912 |    0.01871 |      0.80 | 0.04728 |  2.02 |   2.33459 |  2.27356 |  2.47192 |  0.95 |
-- | "GetPosition upvalue - 4"      |      30 |  4.81110 |    0.02343 |      0.49 | 0.06274 |  1.30 |   4.80652 |  4.69971 |  4.92859 |  0.17 |
-- | "GetPosition upvalue - 8"      |      28 |  9.44573 |    0.03334 |      0.35 | 0.08596 |  0.91 |   9.46808 |  9.30786 |  9.62830 |  0.05 |
-- | "GetPosition upvalue - 16"     |      28 | 18.73834 |    0.05165 |      0.28 | 0.13318 |  0.71 |  18.70728 | 18.52417 | 19.01245 |  0.46 |
-- |--------------------------------|---------|----------|------------|-----------|---------|-------|-----------|----------|----------|-------|
-- | "Baseline, 1 parameter"        |     614 |  0.03811 |    0.00062 |      1.63 | 0.00785 | 20.60 |   0.03815 |  0.03052 |  0.06104 |  0.30 |
-- |--------------------------------|---------|----------|------------|-----------|---------|-------|-----------|----------|----------|-------|

-- Using the self version of a function is the slowest approach. Having it as an upvalue 
-- (and manually adding in the self) has a significant difference: a 5% improvement.

-- When calling the function directly (without using :) it is still less efficient. I suspect
-- this is because of the table operation that is hidden. Having GETUPVAL is cheaper than GETTABLE
-- as an instruction, which is cheaper than SELF.


ModuleName = "Function Scopes"
BenchmarkData = {
    GetPositionLocal01 = "GetPosition local - 1",
    GetPositionLocal02 = "GetPosition local - 2",
    GetPositionLocal04 = "GetPosition local - 4",
    GetPositionLocal08 = "GetPosition local - 8",
    GetPositionLocal16 = "GetPosition local - 16",
    GetPositionUpvalue01 = "GetPosition upvalue - 1",
    GetPositionUpvalue02 = "GetPosition upvalue - 2",
    GetPositionUpvalue04 = "GetPosition upvalue - 4",
    GetPositionUpvalue08 = "GetPosition upvalue - 8",
    GetPositionUpvalue16 = "GetPosition upvalue - 16",
    GetPositionSelf01 = "GetPosition method - 1",
    GetPositionSelf02 = "GetPosition method - 2",
    GetPositionSelf04 = "GetPosition method - 4",
    GetPositionSelf08 = "GetPosition method - 8",
    GetPositionSelf16 = "GetPosition method - 16",
    GetPositionSelfManual01 = "GetPosition manual self - 1",
    GetPositionSelfManual02 = "GetPosition manual self - 2",
    GetPositionSelfManual04 = "GetPosition manual self - 4",
    GetPositionSelfManual08 = "GetPosition manual self - 8",
    GetPositionSelfManual16 = "GetPosition manual self - 16",
}

function GetPositionLocal01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionLocal02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionLocal04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionLocal08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionLocal16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end


local GetPosition = moho.entity_methods.GetPosition

function GetPositionUpvalue01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionUpvalue02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionUpvalue04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionUpvalue08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionUpvalue16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end

function GetPositionSelf01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit:GetPosition()
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelf02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelf04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelf08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelf16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end

function GetPositionSelfManual01(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit.GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelfManual02(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelfManual04(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelfManual08(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)

        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end
function GetPositionSelfManual16(loop)
    local timer = GetSystemTimeSecondsOnlyForProfileUse
    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)
    local start = timer()

    for _ = 1, loop do
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)

        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)

        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)

        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = timer()
    -- destroy dummy unit
    unit:Destroy()
    return final - start
end