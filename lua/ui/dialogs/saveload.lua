--*****************************************************************************
--* File: lua/modules/ui/dialogs/saveload.lua
--* Author: Chris Blackwell
--* Summary: Load and save game UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Prefs = import("/lua/user/prefs.lua")
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local FilePicker = import("/lua/ui/controls/filepicker.lua").FilePicker
local IsNISMode = import("/lua/ui/game/gamemain.lua").IsNISMode

local function CreateDialog(over, isLoad, callback, exitBehavior, fileType)
    fileType = fileType or "SaveGame"

    ---------------------------------------------------------------------------
    -- basic layout and operation of dialog
    ---------------------------------------------------------------------------
    local parent = nil
    local background = nil
    if over then
        parent = over
    else
        parent = UIUtil.CreateScreenGroup(GetFrame(0), "Load Game ScreenGroup")
        background = MenuCommon.SetupBackground(GetFrame(0))
    end

    -- don't parent background to screen group so it doesn't get destroyed until we leave the menus
    local exitButton = nil
    if background then
        exitButton = MenuCommon.CreateExitMenuButton(parent, background, "<LOC _Back>")
    end

    local panel = Bitmap(parent, UIUtil.UIFile('/scx_menu/replay/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, parent)

    panel.brackets = UIUtil.CreateDialogBrackets(panel, 43, 25, 43, 25)

    if over then
        panel.Depth:Set(GetFrame(over:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    end

    local worldCover = UIUtil.CreateWorldCover(panel)

    local dlgHead = UIUtil.CreateText(panel, "", 20, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(dlgHead, panel, 35)
    LayoutHelpers.AtHorizontalCenterIn(dlgHead, panel)
    if isLoad then
        dlgHead:SetText(LOC("<LOC uisaveload_0001>Load"))
    else
        dlgHead:SetText(LOC("<LOC uisaveload_0002>Save"))
    end

    local dlgLabel = UIUtil.CreateText(panel, "<LOC uisaveload_0003>Enter or select filename", 16, UIUtil.titleFont)
    LayoutHelpers.AtLeftTopIn(dlgLabel, panel, 52, 83)

    ---------------------------------------------------------------------------
    -- OK and cancel button behaviors
    ---------------------------------------------------------------------------
    local function KillDialog(cancelled)
        if over then
            panel:Destroy()
        else
            parent:Destroy()
        end
        if exitBehavior then
            exitBehavior(cancelled or false)
        end
    end

    panel.cancelButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Cancel>", 14)
    panel.cancelButton.OnClick = function(self, modifiers)
        KillDialog(true)
    end
    local okButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC _Ok>", 14)
    local deleteButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0006>Delete", 14)

    LayoutHelpers.AtLeftTopIn(deleteButton, panel, 15, 505)

    LayoutHelpers.AtRightTopIn(panel.cancelButton, panel, 15, 505)
    LayoutHelpers.LeftOf(okButton, panel.cancelButton, 0)

    panel.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' and event.KeyCode == 127 then
            deleteButton:OnClick()
        end
    end

    UIUtil.MakeInputModal(panel, function() okButton.OnClick(okButton) end, function() panel.cancelButton.OnClick(panel.cancelButton) end)

    if exitButton then
        exitButton.OnClick = function(self, modifiers)
            KillDialog(true)
        end
    end

    local filePicker = FilePicker(panel, fileType, ((not isLoad) or (fileType == "CampaignSave")) , function(control, fileInfo)
        ForkThread(function()
            callback(fileInfo, panel, KillDialog)
        end)
    end)
    LayoutHelpers.AtLeftTopIn(filePicker, panel, 43, 118)
    LayoutHelpers.SetDimensions(filePicker, 595, 362)

    local lastStr = Prefs.GetFromCurrentProfile(fileType)
    if lastStr then
        filePicker:SetFilename(lastStr)
    end

    okButton.OnClick = function(self, modifiers)
        filePicker:DoSelectBehavior()
    end

    deleteButton.OnClick = function(self, modifiers)
        if filePicker:GetBaseName() == '' then
            UIUtil.QuickDialog(panel, "<LOC file_0002>You must select a file to delete first.",
                "<LOC _Ok>", nil,
                nil, nil,
                nil, nil,
                true,
                {worldCover = false, enterButton = 1, escapeButton = 1})
        else
            UIUtil.QuickDialog(panel, "<LOC file_0001>Are you sure you want to move this file to the recycle bin?",
                "<LOC _Yes>", function()
                    if filePicker:GetBaseName() == Prefs.GetFromCurrentProfile(fileType) then
                        Prefs.SetToCurrentProfile(fileType, nil)
                    end
                    RemoveSpecialFile(filePicker:GetProfile(), filePicker:GetBaseName(), fileType)
                    filePicker:SetFilename('')
                    filePicker:RepopulateList()
                end,
                "<LOC _No>", nil,
                nil, nil,
                true,
                {worldCover = false, enterButton = 1, escapeButton = 2})
        end
    end
    return panel
end

local dlg = false

-- these match strings thrown from the engine
local InternalErrors = {
    ['eof'] = "<LOC Engine0027>EOF reached during serialization.",
    ['noread'] = "<LOC Engine0028>Error reading file stream during serialization.",
    ['nowrite'] = "<LOC Engine0026>Error writing data during serialization. Possibly out of disk space.",
}

function CreateSaveDialog(parent, exitBehavior, fileType)
    local function DoSave(fileInfo, lparent, killBehavior)
        local function ExecuteSave()
            if not IsNISMode() then
                local prettyName = Basename(fileInfo.fspec, true)
                Prefs.SetToCurrentProfile(fileType, prettyName)
                local statusStr = "<LOC saveload_0001>Saving game..."
                local status = UIUtil.ShowInfoDialog(lparent, statusStr)
                InternalSaveGame(fileInfo.fspec, prettyName, function(worked, errmsg)
                    status:Destroy()
                    local infoStr
                    if not worked then
                        errmsg = InternalErrors[errmsg] or errmsg
                        infoStr = LOC("<LOC uisaveload_0008>Save failed! ") .. LOC(errmsg)
                        UIUtil.ShowInfoDialog(lparent, infoStr, "<LOC _Ok>")
                    else
                        killBehavior()
                    end
                end)
            end
        end

        if GetSpecialFileInfo(fileInfo.profile, fileInfo.fname, fileInfo.type) then
            UIUtil.QuickDialog(parent, "<LOC filepicker_0004>A file already exists with that name. Are you sure you want to overwrite it?",
                "<LOC _Yes>", function() ExecuteSave() end,
                "<LOC _No>", nil,
                nil, nil,
                true, {worldCover = false, enterButton = 1, escapeButton = 2})
        else
            ExecuteSave()
        end
    end
    dlg = CreateDialog(parent, false, DoSave, exitBehavior, fileType)
end

local SaveErrors = {
    WrongVersion = '<LOC uisaveload_0005>Wrong version for savegame "%s"',
    CantOpen = '<LOC uisaveload_0004>Couldn\'t open savegame "%s"',
    InvalidFormat = '<LOC uisaveload_0006>"%s" is not a valid savegame',
    InternalError = '<LOC uisaveload_0007>Internal error loading savegame "%s": %s',
}

function CreateLoadDialog(parent, exitBehavior, fileType)
    local function DoLoad(fileInfo, lparent, killBehavior)
        SetFrontEndData('NextOpBriefing', nil)
        local worked, error, detail = LoadSavedGame(fileInfo.fspec)
        if not worked then
            UIUtil.ShowInfoDialog(lparent,
                                  -- note - the 'Unknown error...' string below is intentionally not localized because
                                  -- it should never show up.  If it does, add the error string to SaveErrors.
                                  LOCF(SaveErrors[error] or ('Unknown error ' .. repr(error) .. 'loading savegame %s: %s'),
                                       Basename(fileInfo.fspec, true),
                                       InternalErrors[detail] or detail),
                                  "<LOC _Ok>")
        else
            if parent then
                parent:Destroy()
            end
            MenuCommon.MenuCleanup()
        end
    end
    dlg = CreateDialog(parent, true, DoLoad, exitBehavior, fileType)
end

function OnNISBegin()
    if dlg then
        dlg.cancelButton:OnClick()
    end
end