local mathMod = math.mod
local mathCeil = math.ceil
local mathFloor = math.floor
local mathMin = math.min
local mathMax = math.max
local tableGetN = table.getn
local tableHash = table.hash

local GetUnitCommandData = GetUnitCommandData
local EntityCategoryGetUnitList = EntityCategoryGetUnitList

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

--- Gets an offset to add to template positions to center templates with units
--- that have odd-numbered footprint sizes, such as walls and SMD.
---@param unitbp UnitBlueprint
---@param axis 'SizeX' | 'SizeZ'
---@return number # 0 or 0.5
function TemplateAxisOffset(unitbp, axis)
    return mathMod(
            mathCeil(
                unitbp.Footprint and unitbp.Footprint[axis]
                or unitbp[axis]
                or 1
            )
            , 2
        ) == 1 and 0
        or 0.5
end


--#endregion

--#region Template movement functions

--- Offsets the given template in-place so that it moves smoothly with the mouse
--- when used in build command mode with the given blueprint.
--- 
--- Blueprint defaults to the bp for the first bp id in the template.
---@param template UIBuildTemplate
---@param buildModeBlueprint UnitBlueprint? # Defaults to the bp for the first bp id in the template.
---@return UIBuildTemplate offsetTemplate
function OffsetTemplateForBuildModeBp(template, buildModeBlueprint)
    buildModeBlueprint = buildModeBlueprint or __blueprints[template[3][1]] --[[@as UnitBlueprint]]
    local offX = TemplateAxisOffset(buildModeBlueprint, 'SizeX')
    local offZ = TemplateAxisOffset(buildModeBlueprint, 'SizeZ')
    if offX ~= 0 or offZ ~= 0 then
        for i = 3, tableGetN(template) do
            local nextbp = template[i]
            nextbp[3] = nextbp[3] + offX
            nextbp[4] = nextbp[4] + offZ
        end
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

    local mouseCenterOffX, mouseCenterOffZ = GetTemplateOffsetToCenterBp(buildModeBp)

    local x0Min, z0Min, x1Max, z1Max = 10000, 10000, -10000, -10000
    for i = 3, tableGetN(template) do
        local nextBuilding = template[i]
        local bpId = nextBuilding[1]
        local bp = __blueprints[bpId] --[[@as UnitBlueprint]]
        local x0, z0, x1, z1 = GetTemplateBpSkirtRectCoords(bp)
        local offX = nextBuilding[3] + mouseCenterOffX
        local offZ = nextBuilding[4] + mouseCenterOffZ
        nextBuilding[3] = offX
        nextBuilding[4] = offZ
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

    for i = 3, tableGetN(template) do
        local nextBuilding = template[i]
        local offX, offZ = nextBuilding[3], nextBuilding[4]
        nextBuilding[3] = offX - centerX
        nextBuilding[4] = offZ - centerZ
    end

    return template
end

--#endregion
--#region Template validation functions

--- Returns true if the template has anything in the first building's blueprint id index.
---@param template UIBuildTemplate
---@return boolean
function VerifyTemplate(template)
    local firstBpId = template[3][1]
    if not firstBpId then
        return false
    end

    return true
end

--- Checks if command data of units allows building the template
---@param units UserUnit[]
---@param template UIBuildTemplate
---@return boolean
function CanUnitsBuildTemplate(units, template)
    local _, _, buildables = GetUnitCommandData(units --[[@as UserUnit[] ]])
    buildables = EntityCategoryGetUnitList(buildables)
    local buildablesHashed = tableHash(buildables)

    local n = tableGetN(template)
    for i = 3, n do
        local bpId = template[i][1]
        if not buildablesHashed[bpId] then
            return false
        end
    end
    return true
end
--#endregion

