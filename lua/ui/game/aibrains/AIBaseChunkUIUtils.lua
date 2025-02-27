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

local TableEmpty = table.empty

local CreateBaseChunk = import("/lua/shared/AIBrain/AIBaseChunkSharedUtils.lua").CreateBaseChunk
local VerifyBaseChunk = import("/lua/shared/AIBrain/AIBaseChunkSharedUtils.lua").VerifyBaseChunk
local StringifyBaseChunk = import("/lua/shared/AIBrain/AIBaseChunkSharedUtils.lua").StringifyBaseChunk

--- Converts a building site to a template building used in user templates.
---@param buildingSite AIBaseChunkBuildingSite
---@return UIBuildTemplateBuilding
function BuildingSiteToUserTemplateEntry(buildingSite, index)
    ---@type UIBuildTemplateBuilding
    return {
        EntityCategoryGetUnitList(categories.UEF * categories.STRUCTURE * buildingSite.TypePreference * buildingSite.TechPreference)[1],
        index,
        buildingSite.OffsetX,
        buildingSite.OffsetZ
    }
end

--- Converts a base chunk to a user template.
---@param chunk AIBaseChunk
---@return UIBuildTemplate
function BaseChunkToUserTemplate(chunk)
    ---@type UIBuildTemplateBuilding[]
    local userTemplate = {
        chunk.Size,
        chunk.Size,
    }
    for k, buildingSite in chunk.BuildingSites do
        table.insert(userTemplate, BuildingSiteToUserTemplateEntry(buildingSite, k))
    end

    ---@type UIBuildTemplate
    return userTemplate
end

--- Creates a base chunk from the unit selection.
---@param size number
---@return AIBaseChunk?
function CreateBaseChunkFromUnitSelection(size)

    -- sanity check
    local selection = GetSelectedUnits()
    if not selection or TableEmpty(selection) then
        print("Unable to populate a new chunk template with no unit selection")
        return
    end

    -- create the template
    local template, err = CreateBaseChunk(selection, size)
    if not template then
        print("Unable to populate a new chunk template with the given unit selection: " .. err)
        return
    end

    -- verify the template
    local ok, err = VerifyBaseChunk(template)
    if not ok then
        print("Failed to generate a valid base chunk from the given unit selection: " .. err)
        return
    end

    -- copy the template to the clipboard
    CopyToClipboard(StringifyBaseChunk(template))
    print("Template copied to clipboard")

    -- makes it easier to understand what it turns out to be
    local userTemplate = BaseChunkToUserTemplate(template)
    SetActiveBuildTemplate(userTemplate)
    import("/lua/ui/game/commandmode.lua").StartCommandMode('build', { name = userTemplate[3][1] })

    return template
end