-------------------------------------------------------------------------------
--- File: lua/modules/ui/campaign/campaignmovies.lua
--- Author: Chris Blackwell
--- Summary: Play campaign movies on demand
--- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local WrapText = import("/lua/maui/text.lua").WrapText
local Movie = import("/lua/maui/movie.lua").Movie
local Prefs = import("/lua/user/prefs.lua")

local creditsMovies = {
    uef = 'FMV_UEF_Credits',
    aeon = 'FMV_Aeon_Credits',
    cybran = 'FMV_Cybran_Credits',
}

local subtitleThread = nil

---@param textControl any
---@param captions any
function DisplaySubtitles(textControl,captions)
    subtitleThread = ForkThread(
        function()
            -- Display subtitles
            local lastOff = 0
            for k,v in captions do
                WaitSeconds(v.offset - lastOff)
                textControl:DeleteAllItems()
                locText = LOC(v.text)
                --LOG("Wrap: ",locText)
                local lines = WrapText(locText, textControl.Width(), function(text) return textControl:GetStringAdvance(text) end)
                for i,line in lines do
                    textControl:AddItem(line)
                end
                textControl:ScrollToBottom()
                lastOff = v.offset
            end
        end
    )
end

--- # Call this to play a full screen campaign movie
--- - movieName = name of movie (no directory or extension required)
--- - cueName = name of wavebank cue, if blank then use movieName
--- - over = control to play above (to make sure depth is correct)
--- - exitBehavior = function that will get called when the movie is done playing (optional)
--- - returns `true` if movie played, else `false`
---@param movieName string
---@param over any
---@param exitBehavior any
---@param cue string
---@param voice string
---@return boolean
function PlayCampaignMovie(movieName, over, exitBehavior, cue, voice)

    GetCursor():Hide()

    local subtitleKey = voice

    local parent = UIUtil.CreateScreenGroup(GetFrame(over:GetRootFrame():GetTargetHead()), "Campaign Movie ScreenGroup")
    parent.Depth:Set(function() return over.Depth() + 1 end)
    AddInputCapture(parent)

    local background = Bitmap(parent)
    LayoutHelpers.FillParent(background, parent)
    background:SetSolidColor('black')

    local movie = Movie(background)
    LayoutHelpers.FillParentPreserveAspectRatio(movie, parent)

    movie:DisableHitTest()    -- get clicks to parent group

    -- black background for subtitles (only impacts 16:9 ratio slightly)
    local subtitleBG = Bitmap(movie)

    local textArea = ItemList(subtitleBG)
    textArea:SetFont(UIUtil.bodyFont, 15)
    local height = 4 * textArea:GetRowHeight()
    textArea.Height:Set( height )
    textArea.Top:Set( function() return background.Bottom() - height - 4 end )
    textArea.Width:Set( function() return movie.Width() / 2 end )
    LayoutHelpers.AtHorizontalCenterIn(textArea,parent)
    textArea:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  UIUtil.highlightColor)

    subtitleBG:SetSolidColor('black')
    subtitleBG.Left:Set( function() return parent.Left() end )
    subtitleBG.Top:Set( function() return textArea.Top() end )
    subtitleBG.Height:Set( function() return textArea.Height() end )
    subtitleBG.Width:Set( function() return parent.Width() end )

    local useSubtitles = Prefs.GetOption('subtitles') or not HasLocalizedVO(__language)
    local captions = false
    if useSubtitles then
        local strings = import("/lua/ui/game/vo_fmv.lua")
        for k,v in strings do
            if string.lower(k) == string.lower(subtitleKey) then
                captions = v.captions
                break
            end
        end
    end

    movie.OnLoaded = function(self)
        movie:Play()
        if captions then
            DisplaySubtitles(textArea,captions)
        end
    end

    movie:Set("/movies/" .. movieName .. ".sfd",
          cue != nil and Sound( {Cue = cue, Bank = 'FMV_BG'} ),
          voice != nil and Sound( {Cue = voice, Bank = 'X_FMV'} ))

    local function LeaveMovie()
        GetCursor():Show()
        RemoveInputCapture(parent)
        if subtitleThread then
            KillThread(subtitleThread)
            subtitleThread = false
        end
        movie:Stop()
        movie.OnLoaded = nil
        parent:Destroy()
        if exitBehavior != nil then
            exitBehavior()
        end
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
            LeaveMovie()
            return true
        end
    end

    movie.OnFinished = function(self)
        LeaveMovie()
    end

    return true
end