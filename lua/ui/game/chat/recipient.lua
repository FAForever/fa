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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

local armies = GetArmiesTable()

---@param message any
local LOG = function(message)
    _G.LOG("ChatRecipientPicker.lua - " .. tostring(message))
end

---@param message any
local WARN = function(message)
    _G.WARN("ChatRecipientPicker.lua - " .. tostring(message))
end

---@alias UIMessageRecipients 'All' | 'Allies' | 'Enemies' | number

---@class UIMessage
---@field ReceivedAtTime number         # timestamp of when it was received
---@field To UIMessageRecipients        # recipient(s)
---@field From number                   # sender
---@field Text string                   # message content
---@field Camera? UserCameraSettings    # some messages contain camera coordinates
---@field EventType?  'Nuke' | 'Resources' | 'Ping-Help' | 'Ping-Attack' | 'Ping-Assist'

---@class UIChatRecipient
---@field Name string
---@field Identifier UIMessageRecipients

---@class UIChatRecipientPicker : Group
---@field BackgroundTL Bitmap
---@field BackgroundTR Bitmap
---@field BackgroundBR Bitmap
---@field BackgroundBL Bitmap
---@field BackgroundLeft Bitmap
---@field BackgroundRight Bitmap
---@field BackgroundTop Bitmap
---@field BackgroundBottom Bitmap
---@field Recipients UIChatRecipient[]
---@field RecipientControls (Group | { Text: Text, Bitmap: Bitmap })[]
---@field OnRecipientPickedCallbacks table<string, fun(recipient: UIChatRecipient)>
ChatRecipientPicker = ClassUI(Group) {

    RecipientCount = 20,

    ---@param self UIChatRecipientPicker
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'ChatRecipientPicker')
        self.BackgroundTL = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ul.dds')
        self.BackgroundTR = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ur.dds')
        self.BackgroundBR = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_lr.dds')
        self.BackgroundBL = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ll.dds')
        self.BackgroundLeft = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_vert_l.dds')
        self.BackgroundRight = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_vert_r.dds')
        self.BackgroundTop = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_horz_um.dds')
        self.BackgroundBottom = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_lm.dds')

        self.Recipients = {}
        self.OnRecipientPickedCallbacks = { }

        self.RecipientControls = {}
        for k = 1, self.RecipientCount do
            local group = Group(self)
            group.Text = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
            group.Bitmap = UIUtil.CreateBitmapColor(group, 'ff000000')
            self.RecipientControls[k] = group
        end
    end,

    ---@param self UIChatRecipientPicker
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Over(parent, 10)

        LayoutHelpers.LayoutFor(self.BackgroundTL)
            :Right(self.Left)
            :Bottom(self.Top)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundTR)
            :Left(self.Right)
            :Bottom(self.Top)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundBR)
            :Left(self.Right)
            :Top(self.Bottom)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundBL)
            :Right(self.Left)
            :Top(self.Bottom)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundLeft)
            :Right(self.Left)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundRight)
            :Left(self.Right)
            :Top(self.Top)
            :Bottom(self.Bottom)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundTop)
            :Left(self.Left)
            :Right(self.Right)
            :Bottom(self.Top)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.BackgroundBottom)
            :Left(self.Left)
            :Right(self.Right)
            :Top(self.Bottom)
            :DisableHitTest()

        local recipientControls = self.RecipientControls
        for k = 1, self.RecipientCount do
            -- local scope for references
            local index = k

            local controls = recipientControls[index]
            LayoutHelpers.LayoutFor(controls)
                :Width(controls.Text.Width)
                :Height(controls.Text.Height)
                :AtLeftTopIn(self, 4, (index - 1) * 12)
                :DisableHitTest()

            LayoutHelpers.LayoutFor(controls.Text)
                :AtLeftTopIn(controls)
                :Color('ffffffff')
                :DisableHitTest()

            LayoutHelpers.LayoutFor(controls.Bitmap)
                :Color('ff000000')
                :Under(controls.Text)
                :AtLeftTopIn(controls.Text, 0, 0)
                :AtRightBottomIn(controls.Text, 0, 0)
                :FillHorizontally(self)

            ---@param bitmap Bitmap
            ---@param event KeyEvent
            controls.Bitmap.HandleEvent = function(bitmap, event)
                local typeOfevent = event.Type
                if typeOfevent == 'MouseEnter' then
                    bitmap:SetSolidColor('ff666666')
                    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Rollover_02'}))
                elseif typeOfevent == 'MouseExit' then
                    bitmap:SetSolidColor('ff000000')
                elseif typeOfevent == 'ButtonPress' then
                    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_02'}))
                    local recipient = self.Recipients[index]
                    if recipient then
                        self:OnRecipientPicked(recipient)
                    end
                end
            end
        end

        self:UpdateEntries()
        self:ShowEntries()
    end,

    ---------------------------------------------------------------------------
    --#region Engine functionality

    --#endregion

    ---------------------------------------------------------------------------
    --#region Callback functionality

    ---@param self UIChatRecipientPicker
    ---@param recipient UIChatRecipient
    OnRecipientPicked = function(self, recipient)
        self:Hide()

        for name, callback in self.OnRecipientPickedCallbacks do
            local ok, msg = pcall(callback, recipient)
            if not ok then
                WARN(string.format("Callback '%s' for 'OnRecipientPicked' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UIChatRecipientPicker
    ---@param callback fun(recipient: UIChatRecipient)
    ---@param name string
    AddOnRecipientPickedCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            WARN("Ignoring callback, 'name' parameter is invalid for  'AddOnRecipientPickedCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            WARN("Ignoring callback, 'callback' parameter is invalid for 'AddOnRecipientPickedCallback'")
            return
        end

        self.OnRecipientPickedCallbacks[name] = callback
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Lua functionality

    ---@param self UIChatRecipientPicker
    UpdateEntries = function(self)
        local head = 3
        local recipients = self.Recipients
        recipients[1] = { Name = 'To all:', Identifier = 'All' }
        recipients[2] = { Name = 'To allies:', Identifier = 'Allies' }

        for k = 1, armies.numArmies do
            local army = armies.armiesTable[k]
            if not army.civilian then
                recipients[head] = {
                    Name = army.nickname,
                    Identifier = k
                }
                head = head + 1
            end
        end
    end,

    ---@param self UIChatRecipientPicker
    ShowEntries = function(self)
        local maxWidth = 0
        local recipientsUsed = 0 
        for k = 1, self.RecipientCount do
            local controls = self.RecipientControls[k]
            local recipient = self.Recipients[k]
            if recipient then
                controls.Bitmap:SetSolidColor('ff000000')
                controls.Text:SetText(recipient.Name)

                recipientsUsed = recipientsUsed + 1
                local width = controls.Text:GetStringAdvance(recipient.Name)
                if width > maxWidth then
                    maxWidth = width
                end
            else

                controls:Hide()
                controls.Bitmap:SetSolidColor('00000000')
            end
        end

        -- determine width and height dynamically
        LayoutHelpers.LayoutFor(self)
            :Width(maxWidth + 20)
            :Height(recipientsUsed * 14 + 2)
    end,

    --#endregion
}

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnReload(newModule)
end
