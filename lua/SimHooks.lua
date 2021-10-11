
-- upvalue for performance
local EntityCategoryFilterDown = EntityCategoryFilterDown
local CategoriesNoInsignificant = categories.ALLUNITS - categories.INSIGNIFICANTUNIT

do
    local oldGetUnitsInRect = GetUnitsInRect

    --- Retrieves all units in a rectangle, Excludes insignificant units, such as the Cybran Drone, by default.
    -- @param rectangle The rectangle to look for units in.
    -- @param excludeInsignificantUnits Whether or not we exclude insignificant units, defaults to true. 
    _G.GetUnitsInRect = function(rectangle, excludeInsignificantUnits)

        -- retrieve the units 
        local units = oldGetUnitsInRect(rectangle)

        -- as it can return nil, check if we have any units
        if units then 
            -- if it isn't set, we try and exclude them anyhow
            if excludeInsignificantUnits == nil then 
                excludeInsignificantUnits = true 
            end

            -- check if we want to exclude them
            if excludeInsignificantUnits then 
                units = EntityCategoryFilterDown(CategoriesNoInsignificant, units)
            end
        end

        return units
    end
end