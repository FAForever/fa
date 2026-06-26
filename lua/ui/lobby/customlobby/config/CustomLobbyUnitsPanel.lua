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
-- It reads the **restrictions derived model** (the active restrictions, each already enriched with its
-- preset name / icon / tooltip) and lists each one with its preset icon + name. Editing happens in the
-- host-only `CustomLobbyUnitSelect` dialog behind this tab's config gear (see CustomLobbyConfigInterface).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Grid = import("/lua/maui/grid.lua").Grid

local CustomLobbyRestrictionsDerivedModel = import("/lua/ui/lobby/customlobby/derived/customlobbyrestrictionsderivedmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

-- taller rows than a plain text list so each restriction's preset icon reads clearly
local RowHeight = 34
local IconSize = 26
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
            LazyVarDerive(CustomLobbyRestrictionsDerivedModel.GetRestrictionsVar(), function(restrictionsLazy)
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

    --- Rebuilds the list of active restrictions (icon + name) from the derived model.
    ---@param self UICustomLobbyUnitsPanel
    Refresh = function(self)
        local restrictions = CustomLobbyRestrictionsDerivedModel.GetRestrictions()
        local items = restrictions.Items

        self.Grid:DeleteAndDestroyAll(true)

        if restrictions.Count == 0 then
            self.Empty:Show()
            self:UpdateScrollbar()
            return
        end
        self.Empty:Hide()

        self.Grid:AppendCols(1, true)
        self.Grid:AppendRows(restrictions.Count, true)
        for row, item in items do
            self.Grid:SetItem(self:CreateRow(item), 1, row, true)
        end
        self.Grid:EndBatch()
        self:UpdateScrollbar()
    end,

    --- Builds one read-only row: the restriction's preset icon + name (the icon's tooltip is the
    --- preset's description). Private.
    ---@param self UICustomLobbyUnitsPanel
    ---@param item UICustomLobbyRestriction
    ---@return Group
    CreateRow = function(self, item)
        local row = Group(self.Grid)
        LayoutHelpers.SetDimensions(row, 10, RowHeight)
        row.Width:Set(function() return self.Grid.Width() end)

        local labelLeft = 4
        if item.Icon then
            local icon = Bitmap(row)
            icon:SetTexture(item.Icon)
            Layouter(icon):AtLeftIn(row, 4):AtVerticalCenterIn(row):Width(IconSize):Height(IconSize):End()
            if item.Tooltip then
                Tooltip.AddControlTooltipManual(icon, item.Name, item.Tooltip)
            else
                icon:DisableHitTest()
            end
            labelLeft = 4 + IconSize + 8
        end

        local label = UIUtil.CreateText(row, item.Name, 13, UIUtil.bodyFont)
        label:SetColor(LabelColor)
        label:DisableHitTest()
        Layouter(label):AtLeftIn(row, labelLeft):AtVerticalCenterIn(row):End()
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
