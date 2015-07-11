--*****************************************************************************
--* File: lua/ui/game/helptext.lua
--* Author: Ted Snook
--* Summary: Help Text Popup
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import('/lua/maui/text.lua').Text

local keydesc = import('/lua/keymap/keydescriptions.lua').keyDescriptions
local properKeyNames = import('/lua/keymap/properKeyNames.lua').properKeyNames
local keyNames = import('/lua/keymap/keyNames.lua').keyNames
local keyCategories = import('/lua/keymap/keycategories.lua').keyCategories

local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

local panel
local keyContainer
local keyTable

local function ResetKeyMap()
    IN_ClearKeyMap()
    import('/lua/keymap/keymapper.lua').ClearUserKeyMap()
    IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyActions(true))
    keyTable = FormatData()
    keyContainer:CalcVisible()
end

local function ConfirmNewKeyMap()
    --add option to accept the changes to the key map?
    IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyMappings(true))
    -- Update hotbuild modifiers
    if SessionIsActive() then
        import('/modules/hotbuild.lua').addModifiers()
    end
end

local function EditActionKey(parent, action, currentKey)
    local dialog = Group(parent, "editActionKeyDialog")
    LayoutHelpers.AtCenterIn(dialog, parent)
    LayoutHelpers.DepthOverParent(dialog, parent, 100)
    dialog.Height:Set(100)
    
    local background = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp_m.dds'))
    background:SetTiled(true)
    dialog.Width:Set(background.Width)
    LayoutHelpers.FillParent(background, dialog)

    local backgroundTop = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp_T.dds'))
    LayoutHelpers.Above(backgroundTop, background)
    local backgroundBottom = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp_b.dds'))
    LayoutHelpers.Below(backgroundBottom, background)
    
    local okButton = UIUtil.CreateButtonStd( background, '/widgets/small', "<LOC _Ok>", 12, 0)
    LayoutHelpers.AtBottomIn(okButton, backgroundBottom, 25)
    LayoutHelpers.AtLeftIn(okButton, backgroundBottom, 30)           

    local cancelButton = UIUtil.CreateButtonStd( background, '/widgets/small', "<LOC _Cancel>", 12, 0)
    LayoutHelpers.AtBottomIn(cancelButton, backgroundBottom, 25)
    LayoutHelpers.AtRightIn(cancelButton, backgroundBottom, 30)
    cancelButton.OnClick = function(self, modifiers)
        dialog:Destroy()
    end          
    
    local helpText = UIUtil.CreateText(background, "<LOC key_binding_0002>Hit the key combination you'd like to assign", 16)
    LayoutHelpers.AtTopIn(helpText, background)
    LayoutHelpers.AtHorizontalCenterIn(helpText, background)
    
    local keyText = UIUtil.CreateText(background, formatkeyname(currentKey), 24)
    LayoutHelpers.AtTopIn(keyText, background, 40)
    LayoutHelpers.AtHorizontalCenterIn(keyText, background)

    dialog:AcquireKeyboardFocus(false)
    dialog.OnDestroy = function(self)
        dialog:AbandonKeyboardFocus()
    end

    local keyCodeLookup = import('/lua/keymap/keymapper.lua').GetKeyCodeLookup()
    local keyAdder = {}
    local currentKeyPattern
    
    local function AddKey(keyCode, modifiers)
       
        if keyCodeLookup[keyCode] != nil then
            local ctrl = false
            local alt = false
            local shift = false

            local key = keyCodeLookup[keyCode]
            
            if key != 'Ctrl' then
                if modifiers.Ctrl == true then
                    ctrl = true
                end
                
                if key != 'Shift' then
                    if modifiers.Shift == true then
                        shift = true
                    end
                
                    if key != 'Alt' then
                        if modifiers.Alt == true then
                            alt = true
                        end
                    end
                end

            end
            
            local keyComboName = ""
            currentKeyPattern = ""
            
            if ctrl == true then
                currentKeyPattern = currentKeyPattern .. keyNames['11'] .. "-"
                keyComboName = keyComboName .. LOC(properKeyNames[keyNames['11']]) .. "-"
            end
            
            if shift == true  then
                currentKeyPattern = currentKeyPattern .. keyNames['10'] .. "-"
                keyComboName = keyComboName .. LOC(properKeyNames[keyNames['10']]) .. "-"
            end
            
            if alt == true  then
                currentKeyPattern = currentKeyPattern .. keyNames['12'] .. "-"
                keyComboName = keyComboName .. LOC(properKeyNames[keyNames['12']]) .. "-"
            end
    
            currentKeyPattern = currentKeyPattern .. key
            keyComboName = keyComboName .. LOC(properKeyNames[key])
            
            keyText:SetText(keyComboName)        
            
        end
    end
    
    dialog.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            AddKey(event.RawKeyCode, event.Modifiers)
        end
    end    

    local function AssignKey()
        -- check if key is already assigned to something else
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
            local cat = Keymapper.KeyCategory(currentKeyPattern, Keymapper.GetCurrentKeyMap(true), Keymapper.GetKeyActions())
            if cat and cat == "hotbuilding" then
                if Keymapper.IsKeyInMap("Shift-" .. currentKeyPattern, Keymapper.GetCurrentKeyMap(true)) then
                    UIUtil.QuickDialog(panel, "Shift-"..currentKeyPattern.. " is already mapped to another action, do you want to clear it for hotbuild?",
                        "<LOC _Yes>", ClearShiftKey,
                        "<LOC _No>", nil,
                        nil, nil,
                        true, 
                        {escapeButton = 2, enterButton = 1, worldCover = false})
                end

                if Keymapper.IsKeyInMap("Alt-" .. currentKeyPattern, Keymapper.GetCurrentKeyMap(true)) then
                    UIUtil.QuickDialog(panel, "Alt-"..currentKeyPattern.. " is already mapped to another action, do you want to clear it for hotbuild?",
                        "<LOC _Yes>", ClearAltKey,
                        "<LOC _No>", nil,
                        nil, nil,
                        true, 
                        {escapeButton = 2, enterButton = 1, worldCover = false})
                end
            end
            keyTable = FormatData()
            keyContainer:CalcVisible()
        end
        if Keymapper.IsKeyInMap(currentKeyPattern, Keymapper.GetCurrentKeyMap(true)) then
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
        dialog:Destroy()
    end          

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

    keyTable = FormatData()

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
        keyContainer:CalcVisible()
    end

    local dialogContent = Group(GetFrame(0))
    dialogContent.Width:Set(593)
    dialogContent.Height:Set(530)

    panel = Popup(GetFrame(0), dialogContent)

    panel.OnDestroy = function(self)
        RemoveInputCapture(dialogContent)
    end

    local title = UIUtil.CreateText(dialogContent, LOC("<LOC key_binding_0000>Key Bindings"), 22)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
    
    local closeButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC _Close>"))
    LayoutHelpers.AtBottomIn(closeButton, dialogContent, 9)
    LayoutHelpers.AtRightIn(closeButton, dialogContent, -2)
    closeButton.OnClick = function(self, modifiers)
        ConfirmNewKeyMap()
        panel:Close()
        panel = false
    end

    local assignKeyButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0003>Assign Key"))
    LayoutHelpers.LeftOf(assignKeyButton, closeButton, 27)
    assignKeyButton.OnClick = function(self, modifiers)
        AssignCurrentSelection()
    end
    
    local unbindKeyButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0007>Unbind Key"))
    LayoutHelpers.LeftOf(unbindKeyButton, assignKeyButton, 27)
    unbindKeyButton.OnClick = function(self, modifiers)
        UnbindCurrentSelection()
    end
    
    local resetButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC key_binding_0004>Reset"))
    LayoutHelpers.LeftOf(resetButton, unbindKeyButton, 27)
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
    
    AddInputCapture(dialogContent)

    keyContainer = Group(dialogContent)
    keyContainer.Height:Set(421)
    keyContainer.Width:Set(562)
    keyContainer.top = 0
    
    LayoutHelpers.AtLeftTopIn(keyContainer, dialogContent, 10, 50)
    UIUtil.CreateLobbyVertScrollbar(keyContainer)
    
    local keyEntries = {}
    
    local function CreateElement(index)
        local entry = {}
        keyEntries[index] = entry

        entry.bg = Bitmap(keyContainer)
        entry.bg.Left:Set(keyContainer.Left)
        entry.bg.Right:Set(keyContainer.Right)
        
        entry.key = UIUtil.CreateText(keyEntries[1].bg, '', 16, "Arial")
        entry.key:DisableHitTest()
        
        entry.description = UIUtil.CreateText(keyEntries[1].bg, '', 16, "Arial")
        entry.description:DisableHitTest()
        entry.description:SetClipToWidth(true)
        -- this is not meant to be a lazy var function since the layout is static
        entry.description.Width:Set(entry.bg.Right() - entry.bg.Left() - 150)
        
        entry.bg.Height:Set(function() return entry.key.Height() + 4 end)
        
        LayoutHelpers.AtVerticalCenterIn(entry.key, entry.bg)
        LayoutHelpers.AtLeftIn(entry.description, entry.bg, 150)
        LayoutHelpers.AtVerticalCenterIn(entry.description, entry.bg)

        entry.bg.HandleEvent = function(self, event)
            local eventHandled = false

            local function SelectLine()
                for k, v in keyTable do
                    if v._selected then
                        v._selected = nil
                    end
                end
                if keyTable[self.dataIndex].type == 'entry' then
                    keyTable[self.dataIndex]._selected = true
                end               
                keyContainer:CalcVisible()
            end
            
            if event.Type == 'ButtonPress' then
                SelectLine()
                eventHandled = true
            elseif event.Type == 'ButtonDClick' then
                SelectLine()
                eventHandled = true
            end

            return eventHandled
        end
    end
    
    CreateElement(1)
    LayoutHelpers.AtTopIn(keyEntries[1].bg, keyContainer)
        
    local index = 2
    while keyEntries[table.getsize(keyEntries)].bg.Top() + (2 * keyEntries[1].bg.Height()) < keyContainer.Bottom() do
        CreateElement(index)
        LayoutHelpers.Below(keyEntries[index].bg, keyEntries[index-1].bg)
        index = index + 1
    end
    
    local numLines = function() return table.getsize(keyEntries) end
    
    local function DataSize()
        return table.getn(keyTable)
    end
    
    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    keyContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    keyContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    keyContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    keyContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    keyContainer.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    keyContainer.CalcVisible = function(self)
        local function GetEntryColor(lineID, selected)
            if selected then
                return 'ff880000'
            end
            if math.mod(lineID, 2) == 1 then
                return 'ff313131'
            else
                return 'ff202020'
            end
        end
        local function SetTextLine(line, data, lineID)
            if data.type == 'header' then
                LayoutHelpers.AtHorizontalCenterIn(line.key, keyContainer)
                line.bg:SetSolidColor('ff506268')
                line.key:SetText(LOC(data.text))
                line.key:SetFont('Arial Bold', 16)
                line.key:SetColor('ffe9e45f')
                line.description:SetText('')
            elseif data.type == 'spacer' then
                line.bg:SetSolidColor('00000000')
                line.key:SetText('')
                line.description:SetText('')
            else
                --LayoutHelpers.AtLeftIn(line.key, line.bg)
                line.key.Left:Set(function() return math.floor((line.bg.Left() + 70) - (line.key.Width() / 2)) end)
                line.bg:SetSolidColor(GetEntryColor(lineID, data._selected))
                line.key:SetText(LOC(data.keyDisp))
                line.key:SetColor('ffffffff')
                line.key:SetFont('Arial', 16)
                line.description:SetText(LOC(data.text or data.action or "<LOC key_binding_0001>No action text"))
                line.bg.dataKey = data.key
                line.bg.dataAction = data.action
                line.bg.dataIndex = lineID
            end
        end
        for i, v in keyEntries do
            if keyTable[i + self.top] then
                SetTextLine(v, keyTable[i + self.top], i + self.top)
            else
                v.bg:SetSolidColor('00000000')
                v.key:SetText('')
                v.description:SetText('')
            end
        end
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
    keyContainer:CalcVisible()
end

--TODO clean up the table names a bit to be more consistent?
function FormatData()
    local keyactions = import('/lua/keymap/keymapper.lua').GetKeyActions(true)

    local retkeys = {}
    local KeyData = {}
    local keyLookup = import('/lua/keymap/keymapper.lua').GetKeyLookup()

    for k, v in keyactions do
        if v.category then
            local keyForAction = keyLookup[k]
            if not keyCategories[v.category] then
                keyCategories[v.category] = v.category
            end
            if not retkeys[v.category] then
                retkeys[v.category] = {}
            end
            table.insert(retkeys[v.category], {id = v.order, desckey = k, key = keyForAction})

        end
    end
    
    for i, v in retkeys do
        table.sort(v, function(val1, val2)
            if val1.id == val2.id then
                
                if keydesc[val1.desckey] and keydesc[val2.desckey] then
                    if keydesc[val1.desckey] >= keydesc[val2.desckey] then
                        return false
                    else
                        return true
                    end
                else
                    return false
                end
            else
                if val1.id >= val2.id then
                    return false
                else
                    return true
                end
            end
        end)
    end
    
    local index = 1
    for i, v in retkeys do
        if index ~= 1 then
            KeyData[index] = {type = 'spacer'}
            index = index + 1
        end
        KeyData[index] = {type = 'header', text = keyCategories[i]}
        index = index + 1
        for currentval, data in v do
            local properKey = formatkeyname(data.key)
            KeyData[index] = {type = 'entry', text = keydesc[data.desckey], keyDisp = properKey, action = data.desckey, key = data.key}
            index = index + 1
        end
    end

    return KeyData
end

function formatkeyname(key)
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
