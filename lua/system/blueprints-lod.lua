---@declare-global
local MathSqrt = math.sqrt

--- Calculates the LODs of a single prop
---@param prop PropBlueprint to compute the LODs for
local function CalculateLODOfProp(prop)
    local sx = prop.SizeX or 1
    local sy = prop.SizeY or 1
    local sz = prop.SizeZ or 1

    -- give more emphasis to the x / z value as that is easier to see in the average camera angle
    local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz
    if prop.ScriptClass == 'Tree' or prop.ScriptClass == 'TreeGroup' then
        weighted = 3
    end

    -- 1 -> ~ 330
    -- 2 -> ~ 470
    -- 3 -> ~ 580
    -- 4 -> ~ 670
    -- 5 -> ~ 750
    -- 6 -> ~ 820
    -- https://www.desmos.com/calculator/amw5fi5569 (1.5 * sqrt(100 * 500 * x))
    local lod = 1.30 * MathSqrt(100 * 500 * weighted)

    if prop.Display and prop.Display.Mesh and prop.Display.Mesh.LODs then
        -- used for scaling the LODs
        local n = table.getn(prop.Display.Mesh.LODs)

        -- read LODs in order
        for k = 1, table.getn(prop.Display.Mesh.LODs) do 
            local data = prop.Display.Mesh.LODs[k]

            -- 1/1 -> 1/1
            -- 1/2 -> 1/4
            -- 1/3 -> 1/9
            -- 1/4 -> 1/16
            -- https://www.desmos.com/calculator/keue6viu3b (x * x)
            local factor = (k / n) * (k / n)

            -- if prop.ScriptClass and prop.ScriptClass == "TreeGroup" then 
            --     LOG("Mapping ( " .. tostring(weighted) .. "): " .. tostring(data.LODCutoff) .. " -> " .. tostring(factor * lod))
            -- end

            data.LODCutoff = factor * lod + 10
        end
    end
end

--- Calculates the LODs of a list of props
---@param props PropBlueprint[] list of props to tweak the LODs for
local function CalculateLODsOfProps(props)
    for _, prop in props do
        CalculateLODOfProp(prop)
    end
end

--- Calculates the LODs of all entities
---@param bps BlueprintsTable all available blueprints
function CalculateLODs(bps)
    CalculateLODsOfProps(bps.Prop)
end
