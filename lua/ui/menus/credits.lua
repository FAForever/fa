--*****************************************************************************
--* File: lua/modules/ui/menus/credits.lua
--* Author: Chris Blackwell
--* Summary: Plays the credits
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Movie = import("/lua/maui/movie.lua").Movie
local MenuCommon = import("/lua/ui/menus/menucommon.lua")

-- TODO: add credits music if any
function CreateDialog(exitBehavior)
    if SessionIsActive() then
        SessionRequestPause()
        ConExecute("ren_Oblivion")
    end

    local parent = Group(GetFrame(0))
    LayoutHelpers.FillParent(parent, GetFrame(0))
    parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    
    local worldCover = UIUtil.CreateWorldCover(parent)

    local creditsMovie = Movie(parent, "/movies/credits_generic.sfd", Sound({Bank = 'FMV_BG', Cue = 'Menu_Credits'}))

    local function ExitDialog()
        parent:Destroy()
        if SessionIsActive() then
            ConExecute("ren_Oblivion")
        end
        if exitBehavior then
            exitBehavior()
        end
    end

    LayoutHelpers.FillParentPreserveAspectRatio(creditsMovie, parent)
    creditsMovie.OnLoaded = function(self)
        creditsMovie:Play()
    end
    creditsMovie.OnFinished = function(self)
        ExitDialog()
    end
    
    UIUtil.MakeInputModal(creditsMovie)
    
    creditsMovie.HandleEvent = function(self, event)
        -- cancel movie playback on mouse click or key hit
        if event.Type == "ButtonPress" or event.Type == "KeyDown" then
            if event.KeyCode then
                if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == UIUtil.VK_SPACE or event.KeyCode == 1  or event.KeyCode == 3 then
                else
                    return true
                end
            end 
            ExitDialog()
            return true
        end
    end
end
