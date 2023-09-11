
--**********************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local Colors = import("/lua/shared/color.lua")

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")


local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group
local Grid = import("/lua/maui/grid.lua").Grid

local CreateLazyVar = import("/lua/lazyvar.lua").Create
local AddControlTooltipManual = import("/lua/ui/game/tooltip.lua").AddControlTooltipManual

---@type UISimPerformancePopup
local Instance = nil

---@class UISimPerformanceElement : Group
---@field Background Bitmap
---@field Foreground Group
---@field MaximumUnits number
---@field Percentage LazyVar
---@field Bar Bitmap
---@field Label Text
UISimPerformanceElement = ClassUI(Group) {

    ---@param self UISimPerformanceElement
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.PercentageTop = CreateLazyVar(1.0)
        self.PercentageBottom = CreateLazyVar(0.0)

        do
            self.Background = UIUtil.CreateBitmapColor(self, 'ffffff')
            self.Background:SetAlpha(0.1)
            LayoutHelpers.FillParent(self.Background, self)

            self.Foreground = Group(self) --[[@as Group]]
            LayoutHelpers.FillParent(self.Foreground, self)
            self.Foreground:EnableHitTest()
            LayoutHelpers.DepthOverParent(self.Foreground, self, 100)

            self.Foreground.HandleEvent = function(element, event)
                if event.Type == 'MouseEnter' then
                    self.Background:SetAlpha(0.3)
                elseif event.Type == 'MouseExit' then
                    self.Background:SetAlpha(0.1)
                end
            end

            self.Bar = UIUtil.CreateBitmapColor(self, '999999')
            LayoutHelpers.FillHorizontally(self.Bar, self)

            self.Bar.Bottom:Set(
                function()
                    return self.Bottom() - (self.Height() * self.PercentageBottom())
                end
            )

            self.Bar.Top:Set(
                function()
                    return self.Bottom() - (self.Height() * self.PercentageTop())
                end
            )
        end

        do
            self.Label = UIUtil.CreateText(self, '+00', 12, UIUtil.bodyFont, false)
            LayoutHelpers.AtVerticalCenterIn(self.Label, self)
            LayoutHelpers.CenteredBelow(self.Label, self, 12)
        end
    end,

    ---@param self UISimPerformanceElement
    ---@param samples number
    ---@param min number
    ---@param max number
    SetData = function(self, samples, min, max)
        self.PercentageBottom:Set(min / self.MaximumUnits)
        self.PercentageTop:Set(max / self.MaximumUnits)

        local color = 1 - 1 / math.floor(math.sqrt(samples))
        self.Bar:SetSolidColor(Colors.ColorRGB(color, color, color))

        -- update tooltip
        AddControlTooltipManual(self.Foreground, 'Metrics', string.format("Min: %f\r\n Max: %f", min, max), 0, 200, 6, 14, 14, 'left')
    end,

    ---@param self UISimPerformanceElement
    ---@param label string
    SetLabel = function(self, label)
        self.Label:SetText(label)
    end,

    ---@param self UISimPerformanceElement
    ---@param max number
    SetMaximumUnits = function(self, max)
        self.MaximumUnits = max
    end
}

---@class UISimPerformancePopup : Window
---@field GridElements Grid
UISimPerformancePopup = ClassUI(Window) {

    ---@param self UISimPerformancePopup
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "Performance metrics", false, false, false, true, false, "PerformanceMetrics04", {
            Left = 10,
            Top = 300,
            Right = 550,
            Bottom = 450
        })

        self.GridElements = Grid(self, 24, 70)
        -- LayoutHelpers.FillParent(self.GridElements, self)
        LayoutHelpers.FillHorizontally(self.GridElements, self)
        LayoutHelpers.SetHeight(self.GridElements, 100)
        LayoutHelpers.AtLeftBottomIn(self.GridElements, self, 18, 5)

        self.GridElements:AppendCols(22, true)
        self.GridElements:AppendRows(1, true)
        for k = 1, 22 do
            local element = UISimPerformanceElement(self) --[[@as UISimPerformanceElement]]
            local rate = 11 - k
            local label = tostring(rate)
            if rate >= 0 then
                label = "+" .. label
            end

            element:SetLabel(label)
            LayoutHelpers.SetDimensions(element, 22, 60)
            self.GridElements:SetItem(element, k, 1, true)
        end
        self.GridElements:EndBatch()
    end,

    ---@param self UISimPerformancePopup
    ---@param data UIPerformanceMetricsArray
    SetData = function(self, data)

        local min = 20000
        local max = 0
        for k = 1, 22 do
            local dataElement = data[k] --[[@as UIPerformanceMetricsEntry]]
            if dataElement.UnitCount then
                if dataElement.UnitCount.Min < min then
                    min = dataElement.UnitCount.Min
                end

                if dataElement.UnitCount.Max > max then
                    max = dataElement.UnitCount.Max
                end
            end
        end

        for k = 1, 22 do
            local element = self.GridElements:GetItem(k, 1) --[[@as UISimPerformanceElement]]
            element:SetMaximumUnits(max)

            local dataElement = data[k] --[[@as UIPerformanceMetricsEntry]]
            if dataElement.UnitCount then
                element:SetData(dataElement.Samples, dataElement.UnitCount.Min, dataElement.UnitCount.Max)
            else
                element:SetData(0, 0, 0)
            end
        end
    end,

    ---@param self UISimPerformancePopup
    OnClose = function(self)
        self:Hide()
    end,
}

---@return UISimPerformancePopup
function OpenWindow()
    if Instance then
        Instance:Show()
    else
        Instance = UISimPerformancePopup(GetFrame(0))
        Instance:Show()
    end

    local data = GetPreference('PerformanceTrackingV2') --[[@as UIPerformanceMetrics]]
    Instance:SetData(data.Skirmish)

    return Instance
end

---@return UISimPerformancePopup
function CloseWindow()
    if Instance then
        Instance:OnClose()
    end

    return Instance
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Instance then
        Instance:Destroy()
    end
end
