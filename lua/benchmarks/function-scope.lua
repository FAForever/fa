
-- Results with loop count 50000:
--
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | Name                           | Samples | Mean ms | +/- 95% ms | +/- 95% % | Dev ms |  CV % | Median ms |  Min ms |  Max ms |  Skew |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "GetPosition local - 1"        |      28 |  6.6076 |     0.0270 |      0.41 | 0.0697 |  1.05 |    6.6071 |  6.5002 |  6.7749 |  0.40 |
-- | "GetPosition local - 2"        |      27 | 12.3992 |     0.0216 |      0.17 | 0.0546 |  0.44 |   12.3901 | 12.3138 | 12.5122 |  0.69 |
-- | "GetPosition local - 4"        |      27 | 23.8987 |     0.0414 |      0.17 | 0.1046 |  0.44 |   23.8953 | 23.6816 | 24.1089 |  0.13 |
-- | "GetPosition local - 8"        |      28 | 46.4129 |     0.0648 |      0.14 | 0.1671 |  0.36 |   46.3867 | 46.1884 | 46.8292 |  0.74 |
-- | "GetPosition local - 16"       |      27 | 91.4369 |     0.2240 |      0.24 | 0.5661 |  0.62 |   91.3544 | 90.5762 | 92.7734 |  0.40 |
-- | "GetPosition method - 1"       |      30 |  6.1854 |     0.0148 |      0.24 | 0.0398 |  0.64 |    6.1798 |  6.1340 |  6.2714 |  0.36 |
-- | "GetPosition method - 2"       |      27 | 12.5495 |     0.0402 |      0.32 | 0.1017 |  0.81 |   12.5427 | 12.3901 | 12.7563 |  0.24 |
-- | "GetPosition method - 4"       |      29 | 24.7129 |     0.0434 |      0.18 | 0.1140 |  0.46 |   24.7192 | 24.5361 | 24.9023 | -0.06 |
-- | "GetPosition method - 8"       |      28 | 49.0505 |     0.0987 |      0.20 | 0.2545 |  0.52 |   48.9502 | 48.6450 | 49.6216 |  0.56 |
-- | "GetPosition method - 16"      |      30 | 97.0723 |     0.2375 |      0.24 | 0.6361 |  0.66 |   96.8933 | 96.2219 | 98.1750 |  0.24 |
-- | "GetPosition manual self - 1"  |      29 |  6.1109 |     0.0200 |      0.33 | 0.0526 |  0.86 |    6.1035 |  6.0120 |  6.2256 |  0.20 |
-- | "GetPosition manual self - 2"  |      29 | 12.4101 |     0.0245 |      0.20 | 0.0644 |  0.52 |   12.3901 | 12.2986 | 12.5427 |  0.24 |
-- | "GetPosition manual self - 4"  |      28 | 24.3835 |     0.0492 |      0.20 | 0.1268 |  0.52 |   24.3530 | 24.1699 | 24.6582 |  0.53 |
-- | "GetPosition manual self - 8"  |      28 | 48.4467 |     0.0878 |      0.18 | 0.2263 |  0.47 |   48.4314 | 48.0042 | 48.9197 |  0.10 |
-- | "GetPosition manual self - 16" |      25 | 95.6897 |     0.1386 |      0.14 | 0.3358 |  0.35 |   95.5811 | 95.2454 | 96.5576 |  0.79 |
-- | "GetPosition upvalue - 1"      |      30 |  5.7322 |     0.0127 |      0.22 | 0.0341 |  0.59 |    5.7373 |  5.6763 |  5.7983 |  0.32 |
-- | "GetPosition upvalue - 2"      |      26 | 11.5920 |     0.0214 |      0.18 | 0.0530 |  0.46 |   11.5967 | 11.5051 | 11.6882 |  0.23 |
-- | "GetPosition upvalue - 4"      |      29 | 23.0197 |     0.0457 |      0.20 | 0.1202 |  0.52 |   22.9797 | 22.8577 | 23.2849 |  0.47 |
-- | "GetPosition upvalue - 8"      |      29 | 45.9605 |     0.0983 |      0.21 | 0.2584 |  0.56 |   45.9595 | 45.6238 | 46.6309 |  0.63 |
-- | "GetPosition upvalue - 16"     |      28 | 90.8290 |     0.2021 |      0.22 | 0.5212 |  0.57 |   90.7288 | 89.7522 | 91.8884 |  0.32 |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|
-- | "Baseline, 1 parameter"        |     606 |  0.1902 |     0.0021 |      1.11 | 0.0265 | 13.92 |    0.1831 |  0.1526 |  0.7019 | 12.72 |
-- |--------------------------------|---------|---------|------------|-----------|--------|-------|-----------|---------|---------|-------|

-- Using the self version of a function is the slowest approach. Having it as an upvalue 
-- (and manually adding in the self) has a significant difference: a 6% improvement.

-- When calling the function directly (without using :) it is still less efficient. I suspect
-- this is because of the table operation that is hidden. Having GETUPVAL is cheaper than GETTABLE
-- as an instruction, which is cheaper than SELF.

-- The local versions look up `GetPosition` in every iteration, which costs about 12 to 18 ns. So
-- they only catch up with the upvalue versions once that is spread over several calls.


ModuleName = "Function Scopes"
ModuleLoopCount = 50000
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 1)
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