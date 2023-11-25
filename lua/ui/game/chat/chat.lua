--**********************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local UiUtilsS = import("/lua/uiutilssorian.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EffectHelpers = import("/lua/maui/effecthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Checkbox = import("/lua/ui/controls/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Window = import("/lua/maui/window.lua").Window
local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local Prefs = import("/lua/user/prefs.lua")
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Tooltip = import("/lua/ui/game/tooltip.lua")
local UIMain = import("/lua/ui/uimain.lua")

local ChatMessage = import("/lua/ui/game/chat/message.lua").ChatMessage
local ChatRecipientPicker = import("/lua/ui/game/chat/recipient.lua").ChatRecipientPicker

local sessionClients = GetSessionClients()
local armies = GetArmiesTable()

-- Features to support:
-- - [x] Send a chat message (as a sim callback)
-- - [x] Receive a chat message (through a sim callback)
-- - [x] Visualize a chat message on screen
-- - [x] Add the user name, faction and color back to the chat
-- - [x] Add a highlight
-- - [x] Autofocus the text input when opened
-- - [ ] Add the origin / color queue of messages (to all, to allies and the whisper)
-- - [ ] Add support for wrapping messages
-- - [ ] Add support for scrolling through the messages
-- - [x] Add support for 'to all' / 'to allies' / 'whisper'

---@param message any
local LOG = function(message)
    _G.LOG("Chat.lua - " .. tostring(message))
end

---@param message any
local WARN = function(message)
    _G.WARN("Chat.lua - " .. tostring(message))
end

---@class UIMessage
---@field ReceivedAtTime number         # timestamp of when it was received
---@field To 'All' | 'Allies' | 'Enemies' | number  # recipient(s)
---@field From number                   # sender
---@field Text string                   # message content
---@field Camera? UserCameraSettings    # some messages contain camera coordinates
---@field EventType?  'Nuke' | 'Resources' | 'Ping-Help' | 'Ping-Attack' | 'Ping-Assist'

local Instance = nil

---@type UIMessage[]
ChatMessages = {}

---@type UIMessage []
EventMessages = {}

---@class UIChatWindow : Window
---@field MessageRows UIChatMessage[]
---@field MessageContent UIMessage[]
---@field WindowState 'Open' | 'Closed'
---@field ProcessChatMessages boolean
---@field ProcessEventMessages boolean
---@field DragControlMap { tl: Bitmap[], tr: Bitmap[], bl: Bitmap[], br: Bitmap[], mr: Bitmap[], ml: Bitmap[], tm: Bitmap[], bm: Bitmap[] }
---@field DragTL Bitmap
---@field DragTR Bitmap
---@field DragBL Bitmap
---@field DragBR Bitmap
---@field EditRecipientsBubble Button
---@field Edit Edit
---@field EditLabel Text
---@field EditGroup Group
---@field EditRecipientsPicker UIChatRecipientPicker
---@field Recipients LazyVar<UIChatRecipient>
ChatWindow = ClassUI(Window) {

    MinimumSizeX = 400,
    MinimumSizeY = 160,

    ---@param self UIChatWindow
    ---@param parent Control
    __init = function(self, parent)
        local title = ""
        local icon = false
        local pin = true
        local config = true
        local lockSize = false
        local lockPosition = false
        local preferenceName = 'UIChat'

        local location = {
            Top = function() return GetFrame(0).Bottom() - LayoutHelpers.ScaleNumber(393) end,
            Left = function() return GetFrame(0).Left() + LayoutHelpers.ScaleNumber(8) end,
            Right = function() return GetFrame(0).Left() + LayoutHelpers.ScaleNumber(430) end,
            Bottom = function() return GetFrame(0).Bottom() - LayoutHelpers.ScaleNumber(238) end,
        }

        local textures = {
            tl = UIUtil.UIFile('/game/chat_brd/chat_brd_ul.dds'),
            tr = UIUtil.UIFile('/game/chat_brd/chat_brd_ur.dds'),
            tm = UIUtil.UIFile('/game/chat_brd/chat_brd_horz_um.dds'),
            ml = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_l.dds'),
            m = UIUtil.UIFile('/game/chat_brd/chat_brd_m.dds'),
            mr = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_r.dds'),
            bl = UIUtil.UIFile('/game/chat_brd/chat_brd_ll.dds'),
            bm = UIUtil.UIFile('/game/chat_brd/chat_brd_lm.dds'),
            br = UIUtil.UIFile('/game/chat_brd/chat_brd_lr.dds'),
            borderColor = 'ff415055',
        }

        Window.__init(self, parent, title, icon, pin, config, lockSize, lockPosition, preferenceName, location, textures)

        self.WindowState = 'Open'

        -- custom draggers setup: top-left / top-right / bottom-left / bottom-right

        self.DragTL = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        self.DragTR = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        self.DragBL = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        self.DragBR = Bitmap(self, UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

        self.DragControlMap = {
            tl = { self.DragTL },
            tr = { self.DragTR },
            bl = { self.DragBL },
            br = { self.DragBR },
            mr = { self.DragBR, self.DragTR },
            ml = { self.DragBL, self.DragTL },
            tm = { self.DragTL, self.DragTR },
            bm = { self.DragBL, self.DragBR },
        }

        self.DragTL.textures = {
            up = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_over.dds')
        }

        self.DragTR.textures = {
            up = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_over.dds')
        }

        self.DragBL.textures = {
            up = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_over.dds')
        }

        self.DragBR.textures = {
            up = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_over.dds')
        }

        -- content of the chat window

        self.ProcessChatMessages = true
        self.ProcessEventMessages = true
        self.MessageContent = {}

        local contentGroup = self:GetClientGroup()

        self.EditGroup = Group(contentGroup)
        self.EditLabel = UIUtil.CreateText(self.EditGroup, 'To all:', 14, 'Arial')
        self.Edit = Edit(self.EditGroup)

        self.EditRecipientsBubble = UIUtil.CreateButton(self,
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
            UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))

        self.EditRecipientsPicker = ChatRecipientPicker(self)

        self.Edit.OnEnterPressed = function(control, text)
            if text == '' then
                self:OnToggle()
                return
            end

            -- sync it to other players

            SimCallback({
                Func = 'DistributeChatMessage',
                Args = {
                    From = GetFocusArmy(),
                    To = self.Recipients().Identifier,
                    Text = text,
                }
            })
        end

        self.MessageRows = {}
        for k = 1, 50 do
            self.MessageRows[k] = ChatMessage(self)
        end

        AddOnSyncHashedCallback(
        ---@param messages UIMessage[]
            function(messages)
                if messages then
                    for _, message in messages do
                        if self:ValidateMessage(message) then
                            -- keep track of when we received it
                            message.ReceivedAtTime = GetGameTimeSeconds()
                            table.insert(ChatMessages, message)
                            self:UpdateMessages()
                        else
                            WARN(string.format("Malformed chat data: %s", GetCurrentCommandSource(), reprs(message)))
                        end
                    end
                end

                LOG(repru(ChatMessages))

            end, 'ReceiveChatMessage', 'Chat.lua'
        )

        AddOnSyncHashedCallback(
        ---@param messages UIMessage[]
            function(messages)
                if messages then
                    for _, message in messages do
                        if self:ValidateMessage(message) then
                            -- keep track of when we received it
                            message.ReceivedAtTime = GetGameTimeSeconds()
                            table.insert(EventMessages, message)
                            self:UpdateMessages()
                        else
                            WARN(string.format("Malformed event data: %s", GetCurrentCommandSource(), reprs(message)))
                        end
                    end
                end

                LOG(repru(EventMessages))

            end, 'ReceiveEventMessage', 'Chat.lua'
        )
    end,

    ---@param self UIChatWindow
    ---@param parent Control
    __post_init = function(self, parent)

        self:SetMinimumResize(self.MinimumSizeX, self.MinimumSizeY)

        ---@type UIChatRecipient
        local defaultRecipient = { Identifier = 'All', Name = 'To all:' }
        self.Recipients = import("/lua/lazyvar.lua").Create(defaultRecipient)

        ---@param lazyvar LazyVar<UIChatRecipient>
        self.Recipients.OnDirty = function(lazyvar)
            self.EditLabel:SetText(lazyvar().Name)
        end

        -- state that users can change
        self.WindowAlpha = import("/lua/lazyvar.lua").Create()
        self.WindowAlpha.OnDirty = function(lazyvar)
            local value = lazyvar()
            if value > 1.0 then
                return
            end

            if value < 0.0 then
                return
            end

            self:SetAlpha(value)
        end

        -- custom draggers setup: top-left / top-right / bottom-left / bottom-right

        LayoutHelpers.LayoutFor(self.DragTL)
            :AtLeftTopIn(self, -26, -6)
            :Over(self, 20)
            :DisableHitTest(true)

        LayoutHelpers.LayoutFor(self.DragTR)
            :AtRightTopIn(self, -22, -8)
            :Over(self, 20)
            :DisableHitTest(true)

        LayoutHelpers.LayoutFor(self.DragBL)
            :AtLeftBottomIn(self, -26, -8)
            :Over(self, 20)
            :DisableHitTest(true)

        LayoutHelpers.LayoutFor(self.DragBR)
            :AtRightBottomIn(self, -22, -8)
            :Over(self, 20)
            :DisableHitTest(true)

        -- content of the chat window

        local contentGroup = self:GetClientGroup()

        LayoutHelpers.LayoutFor(self.EditGroup)
            :Bottom(contentGroup.Bottom)
            :Right(contentGroup.Right)
            :Left(contentGroup.Left)
            :Height(self.Edit.Height)

        LayoutHelpers.LayoutFor(self.EditLabel)
            :AtBottomIn(self.EditGroup, 1)
            :AtLeftIn(self.EditGroup, 35)

        LayoutHelpers.LayoutFor(self.Edit)
            :AnchorToRight(self.EditLabel, 5)
            :AtRightIn(self.EditGroup, 50)
            :Over(self, 200)
            :AtBottomIn(self.EditGroup, 1)
            :Height(function() return self.Edit:GetFontHeight() end)

        UIUtil.SetupEditStd(self.Edit, "ff00ff00", nil, "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
        self.Edit:SetDropShadow(true)
        self.Edit:ShowBackground(false)

        LayoutHelpers.LayoutFor(self.EditRecipientsBubble)
            :CenteredLeftOf(self.EditLabel, 8)
            :Over(self, 10)

        self.EditRecipientsBubble.OnClick = function(editRecipientsBubble)
            if self.EditRecipientsPicker:IsHidden() then
                self.EditRecipientsPicker:Show()
            else
                self.EditRecipientsPicker:Hide()
            end
        end

        LayoutHelpers.LayoutFor(self.EditRecipientsPicker)
            :Above(self.EditRecipientsBubble, 15)
            :AtLeftIn(self.EditRecipientsBubble, 15)
            :Hide()

        self.EditRecipientsPicker:AddOnRecipientPickedCallback(
            function(recipient)
                self.Recipients:Set(recipient)
            end, 'Chat.lua'
        )

        for k = 1, 50 do
            ---@type UIChatMessage
            local chatMessage = self.MessageRows[k]
            LayoutHelpers.LayoutFor(chatMessage)
                :AtRightIn(contentGroup, 2)
                :AtLeftTopIn(contentGroup, 8, 2 + (k - 1) * 16)
                :Height(16)
        end

        self:UpdateMessages()
    end,

    ---------------------------------------------------------------------------
    --#region UI events

    ---@param self UIChatWindow
    ---@param event any
    ---@param xControl number
    ---@param yControl number
    ---@param cursor any
    ---@param controlID any
    RolloverHandler = function(self, event, xControl, yControl, cursor, controlID)
        if self._lockSize then
            return
        end

        local controlMap = self.DragControlMap
        local styles = import("/lua/maui/window.lua").styles
        if not self._sizeLock then
            if event.Type == 'MouseEnter' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        reprsl(control)
                        control:SetTexture(control.textures.over)
                    end
                end
                GetCursor():SetTexture(styles.cursorFunc(cursor))
            elseif event.Type == 'MouseExit' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.up)
                    end
                end
                GetCursor():Reset()
            elseif event.Type == 'ButtonPress' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.down)
                    end
                end
                self.StartSizing(event, xControl, yControl)
                self._sizeLock = true
            end
        end
    end,

    ---@param self UIChatWindow
    OnResizeSet = function(self)
        self.DragTL:SetTexture(self.DragTL.textures.up)
        self.DragTR:SetTexture(self.DragTR.textures.up)
        self.DragBL:SetTexture(self.DragBL.textures.up)
        self.DragBR:SetTexture(self.DragBR.textures.up)
        self.Edit:AcquireFocus()
    end,

    ---@param self UIChatWindow
    OnMoveSet = function(self)
        self.Edit:AcquireFocus()
    end,

    ---@param self UIChatWindow
    OnOpen = function(self)
        self.WindowState = 'Open'
        self.Edit:AcquireFocus()

        local isEditRecipientsPickerHidden =  self.EditRecipientsPicker:IsHidden()
        self:Show()

        if isEditRecipientsPickerHidden then
            self.EditRecipientsPicker:Hide()
        end
    end,

    ---@param self UIChatWindow
    OnClose = function(self)
        self.WindowState = 'Closed'
        self:Hide()
    end,

    ---@param self UIChatWindow
    OnToggle = function(self)
        if self.WindowState == 'Open' then
            self:OnClose()
        else
            self:OnOpen()
        end
    end,

    --#endregion

    ---@param self UIChatWindow
    ---@param message UIMessage
    ValidateMessage = function(self, message)
        local ok, msg = import("/lua/shared/chat.lua").ValidateMessage(message)
        if not ok then
            WARN(msg)
        end

        return ok
    end,

    ---@param a UIMessage
    ---@param b UIMessage
    SortMessageCriteria = function(a, b)
        return a.ReceivedAtTime < b.ReceivedAtTime
    end,

    ---@param self UIChatWindow
    UpdateMessages = function(self)
        local messages = self.MessageContent
        local count = table.getn(messages)

        local head = 1
        if self.ProcessChatMessages then
            for k = 1, table.getn(ChatMessages) do
                messages[head] = ChatMessages[k]
                head = head + 1
            end
        end

        if self.ProcessEventMessages then
            for k = 1, table.getn(EventMessages) do
                messages[head] = EventMessages[k]
                head = head + 1
            end
        end

        -- clear out remaining messages
        for k = head, count do
            messages[k] = nil
        end

        table.sort(messages, self.SortMessageCriteria)
        self:ShowMessages()
    end,

    ---@param self UIChatWindow
    ShowMessages = function(self)
        local messages = self.MessageContent
        local messageCount = table.getn(messages)
        for k = 1, messageCount do
            local chatMessage = self.MessageRows[k]
            chatMessage:ProcessMessage(messages[k])
        end
    end,
}

--- Opens the chat window
function OpenWindow()
    if not Instance then
        Instance = ChatWindow(GetFrame(0))
    end

    Instance:OnOpen()
end

--- Closes the chat window
function CloseWindow()
    if Instance then
        Instance:OnClose()
    end
end

--- Toggle the chat window, showing or hiding it if it was hidden or shown respectively
function ToggleWindow()
    if Instance then
        Instance:OnToggle()
    else
        OpenWindow()
    end

end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Instance then
        Instance:Destroy()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnReload(newModule)
    newModule.ChatMessages = ChatMessages
    newModule.EventMessages = EventMessages
end
