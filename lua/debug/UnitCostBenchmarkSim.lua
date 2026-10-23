--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- Sim half of the unit cost benchmark, see `/lua/debug/UnitCostBenchmark.lua`. The UI half calls
-- these functions through `ConExecute('SimLua ...')`, so cheats must be enabled.

---@type Unit[]
local spawned = {}

--- Returns the first army that is an enemy of `army`.
---@param army number
---@return number?
local function FindEnemyArmy(army)
    for index, _ in ArmyBrains do
        if index ~= army and IsEnemy(army, index) then
            return index
        end
    end
end

---@param blueprintId UnitId
---@return number
local function UnitSize(blueprintId)
    local bp = __blueprints[string.lower(blueprintId)]
    return math.max(bp.Footprint.SizeX or 1, bp.Footprint.SizeZ or 1, bp.SizeX or 1, bp.SizeZ or 1)
end

--- Spawns groups of up to 10 builders, each group in its own cell of a grid with room for one
--- `target` (including its skirt) and two rows of 5 builders south of it, and orders each group
--- to build its `target`.
---@param blueprintId UnitId
---@param army number
---@param count number
---@param x number
---@param z number
---@param target UnitId
---@return Unit[]
local function SpawnBuildGroups(blueprintId, army, count, x, z, target)
    local targetBp = __blueprints[string.lower(target)]
    local skirt = math.max(targetBp.Physics.SkirtSizeX or 0, targetBp.Physics.SkirtSizeZ or 0, UnitSize(target))
    local builderSpacing = UnitSize(blueprintId) + 2
    local cellX = math.max(skirt, 5 * builderSpacing) + 4
    local cellZ = skirt + 2 * builderSpacing + 4

    local groupCount = math.ceil(count / 10)
    local columns = math.ceil(math.sqrt(groupCount))
    local startX = x - (columns - 1) * 0.5 * cellX
    local startZ = z - (columns - 1) * 0.5 * cellZ

    local units = {}
    for g = 0, groupCount - 1 do
        local siteX = startX + math.mod(g, columns) * cellX
        local siteZ = startZ + math.floor(g / columns) * cellZ

        local group = {}
        for b = 0, math.min(9, count - 1 - 10 * g) do
            local ux = siteX + (math.mod(b, 5) - 2) * builderSpacing
            local uz = siteZ + 0.5 * skirt + 1 + (math.floor(b / 5) + 0.5) * builderSpacing
            local unit = CreateUnitHPR(blueprintId, army, ux, GetTerrainHeight(ux, uz), uz, 0, 0, 0)
            if unit then
                table.insert(group, unit)
                table.insert(units, unit)
                table.insert(spawned, unit)
            end
        end

        IssueBuildAllMobile(group, { siteX, GetTerrainHeight(siteX, siteZ), siteZ }, target, {})
    end
    return units
end

--- Spawns `count` units in a square grid centered on (`x`, `z`).
---@param blueprintId UnitId
---@param army number
---@param count number
---@param x number
---@param z number
---@param spacing? number   # defaults to the unit size plus 2
---@return Unit[]
local function SpawnGrid(blueprintId, army, count, x, z, spacing)
    spacing = spacing or UnitSize(blueprintId) + 2
    local columns = math.ceil(math.sqrt(count))
    local start = (columns - 1) * 0.5 * spacing

    local units = {}
    for i = 0, count - 1 do
        local ux = x - start + math.mod(i, columns) * spacing
        local uz = z - start + math.floor(i / columns) * spacing
        local unit = CreateUnitHPR(blueprintId, army, ux, GetTerrainHeight(ux, uz), uz, 0, 0, 0)
        if unit then
            table.insert(units, unit)
            table.insert(spawned, unit)
        end
    end
    return units
end

--- Fills the storage of the army, so that units with an energy upkeep (intel, shields, fabricators)
--- stay enabled and builders do not stall for the duration of a case.
---@param army number
local function GiveEconomy(army)
    local brain = ArmyBrains[army]
    brain:GiveStorage('MASS', 1e9)
    brain:GiveStorage('ENERGY', 1e9)
    brain:GiveResource('MASS', 1e9)
    brain:GiveResource('ENERGY', 1e9)
end

--- Orders land units to move in a straight line for at least `duration` seconds at their max speed,
--- towards the side of the playable area with the most room. Air units land once their orders are
--- done, so they get enough laps of a square around their position to fly for `duration` seconds.
---@param units Unit[]
---@param duration number
local function IssueMovement(units, duration)
    local rect = ScenarioInfo.MapData.PlayableRect
    local minX, maxX = 0, ScenarioInfo.size[1]
    if rect then
        minX, maxX = rect[1], rect[3]
    end

    local warned = false
    for _, unit in units do
        local pos = unit:GetPosition()
        local direction = (maxX - pos[1] > pos[1] - minX) and 1 or -1
        local room = (direction == 1) and (maxX - 10 - pos[1]) or (pos[1] - minX - 10)

        if EntityCategoryContains(categories.AIR, unit) then
            local half = 40
            local corners = {
                { pos[1] + half, pos[2], pos[3] + half },
                { pos[1] - half, pos[2], pos[3] + half },
                { pos[1] - half, pos[2], pos[3] - half },
                { pos[1] + half, pos[2], pos[3] - half },
            }
            local legs = math.ceil(1.1 * duration * (unit.Blueprint.Air.MaxAirspeed or 10) / (2 * half))
            for leg = 1, legs do
                IssueMove({ unit }, corners[math.mod(leg - 1, 4) + 1])
            end
        else
            local distance = 1.1 * duration * (unit.Blueprint.Physics.MaxSpeed or 1)
            if distance > room then
                if not warned then
                    WARN(string.format("UnitCostBenchmark: %s needs %.0f ogrids to move for %.0f seconds, the map has %.0f", unit.UnitId, distance, duration, room))
                    warned = true
                end
                distance = room
            end
            IssueMove({ unit }, { pos[1] + direction * distance, pos[2], pos[3] })
        end
    end
end

--- Spawns one benchmark case. `mode` decides what the units do once spawned:
--- - `idle`: nothing;
--- - `move`: see `IssueMovement`;
--- - `build`: groups of 10 units each build a `target`, see `SpawnBuildGroups`;
--- - `targets`: only spawn the invulnerable hostile targets of the `engage` mode, for the baseline;
--- - `engage`: as `targets`, plus the units, which auto-target the targets. Without `targetDistance`,
---   each unit has a target next to it. With it, `targetCount` targets form a grid that far along the
---   x axis, and an omni sensor gives the army radar on them.
---@param blueprintId UnitId
---@param count number
---@param army number
---@param x number
---@param z number
---@param mode 'idle' | 'move' | 'build' | 'targets' | 'engage'
---@param target? UnitId
---@param duration number           # seconds the units must stay busy for
---@param targetCount? number       # defaults to `count`
---@param targetDistance? number
function Spawn(blueprintId, count, army, x, z, mode, target, duration, targetCount, targetDistance)
    GiveEconomy(army)

    -- without a distance, the units and targets share one grid, with the targets offset half a cell
    local spacing = nil
    if (mode == 'targets' or mode == 'engage') and not targetDistance then
        spacing = 2 * math.max(UnitSize(blueprintId), UnitSize(target)) + 4
    end

    local units = {}
    if mode == 'build' then
        units = SpawnBuildGroups(blueprintId, army, count, x, z, target)
    elseif mode ~= 'targets' then
        units = SpawnGrid(blueprintId, army, count, x, z, spacing)
    end

    if mode == 'move' then
        IssueMovement(units, duration)
    elseif mode == 'targets' or mode == 'engage' then
        local enemy = FindEnemyArmy(army)
        if not enemy then
            WARN("UnitCostBenchmark: no enemy army to spawn targets for, skipping")
            return
        end

        local targets
        if targetDistance then
            -- packed edge to edge, so that a large number of targets still fits between the min and max range
            targets = SpawnGrid(target, enemy, targetCount or count, x + targetDistance, z, UnitSize(target))

            -- behind the grid of units, away from the targets
            local gridHalf = 0.5 * math.ceil(math.sqrt(count)) * (UnitSize(blueprintId) + 2)
            local omniX = x - gridHalf - 20
            local omni = CreateUnitHPR('UEB3104', army, omniX, GetTerrainHeight(omniX, z), z, 0, 0, 0)
            table.insert(spawned, omni)
        else
            targets = SpawnGrid(target, enemy, count, x, z + 0.5 * spacing, spacing)
        end
        for _, unit in targets do
            unit:SetCanTakeDamage(false)
            unit:SetCanBeKilled(false)
        end
    end

    SPEW(string.format("UnitCostBenchmark: spawned %d/%d %s (%s)", table.getn(units), count, blueprintId, mode))
end

--- Logs what the spawned units are doing, to check that a case measured what it claims to: builders
--- building, movers still moving, air units still in the air. Also counts units near (`x`, `z`) that
--- were not spawned by the benchmark, such as leftovers that block build sites.
---@param x number
---@param z number
function Report(x, z)
    local alive, building, assisting, moving, flying, targeting = 0, 0, 0, 0, 0, 0
    local own = {}
    for _, unit in spawned do
        if not IsDestroyed(unit) then
            own[unit.EntityId] = true
            if unit.UnitBeingBuilt then
                own[unit.UnitBeingBuilt.EntityId] = true
            end
            alive = alive + 1
            if unit:IsUnitState('Building') then
                building = building + 1
            end
            if unit:IsUnitState('Repairing') or unit:IsUnitState('Guarding') then
                assisting = assisting + 1
            end
            if unit:IsUnitState('Moving') then
                moving = moving + 1
            end
            if EntityCategoryContains(categories.AIR, unit) and unit:GetCurrentLayer() == 'Air' then
                flying = flying + 1
            end
            for i = 1, unit:GetWeaponCount() do
                if unit:GetWeapon(i):WeaponHasTarget() then
                    targeting = targeting + 1
                    break
                end
            end
        end
    end

    local foreign = 0
    for _, unit in GetUnitsInRect(x - 150, z - 150, x + 150, z + 150) or {} do
        if not own[unit.EntityId] and not IsDestroyed(unit) then
            foreign = foreign + 1
        end
    end

    SPEW(string.format(
        "UnitCostBenchmark: state: %d alive, %d building, %d assisting, %d moving, %d flying, %d with a target; %d other units nearby",
        alive, building, assisting, moving, flying, targeting, foreign
    ))
end

--- Destroys everything spawned by `Spawn`, including unfinished structures of builders, without
--- wrecks or death effects.
function Clear()
    for _, unit in spawned do
        if not IsDestroyed(unit) then
            local building = unit.UnitBeingBuilt
            if building and not IsDestroyed(building) then
                building:Destroy()
            end
            unit:Destroy()
        end
    end
    spawned = {}
end
