--*****************************************************************************
--* File: lua/modules/ui/game/construction.lua
--* Author: Chris Blackwell / Ted Snook
--* Summary: Construction management UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Movie = import("/lua/maui/movie.lua").Movie
local Button = import("/lua/maui/button.lua").Button
local GameMain = import("/lua/ui/game/gamemain.lua")

local oldMusicVolume = GetVolume("Music")

local fadeInTime = 2

function OnDemoEnd()
    GameMain.gameUIHidden = true
    SessionRequestPause()
    GetCursor():Hide()
    local bg = Bitmap(GetFrame(0))
    bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    bg:SetSolidColor("black")
    LayoutHelpers.FillParent(bg, GetFrame(0))

    local splash = Bitmap(bg)
    splash:SetTexture(UIUtil.UIFile('/marketing/end_demo_1.dds'))
    LayoutHelpers.FillParentPreserveAspectRatio(splash, GetFrame(0))
    splash:AcquireKeyboardFocus(true)
    splash.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' and event.KeyCode == 27 then
            SetVolume("Music", oldMusicVolume)
            ConExecute("ren_Oblivion false")
            ExitApplication()
        end
    end

    bg:SetNeedsFrameUpdate(true)
    local timeAccum = 0
    bg.OnFrame = function(self, delta)
        local alpha = MATH_Lerp(timeAccum, 0, fadeInTime, 0, 1)
        bg:SetAlpha(alpha)
        splash:SetAlpha(alpha)
        timeAccum = timeAccum + delta
        if timeAccum > fadeInTime then
            bg:SetNeedsFrameUpdate(false)
            ConExecute("ren_Oblivion true")
            SetVolume("Music", 0)
        end        
    end
    
end