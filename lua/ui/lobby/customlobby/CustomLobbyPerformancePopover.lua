--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- A hover popover that visualises a peer's sim-performance history (the
-- `PerformanceTrackingV2` data, see /lua/system/performance.lua). Framed like the
-- chat config, with a hand-built bitmap bar chart (no functional histogram control
-- exists). One bar per simulation-rate bucket: the bar spans the unit-count range
-- [Min, Max] observed at that rate (scaled to the busiest bucket), and its brightness
-- encodes how many samples back it up. Negative rates = the sim lagged; positive =
-- the machine had headroom.
--
-- Singleton, shown/hidden by the slot rows on CPU-score hover.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Create = import("/lua/lazyvar.lua").Create
local Layouter = LayoutHelpers.ReusedLayoutFor

local Buckets = 21            -- sim-rate buckets: index k -> rate (k - 11), i.e. -10 .. +10
local BarWidth = 13
local BarGap = 2
local ChartHeight = 78
local ContentPad = 14
local AxisWidth = 38          -- left gutter for the unit-count (Y) axis labels
local PopoverWidth = ContentPad * 2 + AxisWidth + Buckets * (BarWidth + BarGap)
local PopoverHeight = 156

local GridlineColor = 'ffffffff'  -- faint white reference lines
local GridlineAlpha = 0.10
local CapColor = 'ffe0c020'       -- the recommended-unit-cap line (and its label): a clear yellow
local CapAlpha = 0.85

--- Formats a unit count compactly for the Y axis (e.g. 5421 -> "5.4k").
---@param value number
---@return string
local function FormatUnits(value)
    if value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(math.floor(value + 0.5))
end

--- The three game-type categories tracked, ordered for the "most played" pick.
local Categories = { 'Skirmish', 'SkirmishWithAI', 'Campaign' }
local CategoryLabels = {
    Skirmish       = 'Skirmish',
    SkirmishWithAI = 'Skirmish vs AI',
    Campaign       = 'Campaign',
}

-------------------------------------------------------------------------------
-- One bar: a column whose filled extent is the [Min, Max] unit-count range.

---@class UIPerformanceBar : Group
---@field Background Bitmap
---@field Bar Bitmap
---@field Label Text
---@field PctBottom LazyVar
---@field PctTop LazyVar
local PerformanceBar = ClassUI(Group) {

    ---@param self UIPerformanceBar
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.PctBottom = Create(0.0)
        self.PctTop = Create(0.0)

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('ffffffff')
        self.Background:SetAlpha(0.06)
        self.Background:DisableHitTest()

        self.Bar = Bitmap(self)
        self.Bar:SetSolidColor('ff999999')
        self.Bar:DisableHitTest()

        self.Label = UIUtil.CreateText(self, '', 9, UIUtil.bodyFont)
        self.Label:DisableHitTest()
    end,

    ---@param self UIPerformanceBar
    __post_init = function(self)
        Layouter(self.Background):Fill(self):End()

        -- the bar fills the column horizontally; its vertical extent is driven by
        -- the [Min, Max] percentages, measured up from the column's bottom
        Layouter(self.Bar):AtLeftIn(self):AtRightIn(self):End()
        self.Bar.Bottom:Set(function() return self.Bottom() - self.Height() * self.PctBottom() end)
        self.Bar.Top:Set(function() return self.Bottom() - self.Height() * self.PctTop() end)

        Layouter(self.Label):AtHorizontalCenterIn(self):AnchorToBottom(self, 2):End()
    end,

    --- @param self UIPerformanceBar
    --- @param samples number
    --- @param min number
    --- @param max number
    --- @param maxUnits number   # largest Max across all buckets, for scaling
    SetData = function(self, samples, min, max, maxUnits)
        if samples <= 0 or maxUnits <= 0 then
            self.PctBottom:Set(0.0)
            self.PctTop:Set(0.0)
            return
        end

        -- clamp to the chart: a bucket above the scale (e.g. over the recommended
        -- cap) pegs at the top rather than overflowing the popover
        self.PctBottom:Set(math.clamp(min / maxUnits, 0.0, 1.0))
        self.PctTop:Set(math.clamp(max / maxUnits, 0.0, 1.0))

        -- brightness grows with confidence (more samples -> whiter)
        local c = 1 - 1 / math.sqrt(math.max(samples, 1))
        local v = math.floor(math.clamp(c, 0.15, 1.0) * 255)
        self.Bar:SetSolidColor(string.format('ff%02x%02x%02x', v, v, v))
    end,

    ---@param self UIPerformanceBar
    ---@param text string
    SetLabel = function(self, text)
        self.Label:SetText(text)
    end,
}

-------------------------------------------------------------------------------
-- The popover panel.

---@class UICustomLobbyPerformancePopover : Group
---@field Border Bitmap
---@field Background Bitmap
---@field Title Text
---@field Subtitle Text
---@field Gridlines Bitmap[]       # three faint horizontal reference lines (top / mid / bottom)
---@field AxisLabels Text[]        # unit-count labels next to those lines (max / half / 0)
---@field CapLine Bitmap           # yellow reference line at the recommended unit cap
---@field CapFraction LazyVar      # cap as a fraction of the chart's scale (0 = bottom, 1 = top)
---@field Bars UIPerformanceBar[]
local CustomLobbyPerformancePopover = ClassUI(Group) {

    ---@param self UICustomLobbyPerformancePopover
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyPerformancePopover")

        -- simple 1px frame: a light border bitmap with a dark fill pinned 1px inside
        -- (the chat-config border colour, for a consistent look)
        self.Border = Bitmap(self)
        self.Border:SetSolidColor('ff415055')
        self.Border:DisableHitTest()

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('f0101418')
        self.Background:DisableHitTest()

        self.Title = UIUtil.CreateText(self, "Sim performance", 14, UIUtil.titleFont)
        self.Title:DisableHitTest()
        self.Subtitle = UIUtil.CreateText(self, "", 10, UIUtil.bodyFont)
        self.Subtitle:DisableHitTest()
        self.Subtitle:SetColor('ff9aa0a8')

        -- the unit-count (Y) axis: three faint reference lines and their labels.
        -- Created before the bars so the bars draw on top of the lines.
        self.Gridlines = {}
        self.AxisLabels = {}
        for k = 1, 3 do
            local line = Bitmap(self)
            line:SetSolidColor(GridlineColor)
            line:SetAlpha(GridlineAlpha)
            line:DisableHitTest()
            self.Gridlines[k] = line

            local label = UIUtil.CreateText(self, "", 9, UIUtil.bodyFont)
            label:SetColor('ff9aa0a8')
            label:DisableHitTest()
            self.AxisLabels[k] = label
        end

        self.Bars = {}
        for k = 1, Buckets do
            self.Bars[k] = PerformanceBar(self)
            local rate = k - 11
            self.Bars[k]:SetLabel(rate >= 0 and ("+" .. rate) or tostring(rate))
        end

        -- the recommended-cap line floats at CapFraction of the chart; it draws over
        -- the bars (created last) so it reads as a threshold the bars can exceed.
        -- Hidden (alpha 0) until SetData is given a cap.
        self.CapFraction = Create(0.0)
        self.CapLine = Bitmap(self)
        self.CapLine:SetSolidColor(CapColor)
        self.CapLine:SetAlpha(0.0)
        self.CapLine:DisableHitTest()

        -- purely informational; never capture the mouse (the slot row drives
        -- show/hide on hover, and capturing would make it flicker)
        self:DisableHitTest(true)
    end,

    ---@param self UICustomLobbyPerformancePopover
    __post_init = function(self)
        Layouter(self):Width(PopoverWidth):Height(PopoverHeight):End()
        Layouter(self.Border):Fill(self):End()
        Layouter(self.Background)
            :AtLeftIn(self, 1):AtRightIn(self, 1):AtTopIn(self, 1):AtBottomIn(self, 1)
            :End()

        Layouter(self.Title):AtLeftTopIn(self, ContentPad, 8):End()
        Layouter(self.Subtitle):AtLeftIn(self, ContentPad):AnchorToBottom(self.Title, 2):End()

        local chartTop = PopoverHeight - ContentPad - 14 - ChartHeight
        for k = 1, Buckets do
            local bar = self.Bars[k]
            local builder = Layouter(bar):Width(BarWidth):Height(ChartHeight):Top(function() return self.Top() + LayoutHelpers.ScaleNumber(chartTop) end)
            if k == 1 then
                builder:AtLeftIn(self, ContentPad + AxisWidth)
            else
                builder:AnchorToRight(self.Bars[k - 1], BarGap)
            end
            builder:End()
        end

        -- reference lines at the top (max), middle (half) and bottom (zero) of the
        -- chart, with the unit-count labels right-aligned in the left gutter
        local lineYs = { chartTop, chartTop + ChartHeight * 0.5, chartTop + ChartHeight }
        for k = 1, 3 do
            local y = lineYs[k]
            Layouter(self.Gridlines[k])
                :AtLeftIn(self, ContentPad + AxisWidth):AtRightIn(self, ContentPad):Height(1)
                :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(y) end)
                :End()
            Layouter(self.AxisLabels[k])
                :AnchorToLeft(self.Bars[1], 4):AtVerticalCenterIn(self.Gridlines[k])
                :End()
        end

        -- the yellow cap line spans the chart; its height up from the baseline is
        -- CapFraction of the chart height (1 = top of chart)
        Layouter(self.CapLine)
            :AtLeftIn(self, ContentPad + AxisWidth):AtRightIn(self, ContentPad):Height(1)
            :Top(function()
                return self.Top()
                    + LayoutHelpers.ScaleNumber(chartTop + ChartHeight)
                    - self.CapFraction() * LayoutHelpers.ScaleNumber(ChartHeight)
            end)
            :End()
    end,

    --- Fills the chart from a peer's performance metrics (the whole
    --- `PerformanceTrackingV2` table). Picks the most-played category.
    ---@param self UICustomLobbyPerformancePopover
    ---@param metrics UIPerformanceMetrics | nil
    ---@param unitCap? number   # recommended total-unit ceiling (the yellow line), if known
    SetData = function(self, metrics, unitCap)
        local category, categoryKey, bestSamples = nil, nil, -1
        if metrics then
            for _, key in Categories do
                local c = metrics[key]
                if c and (c.Samples or 0) > bestSamples then
                    bestSamples = c.Samples or 0
                    category = c
                    categoryKey = key
                end
            end
        end

        if not category or bestSamples <= 0 then
            self.Subtitle:SetText("no data shared yet")
            for k = 1, Buckets do
                self.Bars[k]:SetData(0, 0, 0, 0)
            end
            for k = 1, 3 do
                self.AxisLabels[k]:SetText("")
            end
            self.CapLine:SetAlpha(0.0)
            return
        end

        -- busiest unit count actually observed across the category
        local observedMax = 0
        for k = 1, Buckets do
            local entry = category[k]
            if entry and entry.UnitCount and entry.UnitCount.Max > observedMax then
                observedMax = entry.UnitCount.Max
            end
        end

        -- the chart scales to the data, but never below the recommended cap, so the
        -- yellow line is always on-chart while the bars are free to rise above it.
        local cap = (unitCap and unitCap > 0) and unitCap or nil
        local chartMax = math.max(observedMax, cap or 0, 1)

        local subtitle = string.format("%s  —  %d game(s)", CategoryLabels[categoryKey] or categoryKey, bestSamples)
        if cap then
            subtitle = subtitle .. string.format("  ·  rec. cap %s", FormatUnits(cap))
        end
        self.Subtitle:SetText(subtitle)

        for k = 1, Buckets do
            local entry = category[k]
            if entry and entry.UnitCount then
                self.Bars[k]:SetData(entry.Samples or 0, entry.UnitCount.Min or 0, entry.UnitCount.Max or 0, chartMax)
            else
                self.Bars[k]:SetData(0, 0, 0, chartMax)
            end
        end

        -- label the reference lines (top = busiest / cap, middle = half, bottom = 0)
        self.AxisLabels[1]:SetText(FormatUnits(chartMax))
        self.AxisLabels[2]:SetText(FormatUnits(chartMax * 0.5))
        self.AxisLabels[3]:SetText("0")

        -- place (or hide) the yellow recommended-cap line
        if cap then
            self.CapFraction:Set(cap / chartMax)
            self.CapLine:SetAlpha(CapAlpha)
        else
            self.CapLine:SetAlpha(0.0)
        end
    end,
}

-------------------------------------------------------------------------------
-- Singleton + show / hide

local ModuleTrash = TrashBag()

---@type UICustomLobbyPerformancePopover | false
local Instance = false

---@return UICustomLobbyPerformancePopover
local function GetInstance()
    if not Instance then
        Instance = CustomLobbyPerformancePopover(GetFrame(0))
        ModuleTrash:Add(Instance)
    end
    return Instance
end

--- Shows the popover next to `anchor`, filled with `metrics`.
---@param anchor Control
---@param metrics UIPerformanceMetrics | nil
---@param unitCap? number   # recommended total-unit ceiling (the yellow line), if known
function Show(anchor, metrics, unitCap)
    local popover = GetInstance()
    popover:SetData(metrics, unitCap)

    -- float to the right of the hovered control, vertically centred on it
    Layouter(popover)
        :AnchorToRight(anchor, 12)
        :AtVerticalCenterIn(anchor)
        :End()

    popover:Show()
end

function Hide()
    if Instance then
        Instance:Hide()
    end
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()
    Instance = false
end

--#endregion
