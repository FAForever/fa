local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

---@class Label : Group
---@field icon? Bitmap
---@field text? Text
---
---@field iconRight boolean
---@field padding number
Label = Class(Group) {
    ---@param self WorldLabel
    ---@param parent Control
    ---@param icon? FileName
    ---@param label? UnlocalizedString
    ---@param pointSize? number
    ---@param font? string
    ---@param dropshadow? boolean
    __init = function(self, parent, icon, label, pointSize, font, dropshadow)
        Group.__init(self, parent)
        if icon then
            self.icon = Bitmap(self, icon)
        end
        if label and pointSize then
            self.text = UIUtil.CreateText(self, label, pointSize, font, dropshadow)
        end
    end;

    ---@param self Label
    ---@param iconRight? boolean
    ---@param sep? number separation of icon and text
    ---@param padding? number
    Layout = function(self, iconRight, sep, padding)
        self.iconRight = iconRight
        sep = sep or 2
        padding = padding or 0
        self.padding = padding
        padding = padding * 2

        local icon, text = self.icon, self.text
        local left, right
        if icon and text then
            self.Height:SetFunction(function()
                local iconHeight = self.icon.Height()
                local textHeight = self.text.Height()
                if iconHeight > textHeight then
                    return iconHeight + padding
                end
                return textHeight + padding
            end)
            self.Width:SetFunction(function()
                return self.icon.Width() + sep + self.text.Width() + padding
            end)
            left, right = icon, text
        elseif icon then
            self.Height:SetFunction(function()
                return self.icon.Height() + padding
            end)
            self.Width:SetFunction(function()
                return self.icon.Width() + padding
            end)
            left = icon
        elseif text then
            self.Width:SetFunction(function()
                return self.icon.Width() + padding
            end)
            self.Height:SetFunction(function()
                return self.text.Height() + padding
            end)
            left = text
        end
        if right and iconRight then
            left, right = right, left
        end

        LayoutHelpers.AtLeftCenterIn(left, self, padding)

        if right then
            LayoutHelpers.AnchorToRight(right, left, sep)
            LayoutHelpers.AtVerticalCenterIn(right, self)
        end
    end;

    ---@param self Label
    ---@param x number
    ---@param y number
    FocusOn = function(self, x, y)
        if iscallable(x) then
            self.Left:SetFunction(function()
                local self = self
                local left = x()
                local icon = self.icon
                if icon then
                    local offset = 0.5 * icon.Width() + self.padding
                    if self.iconRight then
                        return left - self.Width() + offset
                    end
                    return left - offset
                end
                return left - 0.5 * self.Width()
            end)
        else
            self.Left:SetFunction(function()
                local self = self
                local left = x
                local icon = self.icon
                if icon then
                    local offset = 0.5 * icon.Width() + self.padding
                    if self.iconRight then
                        return left - self.Width() + offset
                    end
                    return left - offset
                end
                return left - 0.5 * self.Width()
            end)
        end
        if iscallable(y) then
            self.Top:SetFunction(function() return y() - 0.5 * self.Height() end)
        else
            self.Top:SetFunction(function() return y - 0.5 * self.Height() end)
        end
    end;

    ---@param self Label
    GetText = function(self)
        local text = self.text
        if text then
            return text:GetText()
        end
    end;

    ---@param self Label
    ---@param text LocalizedString | number
    SetText = function(self, text)
        self.text:SetText(text)
    end;

    ---@param self Label
    ---@param color Color
    SetColor = function(self, color)
        self.text:SetColor(color)
    end;

    ---@param self Label
    ---@param family string
    ---@param pointSize number
    SetFont = function(self, family, pointSize)
        self.text:SetFont(family, pointSize)
    end;
}
