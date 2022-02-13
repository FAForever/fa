
local MathSqrt = math.sqrt

local LODFactors = {
    [1] = { 1.0 },
    [2] = { 0.3, 1.0 },
    [3] = { 0.1, 0.3, 1.0 },
    [4] = { 0.1, 0.3, 0.6, 1.0 },
}

local function CalculateLODOfProp(prop)
    local sx = prop.SizeX or 1 
    local sy = prop.SizeY or 1
    local sz = prop.SizeZ or 1

    -- give more emphasis to the x / z value as that is easier to see in the average camera angle
    local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz 

    -- https://www.desmos.com/calculator/amw5fi5569
    -- 1 -> ~ 330
    -- 2 -> ~ 470
    -- 3 -> ~ 580
    -- 4 -> ~ 670
    -- 5 -> ~ 750
    -- 6 -> ~ 820
    local lod = 1.5 * MathSqrt(100 * 500 * weighted)
    
    if prop.Display and prop.Display.Mesh and prop.Display.Mesh.LODs then

        local factors = LODFactors[table.getn(prop.Display.Mesh.LODs)]

        -- find order of LODs 
        for k = 1, table.getn(prop.Display.Mesh.LODs) do 
            local data = prop.Display.Mesh.LODs[k]

            -- if prop.ScriptClass and prop.ScriptClass == "TreeGroup" then 
            --     LOG("Mapping ( " .. tostring(weighted) .. "): " .. tostring(data.LODCutoff) .. " -> " .. tostring(factors[k] * lod))
            -- end

            data.LODCutoff = factors[k] * lod 
        end
    end
end

local function CalculateLODsOfProps(props)
    for k, prop in props do 
        CalculateLODOfProp(prop)
    end
end

function CalculateLODs(bps)
    CalculateLODsOfProps(bps.Prop)
end
