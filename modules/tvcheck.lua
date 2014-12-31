function Init()
            if GetUnitById(0) and GetUnitById(0):GetBlueprint().Economy and not GetUnitById(0):GetBlueprint().Economy.xpValue
            then
                return false
            end
            if GetUnitById(0) and not GetUnitById(0):GetBlueprint().Economy.xpValue then
                return true
            end
end




