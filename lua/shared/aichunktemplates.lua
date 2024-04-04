
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

    local count = table.getn(template.BuildAreas)
    if count < 16 then
        WARN("AIChunkTemplates - not sufficient offsets in the 'BuildAreas' field: should be at least 16")
        return false
    end

    for k = 1, table.getn(template.BuildAreas) do
        local offsets = template.BuildAreas[k]
        for i = 1, table.getn(offsets) do
            local offset = offsets[i]

            if not (offset[1] or offset[2]) then
                WARN(string.format("AIChunkTemplates - invalid offset at size %d at index %d: %s ", k, i, repru(offset)))
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
        WARN(string.format("AIChunkTemplates - size is too small: %s", tostring(size)))
        return nil
    end

    if size > 256 then
        WARN(string.format("AIChunkTemplates - size is too large: %s", tostring(size)))
        return nil
    end

    ---@type AIChunkTemplate
    local template = {
        Faction = faction,
        BuildAreas = { },
        Size = size,
    }

    -- pre-pupulate the first 16 tables
    for k = 1, 16 do
        template.BuildAreas[k] = {}
    end

    VerifyChunkTemplate(template)

    return template
end

--- Copies the template 
---@param template AIChunkTemplate
function CopyChunkTemplate(template)

end

--- Turns the template into a stringified Lua table
---@param template AIChunkTemplate
function StringifyChunkTemplate(template)

    local lines = { }

    table.insert(lines, "{\r\n")
    table.insert(lines, string.format("  Faction = %s, \r\n", tostring(template.Faction)))
    table.insert(lines, string.format("  Size = %d, \r\n", tostring(template.Size)))
    table.insert(lines, string.format("  BuildAreas = { \r\n", tostring(template.Size)))
    for k = 1, table.getn(template.BuildAreas) do
        local buildOffsets = template.BuildAreas[k]
        local content = { }
        for l = 1, table.getn(buildOffsets) do
            local offset = buildOffsets[l]
            content[l] = string.format("{ %.2f, %.2f }, ", offset[1], offset[2])
        end
        table.insert(lines, string.format("    { %s }, \r\n", table.concat(content, "")))
    end
    table.insert(lines, "  }, \r\n")
    table.insert(lines, "} \r\n")

    return table.concat(lines, "")
end