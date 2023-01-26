--*****************************************************************************
--* File: lua/modules/ui/splash/splash.lua
--* Author: Chris Blackwell
--* Summary: create and control pre-game splash screens
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Movie = import("/lua/maui/movie.lua").Movie


local movies = {
    { "/movies/thqlogo.sfd", {Cue = 'THQ_Logo', Bank = 'FMV_BG'} },
    { "/movies/gpglogo.sfd", {Cue = 'GPG_introLogo_HD', Bank = 'FMV_BG' } },
    { "/movies/nvidia_logo.sfd", {Cue = 'NVIDIA', Bank = 'FMV_BG' } },
    { "/movies/fmv_scx_intro.sfd", {Cue = 'X_FMV_Intro', Bank = 'FMV_BG' }, {Cue = 'SCX_INTRO_VO', Bank = 'X_FMV' } }
}

function CreateUI()
    if GetPreference("movie.nologo") or HasCommandLineArg("/nomovie") then
        EngineStartFrontEndUI()
        return
    end
    
    GetCursor():Hide()

    local parent = UIUtil.CreateScreenGroup(GetFrame(0), "Splash ScreenGroup")
    AddInputCapture(parent)
    
    local movie = Movie(parent)
    LayoutHelpers.FillParentPreserveAspectRatio(movie, parent)
    movie:DisableHitTest()    -- get clicks to parent group

    movie.OnLoaded = movie.Play

    local currentMovie

    local function StartMovie(index)
        currentMovie = index
        local info = movies[index]
        local sound = info[2]
        local voice = info[3]
        movie:Set(info[1], sound and Sound(sound), voice and Sound(voice))
    end

    local function LeaveSplashScreen()
        RemoveInputCapture(parent)
        parent:Destroy()
        EngineStartFrontEndUI()
        GetCursor():Show()
    end

    parent.HandleEvent = function(self, event)
        -- cancel movie playback on mouse click or key hit
        if event.Type == "ButtonPress" or event.Type == "KeyDown" then
            if event.KeyCode then
                if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == UIUtil.VK_SPACE or event.KeyCode == 1  or event.KeyCode == 3 then
                else
                    return true
                end
            end 
            movie:Stop()
            if currentMovie < table.getn(movies) then
                StartMovie(table.getn(movies))
            else
                LeaveSplashScreen()
            end
            
            return true
        end
    end

    movie.OnFinished = function(self)
        movie:Stop()
        if currentMovie < table.getn(movies) then
            StartMovie(currentMovie + 1)
        else
            LeaveSplashScreen()
        end
    end

    StartMovie(1)
end
