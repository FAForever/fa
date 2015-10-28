MassActiveBuffCheck = function(buff, unit)
    local bp = unit:GetBlueprint()
    if bp.Economy.BuildableCategory and table.getn(bp.Economy.BuildableCategory) > 0 then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

EnergyActiveBuffCheck = MassActiveBuffCheck
