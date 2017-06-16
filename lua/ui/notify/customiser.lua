-- This file is the F1 menu used for navigating and interacting with keybindings
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Tooltip = import('/lua/ui/game/tooltip.lua')
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText

local populateMessages = import('/lua/ui/notify/notify.lua').populateMessages
local defaultMessages = import('/lua/ui/notify/defaultmessages.lua')
local defaultMessageTable = defaultMessages.defaultMessages
local clarityTable = defaultMessages.clarityTable
local Prefs = import('/lua/user/prefs.lua')
local factions = import('/lua/factions.lua').FactionIndexMap
local newMessageTable = {}
local lineGroupTable = {}
local LineGroups = {}

local popup = nil
local mainContainer
local messageLines = {}

-- Store indexes of visible lines including headers and key entries
local linesVisible = {}
local linesCollapsed = true

local function EditMessage(parent, data, line)
    local dialogContent = Group(parent)
    dialogContent.Height:Set(150)
    dialogContent.Width:Set(900)

    local messagePopup = Popup(popup, dialogContent)

    local cancelButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelButton, dialogContent, 15)
    LayoutHelpers.AtRightIn(cancelButton, dialogContent, -2)
    cancelButton.OnClick = function(self, modifiers)
        messagePopup:Close()
    end

    local okButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtBottomIn(okButton, dialogContent, 15)
    LayoutHelpers.AtLeftIn(okButton, dialogContent, -2)

    local helpText = MultiLineText(dialogContent, UIUtil.bodyFont, 20, UIUtil.fontColor)
    LayoutHelpers.AtTopIn(helpText, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(helpText, dialogContent)
    helpText.Width:Set(dialogContent.Width() - 10)
    helpText:SetText(clarityTable[data.upgrade])
    helpText:SetCenteredHorizontally(true)
    
    messageEntry = Bitmap(dialogContent)
    messageEntry:SetSolidColor('FF282828')
    messageEntry.Left:Set(function() return dialogContent.Left() + 15 end)
    messageEntry.Right:Set(function() return dialogContent.Right() - 15 end)
    messageEntry.Top:Set(function() return helpText.Bottom() + 15 end)
    messageEntry.Bottom:Set(function() return okButton.Top() - 15 end)
    messageEntry.Width:Set(function() return messageEntry.Right() - messageEntry.Left() end)
    messageEntry.Height:Set(function() return messageEntry.Bottom() - messageEntry.Top() end)
    
    messageEntry.text = Edit(messageEntry)
    messageEntry.text:SetForegroundColor('FFF1ECEC')
    messageEntry.text:SetBackgroundColor('04E1B44A')
    messageEntry.text:SetHighlightForegroundColor(UIUtil.highlightColor)
    messageEntry.text:SetHighlightBackgroundColor("880085EF")
    messageEntry.text.Height:Set(function() return messageEntry.Bottom() - messageEntry.Top() - 10 end)
    messageEntry.text.Left:Set(function() return messageEntry.Left() + 5 end)
    messageEntry.text.Right:Set(function() return messageEntry.Right() end)
    LayoutHelpers.AtVerticalCenterIn(messageEntry.text, messageEntry)
    messageEntry.text:AcquireFocus()
    messageEntry.text:SetText('Insert Message Here')
    messageEntry.text:SetFont(UIUtil.titleFont, 17)
    messageEntry.text:SetMaxChars(60)

    messagePopup.OnClose = function(self)
        dialogContent:AbandonKeyboardFocus()
    end

    okButton.OnClick = function(self, modifiers)
        local newmsg = messageEntry.text:GetText()
        if newmsg ~= 'Insert Message Here' then
            data.message = newmsg
            line.message:SetText(newmsg)
            newMessageTable[data.faction][data.upgrade] = newmsg
        end
        messagePopup:Close()
    end
end

local function AssignCurrentSelection(line)
    for _, data in lineGroupTable do
        if data.selected then
            EditMessage(popup, data, line)
            break
        end
    end
end

local function RemoveCurrentMessage()
    for _, data in lineGroupTable do
        if data.selected then
            data.message = ''
            break
        end
    end
end

local function GetLineColor(lineID, data)
    if data.type == 'header' then
        return 'FF282828'
    elseif data.type == 'spacer' then
        return '00000000'
    elseif data.type == 'entry' then
        if data.selected then
            return UIUtil.factionBackColor
        elseif math.mod(lineID, 2) == 1 then
            return 'ff202020'
        else
            return 'FF343333'
        end
    else
        return 'FF6B0088'
    end
end

-- toggles expansion or collapse of lines with specified key category only if searching is not active
local function ToggleLines(faction)
    -- Set everything invisible to start
    linesVisible = {}
    for index, line in lineGroupTable do
        if line.type == 'entry' then
            if line.faction == faction then
                if line.collapsed then
                    line.collapsed = false
                else
                    line.collapsed = true
                end
            end
            if not line.collapsed then
                table.insert(linesVisible, index)
            end
        else
            table.insert(linesVisible, index) -- Always have non-entry lines visible
        end
    end

    if LineGroups[faction].collapsed then
        LineGroups[faction].collapsed = false
    else
        LineGroups[faction].collapsed = true
    end

    mainContainer:CalcVisible()
end

local function SelectLine(dataIndex)
    for _, data in lineGroupTable do
        data.selected = false
    end

    if lineGroupTable[dataIndex].type == 'entry' then
        lineGroupTable[dataIndex].selected = true
    end
end

function CreateToggle(parent, bgColor, txtColor, bgSize, txtSize, txt)
    if not bgSize then bgSize = 20 end
    if not bgColor then bgColor = 'FF343232' end
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

    button.OnMouseClick = function(self) -- Override for mouse clicks
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

-- Create a line with dynamically updating UI elements based on type of data line
function CreateLine()
    local keyBindingWidth = 280
    local line = Bitmap(mainContainer)
    line.Left:Set(mainContainer.Left)
    line.Right:Set(mainContainer.Right)
    line.Height:Set(20)

    -- Preset key
    line.description = UIUtil.CreateText(line, '', 16, "Arial")
    line.description:DisableHitTest()
    line.description:SetAlpha(0.9)

    -- Preset description
    line.message = UIUtil.CreateText(line, '', 16, "Arial")
    line.message:DisableHitTest()
    line.message:SetClipToWidth(true)
    line.message.Width:Set(line.Right() - line.Left() - keyBindingWidth)
    line.message:SetAlpha(0.9)

    line.Height:Set(function() return line.description.Height() + 4 end)
    line.Width:Set(function() return line.Right() - line.Left() end)

    LayoutHelpers.AtLeftIn(line.message, line, keyBindingWidth)
    LayoutHelpers.AtVerticalCenterIn(line.message, line)
    LayoutHelpers.AtRightIn(line.description, line, line.Width() - keyBindingWidth + 30)
    LayoutHelpers.AtVerticalCenterIn(line.description, line)

    line.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            line:SetAlpha(0.9)
            line.description:SetAlpha(1.0)
            line.message:SetAlpha(1.0)
            PlaySound(Sound({Cue = "UI_Menu_Rollover_Sml", Bank = "Interface"}))
        elseif event.Type == 'MouseExit' then
            line:SetAlpha(1.0)
            line.description:SetAlpha(0.9)
            line.message:SetAlpha(0.9)
        elseif self.data.type == 'entry' then
            if event.Type == 'ButtonPress' then
                SelectLine(self.data.index)
                return true
            elseif event.Type == 'ButtonDClick' then
                SelectLine(self.data.index)
                AssignCurrentSelection(self)
                return true
            end
        elseif self.data.type == 'header' and (event.Type == 'ButtonPress' or event.Type == 'ButtonDClick') then
            ToggleLines(self.data.faction)

            if LineGroups[self.data.faction].collapsed then
               self.toggle.txt:SetText('+')
            else
               self.toggle.txt:SetText('-')
            end
            PlaySound(Sound({Cue = "UI_Menu_MouseDown_Sml", Bank = "Interface"}))
            return true
        end
        return false
    end

    line.AssignNewMessage = function(self)
        SelectLine(self.data.index)
        AssignCurrentSelection(self)
    end

    line.RemoveMessage = function(self)
        if lineGroupTable[self.data.index].text then
            SelectLine(self.data.index)
            RemoveCurrentMessage()
        end
    end

    -- The dropdown button
    line.toggle = CreateToggle(line,
         'FF1B1A1A',
         UIUtil.factionTextColor,
         line.description.Height() + 4, 18, '+')
    LayoutHelpers.AtLeftIn(line.toggle, line, keyBindingWidth - 30)
    LayoutHelpers.AtVerticalCenterIn(line.toggle, line)
    Tooltip.AddControlTooltip(line.toggle,
    {
        text = '<LOC notify_0007>Toggle Faction',
        body = '<LOC notify_0008>Toggle visibility of all messages for this faction'
    })

    -- The + on the left which brings up the assignment dialogue
    line.newMessageButton = CreateToggle(line,
         '645F5E5E',
         'FFAEACAC',
         line.description.Height() + 4, 18, '+')
    LayoutHelpers.AtLeftIn(line.newMessageButton, line)
    LayoutHelpers.AtVerticalCenterIn(line.newMessageButton, line)
    Tooltip.AddControlTooltip(line.newMessageButton,
    {
        text = LOC('<LOC notify_0003>Assign Message'),
        body = '<LOC notify_0004>Opens a dialog that allows assigning a message for a given upgrade'
    })
    line.newMessageButton.OnMouseClick = function(self)
        line:AssignNewMessage()
        return true
    end

    -- The X button to the right of the line
    line.removeMessageButton = CreateToggle(line,
         '645F5E5E',
         'FFAEACAC',
         line.description.Height() + 4, 18, 'x')
    LayoutHelpers.AtRightIn(line.removeMessageButton, line)
    LayoutHelpers.AtVerticalCenterIn(line.removeMessageButton, line)
    Tooltip.AddControlTooltip(line.removeMessageButton,
    {
        text = LOC('<LOC notify_0005>Remove Message'),
        body = '<LOC notify_0006>Removes the message for this upgrade entirely'
    })
    line.removeMessageButton.OnMouseClick = function(self)
        line:RemoveMessage()
        return true
    end

    -- This is where data is assigned to a line from the lineGroupTable by lineID
    line.Update = function(self, data, lineID)
        line:SetSolidColor(GetLineColor(lineID, data))
        line.data = table.copy(data)

        if data.type == 'header' then
            if LineGroups[self.data.faction].collapsed then
               self.toggle.txt:SetText('+')
            else
               self.toggle.txt:SetText('-')
            end
            line.toggle:Show()
            line.newMessageButton:Hide()
            line.removeMessageButton:Hide()
            line.message:SetText(data.text)
            line.message:SetFont(UIUtil.titleFont, 16)
            line.message:SetColor(UIUtil.factionTextColor)
            line.description:SetText('')
        elseif data.type == 'spacer' then
            line.toggle:Hide()
            line.newMessageButton:Hide()
            line.removeMessageButton:Hide()
            line.description:SetText('')
            line.message:SetText('')
        elseif data.type == 'entry' then
            line.toggle:Hide()
            line.description:SetText(clarityTable[data.upgrade])
            line.description:SetColor('ffffffff')
            line.description:SetFont('Arial', 16)
            line.message:SetText(data.text)
            line.message:SetFont('Arial', 16)
            line.message:SetColor(UIUtil.fontColor)
            line.removeMessageButton:Show()
            line.newMessageButton:Show()
        end
    end
    return line
end

function ImportMessages()
    local prefsMessages = Prefs.GetFromCurrentProfile('Notify_Messages')
    if prefsMessages and not table.empty(prefsMessages) then
        messageTable = prefsMessages
    else
        messageTable = defaultMessageTable
        Prefs.SetToCurrentProfile('Notify_Messages', messageTable)
    end
    
    return messageTable
end

function CloseUI()
    if popup then
       popup:Close()
       popup = false
    end
end

function CreateUI()
    if popup then
        CloseUI()
        return
    end

    lineGroupTable = FormatData()
    linesVisible = {}
    
    -- Set headers visible at the start
    for index, line in lineGroupTable do
        if line.type == 'header' then
            table.insert(linesVisible, index)
        end
    end

    local dialogContent = Group(GetFrame(0))
    dialogContent.Width:Set(980)
    dialogContent.Height:Set(730)

    popup = Popup(GetFrame(0), dialogContent)
    popup.OnShadowClicked = CloseUI
    popup.OnEscapePressed = CloseUI
    popup.OnDestroy = function(self)
        RemoveInputCapture(dialogContent)
    end

    local title = UIUtil.CreateText(dialogContent, LOC("<LOC notify_0001>Notify Messages"), 22)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local offset = dialogContent.Width() / 5

    local closeButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", LOC("<LOC _Close>"))
    closeButton.Width:Set(200)
    LayoutHelpers.AtBottomIn(closeButton, dialogContent, 10)
    LayoutHelpers.AtRightIn(closeButton, dialogContent, 10)
    Tooltip.AddControlTooltip(closeButton, {text = 'Close Dialog', body = '<LOC notify_0002>Closes this dialog and confirms assignments of messages'})
    closeButton.OnClick = function(self, modifiers)
        CloseUI() 
    end

    -- Activate the function to have this take effect on closing
    popup.OnClosed = function(self)
        Prefs.SetToCurrentProfile('Notify_Messages', newMessageTable)
        populateMessages()
    end

    -- Handle using keypress to exit
    dialogContent.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 342 then
                closeButton:OnClick()
            end
        end
    end

    -- This contains all the actual dropdowns etc
    mainContainer = Group(dialogContent)
    mainContainer.Left:Set(function() return dialogContent.Left() + 10 end)
    mainContainer.Right:Set(function() return dialogContent.Right() - 20 end)
    mainContainer.Top:Set(function() return title.Bottom() + 10 end)
    mainContainer.Bottom:Set(function() return closeButton.Top() - 10 end)
    mainContainer.Height:Set(function() return mainContainer.Bottom() - mainContainer.Top() - 10 end)
    mainContainer.top = 0
    UIUtil.CreateLobbyVertScrollbar(mainContainer)

    -- Create as many lines as will fit
    local index = 1
    messageLines = {}
    messageLines[index] = CreateLine()
    LayoutHelpers.AtTopIn(messageLines[1], mainContainer)

    index = index + 1
    while messageLines[table.getsize(messageLines)].Top() + messageLines[1].Height() < mainContainer.Bottom() do
        messageLines[index] = CreateLine()
        LayoutHelpers.Below(messageLines[index], messageLines[index-1])
        index = index + 1
    end

    -- Called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- axis can be "Vert" or "Horz"
    mainContainer.GetScrollValues = function(self, axis)
        local size = table.getsize(linesVisible)
        local visibleMax = math.min(self.top + table.getsize(messageLines), size)
        return 0, size, self.top, visibleMax
    end

    -- Called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    mainContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- Called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    mainContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * table.getsize(messageLines))
    end

    -- Called when the scrollbar wants to set a new visible top line
    mainContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end

        local size = table.getsize(linesVisible)
        self.top = math.max(math.min(size - table.getsize(messageLines) , top), 0)
        self:CalcVisible()
    end

    -- Determines what control lines should be visible or not
    mainContainer.CalcVisible = function(self)
        for i, line in messageLines do
            local id = i + self.top
            local index = linesVisible[id]
            local data = lineGroupTable[index]

            if data then
                line:Update(data, id)
            else
                line:SetSolidColor('00000000')
                line.description:SetText('')
                line.message:SetText('')
                line.toggle:Hide()
                line.newMessageButton:Hide()
                line.removeMessageButton:Hide()
            end
        end
    end

    mainContainer.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            control:ScrollLines(nil, lines)
        end
    end
    
    mainContainer:CalcVisible()
end

-- Format the upgrades and messages into groups and lines
function FormatData()
    local lineData = {}
    local messageTable = ImportMessages()
    newMessageTable = messageTable

    -- Reset the lines because messages might have been changed
    for faction, group in LineGroups do
        group.upgrades = {}
    end
    
    -- Group upgrades and messages according to their faction
    for faction, data in messageTable do
        if factions[faction] then
            if not LineGroups[faction] then
                LineGroups[faction] = {}
                LineGroups[faction].upgrades = {}
                LineGroups[faction].name = faction
                LineGroups[faction].order = factions[faction] -- UEF == 1, Cybran == 2 etc
                LineGroups[faction].text = faction
            end

            LineGroups[faction].collapsed = linesCollapsed

            for upgrade, message in data do
                local messageLine = {
                    upgrade = upgrade,
                    faction = faction,
                    order = LineGroups[faction].order,
                    text = message
                }
                table.insert(LineGroups[faction].upgrades, messageLine)
            end
        end
    end

    -- flatten all key actions to a list separated by a header with info about key category
    local index = 1
    for faction, data in LineGroups do
        if table.getsize(data.upgrades) > 0 then
            -- This is the first row
            lineData[index] = {
                type = 'header',
                id = index,
                order = LineGroups[faction].order,
                count = table.getsize(data.upgrades),
                faction = faction,
                text = LineGroups[faction].text,
                collapsed = LineGroups[faction].collapsed
            }
            
            -- Now fill in the rest of the faction's lines
            index = index + 1
            for _, line in data.upgrades do
                lineData[index] = {
                    type = 'entry',
                    text = line.text,
                    upgrade = line.upgrade,
                    faction = faction,
                    order = factions[faction],
                    collapsed = LineGroups[faction].collapsed,
                    id = index,
                }
                index = index + 1
            end
        end
    end

    -- Store index of a header line for each key line
    local header = 1
    for i, data in lineData do
        if data.type == 'header' then
            header = i
        elseif data.type == 'entry' then
            data.header = header
        end
        data.index = i
    end

    return lineData
end
