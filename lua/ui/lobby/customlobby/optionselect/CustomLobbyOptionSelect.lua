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

-- The options dialog: three columns — lobby, scenario and mod options — over the currently
-- selected scenario + mods. The third sibling of the map- and mod-select dialogs.
--
-- It is a transient picker, NOT a model component: it owns no synced state. Its inputs are the
-- selected `ScenarioFile`, the selected sim mods (`GameMods`) and the existing option *values*;
-- it derives the option *schema* per column via `optionutil` (lobby = lobbyOptions.lua, scenario =
-- the map's `_options.lua`, mods = each sim mod's lobbyoptions). Only options from the selected
-- scenario / mods are shown, so a column is empty (with an empty state) when that source has none.
--
-- It edits a working copy of the values and, on OK, hands the complete value set (defaults seeded
-- for everything untouched) to an `onConfirm` callback. The in-lobby opener routes that through
-- the host-authoritative `RequestSetGameOptions` intent (game options are synced). An option that
-- is *not* at its default is marked per row (a dot + tinted label) by the column.
--
-- Top bar: a search filter (by option label) and a "Hide defaults" toggle. (Per-column show/hide
-- toggles would need the columns to reflow, which the Grid can't do without rebuilding — left for
-- later; the three columns are fixed for now.)

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local OptionUtil = import("/lua/ui/optionutil.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyOptionColumn = import("/lua/ui/lobby/customlobby/optionselect/customlobbyoptioncolumn.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

local DialogWidth = 980
local DialogHeight = 620
local Pad = 12
local ColGap = 16
local TitleHeight = 32
local FilterHeight = 28
local ActionHeight = 48

-- three equal columns spanning the inner width, each reserving room on its right for a scrollbar
local ColTotalWidth = math.floor((DialogWidth - 2 * Pad - 2 * ColGap) / 3)
local ColContentWidth = ColTotalWidth - 32   -- reserve the standard 32px scrollbar gutter

local PrefsKey = "customlobby_optionselect"

--- Concatenates the three columns' option lists into one (for seeding defaults across all of them).
---@param lobby ScenarioOption[]
---@param scenario ScenarioOption[]
---@param mods ScenarioOption[]
---@return ScenarioOption[]
local function ConcatOptions(lobby, scenario, mods)
    local all = {}
    for _, list in { lobby, scenario, mods } do
        for _, option in list do
            table.insert(all, option)
        end
    end
    return all
end

--- Creates a layout area (an invisible Group with an optional debug tint).
---@param parent Control
---@param name string
---@param color string
---@return Group
local function CreateArea(parent, name, color)
    local area = Group(parent, name)
    local bg = Bitmap(area)
    bg:SetSolidColor(color)
    bg:SetAlpha(Debug and 0.18 or 0.0)
    bg:DisableHitTest()
    Layouter(bg):Fill(area):End()
    return area
end

---@class UICustomLobbyOptionSelect : Group
---@field Trash TrashBag
---@field Values table<string, any>
---@field LobbyOptions ScenarioOption[]
---@field ScenarioOptions ScenarioOption[]
---@field ModOptions ScenarioOption[]
---@field OnConfirmCb fun(values: table<string, any>)
---@field OnCancelCb fun()
---@field HideDefaults boolean
---@field TitleArea Group
---@field ActionArea Group
---@field Title Text
---@field SearchLabel Text
---@field Search Edit
---@field HideDefaultsToggle Checkbox
---@field LobbyColumn UICustomLobbyOptionColumn
---@field ScenarioColumn UICustomLobbyOptionColumn
---@field ModColumn UICustomLobbyOptionColumn
---@field ResetButton Button
---@field SelectButton Button
---@field CancelButton Button
---@field Ready boolean
local CustomLobbyOptionSelect = ClassUI(Group) {

    ---@param self UICustomLobbyOptionSelect
    ---@param parent Control
    ---@param options { scenarioFile: FileName|false, gameMods: table<string,true>, values: table<string,any>, onConfirm: fun(values: table<string,any>), onCancel: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyOptionSelect")

        self.Trash = TrashBag()
        self.OnConfirmCb = options.onConfirm
        self.OnCancelCb = options.onCancel
        self.Ready = false

        -- working copy of the values; the columns read + write this same table
        self.Values = table.copy(options.values or {})

        -- the schema, derived per-column from the selected scenario + mods (reference data)
        self.LobbyOptions = OptionUtil.GetLobbyOptions()
        self.ScenarioOptions = CustomLobbyMapCatalog.LoadOptions(options.scenarioFile)
        self.ModOptions = OptionUtil.GetModOptions(options.gameMods)

        local saved = import("/lua/user/prefs.lua").GetFromCurrentProfile(PrefsKey) or {}
        self.HideDefaults = saved.hideDefaults == true

        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Game options", 22, UIUtil.titleFont)

        --#region top filter bar
        self.SearchLabel = UIUtil.CreateText(self, "Search", 13, UIUtil.bodyFont)
        self.SearchLabel:SetColor('ff9aa0a8')

        self.Search = Edit(self)
        Layouter(self.Search):Left(0):Top(0):Width(96):Height(22):End()
        self.Search:SetFont(UIUtil.bodyFont, 16)
        self.Search:SetForegroundColor(UIUtil.fontColor)
        self.Search:ShowBackground(true)
        self.Search:SetBackgroundColor('77778888')
        self.Search:SetText(saved.search or "")
        self.Search.OnTextChanged = function(control, newText, oldText)
            self:RefreshColumns()
        end
        Tooltip.AddControlTooltipManual(self.Search, "Search", "Filter options by name across all three columns.")

        self.HideDefaultsToggle = UIUtil.CreateCheckbox(self, '/CHECKBOX/', "Hide defaults", true, 13)
        self.HideDefaultsToggle:SetCheck(self.HideDefaults, true)
        self.HideDefaultsToggle.OnCheck = function(control, checked)
            self.HideDefaults = checked
            self:RefreshColumns()
        end
        Tooltip.AddControlTooltipManual(self.HideDefaultsToggle, "Hide defaults",
            "Show only the options that have been changed from their default value.")
        --#endregion

        --#region columns
        self.LobbyColumn = CustomLobbyOptionColumn.Create(self, "Lobby", ColContentWidth)
        self.ScenarioColumn = CustomLobbyOptionColumn.Create(self, "Scenario", ColContentWidth)
        self.ModColumn = CustomLobbyOptionColumn.Create(self, "Mods", ColContentWidth)

        self.LobbyColumn:SetData(self.LobbyOptions, self.Values)
        self.ScenarioColumn:SetData(self.ScenarioOptions, self.Values)
        self.ModColumn:SetData(self.ModOptions, self.Values)
        --#endregion

        --#region actions
        self.ResetButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Reset", 16, 2)
        self.ResetButton.OnClick = function(button, modifiers)
            self:ResetToDefaults()
        end
        Tooltip.AddControlTooltipManual(self.ResetButton, "Reset", "Reset every option to its default value.")

        self.SelectButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Ok>OK", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers)
            self:Confirm()
        end

        self.CancelButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Cancel>Cancel", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers)
            self.OnCancelCb()
        end
        --#endregion
    end,

    ---@param self UICustomLobbyOptionSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        --#region top filter bar
        Layouter(self.SearchLabel):AtLeftIn(self, Pad):AnchorToBottom(self.TitleArea, 10):End()
        Layouter(self.Search):AnchorToRight(self.SearchLabel, 8):AtVerticalCenterIn(self.SearchLabel):Width(220):Height(FilterHeight - 6):End()
        Layouter(self.HideDefaultsToggle):AnchorToRight(self.Search, 24):AtVerticalCenterIn(self.Search):End()
        --#endregion

        --#region columns (three fixed equal columns between the filter bar and the actions)
        Layouter(self.LobbyColumn)
            :AtLeftIn(self, Pad):Width(ColTotalWidth)
            :AnchorToBottom(self.Search, 12):AnchorToTop(self.ActionArea, 10)
            :End()
        Layouter(self.ScenarioColumn)
            :AnchorToRight(self.LobbyColumn, ColGap):Width(ColTotalWidth)
            :AnchorToBottom(self.Search, 12):AnchorToTop(self.ActionArea, 10)
            :End()
        Layouter(self.ModColumn)
            :AnchorToRight(self.ScenarioColumn, ColGap):Width(ColTotalWidth)
            :AnchorToBottom(self.Search, 12):AnchorToTop(self.ActionArea, 10)
            :End()
        --#endregion

        --#region actions
        Layouter(self.SelectButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.CancelButton):AnchorToLeft(self.SelectButton, 12):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.ResetButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        --#endregion
    end,

    --- Builds the columns' scrollbars + first render. Called by the opener after Popup mounts (the
    --- Grids need a concrete height — three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyOptionSelect
    Initialize = function(self)
        self.Ready = true
        self.LobbyColumn:Initialize()
        self.ScenarioColumn:Initialize()
        self.ModColumn:Initialize()
        self:RefreshColumns()
    end,

    --- Re-applies the search + hide-defaults filter to every column.
    ---@param self UICustomLobbyOptionSelect
    RefreshColumns = function(self)
        if not self.Ready then
            return
        end
        local search = string.lower(self.Search:GetText() or "")
        self.LobbyColumn:Refresh(search, self.HideDefaults)
        self.ScenarioColumn:Refresh(search, self.HideDefaults)
        self.ModColumn:Refresh(search, self.HideDefaults)
    end,

    --- Resets every option to its default by clearing the working values in place (the columns
    --- share the table by reference), then re-rendering.
    ---@param self UICustomLobbyOptionSelect
    ResetToDefaults = function(self)
        for key in self.Values do
            self.Values[key] = nil
        end
        self:RefreshColumns()
    end,

    --- Persists the search + hide-defaults filter for next time. Called once on close (not per
    --- interaction — `SetToCurrentProfile` writes the profile, too costly to fire per keystroke).
    ---@param self UICustomLobbyOptionSelect
    SavePrefs = function(self)
        import("/lua/user/prefs.lua").SetToCurrentProfile(PrefsKey, {
            hideDefaults = self.HideDefaults,
            search = self.Search:GetText() or "",
        })
    end,

    --- Commits the complete value set (defaults seeded for every untouched option) via the opener.
    ---@param self UICustomLobbyOptionSelect
    Confirm = function(self)
        local all = ConcatOptions(self.LobbyOptions, self.ScenarioOptions, self.ModOptions)
        self.OnConfirmCb(OptionUtil.SeedDefaults(all, self.Values))
    end,

    ---@param self UICustomLobbyOptionSelect
    OnDestroy = function(self)
        self:SavePrefs()
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the options dialog over `parent`, seeded from the launch model's scenario / mods /
--- option values. Confirming routes the new values through the host-authoritative
--- `RequestSetGameOptions` intent (game options are synced). Replaces any dialog already open.
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)
    if Instance then
        Instance:Close()
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()

    local popup
    local content = CustomLobbyOptionSelect(parent, {
        scenarioFile = launch.ScenarioFile(),
        gameMods = launch.GameMods(),
        values = launch.GameOptions(),
        onConfirm = function(values)
            CustomLobbyController.RequestSetGameOptions(values)
            if popup then
                popup:Close()
            end
        end,
        onCancel = function()
            if popup then
                popup:Close()
            end
        end,
    })

    popup = Popup(parent, content)
    local baseOnClosed = popup.OnClosed
    popup.OnClosed = function(self)
        baseOnClosed(self)
        Instance = false
    end
    Instance = popup

    -- Popup has mounted + centred the content; safe to build the grids' scrollbars + render
    content:Initialize()
end

--- Closes the dialog if open.
function Close()
    if Instance then
        Instance:Close()
        Instance = false
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Close()
end

--#endregion
