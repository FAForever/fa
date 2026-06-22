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

-- A scrollable, pooled mod list for the mod-select dialog. Each row carries a checkbox (select /
-- deselect the mod), the mod name, and a short type badge. The sibling of CustomLobbyMapList —
-- same virtualisation, same scrollbar contract — with selection checkboxes added.
--
-- Rows are *text-only* (no per-row mod icons) on purpose: a mod's icon is a distinct texture per
-- mod, and the engine never frees the textures a `Bitmap`/`MapPreview` loads (see
-- mapselect/CLAUDE.md). One icon per row × a big vault would leak the memory the game needs
-- in-match, so the icon is shown once, in the dialog's detail panel, for the highlighted mod.
--
-- Two interactions, two regions:
--   * the checkbox toggles membership in the selection (`OnToggle`);
--   * clicking the rest of the row highlights it for the detail panel (`OnSelect`), and
--     double-clicking confirms (`OnConfirm`).
--
-- The list does not own the selection — it paints checkboxes from a selection set the dialog
-- hands it (`SetChecked`) and asks the dialog whether each row may be toggled (`SetCanToggle`,
-- e.g. a non-host can't change sim mods, blacklisted mods can't be enabled). After the dialog
-- mutates the selection it calls `Refresh` to repaint.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 26

-- mod names are single-line Text (which doesn't clip), so cap them with an ellipsis to stop a
-- long name running under the type badge. Char-based (the engine's Text has no width-measure).
local NameMaxChars = 28

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

local SelectedColor = 'ff2c3e48'
local HoverColor = 'ff1a2630'
local IdleColor = '00000000'

local EnabledNameColor = 'ffe9ece9'
local DisabledNameColor = 'ff6a7078'

-- short badge text + colour per mod type
local TypeBadges = {
    GAME =          { text = "GAME", color = 'ffd0a24c' },
    UI =            { text = "UI",   color = 'ff6db3e2' },
    BLACKLISTED =   { text = "BL",   color = 'ffb05050' },
    NO_DEPENDENCY = { text = "DEP",  color = 'ffb05050' },
    LOCAL =         { text = "LCL",  color = 'ffb0902c' },
}

---@class UICustomLobbyModListRow : Group
---@field Background Bitmap
---@field Check Checkbox
---@field Name Text
---@field Badge Text
---@field _poolIndex number
---@field _hover boolean

---@class UICustomLobbyModList : Group
---@field Trash TrashBag
---@field Items UILobbyModInfo[]
---@field Rows UICustomLobbyModListRow[]
---@field PoolCount number
---@field ScrollTop number                    # 0-based scroll offset; NOT the `Top` edge LazyVar
---@field Selected number | false             # highlighted item index (1-based)
---@field Scrollbar Scrollbar | false         # hidden while everything fits
---@field Checked UIModSelection              # the dialog's selection set (read-only here)
---@field CanToggle fun(mod: UILobbyModInfo): boolean
---@field OnSelect fun(mod: UILobbyModInfo, index: number)
---@field OnToggle fun(mod: UILobbyModInfo, checked: boolean)
---@field OnConfirm fun(mod: UILobbyModInfo)
local CustomLobbyModList = ClassUI(Group) {

    ---@param self UICustomLobbyModList
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyModList")

        self.Trash = TrashBag()
        self.Items = {}
        self.Rows = {}
        self.PoolCount = 0
        self.ScrollTop = 0
        self.Selected = false
        self.Scrollbar = false
        self.Checked = {}
        self.CanToggle = function(mod) return true end
        self.OnSelect = nil
        self.OnToggle = nil
        self.OnConfirm = nil
    end,

    ---@param self UICustomLobbyModList
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
    --- Called by the owner after the list is laid out + mounted (three-phase init,
    --- /lua/ui/CLAUDE.md § 1) — the pool count reads `Height()`, unsettled during __post_init.
    ---@param self UICustomLobbyModList
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
        -- CalcVisible iterating past rows that were actually created
        self.PoolCount = count

        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self)
        self:CalcVisible()
    end,

    --- Builds one pooled row (checkbox + name + type badge). Private.
    ---@param self UICustomLobbyModList
    ---@param poolIndex number
    ---@return UICustomLobbyModListRow
    CreateRow = function(self, poolIndex)
        ---@type UICustomLobbyModListRow
        local row = Group(self)
        row._poolIndex = poolIndex
        row._hover = false

        row.Background = Bitmap(row)
        row.Background:SetSolidColor(IdleColor)

        row.Check = UIUtil.CreateCheckbox(row, '/CHECKBOX/', "", false, 11)
        row.Check.OnCheck = function(control, checked)
            local index = self.ScrollTop + poolIndex
            local mod = self.Items[index]
            if mod and self.OnToggle then
                self.OnToggle(mod, checked)
            end
        end

        row.Name = UIUtil.CreateText(row, "", 14, UIUtil.bodyFont)
        row.Name:DisableHitTest()

        row.Badge = UIUtil.CreateText(row, "", 11, UIUtil.bodyFont)
        row.Badge:DisableHitTest()

        Layouter(row.Background):Fill(row):End()
        Layouter(row.Check):AtLeftIn(row, 6):AtVerticalCenterIn(row):End()
        Layouter(row.Name):AnchorToRight(row.Check, 8):AtVerticalCenterIn(row):End()
        Layouter(row.Badge):AtRightIn(row, 10):AtVerticalCenterIn(row):End()

        -- the background catches selection / confirm; the checkbox handles its own clicks, and
        -- the text labels are hit-test-disabled so they don't block the background
        row.Background.HandleEvent = function(control, event)
            local index = self.ScrollTop + poolIndex
            local mod = self.Items[index]
            if not mod then
                return false
            end
            if event.Type == 'ButtonPress' then
                self:SetSelection(index)
                if self.OnSelect then
                    self.OnSelect(mod, index)
                end
                return true
            elseif event.Type == 'ButtonDClick' then
                if self.OnConfirm then
                    self.OnConfirm(mod)
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
    ---@param self UICustomLobbyModList
    ---@param items UILobbyModInfo[]
    SetItems = function(self, items)
        self.Items = items or {}
        self.ScrollTop = 0
        self.Selected = false
        self:CalcVisible()
    end,

    --- Points the list at the dialog's selection set (held by reference; the dialog mutates it
    --- and calls `Refresh`). Drives each row's checkbox state.
    ---@param self UICustomLobbyModList
    ---@param checked UIModSelection
    SetChecked = function(self, checked)
        self.Checked = checked or {}
        self:CalcVisible()
    end,

    --- Sets the predicate deciding whether a row's checkbox is interactive (e.g. a non-host
    --- can't toggle sim mods; blacklisted mods can't be enabled).
    ---@param self UICustomLobbyModList
    ---@param predicate fun(mod: UILobbyModInfo): boolean
    SetCanToggle = function(self, predicate)
        self.CanToggle = predicate or function(mod) return true end
    end,

    --- Repaints the visible window (call after the dialog mutates the selection).
    ---@param self UICustomLobbyModList
    Refresh = function(self)
        self:CalcVisible()
    end,

    --- Selects an item by index (1-based) and repaints; does not scroll (see ShowItem).
    ---@param self UICustomLobbyModList
    ---@param index number | false
    SetSelection = function(self, index)
        self.Selected = index or false
        self:CalcVisible()
    end,

    --- The highlighted mod, or nil.
    ---@param self UICustomLobbyModList
    ---@return UILobbyModInfo | nil
    GetSelected = function(self)
        return self.Selected and self.Items[self.Selected] or nil
    end,

    --- Scrolls so item `index` (1-based) is within the visible window.
    ---@param self UICustomLobbyModList
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

    --- Paints a single row to reflect its data + selection / hover / checkbox state. Private.
    ---@param self UICustomLobbyModList
    ---@param row UICustomLobbyModListRow
    ---@param index number
    PaintRow = function(self, row, index)
        if not row then
            return
        end
        local mod = self.Items[index]
        if not mod then
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

        local canToggle = self.CanToggle(mod)
        row.Check:SetCheck(self.Checked[mod.uid] and true or false, true)
        if canToggle then
            row.Check:Enable()
        else
            row.Check:Disable()
        end

        row.Name:SetText(Truncate(mod.title or mod.name or "?", NameMaxChars))
        row.Name:SetColor(canToggle and EnabledNameColor or DisabledNameColor)

        local badge = TypeBadges[mod.type] or TypeBadges.GAME
        row.Badge:SetText(badge.text)
        row.Badge:SetColor(badge.color)
    end,

    ---------------------------------------------------------------------------
    --#region Scrollbar contract

    ---@param self UICustomLobbyModList
    CalcVisible = function(self)
        for i = 1, self.PoolCount do
            self:PaintRow(self.Rows[i], self.ScrollTop + i)
        end
        self:UpdateScrollbar()
    end,

    --- Shows the scrollbar only when there are more items than fit the pool.
    ---@param self UICustomLobbyModList
    UpdateScrollbar = function(self)
        if not self.Scrollbar then
            return
        end
        if table.getn(self.Items) > self.PoolCount then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end
    end,

    ---@param self UICustomLobbyModList
    ClampTop = function(self)
        local maxTop = math.max(0, table.getn(self.Items) - self.PoolCount)
        if self.ScrollTop > maxTop then
            self.ScrollTop = maxTop
        end
        if self.ScrollTop < 0 then
            self.ScrollTop = 0
        end
    end,

    ---@param self UICustomLobbyModList
    GetScrollValues = function(self, axis)
        local size = table.getn(self.Items)
        return 0, size, self.ScrollTop, math.min(self.ScrollTop + self.PoolCount, size)
    end,

    ---@param self UICustomLobbyModList
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta))
    end,

    ---@param self UICustomLobbyModList
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.ScrollTop + math.floor(delta) * self.PoolCount)
    end,

    ---@param self UICustomLobbyModList
    ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.ScrollTop then
            return
        end
        self.ScrollTop = top
        self:ClampTop()
        self:CalcVisible()
    end,

    ---@param self UICustomLobbyModList
    IsScrollable = function(self, axis)
        return true
    end,

    --#endregion

    ---@param self UICustomLobbyModList
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyModList
Create = function(parent)
    return CustomLobbyModList(parent)
end
