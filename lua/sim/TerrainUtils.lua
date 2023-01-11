
local GetTerrainHeight = GetTerrainHeight
local type = type

local MathMax = math.max
local MathAtan = math.atan
local MathDeg = math.deg

local CacheBox = { 0, 0 }
local CacheAngles = { 0, 0, 0, 0 }
local CacheHeights = { 0, 0, 0, 0 }

function GetTerrainSlopeAngles(pos, bx, bz, sx, sz)

    local box = CacheBox
    box[1], box[2] = 0.5 * bx, 0.5 * bz

    --Get heights
    local heights = CacheHeights
    heights[1] = GetTerrainHeight(pos[1]-box[1],pos[3])
    heights[2] = GetTerrainHeight(pos[1],pos[3]-box[2])

    --Get averages if its 2 squares or bigger, bearing in mind the number was halved.
    local requireFourPoints = MathMax(box[1],box[2]) >= 1
    if requireFourPoints then
        heights[3] = GetTerrainHeight(pos[1]+box[1],pos[3])
        heights[4] = GetTerrainHeight(pos[1],pos[3]+box[2])
    end

    --Subtract center height
    for i, v in heights do
        heights[i] = v - pos[2]
    end

    --Calculate angles
    local angles = CacheAngles
    for i, v in heights do
        angles[i] = MathAtan(heights[i] / box[math.mod(i-1,2)+1])
    end

    --Condence down to average if they were calculated
    if requireFourPoints then
        return 0.5 * (angles[1]-angles[3]), 0.5 * (angles[2]-angles[4])
    else
        return angles[1], angles[2]
    end
end

function GetTerrainSlopeAnglesDegrees(pos, bx, bz, sx, sz)
    local az, ax = GetTerrainSlopeAngles(pos, bx, bz, sx, sz)
    return -1 * MathDeg(az), MathDeg(ax)
end