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

---@class AIBaseChunkBuildingSite
---@field OffsetX number                    # X offset in world coordinates
---@field OffsetZ number                    # Z offset in world coordinates
---@field Size number                       # Size in world coordinates of the building site
---@field TypePreference EntityCategory     # Preferred unit category for this building site
---@field TechPreference EntityCategory     # Preferred tech category for this building site

---@class AIBaseChunk
---@field Size number                       # Size in world coordinates
---@field Layer ChunkLayers                 # Intended build layer of the chunk
---@field BuildingSites AIBaseChunkBuildingSite[]  # Building sites of the chunk

local MathFloor = math.floor
local MathMax = math.max

local TableGetn = table.getn
local TableInsert = table.insert
local TableConcat = table.concat

local StringFormat = string.format

local TechPreferences = {
    "EXPERIMENTAL",
    "TECH3",
    "TECH2",
    "TECH1",
}

local TypePreferences = {
    "GATE",
    "FACTORY",
    "SHIELD",
    "ANTIMISSILE",
    "DIRECTFIRE",
    "ANTIAIR",
    "ENERGYPRODUCTION",
    "MASSFABRICATION",
    "ENERGYSTORAGE",
    "MASSSTORAGE",
    "WALL"
}

--- Verifies that a building site of a base chunk is valid.
---@param buildingSite AIBaseChunkBuildingSite
---@return boolean
---@return 'MissingFieldSize' | 'MissingFieldOffsetX' | 'MissingFieldOffsetZ' | 'MissingFieldTypePreference' | 'MissingFieldTechPreference' ?
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

    if not buildingSite.TypePreference then
        return false, 'MissingFieldTypePreference'
    end

    if not buildingSite.TechPreference then
        return false, 'MissingFieldTechPreference'
    end

    return true
end

--- Verifies that a base chunk is valid.
---@param template AIBaseChunk
---@return boolean
---@return 'MissingFieldSize' | 'MissingFieldLayer' | 'MissingFieldBuildingSites' | 'MissingFieldSize' | 'MissingFieldOffsetX' | 'MissingFieldOffsetZ' | 'MissingFieldTypePreference' | 'MissingFieldTechPreference'?
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

--- Computes the tech preference of a building site.
---@param unitBlueprint UnitBlueprint
---@return EntityCategory
local function ComputeTechPreference(unitBlueprint)
    for _, category in TechPreferences do
        if EntityCategoryContains(categories[category], unitBlueprint.BlueprintId) then
            return categories[category]
        end
    end

    -- fallback, allow anything
    return categories.ALLUNITS
end

--- Computes the type preference of a building site.
---@param unitBlueprint UnitBlueprint
---@return EntityCategory
local function ComputeTypePreference(unitBlueprint)
    for _, category in TypePreferences do
        if EntityCategoryContains(categories[category], unitBlueprint.BlueprintId) then
            return categories[category]
        end
    end

    -- fallback, allow anything
    return categories.ALLUNITS
end

--- Computes the offset of a building site.
---@param position Vector
---@return number   # X in world coordinates
---@return number   # Z in world coordinates
local function ComputeOffset(position, chunkSize, unitSize)
    local px = position[1] - 0.5
    local pz = position[3] - 0.5
    local ox = MathFloor(px / chunkSize) * chunkSize
    local oz = MathFloor(pz / chunkSize) * chunkSize
    return px - ox, pz - oz
end

--- Computes the size of a building site.
---@param unitBlueprint UnitBlueprint
---@return number   # Size of base chunk in world coordinates
local function ComputeSize(unitBlueprint)
    return MathMax(unitBlueprint.Physics.SkirtSizeX or 1, unitBlueprint.Physics.SkirtSizeZ or 1)
end

--- Creates a building site of a unit.
---@param unit UserUnit | Unit
---@param chunkSize number   # Size of base chunk in world coordinates
---@return AIBaseChunkBuildingSite
local function CreateBuildingSite(unit, chunkSize)
    local unitBlueprint = unit:GetBlueprint()
    local unitPosition = unit:GetPosition()

    local typePreference = ComputeTypePreference(unitBlueprint)
    local techPreference = ComputeTechPreference(unitBlueprint)
    local unitSize = ComputeSize(unitBlueprint)
    local offsetX, offsetZ = ComputeOffset(unitPosition, chunkSize, unitSize)

    ---@type AIBaseChunkBuildingSite
    local buildingSite = {
        TypePreference = typePreference,
        TechPreference = techPreference,
        Size = unitSize,
        OffsetX = offsetX,
        OffsetZ = offsetZ
    }

    return buildingSite
end

--- Creates a base chunk from the given units.
---@param units (UserUnit | Unit)[]
---@param size number   # Size of base chunk in world coordinates
---@return AIBaseChunk?
---@return 'MissingFieldSize' | 'MissingFieldLayer' | 'MissingFieldBuildingSites' | 'MissingFieldSize' | 'MissingFieldOffsetX' | 'MissingFieldOffsetZ' | 'TypePreference'?
function CreateBaseChunk(units, size)
    ---@type AIBaseChunkBuildingSite[]
    local buildingSites = {}

    -- populate building sites
    for k = 1, TableGetn(units) do
        local unit = units[k]
        local buildingSite = CreateBuildingSite(unit, size)
        TableInsert(buildingSites, buildingSite)
    end

    ---@type AIBaseChunk
    local template = {
        BuildingSites = buildingSites,
        Size = size,
        Layer = "Land",
    }

    return template
end

--- Stringifies a type preference into a syntax-wise valid Lua value.
local function StringifyTypePreference(typePreference)
    for _, category in TypePreferences do
        if typePreference == categories[category] then
            return string.format("categories.%s", category)
        end
    end

    return "ALLUNITS"
end

--- Stringifies a tech preference into a syntax-wise valid Lua value.
local function StringifyTechPreference(techPreference)
    for _, category in TechPreferences do
        if techPreference == categories[category] then
            return string.format("categories.%s", category)
        end
    end

    return "ALLUNITS"
end

--- Stringifies a building site into a syntax-wise valid Lua table.
---@param buildingSite AIBaseChunkBuildingSite
---@return string   # stringified results
---@return string   # type
---@return string   # tech
local function StringifyBuildingSite(buildingSite)
    local stringifiedTechPreference = StringifyTechPreference(buildingSite.TechPreference)
    local stringifiedTypePreference = StringifyTypePreference(buildingSite.TypePreference)

    return string.format(
        "{ TypePreference = %s, TechPreference = %s, OffsetX = %f, OffsetZ = %f, Size = %f }",
        stringifiedTechPreference,
        stringifiedTypePreference,
        buildingSite.OffsetX, buildingSite.OffsetZ, buildingSite.Size
    ), stringifiedTypePreference, stringifiedTechPreference
end

--- Stringifies a base chunk into a syntax-wise valid Lua table.
---@param template AIBaseChunk
function StringifyBaseChunk(template)

    -- stringify template
    local lines = {}
    local typeCount = {}
    local techCount = {}
    TableInsert(lines, "BaseChunk = {")
    TableInsert(lines, StringFormat("  Size = %d,", tostring(template.Size)))
    TableInsert(lines, StringFormat("  BuildingSites = {", tostring(template.Size)))
    for _, buildingSite in template.BuildingSites do
        local stringifiedBuildingSite, type, tech = StringifyBuildingSite(buildingSite)
        typeCount[type] = (typeCount[type] or 0) + 1
        techCount[tech] = (techCount[tech] or 0) + 1
        TableInsert(lines, StringFormat("      %s,", stringifiedBuildingSite))
    end
    TableInsert(lines, "    },")
    TableInsert(lines, "}")

    -- comments with meta data at the top
    local comments = {}
    TableInsert(comments, "-- Count per type:")
    for type, count in typeCount do
        TableInsert(comments, StringFormat("-- - %s: %d", type, count))
    end
    TableInsert(comments, "\r\n")

    TableInsert(comments, "-- Count per tech:")
    for tech, count in techCount do
        TableInsert(comments, StringFormat("-- - %s: %d,", tech, count))
    end
    TableInsert(comments, "\r\n")

    -- combine it all together
    return TableConcat(comments, "\r\n") .. TableConcat(lines, "\r\n")
end
