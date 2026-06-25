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

-- The unit-restriction dialog (step 1: the minimal core). A transient `Popup` modelled on the
-- mod-select dialog (see ../modselect/CLAUDE.md): a scrollable list of restriction-preset toggles,
-- with Clear / OK / Cancel. It is NOT a model component — it owns a *working selection* (a set of
-- preset keys) and, on OK, hands the **array of keys** to an `onConfirm` callback. Where that goes
-- is the opener's decision: `Open` routes it through the host-authoritative `RequestSetRestrictions`
-- intent (synced via the launch model's `Restrictions`).
--
-- The preset list needs NO blueprint analysis — `UnitsRestrictions.GetPresetsData()` already gives
-- the name + tooltip per preset, and the sim expands the keys at launch (see simInit.lua). The
-- preset icon grid and the per-unit (UnitsAnalyzer-backed) grid are later steps; they plug into the
-- same working-selection / `onConfirm` contract, so this file's openers stay unchanged.
--
-- `isHost = false` → read-only: the checkboxes are disabled and the OK / Clear buttons are hidden
-- (Cancel reads "Close"), matching the legacy UnitsManager `isHost` contract.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local UnitsRestrictions = import("/lua/ui/lobby/unitsrestrictions.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = true

-- sized for the lobby's 1024×768 floor (the Popup centres it, leaving a small margin)
local DialogWidth = 960
local DialogHeight = 710
local Pad = 12
local TitleHeight = 32
local StatsHeight = 22
local ActionHeight = 44
local RowHeight = 26
local ScrollbarGap = 32      -- standard lobby gutter reserved on the list's right
local Columns = 3            -- the preset checkboxes flow across this many columns to fill the width

local DimColor = 'ff9aa0a8'

-- the width of one preset column (the Grid's cell width); the rows fill it
local ColumnWidth = math.floor((DialogWidth - 2 * Pad - ScrollbarGap) / Columns)

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
    area.Bg = bg
    return area
end

--- The ordered list of selectable preset keys: `GetPresetsOrder()` minus the `""` separators and
--- any key that has no visible preset (name) in the data table.
---@return string[]
local function SelectablePresetKeys()
    local presets = UnitsRestrictions.GetPresetsData()
    local keys = {}
    for _, key in UnitsRestrictions.GetPresetsOrder() do
        if key ~= "" and presets[key] and presets[key].name then
            table.insert(keys, key)
        end
    end
    return keys
end

---@class UICustomLobbyUnitSelect : Group
---@field Trash TrashBag
---@field Editable boolean
---@field Selection table<string, true>
---@field OnConfirmCb fun(keys: string[])
---@field OnCancelCb fun()
---@field Keys string[]
---@field Checkboxes table<string, Checkbox>
---@field TitleArea Group
---@field ListArea Group
---@field StatsArea Group
---@field ActionArea Group
---@field Title Text
---@field Grid Grid
---@field Scrollbar Scrollbar | false
---@field Count Text
---@field SelectButton Button
---@field CancelButton Button
---@field ClearButton Button
local CustomLobbyUnitSelect = ClassUI(Group) {

    ---@param self UICustomLobbyUnitSelect
    ---@param parent Control
    ---@param options { initial: string[], editable: boolean, onConfirm: fun(keys: string[]), onCancel: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyUnitSelect")

        self.Trash = TrashBag()
        self.OnConfirmCb = options.onConfirm
        self.OnCancelCb = options.onCancel
        self.Editable = options.editable ~= false
        self.Scrollbar = false
        self.Checkboxes = {}
        self.Keys = SelectablePresetKeys()

        -- working selection: a set built from the initial key array
        self.Selection = {}
        for _, key in (options.initial or {}) do
            self.Selection[key] = true
        end

        -- areas
        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.ListArea = CreateArea(self, "ListArea", 'ff4060cc')
        self.StatsArea = CreateArea(self, "StatsArea", 'ff40cccc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Unit restrictions", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()

        -- a multi-column grid (cell = one preset column); Grid scales itemWidth / itemHeight
        -- itself, so pass unscaled values
        self.Grid = Grid(self.ListArea, ColumnWidth, RowHeight)

        self.Count = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.Count:SetColor(DimColor)
        self.Count:DisableHitTest()

        --#region actions
        self.SelectButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Ok>OK", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers)
            self:Confirm()
        end

        self.CancelButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small',
            self.Editable and "<LOC _Cancel>Cancel" or "<LOC _Close>Close", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers)
            self.OnCancelCb()
        end

        self.ClearButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Clear", 14, 2)
        self.ClearButton.OnClick = function(button, modifiers)
            self:ClearSelection()
        end
        Tooltip.AddControlTooltipManual(self.ClearButton, "Clear", "Remove every unit restriction.")

        if not self.Editable then
            self.SelectButton:Hide()
            self.ClearButton:Hide()
        end
        --#endregion
    end,

    ---@param self UICustomLobbyUnitSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.StatsArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToTop(self.ActionArea, Pad):Height(StatsHeight):End()
        Layouter(self.ListArea)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.StatsArea, Pad)
            :End()

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        Layouter(self.Grid):AtLeftIn(self.ListArea):AtTopIn(self.ListArea):AtBottomIn(self.ListArea):End()
        self.Grid.Right:Set(function() return self.ListArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarGap) end)

        Layouter(self.Count):AtLeftIn(self.StatsArea):AtVerticalCenterIn(self.StatsArea):End()

        -- one row (the wide dialog has room): Clear on the left, the Cancel / OK pair on the right
        Layouter(self.ClearButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.SelectButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.CancelButton):AnchorToLeft(self.SelectButton, 12):AtVerticalCenterIn(self.SelectButton):End()
    end,

    --- Builds the row pool + scrollbar; called by the opener after Popup mounts + centres the dialog
    --- (three-phase init — the Grid needs a concrete height).
    ---@param self UICustomLobbyUnitSelect
    Initialize = function(self)
        self:Populate()
        if not self.Scrollbar then
            self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
            UIUtil.ForwardWheelToScroll(self.Grid, self.Grid)
        end
        self:UpdateScrollbar()
        self:UpdateStats()
    end,

    --- Builds one checkbox cell per selectable preset, flowed across `Columns` columns.
    ---@param self UICustomLobbyUnitSelect
    Populate = function(self)
        local presets = UnitsRestrictions.GetPresetsData()
        local count = table.getn(self.Keys)

        self.Grid:DeleteAndDestroyAll(true)
        self.Checkboxes = {}
        if count == 0 then
            return
        end

        -- flow the presets left-to-right then down, filling `Columns` columns
        local rows = math.floor((count - 1) / Columns) + 1
        self.Grid:AppendCols(Columns, true)
        self.Grid:AppendRows(rows, true)
        for i, key in self.Keys do
            local col = math.mod(i - 1, Columns) + 1
            local row = math.floor((i - 1) / Columns) + 1
            self.Grid:SetItem(self:CreateRow(presets[key]), col, row, true)
        end
        self.Grid:EndBatch()
    end,

    --- Builds one preset cell: a labelled checkbox wired to the working selection. Private.
    ---@param self UICustomLobbyUnitSelect
    ---@param preset table          # an entry from UnitsRestrictions.GetPresetsData()
    ---@return Group
    CreateRow = function(self, preset)
        local key = preset.key
        local row = Group(self.Grid)
        LayoutHelpers.SetDimensions(row, ColumnWidth, RowHeight)

        local checkbox = UIUtil.CreateCheckbox(row, '/CHECKBOX/', LOC(preset.name) or key, true, 13)
        checkbox:SetCheck(self.Selection[key] == true, true)
        if self.Editable then
            checkbox.OnCheck = function(control, checked)
                self:TogglePreset(key, checked)
            end
        else
            checkbox:Disable()
        end
        if preset.tooltip then
            Tooltip.AddControlTooltipManual(checkbox, LOC(preset.name) or key, LOC(preset.tooltip) or "")
        end
        self.Checkboxes[key] = checkbox

        Layouter(checkbox):AtLeftIn(row):AtVerticalCenterIn(row):End()
        return row
    end,

    --- Adds or removes a preset key from the working selection and refreshes the count.
    ---@param self UICustomLobbyUnitSelect
    ---@param key string
    ---@param checked boolean
    TogglePreset = function(self, key, checked)
        if checked then
            self.Selection[key] = true
        else
            self.Selection[key] = nil
        end
        self:UpdateStats()
    end,

    --- Clears the whole working selection and unticks every checkbox.
    ---@param self UICustomLobbyUnitSelect
    ClearSelection = function(self)
        self.Selection = {}
        for _, checkbox in self.Checkboxes do
            checkbox:SetCheck(false, true)
        end
        self:UpdateStats()
    end,

    --- Updates the "N restrictions" footer.
    ---@param self UICustomLobbyUnitSelect
    UpdateStats = function(self)
        local count = table.getsize(self.Selection)
        if count == 0 then
            self.Count:SetText("No restrictions")
        elseif count == 1 then
            self.Count:SetText("1 restriction")
        else
            self.Count:SetText(count .. " restrictions")
        end
    end,

    --- Shows the scrollbar only when the grid actually overflows.
    ---@param self UICustomLobbyUnitSelect
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

    --- Commits the working selection (as a key array) via the opener's callback.
    ---@param self UICustomLobbyUnitSelect
    Confirm = function(self)
        local keys = {}
        for key in self.Selection do
            table.insert(keys, key)
        end
        self.OnConfirmCb(keys)
    end,

    ---@param self UICustomLobbyUnitSelect
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the unit-restriction dialog. Seeds from the synced `Restrictions`; the host can edit and
--- on OK the new key list routes through the host-authoritative `RequestSetRestrictions` intent. A
--- non-host opens it read-only (a window into the host's choice).
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)

    if Instance then
        Instance:Close()
    end

    local launch = CustomLobbyLaunchModel.GetSingleton()
    local isHost = CustomLobbyLocalModel.GetSingleton().IsHost()

    local popup
    local content = CustomLobbyUnitSelect(parent, {
        initial = launch.Restrictions() or {},
        editable = isHost,
        onConfirm = function(keys)
            CustomLobbyController.RequestSetRestrictions(keys)
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

    -- now that Popup has mounted + centred the content, it's safe to build the rows + scrollbar
    -- (both read concrete geometry)
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
