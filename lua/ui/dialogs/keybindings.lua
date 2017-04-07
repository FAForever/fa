-----------------------------------------------------------------
-- File: lua/ui/game/helptext.lua
-- Author: Ted Snook
-- Summary: Help Text Popup
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- This file is the F1 menu used for navigating and interacting with keybindings

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group     = import('/lua/maui/group.lua').Group
local Bitmap    = import('/lua/maui/bitmap.lua').Bitmap
local Text      = import('/lua/maui/text.lua').Text
local Edit      = import('/lua/maui/edit.lua').Edit
local Popup     = import('/lua/ui/controls/popups/popup.lua').Popup
local Tooltip   = import('/lua/ui/game/tooltip.lua')

local keydesc = import('/lua/keymap/keydescriptions.lua').keyDescriptions
local properKeyNames = import('/lua/keymap/properKeyNames.lua').properKeyNames
local keyNames = import('/lua/keymap/keyNames.lua').keyNames
local keyCategories = import('/lua/keymap/keycategories.lua').keyCategories
local keyCategoryOrder = import('/lua/keymap/keycategories.lua').keyCategoryOrder

local panel
local keyContainer
local keyTable
local keyFilter
local keyEntries = {}
local keyword = ''
-- store indexes of visible lines including headers and key entries
local linesVisible = {}
local linesCollapsed = true

-- store info about current state of key categories and preserve their state between FormatData() calls
local keyGroups = {}
for order, category in keyCategoryOrder do
    local name = string.lower(category)
    keyGroups[name] = {}
    keyGroups[name].order = order
    keyGroups[name].name = name
    keyGroups[name].text = LOC(keyCategories[category])
    keyGroups[name].collapsed = linesCollapsed
end

local function ResetKeyMap()
    IN_ClearKeyMap()
    import('/lua/keymap/keymapper.lua').ClearUserKeyMap()
    IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyActions())
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function ConfirmNewKeyMap()
    -- TODO: Add option to accept the changes to the key map?
    IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyMappings(true))
    -- Update hotbuild modifiers
    if SessionIsActive() then
        import('/lua/keymap/hotbuild.lua').addModifiers()
    end
end

local function EditActionKey(parent, action, currentKey)
    local dialogContent = Group(parent)
    dialogContent.Height:Set(130)
    dialogContent.Width:Set(400)

    local keyPopup = Popup(panel, dialogContent)

    local cancelButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelButton, dialogContent, 9)
    LayoutHelpers.AtRightIn(cancelButton, dialogContent, -2)
    cancelButton.OnClick = function(self, modifiers)
        keyPopup:Close()
    end

    local okButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.LeftOf(okButton, cancelButton, 145)

    local helpText = UIUtil.CreateText(dialogContent, "<LOC key_binding_0002>Hit the key combination you'd like to assign", 16)
    LayoutHelpers.AtTopIn(helpText, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(helpText, dialogContent)

    local keyText = UIUtil.CreateText(dialogContent, FormatKeyName(currentKey), 24)
    LayoutHelpers.AtTopIn(keyText, dialogContent, 40)
    LayoutHelpers.AtHorizontalCenterIn(keyText, dialogContent)

    dialogContent:AcquireKeyboardFocus(false)
    keyPopup.OnClose = function(self)
        dialogContent:AbandonKeyboardFocus()
    end

    local keyCodeLookup = import('/lua/keymap/keymapper.lua').GetKeyCodeLookup()
    local keyAdder = {}
    local currentKeyPattern

    local function AddKey(keyCode, modifiers)
        local key = keyCodeLookup[keyCode]
        if not key then
            return
        end

        local keyComboName = ""
        currentKeyPattern = ""

        if key ~= 'Ctrl' and modifiers.Ctrl then
            currentKeyPattern = currentKeyPattern .. keyNames['11'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[keyNames['11']]) .. "-"
        end

        if key ~= 'Alt' and modifiers.Alt then
            currentKeyPattern = currentKeyPattern .. keyNames['12'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[keyNames['12']]) .. "-"
        end

        if key ~= 'Shift' and modifiers.Shift then
            currentKeyPattern = currentKeyPattern .. keyNames['10'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[keyNames['10']]) .. "-"
        end

        currentKeyPattern = currentKeyPattern .. key
        keyComboName = keyComboName .. LOC(properKeyNames[key])

        keyText:SetText(keyComboName)
    end

    local oldHandleEvent = dialogContent.HandleEvent
    dialogContent.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            AddKey(event.RawKeyCode, event.Modifiers)
        end

        oldHandleEvent(self, event)
    end

    local function AssignKey()
        -- Check if key is already assigned to something else
        local Keymapper = import('/lua/keymap/keymapper.lua')

        local function ClearShiftKey()
            Keymapper.ClearUserKeyMapping("Shift-" .. currentKeyPattern)
            LOG("clearing Shift-"..currentKeyPattern)
        end

        local function ClearAltKey()
            Keymapper.ClearUserKeyMapping("Alt-" .. currentKeyPattern)
            LOG("clearing Alt-"..currentKeyPattern)
        end

        local function MapKey()
            Keymapper.SetUserKeyMapping(currentKeyPattern, currentKey, action)
            local cat = Keymapper.KeyCategory(currentKeyPattern, Keymapper.GetCurrentKeyMap(), Keymapper.GetKeyActions())
            if cat and cat == "hotbuilding" then
                if Keymapper.IsKeyInMap("Shift-" .. currentKeyPattern, Keymapper.GetCurrentKeyMap()) then
                    UIUtil.QuickDialog(panel, "Shift-"..currentKeyPattern.. " is already mapped to another action, do you want to clear it for hotbuild?",
                        "<LOC _Yes>", ClearShiftKey,
                        "<LOC _No>", nil,
                        nil, nil,
                        true,
                        {escapeButton = 2, enterButton = 1, worldCover = false})
                end
                if Keymapper.IsKeyInMap("Alt-" .. currentKeyPattern, Keymapper.GetCurrentKeyMap()) then
                    UIUtil.QuickDialog(panel, "Alt-"..currentKeyPattern.. " is already mapped to another action, do you want to clear it for hotbuild?",
                        "<LOC _Yes>", ClearAltKey,
                        "<LOC _No>", nil,
                        nil, nil,
                        true,
                        {escapeButton = 2, enterButton = 1, worldCover = false})
                end
            end
            keyTable = FormatData()
            keyContainer:Filter(keyword)
        end
        if Keymapper.IsKeyInMap(currentKeyPattern, Keymapper.GetCurrentKeyMap()) then
            UIUtil.QuickDialog(panel, "<LOC key_binding_0006>This key is already mapped to another action, are you sure you want to change it?",
                "<LOC _Yes>", MapKey,
                "<LOC _No>", nil,
                nil, nil,
                true,
                {escapeButton = 2, enterButton = 1, worldCover = false})
        else
            MapKey()
        end
    end

    okButton.OnClick = function(self, modifiers)
        AssignKey()
        keyPopup:Close()
    end
end

local function AssignCurrentSelection()
    for k, v in keyTable do
        if v._selected then
            EditActionKey(panel, v.action, v.key)
            break
        end
    end
end

local function UnbindCurrentSelection()
    local Keymapper = import('/lua/keymap/keymapper.lua')
    for k, v in keyTable do
        if v._selected then
            Keymapper.ClearUserKeyMapping(v.key)
            break
        end
    end
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function GetLineColor(lineID, data)
    if data.type == 'header' then
        return 'FF282828' --#FF282828
    elseif data.type == 'spacer' then
        return '00000000' --#00000000
    elseif data.type == 'entry' then
        if data._selected then
            return UIUtil.factionBackColor
        elseif math.mod(lineID, 2) == 1 then
            return 'ff202020' --#ff202020
        else
            return 'FF343333' --#FF343333
        end
    else
        return 'FF6B0088' --#FF9D06C6
    end
end

-- toggles expansion or collapse of lines with specified key category only if searching is not active
local function ToggleLines(category)
    if keyword and string.len(keyword) > 0 then return end

    for k, v in keyTable do
        if v.category == category then
           if v.collapsed then
              v.collapsed = false
           else
              v.collapsed = true
           end
        end
    end
    if keyGroups[category].collapsed then
       keyGroups[category].collapsed = false
    else
       keyGroups[category].collapsed = true
    end
    keyContainer:Filter(keyword)
end

local function SelectLine(dataIndex)
    local index = nil
    for k, v in keyTable   do
        v._selected = false
    end

    if keyTable[dataIndex].type == 'entry' then
       keyTable[dataIndex]._selected = true
    end
    keyContainer:Filter(keyword)
end

function CreateToggle(parent, bgColor, txtColor, bgSize, txtSize, txt)
    if not bgSize then bgSize = 20 end
    if not bgColor then bgColor = 'FF343232' end -- #FF343232
    if not txtColor then txtColor = UIUtil.factionTextColor end
    if not txtSize then txtSize = 18 end
    if not txt then txt = '?' end

    local button  = Bitmap(parent)
    button:SetSolidColor(bgColor) 
    button.Height:Set(bgSize)
    button.Width:Set(bgSize + 4) 
    button.txt = UIUtil.CreateText(button, txt, txtSize)
    button.txt:SetColor(txtColor)
    button.txt:SetFont(UIUtil.bodyFont, txtSize)
    LayoutHelpers.AtVerticalCenterIn(button.txt, button)
    LayoutHelpers.AtHorizontalCenterIn(button.txt, button)
    
    button:SetAlpha(0.8)
    button.txt:SetAlpha(0.8)

    button.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            button:SetAlpha(1.0)
            button.txt:SetAlpha(1.0)
        elseif event.Type == 'MouseExit' then
            button:SetAlpha(0.8)
            button.txt:SetAlpha(0.8)
        end
        return false
    end
    return button
end
-- create a line with dynamically updating UI elements based on type of data line
function CreateLine()
    local keyBindingWidth = 180
    local line = Bitmap(keyContainer)
    line.Left:Set(keyContainer.Left)
    line.Right:Set(keyContainer.Right)
    line.Height:Set(20)

    line.key = UIUtil.CreateText(line, '', 16, "Arial")
    line.key:DisableHitTest()
    line.key:SetAlpha(0.9)

    line.description = UIUtil.CreateText(line, '', 16, "Arial")
    line.description:DisableHitTest()
    line.description:SetClipToWidth(true)
    line.description.Width:Set(line.Right() - line.Left() - keyBindingWidth)
    line.description:SetAlpha(0.9)

    line.Height:Set(function() return line.key.Height() + 4 end)
    line.Width:Set(function() return line.Right() - line.Left() end)

    line.statistics = UIUtil.CreateText(line, '', 16, "Arial")
    line.statistics:EnableHitTest()
    line.statistics:SetColor('FF9A9A9A') --#FF9A9A9A'
    line.statistics:SetAlpha(0.9)

    Tooltip.AddControlTooltip(line.statistics,
    {
        text = 'Category Statistics',
        body = 'Show total of bound actions and total of all actions in this category of keys'
    })

    LayoutHelpers.AtLeftIn(line.description, line, keyBindingWidth)
    LayoutHelpers.AtVerticalCenterIn(line.description, line)
    LayoutHelpers.AtRightIn(line.key, line, line.Width() - keyBindingWidth + 20)
    LayoutHelpers.AtVerticalCenterIn(line.key, line)

    LayoutHelpers.AtRightIn(line.statistics, line, 10)
    LayoutHelpers.AtVerticalCenterIn(line.statistics, line)

    line.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            line:SetAlpha(0.9)
            line.key:SetAlpha(1.0)
            line.description:SetAlpha(1.0)
            line.statistics:SetAlpha(1.0)
            PlaySound(Sound({Cue = "UI_Menu_Rollover_Sml", Bank = "Interface"})) 
        elseif event.Type == 'MouseExit' then
            line:SetAlpha(1.0)
            line.key:SetAlpha(0.9)
            line.description:SetAlpha(0.9)
            line.statistics:SetAlpha(0.9)

        elseif self.data.type == 'entry' then
            if event.Type == 'ButtonPress' then
                SelectLine(self.data.index)
                keyFilter.text:AcquireFocus()
                return true
            elseif event.Type == 'ButtonDClick' then
                SelectLine(self.data.index)
                AssignCurrentSelection()
                return true
            end
        elseif self.data.type == 'header' and (event.Type == 'ButtonPress' or event.Type == 'ButtonDClick') then
            if string.len(keyword) == 0 then
                ToggleLines(self.data.category)
                keyFilter.text:AcquireFocus()
                
                if keyGroups[self.data.category].collapsed then
                   self.toggle.txt:SetText('+')
                else
                   self.toggle.txt:SetText('-')
                end
                PlaySound(Sound({Cue = "UI_Menu_MouseDown_Sml", Bank = "Interface"}))
                return true
            end
        end

        return false
    end
    
    line.toggle = CreateToggle(line, 
         'FF131212',  --#FF131212'
         UIUtil.factionTextColor,
         line.key.Height() + 2, 
         18, '+')
    LayoutHelpers.AtLeftIn(line.toggle, line)
    LayoutHelpers.AtVerticalCenterIn(line.toggle, line)

    Tooltip.AddControlTooltip(line.toggle, 
    {
        text = 'Toggle Category',
        body = 'Toggle visibility of all actions for this category of keys' 
    })
    
    line.Update = function(self, data, lineID)
        
        line:SetSolidColor(GetLineColor(lineID, data))
        line.data = table.copy(data)
          
        if data.type == 'header' then
            if keyGroups[self.data.category].collapsed then
               self.toggle.txt:SetText('+')
            else
               self.toggle.txt:SetText('-')
            end
            local stats = keyGroups[data.category].bindings .. ' / ' .. 
                          keyGroups[data.category].visible  ..' Actions'

            line.toggle:Show()
            line.description:SetText(data.text)
            line.description:SetFont(UIUtil.titleFont, 16)
            line.description:SetColor(UIUtil.factionTextColor) 
            line.key:SetText('')
            line.statistics:SetText(stats)
            
        elseif data.type == 'spacer' then
            line.toggle:Hide()
            line.key:SetText('')
            line.description:SetText('')
            line.statistics:SetText('')
        elseif data.type == 'entry' then
            line.toggle:Hide()
            line.key:SetText(data.keyText)
            line.key:SetColor('ffffffff') --#ffffffff'
            line.key:SetFont('Arial', 16)
            line.description:SetText(data.text)
            line.description:SetFont('Arial', 16)
            line.description:SetColor(UIUtil.fontColor)
            line.statistics:SetText('')
        end
    end

    return line
end
 
function CreateUI()
    if WorldIsLoading() or (import('/lua/ui/game/gamemain.lua').supressExitDialog == true) then
        return
    end

    if panel then
        panel:Close()
        panel = false
        return
    end
    keyword = ''
    keyTable = FormatData()

    local dialogContent = Group(GetFrame(0))
    dialogContent.Width:Set(800)
    dialogContent.Height:Set(730)

    panel = Popup(GetFrame(0), dialogContent)

    panel.OnDestroy = function(self)
        RemoveInputCapture(dialogContent)
    end

    local title = UIUtil.CreateText(dialogContent, LOC("<LOC key_binding_0000>Key Bindings"), 22)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local offset = dialogContent.Width() / 5

    local closeButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC _Close>"))
    LayoutHelpers.AtBottomIn(closeButton, dialogContent, 10)
    LayoutHelpers.AtRightIn(closeButton, dialogContent, offset - (closeButton.Width() / 2))
    closeButton.OnClick = function(self, modifiers)
        ConfirmNewKeyMap()
        panel:Close()
        panel = false
    end

    panel.OnClosed = function(self)
        panel = false
    end

    local assignKeyButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0003>Assign Key"))
    LayoutHelpers.AtBottomIn(assignKeyButton, dialogContent, 10)
    LayoutHelpers.AtRightIn(assignKeyButton, dialogContent, 2*offset - (assignKeyButton.Width() / 2))
    assignKeyButton.OnClick = function(self, modifiers)
        AssignCurrentSelection()
    end

    local unbindKeyButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0007>Unbind Key"))
    LayoutHelpers.AtBottomIn(unbindKeyButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(unbindKeyButton, dialogContent, 2*offset - (unbindKeyButton.Width() / 2))
    unbindKeyButton.OnClick = function(self, modifiers)
        UnbindCurrentSelection()
    end

    local resetButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0004>Reset"))
    LayoutHelpers.AtBottomIn(resetButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(resetButton, dialogContent, offset - (resetButton.Width() / 2))
    resetButton.OnClick = function(self, modifiers)
        UIUtil.QuickDialog(panel, "<LOC key_binding_0005>Are you sure you want to reset all key bindings to the default keybindings?",
            "<LOC _Yes>", ResetKeyMap,
            "<LOC _No>", nil,
            nil, nil,
            true,
            {escapeButton = 2, enterButton = 1, worldCover = false})
    end

    dialogContent.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 342 then
                closeButton:OnClick()
            end
        end
    end
    
    keyFilter = Bitmap(dialogContent)
    keyFilter:SetSolidColor('FF282828')-- #FF282828
    keyFilter.Left:Set(function() return dialogContent.Left() + 63 end)
    keyFilter.Right:Set(function() return dialogContent.Right() - 6 end)
    keyFilter.Top:Set(function() return title.Bottom() + 10 end)
    keyFilter.Bottom:Set(function() return title.Bottom() + 40 end)
    keyFilter.Width:Set(function() return keyFilter.Right() - keyFilter.Left() end)
    keyFilter.Height:Set(function() return keyFilter.Bottom() - keyFilter.Top() end)
    
    keyFilter:EnableHitTest()
    import('/lua/ui/game/tooltip.lua').AddControlTooltip(keyFilter, 
    {
        text = 'Key Binding Filter',
        body = 'Filter all actions by typing either: ' .. 
        '\n - full key binding "CTRL+K" ' .. 
        '\n - partial key binding "CTRL" ' .. 
        '\n - full action name "Self-Destruct" ' .. 
        '\n - partial action name "Self" '.. 
        '\n\n Note that collapsing of key categories is disabled while this filter contains some text'
    }, nil, 200)

    keyFilter.label = UIUtil.CreateText(dialogContent, 'Filter', 17)
    keyFilter.label:SetColor('FF929191') -- #FF929191
    keyFilter.label:SetFont(UIUtil.titleFont, 17)
    LayoutHelpers.AtVerticalCenterIn(keyFilter.label, keyFilter, 2)
    LayoutHelpers.AtLeftIn(keyFilter.label, dialogContent, 9)

    local text = LOC("<LOC key_binding_filterInfo>Type key binding or name of action")
    keyFilter.info = UIUtil.CreateText(keyFilter, text, 17, UIUtil.titleFont)
    keyFilter.info:SetColor('FF727171') -- #FF727171
    keyFilter.info:DisableHitTest()
    LayoutHelpers.AtHorizontalCenterIn(keyFilter.info, keyFilter, -7)
    LayoutHelpers.AtVerticalCenterIn(keyFilter.info, keyFilter, 2)
     
    keyFilter.text = Edit(keyFilter)
    keyFilter.text:SetForegroundColor('FFF1ECEC') -- #FFF1ECEC
    keyFilter.text:SetBackgroundColor('04E1B44A') -- #04E1B44A
    keyFilter.text:SetHighlightForegroundColor(UIUtil.highlightColor)
    keyFilter.text:SetHighlightBackgroundColor("880085EF") --#880085EF
    keyFilter.text.Height:Set(function() return keyFilter.Bottom() - keyFilter.Top() - 10 end)
    keyFilter.text.Left:Set(function() return keyFilter.Left() + 5 end)
    keyFilter.text.Right:Set(function() return keyFilter.Right() end)
    LayoutHelpers.AtVerticalCenterIn(keyFilter.text, keyFilter)
    keyFilter.text:AcquireFocus()
    keyFilter.text:SetText('')
    keyFilter.text:SetFont(UIUtil.titleFont, 17)
    keyFilter.text:SetMaxChars(20)
    keyFilter.text.OnTextChanged = function(self, newText, oldText)
        -- interpret plus chars as spaces for easier key filtering
        keyword = string.gsub(string.lower(newText), '+', ' ')
        keyword = string.gsub(string.lower(keyword), '  ', ' ')
        keyword = string.gsub(string.lower(keyword), '  ', ' ')
        if string.len(keyword) == 0 then
            for k, v in keyGroups do
                v.collapsed = true
            end
            for k, v in keyTable do
                v.collapsed = true
            end
        end
        keyContainer:Filter(keyword)
        keyContainer:ScrollSetTop(nil, 0)
    end

    keyFilter.clear = UIUtil.CreateText(keyFilter.text, 'X', 17, "Arial Bold")
    keyFilter.clear:SetColor('FF8A8A8A') -- #FF8A8A8A 
    keyFilter.clear:EnableHitTest()
    LayoutHelpers.AtVerticalCenterIn(keyFilter.clear, keyFilter.text, 1)
    LayoutHelpers.AtRightIn(keyFilter.clear, keyFilter.text, 9)

    keyFilter.clear.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            keyFilter.clear:SetColor('FFC9C7C7') -- #FFC9C7C7
        elseif event.Type == 'MouseExit' then
            keyFilter.clear:SetColor('FF8A8A8A') -- #FF8A8A8A
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            keyFilter.text:SetText('')
            keyFilter.text:AcquireFocus()
        end
        return true
    end
    Tooltip.AddControlTooltip(keyFilter.clear, 
    {
        text = 'Clear Filter',
        body = 'Clears text that was typed in the filter field.' 
    })

    keyContainer = Group(dialogContent)
    keyContainer.Left:Set(function() return dialogContent.Left() + 10 end)
    keyContainer.Right:Set(function() return dialogContent.Right() - 20 end)
    keyContainer.Top:Set(function() return keyFilter.Bottom() + 10 end)
    keyContainer.Bottom:Set(function() return resetButton.Top() - 10 end)
    keyContainer.Height:Set(function() return keyContainer.Bottom() - keyContainer.Top() - 10 end)
    keyContainer.top = 0

    UIUtil.CreateLobbyVertScrollbar(keyContainer)
    
    local index = 1
    keyEntries = {}
    keyEntries[index] = CreateLine()
    LayoutHelpers.AtTopIn(keyEntries[1], keyContainer)

    index = index + 1
    
    while keyEntries[table.getsize(keyEntries)].Top() + (2 * keyEntries[1].Height()) < keyContainer.Bottom() do
        keyEntries[index] = CreateLine()
        LayoutHelpers.Below(keyEntries[index], keyEntries[index-1])
        index = index + 1
    end

    local height = keyContainer.Height()
    local items = math.floor(keyContainer.Height() / keyEntries[1].Height()) 

    local GetLinesTotal = function() 
        return table.getsize(keyEntries) 
    end

    local function GetLinesVisible()
        return table.getsize(linesVisible)
    end

    -- Called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- axis can be "Vert" or "Horz"
    keyContainer.GetScrollValues = function(self, axis)
        local size = GetLinesVisible()
        local visibleMax = math.min(self.top + GetLinesTotal(), size)
        return 0, size, self.top, visibleMax
    end

    -- Called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    keyContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- Called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    keyContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * GetLinesTotal())
    end

    -- Called when the scrollbar wants to set a new visible top line
    keyContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = GetLinesVisible()
        self.top = math.max(math.min(size - GetLinesTotal() , top), 0)
        self:CalcVisible()
    end

    -- Called to determine if the control is scrollable on a particular access. Must return true or false.
    keyContainer.IsScrollable = function(self, axis)
        return true
    end

    -- Determines what control lines should be visible or not
    keyContainer.CalcVisible = function(self)
        for i, line in keyEntries do
            local id = i + self.top
            local index = linesVisible[id]
            local data = keyTable[index]
            
            if data then
                line:Update(data, id)
            else
                line:SetSolidColor('00000000') --#00000000
                line.key:SetText('')
                line.description:SetText('')
                line.statistics:SetText('')
                line.toggle:Hide()
            end
        end
        keyFilter.text:AcquireFocus()
    end

    keyContainer.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            control:ScrollLines(nil, lines)
        end
    end
    -- filter all key-bindings by checking if either text, action, or a key contains target string
    keyContainer.Filter = function(self, target)
        local headersVisible = {}
        linesVisible = {} 

        if not target or string.len(target) == 0 then
            keyFilter.info:Show() 
            for k, v in keyTable do
                if v.type == 'header' then
                    table.insert(linesVisible, k)
                    keyGroups[v.category].visible = v.count
                    keyGroups[v.category].bindings = 0
                elseif v.type == 'entry' then
                    if not v.collapsed then
                        table.insert(linesVisible, k)
                    end
                    if v.key then
                        keyGroups[v.category].bindings = keyGroups[v.category].bindings + 1
                    end
                end
            end
        else
            keyFilter.info:Hide()
            for k, v in keyTable do
                local match = false
                if v.type == 'header' then
                    keyGroups[v.category].visible = 0
                    keyGroups[v.category].bindings = 0
                    if not headersVisible[k] then
                        headersVisible[k] = true
                        table.insert(linesVisible, k)
                        keyGroups[v.category].collapsed = true
                    end
                elseif v.type == 'entry' and v.filters then
                    if string.find(v.filters.text, target) then
                        match = true
                        v.filterMatch = 'text'
                    elseif string.find(v.filters.key, target) then
                        match = true
                        v.filterMatch = 'key'
                    elseif string.find(v.filters.action, target) then
                        match = true
                        v.filterMatch = 'action'
                    elseif string.find(v.filters.category, target) then
                        match = true
                        v.filterMatch = 'category'
                    else
                        match = false 
                        v.filterMatch = nil
                    end 
                    if match then
                        if not headersVisible[v.header] then
                            headersVisible[v.header] = true
                            table.insert(linesVisible, v.header)
                        end
                        keyGroups[v.category].collapsed = false
                        keyGroups[v.category].visible = keyGroups[v.category].visible + 1
                        table.insert(linesVisible, k)
                        if v.key then
                            keyGroups[v.category].bindings = keyGroups[v.category].bindings + 1
                        end
                    end
                end
            end
        end
        self:CalcVisible()
    end

    keyFilter.text:SetText('')
end

function SortData(dataTable)
    table.sort(dataTable, function(a, b)
        if a.order ~= b.order then 
            return a.order < b.order
        else
            if a.category ~= b.category then 
                return string.lower(a.category) < string.lower(b.category)
            else
                if a.type == 'entry' and b.type == 'entry' then 
                    if string.lower(a.text) ~= string.lower(b.text) then 
                        return string.lower(a.text) < string.lower(b.text) 
                    else 
                        return a.action < b.action
                    end
                else 
                    return a.id < b.id
                end
            end
        end 
    end)
end
-- format all key data, group them based on key category or default to none category and finally sort all keys
function FormatData()
    local retkeys = {}
    local KeyData = {}
    local keyLookup = import('/lua/keymap/keymapper.lua').GetKeyLookup()
    local keyactions = import('/lua/keymap/keymapper.lua').GetKeyActions()

    -- group game keys and key defined in mods by their key category
    for k, v in keyactions do
        local category = string.lower(v.category or 'none')
        local keyForAction = keyLookup[k]

        if not keyGroups[category] then
            keyGroups[category] = {}
            keyGroups[category].name = category
            keyGroups[category].collapsed = linesCollapsed
            keyGroups[category].order = table.getsize(keyGroups) - 1
            keyGroups[category].text = v.category or keyCategories['none'].text
        end

        if not retkeys[category] then
            retkeys[category] = {}
        end

        local data = {
            action = k,
            key = keyForAction,
            keyText = FormatKeyName(keyForAction),
            category = category,
            order = keyGroups[category].order,
            text = LOC(keydesc[k] or k or "<LOC key_binding_0001>No action text"),
        }
        table.insert(retkeys[category], data)
    end

    local indexOrders = 1
    local indexSelection = 1
    local index = 1
    for category, v in retkeys do
        KeyData[index] = { 
            type = 'header', 
            id = index, 
            order = keyGroups[category].order, 
            count = table.getsize(v), 
            category = category, 
            text = keyGroups[category].text,
            collapsed = keyGroups[category].collapsed
        }
        index = index + 1
        for _, data in v do 
            KeyData[index]  = { 
                type = 'entry', 
                text = data.text,
                action = data.action,
                key = data.key,
                keyText = LOC(data.keyText),
                category = category,
                order = keyGroups[category].order,
                collapsed = keyGroups[category].collapsed,
                id = index, 
                filters = { -- create filter parameters for quick searching of keys
                     key =  string.gsub( string.lower(data.keyText), ' %+ ', ' '),
                     text = string.lower(data.text or ''),
                     action = string.lower(data.action or ''),
                     category = string.lower(data.category or ''),
                }
            } 
            index = index + 1
        end
    end

    SortData(KeyData)

    -- store index of a header line for each key line
    local header = 1
    for i, data in KeyData do
        if data.type == 'header' then
            header = i
        elseif data.type == 'entry' then
            data.header = header
        end
        data.index = i
    end

    return KeyData
end

function FormatKeyName(key)
    if not key then
        return ""
    end

    local function LookupToken(token)
        if properKeyNames[token] then
            return LOC(properKeyNames[token])
        else
            return token
        end
    end

    local result = ''

    while string.find(key, '-') do
        local loc = string.find(key, '-')
        local token = string.sub(key, 1, loc-1)
        result = result..LookupToken(token)..' + '
        key = string.sub(key, loc+1)
    end

    return result..LookupToken(key)
end
