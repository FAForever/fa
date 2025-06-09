--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

-- upvalue for performance
local pairs = pairs

local TableInsert = table.insert
local TableFind = table.find
local TableGetn = table.getn

local MathFloor = math.floor
local MathSqrt = math.sqrt
local MathMax = math.max

--- Feature: quick access to (individual) categories
---
---@param prop PropBlueprint
local function ProcessCategories(prop)
    prop.Categories = prop.Categories or {}

    prop.CategoriesHash = {}
    for k, category in pairs(prop.Categories) do
        prop.CategoriesHash[category] = true
    end
end

--- Feature: ability to (not) build on top of props
---
--- A little bit of an odd hack to guarantee wrecks block construction sites. The file that wrecks use is here:
--- - /props/DefaultWreckage/DefaultWreckage_prop.bp
---
--- But we do not distribute the `props` folder, which means that everything that is in there is ignored in production
--- therefore we try and catch all wreck related props here
---
--- See also:
--- - https://github.com/FAForever/fa/pull/5266
--- - https://github.com/FAForever/FA-Binary-Patches/pull/16
---@param prop PropBlueprint
local function ProcessObstructions(prop)
    if prop.ScriptClass == "Wreckage" and prop.ScriptModule == '/lua/wreckage.lua' then
        TableInsert(prop.Categories, 'OBSTRUCTSBUILDING')
    end

    local isObstructing = TableFind(prop.Categories, 'OBSTRUCTSBUILDING')
    local isReclaimable = TableFind(prop.Categories, 'OBSTRUCTSBUILDING')

    -- check for props that should block pathing
    if not (prop.ScriptClass == "Tree" or prop.ScriptClass == "TreeGroup") and isReclaimable then
        if prop.Economy and prop.Economy.ReclaimMassMax and prop.Economy.ReclaimMassMax > 0 and
            not isObstructing then
            if not isObstructing then
                WARN("Prop is missing 'OBSTRUCTSBUILDING' category: " .. prop.BlueprintId)
            end
        end
    end
end

--- Feature: indestructible props
---
---@param prop PropBlueprint
local function ProcessInvulnerability(prop)
    local isInvulnerable = TableFind(prop.Categories, 'INVULNERABLE')
    -- make invulnerable props actually invulnerable
    if prop.Categories then
        if isInvulnerable then
            prop.ScriptClass = 'PropInvulnerable'
            prop.ScriptModule = '/lua/sim/prop.lua'
        end
    end
end

--- Feature: health value based on mass value
---
---@param prop PropBlueprint
local function ProcessHealth(prop)
    local massValue = prop.Economy.ReclaimMassMax or 0
    local healthValue = MathMax(50, 2 * massValue)

    prop.Defense = prop.Defense or {}
    prop.Defense.Health = healthValue
    prop.Defense.MaxHealth = healthValue
end

--- Feature: LOD based on the size of the prop
---
--- See also:
--- - https://github.com/FAForever/fa/pull/3662
--- - https://github.com/FAForever/fa/pull/4675
---@param prop PropBlueprint
local function ProcessLOD(prop)

    local sx = prop.SizeX or 1
    local sy = prop.SizeY or 1
    local sz = prop.SizeZ or 1

    -- give more emphasis to the x / z value as that is easier to see in the average camera angle
    local weighted = 0.40 * sx + 0.2 * sy + 0.4 * sz
    if prop.ScriptClass == 'Tree' or prop.ScriptClass == 'TreeGroup' then
        weighted = 2.6
    end

    -- https://www.desmos.com/calculator (0.9 * sqrt(100 * 500 * x))
    local lod = 0.9 * MathSqrt(100 * 500 * weighted)

    if prop.Display and prop.Display.Mesh and prop.Display.Mesh.LODs then
        local n = TableGetn(prop.Display.Mesh.LODs)
        for k = 1, n do
            local data = prop.Display.Mesh.LODs[k]

            -- https://www.desmos.com/calculator (x * x)
            local factor = (k / n) * (k / n)
            local LODCutoff = factor * lod

            -- sanitize the value
            data.LODCutoff = MathFloor(LODCutoff / 10 + 1) * 10
        end
    end
end

--- Post-processes all props
---@param props PropBlueprint[]
function PostProcessProps(props)
    for _, prop in pairs(props) do
        ProcessInvulnerability(prop)
        ProcessObstructions(prop)
        ProcessHealth(prop)
        ProcessLOD(prop)
        ProcessCategories(prop)
    end
end

--- Post-processing that is used by the bake workflow. All changes are baked into the blueprints. For more information, see the following file:
--- - .github\workflows\bake-blueprints.yaml
---@param blueprints BlueprintsTable
function BakePropBlueprints(blueprints)
    if blueprints.Prop then
        for _, prop in pairs(blueprints.Prop) do
            ProcessInvulnerability(prop)
            ProcessObstructions(prop)
            ProcessHealth(prop)
            ProcessLOD(prop)
        end
    end
end
