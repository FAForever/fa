--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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


local UserDecal = import("/lua/user/userdecal.lua").UserDecal
local CreateChunkTemplate = import("/lua/shared/aichunktemplates.lua").CreateChunkTemplate
local VerifyChunkTemplate = import("/lua/shared/aichunktemplates.lua").VerifyChunkTemplate
local StringifyChunkTemplate = import("/lua/shared/aichunktemplates.lua").StringifyChunkTemplate

---@param size number
function PopulateChunkTemplate (size)
    -- sanity check
    local template = CreateChunkTemplate(size, 'UEF')
    if not template then
        return
    end

    -- sanity check
    local selection = GetSelectedUnits()
    if not selection or table.empty(selection) then
        return
    end

    local buildAreas = template.BuildAreas

    -- for debugging
    local decals = { }
    ForkThread(
        function()
            WaitSeconds(10)
            for k, v in decals do
                v:Destroy()
            end
        end
    )

    local c = table.getn(selection)
    local cx, cz = 0, 0
    for k = 1, c do
        -- compute center
        local unit = selection[k]
        local position = unit:GetPosition()
        cx = cx + position[1]
        cz = cz + position[3]

        -- determine skirt size
        local blueprint = unit:GetBlueprint()

        ---@type string | number
        -- local id = "Walls"
        -- if not EntityCategoryContains(categories.WALL, unit) then
            id = math.min(math.max(blueprint.Physics.SkirtSizeX, blueprint.Physics.SkirtSizeZ), 16)
        -- end

        table.insert(buildAreas[id], unit)
    end

    cx = math.floor((cx / c) / size) * size + 0.5 * size
    cz = math.floor((cz / c) / size) * size + 0.5 * size

    for k = 1, table.getn(buildAreas) do
        local buildOffsets = buildAreas[k]
        for u = 1, table.getn(buildOffsets) do
            local unit = buildOffsets[u] --[[@as UserUnit]]
            local position = unit:GetPosition()
            buildOffsets[u] = {
                position[1] - cx,
                position[3] - cz
            }
        end
    end

    --#region debugging

    local decal = UserDecal()
    decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/nuke_icon_inner.dds")
    decal:SetScale({ 20, 1, 20 })
    decal:SetPosition({cx, 0, cz})
    table.insert(decals, decal)

    for k = 1, table.getn(buildAreas) do
        local buildOffsets = buildAreas[k]
        for u = 1, table.getn(buildOffsets) do
            local offset = buildOffsets[u]

            local decal = UserDecal()
            decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/nuke_icon_inner.dds")
            decal:SetScale({ 1, 1, 1 })
            decal:SetPosition({ cx + offset[1], 0, cz + offset[2] })
            table.insert(decals, decal)
        end
    end

    --#endregion

    LOG(StringifyChunkTemplate(template))
    VerifyChunkTemplate(template)

    return template
end