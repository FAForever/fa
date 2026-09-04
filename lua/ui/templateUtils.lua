local mathMod = math.mod
local mathCeil = math.ceil
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max
local tableGetN = table.getn
local tableHash = table.hash

local GetUnitCommandData = GetUnitCommandData
local EntityCategoryGetUnitList = EntityCategoryGetUnitList

local __blueprints = __blueprints

-- Utilities that help work with UI build template data

--#region Data calculation functions

---@param bp UnitBlueprint
---@nodiscard
---@return number x0
---@return number z0
---@return number x1
---@return number z1
function GetTemplateBpSkirtRectCoords(bp)
    local bpFoot = bp.Footprint ---@cast bpFoot -nil
    local bpPhysics = bp.Physics
    local x0, z0, x1, z1 = 0, 0, 0, 0
    local footSizeX = bpFoot.SizeX
    if bpPhysics.SkirtSizeX <= footSizeX then
        x0 = 0.5 - footSizeX
        x1 = 0.5
    else
        local offX = bpPhysics.SkirtOffsetX
        local skirtDiff = bpPhysics.SkirtSizeX - footSizeX
        x0 = 0.5 - footSizeX + offX
        x1 = 0.5 + skirtDiff + offX
    end
    local footSizeZ = bpFoot.SizeZ
    if bpPhysics.SkirtSizeZ <= footSizeZ then
        z0 = 0.5 - footSizeZ
        z1 = 0.5
    else
        local skirtOffZ = bpPhysics.SkirtOffsetZ
        local skirtDiffZ = bpPhysics.SkirtSizeZ - footSizeZ
        z0 = 0.5 - footSizeZ + skirtOffZ
        z1 = 0.5 + skirtDiffZ + skirtOffZ
    end
    return x0, z0, x1, z1
end

---@param bp UnitBlueprint
---@nodiscard
---@return Rectangle
function GetTemplateBpSkirtRect(bp)
    return Rect(GetTemplateBpSkirtRectCoords(bp))
end

--- Returns the template offsets needed to center the cursor in a template
--- that uses a build mode of the given bp.
---
--- Ensures smooth movement for the given bp if it is used in a template.
---@param buildModeBp UnitBlueprint
---@nodiscard
---@return number centerOffX
---@return number centerOffZ
function GetTemplateOffsetToCenterBp(buildModeBp)
    -- Problem: Get template build mode cursor pos to be at center of structure skirt.
    -- Cursor starts at the center of the bottom right footprint grid 1x1 cell.
    -- Positive offsets move the *template* to the right and down (positive X/Z direction).

    -- Cursor starts at `FtSzX - 0.5` (0.5 is from being centered in a 1x1 cell)
    -- We want to get to `SkSzX / 2 + SkOffX` using template-shifting offset `x`
    -- x + SkirtCenter = CursorPos
    -- x + (SkSzX / 2 + SkOffX) = (FtSzX - 0.5)
    -- x = FtSzX - 0.5 - SkSzX / 2 - SkOffX

    local bpFoot = buildModeBp.Footprint ---@cast bpFoot -nil
    local bpPhysics = buildModeBp.Physics
    local centerOffX = bpFoot.SizeX
        - 0.5
        - bpPhysics.SkirtSizeX / 2
        - bpPhysics.SkirtOffsetX
    -- repeat for Z
    local centerOffZ = bpFoot.SizeZ
        - 0.5
        - bpPhysics.SkirtSizeZ / 2
        - bpPhysics.SkirtOffsetZ
    return centerOffX, centerOffZ
end

--- Gets an offset to align templates with the world grid when using build command
--- mode with a blueprint that has even-numbered footprint sizes, like SMD.
---@param buildModeBp UnitBlueprint
---@param axis 'SizeX' | 'SizeZ'
---@nodiscard
---@return number # 0 or 0.5
function GetTemplateAlignmentAxisOffsetForBp(buildModeBp, axis)
    return mathMod(
            mathCeil(
                buildModeBp.Footprint and buildModeBp.Footprint[axis]
                or buildModeBp[axis]
                or 1
            )
            , 2
        ) == 1 and 0
        or 0.5
end

--- Gets the offsets to align templates with the world grid when using build command
--- mode with a blueprint that has even-numbered footprint sizes, like SMD.
---@param buildModeBp UnitBlueprint
---@return number offX
---@return number offZ
function GetTemplateAlignmentOffsetsForBp(buildModeBp)
    return GetTemplateAlignmentAxisOffsetForBp(buildModeBp, 'SizeX')
        , GetTemplateAlignmentAxisOffsetForBp(buildModeBp, 'SizeZ')
end

--#endregion

--#region Template movement functions

--- Offests the template in-place
--- 
--- You should only use offsets that are multiples of 0.5
---@param template UIBuildTemplate
---@param offX number
---@param offZ number
---@return UIBuildTemplate
function OffsetTemplate(template, offX, offZ)
    for i = 3, tableGetN(template) do
        local buildData = template[i]
        buildData[3] = buildData[3] + offX
        buildData[4] = buildData[4] + offZ
    end
    return template
end

--- Offsets the given template in-place so that it moves smoothly with the mouse
--- when used in build command mode with the given blueprint.
--- 
--- Blueprint defaults to the bp for the first bp id in the template.
---@param template UIBuildTemplate
---@param buildModeBlueprint UnitBlueprint? # Defaults to the bp for the first bp id in the template.
---@return UIBuildTemplate offsetTemplate
function OffsetTemplateForBuildModeBp(template, buildModeBlueprint)
    buildModeBlueprint = buildModeBlueprint or __blueprints[template[3][1]] --[[@as UnitBlueprint]]
    local offX, offZ = GetTemplateAlignmentOffsetsForBp(buildModeBlueprint)
    if offX ~= 0 or offZ ~= 0 then
        OffsetTemplate(template, offX, offZ)
    end
    return template
end

--- Centers the given template in-place so that it is centered on the build mode cursor. 
--- Ensures smooth movement of the template in build mode.
--- 
--- Since the blueprint id passed to the build command is relevant to the template offsets relative to the mouse,
--- the blueprint table is an optional parameter, defaulting to the bp of the first building in the template.
---@param template UIBuildTemplate
---@param buildModeBp UnitBlueprint? # Defaults to bp of first template building
---@return UIBuildTemplate centeredTemplate
function CenterTemplateForBuildModeBp(template, buildModeBp)
    buildModeBp = buildModeBp or __blueprints[template[3][1]] --[[@as UnitBlueprint]]

    local alignOffX, alignOffZ = GetTemplateAlignmentOffsetsForBp(buildModeBp)

    local x0Min, z0Min, x1Max, z1Max = 10000, 10000, -10000, -10000
    for i = 3, tableGetN(template) do
        -- Offset template to align it with world grid
        local nextBuilding = template[i]
        local offX = nextBuilding[3] + alignOffX
        local offZ = nextBuilding[4] + alignOffZ
        nextBuilding[3] = offX
        nextBuilding[4] = offZ

        -- While we're offsetting the template, collect skirt rect data.
        local bpId = nextBuilding[1]
        local bp = __blueprints[bpId] --[[@as UnitBlueprint]]
        local x0, z0, x1, z1 = GetTemplateBpSkirtRectCoords(bp)
        x0 = x0 + offX
        z0 = z0 + offZ
        x1 = x1 + offX
        z1 = z1 + offZ
        x0Min = mathMin(x0, x0Min)
        z0Min = mathMin(z0, z0Min)
        x1Max = mathMax(x1, x1Max)
        z1Max = mathMax(z1, z1Max)
    end
    -- Floor so that we don't break smooth movement of the template with
    -- an unnecessary 0.5 offset.
    local centerX = mathFloor((x0Min + x1Max) / 2)
    local centerZ = mathFloor((z0Min + z1Max) / 2)

    OffsetTemplate(template, -centerX, -centerZ)

    return template
end

--#endregion
--#region Template validation functions

--- Returns true if the template is composed of valid blueprints.
--- 
--- Returns false with a reason otherwise.
---@param template UIBuildTemplate
---@nodiscard
---@return boolean
---@return string?
function VerifyTemplate(template)
    for i = 3, tableGetN(template) do
        local bpId = template[i][1]
        if not bpId then
            return false, 'nil blueprint at index ' .. i
        end
        if not __blueprints[bpId] then
            return false, 'unknown blueprint "' .. bpId .. '" at index ' .. i
        end
    end

    return true
end

--- Checks if command data of units allows building the template
---@param units UserUnit[]
---@param template UIBuildTemplate
---@nodiscard
---@return boolean
function CanUnitsBuildTemplate(units, template)
    local _, _, buildables = GetUnitCommandData(units --[[@as UserUnit[] ]])
    buildables = EntityCategoryGetUnitList(buildables)
    local buildablesHashed = tableHash(buildables)

    for i = 3, tableGetN(template) do
        local bpId = template[i][1]
        if not buildablesHashed[bpId] then
            return false
        end
    end
    return true
end
--#endregion

