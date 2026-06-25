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

-- The Units tab panel of the config interface: a **read-only** view of the active unit
-- restrictions. A config-interface tab panel — the host creates it when the Units tab is selected
-- and destroys it on switch, and calls `Initialize` after sizing it (same interface as the others).
--
-- It subscribes to the launch model's `Restrictions` (the preset-key list, host-dictated + synced)
-- and lists each restriction's name. Editing happens in the host-only `CustomLobbyUnitSelect` dialog
-- behind this tab's config gear (see CustomLobbyConfigInterface). Step 1 lists names only; the
-- preset icons land with the dialog's icon grid.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Grid = import("/lua/maui/grid.lua").Grid

local UnitsRestrictions = import("/lua/ui/lobby/unitsrestrictions.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local RowHeight = 24
local ScrollbarGap = 32
local LabelColor = 'ffc8ccd0'
local DimColor = 'ff8a909a'

---@class UICustomLobbyUnitsPanel : Group
---@field Trash TrashBag
---@field Grid Grid
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field Ready boolean
---@field RestrictionsObserver LazyVar
local CustomLobbyUnitsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyUnitsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyUnitsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Scrollbar = false

        -- a single-column list: the column width is nominal (rows bind their own Width to the grid),
        -- only RowHeight drives the vertical layout / scroll. Grid scales these itself (pass unscaled).
        self.Grid = Grid(self, 200, RowHeight)

        self.Empty = UIUtil.CreateText(self, "No unit restrictions.", 14, UIUtil.bodyFont)
        self.Empty:SetColor(DimColor)
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- gated behind Ready so the immediate fire on creation (hot-reload, model already populated)
        -- doesn't rebuild rows before the parent has sized us — see ../CLAUDE.md layout gotchas
        self.RestrictionsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().Restrictions, function(restrictionsLazy)
                restrictionsLazy()
                if self.Ready then
                    self:Refresh()
                end
            end))
    end,

    ---@param self UICustomLobbyUnitsPanel
    __post_init = function(self)
        Layouter(self.Grid):AtLeftIn(self, 6):AtTopIn(self, 6):AtBottomIn(self, 6):End()
        self.Grid.Right:Set(function() return self.Right() - LayoutHelpers.ScaleNumber(ScrollbarGap) end)
        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, 16):End()
    end,

    --- Three-phase init: the tabs container calls this after sizing the panel (the Grid needs a
    --- concrete height). Builds the scrollbar and renders the first list.
    ---@param self UICustomLobbyUnitsPanel
    Initialize = function(self)
        self.Ready = true
        if not self.Scrollbar then
            self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.Grid)
            UIUtil.ForwardWheelToScroll(self.Grid, self.Grid)
        end
        self:Refresh()
    end,

    --- Rebuilds the list of active restriction names from the launch model.
    ---@param self UICustomLobbyUnitsPanel
    Refresh = function(self)
        local presets = UnitsRestrictions.GetPresetsData()
        local keys = CustomLobbyLaunchModel.GetSingleton().Restrictions()
        local count = table.getn(keys)

        self.Grid:DeleteAndDestroyAll(true)

        if count == 0 then
            self.Empty:Show()
            self:UpdateScrollbar()
            return
        end
        self.Empty:Hide()

        self.Grid:AppendCols(1, true)
        self.Grid:AppendRows(count, true)
        for row, key in keys do
            local preset = presets[key]
            local name = (preset and preset.name and LOC(preset.name)) or key
            self.Grid:SetItem(self:CreateRow(name), 1, row, true)
        end
        self.Grid:EndBatch()
        self:UpdateScrollbar()
    end,

    --- Builds one read-only row: the restriction's name. Private.
    ---@param self UICustomLobbyUnitsPanel
    ---@param name string
    ---@return Group
    CreateRow = function(self, name)
        local row = Group(self.Grid)
        LayoutHelpers.SetDimensions(row, 10, RowHeight)
        row.Width:Set(function() return self.Grid.Width() end)

        local label = UIUtil.CreateText(row, name, 13, UIUtil.bodyFont)
        label:SetColor(LabelColor)
        label:DisableHitTest()
        Layouter(label):AtLeftIn(row, 4):AtVerticalCenterIn(row):End()
        return row
    end,

    --- Shows the scrollbar only when the grid actually overflows.
    ---@param self UICustomLobbyUnitsPanel
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

    ---@param self UICustomLobbyUnitsPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyUnitsPanel
Create = function(parent)
    return CustomLobbyUnitsPanel(parent)
end
