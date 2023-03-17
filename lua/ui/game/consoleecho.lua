--*****************************************************************************
--* File: lua/modules/ui/game/consoleecho.lua
--* Author: Ted Snook
--* Summary: Dev console echo display on screen
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Prefs = import("/lua/user/prefs.lua")

local CONSOLE_LINES = Prefs.GetFromCurrentProfile("console_size") or 5
local CONSOLE_FADE_DELAY = Prefs.GetFromCurrentProfile("console_fade_delay") or 3
local CONSOLE_FONT_SIZE = Prefs.GetFromCurrentProfile("console_font_size") or 12
local CONSOLE_FONT_COLOR = Prefs.GetFromCurrentProfile("console_font_color") or "FFbadbdb"
local CONSOLE_FONT = Prefs.GetFromCurrentProfile("console_font") or "Zeroes Three"
local consoleOutput = {}

local showconsole = true

function CreateConsoleEcho(parent)
    for i = 1, CONSOLE_LINES do
        local index = i
        consoleOutput[index] = CreateTextBox(parent)
        if index == 1 then
            consoleOutput[index].Bottom:Set(function() return parent.Bottom() - 180 end)
        else
            LayoutHelpers.Above(consoleOutput[index], consoleOutput[index-1])
        end
        LayoutHelpers.AtHorizontalCenterIn(consoleOutput[index], parent)
    end
         
    local outputHandler = AddConsoleOutputReciever(function(text)
        AddConsoleOutput(text)
    end)
    
    consoleOutput[1].OnDestroy = function(self)
        RemoveConsoleOutputReciever(outputHandler)
    end
    Prefs.SetToCurrentProfile("console_size", CONSOLE_LINES)
    Prefs.SetToCurrentProfile("console_fade_delay", CONSOLE_FADE_DELAY)
    Prefs.SetToCurrentProfile("console_font_size", CONSOLE_FONT_SIZE)
    Prefs.SetToCurrentProfile("console_font_color", CONSOLE_FONT_COLOR)
    Prefs.SetToCurrentProfile("console_font", CONSOLE_FONT)
end

function CreateTextBox(parent)
    local text = UIUtil.CreateText(parent, "", CONSOLE_FONT_SIZE, CONSOLE_FONT)
    text:SetColor(CONSOLE_FONT_COLOR)
    text.time = 0
    text.OnFrame = function(self, deltaTime)
        if self.time > CONSOLE_FADE_DELAY then
            local curAlpha = self:GetAlpha() - deltaTime
            if curAlpha < 0 then
                self:SetAlpha(0)
                self:SetNeedsFrameUpdate(false)
            else
                self:SetAlpha(curAlpha)
            end
        else
            self.time = self.time + deltaTime
        end
    end
    text:SetNeedsFrameUpdate(true)
    text:SetDropShadow(true)
    text:DisableHitTest()
    text:SetAlpha(0)
    
    return text
end

function AddConsoleOutput(text)
    local index = CONSOLE_LINES
    while index > 0 do
        if index == 1 then
            consoleOutput[1]:SetText(text)
            consoleOutput[1]:SetNeedsFrameUpdate(true)
            consoleOutput[1]:SetAlpha(1)
            consoleOutput[1].time = 0
        elseif consoleOutput[index] then
            consoleOutput[index]:SetText(consoleOutput[index-1]:GetText())
            consoleOutput[index]:SetAlpha(consoleOutput[index-1]:GetAlpha())
            consoleOutput[index]:SetNeedsFrameUpdate(consoleOutput[index-1]:NeedsFrameUpdate())
            consoleOutput[index].time = consoleOutput[index-1].time
        end
        index = index - 1
    end
end

function ToggleOutput(state)
    showconsole = state or not showconsole
    for index, consoleLine in consoleOutput do
        consoleLine.time = CONSOLE_FADE_DELAY + 1
        consoleLine:SetNeedsFrameUpdate(false)
        consoleLine:SetAlpha(0)
        consoleLine:SetHidden(not showconsole)
    end
end