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

-- The Options tab of the config interface: a read-only view of the current option values, grouped
-- into Lobby / Scenario / Mods sections, with a hide-defaults toggle. The grid fills the whole
-- panel — the per-domain action buttons (open editor / reset) are gone; the interface's action-bar
-- Settings button owns opening the options editor, and they'll be reconsidered when the config
-- rework resumes.
--
-- Options that come from the map or a mod are flagged with a gold marker + tinted label; the
-- marker's tooltip names the precise origin (`Map: …` / `Mod: …`), and an option's help shows as a
-- tooltip on its label. All of this is read straight from the **options derived model** (categorized,
-- enriched, schema-cached) — the panel does no schema gathering or value interpretation itself.
--
-- It is a tab panel: created when its tab is selected and destroyed on switch, so it's the
-- live/visible panel for its whole lifetime — model observers just rebuild it. `Initialize` (called
-- by the tabs container after sizing it) builds the grid's scrollbar + does the first render; the
-- grid needs a concrete height by then.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid

local CustomLobbyOptionsDerivedModel = import("/lua/ui/lobby/customlobby/derived/customlobbyoptionsderivedmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 22
local ScrollGap = 32       -- standard lobby scrollbar gutter (see ModSelect)
local GridContentWidth = 360 - 6 - ScrollGap
local LabelMaxChars = 22
local ValueMaxChars = 22

local SpecialColor = 'ffd0a24c'      -- marker + label tint for a map/mod option
local NormalColor = 'ffc8ccd0'
local ValueColor = 'ff9aa0a8'

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

---@class UICustomLobbyOptionsPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field HideDefaults boolean
---@field HideDefaultsToggle Checkbox
---@field OptionsGrid Grid
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field OptionsObserver LazyVar
local CustomLobbyOptionsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyOptionsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyOptionsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.HideDefaults = true
        self.Scrollbar = false

        self.HideDefaultsToggle = UIUtil.CreateCheckbox(self, '/CHECKBOX/', "Hide defaults", true, 13)
        self.HideDefaultsToggle:SetCheck(self.HideDefaults, true)
        self.HideDefaultsToggle.OnCheck = function(control, checked)
            self.HideDefaults = checked
            self:Refresh()
        end
        Tooltip.AddControlTooltipManual(self.HideDefaultsToggle, "Hide defaults",
            "Show only the options that have been changed from their default value.")

        self.OptionsGrid = Grid(self, GridContentWidth, RowHeight)
        self.Empty = UIUtil.CreateText(self, "All options at default", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff8a909a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- the panel is created/destroyed with its tab, so it's always the live/visible panel while
        -- it exists — the observer just rebuilds (Refresh is Ready-gated); no show/hide juggling. One
        -- subscription: the derived model already joins scenario + mods + values into the bundle.
        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyOptionsDerivedModel.GetOptionsVar(), function(lazy) lazy(); self:Refresh() end))
    end,

    ---@param self UICustomLobbyOptionsPanel
    __post_init = function(self)
        Layouter(self.HideDefaultsToggle):AtLeftIn(self, 6):AtTopIn(self, 4):End()
        Layouter(self.OptionsGrid)
            :AtLeftIn(self, 6):Width(GridContentWidth)
            :AnchorToBottom(self.HideDefaultsToggle, 6):AtBottomIn(self, 4)
            :End()
        Layouter(self.Empty):AtHorizontalCenterIn(self.OptionsGrid):AtTopIn(self.OptionsGrid, 8):End()
    end,

    --- Builds the grid's scrollbar + does the first render. Called by the tabs container after it
    --- has sized the panel (the grid needs a concrete height — three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyOptionsPanel
    Initialize = function(self)
        self.Ready = true
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.OptionsGrid)
        UIUtil.ForwardWheelToScroll(self.OptionsGrid, self.OptionsGrid)
        self:Refresh()
    end,

    --- Rebuilds the read-only options grid from the derived model's categories, with the hide-defaults
    --- filter applied. The bundle is already split + enriched, so the panel only filters + lays out.
    ---@param self UICustomLobbyOptionsPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local options = CustomLobbyOptionsDerivedModel.GetOptions()

        local rows = {}
        for _, category in options.Categories do
            local visible = {}
            for _, option in category.Options do
                if not (self.HideDefaults and option.IsDefault) then
                    table.insert(visible, option)
                end
            end
            if table.getn(visible) > 0 then
                table.insert(rows, { Header = category.Title })
                for _, option in visible do
                    table.insert(rows, { Option = option })
                end
            end
        end

        self.OptionsGrid:DeleteAndDestroyAll(true)
        if table.getn(rows) > 0 then
            self.Empty:Hide()
            self.OptionsGrid:AppendCols(1, true)
            self.OptionsGrid:AppendRows(table.getn(rows), true)
            for index, row in rows do
                local control = row.Header and self:CreateSectionHeader(row.Header) or self:CreateOptionRow(row.Option)
                self.OptionsGrid:SetItem(control, 1, index, true)
            end
            self.OptionsGrid:EndBatch()
        else
            self.Empty:Show()
        end
        self:UpdateScrollbar()
    end,

    --- Builds a section header row (Lobby / Scenario / Mods) with a thin underline.
    ---@param self UICustomLobbyOptionsPanel
    ---@param title string
    ---@return Group
    CreateSectionHeader = function(self, title)
        local row = Group(self.OptionsGrid)
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

    --- Builds one read-only option row from an enriched option: origin marker (special only) + label
    --- (help as a tooltip) + current value. Everything is pre-resolved on the bundle.
    ---@param self UICustomLobbyOptionsPanel
    ---@param option UICustomLobbyOption
    ---@return Group
    CreateOptionRow = function(self, option)
        local row = Group(self.OptionsGrid)
        LayoutHelpers.SetDimensions(row, GridContentWidth, RowHeight)

        local labelLeft = 4
        if option.Origin then
            local marker = Bitmap(row)
            marker:SetSolidColor(SpecialColor)
            Layouter(marker):AtLeftIn(row, 4):AtVerticalCenterIn(row):Width(8):Height(8):End()
            local prefix = (option.Origin.Kind == 'scenario') and "Map: " or "Mod: "
            Tooltip.AddControlTooltipManual(marker, "Source", prefix .. option.Origin.Name)
            labelLeft = 18
        end

        local label = UIUtil.CreateText(row, Truncate(option.Label, LabelMaxChars), 13, UIUtil.bodyFont)
        label:SetColor(option.Origin and SpecialColor or NormalColor)
        -- the option's help reads as a tooltip on its label (hit-test stays on for that); no help → inert
        if option.Help then
            Tooltip.AddControlTooltipManual(label, option.Label, option.Help)
        else
            label:DisableHitTest()
        end
        Layouter(label):AtLeftIn(row, labelLeft):AtVerticalCenterIn(row):End()

        local value = UIUtil.CreateText(row, Truncate(option.ValueText, ValueMaxChars), 13, UIUtil.bodyFont)
        value:SetColor(ValueColor)
        -- the chosen value's help reads as a tooltip (titled with the full value text, in case it was
        -- truncated); no help → inert
        if option.ValueHelp then
            Tooltip.AddControlTooltipManual(value, option.ValueText, option.ValueHelp)
        else
            value:DisableHitTest()
        end
        Layouter(value):AtRightIn(row, 4):AtVerticalCenterIn(row):End()

        return row
    end,

    --- Shows the scrollbar only when the grid overflows.
    ---@param self UICustomLobbyOptionsPanel
    UpdateScrollbar = function(self)
        if not self.Scrollbar then
            return
        end
        if self.OptionsGrid:IsScrollable("Vert") then
            self.Scrollbar:Show()
        else
            self.Scrollbar:Hide()
        end
    end,

    ---@param self UICustomLobbyOptionsPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyOptionsPanel
Create = function(parent)
    return CustomLobbyOptionsPanel(parent)
end
