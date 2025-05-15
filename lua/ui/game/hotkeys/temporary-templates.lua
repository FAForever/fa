local Prefs = import('/lua/user/prefs.lua')
local CM = import("/lua/ui/game/commandmode.lua")

local cheatsEnabled = SessionGetScenarioInfo().Options.CheatsEnabled
---@type UIBuildTemplate | nil
TempTemplate = Prefs.GetFromCurrentProfile('build_template_temporary')

---@param unitbp UnitBlueprint
---@param axis 'SizeX' | 'SizeZ'
---@return number
local function GetTemplateAxisOffset(unitbp, axis)
    return (math.mod(
        math.ceil(
            unitbp.Footprint and unitbp.Footprint[axis]
            or unitbp[axis]
            or 1
        )
        , 2
        ) == 1 and 1
        or 0.5
    )
end

--- Centers the given template
---@param template UIBuildTemplate
---@return UIBuildTemplate centeredTemplate
function CenterTemplate(template)
    local centeredTemplate = table.deepcopy(template)
    local bp1 = __blueprints[ centeredTemplate[3][1] ] --[[@as UnitBlueprint]]
    local bp1Xoffset = GetTemplateAxisOffset(bp1, 'SizeX')
    local bp1Yoffset = GetTemplateAxisOffset(bp1, 'SizeZ')

    local totalSizeX = 0
    local totalSizeZ = 0

    if bp1Xoffset ~= 0 or bp1Yoffset ~= 0 then
        for i = 3, table.getn(template) do
            local nextBp = template[i]
            local nextBpFoot = __blueprints[nextBp].Physics.sk
            nextBp[3] = nextBp[3] + bp1Xoffset
            nextBp[4] = nextBp[4] + bp1Yoffset
        end
    end
    return centeredTemplate
end

---@param template any
function SaveTemporaryTemplate(template)
    TempTemplate = template
    print('Saved Temporary Template (' .. tostring(table.getn(template) - 2) .. ' structures)')
end

local function GenerateTemporaryTemplateFromSelection()
    GenerateBuildTemplateFromSelection()
    SaveTemporaryTemplate(GetActiveBuildTemplate())
end

--- Tries to start command mode with the Temporary Template, respecting build restrictions for the given units.
--- If cheats are enabled, passing in no units starts cheat spawn mode with the Temporary Template.
---@param units? UserUnit[]
---@return boolean success
local function TryBuildTemporaryTemplateForUnits(units)
    local template = TempTemplate
    if template then
        local firstBpId = template[3][1]
        if not firstBpId then
            print('Temporary Template is empty/malformed. See moholog for details.')
            WARN('Temporary Template is empty/malformed. Template: ', repr(template))
            TempTemplate = nil
            return false
        end
        if table.empty(units) then
            if cheatsEnabled == 'true' then
                -- xsb5101
                -- local bpId = 'urb1301'
                local bpId = 'uab4302'
                local bpId = 'xsb1301'
                local bpId = 'xsb4302'
                local bp = __blueprints[bpId]
                local bpPhysics = bp.Physics
                local bpFoot = bp.Footprint
                local sOX = bpPhysics.SkirtOffsetX
                local sOZ = bpPhysics.SkirtOffsetZ
                LOG(bpPhysics.SkirtSizeX, bpFoot.SizeX, bpPhysics.SkirtOffsetX, GetTemplateAxisOffset(bp, 'SizeX'))
                local dist = -0.5+2--bpFoot.SizeX + GetTemplateAxisOffset(bp, 'SizeX') - bpPhysics.SkirtOffsetX - bpPhysics.SkirtSizeX/2
                local skirt = bpPhysics.SkirtSizeX
                local offset = bpPhysics.SkirtOffsetX
                local axis = GetTemplateAxisOffset(bp, 'SizeX')
                local foot = bpFoot.SizeX
                local dist = (skirt - axis) / 2 - (skirt - foot) - offset
                local dist = -skirt/2 - axis/2 + foot - offset
                ---@type UIBuildTemplate
                template = {
                    bpPhysics.SkirtSizeX,
                    bpPhysics.SkirtSizeZ,
                    { bpId, 1
                        , dist
                        , dist
                    },
                }
                reprsl(template)
                if not __blueprints[bpId] then WARN('not a bp: ',bpId) return false end
                CM.StartCommandMode('build', { name = bpId, cheat = true, army = GetFocusArmy(), yaw = 0 })
                SetActiveBuildTemplate(template)
                print('Activated Temporary Template (Cheat spawn mode)')
                return true
            else
                print('No selection for building Temporary Template')
                return false
            end
        end

        local n = table.getn(template)
        local _, _, buildables = GetUnitCommandData(units--[[@as UserUnit[] ]] )
        buildables = EntityCategoryGetUnitList(buildables)
        local seen = {}
        for i = 3, n do
            local bpId = template[i][1]
            if not seen[bpId] then
                if not table.find(buildables, bpId) then
                    print('Selection cannot build Temporary Template')
                    return false
                end
                seen[bpId] = true
            end
        end
        SetActiveBuildTemplate(template)
        CM.StartCommandMode('build', { name = firstBpId })
        print('Activated Temporary Template')
        return true
    end

    print('No Temporary Template is saved.')
    return false
end

function UseOrCreateTemporaryTemplate()
    local selection = GetSelectedUnits()
    local structures
    if selection then
        structures = EntityCategoryFilterDown(categories.STRUCTURE, selection)
    end
    if not selection or table.empty(structures) then
        TryBuildTemporaryTemplateForUnits(selection)
    else
        GenerateTemporaryTemplateFromSelection()
    end
end

function CreateTemporaryTemplate()
    local selection = GetSelectedUnits()
    if not selection then
        print('No units selected for creating Temporary Template')
        return
    end

    local structures = EntityCategoryFilterDown(categories.STRUCTURE, selection)
    if table.empty(structures) then
        print('No structures selected for creating Temporary Template')
        return
    end

    GenerateTemporaryTemplateFromSelection()
end

local function OnExit(exitType)
    Prefs.SetToCurrentProfile('build_template_temporary', TempTemplate)
end
import('/lua/ui/override/Exit.lua').AddOnExitCallback('TemporaryTemplateOnExit', OnExit)
