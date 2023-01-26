---@class BuildTemplateBuilding
---@field [1] string unit id
---@field [2] number build order
---@field [3] number position x
---@field [4] number position z

---@class BuildQueue
---@field [1] number
---@field [2] number
---@field [3] BuildTemplateBuilding
--@field [...] BuildTemplateBuilding

---@class BuildTemplate
---@field templateData table
---@field name string
---@field icon string unit id


local Prefs = import("/lua/user/prefs.lua")
---@type BuildTemplate[]
local templates = Prefs.GetFromCurrentProfile('build_templates_factory') or {}
local UIUtil = import("/lua/ui/uiutil.lua")

-- Utils
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

function GetInitialIcon(buildQueue)
    for _, entry in buildQueue do
        if type(entry) == 'table' and UIUtil.UIFile('/icons/units/' .. entry.id .. '_icon.dds', true) then
            return entry.id -- Original or modded unit found
        end
    end
    return 'default' -- If we don't find a valid IconName; return string 'default'
end

-- Main functions
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

function GetTemplates()
    return Prefs.GetFromCurrentProfile('build_templates_factory')
end

-- Options menu
function RemoveTemplate(templateID)
    table.remove(templates, templateID)
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

function RenameTemplate(templateID, name)
    templates[templateID].name = name
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

function SetTemplateIcon(templateID, iconPath)
    templates[templateID].icon = iconPath
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end

function SendTemplate(templateID, armyIndex)
    WARN("Not implemented yet. Shhhh.")
end

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

function ClearTemplateKey(templateID)
    templates[templateID].key = nil
    Prefs.SetToCurrentProfile('build_templates_factory', templates)
end
