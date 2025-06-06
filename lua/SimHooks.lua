---@declare-global

do
    -- can only cause issues, like remote code exploit
    _G.loadstring = nil
end

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

do
    -- implementation of https://github.com/FAForever/FA-Binary-Patches/pull/29
    local oldIssueBuildMobile = _G.IssueBuildMobile
    _G.IssueBuildMobile = function(units, position, blueprintID, table)
        oldIssueBuildMobile(units, position, blueprintID, table, false)
    end

    _G.IssueBuildAllMobile = function(units, position, blueprintID, table)
        oldIssueBuildMobile(units, position, blueprintID, table, true)
    end
end


---@type { [1]: moho.unit_methods }
local UnitsCache = {}

--- Orders a unit to move to a location. See `IssueMove` when you want to apply the order to a group of units.
---
--- This use of this function is **not** compatible with the Steam version of the game.
---@param unit moho.unit_methods
---@param position Vector
---@return SimCommand
IssueToUnitMove = function(unit, position)
    UnitsCache[1] = unit
    return IssueMove(UnitsCache, position)
end

--- Orders a unit to move off a factory build site. See `IssueMoveOffFactory` when you want to apply the order to a group of units.
---
--- This use of this function is **not** compatible with the Steam version of the game.
---@param unit moho.unit_methods
---@param position Vector
---@return SimCommand
IssueToUnitMoveOffFactory = function(unit, position)
    UnitsCache[1] = unit
    return IssueMoveOffFactory(UnitsCache, position)
end

--- Clears out all commands issued on the unit, this happens immediately. See `IssueClearCommands` when you want to apply the order to a group of units.
---
--- This use of this function is **not** compatible with the Steam version of the game.
---@param unit moho.unit_methods
---@return SimCommand
IssueToUnitClearCommands = function(unit)
    UnitsCache[1] = unit
    return IssueClearCommands(UnitsCache)
end

--- Issues a unit to stop what it was doing, this happens immediately. See `IssueStop` when you want to apply the order to a group of units.
---
--- This use of this function is **not** compatible with the Steam version of the game.
---@param unit moho.unit_methods
IssueToUnitStop = function(unit)
    UnitsCache[1] = unit
    IssueStop(UnitsCache)
end
