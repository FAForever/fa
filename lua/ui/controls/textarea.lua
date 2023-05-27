local Text = import("/lua/maui/text.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

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

        -- By default, inherit colour and font from UIUtil (this will update with the skin, too,
        -- because LazyVars are magical.
        self:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
        self:SetFont(UIUtil.bodyFont, 14)

        -- The advance function for Text.WrapText. Delegates to the ItemList.GetStringAdvance.
        self.advanceFunction = function(text) return self:GetStringAdvance(text) end

        -- Reflow text when the width is changed.
        self.Width.OnDirty = function(var)
            self:ReflowText()
        end

        -- Reflow text when the text properties of this ItemList are changed (see itemlist.lua)
        self._font._family.OnDirty = function(var)
            self:_internalSetFont()
            self:ReflowText()
        end
        self._font._pointsize.OnDirty = function(var)
            self:_internalSetFont()
            self:ReflowText()
        end
    end,

    ---@param self TextArea
    ---@param text string
    SetText = function(self, text)
        self.text = text
        self:ReflowText()
    end,

    ---@param self TextArea
    ---@return string
    GetText = function(self)
        return self.text
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

        for i, line in wrapped do
            self:AddItem(line)
        end
    end,

    ---@param self TextArea
    ReflowText = function(self)
        local wrapped = Text.WrapText(self.text, self.Width(), self.advanceFunction)

        -- Replace the old lines with the newly-wrapped ones.
        self:DeleteAllItems()
        for i, line in wrapped do
            self:AddItem(line)
        end
    end
}
