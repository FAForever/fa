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

-- The Mods tab panel of the config interface: the enabled mods, grouped into Game mods (the
-- shared sim mods) and UI mods (this peer's local choice), each row showing the mod's **icon + name**
-- with author/version on hover. The grid fills the whole panel — the "Manage mods" button is gone
-- for now (the per-domain edit buttons are removed during the layout rework).
--
-- It reads the **mods derived model** (the enabled mods, already split into groups and enriched with
-- name / icon / author / version), so the panel does no uid resolution or formatting itself. It is a
-- tab panel: created when its tab is selected and destroyed on switch, so it's the live/visible panel
-- for its whole lifetime; the (synced) sim mods refresh it live (UI-mod prefs aren't reactive — same
-- caveat as before, the model re-reads them whenever the sim mods change).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid

local CustomLobbyModsDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbymodsderivedmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

-- taller rows than a plain text list so each mod's icon reads clearly (like the Restrictions panel)
local RowHeight = 34
local IconSize = 26
local ScrollGap = 32       -- standard lobby scrollbar gutter (see ModSelect)
local GridContentWidth = 360 - 6 - ScrollGap
local LabelMaxChars = 28
local NormalColor = 'ffc8ccd0'

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

---@class UICustomLobbyModsPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field ModsGrid Grid
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field ModsObserver LazyVar
local CustomLobbyModsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyModsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyModsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Scrollbar = false

        self.ModsGrid = Grid(self, GridContentWidth, RowHeight)
        self.Empty = UIUtil.CreateText(self, "No mods enabled", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff8a909a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- the derived model already split + enriched the enabled mods; one subscription rebuilds the
        -- panel when they change (Refresh is Ready-gated for the immediate fire on creation)
        self.ModsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyModsDerivedModel.GetModsVar(), function(lazy)
                lazy()
                self:Refresh()
            end))
    end,

    ---@param self UICustomLobbyModsPanel
    __post_init = function(self)
        Layouter(self.ModsGrid)
            :AtLeftIn(self, 6):Width(GridContentWidth)
            :AtTopIn(self, 6):AtBottomIn(self, 4)
            :End()
        Layouter(self.Empty):AtHorizontalCenterIn(self.ModsGrid):AtTopIn(self.ModsGrid, 8):End()
    end,

    --- Builds the grid's scrollbar + does the first render (picking up the current UI-mod prefs).
    --- Called by the host after it has sized the panel (the grid needs a concrete height).
    ---@param self UICustomLobbyModsPanel
    Initialize = function(self)
        self.Ready = true
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.ModsGrid)
        UIUtil.ForwardWheelToScroll(self.ModsGrid, self.ModsGrid)
        self:Refresh()
    end,

    --- Rebuilds the enabled-mods grid from the derived model's groups: a Game mods section + a UI mods
    --- section, each mod shown as icon + name. The bundle is already split + enriched + sorted.
    ---@param self UICustomLobbyModsPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end

        local rows = {}
        for _, group in CustomLobbyModsDerivedModel.GetMods().Groups do
            if table.getn(group.Mods) > 0 then
                table.insert(rows, { Header = group.Title })
                for _, mod in group.Mods do
                    table.insert(rows, { Mod = mod })
                end
            end
        end

        self.ModsGrid:DeleteAndDestroyAll(true)
        if table.getn(rows) > 0 then
            self.Empty:Hide()
            self.ModsGrid:AppendCols(1, true)
            self.ModsGrid:AppendRows(table.getn(rows), true)
            for index, row in rows do
                local control = row.Header and self:CreateSectionHeader(row.Header) or self:CreateModRow(row.Mod)
                self.ModsGrid:SetItem(control, 1, index, true)
            end
            self.ModsGrid:EndBatch()
        else
            self.Empty:Show()
        end
        self:UpdateScrollbar()
    end,

    --- Builds a section header row (Game mods / UI mods) with a thin underline.
    ---@param self UICustomLobbyModsPanel
    ---@param title string
    ---@return Group
    CreateSectionHeader = function(self, title)
        local row = Group(self.ModsGrid)
        LayoutHelpers.SetDimensions(row, GridContentWidth, RowHeight)

        local label = UIUtil.CreateText(row, string.upper(title), 12, UIUtil.titleFont)
        label:SetColor('ff8a909a')
        label:DisableHitTest()
        Layouter(label):AtLeftIn(row, 2):AtVerticalCenterIn(row):End()

        local line = Bitmap(row)
        line:SetSolidColor('ff3a4048')
        line:DisableHitTest()
        Layouter(line):AtLeftIn(row, 2):AtRightIn(row, 2):AtBottomIn(row):Height(1):End()

        return row
    end,

    --- Builds one enabled-mod row: the mod's icon + name, with author/version on hover (the section
    --- header conveys sim vs. UI).
    ---@param self UICustomLobbyModsPanel
    ---@param mod UICustomLobbyMod
    ---@return Group
    CreateModRow = function(self, mod)
        local row = Group(self.ModsGrid)
        LayoutHelpers.SetDimensions(row, GridContentWidth, RowHeight)

        local icon = Bitmap(row)
        icon:SetTexture(mod.Icon)
        Layouter(icon):AtLeftIn(row, 4):AtVerticalCenterIn(row):Width(IconSize):Height(IconSize):End()
        -- author · version on hover (titled with the mod's full name, in case it was truncated)
        local facts = mod.Version ~= "" and (mod.Author .. "   ·   " .. mod.Version) or mod.Author
        Tooltip.AddControlTooltipManual(icon, mod.Name, facts)

        local label = UIUtil.CreateText(row, Truncate(mod.Name, LabelMaxChars), 13, UIUtil.bodyFont)
        label:SetColor(NormalColor)
        label:DisableHitTest()
        Layouter(label):AtLeftIn(row, 4 + IconSize + 8):AtVerticalCenterIn(row):End()

        return row
    end,

    --- Shows the scrollbar only when the grid overflows.
    ---@param self UICustomLobbyModsPanel
    UpdateScrollbar = function(self)
        if not self.Scrollbar then
            return
        end
        if self.ModsGrid:IsScrollable("Vert") then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end
    end,

    ---@param self UICustomLobbyModsPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyModsPanel
Create = function(parent)
    return CustomLobbyModsPanel(parent)
end
