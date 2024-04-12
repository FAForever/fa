-----------------------------------------------------------------
-- File: lua/ui/game/helptext.lua
-- Author: Ted Snook
-- Summary: Help Text Popup
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- This file is the F1 menu used for navigating and interacting with keybindings
local UIUtil        = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group         = import("/lua/maui/group.lua").Group
local Bitmap        = import("/lua/maui/bitmap.lua").Bitmap
local Edit          = import("/lua/maui/edit.lua").Edit
local Popup         = import("/lua/ui/controls/popups/popup.lua").Popup
local Tooltip       = import("/lua/ui/game/tooltip.lua")
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText

local properKeyNames = import("/lua/keymap/properkeynames.lua").properKeyNames
local keyNames = import("/lua/keymap/keynames.lua").keyNames
local keyCategories = import("/lua/keymap/keycategories.lua").keyCategories
local keyCategoryOrder = import("/lua/keymap/keycategories.lua").keyCategoryOrder
local KeyMapper = import("/lua/keymap/keymapper.lua")

local popup = nil
local FormatData
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

local function ResetBindingToDefaultKeyMap()
    IN_ClearKeyMap()
    KeyMapper.ResetUserKeyMapTo('defaultKeyMap.lua')
    IN_AddKeyMapTable(KeyMapper.GetKeyActions())
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function ResetBindingToHotbuildKeyMap()
    IN_ClearKeyMap()
    KeyMapper.ResetUserKeyMapTo('hotbuildKeyMap.lua')
    IN_AddKeyMapTable(KeyMapper.GetKeyActions())
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function ResetBindingToalternativeKeyMap()
    IN_ClearKeyMap()
    KeyMapper.ResetUserKeyMapTo('alternativeKeyMap.lua')
    IN_AddKeyMapTable(KeyMapper.GetKeyActions())
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function ConfirmNewKeyMap()
    KeyMapper.SaveUserKeyMap()
    IN_ClearKeyMap()
    IN_AddKeyMapTable(KeyMapper.GetKeyMappings(true))
    -- update hotbuild modifiers and re-initialize hotbuild labels
    if SessionIsActive() then
        import("/lua/keymap/hotbuild.lua").addModifiers()
        import("/lua/keymap/hotkeylabels.lua").init()
    end
end

local function ClearActionKey(action, currentKey)
    KeyMapper.ClearUserKeyMapping(currentKey)
    -- auto-clear shift action, e.g. 'shift_attack' for 'attack' action
    local target = KeyMapper.GetShiftAction(action, 'orders')
    if target and target.key then
        KeyMapper.ClearUserKeyMapping(target.key)
    end
end

local function EditActionKey(parent, action, currentKey)
    local dialogContent = Group(parent)
    LayoutHelpers.SetDimensions(dialogContent, 400, 170)

    local keyPopup = Popup(popup, dialogContent)

    local cancelButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelButton, dialogContent, 15)
    LayoutHelpers.AtRightIn(cancelButton, dialogContent, -2)
    cancelButton.OnClick = function(self, modifiers)
        keyPopup:Close()
    end

    local okButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtBottomIn(okButton, dialogContent, 15)
    LayoutHelpers.AtLeftIn(okButton, dialogContent, -2)

    local helpText = MultiLineText(dialogContent, UIUtil.bodyFont, 16, UIUtil.fontColor)
    LayoutHelpers.AtTopIn(helpText, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(helpText, dialogContent)
    helpText.Width:Set(dialogContent.Width() - 10)
    helpText:SetText(LOC("<LOC key_binding_0002>Hit the key combination you'd like to assign"))
    helpText:SetCenteredHorizontally(true)

    local keyText = UIUtil.CreateText(dialogContent, FormatKeyName(currentKey), 24)
    keyText:SetColor(UIUtil.factionBackColor)
    LayoutHelpers.Above(keyText, okButton)
    LayoutHelpers.AtHorizontalCenterIn(keyText, dialogContent)

    dialogContent:AcquireKeyboardFocus(false)
    keyPopup.OnClose = function(self)
        dialogContent:AbandonKeyboardFocus()
    end

    local keyCodeLookup = KeyMapper.GetKeyCodeLookup()
    local keyAdder = {}
    local keyPattern

    local function AddKey(keyCode, modifiers)
        local key = keyCodeLookup[keyCode]
        if not key then
            return
        end

        local keyComboName = ""
        keyPattern = ""

        if key ~= 'Ctrl' and modifiers.Ctrl then
            keyPattern = keyPattern .. keyNames['11'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[ keyNames['11'] ]) .. "-"
        end

        if key ~= 'Alt' and modifiers.Alt then
            keyPattern = keyPattern .. keyNames['12'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[ keyNames['12'] ]) .. "-"
        end

        if key ~= 'Shift' and modifiers.Shift then
            keyPattern = keyPattern .. keyNames['10'] .. "-"
            keyComboName = keyComboName .. LOC(properKeyNames[ keyNames['10'] ]) .. "-"
        end

        keyPattern = keyPattern .. key
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

        local function ClearShiftKey()
            KeyMapper.ClearUserKeyMapping("Shift-" .. keyPattern)
            LOG("Keybindings clearing Shift-" .. keyPattern)
        end

        local function MapKey()
            KeyMapper.SetUserKeyMapping(keyPattern, currentKey, action)

            -- auto-assign shift action, e.g. 'shift_attack' for 'attack' action
            local target = KeyMapper.GetShiftAction(action, 'orders')
            if target and not KeyMapper.ContainsKeyModifiers(keyPattern) then
                KeyMapper.SetUserKeyMapping('Shift-' .. keyPattern, target.key, target.name)
            end

            -- checks if hotbuild modifier keys are conflicting with already mapped actions
            local keyMapping = KeyMapper.GetKeyMappingDetails()
            if keyMapping[keyPattern] and keyMapping[keyPattern].category == "HOTBUILDING" then
                local hotKey = "Shift-" .. keyPattern
                if keyMapping[hotKey] then
                    UIUtil.QuickDialog(popup,
                        LOCF("<LOC key_binding_0006>The %s key is already mapped under %s category, are you sure you want to clear it for the following action? \n\n %s"
                            ,
                            hotKey, keyMapping[hotKey].category, keyMapping[hotKey].name),
                        "<LOC _Yes>", ClearShiftKey,
                        "<LOC _No>", nil, nil, nil, true,
                        { escapeButton = 2, enterButton = 1, worldCover = false })
                end
            end
            keyTable = FormatData()
            keyContainer:Filter(keyword)
        end

        -- checks if this key is already assigned to some other action
        local keyMapping = KeyMapper.GetKeyMappingDetails()
        if keyMapping[keyPattern] and keyMapping[keyPattern].id ~= action then
            UIUtil.QuickDialog(popup,
                LOCF("<LOC key_binding_0006>The %s key is already mapped under %s category, are you sure you want to clear it for the following action? \n\n %s"
                    ,
                    keyPattern, keyMapping[keyPattern].category, keyMapping[keyPattern].name),
                "<LOC _Yes>", MapKey,
                "<LOC _No>", nil, nil, nil, true,
                { escapeButton = 2, enterButton = 1, worldCover = false })
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
        if v.selected then
            EditActionKey(popup, v.action, v.key)
            break
        end
    end
end

local function UnbindCurrentSelection()
    for k, v in keyTable do
        if v.selected then
            ClearActionKey(v.action, v.key)
            break
        end
    end
    keyTable = FormatData()
    keyContainer:Filter(keyword)
end

local function GetLineColor(lineID, data)
    if data.type == 'header' then
        return 'FF282828' ----FF282828
    elseif data.type == 'spacer' then
        return '00000000' ----00000000
    elseif data.type == 'entry' then
        if data.selected then
            return UIUtil.factionBackColor
        elseif math.mod(lineID, 2) == 1 then
            return 'ff202020' ----ff202020
        else
            return 'FF343333' ----FF343333
        end
    else
        return 'FF6B0088' ----FF9D06C6
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
    for k, v in keyTable do
        v.selected = false
    end

    if keyTable[dataIndex].type == 'entry' then
        keyTable[dataIndex].selected = true
    end
    keyContainer:Filter(keyword)
end

function CreateToggle(parent, bgColor, txtColor, bgSize, txtSize, txt)
    if not bgSize then bgSize = 20 end
    if not bgColor then bgColor = 'FF343232' end -- --FF343232
    if not txtColor then txtColor = UIUtil.factionTextColor end
    if not txtSize then txtSize = 18 end
    if not txt then txt = '?' end

    local button = Bitmap(parent)
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

    button.OnMouseClick = function(self) -- override for mouse clicks
        return false
    end

    button.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            button:SetAlpha(1.0)
            button.txt:SetAlpha(1.0)
        elseif event.Type == 'MouseExit' then
            button:SetAlpha(0.8)
            button.txt:SetAlpha(0.8)
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            return button:OnMouseClick()
        end
        return false
    end

    return button
end

-- create a line with dynamically updating UI elements based on type of data line
function CreateLine()
    local keyBindingWidth = 210
    local line = Bitmap(keyContainer)
    line.Left:Set(keyContainer.Left)
    line.Right:Set(keyContainer.Right)
    LayoutHelpers.SetHeight(line, 20)

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
    line.statistics:SetColor('FF9A9A9A') ----FF9A9A9A'
    line.statistics:SetAlpha(0.9)

    Tooltip.AddControlTooltip(line.statistics,
        {
            text = '<LOC key_binding_0014>Category Statistics',
            body = '<LOC key_binding_0015>Show total of bound actions and total of all actions in this category of keys'
        })

    LayoutHelpers.AtLeftIn(line.description, line, keyBindingWidth)
    LayoutHelpers.AtVerticalCenterIn(line.description, line)
    LayoutHelpers.LeftOf(line.key, line.description, 30)
    LayoutHelpers.AtVerticalCenterIn(line.key, line)
    LayoutHelpers.AtRightIn(line.statistics, line, 10)
    LayoutHelpers.AtVerticalCenterIn(line.statistics, line)

    line.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            line:SetAlpha(0.9)
            line.key:SetAlpha(1.0)
            line.description:SetAlpha(1.0)
            line.statistics:SetAlpha(1.0)
            PlaySound(Sound({ Cue = "UI_Menu_Rollover_Sml", Bank = "Interface" }))
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
                PlaySound(Sound({ Cue = "UI_Menu_MouseDown_Sml", Bank = "Interface" }))
                return true
            end
        end
        return false
    end

    line.AssignKeyBinding = function(self)
        SelectLine(self.data.index)
        AssignCurrentSelection()
    end

    line.UnbindKeyBinding = function(self)
        if keyTable[self.data.index].key then
            SelectLine(self.data.index)
            UnbindCurrentSelection()
        end
    end

    line.toggle = CreateToggle(line,
        'FF1B1A1A', ----FF1B1A1A'
        UIUtil.factionTextColor,
        line.key.Height() + 4, 18, '+')
    LayoutHelpers.AtLeftIn(line.toggle, line, keyBindingWidth - 30)
    LayoutHelpers.AtVerticalCenterIn(line.toggle, line)
    Tooltip.AddControlTooltip(line.toggle,
        {
            text = '<LOC key_binding_0010>Toggle Category',
            body = '<LOC key_binding_0011>Toggle visibility of all actions for this category of keys'
        })

    line.wikiButton = UIUtil.CreateBitmap(line, '/textures/ui/common/mods/mod_url_website.dds')
    LayoutHelpers.SetDimensions(line.wikiButton, 20, 20)

    -- LayoutHelpers.AtVerticalCenterIn(line.assignKeyButton, line)
    LayoutHelpers.RightOf(line.wikiButton, line.key, 4)
    LayoutHelpers.AtVerticalCenterIn(line.wikiButton, line.key)
    line.wikiButton:SetAlpha(0.5)
    line.wikiButton.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetAlpha(1.0, false)
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(0.5, false)
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local url = "http://wiki.faforever.com/" .. tostring(self.url)
            OpenURL(url)
        end
        return true
    end
    
    import("/lua/ui/game/tooltip.lua").AddControlTooltipManual(line.wikiButton, 'Learn more on the Wiki of FAForever', '', 0, 140, 6, 14, 14, 'left')

    line.assignKeyButton = CreateToggle(line,
        '645F5E5E', ----735F5E5E'
        'FFAEACAC', ----FFAEACAC'
        line.key.Height() + 4, 18, '+')
    LayoutHelpers.AtLeftIn(line.assignKeyButton, line)
    LayoutHelpers.AtVerticalCenterIn(line.assignKeyButton, line)
    Tooltip.AddControlTooltip(line.assignKeyButton,
        {
            text = "<LOC key_binding_0003>Assign Key",
            body = '<LOC key_binding_0012>Opens a dialog that allows assigning key binding for a given action'
        })
    line.assignKeyButton.OnMouseClick = function(self)
        line:AssignKeyBinding()
        return true
    end

    line.unbindKeyButton = CreateToggle(line,
        '645F5E5E', ----645F5E5E'
        'FFAEACAC', ----FFAEACAC'
        line.key.Height() + 4, 18, 'x')
    LayoutHelpers.AtRightIn(line.unbindKeyButton, line)
    LayoutHelpers.AtVerticalCenterIn(line.unbindKeyButton, line)
    Tooltip.AddControlTooltip(line.unbindKeyButton,
        {
            text = "<LOC key_binding_0007>Unbind Key",
            body = '<LOC key_binding_0013>Removes currently assigned key binding for a given action'
        })

    line.unbindKeyButton.OnMouseClick = function(self)
        line:UnbindKeyBinding()
        return true
    end

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
                keyGroups[data.category].visible
            line.toggle:Show()
            line.assignKeyButton:Hide()
            line.unbindKeyButton:Hide()
            line.wikiButton:Hide()
            line.description:SetText(data.text)
            line.description:SetFont(UIUtil.titleFont, 16)
            line.description:SetColor(UIUtil.factionTextColor)
            line.key:SetText('')
            line.statistics:SetText(stats)
        elseif data.type == 'spacer' then
            line.toggle:Hide()
            line.assignKeyButton:Hide()
            line.unbindKeyButton:Hide()
            line.wikiButton:Hide()
            line.key:SetText('')
            line.description:SetText('')
            line.statistics:SetText('')
        elseif data.type == 'entry' then
            line.toggle:Hide()
            line.key:SetText(data.keyText)
            line.key:SetColor('ffffffff') ----ffffffff'
            line.key:SetFont('Arial', 16)
            line.description:SetText(data.text)
            line.description:SetFont('Arial', 16)
            line.description:SetColor(UIUtil.fontColor)
            line.statistics:SetText('')
            line.unbindKeyButton:Show()
            line.assignKeyButton:Show()

            if (data.wikiURL) then
                line.wikiButton.url = tostring(data.wikiURL)
                line.wikiButton:Show()
            else
                line.wikiButton.url = ""
                line.wikiButton:Hide()
            end
        end
    end
    return line
end

function CloseUI()
    LOG('Keybindings CloseUI')
    if popup then
        popup:Close()
        popup = false
    end
end

function CreateUI()
    LOG('Keybindings CreateUI')
    if WorldIsLoading() or (import("/lua/ui/game/gamemain.lua").supressExitDialog == true) then
        return
    end

    if popup then
        CloseUI()
        return
    end
    keyword = ''
    keyTable = FormatData()

    local dialogContent = Group(GetFrame(0))
    LayoutHelpers.SetDimensions(dialogContent, 980, 730)

    popup = Popup(GetFrame(0), dialogContent)
    popup.OnShadowClicked = CloseUI
    popup.OnEscapePressed = CloseUI
    popup.OnDestroy = function(self)
        RemoveInputCapture(dialogContent)
    end

    local title = UIUtil.CreateText(dialogContent, LOC("<LOC key_binding_0000>Key Bindings"), 22)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local offset = dialogContent.Width() / 5.25

    popup.OnClosed = function(self)
        ConfirmNewKeyMap()
    end

    local defaultButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/",
        "<LOC key_binding_0004>Default Preset")
    LayoutHelpers.SetWidth(defaultButton, 200)
    LayoutHelpers.AtBottomIn(defaultButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(defaultButton, dialogContent,
        (offset - (defaultButton.Width() * 3 / 4)) / LayoutHelpers.GetPixelScaleFactor())
    defaultButton.OnClick = function(self, modifiers)
        UIUtil.QuickDialog(popup,
            "<LOC key_binding_0005>Are you sure you want to reset all key bindings to the default (GPG) preset?",
            "<LOC _Yes>", ResetBindingToDefaultKeyMap,
            "<LOC _No>", nil, nil, nil, true,
            { escapeButton = 2, enterButton = 1, worldCover = false })
    end
    Tooltip.AddControlTooltip(defaultButton,
        {
            text = "<LOC key_binding_0004>Default Preset",
            body = '<LOC key_binding_0022>Reset all key bindings to the default (GPG) preset'
        })

    local hotbuildButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/",
        "<LOC key_binding_0009>Hotbuild Preset")
    LayoutHelpers.SetWidth(hotbuildButton, 200)
    LayoutHelpers.AtBottomIn(hotbuildButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(hotbuildButton, defaultButton,
        (offset + (defaultButton.Width() * 1 / 4)) / LayoutHelpers.GetPixelScaleFactor())
    hotbuildButton.OnClick = function(self, modifiers)
        UIUtil.QuickDialog(popup,
            "<LOC key_binding_0008>Are you sure you want to reset all key bindings to the hotbuild (FAF) preset?",
            "<LOC _Yes>", ResetBindingToHotbuildKeyMap,
            "<LOC _No>", nil, nil, nil, true,
            { escapeButton = 2, enterButton = 1, worldCover = false })
    end
    Tooltip.AddControlTooltip(hotbuildButton,
        {
            text = "<LOC key_binding_0009>Hotbuild Preset",
            body = '<LOC key_binding_0020>Reset all key bindings to the hotbuild (FAF) preset'
        })

    local alternativeButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/",
        "<LOC key_binding_0025>Alternative Preset")
    LayoutHelpers.SetWidth(alternativeButton, 200)
    LayoutHelpers.AtBottomIn(alternativeButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(alternativeButton, hotbuildButton,
        (offset + (defaultButton.Width() * 1 / 4)) / LayoutHelpers.GetPixelScaleFactor())
    alternativeButton.OnClick = function(self, modifiers)
        UIUtil.QuickDialog(popup,
            "<LOC key_binding_0024>Are you sure you want to reset all key bindings to the alternative (FAF) preset?",
            "<LOC _Yes>", ResetBindingToalternativeKeyMap,
            "<LOC _No>", nil, nil, nil, true,
            { escapeButton = 2, enterButton = 1, worldCover = false })
    end
    Tooltip.AddControlTooltip(alternativeButton,
        {
            text = "<LOC key_binding_0025>Alternative Preset",
            body = '<LOC key_binding_0026>Reset all key bindings to the alternative (FAF) preset'
        })

    local closeButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC _Close>"))
    LayoutHelpers.SetWidth(closeButton, 200)
    LayoutHelpers.AtBottomIn(closeButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(closeButton, alternativeButton,
        (offset + (defaultButton.Width() * 1 / 4)) / LayoutHelpers.GetPixelScaleFactor())
    Tooltip.AddControlTooltip(closeButton,
        {
            text = '<LOC _Close>Close',
            body = '<LOC key_binding_0021>Closes this dialog and confirms assignments of key bindings'
        })
    closeButton.OnClick = function(self, modifiers)
        -- confirmation of changes will occur on OnClosed of this UI
        CloseUI()
    end

    dialogContent.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 342 then
                closeButton:OnClick()
            end
        end
    end
    keyFilter = Bitmap(dialogContent)

    keyFilter.label = UIUtil.CreateText(dialogContent, '<LOC key_binding_0023>Filter', 17)
    keyFilter.label:SetColor('FF929191') -- --FF929191
    keyFilter.label:SetFont(UIUtil.titleFont, 17)
    LayoutHelpers.AtVerticalCenterIn(keyFilter.label, keyFilter, 2)
    LayoutHelpers.AtLeftIn(keyFilter.label, dialogContent, 9)

    keyFilter:SetSolidColor('FF282828')
    LayoutHelpers.AnchorToRight(keyFilter, keyFilter.label, 5)
    LayoutHelpers.AtRightIn(keyFilter, dialogContent, 6)
    LayoutHelpers.AnchorToBottom(keyFilter, title, 10)
    LayoutHelpers.AtBottomIn(keyFilter, title, -40)
    keyFilter.Width:Set(function() return keyFilter.Right() - keyFilter.Left() end)
    keyFilter.Height:Set(function() return keyFilter.Bottom() - keyFilter.Top() end)

    keyFilter:EnableHitTest()
    import("/lua/ui/game/tooltip.lua").AddControlTooltip(keyFilter,
        {
            text = '<LOC key_binding_0018>Key Binding Filter',
            body = '<LOC key_binding_0019>' ..
                'Filter all actions by typing either:' ..
                '\n - full key binding "CTRL+K"' ..
                '\n - partial key binding "CTRL"' ..
                '\n - full action name "Self-Destruct"' ..
                '\n - partial action name "Self"' ..
                '\n\n Note that collapsing of key categories is disabled while this filter contains some text'
        }, nil)

    local text = LOC("<LOC key_binding_filterInfo>Type key binding or name of action")
    keyFilter.info = UIUtil.CreateText(keyFilter, text, 17, UIUtil.titleFont)
    keyFilter.info:SetColor('FF727171') -- --FF727171
    keyFilter.info:DisableHitTest()
    LayoutHelpers.AtHorizontalCenterIn(keyFilter.info, keyFilter, -7)
    LayoutHelpers.AtVerticalCenterIn(keyFilter.info, keyFilter, 2)

    keyFilter.text = Edit(keyFilter)
    keyFilter.text:SetForegroundColor('FFF1ECEC') -- --FFF1ECEC
    keyFilter.text:SetBackgroundColor('04E1B44A') -- --04E1B44A
    keyFilter.text:SetHighlightForegroundColor(UIUtil.highlightColor)
    keyFilter.text:SetHighlightBackgroundColor("880085EF") ----880085EF
    keyFilter.text.Height:Set(function() return keyFilter.Bottom() - keyFilter.Top() - LayoutHelpers.ScaleNumber(10) end)
    LayoutHelpers.AtLeftIn(keyFilter.text, keyFilter, 5)
    LayoutHelpers.AtRightIn(keyFilter.text, keyFilter)
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
    keyFilter.clear:SetColor('FF8A8A8A') -- --FF8A8A8A
    keyFilter.clear:EnableHitTest()
    LayoutHelpers.AtVerticalCenterIn(keyFilter.clear, keyFilter.text, 1)
    LayoutHelpers.AtRightIn(keyFilter.clear, keyFilter.text, 9)

    keyFilter.clear.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            keyFilter.clear:SetColor('FFC9C7C7') -- --FFC9C7C7
        elseif event.Type == 'MouseExit' then
            keyFilter.clear:SetColor('FF8A8A8A') -- --FF8A8A8A
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            keyFilter.text:SetText('')
            keyFilter.text:AcquireFocus()
        end
        return true
    end
    Tooltip.AddControlTooltip(keyFilter.clear,
        {
            text = '<LOC key_binding_0016>Clear Filter',
            body = '<LOC key_binding_0017>Clears text that was typed in the filter field.'
        })

    keyContainer = Group(dialogContent)
    LayoutHelpers.AtLeftIn(keyContainer, dialogContent, 10)
    LayoutHelpers.AtRightIn(keyContainer, dialogContent, 20)
    LayoutHelpers.AnchorToBottom(keyContainer, keyFilter, 10)
    LayoutHelpers.AnchorToTop(keyContainer, defaultButton, 10)
    keyContainer.Height:Set(function() return keyContainer.Bottom() - keyContainer.Top() - LayoutHelpers.ScaleNumber(10) end)
    keyContainer.top = 0
    UIUtil.CreateLobbyVertScrollbar(keyContainer)

    local index = 1
    keyEntries = {}
    keyEntries[index] = CreateLine()
    LayoutHelpers.AtTopIn(keyEntries[1], keyContainer)

    index = index + 1
    while keyEntries[table.getsize(keyEntries)].Top() + (2 * keyEntries[1].Height()) < keyContainer.Bottom() do
        keyEntries[index] = CreateLine()
        LayoutHelpers.Below(keyEntries[index], keyEntries[index - 1])
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
        self.top = math.max(math.min(size - GetLinesTotal(), top), 0)
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
                line:SetSolidColor('00000000') ----00000000
                line.key:SetText('')
                line.description:SetText('')
                line.statistics:SetText('')
                line.toggle:Hide()
                line.assignKeyButton:Hide()
                line.unbindKeyButton:Hide()
                line.wikiButton:Hide()
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
    local keyData = {}
    local keyLookup = KeyMapper.GetKeyLookup()
    local keyActions = KeyMapper.GetKeyActions()

    -- reset previously formated key actions in all groups because they might have been re-mapped
    for category, group in keyGroups do
        group.actions = {}
    end
    -- group game keys and key defined in mods by their key category
    for k, v in keyActions do
        local category = string.lower(v.category or 'none')
        local keyForAction = keyLookup[k]

        -- create header if it doesn't exist
        if not keyGroups[category] then
            keyGroups[category] = {}
            keyGroups[category].actions = {}
            keyGroups[category].name = category
            keyGroups[category].collapsed = linesCollapsed
            keyGroups[category].order = table.getsize(keyGroups) - 1
            keyGroups[category].text = v.category or keyCategories['none'].text
        end

        local data = {
            action = k,
            key = keyForAction,
            keyText = FormatKeyName(keyForAction),
            category = category,
            order = keyGroups[category].order,
            text = KeyMapper.GetActionName(k),
            wikiURL = v.wikiURL
        }
        table.insert(keyGroups[category].actions, data)
    end
    -- flatten all key actions to a list separated by a header with info about key category
    local index = 1
    for category, group in keyGroups do
        if not table.empty(group.actions) then
            keyData[index] = {
                type = 'header',
                id = index,
                order = keyGroups[category].order,
                count = table.getsize(group.actions),
                category = category,
                text = keyGroups[category].text,
                collapsed = keyGroups[category].collapsed
            }
            index = index + 1
            for _, data in group.actions do
                keyData[index] = {
                    type = 'entry',
                    text = data.text,
                    action = data.action,
                    key = data.key,
                    keyText = LOC(data.keyText),
                    category = category,
                    order = keyGroups[category].order,
                    collapsed = keyGroups[category].collapsed,
                    id = index,
                    wikiURL = data.wikiURL,
                    filters = { -- create filter parameters for quick searching of keys
                        key = string.gsub(string.lower(data.keyText), ' %+ ', ' '),
                        text = string.lower(data.text or ''),
                        action = string.lower(data.action or ''),
                        category = string.lower(data.category or ''),
                    }
                }
                index = index + 1
            end
        end
    end

    SortData(keyData)

    -- store index of a header line for each key line
    local header = 1
    for i, data in keyData do
        if data.type == 'header' then
            header = i
        elseif data.type == 'entry' then
            data.header = header
        end
        data.index = i
    end

    return keyData
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
        local token = string.sub(key, 1, loc - 1)
        result = result .. LookupToken(token) .. ' + '
        key = string.sub(key, loc + 1)
    end

    return result .. LookupToken(key)
end

-- kept for mod backwards compatibility
local Text = import("/lua/maui/text.lua").Text
