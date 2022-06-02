--*****************************************************************************
--* File: lua/modules/ui/campaign/_head_test.lua
--* Author: Evan Pongress
--* Summary: temp internal screen to view all head anims w/ sound
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Movie = import('/lua/maui/movie.lua').Movie
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local Button = import('/lua/maui/button.lua').Button
local Scrollbar = import('/lua/maui/scrollbar.lua').Scrollbar

function CreateUI()

	local opTable = {
		{ 'X1CA_TUT', 'X1CA_001', 'X1CA_002', 'X1CA_003', 'X1CA_004', 'X1CA_005', 'X1CA_006' },
	}
	local currentOp = nil
	local movTable = {}

	# parent/background
	local parent = UIUtil.CreateScreenGroup(GetFrame(0), "head test group")
	local background = Bitmap(parent)
	background:SetSolidColor('black')
	LayoutHelpers.FillParent(background, parent)

	# BACK BUTTON
	local exitButton = MenuCommon.CreateExitMenuButton(parent, background, "<LOC _Back>")
	LayoutHelpers.AtLeftIn(exitButton, parent, 10)
	LayoutHelpers.AtBottomIn(exitButton, parent, 10)
    exitButton.OnClick = function(self, modifiers)
    	StopMovie()
        parent:Destroy()
        import('../menus/main.lua').CreateUI()
    end

	# STOP MOVIE BUTTON
	local stopButton = UIUtil.CreateButtonStd(parent, '/widgets/small', "Stop Movie", 15)
	LayoutHelpers.AtRightIn(stopButton, parent, 10)
	LayoutHelpers.AtBottomIn(stopButton, parent, 10)
	stopButton.Depth:Set(1000)
    stopButton.OnClick = function(self, modifiers)
    	StopMovie()
    end

	# OPERATION LIST
	local opList = ItemList(background, "opList")
	opList.Width:Set(100)
	opList.Height:Set(function() return parent.Height() - 70 end)
	LayoutHelpers.AtLeftTopIn(opList, background, 10, 10)

	for k, v in opTable do
		for k2, v2 in v do
			opList:AddItem(v2)
		end
	end

	opList.OnClick = function(self, row)
		self:SetSelection(row)
		currentOp = opList:GetItem(row)
		AddMovies(currentOp)
		#LOG('currentOp = ' , currentOp)
	end

	# MOVIE LIST
	local movList = ItemList(background, 'movList')
	movList.Width:Set(250)
	movList.Height:Set(opList.Height)
	movList.Left:Set(function() return opList.Right() + 10 end)
	movList.Top:Set(opList.Top)
	movList:SetFont(UIUtil.bodyFont, 14)

	CreateVertScrollbarFor(movList)

	function AddMovies(opName)
	    if DiskGetFileInfo('/maps/'..opName..'/'..opName..'_strings.lua') then
	        local strings = import('/maps/'..opName..'/'..opName..'_strings.lua')
		    movList:DeleteAllItems()
		    movTable = {}
		    local tempTable = {}
		    for i, v in strings do
		        if type(v) == 'table' then
		            for _, line in v do
		                if line.vid then
		                    if DiskGetFileInfo('/movies/'..line.vid) then
		                        table.insert(tempTable, {vid = '/movies/'..line.vid, cue = line.cue, bank = line.bank})
		                    else
		                        WARN("FMV head script: Can't find video! Entry details: ", i, ": ", line.vid)
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
                movTable[v.cue] = {vid = v.vid, cue = v.cue, bank = v.bank}
		    end
		end
	end

	# movie control
	local movieBack = Bitmap(background)
	movieBack.Width:Set(1)
	movieBack.Height:Set(1)
	LayoutHelpers.AtLeftTopIn(movieBack, background)
	movieBack:SetSolidColor('black')
	movieBack.Depth:Set(10)
	
	local movie = Movie(background)
	LayoutHelpers.AtCenterIn(movie, parent)
	movie.Depth:Set(11)
	
	movie.OnFinished = function(self)
		StopMovie()
	end

	# play movie
	movList.OnClick = function(self, row)
		self:SetSelection(row)
		StopMovie()
		local movID = movList:GetItem(row)
		movie:Set(movTable[movID].vid)

		LayoutHelpers.FillParent(movieBack, movie)

		local sound = Sound( {Cue = movTable[movID].cue, Bank = movTable[movID].bank} )
		movie:Show()
		movieBack:Show()
		movie.OnLoaded = function(self)
			movie:Play()
			movie.voiceHandle = PlayVoice(sound)
		end
	end

	# FUNCTIONS
	function StopMovie()
		movie:Stop()
		movie:Hide()
		movieBack:Hide()
		StopSound(movie.voiceHandle,true)
	end
end

function CreateVertScrollbarFor(attachto)
    local tempfaction = ""
    local scrollbar = Scrollbar(attachto, import('/lua/maui/scrollbar.lua').ScrollAxis.Vert)
    scrollbar:SetTextures(  UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/back_scr_mid.dds')
                            ,UIUtil.UIFile('/small-vert_scroll/bar-mid_scr_over.dds')
                            ,UIUtil.UIFile('/small-vert_scroll/bar-top_scr_up.dds')
                            ,UIUtil.UIFile('/small-vert_scroll/bar-bot_scr_up.dds'))

    local scrollUpButton = Button(  scrollbar
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-up_scr_up.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-up_scr_over.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-up_scr_down.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-up_scr_dis.dds'))

    local scrollDownButton = Button(  scrollbar
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-down_scr_up.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-down_scr_over.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-down_scr_down.dds')
                                    , UIUtil.UIFile('/small-vert_scroll'..tempfaction..'/arrow-down_scr_dis.dds'))

    scrollbar.Left:Set(function() return attachto.Right() end)
    scrollbar.Top:Set(scrollUpButton.Bottom)
    scrollbar.Bottom:Set(scrollDownButton.Top)

    scrollUpButton.Left:Set(scrollbar.Left)
    scrollUpButton.Top:Set(function() return attachto.Top() end)
    scrollDownButton.Left:Set(scrollbar.Left)
    scrollDownButton.Bottom:Set(function() return attachto.Bottom() end)

    scrollbar.Right:Set(scrollUpButton.Right)

    scrollbar:AddButtons(scrollUpButton, scrollDownButton)
    scrollbar:SetScrollable(attachto)

    return scrollbar
end