


do

    -- upvalue for performance
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    local CategoriesNoDummyUnits = categories.ALLUNITS - categories.DUMMYUNIT

    --- Retrieves all units in a rectangle, Excludes dummy units, such as the Cybran Build Drone, by default.
    -- @param rectangle The rectangle to look for units in {x0, z0, x1, z1}.
    -- @return nil if none found or a table.
    -- OR
    -- @param tlx Top left x coordinate.
    -- @param tlz Top left z coordinate.
    -- @param brx Bottom right x coordinate.
    -- @param brz Bottom right z coordinate.
    -- @return nil if none found or a table.
    local oldGetUnitsInRect = _G.GetUnitsInRect
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

do 

    -- upvalue for performance
    local Random = Random

    local oldDrawCircle = _G.DrawCircle
    _G.DrawCircle = function(position, diameter, color)

        if not ScenarioInfo.GameHasAIs then
            -- cause a desync if only one player calls this function
            Random()
        end

        oldDrawCircle(position, diameter, color)
    end

    local oldDrawLine = _G.DrawLine
    _G.DrawLine = function(a, b, color)

        if not ScenarioInfo.GameHasAIs then
            -- cause a desync if only one player calls this function
            Random()
        end

        oldDrawLine(a, b, color)
    end

    local oldDrawLinePop = _G.DrawLinePop
    _G.DrawLinePop = function(a, b, color)

        if not ScenarioInfo.GameHasAIs then
            -- cause a desync if only one player calls this function
            Random()
        end

        oldDrawLinePop(a, b, color)
    end
end

do

    -- do not allow command units to be given
    local oldChangeUnitArmy = _G.ChangeUnitArmy
    _G.ChangeUnitArmy = function(unit, army, noRestrictions)
        if unit and noRestrictions then
            return oldChangeUnitArmy(unit, army)
        end

        -- do not allow command units to be shared
        if unit and unit.Blueprint.CategoriesHash["COMMAND"] then
            return nil
        end

        return oldChangeUnitArmy(unit, army)
    end
end