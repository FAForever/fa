
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