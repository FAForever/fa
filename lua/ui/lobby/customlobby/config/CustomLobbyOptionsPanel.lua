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
-- marker's tooltip names the precise origin (`Map: …` / `Mod: …`). The schema is derived per-peer
-- from the synced scenario + mods via `optionutil`; the values are the synced `GameOptions`.
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

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local OptionUtil = import("/lua/ui/optionutil.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 22
local ScrollGap = 32       -- standard lobby scrollbar gutter (see ModSelect)
local GridContentWidth = 360 - 6 - ScrollGap
local LabelMaxChars = 26

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
---@field ScenarioObserver LazyVar
---@field OptionsObserver LazyVar
---@field ModsObserver LazyVar
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
        -- it exists — observers just rebuild (Refresh is Ready-gated); no show/hide juggling
        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(launch.ScenarioFile, function(lazy) lazy(); self:Refresh() end))
        self.OptionsObserver = self.Trash:Add(
            LazyVarDerive(launch.GameOptions, function(lazy) lazy(); self:Refresh() end))
        self.ModsObserver = self.Trash:Add(
            LazyVarDerive(launch.GameMods, function(lazy) lazy(); self:Refresh() end))
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

    --- Rebuilds the read-only options grid, grouped into Lobby / Scenario / Mods sections with the
    --- hide-defaults filter applied.
    ---@param self UICustomLobbyOptionsPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local launch = CustomLobbyLaunchModel.GetSingleton()
        local scenarioFile = launch.ScenarioFile()
        local gameMods = launch.GameMods()
        local values = launch.GameOptions()

        -- visible (hide-defaults-filtered) entries for one source
        local function collect(options, origin)
            local entries = {}
            for _, option in options do
                if not (self.HideDefaults and OptionUtil.IsDefault(option, values)) then
                    table.insert(entries, {
                        Option = option,
                        Origin = origin,
                        ValueKey = OptionUtil.GetCurrentValueKey(option, values),
                    })
                end
            end
            return entries
        end

        local info = scenarioFile and CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        local mapName = (info and LOC(info.name)) or "the map"

        local modEntries = {}
        for _, group in OptionUtil.GetModOptionsByMod(gameMods) do
            for _, entry in collect(group.options, "Mod: " .. group.name) do
                table.insert(modEntries, entry)
            end
        end

        local sections = {
            { Title = "Lobby",    Entries = collect(OptionUtil.GetLobbyOptions(), false) },
            { Title = "Scenario", Entries = collect(OptionUtil.GetScenarioOptions(scenarioFile), "Map: " .. mapName) },
            { Title = "Mods",     Entries = modEntries },
        }

        local rows = {}
        for _, section in sections do
            if table.getn(section.Entries) > 0 then
                table.insert(rows, { Header = section.Title })
                for _, entry in section.Entries do
                    table.insert(rows, { Entry = entry })
                end
            end
        end

        self.OptionsGrid:DeleteAndDestroyAll(true)
        if table.getn(rows) > 0 then
            self.Empty:Hide()
            self.OptionsGrid:AppendCols(1, true)
            self.OptionsGrid:AppendRows(table.getn(rows), true)
            for index, row in rows do
                local control = row.Header and self:CreateSectionHeader(row.Header) or self:CreateOptionRow(row.Entry)
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

    --- Builds one read-only option row: origin marker (special only) + label + current value.
    ---@param self UICustomLobbyOptionsPanel
    ---@param entry { Option: ScenarioOption, Origin: string|false, ValueKey: any }
    ---@return Group
    CreateOptionRow = function(self, entry)
        local option = entry.Option
        local row = Group(self.OptionsGrid)
        LayoutHelpers.SetDimensions(row, GridContentWidth, RowHeight)

        local labelLeft = 4
        if entry.Origin then
            local marker = Bitmap(row)
            marker:SetSolidColor(SpecialColor)
            Layouter(marker):AtLeftIn(row, 4):AtVerticalCenterIn(row):Width(8):Height(8):End()
            Tooltip.AddControlTooltipManual(marker, "Source", entry.Origin)
            labelLeft = 18
        end

        local label = UIUtil.CreateText(row, Truncate(LOC(option.label) or option.key, LabelMaxChars), 13, UIUtil.bodyFont)
        label:SetColor(entry.Origin and SpecialColor or NormalColor)
        label:DisableHitTest()
        Layouter(label):AtLeftIn(row, labelLeft):AtVerticalCenterIn(row):End()

        local value = UIUtil.CreateText(row, OptionUtil.ValueDisplay(option, entry.ValueKey), 13, UIUtil.bodyFont)
        value:SetColor(ValueColor)
        value:DisableHitTest()
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
