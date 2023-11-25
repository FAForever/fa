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
---@field Background Bitmap
---@field Text Text
---@field Icon Bitmap
---@field Identifier UIMessageRecipients
ChatMessage = ClassUI(Group) {

    ---@param self UIChatRecipientOption
    ---@param parent UIChatWindow
    __init = function(self, parent)
        Group.__init(self, parent)

        self.Text = UIUtil.CreateText(self, '', 12, UIUtil.bodyFont)

    end,

    ---@param self UIChatRecipientOption
    ---@param parent Control
    __post_init = function(self, parent)

    end,

    ---------------------------------------------------------------------------
    --@region Engine functionality

    ---@param self UIChatRecipientOption
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local typeOfevent = event.Type

        if self.Message then
            if typeOfevent == 'MouseEnter' then
                self:CreateHighlight()
            elseif typeOfevent == 'MouseExit' then
                self:DestroyHighlight()
            end
        end
    end,

    ---@param self UIChatRecipientOption
    Show = function(self)
        Group.Show(self)

        self:EnableHitTest()

        if self.IsExtension then

        end
    end,

    ---@param self UIChatRecipientOption
    Hide = function(self)
        Group.Hide(self)
        self:DisableHitTest()
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --@region Lua functionality

    ---@param self UIChatRecipientOption
    CreateHighlight = function(self)
        self.Background:SetAlpha(0.25, true)
    end,

    ---@param self UIChatRecipientOption
    DestroyHighlight = function(self)
        self.Background:SetAlpha(0, true)
    end,

    ---@param self UIChatRecipientOption
    ---@param message? UIMessage
    ProcessMessage = function(self, message, isWrapped, isExtended)
        -- set our internal state
        self.Message = message
        self.IsWrapped = isWrapped
        self.IsExtension = isExtended

        -- apparently there is nothing to show
        if not message then
            self:Hide()
            self.Content:SetText("No message")
            return
        end

        self:Show()

        if self.IsExtension then

        else

        end

        -- populate this line of content
        local army = armies.armiesTable[message.From]
        local factions = import("/lua/factions.lua").Factions
        self.Icon:SetTexture(UIUtil.UIFile(factions[army.faction + 1].Icon or
        '/widgets/faction-icons-alpha_bmp/observer_ico.dds'))

        local textRecipients = ":"
        if message.To == 'All' then
            textRecipients = 'to all:'      -- todo: LOC
        elseif message.To == 'Allies' then
            textRecipients = 'to allies:'   -- todo: LOC
        elseif message.To == 'Enemies' then
            textRecipients = 'to all:'      -- todo: LOC
        end

        self.To:SetText(textRecipients)
        self.Name:SetText(army.nickname)
        self.Color:SetSolidColor(army.color)
        self.Content:SetText(message.Text)
    end,

    --#endregion
}
