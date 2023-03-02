--*****************************************************************************
--* File: lua/modules/ui/menus/common.lua
--* Author: Chris Blackwell
--* Summary: common menu functions
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Button = import("/lua/maui/button.lua").Button
local Tooltip = import("/lua/ui/game/tooltip.lua")

-- Menu background
local background = false
local bgFilespec = false

local backgroundFiles = {
    "/menus02/background-paint01_bmp.dds",
    "/menus02/background-paint02_bmp.dds",
    "/menus02/background-paint03_bmp.dds",
    "/menus02/background-paint04_bmp.dds",
    "/menus02/background-paint05_bmp.dds",
}

-- pick one background per import
local curBackground = nil

function DestroyBackground()
    if background then
        background:Destroy()
        background = false
    end
end

local function CreateBackground(parent, fileSpec, lBorderOverload, rBorderOverload)
    background = Bitmap(parent, UIUtil.SkinnableFile(fileSpec))
    LayoutHelpers.FillParent(background, parent)

    local lborder = Bitmap(background, UIUtil.SkinnableFile(lBorderOverload or '/menus02/borde02b-l_bmp.dds'))
    LayoutHelpers.AtBottomIn(lborder, parent)
    LayoutHelpers.AtLeftIn(lborder, parent)

    local rborder = Bitmap(background, UIUtil.SkinnableFile(rBorderOverload or '/menus/border02-r_bmp.dds'))
    LayoutHelpers.AtTopIn(rborder, parent)
    LayoutHelpers.AtRightIn(rborder, parent)
end

function SetupBackground(parent, lBorderOverload, rBorderOverload)
    DestroyBackground()

    if not curBackground then
        curBackground = math.random(table.getn(backgroundFiles))
    end

    CreateBackground(parent, backgroundFiles[curBackground], lBorderOverload, rBorderOverload)
    return background
end

-- Exit button
function CreateExitMenuButton(parent, over, title, tooltip)
    local exitButton = UIUtil.CreateButtonStd(parent, '/lobby/lan-game-lobby/small-back', title, 16, 0, 0, "UI_Back_MouseDown")
    LayoutHelpers.AtLeftIn(exitButton, parent, 80)
    LayoutHelpers.AtBottomIn(exitButton, parent, 7)
    exitButton.Depth:Set(function() return over.Depth() + 100 end) -- 100 just makes sure it's on top of any extra background art
    if tooltip then
        Tooltip.AddButtonTooltip(exitButton, tooltip)
    end
    return exitButton
end

local ambientSoundHandle = false

function StartMenuAmbientSounds()
    if not ambientSoundHandle then
        ambientSoundHandle = PlaySound(Sound({Cue = "AMB_Menu_Loop", Bank = "AmbientTest",}))
    end
end

-- call this when you're ready to exit menu mode and go in to the game
function MenuCleanup()
    DestroyBackground()
    if ambientSoundHandle then
        StopSound(ambientSoundHandle)
        ambientSoundHandle = false
    end
    import("/lua/ui/uimain.lua").SetEscapeHandler(nil)
end

local profileDlg = nil

function CreateProfileButton(parent, exitBehavior, enterBehavior)
    local profileButton = UIUtil.CreateButtonStd(parent, '/menus/main02/profile-edit', "", 12)
    profileButton.OnRolloverEvent = function(self, event)
    end

    local currentProfileText = UIUtil.CreateText(profileButton, "", 14, UIUtil.bodyFont)
    LayoutHelpers.AtCenterIn(currentProfileText, profileButton)

    function SetNameToCurrentProfile()
        local currentProfile = GetPreference("profile.current")
        if currentProfile then
            local profiles = GetPreference("profile.profiles")
            if profiles[currentProfile] != nil then
                currentProfileText:SetText(profiles[currentProfile].Name)
            else
                SetPreference("profile.current", 0) -- if current profile is damaged, reset to 0
            end
         end
    end

    profileButton.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            Tooltip.CreateMouseoverDisplay(self, "profile", 5, true)
            currentProfileText:SetColor('ff000000')
        elseif event.Type == 'MouseExit' then
            Tooltip.DestroyMouseoverDisplay()
            currentProfileText:SetColor(UIUtil.fontColor())
        end
        Button.HandleEvent(self, event)
    end

    SetNameToCurrentProfile()

    profileButton.OnClick = function(self)
        if enterBehavior then
            enterBehavior()
        end
        if not profileDlg then
            profileDlg = import("/lua/ui/dialogs/profile.lua").CreateDialog(function()
                SetNameToCurrentProfile()
                profileDlg = nil
                if exitBehavior then
                    exitBehavior()
                end
            end)
        end
    end

    return profileButton
end
