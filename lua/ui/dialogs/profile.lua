--*****************************************************************************
--* File: lua/modules/ui/dialogs/profile.lua
--* Author: Chris Blackwell
--* Summary: manages user profiles
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Prefs = import("/lua/user/prefs.lua")

function CreateDialog(exitBehavior)
    local function AnyProfilesDefined(parent)
        if not Prefs.ProfilesExist() then
            UIUtil.ShowInfoDialog(parent, "<LOC PROFILE_0008>You must create at least one profile", "<LOC PROFILE_0009>OK")
            return false
        end

        return true
    end
    local tempProfileCurrent = GetPreference("profile.current")
    local tempProfileTable = GetPreference("profile.profiles")

    local panel = Bitmap(GetFrame(0), UIUtil.UIFile('/scx_menu/profile/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, GetFrame(0))
    panel.Depth:Set(100000)

    panel.brackets = UIUtil.CreateDialogBrackets(panel, 43, 32, 43, 30)

    --local worldCover = UIUtil.CreateWorldCover(panel)

    local titleText = UIUtil.CreateText(panel, "<LOC PROFILE_0001>Profile Manager", 24)
    LayoutHelpers.AtTopIn(titleText, panel, 21)
    LayoutHelpers.AtHorizontalCenterIn(titleText, panel)

    local deleteButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0006>Delete", 16, 2)
    Tooltip.AddButtonTooltip(deleteButton, "Profile_delete")

    local optionsButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0012>Options", 16, 2)
    Tooltip.AddButtonTooltip(optionsButton, "mainmenu_options")
    optionsButton.OnClick = function(self, modifiers)
        if not AnyProfilesDefined(panel) then return end
        panel:Hide()
        import("/lua/ui/dialogs/options.lua").CreateDialog(GetFrame(0), function() panel:Show() end)
    end

    local createButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0004>Create", 16, 2)
    Tooltip.AddButtonTooltip(createButton, "Profile_create")

    LayoutHelpers.AtTopIn(optionsButton, panel, 305)
    LayoutHelpers.AtHorizontalCenterIn(optionsButton, panel)
    LayoutHelpers.LeftOf(deleteButton, optionsButton, -15)
    LayoutHelpers.RightOf(createButton, optionsButton, -15)

    local cancelButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0005>Cancel", 16, 2)
    LayoutHelpers.AtTopIn(cancelButton, panel, 365)
    cancelButton.Left:Set(function() return ((panel.Width() / 2) + 10) + panel.Left() end)
    Tooltip.AddButtonTooltip(cancelButton, "Profile_cancel")

    local okButton = UIUtil.CreateButtonStd(panel, '/scx_menu/small-btn/small', "<LOC PROFILE_0007>OK", 16, 2)
    LayoutHelpers.AtTopIn(okButton, panel, 365)
    okButton.Right:Set(function() return ((panel.Width() / 2) - 10) + panel.Left() end)
    Tooltip.AddButtonTooltip(okButton, "Profile_ok")

    local profileListBG = Bitmap(panel)
    profileListBG:SetSolidColor("00569FFF")
    LayoutHelpers.AtLeftTopIn(profileListBG, panel, 26, 72)
    LayoutHelpers.SetDimensions(profileListBG, 500, 234)

    local profileList = ItemList(profileListBG)
    LayoutHelpers.FillParent(profileList, profileListBG)
    profileList:SetFont("Arial Bold", 16)
    profileList:SetColors(UIUtil.fontColor, "00000000", "ff000000",  UIUtil.highlightColor, "ffbcfffe")
    profileList:ShowMouseoverItem(true)
    UIUtil.CreateVertScrollbarFor(profileList)

    function UpdateProfileList()
        profileList:DeleteAllItems()
        local profiles = GetPreference("profile.profiles")

        if Prefs.GetProfileCount() > 1 then
            deleteButton:Enable()
        else
            deleteButton:Disable()
        end

        if not profiles then return end
        for key, value in profiles do
            profileList:AddItem(value.Name)
        end
        local current = GetPreference("profile.current")
        if current then
            profileList:SetSelection(current - 1)
        end
    end

    profileList.OnClick = function(self, row)
        if row < 0 then return end
        profileList:SetSelection(row)
        SetPreference("profile.current", row + 1)

        import("/lua/options/optionslogic.lua").Repopulate()
    end

    createButton.OnClick = function(self)
        panel:Hide()
        CreationDialog(GetFrame(0), function() panel:Show() end)
    end

    cancelButton.OnClick = function(self)
        if not tempProfileTable then
            UIUtil.ShowInfoDialog(panel, "<LOC PROFILE_0008>You must create at least one profile", "<LOC PROFILE_0009>OK")
            return
        end
        if not AnyProfilesDefined(panel) then return end
        SetPreference("profile.current", tempProfileCurrent)
        SetPreference("profile.profiles", tempProfileTable)
        panel:Destroy()
        if exitBehavior then
            exitBehavior()
        end
    end

    deleteButton.OnClick = function(self)
        if Prefs.GetProfileCount() > 1 then
            UIUtil.QuickDialog(panel, "<LOC PROFILE_0000>Are you sure you want to delete this profile?",
                "<LOC _Yes>", function()
                    local current = GetPreference("profile.current")
                    if not current then return end
                    local profiles = GetPreference("profile.profiles")
                    if not profiles then return end
                    local deletedProfileName = profiles[current].Name
                    table.remove(profiles, current)
                    SetPreference("profile.profiles", profiles)
                    SetPreference("profile.current", 1)
                    SavePreferences()
                    UpdateProfileList()

                    UIUtil.QuickDialog(panel, "<LOC PROFILE_0016>Would you like to move all the save game and replay files associated with this profile to the recycle bin?",
                        "<LOC _Yes>", function() RemoveProfileDirectories(deletedProfileName) end,
                        "<LOC _No>", nil,
                        nil, nil,
                        true, {worldCover = false, enterButton = 1, escapeButton = 2})

               end,
           "<LOC _No>", nil,
           nil, nil,
           true, {worldCover = false, enterButton = 1, escapeButton = 2})
        end
    end

    okButton.OnClick = function(self)
        if not AnyProfilesDefined(panel) then return end

        local OptionsLogic = import("/lua/options/optionslogic.lua")

        -- set up a restart dialog in case it's needed
        local function OptionRestartFunc(proceedFunc, cancelFunc)
            UIUtil.QuickDialog(GetFrame(0)
                , "<LOC options_0001>You have modified an option which requires you to restart Forged Alliance. Selecting OK will exit the game, selecting Cancel will revert the option to its prior setting."
                , "<LOC _OK>", proceedFunc
                ,"<LOC _Cancel>", cancelFunc
                , nil, nil
                , true
                , {worldCover = false, enterButton = 1, escapeButton = 2})
        end
        OptionsLogic.SetSummonRestartDialogCallback(OptionRestartFunc)

        -- set up our new options, if any
        local newOptions = OptionsLogic.GetCurrent()
        OptionsLogic.SetCurrent(newOptions, tempProfileTable[tempProfileCurrent].options)

        panel:Destroy()
        if exitBehavior then
            exitBehavior()
        end
    end

    -- if there are any profiles, populate the list and select the current profile
    UpdateProfileList()

    local profiles = GetPreference("profile.profiles")
    local current = GetPreference("profile.current")
    if profiles and current then
        profileList:SetSelection(current - 1)
        if profiles[current] == nil then
            SetPreference("profile.current", 0) -- if current profile is damaged, reset to 0
        end
    end

    local function OnEnterFunc()
        okButton.OnClick(okButton)
    end
    local function OnEscFunc()
        cancelButton.OnClick(cancelButton)
    end
    UIUtil.MakeInputModal(panel, OnEnterFunc, OnEscFunc)

    return panel
end

function CreationDialog(parent, callback)
    local bg = Bitmap(parent, UIUtil.UIFile('/dialogs/dialog/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(bg, parent)
    bg.Depth:Set(function() return parent.Depth() + 10 end)

    local title = UIUtil.CreateText(bg, LOC('<LOC profile_0000>Enter your Name'), 18)
    LayoutHelpers.AtTopIn(title, bg, 30)
    LayoutHelpers.AtHorizontalCenterIn(title, bg)

    local okButton = UIUtil.CreateButtonStd(bg, '/scx_menu/small-btn/small', "<LOC PROFILE_0007>OK", 14, 2)
    LayoutHelpers.AtLeftTopIn(okButton, bg, 20, 90)

    local cancelButton = UIUtil.CreateButtonStd(bg, '/scx_menu/small-btn/small', "<LOC PROFILE_0005>Cancel", 14, 2)
    LayoutHelpers.RightOf(cancelButton, okButton, -10)

    bg.brackets = UIUtil.CreateDialogBrackets(bg, 30, 36, 32, 36, true)

    local nameEdit = Edit(bg)
    LayoutHelpers.AtTopIn(nameEdit, bg, 50)
    LayoutHelpers.AtHorizontalCenterIn(nameEdit, bg)
    LayoutHelpers.SetWidth(nameEdit, 350)
    nameEdit.Height:Set(function() return nameEdit:GetFontHeight() end)
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, "00569FFF", UIUtil.highlightColor, "880085EF", UIUtil.bodyFont, 20, 20)
    nameEdit:AcquireFocus()

    local function DestroyMe()
        bg:Destroy()
        if callback then
            callback()
        end
    end

    okButton.OnClick = function(self)
        local name = nameEdit:GetText()
        local profiles = GetPreference("profile.profiles")
        if name == "" then
            nameEdit:AbandonFocus()
            UIUtil.ShowInfoDialog(bg, "<LOC PROFILE_0010>Please fill in a profile name", "<LOC PROFILE_0011>OK", function() nameEdit:AcquireFocus() end)
            return
        else
            -- since the profile name will make a directory for save games and replays, it needs to be validated
            local filepicker = import("/lua/ui/controls/filepicker.lua")
            local err = filepicker.IsFilenameInvalid(name)

            if err == 'invalidchars' or err == 'invalidlast' or err == 'invalidname' then
                nameEdit:AbandonFocus()
                UIUtil.ShowInfoDialog(bg, "<LOC PROFILE_0017>Profile names can not begin or end with a space, be a reserved windows file name, or contain the characters \\ / : * ? < > | \" ' .", "<LOC PROFILE_0011>OK", function() nameEdit:AcquireFocus() end)
                return
            end

            if profiles then
                for key, value in profiles do
                    if string.lower(value.Name) == string.lower(name) then
                        nameEdit:AbandonFocus()
                        UIUtil.ShowInfoDialog(bg, "<LOC PROFILE_0014>That name is already in use", "<LOC PROFILE_0011>OK", function() nameEdit:AcquireFocus() end)
                        return
                    end
                end
            end
        end

        if not Prefs.CreateProfile(name) then
            nameEdit:AbandonFocus()
            UIUtil.ShowInfoDialog(bg, "<LOC PROFILE_0013>That name is already in use", "<LOC PROFILE_0011>OK", function() nameEdit:AcquireFocus() end)
            return
        end

        UpdateProfileList()
        DestroyMe()
    end

    cancelButton.OnClick = function(self)
        DestroyMe()
    end

    nameEdit.OnEnterPressed = function(self, text)
        okButton:OnClick()
        return true
    end

    nameEdit.OnEscPressed = function(self, text)
        cancelButton.OnClick(cancelButton)
        return false
    end

    -- don't allow tabs, they screw up multiplayer
    nameEdit.OnCharPressed = function(self, charcode)
        if charcode == UIUtil.VK_TAB then
            return true
        end
        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    local function OnEnterFunc()
        okButton.OnClick(okButton)
    end
    local function OnEscFunc()
        cancelButton.OnClick(cancelButton)
    end
    UIUtil.MakeInputModal(bg, OnEnterFunc, OnEscFunc)
end

-- kept for mod backwards compatibility
local Button = import("/lua/maui/button.lua").Button