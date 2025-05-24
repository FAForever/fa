--******************************************************************************************************
--** Copyright (c) 2025  Willem 'Jip' Wijnia
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
--******************************************************************************************************

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor

local UIUtil = import("/lua/ui/uiutil.lua")
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local AbstractAnnouncement = import("/lua/ui/game/announcement/AbstractAnnouncement.lua").AbstractAnnouncement

--- An announcement with a title and some text below it.
---@class UITitleTextAnnouncement : UIAbstractAnnouncement
---@field Title Text
---@field Text TextArea
TitleTextAnnouncement = ClassUI(AbstractAnnouncement) {

    ---@param self UITitleTextAnnouncement
    ---@param parent Control
    ---@param titleText UnlocalizedString
    ---@param bodyText UnlocalizedString
    __init = function(self, parent, titleText, bodyText)
        AbstractAnnouncement.__init(self, parent)

        self.Title = UIUtil.CreateText(self.ContentArea, LOC(titleText), 22, UIUtil.titleFont)
        self.Text = TextArea(self.ContentArea, 600, 60)
        self.Text:SetText(LOC(bodyText))
    end,

    ---@param self UITitleTextAnnouncement
    ---@param parent Control
    ---@param titleText UnlocalizedString
    __post_init = function(self, parent, titleText, bodyText)
        AbstractAnnouncement.__post_init(self, parent)

        Layouter(self.Title)
            :AtCenterIn(parent, -250)
            :End()

        local text = self.Text
        text:SetFont(UIUtil.bodyFont, 18)
        text:FitToText()
        text:SetTextAlignment(0.5)
        text:SetColors(UIUtil.fontColor)
        text:SetAlphaOfColors(0)

        Layouter(self.Text)
            :CenteredBelow(self.Title, 10)
            :End()

        -- match the content area with the title
        Layouter(self.ContentArea)
            :Left(function() return math.min(self.Title.Left(), self.Text.Left()) end)
            :Right(function() return math.max(self.Title.Right(), self.Text.Right()) end)
            :AtTopIn(self.Title)
            :Bottom(self.Text.Bottom())
            :ResetWidth()
            :ResetHeight()
            :Alpha(0, true)
            :End()
    end,

    ---@param self UITitleTextAnnouncement
    ---@param value number
    SetAlphaOfContent = function(self, value)
        AbstractAnnouncement.SetAlphaOfContent(self, value)
        self.Text:SetAlphaOfColors(value)
    end,
}
