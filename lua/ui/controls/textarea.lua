local mathMax = math.max

local Text = import("/lua/maui/text.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local PixelScaleFactor = LayoutHelpers:GetPixelScaleFactor()

--- A multi-line textfield
--
-- Since there's no native multiline text control, we have to do some magic in Lua.
-- GPG provided the native single-line TextField control, and the lua-based MultiLineText control.
-- MultiLineText aims to arrange a set of TextFields, one per line. Since this thrashes the layout
-- system quite a bit, the performance is suckful, and their implementation is incomplete (read:
-- entirely broken) anyway.
-- So: Let's use an ItemList with one entry per line of text. Since ItemList is native the overhead
-- incurred from having to layout a ton of TextFields is absent, we merely have to stave off the
-- self-harm long enough to finish writing this class so we can call this a solved problem and never
-- look in this file ever again.
---@class TextArea : ItemList
---@field advanceFunction function The advance function for wrapping text.
TextArea = ClassUI(ItemList) {

    ---@param self TextArea
    ---@param parent Control
    ---@param width number
    ---@param height number
    __init = function(self, parent, width, height)
        ItemList.__init(self, parent)

        -- Initial width and height are necessary to dodge partial-initialisation-reflow weirdness.
        LayoutHelpers.SetDimensions(self, width, height)

        self.text = ""
        self._textWidth = 0

        -- The advance function for Text.WrapText. Delegates to the ItemList.GetStringAdvance.
        -- Initialize before setting default font.
        self.advanceFunction = function(text) return self:GetStringAdvance(text) end

        -- By default, inherit colour and font from UIUtil (this will update with the skin, too,
        -- because LazyVars are magical.
        self:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
        self:SetFont(UIUtil.bodyFont, 14)

        -- Reflow text when the width is changed.
        self.Width.OnDirty = function(var)
            self:ReflowText()
        end
    end,

    --- Changes the font and then reflows the text.
    ---@param self TextArea
    _internalSetFont = function(self)
        if not self._lockFontChanges then
            self:SetNewFont(self._font._family(), self._font._pointsize())
            self:ReflowText()
        end
    end,

    ---@param self TextArea
    ---@param text? string | number
    SetText = function(self, text)
        self.text = tostring(text)
        self:ReflowText()
    end,

    ---@param self TextArea
    ---@return string
    GetText = function(self)
        return self.text
    end,

    GetTextHeight = function(self)
        return mathMax(0, self:GetItemCount() * self:GetRowHeight() - PixelScaleFactor)
    end,

    GetTextWidth = function(self)
        return self._textWidth
    end,

    --- Add more text to the textfield starting on a new line (high-performance append operation
    -- that avoids incurring a complete reflow).
    ---@param self TextArea
    ---@param text string
    AppendLine = function(self, text)
        if self.text == "" then
            self.text = text
        else
            self.text = self.text .. "\n" .. text
        end
        local wrapped = Text.WrapText(text, self.Width(), self.advanceFunction)
        local newTextWidth = 0

        for i, line in wrapped do
            self:AddItem(line)

            local lineWidth = self.advanceFunction(line)
            if lineWidth > newTextWidth then
                newTextWidth = lineWidth
            end
        end
        self._textWidth = newTextWidth
    end,

    ---@param self TextArea
    ReflowText = function(self)
        local width = self.Width()
        local advanceFunction = self.advanceFunction
        local alignmentProportion = self._alignmentProportion

        local wrapped = Text.WrapText(self.text, width, advanceFunction)
        local newTextWidth = 0
        -- Replace the old lines with the newly-wrapped ones.
        self:DeleteAllItems()
        for i, line in wrapped do
            if alignmentProportion then
                line = Text.AlignText(line, width, advanceFunction, alignmentProportion)
            end
            self:AddItem(line)

            local lineWidth = self.advanceFunction(line)
            if lineWidth > newTextWidth then
                newTextWidth = lineWidth
            end
        end
        self._textWidth = newTextWidth 
    end,

    ---@param self TextArea
    FitToText = function(self)
        LayoutHelpers.SetDimensions(self, self:GetTextWidth(), self:GetTextHeight())
    end,

    --- Aligns all the text proportionally along the TextArea's width.
    ---@param self TextArea
    ---@param alignmentProportion number How far towards the right of the line the text should be aligned. 0.5 for middle alignment, 1.0 for right alignment.
    SetTextAlignment = function(self, alignmentProportion)
        self._alignmentProportion = alignmentProportion
        local width = self.Width()
        local advanceFunction = self.advanceFunction
        for i = 0, self:GetItemCount() - 1 do
            self:ModifyItem(i, Text.AlignText(self:GetItem(i), width, advanceFunction, alignmentProportion))
        end
    end,
}
