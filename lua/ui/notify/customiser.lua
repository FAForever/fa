-- This file is the F1 menu used for navigating and interacting with keybindings
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local Tooltip = import("/lua/ui/game/tooltip.lua")
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText

local Notify = import("/lua/ui/notify/notify.lua")
local defaultMessages = import("/lua/ui/notify/defaultmessages.lua")
local NotifyOverlay = import("/lua/ui/notify/notifyoverlay.lua")
local defaultMessageTable = defaultMessages.defaultMessages
local clarityTable = defaultMessages.clarityTable
local Prefs = import("/lua/user/prefs.lua")
local factions = import("/lua/factions.lua").FactionIndexMap
local UTF = import("/lua/utf.lua")
local LazyVar = import("/lua/lazyvar.lua")
local lineGroupTable = {}
local LineGroups = {}

local popup = nil
local mainContainer
local messageLines = {}

-- Store indexes of visible lines including headers and key entries
local linesVisible = {}
local linesCollapsed = true

local NotifyMessages = 'Notify_Messages_ESC'
-- proxy for notify messages
local notifyOptions = LazyVar.Create()

function InitMessages()
    local prefsMessages = UTF.UnescapeTable(Prefs.GetFromCurrentProfile(NotifyMessages))
    if prefsMessages and not table.empty(prefsMessages) then
        for catName, cat in defaultMessageTable do
            if not prefsMessages[catName] then
                prefsMessages[catName] = cat
            else
                local prefsCat = prefsMessages[catName]
                for key, def in cat do
                    if not prefsCat[key] then
                        prefsCat[key] = def
                    end
                end
            end
        end
        notifyOptions:Set(prefsMessages)
    else
        notifyOptions:Set(defaultMessageTable)
    end
end

function init(isReplay, parent)
    notifyOptions.OnDirty = function(self)
        Prefs.SetToCurrentProfile(NotifyMessages, UTF.EscapeTable(self()))
    end
    InitMessages()
    Notify.init(isReplay, parent, notifyOptions)
    NotifyOverlay.init()
end



function SavePrefs(messageTable)
    if messageTable then 
        notifyOptions:Set(messageTable)
    else 
        notifyOptions:OnDirty()
    end
end

local function EditMessage(parent, data, line)
    local dialogContent = Group(parent)
    LayoutHelpers.SetDimensions(dialogContent, 900, 150)

    local messagePopup = Popup(popup, dialogContent)

    local cancelButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtBottomIn(cancelButton, dialogContent, 15)
    LayoutHelpers.AtLeftIn(cancelButton, dialogContent, -2)
    cancelButton.OnClick = function(self, modifiers)
        messagePopup:Close()
    end

    local okButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtBottomIn(okButton, dialogContent, 15)
    LayoutHelpers.AtRightIn(okButton, dialogContent, -2)

    local helpText = MultiLineText(dialogContent, UIUtil.bodyFont, 20, UIUtil.fontColor)
    LayoutHelpers.AtTopIn(helpText, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(helpText, dialogContent)
    helpText.Width:Set(dialogContent.Width() - 10)
    helpText:SetText(clarityTable[data.source])
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
    messageEntry.text:SetText(data.text or 'Insert Message Here')
    messageEntry.text:SetFont(UIUtil.titleFont, 17)
    messageEntry.text:SetMaxChars(60)

    local function ClosePopup()
        local newmsg = messageEntry.text:GetText()
        if newmsg == '' then
            newmsg = defaultMessageTable[data.category][data.source]
        end
        data.text = newmsg
        line.message:SetText(newmsg)
        notifyOptions()[data.category][data.source] = newmsg
        messagePopup:Close()
    end

    messageEntry.text.OnEnterPressed = function(self, text)
        ClosePopup()
    end

    okButton.OnClick = function(self, modifiers)
        ClosePopup()
    end

    messagePopup.OnClose = function(self)
        dialogContent:AbandonKeyboardFocus()
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

local function GetLineColor(lineID, data)
    if data.type == 'header' then
        return 'FF282828'
    elseif data.type == 'spacer' then
        return '00000000'
    elseif data.type == 'entry' then
        if math.mod(lineID, 2) == 1 then
            return 'ff202020'
        else
            return 'FF343333'
        end
    else
        return 'FF6B0088'
    end
end

-- toggles expansion or collapse of lines with specified key category only if searching is not active
local function ToggleLines(category)
    -- Set everything invisible to start
    linesVisible = {}
    for index, line in lineGroupTable do
        if line.type == 'entry' then
            if line.category == category then
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

    if LineGroups[category].collapsed then
        LineGroups[category].collapsed = false
    else
        LineGroups[category].collapsed = true
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
    if not txtColor then txtColor = UIUtil.categoryTextColor end
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
    LayoutHelpers.LeftOf(line.description, line.message, 30)
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
            ToggleLines(self.data.category)

            if LineGroups[self.data.category].collapsed then
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

    line.ResetLine = function(self)
        local category = self.data.category
        local source = self.data.source

        notifyOptions()[category][source] = defaultMessageTable[category][source]
        self.message:SetText(notifyOptions()[category][source])
        SavePrefs()
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
        text = '<LOC notify_0006>Toggle Category',
        body = '<LOC notify_0007>Toggle visibility of all messages for this category'
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
        text = '<LOC notify_0002>Assign Message',
        body = '<LOC notify_0003>Opens a dialog that allows assigning a message for a given source'
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
        text = '<LOC notify_0004>Reset Message',
        body = '<LOC notify_0005>Resets the message for this source to default'
    })
    line.removeMessageButton.OnMouseClick = function(self)
        line:ResetLine()
        return true
    end

    -- This is where data is assigned to a line from the lineGroupTable by lineID
    line.Update = function(self, data, lineID)
        line:SetSolidColor(GetLineColor(lineID, data))
        line.data = table.copy(data)

        if data.type == 'header' then
            if LineGroups[self.data.category].collapsed then
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
            line.description:SetText(clarityTable[data.source])
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



function ResetMessages()
    notifyOptions:Set(defaultMessageTable)
    lineGroupTable = FormatData()
    mainContainer:CalcVisible()
end

function CloseUI()
    if popup then
       popup:Close()
       popup = false
    end
end

function CreateMessageToggleButton(parent, category, size)
    local states = {
        normal   = UIUtil.SkinnableFile('/BUTTON/' .. size .. '/_btn_up.dds'),
        active   = UIUtil.SkinnableFile('/BUTTON/' .. size .. '/_btn_down.dds'),
        over     = UIUtil.SkinnableFile('/BUTTON/' .. size .. '/_btn_over.dds'),
        disabled = UIUtil.SkinnableFile('/BUTTON/' .. size .. '/_btn_dis.dds'),
    }

    local function buttonBehaviour(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(states.active)
            else
                self.checked = false
                self:SetTexture(states.normal)
            end

            Notify.toggleCategoryChat(self.category)

            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end

    local button = UIUtil.CreateButton(parent, states.normal, states.active, states.over, states.disabled, "", 11)

    local active = Prefs.GetFromCurrentProfile('Notify_' .. category .. '_disabled')
    button.checked = not active -- Invert the bool because we want enabled messages (prefs is false) to be lit up (down)

    if not button.checked then
        button:SetTexture(states.normal)
    else
        button:SetTexture(states.active)
    end

    button.category = category
    button.HandleEvent = buttonBehaviour

    return button
end

function CreateUI()
    if popup then
        CloseUI()
        return
    end

    -- Create a properly layed out table from the default messages to be used to construct this UI
    lineGroupTable = FormatData()
    linesVisible = {}

    -- Set headers visible at the start
    for index, line in lineGroupTable do
        if line.type == 'header' then
            table.insert(linesVisible, index)
        end
    end

    -- Create the main box
    local dialogContent = Group(GetFrame(0))
    LayoutHelpers.SetDimensions(dialogContent, 980, 730)

    -- Handle using keypress to exit
    dialogContent.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 342 then
                okButton:OnClick()
            end
        end
    end

    popup = Popup(GetFrame(0), dialogContent)
    popup.OnShadowClicked = CloseUI
    popup.OnEscapePressed = CloseUI
    popup.OnDestroy = function(self)
        RemoveInputCapture(dialogContent)
    end

    -- Activate the function to have this take effect on closing
    popup.OnClosed = function(self)
        SavePrefs()
    end

    local title = UIUtil.CreateText(dialogContent, "<LOC notify_0000>Notify Management", 22)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    -- Button to confirm changes and exit
    local okButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", "<LOC _OK>")
    LayoutHelpers.SetWidth(okButton, 151)
    LayoutHelpers.AtBottomIn(okButton, dialogContent, 10)
    LayoutHelpers.AtRightIn(okButton, dialogContent, 10)
    Tooltip.AddControlTooltip(okButton, {text = '<LOC _Close>Close', body = '<LOC notify_0001>Closes this dialog and confirms assignments of messages'})
    okButton.OnClick = function(self, modifiers)
        CloseUI()
    end

    -- Button to reset everything
    local defaultButton = UIUtil.CreateButtonWithDropshadow(dialogContent, "/BUTTON/medium/", "<LOC notify_0008>Default Preset")
    LayoutHelpers.SetWidth(defaultButton, 151)
    LayoutHelpers.AtBottomIn(defaultButton, dialogContent, 10)
    LayoutHelpers.AtLeftIn(defaultButton, dialogContent, 10)
    defaultButton.OnClick = function(self, modifiers)
        UIUtil.QuickDialog(popup, "<LOC notify_0009>Are you sure you want to reset all messages to their defaults?",
            "<LOC _Yes>", ResetMessages,
            "<LOC _No>", nil, nil, nil, true,
            {escapeButton = 2, enterButton = 1, worldCover = false})
    end
    Tooltip.AddControlTooltip(defaultButton,
        {
            text = "<LOC notify_0008>Default Preset",
            body = "<LOC notify_0010>Reset all messages to their defaults"
        }
    )

    -- Button to toggle Notify as a whole
    local notifyButton = CreateMessageToggleButton(dialogContent, 'all', 'large')
    LayoutHelpers.AtBottomIn(notifyButton, dialogContent, -2)
    LayoutHelpers.AtHorizontalCenterIn(notifyButton, dialogContent, 10)
    notifyButton.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/large/_btn_down.dds'))
                self.label:SetText(LOC('<LOC notify_0029>Notify Enabled'))
            else
                self.checked = false
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/large/_btn_up.dds'))
                self.label:SetText(LOC('<LOC notify_0030>Notify Disabled'))
            end

            Notify.toggleNotifyPermanent(not self.checked)

            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end
    if notifyButton.checked then
        notifyButton.label:SetText(LOC('<LOC notify_0029>Notify Enabled'))
    else
        notifyButton.label:SetText(LOC('<LOC notify_0030>Notify Disabled'))
    end
    Tooltip.AddControlTooltip(notifyButton,
        {
            text = "<LOC notify_0031>Toggle Notify",
            body = "<LOC notify_0032>Toggles all aspects of Notify functionality, leaving subsettings intact for when you want to re-enable the feature"
        }
    )

    -- Set up the toggle buttons
    -- Button to toggle ACU notifications
    local acuButton = CreateMessageToggleButton(dialogContent, 'acus', 'medium')
    acuButton.label:SetText(LOC('<LOC notify_0011>ACUs'))
    LayoutHelpers.SetWidth(acuButton, 151)
    LayoutHelpers.Below(acuButton, title, 10)
    LayoutHelpers.AtLeftIn(acuButton, dialogContent, 10)
    Tooltip.AddControlTooltip(acuButton,
        {
            text = "<LOC notify_0012>Toggle ACUs",
            body = "<LOC notify_0013>Toggles showing ACU upgrade notifications from other players"
        }
    )

    -- Button to toggle Experimental notifications
    local expButton = CreateMessageToggleButton(dialogContent, 'experimentals', 'medium')
    expButton.label:SetText(LOC('<LOC notify_0014>Experimentals'))
    LayoutHelpers.SetWidth(expButton, 151)
    LayoutHelpers.Below(expButton, title, 10)
    LayoutHelpers.RightOf(expButton, acuButton, 10)
    Tooltip.AddControlTooltip(expButton,
        {
            text = "<LOC notify_0015>Toggle Experimentals",
            body = "<LOC notify_0016>Toggles showing Experimental-related notifications from other players"
        }
    )

    -- Button to toggle tech notifications
    local techButton = CreateMessageToggleButton(dialogContent, 'tech', 'medium')
    techButton.label:SetText(LOC('<LOC notify_0017>Tech'))
    LayoutHelpers.SetWidth(techButton, 151)
    LayoutHelpers.Below(techButton, title, 10)
    LayoutHelpers.RightOf(techButton, expButton, 10)
    Tooltip.AddControlTooltip(techButton,
        {
            text = "<LOC notify_0018>Toggle Tech",
            body = "<LOC notify_0019>Toggles showing Tech-Upgrade-related notifications from other players"
        }
    )

    -- Button to toggle 'other' notifications
    local otherButton = CreateMessageToggleButton(dialogContent, 'other', 'medium')
    otherButton.label:SetText(LOC('<LOC notify_0020>Other'))
    LayoutHelpers.SetWidth(otherButton, 151)
    LayoutHelpers.Below(otherButton, title, 10)
    LayoutHelpers.RightOf(otherButton, techButton, 10)
    Tooltip.AddControlTooltip(otherButton,
        {
            text = "<LOC notify_0021>Toggle Other",
            body = "<LOC notify_0022>Toggles showing miscellaneous notifications from other players"
        }
    )

    -- Button to toggle ACU Overlay
    local overlayButton = CreateMessageToggleButton(dialogContent, 'overlay', 'medium')
    overlayButton.label:SetText(LOC('<LOC notify_0023>Overlays'))
    LayoutHelpers.SetWidth(overlayButton, 151)
    LayoutHelpers.Below(overlayButton, title, 10)
    LayoutHelpers.RightOf(overlayButton, otherButton, 10)
    overlayButton.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/medium/_btn_down.dds'))
            else
                self.checked = false
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/medium/_btn_up.dds'))
            end

            NotifyOverlay.toggleOverlay(not self.checked, false)

            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end
    Tooltip.AddControlTooltip(overlayButton,
        {
            text = "<LOC notify_0024>Toggle Overlay",
            body = "<LOC notify_0025>Toggles showing ACU upgrade completion and ETA overlays"
        }
    )

    -- Button to toggle displaying only default messages
    local defaultMessagesButton = CreateMessageToggleButton(dialogContent, 'custom', 'medium')
    defaultMessagesButton.label:SetText(LOC('<LOC notify_0026>Show Custom'))
    LayoutHelpers.SetWidth(defaultMessagesButton, 151)
    LayoutHelpers.Below(defaultMessagesButton, title, 10)
    LayoutHelpers.RightOf(defaultMessagesButton, overlayButton, 10)
    defaultMessagesButton.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/medium/_btn_down.dds'))
            else
                self.checked = false
                self:SetTexture(UIUtil.SkinnableFile('/BUTTON/medium/_btn_up.dds'))
            end

            Notify.toggleCustomMessages(not self.checked)

            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end
    Tooltip.AddControlTooltip(defaultMessagesButton,
        {
            text = "<LOC notify_0027>Toggle Custom",
            body = "<LOC notify_0028>Toggles displaying custom messages from other players instead of default ones"
        }
    )

    -- This contains all the actual dropdowns etc
    mainContainer = Group(dialogContent)
    LayoutHelpers.AtLeftIn(mainContainer, dialogContent, 10)
    LayoutHelpers.AtRightIn(mainContainer, dialogContent, 20)
    LayoutHelpers.AnchorToBottom(mainContainer, acuButton, 10)
    LayoutHelpers.AnchorToTop(mainContainer, okButton, 24)
    mainContainer.Height:Set(function() return mainContainer.Bottom() - mainContainer.Top() - (10) end)
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
    -- Reset the lines because messages might have been changed
    for category, group in LineGroups do
        group.sources = {}
    end
    
    local categories = {
        aeon = 1,
        uef = 2,
        cybran = 3,
        seraphim = 4,
        nomads = 5,
        experimentals = 6,
        tech = 7,
        other = 8,
    }
    
    local messageTable = notifyOptions()
    -- Group upgrades and messages according to their category
    for category, data in messageTable do
        if factions[category] or category == 'experimentals' or category == 'tech' or category == 'other' then
            if not LineGroups[category] then
                LineGroups[category] = {}
                LineGroups[category].sources = {}
                LineGroups[category].name = category
                LineGroups[category].order = categories[category]
                LineGroups[category].text = category
            end

            LineGroups[category].collapsed = linesCollapsed

            for source, message in data do
                local messageLine = {
                    source = source,
                    category = category,
                    order = LineGroups[category].order,
                    text = message
                }
                table.insert(LineGroups[category].sources, messageLine)
            end
        end
    end

    -- flatten all key actions to a list separated by a header with info about key category
    local keys = {}
    for category, data in LineGroups do
        table.insert(keys, {key = category, order = data.order})
        table.sort(data.sources, function(a, b) return a.source < b.source end)
    end
    table.sort(keys, function(a, b) return a.order < b.order end)

    local index = 1
    for _, key in ipairs(keys) do
        local category = key.key
        if not table.empty(LineGroups[category].sources) then
            -- This is the first row
            lineData[index] = {
                type = 'header',
                id = index,
                order = LineGroups[category].order,
                category = category,
                text = LineGroups[category].text,
                collapsed = LineGroups[category].collapsed
            }

            -- Now fill in the rest of the category's lines
            index = index + 1
            for _, line in ipairs(LineGroups[category].sources) do
                lineData[index] = {
                    type = 'entry',
                    text = line.text,
                    source = line.source,
                    category = category,
                    order = categories[category],
                    collapsed = LineGroups[category].collapsed,
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
