
-- GetPositionLocal01:       18 ms
-- GetPositionLocal02:       37 ms
-- GetPositionLocal04:       68 ms
-- GetPositionLocal08:      134 ms
-- GetPositionLocal16:      262 ms

-- GetPositionUpvalue01:     16 ms
-- GetPositionUpvalue02:     34 ms
-- GetPositionUpvalue04:     66 ms
-- GetPositionUpvalue08:    129 ms
-- GetPositionUpvalue16:    259 ms

-- GetPositionSelf01:       018 ms
-- GetPositionSelf02:       037 ms
-- GetPositionSelf04:       072 ms
-- GetPositionSelf08:       141 ms
-- GetPositionSelf16:       279 ms

-- GetPositionSelfManual01:  17 ms
-- GetPositionSelfManual02:  35 ms
-- GetPositionSelfManual04:  69 ms
-- GetPositionSelfManual08: 137 ms
-- GetPositionSelfManual16: 274 ms

-- Using the self version of a function is the slowest approach. Having it as an upvalue 
-- (and manually adding in the self) has a significant difference: a 10% improvement.

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
    GetPositionSelfManual01 = "GetPosition self - 1",
    GetPositionSelfManual02 = "GetPosition self - 2",
    GetPositionSelfManual04 = "GetPosition self - 4",
    GetPositionSelfManual08 = "GetPosition self - 8",
    GetPositionSelfManual16 = "GetPosition self - 16",
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