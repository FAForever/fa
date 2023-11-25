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
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

-- does not change as the game progresses
local armies = GetArmiesTable()

reprsl(armies)

---@class UIChatRecipientOption : Group
---@field Recipient? UIChatRecipient
---@field Background Bitmap
---@field Highlight Bitmap
---@field Text Text
---@field Icon Bitmap
---@field Identifier UIMessageRecipients
---@field OnClickCallbacks table<string, fun(recipient: UIChatRecipient)>
ChatRecipientOption = ClassUI(Group) {

    ---@param self UIChatRecipientOption
    ---@param parent UIChatWindow
    __init = function(self, parent)
        Group.__init(self, parent)

        self.OnClickCallbacks = { }

        self.Text = UIUtil.CreateText(self, '', 12, UIUtil.bodyFont)
        self.Highlight = UIUtil.CreateBitmapColor(self, 'ffffffff')
        self.Background = UIUtil.CreateBitmapColor(self, '00000000')
    end,

    ---@param self UIChatRecipientOption
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Width(self.Text.Width)
            :Height(self.Text.Height)
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.Text)
            :AtLeftTopIn(self)
            :Color('ffffffff')
            :DisableHitTest()

        LayoutHelpers.LayoutFor(self.Background)
            :Color('ff000000')
            :Under(self.Text, 5)
            :AtLeftTopIn(self.Text, 0, 0)
            :AtRightBottomIn(self.Text, 0, 0)
            :FillHorizontally(self)

            LayoutHelpers.LayoutFor(self.Highlight)
            :Color('ffffffff')
            :Under(self.Text, 1)
            :AtLeftTopIn(self.Text, 0, 0)
            :AtRightBottomIn(self.Text, 0, 0)
            :FillHorizontally(self)

    end,

    ---------------------------------------------------------------------------
    --@region Engine functionality

    ---@param self UIChatRecipientOption
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local typeOfevent = event.Type

        if self.Recipient then
            if typeOfevent == 'MouseEnter' then
                self:CreateHighlight()
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Rollover_02'}))
            elseif typeOfevent == 'MouseExit' then
                self:DestroyHighlight()
            elseif typeOfevent == 'ButtonPress' then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_02'}))
                self:OnClick(self.Recipient)
            end
        end
    end,

    ---@param self UIChatRecipientOption
    Show = function(self)
        Group.Show(self)
        self:EnableHitTest()
    end,

    ---@param self UIChatRecipientOption
    Hide = function(self)
        Group.Hide(self)
        self:DisableHitTest(true)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Callback functionality

    ---@param self UIChatRecipientOption
    ---@param recipient UIChatRecipient
    OnClick = function(self, recipient)
        for name, callback in self.OnClickCallbacks do
            local ok, msg = pcall(callback, recipient)
            if not ok then
                WARN(string.format("Callback '%s' for 'OnRecipientPicked' failed: \r\n %s", name, msg))
            end
        end
    end,

    ---@param self UIChatRecipientOption
    ---@param callback fun(recipient: UIChatRecipient)
    ---@param name string
    AddOnClickCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            WARN("Ignoring callback, 'name' parameter is invalid for  'AddOnClickCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            WARN("Ignoring callback, 'callback' parameter is invalid for 'AddOnClickCallback'")
            return
        end

        self.OnClickCallbacks[name] = callback
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --@region Lua functionality

    ---@param self UIChatRecipientOption
    CreateHighlight = function(self)
        self.Highlight:SetAlpha(0.25, true)
    end,

    ---@param self UIChatRecipientOption
    DestroyHighlight = function(self)
        self.Highlight:SetAlpha(0, true)
    end,

    ---@param self UIChatRecipientOption
    ---@param recipient? UIChatRecipient
    UpdateRecipient = function(self, recipient, isWrapped, isExtended)
        -- set our internal state
        self.Recipient = recipient

        -- apparently there is nothing to show
        if not recipient then
            self:Hide()
            self.Background:SetAlpha(0)
            self.Highlight:SetAlpha(0)
            return
        end

        self:Show()
        self.Text:SetText(recipient.Name)
        self.Background:SetAlpha(1)
        self.Highlight:SetAlpha(0)
    end,

    --#endregion
}
