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

---@alias ChunkLayers "Land" | "Naval"

---@class AIChunkBuildingSite
---@field OffsetX number                    # X offset in world coordinates
---@field OffsetZ number                    # Z offset in world coordinates
---@field Size number                       # Size in world coordinates of the site
---@field CategoryPreference EntityCategory # Preferred unit category for this site

---@class AIChunkTemplate
---@field Size number                       # Size in world coordinates
---@field Layer ChunkLayers                 # Intended build layer of the chunk
---@field BuildingSites AIChunkBuildingSite[]  # Building sites of the chunk

local TableGetn = table.getn
local TableInsert = table.insert
local TableConcat = table.concat

local StringFormat = string.format

--- Verifies that a building site is valid.
---@param buildingSite AIChunkBuildingSite
---@return boolean
---@return 'MissingFieldSize' | 'MissingFieldOffsetX' | 'MissingFieldOffsetZ' | 'CategoryPreference'?
local function VerifyBuildingSite(buildingSite)
    if not buildingSite.Size then
        return false, 'MissingFieldSize'
    end

    if not buildingSite.OffsetX then
        return false, 'MissingFieldOffsetX'
    end

    if not buildingSite.OffsetZ then
        return false, 'MissingFieldOffsetZ'
    end

    if not buildingSite.CategoryPreference then
        return false, 'CategoryPreference'
    end

    return true
end

--- Verifies that a base chunk is valid.
---@param template AIChunkTemplate
---@return boolean
---@return 'MissingFieldSize' | 'MissingFieldLayer' | 'MissingFieldBuildingSites' | 'MissingFieldSize' | 'MissingFieldOffsetX' | 'MissingFieldOffsetZ' | 'CategoryPreference'?
function VerifyBaseChunk(template)
    if not template.Size then
        return false, 'MissingFieldSize'
    end

    if not template.Layer then
        return false, 'MissingFieldLayer'
    end

    if not template.BuildingSites then
        return false, 'MissingFieldBuildingSites'
    end

    for k = 1, TableGetn(template.BuildingSites) do
        local ok, err = VerifyBuildingSite(template.BuildingSites[k])
        if not ok then
            return false, err
        end
    end

    return true
end

--- Turns the template into a stringified Lua table.
---@param template AIChunkTemplate
function StringifyChunkTemplate(template)

    local lines = {}

    TableInsert(lines, "{\r\n")
    TableInsert(lines, StringFormat("  Faction = %s, \r\n", tostring(template.Faction)))
    TableInsert(lines, StringFormat("  Size = %d, \r\n", tostring(template.Size)))
    TableInsert(lines, StringFormat("  BuildAreas = { \r\n", tostring(template.Size)))
    for k = 1, TableGetn(template.BuildAreas) do
        local buildOffsets = template.BuildAreas[k]
        local content = {}
        for l = 1, TableGetn(buildOffsets) do
            local offset = buildOffsets[l]
            content[l] = StringFormat("{ %.2f, %.2f }, ", offset[1], offset[2])
        end
        TableInsert(lines, StringFormat("    { %s }, \r\n", TableConcat(content, "")))
    end
    TableInsert(lines, "  }, \r\n")
    TableInsert(lines, "} \r\n")

    return TableConcat(lines, "")
end
