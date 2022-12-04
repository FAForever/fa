----------------------------------------------------------------------------
-- File: lua/modules/ui/game/build_templates.lua
-- Author: Ted Snook
-- Summary: Build Templates UI
-- Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

local Prefs = import("/lua/user/prefs.lua")
local templates = Prefs.GetFromCurrentProfile('build_templates') or {}
local UIUtil = import("/lua/ui/uiutil.lua")

function CreateBuildTemplate()
    GenerateBuildTemplateFromSelection()
    local template = GetActiveBuildTemplate()
    ClearBuildTemplates()
    if not table.empty(template) then
        AddTemplate(template)
    end
end

function Init()
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ReceiveTemplate, 'Template')
end

function ReceiveTemplate(sender, msg)
    if Prefs.GetOption('accept_build_templates') ~= 'yes' then return end
    local tab = import("/lua/ui/game/construction.lua").GetTabByID('templates')
    if tab then
        import("/lua/ui/game/announcement.lua").CreateAnnouncement(LOC('<LOC template_0000>Build Template Received'), tab, LOCF('<LOC template_0001>From %s', sender))
    end
    AddTemplate(msg.data)
end

function GetInitialName(template)
    for _, entry in template do
        if type(entry) ~= 'table' then continue end
        return (string.gsub(__blueprints[entry[1]].Description, '^<[^>]*>', '')) -- removes <LOC xyz_desc> from name
    end
end

function GetInitialIcon(template)
    for _, entry in template do
        if type(entry) == 'table' and UIUtil.UIFile('/icons/units/' .. entry[1] .. '_icon.dds', true) then
            return entry[1] -- Original or modded unit found
        end
    end
    return 'default' -- If we don't find a valid IconName; return string 'default'
end

function AddTemplate(newTemplate)
    table.insert(templates, {templateData = newTemplate, name = GetInitialName(newTemplate), icon = GetInitialIcon(newTemplate)})
    Prefs.SetToCurrentProfile('build_templates', templates)
end

function GetTemplates()
    return Prefs.GetFromCurrentProfile('build_templates')
end

function RemoveTemplate(templateID)
    table.remove(templates, templateID)
    Prefs.SetToCurrentProfile('build_templates', templates)
end

function RenameTemplate(templateID, name)
    templates[templateID].name = name
    Prefs.SetToCurrentProfile('build_templates', templates)
end

function SetTemplateIcon(templateID, iconPath)
    templates[templateID].icon = iconPath
    Prefs.SetToCurrentProfile('build_templates', templates)
end

function SendTemplate(templateID, armyIndex)
    armyIndex = armyIndex
    if table.getn(templates[templateID].templateData) > 22 then
        UIUtil.QuickDialog(GetFrame(0), "<LOC build_templates_0000>You may only send build templates with 20 or less buildings.",
            "<LOC _Ok>", nil, nil, nil, nil, nil, true,  {worldCover = true, enterButton = 1, escapeButton = 1})
        return
    end
    SessionSendChatMessage(armyIndex, {Template = true, data = templates[templateID].templateData})
end

function SetTemplateKey(templateID, key)
    for i, template in templates do
        if i ~= templateID and template.key == key then
            return false
        end
    end
    templates[templateID].key = key
    Prefs.SetToCurrentProfile('build_templates', templates)
    return true
end

function ClearTemplateKey(templateID)
    templates[templateID].key = nil
    Prefs.SetToCurrentProfile('build_templates', templates)
end
