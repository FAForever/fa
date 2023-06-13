-----------------------------------------------------------------
-- File     :  /lua/utilities.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Utility functions for scripts.
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local MathCos = math.cos
local MathMod = math.mod
local MathSin = math.sin
local MathSqrt = math.sqrt

function GetDistanceBetweenTwoEntities(entity1, entity2)
    local pos1, pos2 = entity1:GetPosition(), entity2:GetPosition()
    local dx, dy, dz = pos2[1] - pos1[1], pos2[2] - pos1[2], pos2[3] - pos1[3]
    return MathSqrt(dx*dx + dy*dy + dz*dz)
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
---@param originUnit Unit
---@param unitId UnitId
---@param pos Vector
---@return boolean
function CanBuildInSpot(originUnit, unitId, pos)
    local posX, posZ = pos[1], pos[3]
    local bpPhysics = __blueprints[unitId].Physics
    local mySkirtX = bpPhysics.SkirtSizeX / 2
    local mySkirtZ = bpPhysics.SkirtSizeZ / 2

    -- Find the distance between my skirt and the skirt of a potential Quantum Gateway
     -- Using 5 because that's half the size of a Quantum Gateway, the largest stock structure
    local xDiff = mySkirtX + 5
    local zDiff = mySkirtZ + 5

    -- Full extent of search rectangle
    local x1 = posX - xDiff
    local z1 = posZ - zDiff
    local x2 = posX + xDiff
    local z2 = posZ + zDiff

    -- Find all the units in that rectangle
    local units = GetUnitsInRect(x1, z1, x2, z2)
    if not units then
        return false
    end

    -- Filter it down to structures and experimentals only
    units = EntityCategoryFilterDown(categories.STRUCTURE + categories.EXPERIMENTAL, units)

    -- Bail if there's nothing in range
    if not units[1] then
        return false
    end

    for _, struct in units do
        if struct == originUnit then
            continue
        end
        local structPhysics = struct:GetBlueprint().Physics
        local structPos = struct:GetPosition()

        -- These can be positive or negative, so we need to make them positive using math.abs
        local xDist = math.abs(posX - structPos[1])
        local zDist = math.abs(posZ - structPos[3])

        local skirtDiffx = mySkirtX + structPhysics.SkirtSizeX * 0.5
        local skirtDiffz = mySkirtZ + structPhysics.SkirtSizeZ * 0.5

        -- Check if the axis difference is smaller than the combined skirt distance
        -- If it is, we overlap, and can't build here
        if xDist < skirtDiffx and zDist < skirtDiffz then
            return false
        end
    end

    return true
end

--- Gets all units in a sphere that have a different army from a given unit. Note that, despite the
--- name, this also includes ally and civilian units.
---@see GetTrueEnemyUnitsInSphere(unit, position, radius, categories) # to truly only get enemy units
---@param unit Unit
---@param position Vector
---@param radius number
---@return Unit[] | nil
function GetEnemyUnitsInSphere(unit, position, radius)
    local posX, posZ = position[1], position[3]
    local unitsInRec = GetUnitsInRect(posX - radius, posZ - radius, posX + radius, posZ + radius)
    -- Check for empty rectangle
    if not unitsInRec then
        return unitsInRec
    end

    local posY = position[2]
    local army = unit.Army
    local radiusSq = radius*radius
    local k = 1
    local unitsInRadius = {}
    for _, v in unitsInRec do
        if army ~= v.Army then
            continue
        end
        local vPos = v:GetPosition()
        local dx, dy, dz = posX - vPos[1], posY - vPos[2], posZ - vPos[3]
        if dx*dx + dy*dy + dz*dz <= radiusSq then
            unitsInRadius[k] = v
            k = k + 1
        end
    end

    return unitsInRadius
end

--- Gets all units in a sphere that are an enemy to a given unit and contained in a category.
---@param unit Unit
---@param position Vector
---@param radius number
---@param categories? EntityCategory
---@return Unit[] | nil
function GetTrueEnemyUnitsInSphere(unit, position, radius, categories)
    local posX, posZ = position[1], position[3]
    local unitsInRec = GetUnitsInRect(posX - radius, posZ - radius, posX + radius, posZ + radius)
    -- Check for empty rectangle
    if not unitsInRec then
        return unitsInRec
    end

    local posY = position[2]
    local army = unit.Army
    local radiusSq = radius*radius
    local k = 1
    local unitsInRadius = {}
    for _, v in unitsInRec do
        local vArmy = v.Army
        if army ~= v.Army or IsAlly(army, vArmy) then
            continue
        end
        local vPos = v:GetPosition()
        local dx, dy, dz = posX - vPos[1], posY - vPos[2], posZ - vPos[3]
        if dx*dx + dy*dy + dz*dz <= radiusSq and categories and EntityCategoryContains(categories, v) then
            unitsInRadius[k] = v
            k = k + 1
        end
    end

    return unitsInRadius
end

---@see VDist2(x1, z1, x2, z2) # for a 2D option
---@see VDist3(v1, v2) # for a vector option
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function GetDistanceBetweenTwoPoints(x1, y1, z1, x2, y2, z2)
    local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
    return MathSqrt(dx*dx + dy*dy + dz*dz)
end

GetDistanceBetweenTwoVectors = VDist3

--- Returns the horizontal distance between two vectors without considering the y-axis
---@see VDist(v1, v2) # for 3D option
---@param v1 Vector
---@param v2 Vector
---@return number
function XZDistanceTwoVectors(v1, v2)
    local dx, dz = v2[1] - v1[1], v2[3] - v1[3]
    return MathSqrt(dx*dx + dz*dz)
end

--- Returns the vector length
---@param v Vector
---@return number
function GetVectorLength(v)
    local x, y, z = v[1], v[2], v[3]
    return MathSqrt(x*x + y*y + z*z)
end

--- Returns the vector with the same direction, but unit length. The zero-vector returns itself.
---@param v Vector
---@return Vector
function NormalizeVector(v)
    local length = GetVectorLength(v)
    if length > 0 then
        local invlength = 1 / length
        return Vector(v[1] * invlength, v[2] * invlength, v[3] * invlength)
    else
        return Vector(0, 0, 0)
    end
end

GetDifferenceVector = VDiff

--- Gets the direction vector from `v1` to `v2`
---@see GetScaledDirectionVector(v1, v2, len) # for a vector given length
---@param v1 Vector
---@param v2 Vector
---@return Vector
function GetDirectionVector(v1, v2)
    return NormalizeVector(Vector(v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]))
end

--- Gets the vector `v1` to `v2` with a certain length
---@see GetDirectionVector(v1, v2) # for unit length
---@param v1 Vector
---@param v2 Vector
---@param len number
---@return Vector
function GetScaledDirectionVector(v1, v2, len)
    local vec = GetDirectionVector(v1, v2)
    return Vector(vec[1] * len, vec[2] * len, vec[3] * len)
end

--- Gets the vector halfway between `v1` and `v2`
---@param v1 Vector
---@param v2 Vector
---@return Vector
function GetMidPoint(v1, v2)
    return Vector((v1[1] + v2[1]) * 0.5, (v1[2] + v2[2]) * 0.5, (v1[3] + v2[3]) * 0.5)
end

--- Gets a random float between `nmin` and `nmax`
---@param nmin number
---@param nmax number
---@return number
function GetRandomFloat(nmin, nmax)
    return Random() * (nmax - nmin) + nmin
end

GetRandomInt = Random

--- Returns a random offset given size variables where each component is in the range `[-v/2, v/2)`,
--- multiplied by the scalar.
---@param sx number
---@param sy number
---@param sz number
---@param scalar number
---@return number xOffset
---@return number yOffset
---@return number zOffset
function GetRandomOffset(sx, sy, sz, scalar)
    local x = scalar * sx * (Random() - 0.5)
    local y = scalar * sy * (Random() - 0.5)
    local z = scalar * sz * (Random() - 0.5)
    return x, y, z
end

--- Returns a random offset given bounds where the X and Z components are in the range
--- `[-1.5*v, 0.5*v)`, and Y is in `[-v, v)`. Everything is multiplied by the scalar multiplied by
--- the scalar.
---@see GetRandomOffset(sx, sy, sz, scalar) # for a size version
---@param sx number
---@param sy number
---@param sz number
---@param scalar number
---@return number xOffset
---@return number yOffset
---@return number zOffset
function GetRandomOffset2(sx, sy, sz, scalar)
    local x = scalar * sx * (Random() * 2 - 1.5)
    local y = scalar * sy * (Random() * 2 - 1)
    local z = scalar * sz * (Random() * 2 - 1.5)
    return x, y, z
end


--- Returns the vector from a list that is closest to a given vector. Returns nil if empty.
---@param from Vector
---@param list? Vector[]
---@return Vector | nil
function GetClosestVector(from, list)
    if not list or not list[1] then
        return nil
    end
    local closest = list[1]
    local closestDist = GetDistanceBetweenTwoVectors(from, closest)
    for _, vec in list do
        local dist = GetDistanceBetweenTwoVectors(from, vec)
        if dist < closestDist then
            closestDist = dist
            closest = vec
        end
    end
    return closest
end

--- Returns the cross product of `a` across `b`
---@param a Vector
---@param b Vector
---@return Vector
function Cross(a, b)
    local ax, ay, az = a[1], a[2], a[3]
    local bx, by, bz = b[1], b[2], b[3]
    return Vector(
        ay * bz - az * by,
        az * bx - ax * bz,
        ax * by - ay * bx
    )
end

DotP = VDot

--- Gets the angle between two vectors in degrees
---@param a Vector
---@param b Vector
---@return number
function GetAngleInBetween(a, b)
    local ax, ay, az = a[1], a[2], a[3]
    local bx, by, bz = b[1], b[2], b[3]
    -- arccos((a . b) / (|a| |b|))
    local dot = ax*bx + ay*by + az*bz
    local len2 = MathSqrt((ax*ax + ay*ay + az*az) * (bx*bx + by*by + bz*bz))
    return math.acos(dot / len2) * 180 / math.pi
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

--- adds a string to `Sync.UserConRequests`
---@param string string
function UserConRequest(string)
    if not Sync.UserConRequests then
        Sync.UserConRequests = {}
    end
    table.insert(Sync.UserConRequests, string)
end


--- takes multiple tables and constructs a new table with all of the values in it
---@param ... table
---@return table
function TableCat(...)
    local ret = {}
    for index = 1, arg.n do
        if arg[index] ~= nil then
            for _, v in arg[index] do
                table.insert(ret, v)
            end
        end
    end
    return ret
end


---@overload fun(rotation: number): Quaternion
--- Creates a quaternion from an orientation axis and rotation angle. The orientation axis defaults
--- to up (the y-axis).
---@param rotation number
---@param x number
---@param y number
---@param z number
---@return Quaternion
function QuatFromRotation(rotation, x, y, z)
    local halfAngle = 0.00872664625997 * rotation -- math.rad(rotation / 2)
    local angleRot = MathSin(halfAngle)
    local qw = MathCos(halfAngle)
    if not x then
        return UnsafeQuaternion(0, angleRot, 0, qw)
    end
    local qx = x * angleRot
    local qy = y * angleRot
    local qz = z * angleRot
    return Quaternion(qx, qy, qz, qw)
end

--- Returns the orientation quaternion given an XZ direction
---@param dx number
---@param dz number
---@return Quaternion
function QuatFromXZDirection(dx, dz)
    -- ang = atan2(dx, dz) -- `dz` is adjacent
    -- {0, sin(ang/2), 0, cos(ang/2)}
    local hypot = MathSqrt(dx*dx + dz*dz)
    -- use the half-angle formulas
    local halfCosA = dz / (2 * hypot)
    local sinHalfA = MathSqrt(0.5 - halfCosA)
    local cosHalfA = MathSqrt(0.5 + halfCosA)
    return UnsafeQuaternion(0, sinHalfA, 0, cosHalfA)
end

--- Translates the XZ coordinates of a position by a length in a given quaternion orientation.
---@param pos Vector
---@param orientation Quaternion
---@param length number
function TranslateInXZDirection(pos, orientation, length)
    local qx, qy, qz, qw = orientation[1], orientation[2], orientation[3], orientation[4]
    local dirX = 2 * (qx * qz + qw * qy)
    local dirZ = qw*qw + qx*qx - qz*qz - qy*qy
    length = length / MathSqrt(dirX*dirX + dirZ*dirZ)
    return Vector(
        pos[1] + length * dirX,
        pos[2],
        pos[3] + length * dirZ
    )
end
