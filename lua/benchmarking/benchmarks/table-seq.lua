
-- 0.071
-- 0.070
-- 0.071
function TableTest2()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local t = { 
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0) 
    }

    local sum = 1
    for k = 1, 100000 do 
        local unit1 = t.unit1
        local unit2 = t.unit2
        if unit1 and unit2 then 
            unit1:GetPosition()
            unit2:GetPosition()
            unit1:GetPositionXYZ()
            unit2:GetPositionXYZ()
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    t.unit1:Destroy()
    t.unit2:Destroy()

    return final - start
end

-- 0.078
-- 0.073
-- 0.074
function TableTest1()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local t = { 
        unit1 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0),
        unit2 = CreateUnit("uaa0303", 1, 0, 0, 0, 0, 0, 0, 0) 
    }

    local sum = 1
    for k = 1, 100000 do 
        if t.unit1 and t.unit2 then 
           t.unit1:GetPosition()
           t.unit2:GetPosition()
           t.unit1:GetPositionXYZ()
           t.unit2:GetPositionXYZ()
        end
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    t.unit1:Destroy()
    t.unit2:Destroy()

    return final - start
end