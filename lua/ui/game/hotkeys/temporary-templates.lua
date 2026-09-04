local Prefs = import('/lua/user/prefs.lua')
local CM = import("/lua/ui/game/commandmode.lua")
local TemplateUtils = import('/lua/ui/templateutils.lua')

local cheatsEnabled = SessionGetScenarioInfo().Options.CheatsEnabled
---@type UIBuildTemplate | nil
TempTemplate = Prefs.GetFromCurrentProfile('build_template_temporary')

---@param template UIBuildTemplate
---@return boolean success
function SaveTemporaryTemplate(template)
    TemplateUtils.CenterTemplateForBuildModeBp(template)
    local ok, msg = TemplateUtils.VerifyTemplate(template)
    if not ok then
        print('Template being saved as Temporary Template is invalid. See moholog for details.')
        WARN(string.format('Template being saved as Temporary Template is invalid. Template:\n%s\n%s\n%s', msg, repr(template), debug.traceback()))
        return false
    end
    TempTemplate = template
    print('Saved Temporary Template (' .. tostring(table.getn(template) - 2) .. ' structures)')
    return true
end

local function GenerateTemporaryTemplateFromSelection()
    local oldTemplate = GetActiveBuildTemplate()
    GenerateBuildTemplateFromSelection()
    SaveTemporaryTemplate(GetActiveBuildTemplate())
    if table.empty(oldTemplate) then
        ClearBuildTemplates()
    else
        SetActiveBuildTemplate(oldTemplate)
    end
end

--- Tries to start command mode with the Temporary Template, respecting build restrictions for the given units.
--- If cheats are enabled, passing in no units starts cheat spawn mode with the Temporary Template.
---@param units? UserUnit[]
---@return boolean success
local function TryBuildTemporaryTemplateForUnits(units)
    local template = TempTemplate
    if not template then
        print('No Temporary Template is saved.')
        return false
    end

    if table.empty(units) then
        if cheatsEnabled ~= 'true' then
            print('No selection for building Temporary Template')
            return false
        end
        CM.StartCommandMode('build', { name = template[3][1], cheat = true, army = GetFocusArmy(), yaw = 0 })
        SetActiveBuildTemplate(template)
        print('Activated Temporary Template (Cheat spawn mode)')
    else
        ---@cast units -nil
        if not TemplateUtils.CanUnitsBuildTemplate(units, template) then
            print('Selection cannot build Temporary Template')
            return false
        end
        CM.StartCommandMode('build', { name = template[3][1] })
        SetActiveBuildTemplate(template)
        print('Activated Temporary Template')
    end

    return true
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

function CreateTemporaryTemplateFromSelection()
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
import('/lua/ui/override/exit.lua').AddOnExitCallback('TemporaryTemplateOnExit', OnExit)
