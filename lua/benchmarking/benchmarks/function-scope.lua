
-- GetPositionLocal01:      0.0185
-- GetPositionLocal02:      0.0371
-- GetPositionLocal04:      0.0683
-- GetPositionLocal08:      0.1347
-- GetPositionLocal16:      0.2626

-- GetPositionUpvalue01:    0.0161
-- GetPositionUpvalue02:    0.0346
-- GetPositionUpvalue04:    0.0664
-- GetPositionUpvalue08:    0.1293
-- GetPositionUpvalue16:    0.2597

-- GetPositionSelf01:       0.0180
-- GetPositionSelf02:       0.0375
-- GetPositionSelf04:       0.0722
-- GetPositionSelf08:       0.1416
-- GetPositionSelf16:       0.2797

-- GetPositionSelfManual01: 0.0175
-- GetPositionSelfManual02: 0.0356
-- GetPositionSelfManual04: 0.0693
-- GetPositionSelfManual08: 0.1376
-- GetPositionSelfManual16: 0.2744

-- Using the self version of a function is the slowest approach. Having it as an upvalue 
-- (and manually adding in the self) has a significant difference: a 10% improvement.

-- When calling the function directly (without using :) it is still less efficient. I suspect
-- this is because of the table operation that is hidden. Having GETUPVAL is cheaper than GETTABLE
-- as an instruction, which is cheaper than SELF.

function GetPositionLocal01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        local GetPosition = moho.entity_methods.GetPosition
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionLocal02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionLocal04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        local GetPosition = moho.entity_methods.GetPosition 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionLocal08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
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

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionLocal16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
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

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

local GetPosition = moho.entity_methods.GetPosition

function GetPositionUpvalue01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionUpvalue02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionUpvalue04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionUpvalue08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)

        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
        GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionUpvalue16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
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

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelf01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelf02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelf04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelf08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()

        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
        unit:GetPosition()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelf16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do
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

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelfManual01()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit.GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelfManual02()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelfManual04()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelfManual08()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
        unit.GetPosition(unit)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end

function GetPositionSelfManual16()

    -- create a dummy unit
    local unit = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0)

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
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

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    -- destroy dummy unit
    unit:Destroy()

    return final - start
end