---@declare-global
local MathSqrt = math.sqrt

---@param unit UnitBlueprint
local function CalculateLODOfUnit(unit)
    local sx = unit.Physics.SkirtSizeX or unit.SizeX or 1
    local sy = unit.SizeY or 1
    local sz = unit.Physics.SkirtSizeZ or unit.SizeZ or 1

    -- give more emphasis to the x / z value as that is easier to see in the average camera angle
    local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz

    -- https://www.desmos.com/calculator (0.7 * sqrt(100 * 500 * x))
    local lod = 0.7 * MathSqrt(100 * 500 * weighted)

    if unit.Display and unit.Display.Mesh and unit.Display.Mesh.LODs then
        local n = table.getn(unit.Display.Mesh.LODs)
        for k = 1, n do
            local data = unit.Display.Mesh.LODs[k]

            -- slight offset to give more preference to LOD0
            local lk = k + 1
            local ln = n + 1

            -- https://www.desmos.com/calculator (x * x)
            local factor = (lk / ln) * (lk / ln)
            local LODCutoff = factor * lod + 40
            -- LOG(string.format("(%s) / %d: %d -> %d", unit.BlueprintId, k, data.LODCutoff, LODCutoff))
            data.LODCutoff = LODCutoff
        end
    end
end

---@param units UnitBlueprint[]
local function CalculateLODsOfUnits(units)
    for _, unit in units do
        CalculateLODOfUnit(unit)
    end
end

---@param bps BlueprintsTable
function CalculateLODs(bps)
    CalculateLODsOfUnits(bps.Unit)
end
