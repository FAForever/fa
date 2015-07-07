--*****************************************************************************
--* File: lua/modules/ui/game/rename.lua
--* Author: Chris Blackwell
--* Summary: Rename dialog
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Edit = import('/lua/maui/edit.lua').Edit

local dialog = false

function ShowRenameDialog(currentName)
    -- Dialog already showing? Don't show another one
    if dialog then return end

    local mapGroup = import('/lua/ui/game/borders.lua').GetMapGroup()

    dialog = Bitmap(mapGroup, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Rename Dialog")
    LayoutHelpers.AtCenterIn(dialog, mapGroup)
    
    dialog.brackets = UIUtil.CreateDialogBrackets(dialog, 30, 36, 30, 34, true)
    
    local nameEdit = Edit(dialog)
    
    local label = UIUtil.CreateText(dialog, "<LOC RENAME_0000>Enter New Name", 16, UIUtil.buttonFont)
    label.Top:Set(function() return dialog.Top() + 30 end)
    label.Left:Set(function() return dialog.Left() + 35 end)
    
    local function NameUnit()
        local newName = nameEdit:GetText()
        if (newName ~= nil) then
            GetSelectedUnits()[1]:SetCustomName(newName)
        end
    end
    
    local resetButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _Reset>", 14, 2)
    local cancelButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', "<LOC _CANCEL>", 14, 2)
    local okButton = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', LOC("<LOC _OK>"), 14, 2)
    
    resetButton.OnClick = function(self, modifiers)
        nameEdit:SetText('')
        NameUnit()
        dialog:Destroy()
        dialog = false
    end
    
    cancelButton.OnClick = function(self, modifiers)
        dialog:Destroy()
        dialog = false
    end
    
    okButton.OnClick = function(self, modifiers)
        NameUnit()
        dialog:Destroy()
        dialog = false
    end

    LayoutHelpers.AtTopIn(okButton, dialog, 90)
    LayoutHelpers.AtHorizontalCenterIn(okButton, dialog)
    
    LayoutHelpers.LeftOf(resetButton, okButton)
    LayoutHelpers.RightOf(cancelButton, okButton)
    
    LayoutHelpers.AtLeftTopIn(nameEdit, dialog, 35, 60)
    nameEdit.Width:Set(283)
    nameEdit.Height:Set(nameEdit:GetFontHeight())
    nameEdit:ShowBackground(false)
    nameEdit:AcquireFocus()
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

    local firstTime = true

    nameEdit.OnEnterPressed = function(self, text)    
        NameUnit()
        dialog:Destroy()
        dialog = false
        return true
    end

    dialog:SetNeedsFrameUpdate(true)
    dialog.OnFrame = function(self, elapsedTime)
        -- this works around the fact that wxWindows processes keys and then generates a wmChar message
        -- so if you don't set the text you'll see the hotkey that made this dialog
        if firstTime then
            nameEdit:SetText(currentName)
            firstTime = false
        end
    end



end
