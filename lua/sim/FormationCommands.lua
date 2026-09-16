---
--- Helper functions to calculate the angles for the formations commands and issue those commands.
---
--- All the IssueForm commands take `angle` argument that defines which way the platoon should be facing.
--- Same as when the player holds right click and by rotating the mouse chooses the orientation of the formation.
---
--- Commands on the `Platoon` class don't support setting the angle and the formation is always facing south.
---

local Platoon = import("/lua/platoon.lua").Platoon
local Utilities = import("/lua/utilities.lua")

local ipairs = ipairs
local tableGetn = table.getn
local tableInsert = table.insert
local tableMap = table.map
local Vector = Vector

-- Base orientation vector when the formation angle is 0
local baseZeroAngle = Vector(0, 0, 1)

---Converts a table with position to vector if its not a vector already
---@param pos table<{[1]: number, [2]: number, [3]: number}>|Vector
local function positionToVector(pos)
    if pos.x then
        return pos
    end
    return Vector(pos[1], pos[2], pos[3])
end

--- Returns angles the unit formation should face in `IssueFormation` commands for given `path`.
---@param path Vector[]
---@param initialPosition? Vector Position that is used to calculate the first angle of the path. Defaults to last position of the path
---@return number[] angles List of angles for every position
function GetAnglesForRoute(path, initialPosition)
    local count = tableGetn(path)
    if count == 0 then return {} end

    -- Convert positions from table to `Vector` when needed
    ---@type Vector[]
    local positions = tableMap(path, positionToVector)
    ---@type number[]
    local angles = {}

    for k = 1, count do
        local currPos = positions[k - 1] or initialPosition or positions[count]
        local nextPos = positions[k]

        local direction = Utilities.GetDirectionVector(nextPos, currPos)
        angles[k] = Utilities.GetAngleCCW(baseZeroAngle, direction)
    end

    return angles
end

--- Cache for `GetSquadsForFormationOrder` to avoid creating a new table every time an order is issued.
local cachedSquad = {}
--- Returns a list of squads to issue formation order to.
---
---If `squad` is provided, returns a cached list with only that squad, otherwise returns all squad names.
---@param squad? PlatoonSquads
---@return PlatoonSquads[]
function GetSquadsForFormationOrder(squad)
    local squads
    if squad then
        cachedSquad[1] = squad
        squads = cachedSquad
    else
        squads = Platoon.SquadNames
    end

    return squads
end

---@alias UnitsFormationCommand
---| `IssueFormMove` #Formation move
---| `IssueFormAggressiveMove` # Formation attack move
---| `IssueFormPatrol` # Formation patrol. Does NOT return `SimCommand`
---| `IssueFormAttack` # Formation attack

--- Issues formation order to the units, using `angles` to oreient units at each node.
---@param units Unit[]
---@param fn UnitsFormationCommand One of the `IssueFormationCommand` functions
---@param positions Vector[]
---@param angles number[]
---@param formation UnitFormations
---@return SimCommand[] #If `fn` is `IssueFormPatrol` the returned table will be empty
function UnitsFormationOrder(units, fn, positions, angles, formation)
    local commands = {}
    for i, position in ipairs(positions) do
        local cmd = fn(units, position, formation, angles[i])
        if cmd then
            tableInsert(commands, cmd)
        end
    end

    return commands
end
