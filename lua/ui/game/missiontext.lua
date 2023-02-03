--*****************************************************************************
--* File: lua/modules/ui/game/missiontext.lua
--* Author: Ted Snook
--* Summary: Mission text HUD
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local WrapText = import("/lua/maui/text.lua").WrapText
local Movie = import("/lua/maui/movie.lua").Movie
local GameMain = import("/lua/ui/game/gamemain.lua")

local MISSION_TEXT_TIMEOUT = 10
local missionTextInactivityTime = 11
local videoTextInactivityTime = 11
local resetEconWarnings = false
local movieText = ""
local currentlyPlaying = false
local textHistory = ""
local subtitleThread = false
local videoQueue = {}

local prefix = {
    Cybran = {texture = '/icons/comm_cybran.dds', cue = 'UI_Comm_CYB'},
    Aeon = {texture = '/icons/comm_aeon.dds', cue = 'UI_Comm_AEON'},
    UEF = {texture = '/icons/comm_uef.dds', cue = 'UI_Comm_UEF'},
    Seraphim = {texture = '/icons/comm_seraphim.dds', cue = 'UI_Comm_SER'},
    NONE = {texture = '/icons/comm_allied.dds', cue = 'UI_Comm_UEF'}
}

controls = {
    infoBG = false,
    infoText = false,
    movieTextGroup = false,
    textCursor = false,
    movieGroup = false,
    movieText = {},
    movieGroupBG = false,
    movieTextGroupBGTop = false,
    movieTextGroupBGMiddle = false,
    movieTextGroupBGBottom = false,
}

local preNISMovieGroupSettings = {}
local isNISMode = false

function SetLayout()
    import(UIUtil.GetLayoutFilename('missiontext')).SetLayout()
end

function OnGamePause(paused)
    if controls.movieBrackets then
        controls.movieBrackets:Pause(paused)
    end
end

local currentMovie = false
function PlayMFDMovie(movie, text)
    if not controls.movieBrackets then
        controls.movieBrackets = Bitmap(GetFrame(0), UIUtil.SkinnableFile('/game/transmission/video-brackets.dds'))
        controls.movieBrackets.Height:Set(1)
        controls.movieBrackets.Width:Set(1)
        controls.movieBrackets.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
        controls.movieBrackets:SetNeedsFrameUpdate(true)

        controls.movieBrackets.panel = Bitmap(controls.movieBrackets, UIUtil.SkinnableFile('/game/transmission/video-panel.dds'))
        LayoutHelpers.AtCenterIn(controls.movieBrackets.panel, controls.movieBrackets)
        controls.movieBrackets.panel:SetAlpha(0)

        controls.movieBrackets.cover = Bitmap(controls.movieBrackets, UIUtil.UIFile(prefix[movie[4]].texture))
        LayoutHelpers.SetDimensions(controls.movieBrackets.cover, 190, 190)
        LayoutHelpers.DepthUnderParent(controls.movieBrackets.cover, controls.movieBrackets.panel)
        LayoutHelpers.AtCenterIn(controls.movieBrackets.cover, controls.movieBrackets.panel)
        controls.movieBrackets.cover:SetAlpha(0)

        controls.movieBrackets.movie = Movie(controls.movieBrackets, movie[1])
        LayoutHelpers.SetDimensions(controls.movieBrackets.movie, 190, 190)
        LayoutHelpers.DepthUnderParent(controls.movieBrackets.movie, controls.movieBrackets.panel)
        LayoutHelpers.AtCenterIn(controls.movieBrackets.movie, controls.movieBrackets.panel)
        controls.movieBrackets.movie:SetAlpha(0)

        controls.subtitles = CreateSubtitles(controls.movieBrackets, text[1])

        controls.movieBrackets.movie.OnFinished = function(self)
            if (not controls.movieBrackets.movie:IsLoaded()) and (self.loadCheck == nil) then
                ForkThread(
                function(self, duration, onFinished)
                    WaitSeconds(duration)
                    onFinished(self)
                end, self, GetMovieDuration(movie[1]), controls.movieBrackets.movie.OnFinished)
                self.loadCheck = true
                return
            end
            controls.movieBrackets.panel:SetNeedsFrameUpdate(true)
            controls.movieBrackets.panel.sound = PlaySound(Sound{Bank='Interface', Cue=prefix[movie[4]].cue..'_Out'})
            controls.subtitles:Contract()
            controls.movieBrackets.panel.OnFrame = function(self, delta)
                if controls.movieBrackets._paused then
                    return
                end
                local newAlpha = self:GetAlpha() - (delta * 1.5)
                if newAlpha < 0 then
                    self:SetNeedsFrameUpdate(false)
                    controls.movieBrackets:SetNeedsFrameUpdate(true)
                    controls.movieBrackets.movie:SetAlpha(0)
                    controls.movieBrackets.cover:SetAlpha(0)
                    self:SetAlpha(0)
                else
                    self:SetAlpha(newAlpha)
                    controls.movieBrackets.cover:SetAlpha(newAlpha)
                end
            end
            controls.movieBrackets.OnFrame = function(self, delta)
                if controls.movieBrackets._paused then
                    return
                end
                local finishedHeight = false
                local finishedWidth = false
                local newHeight = math.max(self.Height() - (delta * 800), 1)
                local newWidth = math.max(self.Width() - (delta * 800), 1)
                if newHeight == 1 then
                    finishedHeight = true
                end
                if newWidth == 1 then
                    finishedWidth = true
                end
                self.Height:Set(newHeight)
                self.Width:Set(newWidth)
                if finishedWidth and finishedHeight then
                    self:SetNeedsFrameUpdate(false)
                    controls.movieBrackets:Destroy()
                    controls.movieBrackets = false
                    local entryData = {
                        movie = movie[1],
                        text = text,
                        soundbank = movie[2],
                        soundcue = movie[3],
                        faction = movie[4],
                    }
                    import("/lua/ui/game/transmissionlog.lua").AddEntry(entryData)
                    SimCallback( { Func = "OnMovieFinished", Args = movie[1]} )
                end
            end
        end

        controls.movieBrackets.OnFrame = function(self, delta)
            if controls.movieBrackets._paused then
                return
            end
            local finishedHeight = false
            local finishedWidth = false
            local bitmapHeight = LayoutHelpers.ScaleNumber(self.BitmapHeight())
            local bitmapWidth = LayoutHelpers.ScaleNumber(self.BitmapWidth())
            local newHeight = math.min(self.Height() + (delta * 600), bitmapHeight)
            local newWidth = math.min(self.Width() + (delta * 600), bitmapWidth)
            if newHeight == bitmapHeight then
                finishedHeight = true
            end
            if newWidth == bitmapWidth then
                finishedWidth = true
            end
            self.Height:Set(newHeight)
            self.Width:Set(newWidth)
            if finishedWidth and finishedHeight then
                self:SetNeedsFrameUpdate(false)
                controls.movieBrackets.panel:SetNeedsFrameUpdate(true)
                controls.movieBrackets.panel.sound = PlaySound(Sound{Bank='Interface', Cue=prefix[movie[4]].cue..'_In'})
                controls.subtitles:Expand()
            end
        end

        controls.movieBrackets.panel.OnFrame = function(self, delta)
            if controls.movieBrackets._paused then
                return
            end
            local newAlpha = self:GetAlpha() + (delta * 2)
            if newAlpha > 1 then
                self:SetNeedsFrameUpdate(false)
                controls.movieBrackets.movie:SetAlpha(1)
                controls.movieBrackets.cover:SetAlpha(0)
                self:SetAlpha(1)
                controls.movieBrackets.movie:Play()
                controls.movieBrackets.movie.sound = PlayVoice(Sound{Bank=movie[2], Cue=movie[3]}, true)
            else
                self:SetAlpha(newAlpha)
                controls.movieBrackets.cover:SetAlpha(newAlpha)
            end
        end

        controls.movieBrackets.Pause = function(self, state)
            PauseVoice("VO", state)
            self._paused = state
            if state then
                self.movie:Stop()
            else
                self.movie:Play()
            end
        end

        controls.movieBrackets:DisableHitTest(true)
        SetLayout()
    end
end

function IsHeadPlaying()
    if controls.movieBrackets then
        return true
    else
        return false
    end
end

function CreateSubtitles(parent, text)
    local bg = Bitmap(parent, UIUtil.UIFile('/game/filter-ping-list-panel/panel_brd_m.dds'))

    bg.text = {}
    bg.text[1] = UIUtil.CreateText(bg, '', 12, UIUtil.bodyFont)

    bg.tl = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ul.dds'))
    bg.tm = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_horz_um.dds'))
    bg.tr = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ur.dds'))
    bg.ml = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_l.dds'))
    bg.mr = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_vert_r.dds'))
    bg.bl = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_ll.dds'))
    bg.bm = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lm.dds'))
    bg.br = Bitmap(bg, UIUtil.SkinnableFile('/game/filter-ping-list-panel/panel_brd_lr.dds'))

    bg.tl.Bottom:Set(bg.Top)
    bg.tl.Right:Set(bg.Left)
    bg.tr.Bottom:Set(bg.Top)
    bg.tr.Left:Set(bg.Right)
    bg.bl.Top:Set(bg.Bottom)
    bg.bl.Right:Set(bg.Left)
    bg.br.Top:Set(bg.Bottom)
    bg.br.Left:Set(bg.Right)
    bg.tm.Bottom:Set(bg.Top)
    bg.tm.Left:Set(bg.Left)
    bg.tm.Right:Set(bg.Right)
    bg.bm.Top:Set(bg.Bottom)
    bg.bm.Left:Set(bg.Left)
    bg.bm.Right:Set(bg.Right)
    bg.ml.Right:Set(bg.Left)
    bg.ml.Top:Set(bg.Top)
    bg.ml.Bottom:Set(bg.Bottom)
    bg.mr.Left:Set(bg.Right)
    bg.mr.Top:Set(bg.Top)
    bg.mr.Bottom:Set(bg.Bottom)

    local textWidth = LayoutHelpers.ScaleNumber(300)
    local wrapped = WrapText(LOC(text), textWidth,
        function(curText) return bg.text[1]:GetStringAdvance(curText) end)

    for index, line in wrapped do
        local i = index
        if not bg.text[i] then
            bg.text[i] = UIUtil.CreateText(bg.text[1], '', 12, UIUtil.bodyFont)
            LayoutHelpers.Below(bg.text[i], bg.text[i-1])
        end
        bg.text[i]:SetText(line)
    end

    bg.Top:Set(bg.text[1].Top)
    bg.Left:Set(bg.text[1].Left)
    bg.Width:Set(1)
    bg.Height:Set(function() return table.getsize(bg.text) * bg.text[1].Height() end)

    bg:SetAlpha(0, true)

    bg.Expand = function(control)
        control:SetAlpha(1, true)
        bg.text[1]:SetAlpha(0, true)
        control:SetNeedsFrameUpdate(true)
        control.OnFrame = function(self, delta)
            if parent._paused then
                return
            end
            local newWidth = self.Width() + (delta * 800)
            local finishedWidth = false
            if newWidth > textWidth then
                newWidth = textWidth
                finishedWidth = true
            end
            if finishedWidth then
                bg.text[1]:SetNeedsFrameUpdate(true)
                self:SetNeedsFrameUpdate(false)
            end
            self.Width:Set(newWidth)
        end
        control.text[1].OnFrame = function(self, delta)
            if parent._paused then
                return
            end
            local newAlpha = self:GetAlpha() + (delta * 2)
            if newAlpha > 1 then
                newAlpha = 1
                self:SetNeedsFrameUpdate(false)
            end
            self:SetAlpha(newAlpha, true)
        end
    end

    bg.Contract = function(control)
        control.text[1]:SetNeedsFrameUpdate(true)
        control.OnFrame = function(self, delta)
            if parent._paused then
                return
            end
            local newWidth = self.Width() - (delta * 800)
            local finishedWidth = false
            if newWidth < 1 then
                newWidth = 1
                finishedWidth = true
            end
            if finishedWidth then
                self:SetAlpha(0, true)
                self:SetNeedsFrameUpdate(false)
            end
            self.Width:Set(newWidth)
        end
        control.text[1].OnFrame = function(self, delta)
            if parent._paused then
                return
            end
            local newAlpha = self:GetAlpha() - (delta * 2)
            if newAlpha < 0 then
                newAlpha = 0
                self:SetNeedsFrameUpdate(false)
                bg:SetNeedsFrameUpdate(true)
            end
            self:SetAlpha(newAlpha, true)
        end
    end

    return bg
end

function PauseTransmission()
    if currentMovie then
        currentMovie:Stop()
    end
end

function ResumeTransmission()
    if currentMovie then
        currentMovie:Play()
    end
end

function UpdateQueue()
    if not table.empty(videoQueue) then
        PlayMFDMovie({videoQueue[1][1], videoQueue[1][2], videoQueue[1][3], videoQueue[1][4]}, videoQueue[1][5])
        table.remove(videoQueue, 1)
    end
end

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
            subtitleThread = false
        end
    )
end

local FMVData = {
    uef = {name = 'UEF', voicecue = 'SCX_UEF_Credits_VO', soundcue = 'X_FMV_UEF_Credits'},
    cybran = {name = 'Cybran', voicecue = 'SCX_Cybran_Credits_VO', soundcue = 'X_FMV_Cybran_Credits'},
    aeon = {name = 'Aeon', voicecue = 'SCX_Aeon_Credits_VO', soundcue = 'X_FMV_Aeon_Credits'},
}

function EndGameFMV(faction)
    local setResume = SessionIsPaused()
    SessionRequestPause()
    ConExecute("ren_Oblivion true")
    local parent = GetFrame(0)
    local nisBG = Bitmap(parent)
    nisBG:SetSolidColor('FF000000')
    LayoutHelpers.FillParent(nisBG, parent)
    nisBG.Depth:Set(99998)
    local nis = Movie(parent, "/movies/FMV_SCX_Outro.sfd")
    nis.Depth:Set(99999)
    nis.faction = faction
    nis.stage = 1
    LayoutHelpers.FillParentPreserveAspectRatio(nis, parent)
    nis.voicecue = 'SCX_Outro_VO'
    nis.soundcue = 'X_FMV_Outro'

    GameMain.gameUIHidden = true

    local textArea = ItemList(parent)
    textArea:SetFont(UIUtil.bodyFont, 13)

    local height = 6 * textArea:GetRowHeight()
    textArea.Height:Set( height )
    textArea.Top:Set( function() return nis.Bottom() end )
    textArea.Width:Set( function() return nis.Width() / 2 end )
    LayoutHelpers.AtHorizontalCenterIn(textArea,parent)

    textArea:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  UIUtil.highlightColor)
    textArea.Depth:Set(100000)

    --local strings = import('/tutorials/' .. subtitleKey .. '/' .. subtitleKey .. '.lua')[subtitleKey]
    AddInputCapture(nis)

    local loading = true

    local function SetMovie(filename, soundcue, voicecue)
        nis:Set(filename,
                Sound({Cue = soundcue, Bank = 'FMV_BG'}),
                Sound({Cue = voicecue, Bank = 'X_FMV'}))
    end

    nis.OnLoaded = function(self)
        GetCursor():Hide()
        nis:Play()
        --DisplaySubtitles(textArea, strings.captions)
        loading = false
    end

    function DoExit(onFMVFinished)
        nis:Stop()
        loading = true
        if nis.stage == 1 then
            SetMovie("/movies/Credits_"..FMVData[nis.faction].name..".sfd",
                     FMVData[nis.faction].soundcue,
                     FMVData[nis.faction].voicecue)
        elseif nis.stage == 2 and onFMVFinished then
            SetMovie("/movies/FMV_SCX_Post_Outro.sfd",
                     'X_FMV_Post_Outro',
                     'SCX_Post_Outro_VO')
        else
            GameMain.gameUIHidden = false
            GetCursor():Show()
            if not setResume then
                SessionResume()
            end
            ConExecute("ren_Oblivion")
            if subtitleThread then
                KillThread(subtitleThread)
                subtitleThread = false
            end
            nisBG:Destroy()
            RemoveInputCapture(nis)
            nis:Destroy()
            if textArea then
                textArea:Destroy()
            end
            SimCallback({Func = "OnEndGameFMVFinished"})
        end
        nis.stage = nis.stage + 1
    end

    nis.OnFinished = function(self)
        DoExit(true)
    end

    nis.HandleEvent = function(self, event)
        if loading then
            return false
        end
        -- cancel movie playback on mouse click or key hit
        if event.Type == "ButtonPress" or event.Type == "KeyDown" then
            DoExit()
            return true
        end
    end
end
