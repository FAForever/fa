
-- upvalue for performance
local EntityCategoryFilterDown = EntityCategoryFilterDown
local CategoriesNoDummyUnits = categories.ALLUNITS - categories.DUMMYUNIT

do
    local oldGetUnitsInRect = GetUnitsInRect

    --- Retrieves all units in a rectangle, Excludes dummy units, such as the Cybran Build Drone, by default.
    -- @param rectangle The rectangle to look for units in {x0, z0, x1, z1}.
    -- @return nil if none found or a table.
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
            units = EntityCategoryFilterDown(CategoriesNoDummyUnits, units)
        end

        return units
    end
end