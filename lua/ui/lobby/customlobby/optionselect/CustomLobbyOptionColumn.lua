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

-- One column of the options dialog (lobby / scenario / mod). A header (title + shown count), a
-- scrollable `Grid` of option rows, an auto-hiding scrollbar, and an empty-state label.
--
-- Each row is `[marker] label …………… [value dropdown]`. The dropdown picks among the option's
-- values; the marker (a dot) lights up when the option is *not* at its default, so changed
-- options stand out. The column doesn't own the values — it reads/writes a shared values table
-- (handed in via `SetData`) and calls `onChange` so the dialog can react (re-count, etc.).
--
-- The list uses the native `Grid`, which hides off-screen rows itself, so the value dropdowns are
-- real `Combo`s created once (no per-scroll rebuild, no clipping tricks). Rows are rebuilt only
-- when the filter (search / hide-defaults) changes — not on a value edit, so editing never
-- disturbs an open dropdown.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid
local Combo = import("/lua/ui/controls/combo.lua").Combo

local OptionUtil = import("/lua/ui/optionutil.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local HeaderHeight = 24
local RowHeight = 30
local ScrollbarGap = 20      -- space reserved on the column's right for the scrollbar
local ComboWidth = 116
local MarkerWidth = 14

local ModifiedColor = 'ffd0a24c'   -- label + marker colour for a non-default option
local DefaultColor = 'ffc8ccd0'

local LabelMaxChars = 22           -- single-line Text doesn't clip; cap with an ellipsis

--- Truncates `text` to `maxChars`, appending "…" when it had to cut.
---@param text string
---@param maxChars number
---@return string
local function Truncate(text, maxChars)
    text = text or ""
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars - 1) .. "…"
    end
    return text
end

---@class UICustomLobbyOptionColumn : Group
---@field Trash TrashBag
---@field ContentWidth number
---@field Header Text
---@field Count Text
---@field Grid Grid
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field Options ScenarioOption[]
---@field Values table<string, any>
---@field OnChange fun()
---@field Shown number              # options currently displayed (after filtering)
local CustomLobbyOptionColumn = ClassUI(Group) {

    ---@param self UICustomLobbyOptionColumn
    ---@param parent Control
    ---@param title string
    ---@param contentWidth number    # unscaled width of the grid / rows (excludes the scrollbar gap)
    __init = function(self, parent, title, contentWidth)
        Group.__init(self, parent, "CustomLobbyOptionColumn")

        self.Trash = TrashBag()
        self.ContentWidth = contentWidth
        self.Options = {}
        self.Values = {}
        self.OnChange = nil
        self.Scrollbar = false
        self.Shown = 0

        self.Header = UIUtil.CreateText(self, title, 16, UIUtil.titleFont)
        self.Header:DisableHitTest()

        self.Count = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Count:SetColor('ff9aa0a8')
        self.Count:DisableHitTest()

        self.Grid = Grid(self, contentWidth, RowHeight)

        self.Empty = UIUtil.CreateText(self, "No options", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff8a909a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()
    end,

    ---@param self UICustomLobbyOptionColumn
    __post_init = function(self)
        Layouter(self.Header):AtLeftIn(self):AtTopIn(self):End()
        Layouter(self.Count):AtRightIn(self, ScrollbarGap):AtVerticalCenterIn(self.Header):End()
        Layouter(self.Grid)
            :AtLeftIn(self):AnchorToBottom(self.Header, 6):AtBottomIn(self)
            :Width(self.ContentWidth)
            :End()
        Layouter(self.Empty):AtHorizontalCenterIn(self.Grid):AtTopIn(self.Grid, 12):End()
    end,

    --- Points the column at its options + the shared values table, and the change callback. The
    --- title can be refreshed too. Does not build rows yet (see Refresh).
    ---@param self UICustomLobbyOptionColumn
    ---@param options ScenarioOption[]
    ---@param values table<string, any>
    ---@param onChange fun()
    SetData = function(self, options, values, onChange)
        self.Options = options or {}
        self.Values = values or {}
        self.OnChange = onChange
    end,

    --- Builds the scrollbar; called by the dialog after mount (the Grid needs a concrete height).
    ---@param self UICustomLobbyOptionColumn
    Initialize = function(self)
        if self.Scrollbar then
            return
        end
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
    end,

    --- Rebuilds the visible rows applying the search + hide-defaults filter, updates the count and
    --- the empty state, and shows the scrollbar only when it's needed.
    ---@param self UICustomLobbyOptionColumn
    ---@param search string          # already lowercased; "" = no search
    ---@param hideDefaults boolean
    Refresh = function(self, search, hideDefaults)
        self.Grid:DeleteAndDestroyAll(true)

        local filtered = {}
        for _, option in self.Options do
            if self:Passes(option, search, hideDefaults) then
                table.insert(filtered, option)
            end
        end
        self.Shown = table.getn(filtered)

        if self.Shown > 0 then
            self.Empty:Hide()
            self.Grid:AppendCols(1, true)
            self.Grid:AppendRows(self.Shown, true)
            for row, option in filtered do
                self.Grid:SetItem(self:CreateRow(option), 1, row, true)
            end
            self.Grid:EndBatch()
        else
            self.Empty:Show()
        end

        self.Count:SetText(tostring(self.Shown))
        self:UpdateScrollbar()
    end,

    --- Whether an option survives the current filter.
    ---@param self UICustomLobbyOptionColumn
    ---@param option ScenarioOption
    ---@param search string
    ---@param hideDefaults boolean
    ---@return boolean
    Passes = function(self, option, search, hideDefaults)
        if hideDefaults and OptionUtil.IsDefault(option, self.Values) then
            return false
        end
        if search ~= "" then
            if not string.find(string.lower(LOC(option.label) or ""), search, 1, true) then
                return false
            end
        end
        return true
    end,

    --- Builds one option row: a non-default marker, the label, and a value dropdown. Private.
    ---@param self UICustomLobbyOptionColumn
    ---@param option ScenarioOption
    ---@return Group
    CreateRow = function(self, option)
        local row = Group(self.Grid)
        LayoutHelpers.SetDimensions(row, self.ContentWidth, RowHeight)

        local marker = Bitmap(row)
        marker:SetSolidColor(ModifiedColor)
        marker:DisableHitTest()

        local label = UIUtil.CreateText(row, Truncate(LOC(option.label) or option.key, LabelMaxChars), 14, UIUtil.bodyFont)
        label:DisableHitTest()

        local combo = Combo(row, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        combo:AddItems(OptionUtil.ValueLabels(option), OptionUtil.FindValueIndex(option, OptionUtil.GetCurrentValueKey(option, self.Values)))
        combo.OnClick = function(control, index, text)
            self.Values[option.key] = OptionUtil.ValueKeyOf(option.values[index])
            self:PaintMarker(marker, label, option)
            if self.OnChange then
                self.OnChange()
            end
        end

        Layouter(marker):AtLeftIn(row):AtVerticalCenterIn(row):Width(6):Height(6):End()
        Layouter(combo):AtRightIn(row, 4):AtVerticalCenterIn(row):Width(ComboWidth):End()
        Layouter(label):AtLeftIn(row, MarkerWidth):AtVerticalCenterIn(row):End()

        Tooltip.AddControlTooltipManual(label, LOC(option.label) or option.key, LOC(option.help) or "")
        self:PaintMarker(marker, label, option)

        return row
    end,

    --- Lights the marker + tints the label when the option is off its default, dims both when not.
    ---@param self UICustomLobbyOptionColumn
    ---@param marker Bitmap
    ---@param label Text
    ---@param option ScenarioOption
    PaintMarker = function(self, marker, label, option)
        if OptionUtil.IsDefault(option, self.Values) then
            marker:Hide()
            label:SetColor(DefaultColor)
        else
            marker:Show()
            label:SetColor(ModifiedColor)
        end
    end,

    --- Shows the scrollbar only when the grid actually overflows.
    ---@param self UICustomLobbyOptionColumn
    UpdateScrollbar = function(self)
        if not self.Scrollbar then
            return
        end
        if self.Grid:IsScrollable("Vert") then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end
    end,

    ---@param self UICustomLobbyOptionColumn
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@param title string
---@param contentWidth number
---@return UICustomLobbyOptionColumn
Create = function(parent, title, contentWidth)
    return CustomLobbyOptionColumn(parent, title, contentWidth)
end
