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

local TableGetn = table.getn
local TableEmpty = table.empty
local TableInsert = table.insert

local MathFloor = math.floor
local MathMin = math.min
local MathMax = math.max

local UserDecal = import("/lua/user/userdecal.lua").UserDecal
local CreateChunkTemplate = import("/lua/shared/aichunktemplates.lua").CreateChunkTemplate
local VerifyChunkTemplate = import("/lua/shared/aichunktemplates.lua").VerifyChunkTemplate
local StringifyChunkTemplate = import("/lua/shared/aichunktemplates.lua").StringifyChunkTemplate

--- Adds the given units to the given template.
---@param template AIChunkTemplate
---@param units UserUnit[]
---@param size number
---@return boolean
function AddToChunkTemplate(template, units, size)
    local buildAreas = template.BuildAreas

    -- compute the center
    local c = TableGetn(units)
    local cx, cz = 0, 0
    for k = 1, c do
        -- compute center
        local unit = units[k]
        local position = unit:GetPosition()
        cx = cx + position[1]
        cz = cz + position[3]

        -- determine skirt size
        local blueprint = unit:GetBlueprint()

        ---@type string | number
        -- local id = "Walls"
        -- if not EntityCategoryContains(categories.WALL, unit) then
        id = MathMin(MathMax(blueprint.Physics.SkirtSizeX, blueprint.Physics.SkirtSizeZ), 16)
        -- end

        TableInsert(buildAreas[id], unit)
    end

    cx = MathFloor((cx / c) / size) * size + 0.5 * size
    cz = MathFloor((cz / c) / size) * size + 0.5 * size

    for k = 1, TableGetn(buildAreas) do
        local buildOffsets = buildAreas[k]
        for u = 1, TableGetn(buildOffsets) do
            local unit = buildOffsets[u] --[[@as UserUnit]]
            local position = unit:GetPosition()
            buildOffsets[u] = {
                position[1] - cx,
                position[3] - cz
            }
        end
    end

    --#region debugging

    -- add a decal underneath each unit that we processed

    local decals = {}
    ForkThread(
        function()
            WaitSeconds(10)
            for k, v in decals do
                v:Destroy()
            end
        end
    )

    local decal = UserDecal()
    decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/nuke_icon_inner.dds")
    decal:SetScale({ 20, 1, 20 })
    decal:SetPosition({ cx, 0, cz })
    TableInsert(decals, decal)

    for k = 1, TableGetn(buildAreas) do
        local buildOffsets = buildAreas[k]
        for u = 1, TableGetn(buildOffsets) do
            local offset = buildOffsets[u]

            local decal = UserDecal()
            decal:SetTexture("/textures/ui/common/game/AreaTargetDecal/nuke_icon_inner.dds")
            decal:SetScale({ 1, 1, 1 })
            decal:SetPosition({ cx + offset[1], 0, cz + offset[2] })
            TableInsert(decals, decal)
        end
    end

    --#endregion

    if not VerifyChunkTemplate(template) then
        print("Unable to create a valid chunk template")
        return false
    end

    return true
end

--- Creates a new chunk template and populates it with the unit selection.
---@param size number
---@return AIChunkTemplate?
function AddUnitSelectionToEmptyChunkTemplate(size)
    -- sanity check
    local template = CreateChunkTemplate(size, 'UEF')
    if not template then
        print("Unable to create a new chunk template")
        return
    end

    -- sanity check
    local selection = GetSelectedUnits()
    if not selection or TableEmpty(selection) then
        print("Unable to populate a new chunk template with no unit selection")
        return
    end

    -- populate the template
    local ok = AddToChunkTemplate(template, selection, size)
    if not ok then
        print("Unable to populate a new chunk template with the given unit selection")
        return
    end

    -- copy the template to the clipboard
    CopyToClipboard(StringifyChunkTemplate(template))
    print("Template copied to clipboard")
end
