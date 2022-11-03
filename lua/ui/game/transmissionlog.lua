--*****************************************************************************
--* File: lua/modules/ui/game/transmissionlog.lua
--* Author: Ted Snook
--* Summary: Transmission log
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local WinMgr = import("/lua/ui/game/windowmanager.lua")
local WIN_ID = 'Transmission_Log'

-- Possible LOC tag for the future
-- "<LOC _Technology>Technology"
-- <LOC trans_log_0000>Transmission Log
-- <LOC trans_log_0001>No entries
-- <LOC trans_log_0002>%d - %d of %d entries
local controls = {
    bg = false,
    logContainer = false,
    logEntries = {},
    wc = false,
}

local LogData = {}
local loadData = nil
local transmissionHistory = {}
local transmissionIndex = 0
local displayIndex = 1

function CreateTransmissionLog()
    controls.bg = Bitmap(GetFrame(0), UIUtil.UIFile('/dialogs/transmision-log/panel_bmp.dds'))
    controls.bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    LayoutHelpers.AtCenterIn(controls.bg, GetFrame(0))

    controls.closeBtn = UIUtil.CreateButtonStd(controls.bg, "/widgets02/small", "<LOC _Close>", 16)
    LayoutHelpers.AtRightBottomIn(controls.closeBtn, controls.bg, 70, 28)
    controls.closeBtn.OnClick = function(self, modifiers)
        ToggleTransmissionLog()
    end

    -- note this will only get called when the bg has input mode
    controls.bg.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 344 then
                controls.closeBtn:OnClick()
            end
        end
    end

    controls.logContainer = Group(controls.bg)
    LayoutHelpers.SetDimensions(controls.logContainer, 752, 330)
    controls.logContainer.top = 1

    controls.title = UIUtil.CreateText(controls.bg, LOC('<LOC trans_log_0000>Transmission Log'), 20)
    LayoutHelpers.AtLeftTopIn(controls.title, controls.bg, 35, 30)

    LayoutHelpers.AtLeftTopIn(controls.logContainer, controls.bg, 55, 100)
    UIUtil.CreateVertScrollbarFor(controls.logContainer)

    controls.logEntries[1] = {}
    controls.logEntries[1].bg = Bitmap(controls.logContainer)

    controls.logEntries[1].time = UIUtil.CreateText(controls.logEntries[1].bg, '', 14, "Arial")
    LayoutHelpers.AtLeftTopIn(controls.logEntries[1].time, controls.logContainer)
    LayoutHelpers.SetWidth(controls.logEntries[1].time, 60)

    controls.logEntries[1].name = UIUtil.CreateText(controls.logEntries[1].bg, '', 14, "Arial")

    controls.logEntries[1].text = UIUtil.CreateText(controls.logEntries[1].bg, '', 14, "Arial")
    LayoutHelpers.AtRightTopIn(controls.logEntries[1].text, controls.logContainer)
    controls.logEntries[1].text.Width:Set(function() return controls.logContainer.Width() - LayoutHelpers.ScaleNumber(170) end)

    controls.logEntries[1].bg.Top:Set(controls.logEntries[1].time.Top)
    LayoutHelpers.AtLeftIn(controls.logEntries[1].bg, controls.logContainer, -10)
    controls.logEntries[1].bg.Right:Set(controls.logContainer.Right)
    controls.logEntries[1].bg.Bottom:Set(controls.logEntries[1].time.Bottom)
    controls.logEntries[1].bg:SetSolidColor('00000000')

    LayoutHelpers.LeftOf(controls.logEntries[1].name, controls.logEntries[1].text, 15)
    controls.logEntries[1].name.Left:Set(controls.logEntries[1].time.Right)
    controls.logEntries[1].name:SetClipToWidth(true)

    local index = 2
    while controls.logEntries[table.getsize(controls.logEntries)].time.Bottom() + controls.logEntries[1].time.Height() < controls.logContainer.Bottom() do
        controls.logEntries[index] = {}
        controls.logEntries[index].bg = Bitmap(controls.logContainer)

        controls.logEntries[index].time = UIUtil.CreateText(controls.logEntries[index].bg, '', 14, "Arial")
        LayoutHelpers.Below(controls.logEntries[index].time, controls.logEntries[index-1].time)
        LayoutHelpers.SetWidth(controls.logEntries[index].time, 60)

        controls.logEntries[index].name = UIUtil.CreateText(controls.logEntries[index].bg, '', 14, "Arial")

        controls.logEntries[index].text = UIUtil.CreateText(controls.logEntries[index].bg, '', 14, "Arial")
        LayoutHelpers.Below(controls.logEntries[index].text, controls.logEntries[index-1].text)

        LayoutHelpers.LeftOf(controls.logEntries[index].name, controls.logEntries[index].text, 15)

        controls.logEntries[index].name.Left:Set(controls.logEntries[index].time.Right)
        controls.logEntries[index].name:SetClipToWidth(true)

        controls.logEntries[index].bg.Top:Set(controls.logEntries[index].time.Top)
        LayoutHelpers.AtLeftIn(controls.logEntries[index].bg, controls.logContainer, -5)
        controls.logEntries[index].bg.Right:Set(controls.logContainer.Right)
        controls.logEntries[index].bg.Bottom:Set(controls.logEntries[index].time.Bottom)
        controls.logEntries[index].bg:SetSolidColor('00000000')
        index = index + 1
    end

    local numLines = table.getsize(controls.logEntries)
    local prevtabsize = 0
    local prevsize = 0


    local function DataSize()
        if prevtabsize ~= table.getn(LogData) then
            local size = 1
            for i, v in LogData do
                size = size + table.getn(v.text)
            end
            prevtabsize = table.getn(LogData)
            prevsize = size
            return size
        else
            return prevsize
        end
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    controls.logContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 1, size, self.top, math.min(self.top + numLines, size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    controls.logContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    controls.logContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines)
    end

    -- called when the scrollbar wants to set a new visible top line
    controls.logContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines , top), 1)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    controls.logContainer.IsScrollable = function(self, axis)
        return true
    end

    -- determines what controls should be visible or not
    controls.logContainer.CalcVisible = function(self)
        local maxLines = table.getn(controls.logEntries)
        local size = 0
        for i, v in LogData do
            if size + table.getn(v.text) < self.top then
                size = size + table.getn(v.text)
            else
                local currentDataLine = 0
                while size < self.top do
                    currentDataLine = currentDataLine + 1
                    size = size + 1
                end
                local currentLine = 1
                local currentEntry = i
                while currentLine <= table.getn(controls.logEntries) do
                    if LogData[currentEntry].text[currentDataLine] then
                        if currentDataLine == 1 then
                            controls.logEntries[currentLine].name:SetText(LogData[currentEntry].name)
                            controls.logEntries[currentLine].time:SetText(LogData[currentEntry].time)
                        else
                            controls.logEntries[currentLine].name:SetText('')
                            controls.logEntries[currentLine].time:SetText('')
                        end
                        controls.logEntries[currentLine].text:SetText(LogData[currentEntry].text[currentDataLine] or "")
                        currentDataLine = currentDataLine + 1
                    else
                        currentDataLine = 1
                        currentEntry = currentEntry + 1
                        if controls.logEntries[currentLine] and LogData[currentEntry] then
                            controls.logEntries[currentLine].name:SetText(LogData[currentEntry].name)
                            controls.logEntries[currentLine].time:SetText(LogData[currentEntry].time)
                            controls.logEntries[currentLine].text:SetText(LogData[currentEntry].text[currentDataLine] or "")
                        end
                        currentDataLine = currentDataLine + 1
                    end
                    if LogData[currentEntry] then
                        SetColors(controls.logEntries[currentLine], LogData[currentEntry].color, math.mod(currentEntry, 2))
                    end
                    currentLine = currentLine + 1
                end
                break
            end
        end
    end

    controls.bg:Hide()
    if loadData then
        FormatLoadData()
    end
    WinMgr.AddWindow({id = WIN_ID, closeFunc = ToggleTransmissionLog})
end

function SetColors(control, color, entryColor)
    if entryColor == 1 then
        control.bg:SetSolidColor('ff000000')
    else
        control.bg:SetSolidColor('ff202020')
    end
    control.name:SetColor(color)
    control.text:SetColor(color)
end

function ToggleTransmissionLog()
    if controls.bg then
        controls.bg:SetHidden(not controls.bg:IsHidden())
        if controls.bg:IsHidden() then
            WinMgr.CloseWindow(WIN_ID)
            RemoveInputCapture(controls.bg)
        else
            if not controls.wc then
                controls.wc = UIUtil.CreateWorldCover(controls.bg)
            end
            WinMgr.OpenWindow(WIN_ID)
            AddInputCapture(controls.bg)
        end
        controls.logContainer:CalcVisible()
    end
end

function AddEntry(entryData)
    local tempText = LOC(entryData.text[1])
    local tempData = {}
    local nameStart = string.find(tempText, ']')

    if nameStart ~= nil then
        tempData.name = LOC("<LOC "..string.sub(tempText, 2, nameStart-1)..">")
        tempData.text = WrapText(string.sub(tempText, nameStart+2))
    else
        tempData.name = "INVALID NAME"
        tempData.text =  WrapText(tempText)
        LOG("ERROR: Unable to find name in string: " .. entryData.text[1] .. " (" .. tempText .. ")")
    end
    tempData.time = GetGameTime()

    local factionData = import("/lua/factions.lua")
    local factionColor
    if entryData.Faction then
        factionColor = factionData.Factions[factionData.FactionIndexMap[string.lower(entryData.faction)]].TransmissionLogColor
    end
    tempData.color = factionColor or 'ffffffff'

    PostEntry(tempData)
end

function AddChatEntry(entryData)
    local newEntry = {}
    if entryData.text then
        newEntry.text = WrapText(entryData.text)
    end
    newEntry.color = entryData.color or 'ffffffff'
    newEntry.name = entryData.name
    newEntry.time = GetGameTime()
    PostEntry(newEntry)
end

function WrapText(intext)
    local textBoxWidth = controls.logEntries[1].text.Right() - controls.logEntries[1].text.Left()
    local retText = import("/lua/maui/text.lua").WrapText(intext, textBoxWidth,
    function(text)
        return controls.logEntries[1].text:GetStringAdvance(text)
    end)
    return retText
end

function PostEntry(formattedData)
    table.insert(LogData, 1, formattedData)
    controls.logContainer.top = 1
    controls.logContainer:CalcVisible()
end

function OnPostLoad(data)
    loadData = data
end

function FormatLoadData()
    if loadData then
        for i, v in loadData do
            v.text = WrapText(v.text)
            PostEntry(v)
        end
    end
end