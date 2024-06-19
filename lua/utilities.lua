-----------------------------------------------------------------
-- File     :  /lua/utilities.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Utility functions for scripts.
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local MathMod = math.mod

function GetDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3(entity1:GetPosition(), entity2:GetPosition())
end

local powersOf2 = {[0] = 1,
    2,       4,       8,       16,       32,       64,       128,       256,       512,       1024,
    2048,    4096,    8192,    16384,    32768,    65536,    131072,    262144,    524288,    1048576,
    2097152, 4194304, 8388608, 16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824,
}

--- Returns the bit in a position of a number
---@param number number
---@param bit number
---@return number
function SelectBit(number, bit)
    local power = powersOf2[bit]
    if MathMod(number, power) <= power * 0.5 then
        return 1
    else
        return 0
    end
end

--- Returns the boolean in a bit position of a number
---@param number number
---@param bit number
---@return boolean
function SelectBitBool(number, bit)
    local power = powersOf2[bit]
    return MathMod(number, power) <= power * 0.5
end

--- Gets the bits of the number. Note that the array is zero-indexed.
---@param number number
---@return number[]
function GetBits(number)
    local MathMod = MathMod
    local pos = 0
    local bits = {}
    while number > 0 do
        local bit = MathMod(number, 2)
        bits[pos] = bit
        pos = pos + 1
        number = (number - bit) * 0.5
    end
    return bits
end

-- Function originally created to check if a Mass Storage can be queued in a location without overlapping
function CanBuildInSpot(originUnit, unitId, pos)
    local bp = __blueprints[unitId]
    local mySkirtX = bp.Physics.SkirtSizeX / 2
    local mySkirtZ = bp.Physics.SkirtSizeZ / 2

    -- Find the distance between my skirt and the skirt of a potential Quantum Gateway
    local xDiff = mySkirtX + 5 -- Using 5 because that's half the size of a Quantum Gateway, the largest stock structure
    local zDiff = mySkirtZ + 5

    -- Full extent of search rectangle
    local x1 = pos.x - xDiff
    local z1 = pos.z - zDiff
    local x2 = pos.x + xDiff
    local z2 = pos.z + zDiff

    -- Find all the units in that rectangle
    local units = GetUnitsInRect(x1, z1, x2, z2)

    -- Filter it down to structures and experimentals only
    units = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, units)

    -- Bail if there's nothing in range
    if not units[1] then return false end

    for _, struct in units do
        if struct ~= originUnit then
            local structPhysics = struct:GetBlueprint().Physics
            local structPos = struct:GetPosition()

            -- These can be positive or negative, so we need to make them positive using math.abs
            local xDist = math.abs(pos.x - structPos.x)
            local zDist = math.abs(pos.z - structPos.z)

            local skirtDiffx = mySkirtX + (structPhysics.SkirtSizeX / 2)
            local skirtDiffz = mySkirtZ + (structPhysics.SkirtSizeZ / 2)

            -- Check if the axis difference is smaller than the combined skirt distance
            -- If it is, we overlap, and can't build here
            if xDist < skirtDiffx and zDist < skirtDiffz then
                return false
            end
        end
    end

    return true
end

-- Note: Includes allied units in selection!!
function GetEnemyUnitsInSphere(unit, position, radius)
    local x1 = position.x - radius
    local y1 = position.y - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local y2 = position.y + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(x1, z1, x2, z2)

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    for _, v in UnitsinRec do
        local dist = VDist3(position, v:GetPosition())
        if unit.Army ~= v.Army and dist <= radius then
            table.insert(RadEntities, v)
        end
    end

    return RadEntities
end

-- This function is like the one above, but filters out Allied units
function GetTrueEnemyUnitsInSphere(unit, position, radius, categories)
    local x1 = position.x - radius
    local y1 = position.y - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local y2 = position.y + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(x1, z1, x2, z2)

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    for _, v in UnitsinRec do
        local dist = VDist3(position, v:GetPosition())
        local vArmy = v.Army
        if unit.Army ~= vArmy and not IsAlly(unit.Army, vArmy) and dist <= radius and EntityCategoryContains(categories or categories.ALLUNITS, v) then
            table.insert(RadEntities, v)
        end
    end

    return RadEntities
end

function GetDistanceBetweenTwoPoints(x1, y1, z1, x2, y2, z2)
    local dx = (x1-x2)
    local dy = (y1-y2)
    local dz = (z1-z2)
    return (math.sqrt(dx * dx + dy * dy + dz * dz))
end

function GetDistanceBetweenTwoVectors(v1, v2)
    return VDist3(v1, v2)
end

function XZDistanceTwoVectors(v1, v2)
    return VDist2(v1[1], v1[3], v2[1], v2[3])
end

function GetVectorLength(v)
    return math.sqrt(math.pow(v.x, 2) + math.pow(v.y, 2) + math.pow(v.z, 2))
end

function NormalizeVector(v)
    local length = GetVectorLength(v)
    if length > 0 then
        local invlength = 1 / length
        return Vector(v.x * invlength, v.y * invlength, v.z * invlength)
    else
        return Vector(0,0,0)
    end
end

function GetDifferenceVector(v1, v2)
    return Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
end

function GetDirectionVector(v1, v2)
    return NormalizeVector(Vector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z))
end

function GetScaledDirectionVector(v1, v2, scale)
    local vec = GetDirectionVector(v1, v2)
    return Vector(vec.x * scale, vec.y * scale, vec.z * scale)
end

function GetMidPoint(v1, v2)
    return Vector((v1.x + v2.x) * 0.5, (v1.y + v2.y) * 0.5, (v1.z + v2.z) * 0.5)
end

function GetRandomFloat(nmin, nmax)
    return Random() * (nmax - nmin) + nmin
end

function GetRandomInt(nmin, nmax)
    return Random(nmin, nmax)
end

function GetRandomOffset(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = Random() * sx - (sx * 0.5)
    local y = Random() * sy - (sy * 0.5)
    local z = Random() * sz - (sz * 0.5)

    return x, y, z
end

function GetRandomOffset2(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = (Random() * 2 - 1) * sx - (sx * 0.5)
    local y = (Random() * 2 - 1) * sy
    local z = (Random() * 2 - 1) * sz - (sz * 0.5)

    return x, y, z
end

function GetClosestVector(vFrom, vToList)
    local dist, cDist, retVec = 0
    if vToList then
        dist = GetDistanceBetweenTwoVectors(vFrom, vToList[1])
        retVec = vToList[1]
    end

    for kTo, vTo in vToList do
        cDist = GetDistanceBetweenTwoVectors(vFrom, vTo)
        if dist > cDist then
            dist = cDist
            retVec = vTo
        end
    end

    return retVec
end

function Cross(v1, v2)
    return Vector((v1.y * v2.z) - (v1.z * v2.y), (v1.z * v2.x) - (v1.x * v2.z), (v1.x * v2.y) - (v1.y - v2.x))
end

function DotP(v1, v2)
    return (v1.x * v2.x) + (v1.y * v2.y) + (v1.z * v2.z)
end

function GetAngleInBetween(v1, v2)
    -- Normalize the vectors
    local vec1 = {}
    local vec2 = {}
    vec1 = NormalizeVector(v1)
    vec2 = NormalizeVector(v2)
    local dotp = DotP(vec1, vec2)

    return math.acos(dotp) * (360 / (math.pi * 2))
end

--- Computes the full angle between the two vectors in two dimensions: the y dimension is not taken into account. Angle
-- is computed in a counter clockwise direction: if the base is to the south ({0, 0, 1}) then the direction to the east ({1, 0, 0}) is 90 degrees.
-- @param base The base direction from which the angle will be computed in a counter clockwise fashion.
-- @param direction The direction from which we want to compute the angle given a base.
function GetAngleCCW(base, direction)

    local bn = NormalizeVector(base)
    local dn = NormalizeVector(direction)

    -- compute the orthogonal vector to determine if we need to take the inverse
    local ort = { bn[3], 0, -bn[1] }

    -- compute the radians, correct it accordingly
    local rads = math.acos(bn[1] * dn[1] + bn[3] * dn[3])
    if ort[1] * dn[1] + ort[3] * dn[3] < 0 then
        rads = 2 * math.pi - rads
    end

    -- convert to degrees
    return (180 / math.pi) * rads
end

function UserConRequest(string)
    if not Sync.UserConRequests then
        Sync.UserConRequests = {}
    end
    table.insert(Sync.UserConRequests, string)
end

-----------------------------------------------------------------
-- TableCat - Concatenates multiple tables into one single table
-----------------------------------------------------------------
function TableCat(...)
    local ret = {}
    for index = 1, table.getn(arg) do
        if arg[index] ~= nil then
            for k, v in arg[index] do
                table.insert(ret, v)
            end
        end
    end

    return ret
end
