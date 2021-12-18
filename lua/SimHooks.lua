
-- upvalue for performance
local EntityCategoryFilterDown = EntityCategoryFilterDown
local CategoriesNoInsignificant = categories.ALLUNITS - categories.INSIGNIFICANTUNIT

do
    local oldGetUnitsInRect = GetUnitsInRect

    --- Retrieves all units in a rectangle, Excludes insignificant units, such as the Cybran Drone, by default.
    -- @param rectangle The rectangle to look for units in {x0, z0, x1, z1}.
    -- OR
    -- @param tlx Top left x coordinate.
    -- @param tlz Top left z coordinate.
    -- @param brx Bottom right x coordinate.
    -- @param brz Bottom right z coordinate.
    -- @return nil if none found or a table.
    _G.GetUnitsInRect = function(rtlx, tlz, brx, brz)

        -- try and retrieve units
        local units 
        if brx then 
            units = oldGetUnitsInRect(rtlx, tlz, brx, brz)
        else
            units = oldGetUnitsInRect(rtlx)
        end

        -- as it can return nil, check if we have any units
        if units then 
            units = EntityCategoryFilterDown(CategoriesNoInsignificant, units)
        end

        return units
    end
end