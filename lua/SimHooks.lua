---@declare-global

do
    -- can only cause issues, like remote code exploit
    _G.loadstring = nil
end

do
    -- upvalue for performance
    local EntityCategoryFilterDown = EntityCategoryFilterDown
    local CategoriesNoDummyUnits = categories.ALLUNITS - categories.DUMMYUNIT

    local oldGetUnitsInRect = _G.GetUnitsInRect
    ---Retrieves all units in a rectangle, Excludes dummy units, such as the Cybran Build Drone, by default.
    ---@param rtlx number Top left x coordinate.
    ---@param tlz number Top left z coordinate.
    ---@param brx number Bottom right x coordinate.
    ---@param brz number Bottom right z coordinate.
    ---@return Unit[]?
    ---@overload fun(rectangle: Rectangle): Unit[]?
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
        ---@diagnostic disable-next-line: redundant-parameter
        oldIssueBuildMobile(units, position, blueprintID, table, false)
    end

    _G.IssueBuildAllMobile = function(units, position, blueprintID, table)
        ---@diagnostic disable-next-line: redundant-parameter
        oldIssueBuildMobile(units, position, blueprintID, table, true)
    end
end


---@type { [1]: moho.unit_methods }
local UnitsCache = {}

--- Orders a unit to attack-move to a target
---
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueAggressiveMove for units group variant
---@param unit Unit
---@param target Unit | Vector | Prop | Blip
---@return SimCommand
function IssueToUnitAggressiveMove(unit, target)
    UnitsCache[1] = unit
    return IssueAggressiveMove(UnitsCache, target)
end

--- Orders a unit to attack a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueAttack for units group variant
---@param unit Unit
---@param target Unit | Vector | Prop | Blip
---@return SimCommand
function IssueToUnitAttack(unit, target)
    UnitsCache[1] = unit
    return IssueAttack(UnitsCache, target)
end

--- Orders a factory to build a unit.
--- Takes 1 tick to apply.
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueBuildFactory for units group variant
---@see IssueToUnitBuildMobile to build a unit with engineers
---@param unit Unit
---@param blueprintID string
---@param count integer
---@return SimCommand
function IssueToUnitBuildFactory(unit, blueprintID, count)
    UnitsCache[1] = unit
    return IssueBuildFactory(UnitsCache, blueprintID, count)
end

--- Orders a to build a unit, the nearest unit is given the order
--- Takes some time to apply (at least 3 ticks).
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueBuildMobile for units group variant
---@see IssueToUnitBuildFactory to produce units in a factory
---@param unit Unit
---@param position Vector
---@param blueprintID string
---@param table number[] # A list of alternative build locations, similar to AiBrain.BuildStructure. Doesn't appear to function properly
function IssueToUnitBuildMobile(unit, position, blueprintID, table)
    UnitsCache[1] = unit
    return IssueBuildMobile(UnitsCache, position, blueprintID, table)
end

--- Orders a unit to capture a target, usually engineers
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueCapture for units group variant
---@param unit Unit
---@param target Unit
---@return SimCommand
function IssueToUnitCapture(unit, target)
    UnitsCache[1] = unit
    return IssueCapture(UnitsCache, target)
end

--- Clears out all commands issued on the unit, this happens immediately.
---
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueClearCommands for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitClearCommands(unit)
    UnitsCache[1] = unit
    return IssueClearCommands(UnitsCache)
end

--- Clears out all commands issued on the factory without affecting
--- the build queue, allows you to change the rally point
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueClearFactoryCommands for units group variant
---@param factory Unit
---@return SimCommand
function IssueToUnitClearFactoryCommands(factory)
    UnitsCache[1] = factory
    return IssueClearFactoryCommands(UnitsCache)
end

--- Orders a unit to destroy itself, doesn't leave a wreckage
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueToUnitKillSelf for an alternative that does leave a wreckage
---@see IssueDestroySelf for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitDestroySelf(unit)
    UnitsCache[1] = unit
    return IssueDestroySelf(UnitsCache)
end

--- Orders a unit to dive
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueDive for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitDive(unit)
    UnitsCache[1] = unit
    return IssueDive(UnitsCache)
end

--- Orders a factory to assist another factory
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueFactoryAssist for units group variant
---@param unit Unit
---@param target Unit
---@return SimCommand
function IssueToUnitFactoryAssist(unit, target)
    UnitsCache[1] = unit
    return IssueFactoryAssist(UnitsCache, target)
end

--- Orders a factory to set rally point
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueFactoryRallyPoint for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitFactoryRallyPoint(unit, position)
    UnitsCache[1] = unit
    return IssueFactoryRallyPoint(UnitsCache, position)
end

--- Orders unit to setup a ferry
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueFerry for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitFerry(unit, position)
    UnitsCache[1] = unit
    return IssueFerry(UnitsCache, position)
end

--- Orders a unit to guard a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueGuard for units group variant
---@param unit Unit
---@param target Unit | Vector
---@return SimCommand
function IssueToUnitGuard(unit, target)
    UnitsCache[1] = unit
    return IssueGuard(UnitsCache, target)
end

--- Orders a unit to kill themselves
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueToUnitDestroySelf # an alternative that does not leave a wreckage
---@see IssueKillSelf for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitKillSelf(unit)
    UnitsCache[1] = unit
    return IssueKillSelf(UnitsCache)
end

--- Orders a unit to move to a position.
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueMove for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitMove(unit, position)
    UnitsCache[1] = unit
    return IssueMove(UnitsCache, position)
end

--- Orders a unit to move off a factory build site.
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueMoveOffFactory for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitMoveOffFactory(unit, position)
    UnitsCache[1] = unit
    return IssueMoveOffFactory(UnitsCache, position)
end

--- Orders a unit to launch a strategic missile at a position
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueToUnitTactical # for tactical missiles
---@see IssueNuke for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitNuke(unit, position)
    UnitsCache[1] = unit
    return IssueNuke(UnitsCache, position)
end

--- Orders a unit to use Overcharge at a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueOverCharge for units group variant
---@param unit Unit
---@param target Unit
---@return SimCommand
function IssueToUnitOverCharge(unit, target)
    UnitsCache[1] = unit
    return IssueOverCharge(UnitsCache, target)
end

--- Orders a unit to patrol to a position
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssuePatrol for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitPatrol(unit, position)
    UnitsCache[1] = unit
    return IssuePatrol(UnitsCache, position)
end

--- Orders a unit to pause building, upgrading, and other tasks.
--- This pause order is put into the order queue, so it may not apply immediately.
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see Unit.SetPaused to pause a unit in the middle of a task.
---@see IssuePause for units group variant
---@param unit Unit
function IssueToUnitPause(unit)
    UnitsCache[1] = unit
    return IssuePause(UnitsCache)
end

--- Orders a unit to reclaim a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueReclaim for units group variant
---@param unit Unit
---@param target ReclaimObject
---@return SimCommand
function IssueToUnitReclaim(unit, target)
    UnitsCache[1] = unit
    return IssueReclaim(UnitsCache, target)
end

--- Orders a unit to repair a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueRepair for units group variant
---@param unit Unit
---@param target Unit
---@return SimCommand
function IssueToUnitRepair(unit, target)
    UnitsCache[1] = unit
    return IssueRepair(UnitsCache, target)
end

--- Orders a unit to sacrifice, yielding part of their build cost to a target
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueSacrifice for units group variant
---@param unit Unit
---@param target Unit
---@return SimCommand
function IssueToUnitSacrifice(unit, target)
    UnitsCache[1] = unit
    return IssueSacrifice(UnitsCache, target)
end

--- Orders a unit to run a script sequence, as an example:
--- `{ TaskName = "EnhanceTask", Enhancement = "AdvancedEngineering" }`
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueScript for units group variant
---@param unit Unit
---@param order Task
---@return ScriptTask
function IssueToUnitScript(unit, order)
    UnitsCache[1] = unit
    return IssueScript(UnitsCache, order)
end

--- Orders a unit (SML or SMD) to build a nuke
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueSiloBuildNuke for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitSiloBuildNuke(unit)
    UnitsCache[1] = unit
    return IssueSiloBuildNuke(UnitsCache)
end

--- Orders a unit to build a tactical missile
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueSiloBuildTactical for units group variant
---@param unit Unit
---@return SimCommand
function IssueToUnitSiloBuildTactical(unit)
    UnitsCache[1] = unit
    return IssueSiloBuildTactical(UnitsCache)
end

--- Orders a unit to stop, this happens immediately
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueStop for units group variant
---@param unit Unit
function IssueToUnitStop(unit)
    UnitsCache[1] = unit
    return IssueStop(UnitsCache)
end

--- Orders a unit to launch a tactical missile
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueToUnitNuke # for nuclear missiles
---@see IssueTactical for units group variant
---@param unit Unit
---@param target Unit | Vector
---@return SimCommand
function IssueToUnitTactical(unit, target)
    UnitsCache[1] = unit
    return IssueTactical(UnitsCache, target)
end

--- Orders a unit to teleport to a position
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueTeleport for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitTeleport(unit, position)
    UnitsCache[1] = unit
    return IssueTeleport(UnitsCache, position)
end

--- This function is **not** compatible with the Steam version of the game.
---@see IssueTeleportToBeacon for units group variant
---@param unit Unit
---@param beacon unknown
---@return SimCommand
function IssueToUnitTeleportToBeacon(unit, beacon)
    UnitsCache[1] = unit
    return IssueTeleportToBeacon(UnitsCache, beacon)
end

--- Orders a unit to attach itself to a transport
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueTransportLoad for units group variant
---@param unit Unit
---@param transport Unit
---@return SimCommand
function IssueToUnitTransportLoad(unit, transport)
    UnitsCache[1] = unit
    return IssueTransportLoad(UnitsCache, transport)
end

--- Orders a transport to unload their cargo at a position
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueTransportUnload for units group variant
---@param unit Unit
---@param position Vector
---@return SimCommand
function IssueToUnitTransportUnload(unit, position)
    UnitsCache[1] = unit
    return IssueTransportUnload(UnitsCache, position)
end

--- Orders a transport or carrier to unload specific units by `categories`
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueTransportUnloadSpecific for units group variant
---@param unit Unit
---@param category EntityCategory
---@param position Vector
---@return SimCommand
function IssueToUnitTransportUnloadSpecific(unit, category, position)
    UnitsCache[1] = unit
    return IssueTransportUnloadSpecific(UnitsCache, category, position)
end

--- Orders a unit to upgrade
--- 
--- This function is **not** compatible with the Steam version of the game.
---
---@see IssueUpgrade for units group variant
---@param unit Unit
---@param blueprintID string
---@return SimCommand
function IssueToUnitUpgrade(unit, blueprintID)
    UnitsCache[1] = unit
    return IssueUpgrade(UnitsCache, blueprintID)
end
