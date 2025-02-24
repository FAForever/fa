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

---@class AIChunkOffset
---@field [1] number
---@field [2] number

---@class AIChunks
---@field [1] AIChunkOffset[]    # 01 ogrid : units such as walls and tech 1 anti air and point defense
---@field [2] AIChunkOffset[]    # 02 ogrids: units such as radars, extractors, and storages
---@field [3] AIChunkOffset[]    # 03 ogrids: units such as a strategic missile defense
---@field [4] AIChunkOffset[]    # 04 ogrids: exists for mods
---@field [5] AIChunkOffset[]    # 05 ogrids: exists for mods
---@field [6] AIChunkOffset[]    # 06 ogrids: units such as tech 2 power generators, stealth field and shield generators
---@field [7] AIChunkOffset[]    # 07 ogrids: exists for mods
---@field [8] AIChunkOffset[]    # 08 ogrids: units such as factories
---@field [9] AIChunkOffset[]    # 09 ogrids: units such as the novax center
---@field [10] AIChunkOffset[]   # 10 ogrids: units such as the paragon
---@field [11] AIChunkOffset[]   # 11 ogrids: exists for mods
---@field [12] AIChunkOffset[]   # 12 ogrids: exists for mods
---@field [13] AIChunkOffset[]   # 13 ogrids: exists for mods
---@field [14] AIChunkOffset[]   # 14 ogrids: exists for mods
---@field [15] AIChunkOffset[]   # 15 ogrids: exists for mods
---@field [16] AIChunkOffset[]   # 16 ogrids: exists for mods

---@class AIChunkTemplate
---@field Size number
---@field BuildAreas AIChunkOffset[][]
---@field Faction FactionCategory

local TableGetn = table.getn
local TableInsert = table.insert
local TableConcat = table.concat

local StringFormat = string.format

--- Verifies the chunk so that it
---@param template AIChunkTemplate
function VerifyChunkTemplate(template)
    if not template.Faction then
        WARN("AIChunkTemplates - missing 'Faction' field")
        return false
    end

    if not template.Size then
        WARN("AIChunkTemplates - missing 'Size' field")
        return false
    end

    if not template.BuildAreas then
        WARN("AIChunkTemplates - missing 'BuildAreas' field")
        return false
    end

    local count = TableGetn(template.BuildAreas)
    if count < 16 then
        WARN("AIChunkTemplates - not sufficient offsets in the 'BuildAreas' field: should be at least 16")
        return false
    end

    for k = 1, TableGetn(template.BuildAreas) do
        local offsets = template.BuildAreas[k]
        for i = 1, TableGetn(offsets) do
            local offset = offsets[i]

            if not (offset[1] or offset[2]) then
                WARN(StringFormat("AIChunkTemplates - invalid offset at size %d at index %d: (%f, %f) ", k, i, unpack(offset)))
            end
        end
    end

    return true
end

---@param faction FactionCategory
---@param size number
---@return AIChunkTemplate?
function CreateChunkTemplate(size, faction)

    if size < 1 then
        WARN(StringFormat("AIChunkTemplates - size is too small: %s", tostring(size)))
        return nil
    end

    if size > 256 then
        WARN(StringFormat("AIChunkTemplates - size is too large: %s", tostring(size)))
        return nil
    end

    ---@type AIChunkTemplate
    local template = {
        Faction = faction,
        BuildAreas = {},
        Size = size,
    }

    -- pre-pupulate the first 16 tables
    for k = 1, 16 do
        template.BuildAreas[k] = {}
    end

    VerifyChunkTemplate(template)

    return template
end

--- Turns the template into a stringified Lua table. Useful for debugging
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
