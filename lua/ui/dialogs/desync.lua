--*****************************************************************************
--* File: lua/modules/ui/dialogs/desync.lua
--* Author: Chris Blackwell
--* Summary: handles multiplayer desyncs
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local dialog = false
local doesntCare = false

function UpdateDialog(beatNumber, strings)
    WARN("Desync at beat " .. beatNumber .. " tick " .. GetGameTimeSeconds())
    if doesntCare or dialog then
        return
    end

    local dialogContent = Group(GetFrame(0))
    LayoutHelpers.SetDimensions(dialogContent, 400, 320)

    dialog = Popup(GetFrame(0), dialogContent)

    local title = UIUtil.CreateText(dialogContent, "<LOC desync_0000>Desync Detected", 14, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 5)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local infoText = TextArea(dialogContent, 390, 80)
    infoText:SetText(LOC("<LOC desync_0003>"))
    LayoutHelpers.Below(infoText, title)
    LayoutHelpers.AtLeftIn(infoText, dialogContent, 5)

    local subtitle = UIUtil.CreateText(dialogContent, "<LOC desync_0004>Diagnostic Info", 14, UIUtil.titleFont)
    LayoutHelpers.Below(subtitle, infoText, 5)
    LayoutHelpers.AtHorizontalCenterIn(subtitle, dialogContent)

    dialog.diagnosticBox = TextArea(dialogContent, 390, 130)
    dialog.diagnosticBox:SetFont(UIUtil.bodyFont, 10)
    LayoutHelpers.Below(dialog.diagnosticBox, subtitle, 5)
    LayoutHelpers.AtHorizontalCenterIn(dialog.diagnosticBox, dialogContent)

    local dontCare = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', "<LOC desync_0002>Don't tell me any more", true, 11)
    LayoutHelpers.AtBottomIn(dontCare, dialogContent, 15)
    LayoutHelpers.AtLeftIn(dontCare, dialogContent, 5)

    local okBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtHorizontalCenterIn(okBtn, dialogContent)
    LayoutHelpers.AtBottomIn(okBtn, dialogContent, 5)

    okBtn.OnClick = function(self, modifiers)
        dialog:Close()
    end

    dialog.OnClosed = function(self)
        dialog = false
        doesntCare = dontCare:IsChecked()
    end

    for k, v in strings do
        if v then
            dialog.diagnosticBox:AppendLine(v)
        end
    end
    dialog.diagnosticBox:AppendLine(LOC("<LOC desync_0001>Beat-- ") .. tostring(beatNumber))
end
