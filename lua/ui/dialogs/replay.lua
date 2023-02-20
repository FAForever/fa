--*****************************************************************************
--* File: lua/modules/ui/dialogs/replay.lua
--* Author: Chris Blackwell
--* Summary: Allows you to choose replays
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local FilePicker = import("/lua/ui/controls/filepicker.lua").FilePicker

local forbiddenSaveNames = {
    [LOC("<LOC Engine0030>")] = true,   -- LastGame forbidden
}

function CreateDialog(over, isLoad, exitBehavior)
    ---------------------------------------------------------------------------
    -- basic layout and operation of dialog
    ---------------------------------------------------------------------------

	local parent = over

    local panel = Bitmap(parent, UIUtil.UIFile('/scx_menu/replay/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, parent)

    panel.brackets = UIUtil.CreateDialogBrackets(panel, 43, 25, 43, 25)

    panel.Depth:Set(GetFrame(over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)

    local worldCover = UIUtil.CreateWorldCover(panel)

    local titleString
    if isLoad then
        titleString = "<LOC uireplay_0001>Replay"
    else
        titleString = "<LOC uireplay_0003>Save Replay"
    end

    local dlgHead = UIUtil.CreateText(panel, titleString, 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(dlgHead, panel, 35)
    LayoutHelpers.AtHorizontalCenterIn(dlgHead, panel)

    local dlgLabel = UIUtil.CreateText(panel, "<LOC uireplay_0002>Enter or select a name", 16, UIUtil.titleFont)
    LayoutHelpers.AtLeftTopIn(dlgLabel, panel, 52, 83)

    ---------------------------------------------------------------------------
    -- OK and cancel button behaviors
    ---------------------------------------------------------------------------
    local function KillDialog()
        panel:Destroy()
        if exitBehavior then
            exitBehavior()
        end
    end

    function DoReplaySave(profile, base)
        CopyCurrentReplay(profile, base)
    end

    function DoReplayLaunch(filename)
        if LaunchReplaySession(filename) == true then
            SetFrontEndData('replay_filename', filename)
            parent:Destroy()
            MenuCommon.MenuCleanup()
        else
            UIUtil.ShowInfoDialog(parent, LOCF("<LOC REPLAY_0000>Unable to launch replay: %s", Basename(filename, true)), "<LOC _Ok>")
        end
    end

    local filePicker = FilePicker(panel, "Replay", (not isLoad), function(control, fileInfo)
        if isLoad then
            DoReplayLaunch(fileInfo.fspec)
        else
            local function ExecuteSave()
                DoReplaySave(control:GetProfile(), control:GetBaseName())
                KillDialog()
            end
            if forbiddenSaveNames[string.lower(control:GetBaseName())] then
                UIUtil.ShowInfoDialog(parent, LOCF("<LOC filepicker_0005>The file %s is protected and can not be overwritten.", control:GetBaseName()), "<LOC _Ok>")
            elseif GetSpecialFileInfo(fileInfo.profile, fileInfo.fname, fileInfo.type) then
                UIUtil.QuickDialog(parent, "<LOC filepicker_0003>A file already exits with that name. Are you sure you want to overwrite it?",
                "<LOC _Yes>", function() ExecuteSave() end,
                "<LOC _No>", nil,
                nil, nil,
                true, {worldCover = false, enterButton = 1, escapeButton = 2})
            else
                ExecuteSave()
            end
        end
    end)
    LayoutHelpers.AtLeftTopIn(filePicker, panel, 43, 118)
    LayoutHelpers.SetDimensions(filePicker, 595, 362)

    local cancelBtn = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Cancel>", 14, 0, nil, "UI_Menu_Cancel_02")
    cancelBtn.OnClick = function(self, modifiers)
        KillDialog()
    end

    local okBtn = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Ok>", 14, 0, nil, "UI_Opt_Yes_No")
    okBtn.OnClick = function(self, modifiers)
        filePicker:DoSelectBehavior()
    end

    local deleteButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0006>Delete", 14)
    deleteButton.OnClick = function(self, modifiers)
        if filePicker:GetBaseName() == '' then
            UIUtil.QuickDialog(panel, "<LOC file_0002>You must select a file to delete first.",
                "<LOC _Ok>", nil,
                nil, nil,
                nil, nil,
                true,
                {worldCover = false, enterButton = 1, escapeButton = 1})
        else
            UIUtil.QuickDialog(panel, "<LOC file_0000>Are you sure you want to move this file to the recycle bin?",
                "<LOC _Yes>", function()
                    RemoveSpecialFile(filePicker:GetProfile(), filePicker:GetBaseName(), "Replay")
                    filePicker:SetFilename('')
                    filePicker:RepopulateList()
                end,
                "<LOC _No>", nil,
                nil, nil,
                true,
                {worldCover = false, enterButton = 1, escapeButton = 2})
        end
    end

    LayoutHelpers.AtLeftTopIn(deleteButton, panel, 15, 505)

    LayoutHelpers.AtRightTopIn(cancelBtn, panel, 15, 505)
    LayoutHelpers.LeftOf(okBtn, cancelBtn, 0)

    UIUtil.MakeInputModal(panel, function() okBtn.OnClick(okBtn) end, function() cancelBtn.OnClick(cancelBtn) end)

end
