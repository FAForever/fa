local MathAtan2 = math.atan2
local MathDeg = math.deg
local GetTerrainHeight = GetTerrainHeight
local FlattenMapRect = FlattenMapRect

--- Compute two angles in radians to match the terrain gradient.
--- Copyright 2018-2022 Sean 'Balthazar' Wheeldon
---@param pos Vector
---@param sizeX number
---@param sizeZ number
---@return number angleX
---@return number angleZ
function GetTerrainSlopeAngles(pos, sizeX, sizeZ)
    local posX, posY, posZ = pos[1], pos[2], pos[3]
    local lenX, lenZ = sizeX * 0.5, sizeZ * 0.5

    -- Get angles, starting from the upper-left edges
    local angleX = MathAtan2(GetTerrainHeight(posX - lenX, posZ) - posY, lenX)
    local angleZ = MathAtan2(GetTerrainHeight(posX, posZ - lenZ) - posY, lenZ)

    -- If it has the other edges to sample, average those
    if sizeX >= 2 then
        local rightX = MathAtan2(GetTerrainHeight(posX + lenX, posZ) - posY, lenX)
        angleX = (angleX - rightX) * 0.5
    end
    if sizeZ >= 2 then
        local lowerZ = MathAtan2(GetTerrainHeight(posX, posZ + lenZ) - posY, lenZ)
        angleZ = (angleZ - lowerZ) * 0.5
    end

    return angleX, angleZ
end

--- Compute two angles in degrees to match the terrain gradient.
--- Copyright 2018-2022 Sean 'Balthazar' Wheeldon
---@param pos Vector Center of area
---@param sizeX number
---@param sizeZ number
---@return number angleX
---@return number angleZ
function GetTerrainSlopeAnglesDegrees(pos, sizeX, sizeZ)
    local angleX, angleZ = GetTerrainSlopeAngles(pos, sizeX, sizeZ)
    return MathDeg(angleX), MathDeg(angleZ)
end

--- Flattens the terrain by bilinearly interpolating between the rectangle.
--- Copyright 2018-2022 Sean 'Balthazar' Wheeldon
---@param x number Top-left coordinate
---@param z number Top-left coordinate
---@param w number
---@param h number
function FlattenGradientMapRect(x, z, w, h)
    local start, xHeight = GetTerrainHeight(x, z), GetTerrainHeight(x + w, z)
    local zHeight, corner = GetTerrainHeight(x, z + h), GetTerrainHeight(x + w, z + h)
    local xGrad = (xHeight - start) / w
    local zGrad = (zHeight - start) / h
    local diagGrad = (start + corner - xHeight - zHeight) / (w * h)
    for i = 0, w do
        for j = 0, h do
            FlattenMapRect(x + i, z + j, 0, 0, start + i*xGrad + j*zGrad + i*j*diagGrad)
        end
    end
end
