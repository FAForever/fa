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

-- A scrollable, pooled map list for the map-select dialog: each row shows the map name and a
-- `size · players` badge. Replaces the flat `ItemList` so rows can carry richer content (see
-- /lua/ui/CLAUDE.md § 6.1).
--
-- NOTE: rows used to carry a mini map-preview thumbnail, but the engine never releases the
-- textures `MapPreview:SetTextureFromMap` / `SetTexture` allocate — not on re-texture, not on
-- `ClearTexture`, not on `Destroy`, not on dialog close. Scrolling a vault leaked tens of MB
-- that the game needs in-match, so thumbnails were removed. Rows are now text-only.
--
-- It is *virtualised*: a fixed pool of row controls (sized to the visible height) is reused as
-- you scroll. The standard scrollbar contract (GetScrollValues / ScrollLines / ScrollPages /
-- ScrollSetTop / IsScrollable / CalcVisible) drives the windowing.
--
-- Mouse-driven (click selects, double-click confirms, wheel + scrollbar scroll). A custom Group
-- list can't take keyboard focus the way ItemList can, so arrow-key navigation lives with the
-- owner (the dialog wires Enter on its search box / Esc on the popup).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 24

local SelectedColor = 'ff2c3e48'
local HoverColor = 'ff1a2630'
local IdleColor = '00000000'

--- Number of start spots a scenario declares, or 0.
---@param scenario UILobbyScenarioInfo
---@return number
local function ArmyCount(scenario)
    local armies = scenario.Configurations
        and scenario.Configurations.standard
        and scenario.Configurations.standard.teams
        and scenario.Configurations.standard.teams[1]
        and scenario.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
end

---@class UICustomLobbyMapListRow : Group
---@field Background Bitmap
---@field Name Text
---@field Meta Text
---@field _poolIndex number
---@field _hover boolean

---@class UICustomLobbyMapList : Group
---@field Trash TrashBag
---@field Items UILobbyScenarioInfo[]
---@field Rows UICustomLobbyMapListRow[]
---@field PoolCount number
---@field ScrollTop number                    # 0-based scroll offset (first visible = Items[ScrollTop+1]); NOT the `Top` edge LazyVar
---@field Selected number | false             # selected item index (1-based)
---@field OnSelect fun(scenario: UILobbyScenarioInfo, index: number)
---@field OnConfirm fun(scenario: UILobbyScenarioInfo)
local CustomLobbyMapList = ClassUI(Group) {

    ---@param self UICustomLobbyMapList
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyMapList")

        self.Trash = TrashBag()
        self.Items = {}
        self.Rows = {}
        self.PoolCount = 0
        self.ScrollTop = 0
        self.Selected = false
        self.OnSelect = nil
        self.OnConfirm = nil
    end,

    ---@param self UICustomLobbyMapList
    __post_init = function(self)
        self.HandleEvent = function(control, event)
            if event.Type == 'WheelRotation' then
                local lines = event.WheelRotation > 0 and -3 or 3
                self:ScrollLines(nil, lines)
                return true
            end
            return false
        end
    end,

    --- Builds the row pool sized to the (now concrete) height and attaches the scrollbar.
    --- Called by the owner after the list is laid out + mounted — the pool count is read from
    --- `Height()`, which isn't settled during __post_init (three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyMapList
    Initialize = function(self)
        if self.PoolCount > 0 then
            return
        end

        local count = math.floor(self.Height() / LayoutHelpers.ScaleNumber(RowHeight))
        if count < 1 then
            count = 1
        end
        for i = 1, count do
            self.Rows[i] = self:CreateRow(i)
            local top = (i - 1) * RowHeight
            Layouter(self.Rows[i])
                :AtLeftIn(self)
                :AtRightIn(self)
                :AtTopIn(self, top)
                :Height(RowHeight)
                :End()
        end
        -- set the pool count only once the whole pool exists, so a build error never leaves
        -- CalcVisible iterating past the rows that were actually created
        self.PoolCount = count

        UIUtil.CreateVertScrollbarFor(self)
        self:CalcVisible()
    end,

    --- Builds one pooled row (name + size/players badge). Private.
    ---@param self UICustomLobbyMapList
    ---@param poolIndex number
    ---@return UICustomLobbyMapListRow
    CreateRow = function(self, poolIndex)
        ---@type UICustomLobbyMapListRow
        local row = Group(self)
        row._poolIndex = poolIndex
        row._hover = false

        row.Background = Bitmap(row)
        row.Background:SetSolidColor(IdleColor)

        row.Name = UIUtil.CreateText(row, "", 14, UIUtil.bodyFont)
        row.Name:DisableHitTest()

        row.Meta = UIUtil.CreateText(row, "", 12, UIUtil.bodyFont)
        row.Meta:SetColor('ff9aa0a8')
        row.Meta:DisableHitTest()

        Layouter(row.Background):Fill(row):End()
        Layouter(row.Name):AtLeftIn(row, 10):AtVerticalCenterIn(row):End()
        Layouter(row.Meta):AtRightIn(row, 10):AtVerticalCenterIn(row):End()

        -- the background catches the mouse; children are hit-test-disabled so they don't block it
        row.Background.HandleEvent = function(control, event)
            local index = self.ScrollTop + poolIndex
            local scenario = self.Items[index]
            if not scenario then
                return false
            end
            if event.Type == 'ButtonPress' then
                self:SetSelection(index)
                if self.OnSelect then
                    self.OnSelect(scenario, index)
                end
                return true
            elseif event.Type == 'ButtonDClick' then
                if self.OnConfirm then
                    self.OnConfirm(scenario)
                end
                return true
            elseif event.Type == 'MouseEnter' then
                row._hover = true
                self:PaintRow(row, index)
                return true
            elseif event.Type == 'MouseExit' then
                row._hover = false
                self:PaintRow(row, index)
                return true
            end
            return false
        end

        return row
    end,

    --- Replaces the data set and refreshes the window (resets scroll to the top).
    ---@param self UICustomLobbyMapList
    ---@param items UILobbyScenarioInfo[]
    SetItems = function(self, items)
        self.Items = items or {}
        self.ScrollTop = 0
        self.Selected = false
        self:CalcVisible()
    end,

    --- Selects an item by index (1-based) and repaints; does not scroll (see ShowItem).
    ---@param self UICustomLobbyMapList
    ---@param index number | false
    SetSelection = function(self, index)
        self.Selected = index or false
        self:CalcVisible()
    end,

    --- The selected scenario, or nil.
    ---@param self UICustomLobbyMapList
    ---@return UILobbyScenarioInfo | nil
    GetSelected = function(self)
        return self.Selected and self.Items[self.Selected] or nil
    end,

    --- Scrolls so item `index` (1-based) is within the visible window.
    ---@param self UICustomLobbyMapList
    ---@param index number
    ShowItem = function(self, index)
        if self.PoolCount == 0 then
            return
        end
        if index <= self.ScrollTop then
            self.ScrollTop = index - 1
        elseif index > self.ScrollTop + self.PoolCount then
            self.ScrollTop = index - self.PoolCount
        end
        self:ClampTop()
        self:CalcVisible()
    end,

    --- Paints a single row to reflect its data + selection/hover state. Private.
    ---@param self UICustomLobbyMapList
    ---@param row UICustomLobbyMapListRow
    ---@param index number
    PaintRow = function(self, row, index)
        if not row then
            return
        end
        local scenario = self.Items[index]
        if not scenario then
            row:Hide()
            return
        end
        row:Show()

        local color = IdleColor
        if index == self.Selected then
            color = SelectedColor
        elseif row._hover then
            color = HoverColor
        end
        row.Background:SetSolidColor(color)

        row.Name:SetText(LOC(scenario.name) or "?")

        local players = ArmyCount(scenario)
        local size = scenario.size and math.floor(scenario.size[1] / 50) or "?"
        row.Meta:SetText(size .. "km  ·  " .. players .. "p")
    end,

    ---------------------------------------------------------------------------
    --#region Scrollbar contract

    ---@param self UICustomLobbyMapList
    CalcVisible = function(self)
        for i = 1, self.PoolCount do
            self:PaintRow(self.Rows[i], self.ScrollTop + i)
        end
    end,

    ---@param self UICustomLobbyMapList
    ClampTop = function(self)
        local maxTop = math.max(0, table.getn(self.Items) - self.PoolCount)
        if self.ScrollTop > maxTop then
            self.ScrollTop = maxTop
        end
        if self.ScrollTop < 0 then
            self.ScrollTop = 0
        end
    end,

    ---@param self UICustomLobbyMapList
    GetScrollValues = function(self, axis)
        local size = table.getn(self.Items)
        return 0, size, self.ScrollTop, math.min(self.ScrollTop + self.PoolCount, size)
    end,

    ---@param self UICustomLobbyMapList
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta))
    end,

    ---@param self UICustomLobbyMapList
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta) * self.PoolCount)
    end,

    ---@param self UICustomLobbyMapList
    ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.ScrollTop then
            return
        end
        self.ScrollTop = top
        self:ClampTop()
        self:CalcVisible()
    end,

    ---@param self UICustomLobbyMapList
    IsScrollable = function(self, axis)
        return true
    end,

    --#endregion

    ---@param self UICustomLobbyMapList
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyMapList
Create = function(parent)
    return CustomLobbyMapList(parent)
end
