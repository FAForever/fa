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

-- The unit-restriction dialog: the custom-lobby rebuild of the legacy UnitsManager, laid out as
--   * a shared **presets strip** on top — the faction-agnostic restriction presets (No T1, No
--     Nukes, …), which restrict by category for everyone;
--   * a row of **faction tabs** (Seraphim / UEF / Cybran / Aeon / …, from the loaded blueprints);
--   * the active faction's **unit grid** below — every unit as an icon you can individually
--     restrict (grouped by type: land / air / naval / construction / economy / support / defenses).
--
-- It is a transient `Popup`, NOT a model component: it owns a *working selection* (a set of keys)
-- and on OK hands the **array of keys** to `onConfirm`. A key is either a preset key
-- (UnitsRestrictions) or a raw unit blueprint id — the sim expands both at launch (a non-preset key
-- is treated as a custom category/id expression — see simInit.lua). `Open` routes the result through
-- the host-authoritative `RequestSetRestrictions` intent (synced via the launch model's
-- `Restrictions`). `editable = false` → read-only (tiles can't toggle; OK / Clear hidden).
--
-- The unit blueprints come from `CustomLobbyUnitCatalog` (reference data, streamed in by
-- `UnitsAnalyzer` for the lobby's sim mods); a progress label shows while they load.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Mods = import("/lua/mods.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local UnitsRestrictions = import("/lua/ui/lobby/unitsrestrictions.lua")
local UnitsAnalyzer = import("/lua/ui/lobby/unitsanalyzer.lua")
local UnitsTooltip = import("/lua/ui/lobby/unitstooltip.lua")
local CustomLobbyUnitCatalog = import("/lua/ui/lobby/customlobby/unitselect/customlobbyunitcatalog.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

-- sized for the lobby's 1024×768 floor (the Popup centres it, leaving a small margin)
local DialogWidth = 960
local DialogHeight = 710
local Pad = 12
local TitleHeight = 32
local TabsHeight = 34
local ActionHeight = 44
local ScrollbarGap = 32      -- standard lobby gutter reserved on a list's right

local DimColor = 'ff9aa0a8'
local TabActiveColor = 'ffffffff'
local TabIdleColor = 'ff7a828c'

-- icon tiles: a square icon in a clickable cell; the tile is TileSize, the Grid cell TileStride
-- (so there's a small gap between tiles). Used for both presets and units.
local TileSize = 48
local TileGap = 4
local TileStride = TileSize + TileGap
local TileIconInset = 2
local TileIdle = 'ff141a20'      -- an unselected tile's background
local TileHover = 'ff1f262e'
local TileSelected = 'ff7a2d2d'  -- a restricted preset/unit is lit red (forbidden)
local TileIconDim = 0.55         -- icon alpha when not restricted

-- the presets strip shows this many rows of preset icons (it scrolls if there are more)
local PresetRows = 3
local PresetAreaHeight = PresetRows * TileStride + 22  -- + the "Presets" label row

-- the order the unit-type groups are shown in within a faction's grid
local UnitGroupOrder = { 'LAND', 'AIR', 'NAVAL', 'CONSTRUCT', 'ECONOMIC', 'SUPPORT', 'DEFENSES', 'CIVILIAN', 'SCU', 'ACU' }

-- the per-faction "disable entire faction" presets — keyed by the blueprint faction name, which
-- matches the UnitsRestrictions preset key. These are NOT shown in the presets strip; instead each
-- faction tab's icon toggles its own (so a whole faction is banned from its tab).
local FactionPresetKeys = {
    UEF = true,
    CYBRAN = true,
    AEON = true,
    SERAPHIM = true,
    NOMADS = true,
}

-- faction-tab chrome
local TabBgIdle = 'ff10151b'
local TabBgActive = 'ff223344'
local TabBgHover = 'ff1a2128'

--- The faction's icon path (reused from its UnitsRestrictions "disable faction" preset), or nil.
---@param factionName string
---@return FileName | nil
local function FactionIcon(factionName)
    local preset = UnitsRestrictions.GetPresetsData()[factionName]
    return preset and preset.Icon
end

--- One icon tile (preset or unit): a background + icon. Clicking toggles the restriction (when
--- editable), lighting the tile red and brightening the icon. Mirrors the config column's
--- `PreviewTool` look. The owner wires `OnToggle` (and, for units, `OnHover`/`OnHoverEnd` to drive
--- the unit tooltip).
---@class UICustomLobbyIconTile : Group
---@field Editable boolean
---@field Selected boolean
---@field Hovered boolean
---@field DimWhenSelected boolean
---@field OnToggle? fun(selected: boolean)
---@field OnHover? fun()
---@field OnHoverEnd? fun()
---@field Bg Bitmap
---@field Icon Bitmap
local IconTile = ClassUI(Group) {

    ---@param self UICustomLobbyIconTile
    ---@param parent Control
    ---@param texture FileName
    ---@param selected boolean
    ---@param editable boolean
    ---@param dimWhenSelected boolean   # units: bright by default, dim (disabled-looking) when restricted
    __init = function(self, parent, texture, selected, editable, dimWhenSelected)
        Group.__init(self, parent, "CustomLobbyIconTile")

        self.Editable = editable
        self.Selected = selected and true or false
        self.Hovered = false
        self.DimWhenSelected = dimWhenSelected and true or false

        self.Bg = Bitmap(self)
        self.Bg:SetSolidColor(TileIdle)

        self.Icon = Bitmap(self)
        if texture then
            self.Icon:SetTexture(texture)
        end
        self.Icon:DisableHitTest()

        self.Bg.HandleEvent = function(control, event)
            if event.Type == 'MouseEnter' then
                self.Hovered = true
                self:ApplyVisual()
                if self.OnHover then self.OnHover() end
                return true
            elseif event.Type == 'MouseExit' then
                self.Hovered = false
                self:ApplyVisual()
                if self.OnHoverEnd then self.OnHoverEnd() end
                return true
            elseif event.Type == 'ButtonPress' and self.Editable then
                self.Selected = not self.Selected
                self:ApplyVisual()
                if self.OnToggle then self.OnToggle(self.Selected) end
                return true
            end
            return false
        end
    end,

    ---@param self UICustomLobbyIconTile
    __post_init = function(self)
        Layouter(self.Bg):Fill(self):End()
        Layouter(self.Icon):AtCenterIn(self):Width(TileSize - 2 * TileIconInset):Height(TileSize - 2 * TileIconInset):End()
        self:ApplyVisual()
    end,

    ---@param self UICustomLobbyIconTile
    ApplyVisual = function(self)
        local bg = TileIdle
        if self.Selected then
            bg = TileSelected
        elseif self.Hovered then
            bg = TileHover
        end
        self.Bg:SetSolidColor(bg)
        -- presets light up when selected (active rule); units dim when selected (the unit is
        -- disabled), so a restricted unit reads as greyed-out
        if self.DimWhenSelected then
            self.Icon:SetAlpha(self.Selected and TileIconDim or 1.0)
        else
            self.Icon:SetAlpha(self.Selected and 1.0 or TileIconDim)
        end
    end,

    --- Sets the selected state without firing `OnToggle` (initial paint + Clear).
    ---@param self UICustomLobbyIconTile
    ---@param selected boolean
    SetSelected = function(self, selected)
        self.Selected = selected and true or false
        self:ApplyVisual()
    end,
}

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

--- Collects a unit-group map ({ [id] = bp }) into an id-sorted list of blueprints.
---@param units table<string, table>
---@return table[]
local function SortedUnits(units)
    local list = {}
    for _, bp in units do
        table.insert(list, bp)
    end
    table.sort(list, function(a, b) return (a.ID or "") < (b.ID or "") end)
    return list
end

--- One faction tab: a full-cell clickable strip (click → view that faction's units) carrying the
--- faction icon, name and a unit-restriction count badge. The icon doubles as the "disable entire
--- faction" toggle (click → ban every unit of the faction); when the faction is disabled the icon
--- goes red + dim. The owner wires `OnSelect` / `OnToggleDisable`.
---@class UICustomLobbyFactionTab : Group
---@field Name string
---@field Editable boolean
---@field Active boolean
---@field Disabled boolean
---@field Hovered boolean
---@field OnSelect? fun()
---@field OnToggleDisable? fun()
---@field Bg Bitmap
---@field IconBg Bitmap
---@field Icon Bitmap
---@field Label Text
---@field Badge Text
local FactionTab = ClassUI(Group) {

    ---@param self UICustomLobbyFactionTab
    ---@param parent Control
    ---@param faction UICustomLobbyFaction
    ---@param editable boolean
    __init = function(self, parent, faction, editable)
        Group.__init(self, parent, "CustomLobbyFactionTab")

        self.Name = faction.Name
        self.Editable = editable
        self.Active = false
        self.Disabled = false
        self.Hovered = false

        self.Bg = Bitmap(self)
        self.Bg:SetSolidColor(TabBgIdle)
        self.Bg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.OnSelect then self.OnSelect() end
                return true
            elseif event.Type == 'MouseEnter' then
                self.Hovered = true
                self:ApplyVisual()
                return true
            elseif event.Type == 'MouseExit' then
                self.Hovered = false
                self:ApplyVisual()
                return true
            end
            return false
        end

        -- the faction icon doubles as the "disable entire faction" toggle
        self.IconBg = Bitmap(self)
        self.IconBg:SetSolidColor('00000000')
        self.Icon = Bitmap(self.IconBg)
        local icon = FactionIcon(self.Name)
        if icon then
            self.Icon:SetTexture(icon)
        end
        self.Icon:DisableHitTest()
        self.IconBg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and self.Editable then
                if self.OnToggleDisable then self.OnToggleDisable() end
                return true
            end
            return false
        end
        Tooltip.AddControlTooltipManual(self.IconBg, "Disable faction", "Restrict every unit of this faction.")

        self.Label = UIUtil.CreateText(self, self.Name, 15, UIUtil.titleFont)
        self.Label:DisableHitTest()
        self.Badge = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Badge:SetColor(DimColor)
        self.Badge:DisableHitTest()
    end,

    ---@param self UICustomLobbyFactionTab
    __post_init = function(self)
        local iconSize = 24
        Layouter(self.Bg):Fill(self):End()
        -- the icon doubles as the disable toggle, so it must sit *above* the tab's Bg (which handles
        -- the select-click) to receive its own clicks
        Layouter(self.IconBg):AtLeftIn(self, 8):AtVerticalCenterIn(self):Width(iconSize):Height(iconSize):Over(self, 10):End()
        Layouter(self.Icon):Fill(self.IconBg):Over(self.IconBg, 1):End()
        Layouter(self.Label):AnchorToRight(self.IconBg, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Badge):AnchorToRight(self.Label, 6):AtVerticalCenterIn(self):End()
        self:ApplyVisual()
    end,

    ---@param self UICustomLobbyFactionTab
    ApplyVisual = function(self)
        local bg = TabBgIdle
        if self.Active then
            bg = TabBgActive
        elseif self.Hovered then
            bg = TabBgHover
        end
        self.Bg:SetSolidColor(bg)
        self.Label:SetColor(self.Active and TabActiveColor or TabIdleColor)
        -- the icon button shows the faction-disabled state (red + dimmed icon = banned)
        self.IconBg:SetSolidColor(self.Disabled and TileSelected or '00000000')
        self.Icon:SetAlpha(self.Disabled and TileIconDim or 1.0)
    end,

    ---@param self UICustomLobbyFactionTab
    ---@param active boolean
    SetActive = function(self, active)
        self.Active = active and true or false
        self:ApplyVisual()
    end,

    ---@param self UICustomLobbyFactionTab
    ---@param disabled boolean
    SetDisabled = function(self, disabled)
        self.Disabled = disabled and true or false
        self:ApplyVisual()
    end,

    ---@param self UICustomLobbyFactionTab
    ---@param count number
    SetBadge = function(self, count)
        self.Badge:SetText(count > 0 and ("(" .. count .. ")") or "")
    end,
}

---@class UICustomLobbyUnitSelect : Group
---@field Trash TrashBag
---@field Editable boolean
---@field ActiveMods table[]
---@field Selection table<string, true>
---@field OnConfirmCb fun(keys: string[])
---@field OnCancelCb fun()
---@field Ready boolean
---@field PresetTiles table<string, UICustomLobbyIconTile>
---@field UnitTiles table<string, UICustomLobbyIconTile>
---@field Factions UICustomLobbyFaction[]
---@field FactionIds table<string, table<string, true>>   # faction name -> set of its unit ids
---@field ActiveFaction string | false
---@field FactionTabs { name: string, tab: UICustomLobbyFactionTab }[]
---@field PresetPerRow number
---@field UnitPerRow number
---@field TitleArea Group
---@field PresetArea Group
---@field TabsArea Group
---@field UnitArea Group
---@field ActionArea Group
---@field Title Text
---@field Stats Text
---@field PresetLabel Text
---@field PresetGrid Grid
---@field PresetScrollbar Scrollbar | false
---@field UnitGrid Grid
---@field UnitScrollbar Scrollbar | false
---@field ProgressLabel Text
---@field SelectButton Button
---@field CancelButton Button
---@field ClearButton Button
---@field FactionsObserver LazyVar
---@field ProgressObserver LazyVar
local CustomLobbyUnitSelect = ClassUI(Group) {

    ---@param self UICustomLobbyUnitSelect
    ---@param parent Control
    ---@param options { initial: string[], editable: boolean, activeMods: table[], onConfirm: fun(keys: string[]), onCancel: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyUnitSelect")

        self.Trash = TrashBag()
        self.OnConfirmCb = options.onConfirm
        self.OnCancelCb = options.onCancel
        self.Editable = options.editable ~= false
        self.ActiveMods = options.activeMods or {}
        self.Ready = false
        self.PresetTiles = {}
        self.UnitTiles = {}
        self.Factions = {}
        self.FactionIds = {}
        self.ActiveFaction = false
        self.FactionTabs = {}
        self.PresetPerRow = 1
        self.UnitPerRow = 1
        self.PresetScrollbar = false
        self.UnitScrollbar = false

        -- working selection: a set built from the initial key array
        self.Selection = {}
        for _, key in (options.initial or {}) do
            self.Selection[key] = true
        end

        -- areas
        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.PresetArea = CreateArea(self, "PresetArea", 'ff40cc60')
        self.TabsArea = CreateArea(self, "TabsArea", 'ffcc8040')
        self.UnitArea = CreateArea(self, "UnitArea", 'ff4060cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Unit restrictions", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()
        self.Stats = UIUtil.CreateText(self.TitleArea, "", 14, UIUtil.bodyFont)
        self.Stats:SetColor(DimColor)
        self.Stats:DisableHitTest()

        self.PresetLabel = UIUtil.CreateText(self.PresetArea, "Presets", 13, UIUtil.titleFont)
        self.PresetLabel:SetColor(DimColor)
        self.PresetLabel:DisableHitTest()

        -- two icon grids; Grid scales itemWidth / itemHeight itself (pass unscaled)
        self.PresetGrid = Grid(self.PresetArea, TileStride, TileStride)
        self.UnitGrid = Grid(self.UnitArea, TileStride, TileStride)

        self.ProgressLabel = UIUtil.CreateText(self.UnitArea, "Loading blueprints…", 16, UIUtil.bodyFont)
        self.ProgressLabel:SetColor(DimColor)
        self.ProgressLabel:DisableHitTest()

        --#region actions
        self.SelectButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Ok>OK", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers) self:Confirm() end

        self.CancelButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small',
            self.Editable and "<LOC _Cancel>Cancel" or "<LOC _Close>Close", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers) self.OnCancelCb() end

        self.ClearButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Clear", 14, 2)
        self.ClearButton.OnClick = function(button, modifiers) self:ClearSelection() end
        Tooltip.AddControlTooltipManual(self.ClearButton, "Clear", "Remove every unit restriction.")

        if not self.Editable then
            self.SelectButton:Hide()
            self.ClearButton:Hide()
        end
        --#endregion

        -- react to the catalog streaming in (gated by Ready so the immediate fire on creation —
        -- e.g. when already loaded from a previous open — doesn't build grids before we're sized)
        self.FactionsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyUnitCatalog.GetFactionsVar(), function(factionsLazy)
                local factions = factionsLazy()
                if self.Ready and table.getn(factions) > 0 then
                    self:OnFactionsLoaded(factions)
                end
            end))
        self.ProgressObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyUnitCatalog.GetProgressTextVar(), function(textLazy)
                local text = textLazy()
                if self.Ready and not CustomLobbyUnitCatalog.IsLoaded() then
                    self.ProgressLabel:SetText(text ~= "" and text or "Loading blueprints…")
                end
            end))
    end,

    ---@param self UICustomLobbyUnitSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.PresetArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToBottom(self.TitleArea, Pad):Height(PresetAreaHeight):End()
        Layouter(self.TabsArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AnchorToBottom(self.PresetArea, Pad):Height(TabsHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.UnitArea)
            :AtLeftIn(self, Pad):AtRightIn(self, Pad)
            :AnchorToBottom(self.TabsArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()

        Layouter(self.Title):AtLeftIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.Stats):AtRightIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        Layouter(self.PresetLabel):AtLeftIn(self.PresetArea):AtTopIn(self.PresetArea):End()
        Layouter(self.PresetGrid):AtLeftIn(self.PresetArea):AnchorToBottom(self.PresetLabel, 4):AtBottomIn(self.PresetArea):End()
        self.PresetGrid.Right:Set(function() return self.PresetArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarGap) end)

        Layouter(self.UnitGrid):AtLeftIn(self.UnitArea):AtTopIn(self.UnitArea):AtBottomIn(self.UnitArea):End()
        self.UnitGrid.Right:Set(function() return self.UnitArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarGap) end)
        Layouter(self.ProgressLabel):AtHorizontalCenterIn(self.UnitArea):AtVerticalCenterIn(self.UnitArea):End()

        -- one row: Clear on the left, the Cancel / OK pair on the right
        Layouter(self.ClearButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.SelectButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.CancelButton):AnchorToLeft(self.SelectButton, 12):AtVerticalCenterIn(self.SelectButton):End()
    end,

    --- Three-phase init: the opener calls this after Popup mounts + centres the dialog (the Grids
    --- need a concrete width to know how many tiles fit a row). Builds the presets strip, kicks off
    --- the blueprint load, and renders the factions if they're already cached.
    ---@param self UICustomLobbyUnitSelect
    Initialize = function(self)
        self.Ready = true

        self.PresetPerRow = math.max(1, self.PresetGrid:GetVisible())
        self.UnitPerRow = math.max(1, self.UnitGrid:GetVisible())

        self:BuildPresetGrid()
        if not self.PresetScrollbar then
            self.PresetScrollbar = UIUtil.CreateVertScrollbarFor(self.PresetGrid)
            UIUtil.ForwardWheelToScroll(self.PresetGrid, self.PresetGrid)
        end
        if not self.UnitScrollbar then
            self.UnitScrollbar = UIUtil.CreateVertScrollbarFor(self.UnitGrid)
            UIUtil.ForwardWheelToScroll(self.UnitGrid, self.UnitGrid)
        end

        CustomLobbyUnitCatalog.EnsureLoaded(self.ActiveMods)
        if CustomLobbyUnitCatalog.IsLoaded() then
            self:OnFactionsLoaded(CustomLobbyUnitCatalog.GetFactions())
        else
            self.ProgressLabel:Show()
        end

        self:UpdateStats()
        self:UpdatePresetLabel()
        self:UpdateScrollbar(self.PresetGrid, self.PresetScrollbar)
    end,

    ---------------------------------------------------------------------------
    --#region Presets strip

    --- Builds the presets strip: every restriction preset as an icon tile, flowing left-to-right and
    --- starting a fresh row at each preset-group separator. (All presets — they're faction-agnostic.)
    ---@param self UICustomLobbyUnitSelect
    BuildPresetGrid = function(self)
        local presets = UnitsRestrictions.GetPresetsData()
        local order = UnitsRestrictions.GetPresetsOrder()
        local perRow = self.PresetPerRow

        self.PresetGrid:DeleteAndDestroyAll(true)
        self.PresetTiles = {}

        local placements = {}
        local col, row, maxRow = 1, 1, 1
        local placedAny = false
        local pendingBreak = false
        for _, key in order do
            if key == "" then
                pendingBreak = true
            elseif presets[key] and presets[key].name and not FactionPresetKeys[key] then
                -- faction presets are excluded here — each faction tab's icon toggles its own
                if pendingBreak and placedAny and col > 1 then
                    row = row + 1
                    col = 1
                end
                pendingBreak = false
                table.insert(placements, { key = key, col = col, row = row })
                placedAny = true
                if row > maxRow then maxRow = row end
                col = col + 1
                if col > perRow then col = 1; row = row + 1 end
            end
        end

        if table.getn(placements) == 0 then
            return
        end

        self.PresetGrid:AppendCols(perRow, true)
        self.PresetGrid:AppendRows(maxRow, true)
        for _, placement in placements do
            self.PresetGrid:SetItem(self:CreatePresetTile(presets[placement.key]), placement.col, placement.row, true)
        end
        self.PresetGrid:EndBatch()
    end,

    --- Builds one preset cell: an icon tile wired to the working selection. Private.
    ---@param self UICustomLobbyUnitSelect
    ---@param preset table
    ---@return Group
    CreatePresetTile = function(self, preset)
        local key = preset.key
        local cell = Group(self.PresetGrid)
        LayoutHelpers.SetDimensions(cell, TileStride, TileStride)

        local tile = IconTile(cell, preset.Icon, self.Selection[key] == true, self.Editable, false)
        tile.OnToggle = function(selected) self:ToggleKey(key, selected) end
        Layouter(tile):AtLeftIn(cell):AtTopIn(cell):Width(TileSize):Height(TileSize):End()

        if preset.tooltip then
            Tooltip.AddControlTooltipManual(tile.Bg, LOC(preset.name) or key, LOC(preset.tooltip) or "")
        end
        self.PresetTiles[key] = tile
        return cell
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Faction tabs + unit grid

    --- The catalog finished loading: cache the factions, build the faction tabs, and render the
    --- first faction's units.
    ---@param self UICustomLobbyUnitSelect
    ---@param factions UICustomLobbyFaction[]
    OnFactionsLoaded = function(self, factions)
        self.Factions = factions
        self.ProgressLabel:Hide()

        -- per-faction set of unit ids (for the tab badges)
        self.FactionIds = {}
        for _, faction in factions do
            local ids = {}
            for _, bp in faction.Blueprints do
                if bp.ID then ids[bp.ID] = true end
            end
            self.FactionIds[faction.Name] = ids
        end

        self:BuildFactionTabs()
        if table.getn(factions) > 0 then
            self.ActiveFaction = factions[1].Name
            self:PaintTabs()
            self:BuildUnitGrid(factions[1])
        end
    end,

    --- (Re)builds the faction tabs, dividing the tabs area into equal full-width cells. Each tab
    --- selects its faction on click; its icon toggles "disable entire faction".
    ---@param self UICustomLobbyUnitSelect
    BuildFactionTabs = function(self)
        for _, entry in self.FactionTabs do
            entry.tab:Destroy()
        end
        self.FactionTabs = {}

        local count = table.getn(self.Factions)
        if count == 0 then
            return
        end

        for index, faction in self.Factions do
            local name = faction.Name
            local tab = FactionTab(self.TabsArea, faction, self.Editable)
            tab.OnSelect = function() self:SetActiveFaction(name) end
            tab.OnToggleDisable = function() self:ToggleFaction(name) end
            -- equal full-width cells: cell `index` of `count` across the tabs area
            local i = index
            tab.Left:Set(function() return self.TabsArea.Left() + (i - 1) * (self.TabsArea.Width() / count) end)
            tab.Right:Set(function() return self.TabsArea.Left() + i * (self.TabsArea.Width() / count) end)
            tab.Top:Set(function() return self.TabsArea.Top() end)
            tab.Bottom:Set(function() return self.TabsArea.Bottom() end)
            table.insert(self.FactionTabs, { name = name, tab = tab })
        end
    end,

    --- Switches the active faction and rebuilds its unit grid (a no-op if already active).
    ---@param self UICustomLobbyUnitSelect
    ---@param name string
    SetActiveFaction = function(self, name)
        if self.ActiveFaction == name then
            return
        end
        self.ActiveFaction = name
        self:PaintTabs()
        for _, faction in self.Factions do
            if faction.Name == name then
                self:BuildUnitGrid(faction)
                break
            end
        end
    end,

    --- Refreshes every faction tab: which is active, which faction is fully disabled, and each
    --- tab's restricted-unit-count badge.
    ---@param self UICustomLobbyUnitSelect
    PaintTabs = function(self)
        for _, entry in self.FactionTabs do
            entry.tab:SetActive(entry.name == self.ActiveFaction)
            entry.tab:SetDisabled(self.Selection[entry.name] == true)
            entry.tab:SetBadge(self:CountForFaction(entry.name))
        end
    end,

    --- Toggles "disable entire faction" — the faction's UnitsRestrictions preset key (its own name).
    --- Driven by the faction tab's icon. Not shown in the presets strip; reflected on the tab.
    ---@param self UICustomLobbyUnitSelect
    ---@param name string
    ToggleFaction = function(self, name)
        self.Selection[name] = (not self.Selection[name]) and true or nil
        self:UpdateStats()
        self:PaintTabs()
    end,

    --- How many of a faction's units are currently in the selection (its tab badge count).
    ---@param self UICustomLobbyUnitSelect
    ---@param name string
    ---@return number
    CountForFaction = function(self, name)
        local ids = self.FactionIds[name]
        if not ids then
            return 0
        end
        local count = 0
        for key in self.Selection do
            if ids[key] then count = count + 1 end
        end
        return count
    end,

    --- Builds the active faction's unit grid: each type group (land / air / naval / …) flows its
    --- units left-to-right and starts on a fresh row.
    ---@param self UICustomLobbyUnitSelect
    ---@param faction UICustomLobbyFaction
    BuildUnitGrid = function(self, faction)
        local perRow = self.UnitPerRow

        self.UnitGrid:DeleteAndDestroyAll(true)
        self.UnitTiles = {}

        -- gather the placements group by group
        local placements = {}
        local col, row, maxRow = 1, 1, 1
        local placedAny = false
        for _, group in UnitGroupOrder do
            local units = faction.Units[group]
            if units and not table.empty(units) then
                if placedAny and col > 1 then   -- start each group on a fresh row
                    row = row + 1
                    col = 1
                end
                for _, bp in SortedUnits(units) do
                    table.insert(placements, { bp = bp, col = col, row = row })
                    placedAny = true
                    if row > maxRow then maxRow = row end
                    col = col + 1
                    if col > perRow then col = 1; row = row + 1 end
                end
            end
        end

        if table.getn(placements) == 0 then
            self:UpdateScrollbar(self.UnitGrid, self.UnitScrollbar)
            return
        end

        self.UnitGrid:AppendCols(perRow, true)
        self.UnitGrid:AppendRows(maxRow, true)
        for _, placement in placements do
            self.UnitGrid:SetItem(self:CreateUnitTile(placement.bp, faction.Name), placement.col, placement.row, true)
        end
        self.UnitGrid:EndBatch()
        self:UpdateScrollbar(self.UnitGrid, self.UnitScrollbar)
    end,

    --- Builds one unit cell: an icon tile wired to the working selection (keyed by blueprint id),
    --- with the unit tooltip on hover. Private.
    ---@param self UICustomLobbyUnitSelect
    ---@param bp table
    ---@param factionName string
    ---@return Group
    CreateUnitTile = function(self, bp, factionName)
        local id = bp.ID
        local cell = Group(self.UnitGrid)
        LayoutHelpers.SetDimensions(cell, TileStride, TileStride)

        local texture = UnitsAnalyzer.GetImagePath(bp, factionName)
        local tile = IconTile(cell, texture, self.Selection[id] == true, self.Editable, true)
        tile.OnToggle = function(selected) self:ToggleKey(id, selected) end
        tile.OnHover = function() UnitsTooltip.Create(tile, bp) end
        tile.OnHoverEnd = function() UnitsTooltip.Destroy() end
        Layouter(tile):AtLeftIn(cell):AtTopIn(cell):Width(TileSize):Height(TileSize):End()

        self.UnitTiles[id] = tile
        return cell
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Selection

    --- Adds or removes a key (preset key or unit id) from the working selection and refreshes the
    --- stats + tab badges. Keeps any other tile showing the same key in sync.
    ---@param self UICustomLobbyUnitSelect
    ---@param key string
    ---@param selected boolean
    ToggleKey = function(self, key, selected)
        if selected then
            self.Selection[key] = true
        else
            self.Selection[key] = nil
        end
        -- a key can appear in both grids (e.g. a preset and a unit are distinct keys, but a unit id
        -- shown again after a faction switch); keep the matching tiles consistent
        if self.PresetTiles[key] then self.PresetTiles[key]:SetSelected(selected) end
        if self.UnitTiles[key] then self.UnitTiles[key]:SetSelected(selected) end
        self:UpdateStats()
        self:UpdatePresetLabel()
        self:PaintTabs()
    end,

    --- Clears the whole working selection and unlights every tile.
    ---@param self UICustomLobbyUnitSelect
    ClearSelection = function(self)
        self.Selection = {}
        for _, tile in self.PresetTiles do tile:SetSelected(false) end
        for _, tile in self.UnitTiles do tile:SetSelected(false) end
        self:UpdateStats()
        self:UpdatePresetLabel()
        self:PaintTabs()
    end,

    --- Updates the "N restrictions" stat (total selected keys).
    ---@param self UICustomLobbyUnitSelect
    UpdateStats = function(self)
        local count = table.getsize(self.Selection)
        if count == 0 then
            self.Stats:SetText("No restrictions")
        elseif count == 1 then
            self.Stats:SetText("1 restriction")
        else
            self.Stats:SetText(count .. " restrictions")
        end
    end,

    --- Updates the presets-strip label with the count of selected presets (excluding the faction
    --- ones, which live on the tabs).
    ---@param self UICustomLobbyUnitSelect
    UpdatePresetLabel = function(self)
        local presets = UnitsRestrictions.GetPresetsData()
        local count = 0
        for key in self.Selection do
            if presets[key] and not FactionPresetKeys[key] then
                count = count + 1
            end
        end
        self.PresetLabel:SetText(count > 0 and ("Presets (" .. count .. ")") or "Presets")
    end,

    --- Shows a grid's scrollbar only when it actually overflows.
    ---@param self UICustomLobbyUnitSelect
    ---@param grid Grid
    ---@param scrollbar Scrollbar | false
    UpdateScrollbar = function(self, grid, scrollbar)
        if not scrollbar then
            return
        end
        if grid:IsScrollable("Vert") then
            scrollbar:Show()
        else
            scrollbar:Hide()
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

    --#endregion

    ---@param self UICustomLobbyUnitSelect
    OnDestroy = function(self)
        UnitsTooltip.Destroy()
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
        activeMods = Mods.GetGameMods(launch.GameMods()),
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

    -- now that Popup has mounted + centred the content, it's safe to build the grids (they read
    -- concrete geometry)
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
