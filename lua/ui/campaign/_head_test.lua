--*****************************************************************************
--* File: lua/modules/ui/campaign/_head_test.lua
--* Author: Evan Pongress
--* Summary: temp internal screen to view all head anims w/ sound
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Movie = import("/lua/maui/movie.lua").Movie
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Button = import("/lua/maui/button.lua").Button
local Scrollbar = import("/lua/maui/scrollbar.lua").Scrollbar

function CreateUI()
    local currentOp = nil
    local movTable = {}

    -- parent/background
    local parent = UIUtil.CreateScreenGroup(GetFrame(0), "head test group")
    local background = Bitmap(parent)
    background:SetSolidColor('black')
    LayoutHelpers.FillParent(background, parent)

    -- BACK BUTTON
    local exitButton = MenuCommon.CreateExitMenuButton(parent, background, "<LOC _Back>")
    LayoutHelpers.AtLeftIn(exitButton, parent, 10)
    LayoutHelpers.AtBottomIn(exitButton, parent, 10)
    exitButton.OnClick = function(self, modifiers)
        StopMovie()
        parent:Destroy()
        import("/lua/ui/menus/main.lua").CreateUI()
    end

    -- STOP MOVIE BUTTON
    local stopButton = UIUtil.CreateButtonStd(parent, '/widgets/small', "Stop Movie", 15)
    LayoutHelpers.AtRightIn(stopButton, parent, 10)
    LayoutHelpers.AtBottomIn(stopButton, parent, 10)
    stopButton.Depth:Set(1000)
    stopButton.OnClick = function(self, modifiers)
        StopMovie()
    end

    -- OPERATION LIST
    local opList = ItemList(background, "opList")
    LayoutHelpers.SetWidth(opList, 250)
    opList.Height:Set(function() return parent.Height() - LayoutHelpers.ScaleNumber(70) end)
    LayoutHelpers.AtLeftTopIn(opList, background, 10, 10)
    opList:SetFont(UIUtil.bodyFont, 12)

    -- Load the maps containing '_strings.lua' file
    local scenFiles = DiskFindFiles('/maps', '*_strings.lua')
    for i, fileName in scenFiles do
        local opName = string.gsub(string.match(fileName, '[^/]+$'), '_strings.lua', '')
        opList:AddItem(opName)
    end

    opList.OnClick = function(self, row)
        self:SetSelection(row)
        currentOp = opList:GetItem(row)
        AddMovies(currentOp)
    end

    -- MOVIE LIST
    local movList = ItemList(background, 'movList')
    LayoutHelpers.SetWidth(movList, 300)
    movList.Height:Set(opList.Height)
    LayoutHelpers.AnchorToRight(movList, opList, 10)
    movList.Top:Set(opList.Top)
    movList:SetFont(UIUtil.bodyFont, 12)

    UIUtil.CreateVertScrollbarFor(movList)

    function AddMovies(opName)
        if DiskGetFileInfo('/maps/'..opName..'/'..opName..'_strings.lua') then
            local strings = import('/maps/'..opName..'/'..opName..'_strings.lua')
            movList:DeleteAllItems()
            movTable = {}
            local tempTable = {}
            local cueTable = {}
            for i, v in strings do
                if type(v) == 'table' then
                    if v.movies then -- Briefing data have different structure
                        for movieIndex, movie in v.movies do
                            if DiskGetFileInfo('/movies/'..movie) then
                                table.insert(tempTable,
                                    {
                                        vid = '/movies/'..movie,
                                        cue = v.voice[movieIndex].Cue,
                                        bank = v.voice[movieIndex].Bank,
                                        bgCue = v.bgsound[movieIndex].Cue,
                                        bgBank = v.bgsound[movieIndex].Bank
                                    }
                                )
                            end
                        end
                    else
                        for _, line in v do
                            if line.vid then
                                if line.cue and cueTable[line.cue] then
                                    -- the sort function breaks if there are more duplicates cues, as it using it for sorting the list
                                    -- a lot of the custom missions don't have the cues set properly
                                    WARN("FMV head script: Duplicate cue name, for video: ", i, ": ", line.vid)
                                elseif line.vid ~= '' and DiskGetFileInfo('/movies/'..line.vid) and line.cue and line.cue ~= '' then
                                    table.insert(tempTable, {vid = '/movies/'..line.vid, cue = line.cue, bank = line.bank})
                                    cueTable[line.cue] = true
                                else
                                    WARN("FMV head script: Can't find video! Entry details: ", i, ": ", line.vid)
                                end
                            end
                        end
                    end
                end
            end
            table.sort(tempTable, function(a,b)
                return a.cue <= b.cue
            end)
            for i, v in tempTable do
                movList:AddItem(v.cue)
                movTable[v.cue] = {vid = v.vid, cue = v.cue, bank = v.bank, bgCue = v.bgCue, bgBank = v.bgBank}
            end
        end
    end

    -- movie control
    local movieBack = Bitmap(background)
    LayoutHelpers.SetDimensions(movieBack, 1, 1)
    LayoutHelpers.AtLeftTopIn(movieBack, background)
    movieBack:SetSolidColor('black')
    movieBack.Depth:Set(10)
    
    local movie = Movie(background)
    LayoutHelpers.AtCenterIn(movie, parent)
    movie.Depth:Set(11)
    
    movie.OnFinished = function(self)
        StopMovie()
    end

    -- play movie
    movList.OnClick = function(self, row)
        self:SetSelection(row)
        StopMovie()
        local movID = movList:GetItem(row)
        movie:Set(movTable[movID].vid)

        LayoutHelpers.FillParent(movieBack, movie)

        local sound = Sound( {Cue = movTable[movID].cue, Bank = movTable[movID].bank} )
        local bgSound
        if movTable[movID].bgCue then
            bgSound = Sound( {Cue = movTable[movID].bgCue, Bank = movTable[movID].bgBank} )
        end

        movie:Show()
        movieBack:Show()
        movie.OnLoaded = function(self)
            movie:Play()
            movie.voiceHandle = PlayVoice(sound)
            if bgSound then
                movie.bgHandle = PlaySound(bgSound)
            end
        end
    end

    -- FUNCTIONS
    function StopMovie()
        movie:Stop()
        movie:Hide()
        movieBack:Hide()
        StopSound(movie.voiceHandle, true)
        StopSound(movie.bgHandle, true)
    end
end
