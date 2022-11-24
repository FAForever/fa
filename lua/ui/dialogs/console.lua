--*****************************************************************************
--* File: lua/modules/ui/dialogs/console.lua
--* Author: Chris Blackwell
--* Summary: command console
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Edit = import("/lua/maui/edit.lua").Edit
local Control = import("/lua/maui/control.lua").Control
local Window = import("/lua/maui/window.lua").Window
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local Prefs = import("/lua/user/prefs.lua")

local commandDeque = {}
local maxCommandDequeSize = 10
local currentCommandDequeIndex = 0
local currentText = ""
local consoleFontName = UIUtil.fixedFont
local consoleFontSize = 12
local window = false
local parent = false

local TableGetN = table.getn

local windowTexture = {
    bl = '/textures/ui/uef/game/options_brd/options_brd_ll.dds',
    bm = '/textures/ui/uef/game/options_brd/options_brd_lm.dds',
    borderColor = 'ff415055',
    br = '/textures/ui/uef/game/options_brd/options_brd_lr.dds',
    m = '/textures/ui/uef/game/options_brd/options_brd_m.dds',
    ml = '/textures/ui/uef/game/options_brd/options_brd_vert_l.dds',
    mr = '/textures/ui/uef/game/options_brd/options_brd_vert_r.dds',
    tl = '/textures/ui/uef/game/options_brd/options_brd_ul.dds',
    tm = '/textures/ui/uef/game/options_brd/options_brd_horz_um.dds',
    tr = '/textures/ui/uef/game/options_brd/options_brd_ur.dds'
}

local function InsertCommand(text)
    table.insert(commandDeque, text)
    if TableGetN(commandDeque) > maxCommandDequeSize then
        table.remove(commandDeque, 1)
    end
    currentCommandDequeIndex = TableGetN(commandDeque)
end

function ConfigWindow(parent)
    if window then return end
    window = Window(GetFrame(0), '<LOC console_0000>Console Config', nil, nil, nil, true, nil, 'console_window_config', nil, windowTexture)
    LayoutHelpers.AtLeftTopIn(window, parent, 10, 30)
    LayoutHelpers.AnchorToLeft(window, parent, -230)
    LayoutHelpers.AnchorToTop(window, parent, -120)
    window.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

    local client = window:GetClientGroup()
    local defValue = Prefs.GetFromCurrentProfile('console_alpha') or 1
    defValue = defValue * 100
    local label = UIUtil.CreateText(client, LOCF("<LOC console_alpha>Alpha: %d%%", defValue), 14)
    LayoutHelpers.AtLeftTopIn(label, client, 5, 5)

    local slider = IntegerSlider(client, false,
            20, 100, 1, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
    LayoutHelpers.Below(slider, label)
    slider.OnValueSet = function(self, newValue)
    end
    slider.OnValueChanged = function(self, newValue)
        parent:SetAlpha(newValue / 100, true)
        label:SetText(LOCF("<LOC console_alpha>Alpha: %d%%", newValue))
    end
    slider:SetValue(defValue)
    window.OnClose = function(self)
        Prefs.SetToCurrentProfile('console_alpha', slider:GetValue()/100)
        window:Destroy()
        window = false
    end
end

function CreateDialog()
    local mainFrame = GetFrame(0)

    local location = {Top = 5, Left = 5, Bottom = 500, Right = 300}
    parent = Window(mainFrame, '<LOC _Console>Console', nil, nil, true, false, false, 'console_window', location, windowTexture)
    parent.Depth:Set(UIUtil.consoleDepth)
    parent:SetMinimumResize(200, 170)
    local edit = Edit(parent:GetClientGroup())
    LayoutHelpers.AtLeftIn(edit, parent:GetClientGroup(), 10)
    LayoutHelpers.AtRightBottomIn(edit, parent:GetClientGroup(), 38, 10)
    edit:SetForegroundColor(UIUtil.consoleFGColor())
    edit:SetBackgroundColor('ff333333')
    edit:SetHighlightForegroundColor("black")
    edit:SetHighlightBackgroundColor(UIUtil.consoleTextBGColor())
    edit:SetFont(consoleFontName, consoleFontSize)
    edit.Height:Set(function() return math.floor(edit:GetFontHeight()) end)

    local consoleOutput = ItemList(parent:GetClientGroup())
    LayoutHelpers.Above(consoleOutput, edit, 10)
    LayoutHelpers.AtTopIn(consoleOutput, parent:GetClientGroup(), 5)
    consoleOutput.Right:Set(edit.Right)
    consoleOutput:SetColors(UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor(), UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor()) -- we don't really want selection here so don't differentiate colors
    consoleOutput:SetFont(consoleFontName, consoleFontSize)

    UIUtil.CreateVertScrollbarFor(consoleOutput)

    parent.OnConfigClick = function(self)
        ConfigWindow(parent)
    end

    -- set up output control to recieve console spew
    local outputHandler = AddConsoleOutputReciever(function(text)
        consoleOutput:AddItem(text)
        local itemCount = consoleOutput:GetItemCount()
        if itemCount > 300 then  -- 300 seems like a good buffer size
            consoleOutput:DeleteItem(0)
        end
        consoleOutput:SetSelection(itemCount - 1)
        consoleOutput:ScrollToBottom()
    end)

    -- if this gets destroyed we need to unregister and destroy the output handler
    parent.OnDestroy = function(self)
        RemoveConsoleOutputReciever(outputHandler)
    end

    -- handle edit control
    local conFuncsList = false
    local raiseConFuncList = true
    edit.OnTextChanged = function(self, newText, oldText)
        if raiseConFuncList then
            if conFuncsList then
                conFuncsList:Destroy()
                conFuncsList = false
            end
            local matches = ConTextMatches(newText)
            local numMatches = TableGetN(matches)
            if (numMatches > 0) then
                conFuncsList = ItemList(consoleOutput)
                conFuncsList:SetFont(consoleFontName, consoleFontSize)
                LayoutHelpers.Above(conFuncsList, edit)
                LayoutHelpers.AtRightIn(conFuncsList, edit, 32)
                conFuncsList.Height:Set(function()
                    return math.min(consoleOutput.Height(), conFuncsList:GetRowHeight() * numMatches)
                end)
                for i,v in matches do
                    conFuncsList:AddItem(v)
                end

                if conFuncsList:NeedsScrollBar() then
                    UIUtil.CreateVertScrollbarFor(conFuncsList)
                end

                conFuncsList:SetSelection(conFuncsList:GetItemCount() - 1)
                conFuncsList:ScrollToBottom()

                conFuncsList.OnDoubleClick = function(self, row)
                    edit:SetText(conFuncsList:GetItem(row))
                    edit:AcquireFocus()
                end
            end
         end
    end

    edit.OnEnterPressed = function(self, text)
        if string.lower(text) == "ren_showdirtyterrain" then
            WARN("The command \'" .. text .. "\' is harmful and will crash the game. It is not executed.")
            return
        end
        ConExecuteSave(text)
        InsertCommand(text)
    end

    edit.OnNonTextKeyPressed = function(self, keycode)
        local function ChangeConFuncSelection(direction)
            local selection = math.max(math.min(conFuncsList:GetSelection() + direction, conFuncsList:GetItemCount() - 1), 0)
            conFuncsList:SetSelection(selection)
            raiseConFuncList = false
            edit:SetText(conFuncsList:GetItem(selection))
            raiseConFuncList = true
        end

        if keycode == UIUtil.VK_UP then
            if conFuncsList then
                ChangeConFuncSelection(-1)
            else
                -- store off the current text if this is the first press
                local commandDequeSize = TableGetN(commandDeque)
                if commandDequeSize > 0 then
                    if currentCommandDequeIndex == commandDequeSize then currentText = edit:GetText() end
                    edit:SetText(commandDeque[currentCommandDequeIndex])
                    currentCommandDequeIndex = currentCommandDequeIndex - 1
                    if currentCommandDequeIndex <= 0 then currentCommandDequeIndex = 1 end
                end
            end
        elseif keycode == UIUtil.VK_DOWN then
            if conFuncsList then
                ChangeConFuncSelection(1)
            else
                currentCommandDequeIndex = currentCommandDequeIndex + 1
                if currentCommandDequeIndex > TableGetN(commandDeque) then
                    currentCommandDequeIndex = TableGetN(commandDeque)
                    edit:SetText(currentText)
                else
                    edit:SetText(commandDeque[currentCommandDequeIndex])
                end
            end
        end
    end

    edit.OnCharPressed = function(self, charcode)
        -- close console on tilde key (apostrophe, or ascii 96)
        if charcode == 96 then
            edit:AbandonKeyboardFocus()
            parent:Hide()
            return true
        elseif charcode == UIUtil.VK_TAB then
            if conFuncsList then
                edit:SetText(conFuncsList:GetItem(conFuncsList:GetSelection()))
                return true
            else
                return false
            end
        else
            return false
        end
    end

    -- override Show behavior to acquire keyboard focus
    parent.Show = function(self)
        edit:AcquireFocus()
        Control.Show(self)
    end
    parent.Hide = function(self)
        if window then
            window:Destroy()
            window = false
        end
        Control.Hide(self)
    end
    parent.OnClose = function(self)
        self:Hide()
    end
    local tempalpha = Prefs.GetFromCurrentProfile('console_alpha') or 1
    parent:SetAlpha(tempalpha, true)
    return parent
end

-- kept for mod backwards compatibility
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Scrollbar = import("/lua/maui/scrollbar.lua").Scrollbar
local Border = import("/lua/maui/border.lua").Border