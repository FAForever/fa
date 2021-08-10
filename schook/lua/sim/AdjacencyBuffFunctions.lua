MassActiveBuffCheck = function(buff, unit)
    local bp = unit.Blueprint
    if bp.Economy.BuildableCategory and not table.empty(bp.Economy.BuildableCategory) then
        return true
    end
    if EntityCategoryContains(categories.SILO, unit) and EntityCategoryContains(categories.STRUCTURE, unit) then
        return true
    end
    return false
end

EnergyActiveBuffCheck = MassActiveBuffCheck
