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

local ChatRecipientOption = import("/lua/ui/game/chat/recipient-option.lua").ChatRecipientOption

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
---@field RecipientControls UIChatRecipientOption[]
---@field OnRecipientPickedCallbacks table<string, fun(recipient: UIChatRecipient)>
ChatRecipientPicker = ClassUI(Group) {

    RecipientCount = 20,

    ---@param self UIChatRecipientPicker
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'ChatRecipientPicker')

        self.OnRecipientPickedCallbacks = { }

        self.BackgroundTL = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ul.dds')
        self.BackgroundTR = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ur.dds')
        self.BackgroundBR = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_lr.dds')
        self.BackgroundBL = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_ll.dds')
        self.BackgroundLeft = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_vert_l.dds')
        self.BackgroundRight = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_vert_r.dds')
        self.BackgroundTop = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_horz_um.dds')
        self.BackgroundBottom = UIUtil.CreateBitmap(self, '/game/chat_brd/drop-box_brd_lm.dds')

        self.RecipientControls = {}
        for k = 1, self.RecipientCount do
            self.RecipientControls[k] = ChatRecipientOption(self)
        end
    end,

    ---@param self UIChatRecipientPicker
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Width(10)
            :Height(10)
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


        ---@param recipient UIChatRecipient
        local function OnClickCallback (recipient)
            self:OnRecipientPicked(recipient)
        end

        local recipientControls = self.RecipientControls
        for k = 1, self.RecipientCount do
            local index =  k
            local chatRecipient = recipientControls[index]
            LayoutHelpers.LayoutFor(chatRecipient)
                :AtLeftTopIn(self, 4, (index - 1) * 12)
                :FillHorizontally(self)

            chatRecipient:AddOnClickCallback(OnClickCallback, 'Recipient.lua')
        end

        self:UpdateEntries()
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

        -- gather all applicable entries
        local head = 3
        local recipients = { }
        recipients[1] = { Name = 'To all:', Identifier = 'All' }
        recipients[2] = { Name = 'To allies:', Identifier = 'Allies' }

        for k = 1, armies.numArmies do
            local army = armies.armiesTable[k]
            if not army.civilian then
                recipients[head] = {
                    Name = "To " .. army.nickname .. ":",
                    Identifier = k
                }
                head = head + 1
            end
        end

        -- apply the entries
        local maxWidth = 0
        local recipientsUsed = 0 

        for k = 1, self.RecipientCount do
            local recipient = recipients[k]
            local option = self.RecipientControls[k]
            option:UpdateRecipient(recipient)

            if recipient then
                recipientsUsed = recipientsUsed + 1
                local width = option.Text:GetStringAdvance(recipient.Name)
                if width > maxWidth then
                    maxWidth = width
                end
            end
        end

        -- determine width and height dynamically
        LayoutHelpers.LayoutFor(self)
            :Width(maxWidth + 20)
            :Height(recipientsUsed * 12)
    end,

    --#endregion
}

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnReload(newModule)
end
