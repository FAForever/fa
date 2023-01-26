--*****************************************************************************
--* File: lua/modules/ui/game/helptext.lua
--* Author: Ted Snook
--* Summary: Help Text Popup
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text
local Button = import("/lua/maui/button.lua").Button
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText
local Prefs = import("/lua/user/prefs.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local MissionText = import("/lua/ui/game/missiontext.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Combo = import("/lua/ui/controls/combo.lua").Combo

function GetHelpFiles()
    local helpFiles = DiskFindFiles('/tutorials', '*.lua')
    --LOG('Help Files:',repr(helpFiles))
    local retTable = {}
    for i, v in helpFiles do
        local temptablename = string.upper(Basename(v, true))
        local tempfile = import(v)
        if tempfile[temptablename] != nil then
            local temptable = tempfile[temptablename]
            temptable['HelpID'] = temptablename
            table.insert(retTable, temptable)
        end
    end
    return retTable
end

local HelpTextStrings = false

local categoryTable = {}
local DEFAULT_ENTRY = 'TUB050'
local currentCat = 'Basic'
local helpPromptQueue = {}
local helpmap = {}
local parent = false
local worldView = import("/lua/ui/game/borders.lua").GetMapGroup()

controls = {
    mainWindowBG = false,
    mainWindowTitle = false,
    mainWindowDescription = false,
    mainWindowImage = false,
    mainWindowHideButton = false,
    helpIcons = {},
    previousButton = false,
    nextButton = false,
    disableButton = false,
    categoryDropDown = false,
    helpList = false,
}


function CreateHelpText(inParent)
    parent = inParent
end

function CreateControls()

    HelpTextStrings = GetHelpFiles()

    if not controls.mainWindowBG then
        controls.mainWindowBG = Bitmap(parent, UIUtil.UIFile('/dialogs/help/panel_bmp.dds'))
        UIUtil.CreateWorldCover(controls.mainWindowBG)
    end
    LayoutHelpers.AtCenterIn(controls.mainWindowBG, GetFrame(0))
    controls.mainWindowBG.Depth:Set(5000)

    if not controls.mainWindowTitle then
        controls.mainWindowTitle = UIUtil.CreateText(controls.mainWindowBG, "<LOC HELPTEXT_0000>Archiva Videographa", 18)
    end
    controls.mainWindowTitle.Left:Set(function() return controls.mainWindowBG.Left() + 64 end)
    controls.mainWindowTitle.Top:Set(function() return controls.mainWindowBG.Top() + 32 end)
    
    if not controls.mainWindowIcon then
        controls.mainWindowIcon = Bitmap(controls.mainWindowBG, UIUtil.UIFile('/dialogs/help/help-sm_btn.dds'))
    end
    LayoutHelpers.AtLeftTopIn(controls.mainWindowIcon, controls.mainWindowBG, 23, 23)

    if not controls.mainWindowDescriptionBG then
        controls.mainWindowDescriptionBG = Group(controls.mainWindowBG)
    end
    controls.mainWindowDescriptionBG.Top:Set(function() return controls.mainWindowBG.Top() + 153 end)
    controls.mainWindowDescriptionBG.Left:Set(function() return controls.mainWindowBG.Left() + 460 end)
    controls.mainWindowDescriptionBG.Right:Set(function() return controls.mainWindowDescription.Left() + 330 end)
    controls.mainWindowDescriptionBG.Bottom:Set(function() return controls.mainWindowBG.Bottom() - 112 end)

    if not controls.mainWindowDescription then
        controls.mainWindowDescription = ItemList(controls.mainWindowDescriptionBG)
    end
    controls.mainWindowDescription.Top:Set(controls.mainWindowDescriptionBG.Top)
    controls.mainWindowDescription.Left:Set(function() return controls.mainWindowDescriptionBG.Left() + 0 end)
    controls.mainWindowDescription.Right:Set(function() return controls.mainWindowDescriptionBG.Right() - 0 end)
    controls.mainWindowDescription.Bottom:Set(controls.mainWindowDescriptionBG.Bottom)
    controls.mainWindowDescription:SetColors(UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor(), UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor()) -- we don't really want selection here so don't differentiate colors
    controls.mainWindowDescription:SetFont(UIUtil.bodyFont, 14)

    if not controls.hiddenText then
        controls.hiddenText = UIUtil.CreateText(parent, "", 14, UIUtil.bodyFont)
    end
    LayoutHelpers.AtLeftTopIn(controls.hiddenText, controls.mainWindowDescription)
    controls.hiddenText:Hide()

    controls.mainWindowDescription.scrollbar = UIUtil.CreateVertScrollbarFor(controls.mainWindowDescription)
    controls.mainWindowDescription.scrollbar.Left:Set(function() return controls.mainWindowDescription.Right() + 8 end)

    if not controls.closeButton then
        controls.closeButton = UIUtil.CreateButtonStd(controls.mainWindowBG, '/widgets/small', LOC("<LOC _Close>Close"), 14)
    end
    controls.closeButton.Right:Set(function() return controls.mainWindowBG.Right() - 45 end)
    controls.closeButton.Bottom:Set(function() return controls.mainWindowBG.Bottom() - 27 end)
    controls.closeButton.OnClick = function(self, modifiers)
        controls.mainWindowBG:Hide()
    end

    controls.categoryDropDown = Combo(controls.mainWindowBG, 14, 20, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.AtLeftTopIn(controls.categoryDropDown, controls.mainWindowBG, 60, 125)
    controls.categoryDropDown.Depth:Set(function() return controls.mainWindowBG.Depth() + 30 end)
    controls.categoryDropDown.Width:Set(382)
    controls.categoryDropDown.Height:Set(20)

    categoryTable = GetCategories()

    local itemArray = {}
    controls.categoryDropDown.keyMap = {}
    for index, val in categoryTable do
        itemArray[index] = val
        controls.categoryDropDown.keyMap[index] = val
    end
    controls.categoryDropDown:AddItems(itemArray, 1)

    controls.categoryDropDown.OnClick = function(self, index, text)
        currentCat = self.keyMap[index]
        PopulateHelpList()
    end

    controls.helpList = ItemList(controls.mainWindowBG)
    controls.helpList:SetFont(UIUtil.bodyFont, 16)
    controls.helpList:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    controls.helpList.Width:Set(352)
    controls.helpList.Height:Set(280)
    LayoutHelpers.AtLeftTopIn(controls.helpList, controls.mainWindowBG, 60, 150)
    --controls.helpList.Depth:Set(200)

    UIUtil.CreateVertScrollbarFor(controls.helpList)
    controls.helpList.OnKeySelect = function(self, row, noSound)
        controls.helpList:SetSelection(row)
        local sound = Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_01'})
        PlaySound(sound)
        OnHelpClick(helpmap[row + 1])
    end
    controls.helpList.OnClick = function(self, row, noSound)
        controls.helpList:SetSelection(row)
        local sound = Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_01'})
        PlaySound(sound)
        OnHelpClick(helpmap[row + 1])
    end
    
    controls.helpList.OnDoubleClick =  function(self, row, noSound)
        controls.helpList:SetSelection(row)
        OnHelpDClick(helpmap[row + 1])
    end

    if not controls.playButton then
        controls.playButton = UIUtil.CreateButtonStd(controls.mainWindowBG, '/widgets/small', LOC("<LOC _Play_Video>Play Video"), 14)
    end
    controls.playButton.Right:Set(function() return controls.closeButton.Left() - 30 end)
    controls.playButton.Bottom:Set(controls.closeButton.Bottom)

    controls.mainWindowBG:Hide()

    if not controls.helpIcon then
        controls.helpIcon = Button(parent,
            UIUtil.UIFile('/dialogs/objective-unit/help-lg_bmp.dds'),
            UIUtil.UIFile('/dialogs/objective-unit/help-lg_bmp_over.dds'),
            UIUtil.UIFile('/dialogs/objective-unit/help-lg_bmp_down.dds'),
            UIUtil.UIFile('/dialogs/objective-unit/help-lg_bmp.dds'))
    end
    controls.helpIcon.OnClick = function(self, modifiers)
        controls.mainWindowBG:Show()
    end
    controls.helpIcon.Depth:Set(function() return parent.Depth() + 40 end)
    controls.helpIcon:Hide()

    currentCat = categoryTable[1]
    PopulateHelpList()
    InitializeDefaults()
    SetLayout()
end

function SetLayout()
    if controls.helpIcon then
        import(UIUtil.GetLayoutFilename('helptext')).SetLayout()
    end
end

function InitializeDefaults()
    local defCategory
    for i, v in HelpTextStrings do
        if v.HelpID == DEFAULT_ENTRY then
            for h, x in categoryTable do
                if x == v.sequence.category then
                    defCategory = h
                    break
                end
            end
            break
        end
    end
    currentCat = categoryTable[defCategory]
    controls.categoryDropDown:SetItem(defCategory)
    PopulateHelpList()
end

function OnHelpDClick(helpdata)
    local string = LOC(helpdata.text)
    controls.mainWindowDescription:DeleteAllItems()
    if string then
        local textBoxWidth = controls.mainWindowDescription.Width()
        local tempTable = import("/lua/maui/text.lua").WrapText(string, textBoxWidth,
        function(text)
            return controls.hiddenText:GetStringAdvance(text)
        end)
        for i, v in tempTable do
            controls.mainWindowDescription:AddItem(v)
        end
    end
    if DiskGetFileInfo('/tutorials/'..helpdata.HelpID..'/'..helpdata.HelpID..'.sfd') then
        MissionText.PlayNIS('/tutorials/'..helpdata.HelpID..'/'..helpdata.HelpID..'.sfd',helpdata.HelpID)
    else
        controls.playButton:Disable()
    end
end

function OnHelpClick(helpdata)
    local string = LOC(helpdata.text)
    controls.mainWindowDescription:DeleteAllItems()
    if string then
        local textBoxWidth = controls.mainWindowDescription.Width()
        local tempTable = import("/lua/maui/text.lua").WrapText(string, textBoxWidth,
        function(text)
            return controls.hiddenText:GetStringAdvance(text)
        end)
        for i, v in tempTable do
            controls.mainWindowDescription:AddItem(v)
        end
    end
    if DiskGetFileInfo('/tutorials/'..helpdata.HelpID..'/'..helpdata.HelpID..'.sfd') then
        controls.playButton:Enable()
        controls.playButton.OnClick = function(self, modifiers)
            MissionText.PlayNIS('/tutorials/'..helpdata.HelpID..'/'..helpdata.HelpID..'.sfd',helpdata.HelpID)
        end
    else
        controls.playButton:Disable()
    end
end

function AddHelpTextPrompt(show)
    if show then
        if not controls.mainWindowBG then
            CreateControls()
        end
        controls.mainWindowBG:Show()
        controls.helpIcon:Show()
    else
        controls.helpIcon:Hide()
    end
end

function PopulateHelpList()
    controls.helpList:DeleteAllItems()
    controls.mainWindowDescription:DeleteAllItems()
    local temphelp = {}
    for i, v in HelpTextStrings do
        local validhelp = false
        local index = i
        if v.sequence.category != nil and v.sequence.category == currentCat then
            validhelp = true
        elseif v.sequence.category == nil and currentCat == 'Uncategorized' then
            validhelp = true
        end
        if validhelp then
            local position = v.sequence.position or 1
            table.insert(temphelp, position, {v, index})
        end
    end
    local count = 1
    for i,v in sortedpairs(temphelp) do
        controls.helpList:AddItem(LOCF("%2d. %s", count, v[1].title))
        helpmap[count] = v[1]
        count = count + 1
    end
    controls.helpList:SetSelection(0)
    OnHelpClick(helpmap[1])
end

function GetCategories()
    local temptable = {}
    for i, v in HelpTextStrings do
        if v.sequence.category != nil then
            local newEntry = true
            for h, x in temptable do
                if x == v.sequence.category then
                    newEntry = false
                    break
                end
            end
            if newEntry then
                table.insert(temptable, v.sequence.category)
            end
        end
    end
    return temptable
end