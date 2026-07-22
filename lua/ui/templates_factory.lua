local Prefs = import("/lua/user/prefs.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

-- This file is an implementation of factory queue templates, not a factory for templates.

---@class UIBuildTemplateData
---@field templateData UIBuildTemplate
---@field name string
---@field icon UnitId

---@type UIBuildTemplateData[]
local templates = Prefs.GetFromCurrentProfile('build_templates_factory') or {}

--#region Utils

--- Returns the next available default name (a number in parentheses) for factory queue templates.
---@return string
function GetInitialName()
    local nextNum = 0
    for _, template in templates do
        local pStart, pEnd = string.find(template.name, '%(%d+%)')
        if pStart == 1 and pEnd == string.len(template.name) then
            local prevNum = tonumber(string.sub(template.name, 2, pEnd - 1))
            if nextNum < prevNum then
                nextNum = prevNum
            end
        end
    end
    local name = '(' .. nextNum + 1 .. ')'

    return name
end

--- Gets the icon of the first unit in the build queue that has an icon.
---@param buildQueue UIBuildQueueItem[]?
---@return string
function GetInitialIcon(buildQueue)
    for _, entry in buildQueue do
        if type(entry) == 'table' and UIUtil.UIFile('/icons/units/' .. entry.id .. '_icon.dds', true) then
            return entry.id -- Original or modded unit found
        end
    end
    return 'default' -- If we don't find a valid IconName; return string 'default'
end

--#endregion

--#region Template Module functions
-- These functions must have the same name as the ones in build_templates.lua
-- due to the implementation of construction.lua.

--#region Main functions

--- Creates a factory build queue template of the given queue and saves it to prefs.
---@param buildQueue UIBuildQueueItem[]
function CreateBuildTemplate(buildQueue)
    if buildQueue and not table.empty(buildQueue) then
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_02'}))
        table.insert(templates, {templateData = buildQueue, name = GetInitialName(), icon = GetInitialIcon(buildQueue)})
        Prefs.SetToCurrentProfile('build_templates_factory', templates)
        import("/lua/ui/game/construction.lua").RefreshUI()
    else
        PlaySound(Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',}))
    end
end

--- Gets factory build queue templates from prefs.
---@return UIBuildTemplateData[]
function GetTemplates()
    return Prefs.GetFromCurrentProfile('build_templates_factory')
end
--#endregion
--#region Template options context menu
-- These functions must have the same name as the ones in build_templates.lua
-- due to the implementation of construction.lua.

--- Removes the factory build queue template with the given ID (an array index).
---@param templateID integer
function RemoveTemplate(templateID)
    table.remove(templates, templateID)
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

--- Renames the factory build queue template with the given ID (an array index).
---@param templateID integer
---@param name string
function RenameTemplate(templateID, name)
    templates[templateID].name = name
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

--- Changes the icon for the factory build queue template with the given ID (an array index).
---@param templateID integer
---@param iconPath FileName
function SetTemplateIcon(templateID, iconPath)
    templates[templateID].icon = iconPath
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

--- Not implemented.
--- 
--- Shares to another army the factory build queue template with the given ID (an array index).
---@deprecated
---@param templateID integer
---@param armyIndex integer
function SendTemplate(templateID, armyIndex)
    WARN("Not implemented yet. Shhhh.")
end

--- Sets a hotkey for the factory build queue template with the given ID (an array index).
--- 
--- Returns false if the hotkey is already in use by another factory build queue template.
---@param templateID integer
---@param key Keycode
---@return boolean success
function SetTemplateKey(templateID, key)
    local used = false
    for i, template in templates do
        if i == templateID then continue end
        if template.key and template.key == key then
            used = true
            break
        end
    end
    if used then
        return false
    else
        templates[templateID].key = key
        Prefs.SetToCurrentProfile('build_templates_factory', templates)
        return true
    end
end

--- Removes the hotkey for the factory build queue template with the given ID (an array index).
---@param templateID integer
function ClearTemplateKey(templateID)
    templates[templateID].key = nil
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end
--#endregion
--#endregion
