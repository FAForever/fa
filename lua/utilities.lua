-----------------------------------------------------------------
-- File     :  /lua/utilities.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Utility functions for scripts.
-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

function GetDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3(entity1:GetPosition(),entity2:GetPosition())
end

-- Note: Includes allied units in selection!!
function GetEnemyUnitsInSphere(unit, position, radius)
    local x1 = position.x - radius
    local y1 = position.y - radius
    local z1 = position.z - radius
    local x2 = position.x + radius
    local y2 = position.y + radius
    local z2 = position.z + radius
    local UnitsinRec = GetUnitsInRect(Rect(x1, z1, x2, z2))

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    for _, v in UnitsinRec do
        local dist = VDist3(position, v:GetPosition())
        if unit:GetArmy() ~= v:GetArmy() and dist <= radius then
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
    local UnitsinRec = GetUnitsInRect(Rect(x1, z1, x2, z2))

    -- Check for empty rectangle
    if not UnitsinRec then
        return UnitsinRec
    end

    local RadEntities = {}
    local unitArmy = unit:GetArmy()
    for _, v in UnitsinRec do
        local dist = VDist3(position, v:GetPosition())
        local vArmy = v:GetArmy()
        if unitArmy ~= vArmy and not IsAlly(unitArmy, vArmy) and dist <= radius and EntityCategoryContains(categories or categories.ALLUNITS, v) then
            table.insert(RadEntities, v)
        end
    end

    return RadEntities
end

function GetDistanceBetweenTwoPoints(x1, y1, z1, x2, y2, z2)
    return (math.sqrt((x1-x2)^2 + (y1-y2)^2 + (z1-z2)^2))
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
    return (Random() * (nmax - nmin) + nmin)
end

function GetRandomInt(nmin, nmax)
    return math.floor(Random() * (nmax - nmin + 1) + nmin)
end

function GetRandomOffset(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = Random() * sx - (sx * 0.5)
    local y = Random() * sy
    local z = Random() * sz - (sz * 0.5)

    return x, y, z
end

function GetRandomOffset2(sx, sy, sz, scalar)
    sx = sx * scalar
    sy = sy * scalar
    sz = sz * scalar
    local x = Random(-1.0, 1.0) * sx - (sx * 0.5)
    local y = Random(-1.0, 1.0) * sy
    local z = Random(-1.0, 1.0) * sz - (sz * 0.5)

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
