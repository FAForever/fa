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

-- The lobby's right-hand config panel: a tab strip (Map / Options / Mods / Units) over a content
-- area. This is just the **tab host** — each tab's content is its own component in this folder
-- (CustomLobbyMapPanel / OptionsPanel / ModsPanel / UnitsPanel), and each self-subscribes to the
-- model and manages its own host-gating.
--
-- Visibility rule: exactly one panel is active. The host calls `panel:SetActive(isActive)` on a
-- tab switch; a panel only shows + (re)builds its content while active, and stays hidden
-- otherwise. That's what prevents a hidden tab's content from rendering over the active one —
-- MAUI's `Hide()` only cascades the hidden flag to children that exist at call time, so a panel
-- that builds content while hidden would leak; building only-while-active sidesteps it entirely.
--
-- Laid out by its parent (filled into the lobby's right column); internally it splits into a tab
-- strip area + a content area — flip the module `Debug` flag to tint them.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyMapPanel = import("/lua/ui/lobby/customlobby/config/customlobbymappanel.lua")
local CustomLobbyOptionsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyoptionspanel.lua")
local CustomLobbyModsPanel = import("/lua/ui/lobby/customlobby/config/customlobbymodspanel.lua")
local CustomLobbyUnitsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyunitspanel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint the tab strip / content areas while iterating
local Debug = false

local TabHeight = 28
local TabWidth = 88

local TabIdleColor = 'ff141a20'
local TabHoverColor = 'ff1f262e'
local TabActiveColor = 'ff2c3e48'

-- the four tabs, in order
local TabMap = 1
local TabOptions = 2
local TabMods = 3
local TabUnits = 4

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

---@class UICustomLobbyConfigTab
---@field Button Group
---@field Panel Control     # one of the tab-panel components (implements SetActive/Initialize)

---@class UICustomLobbyConfigInterface : Group
---@field Trash TrashBag
---@field TabStripArea Group
---@field TabContentArea Group
---@field Tabs UICustomLobbyConfigTab[]
---@field ActiveTab number
local CustomLobbyConfigInterface = ClassUI(Group) {

    ---@param self UICustomLobbyConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyConfigInterface")

        self.Trash = TrashBag()
        self.ActiveTab = TabMap

        self.TabStripArea = CreateArea(self, "TabStripArea", 'ffcc8040')
        self.TabContentArea = CreateArea(self, "TabContentArea", 'ff8040cc')

        self.Tabs = {
            [TabMap]     = { Button = self:CreateTabButton("Map", TabMap),        Panel = CustomLobbyMapPanel.Create(self.TabContentArea) },
            [TabOptions] = { Button = self:CreateTabButton("Options", TabOptions), Panel = CustomLobbyOptionsPanel.Create(self.TabContentArea) },
            [TabMods]    = { Button = self:CreateTabButton("Mods", TabMods),       Panel = CustomLobbyModsPanel.Create(self.TabContentArea) },
            [TabUnits]   = { Button = self:CreateTabButton("Units", TabUnits),     Panel = CustomLobbyUnitsPanel.Create(self.TabContentArea) },
        }
    end,

    ---@param self UICustomLobbyConfigInterface
    __post_init = function(self)
        Layouter(self.TabStripArea):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(TabHeight):End()
        Layouter(self.TabContentArea)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.TabStripArea, 6):AtBottomIn(self)
            :End()

        for index = 1, table.getn(self.Tabs) do
            local tab = self.Tabs[index]
            local builder = Layouter(tab.Button):AtTopIn(self.TabStripArea):Width(TabWidth):Height(TabHeight)
            if index == 1 then
                builder:AtLeftIn(self.TabStripArea)
            else
                builder:AnchorToRight(self.Tabs[index - 1].Button, 2)
            end
            builder:End()
            Layouter(tab.Button.Bg):Fill(tab.Button):End()
            Layouter(tab.Button.Label):AtHorizontalCenterIn(tab.Button):AtVerticalCenterIn(tab.Button):End()
            Layouter(tab.Panel):Fill(self.TabContentArea):End()

            -- visuals only until the parent calls Initialize; panels build content when activated
            tab.Button.Bg:SetSolidColor(index == self.ActiveTab and TabActiveColor or TabIdleColor)
            tab.Panel:Hide()
        end
    end,

    --- Builds the panels' deferred bits (grids need a concrete height) + activates the first tab.
    --- Called by the parent after it has laid this component out (three-phase init).
    ---@param self UICustomLobbyConfigInterface
    Initialize = function(self)
        for index = 1, table.getn(self.Tabs) do
            self.Tabs[index].Panel:Initialize()
        end
        self:SelectTab(self.ActiveTab)
    end,

    --- Builds one clickable tab button (a tinted group + label). Private.
    ---@param self UICustomLobbyConfigInterface
    ---@param label string
    ---@param index number
    ---@return Group
    CreateTabButton = function(self, label, index)
        local tab = Group(self.TabStripArea, "CustomLobbyConfigTabButton")

        -- the background catches the click; the label is hit-disabled so it doesn't block it
        tab.Bg = Bitmap(tab)
        tab.Bg:SetSolidColor(TabIdleColor)

        tab.Label = UIUtil.CreateText(tab, label, 14, UIUtil.titleFont)
        tab.Label:SetColor('ffc8ccd0')
        tab.Label:DisableHitTest()

        tab.Bg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                self:SelectTab(index)
                return true
            elseif event.Type == 'MouseEnter' then
                if self.ActiveTab ~= index then
                    tab.Bg:SetSolidColor(TabHoverColor)
                end
                return true
            elseif event.Type == 'MouseExit' then
                if self.ActiveTab ~= index then
                    tab.Bg:SetSolidColor(TabIdleColor)
                end
                return true
            end
            return false
        end

        return tab
    end,

    --- Switches tabs: recolours the buttons and activates the chosen panel (which shows + refreshes
    --- itself) while deactivating (hiding) the rest.
    ---@param self UICustomLobbyConfigInterface
    ---@param index number
    SelectTab = function(self, index)
        self.ActiveTab = index
        for i = 1, table.getn(self.Tabs) do
            local tab = self.Tabs[i]
            tab.Button.Bg:SetSolidColor(i == index and TabActiveColor or TabIdleColor)
            tab.Panel:SetActive(i == index)
        end
    end,

    ---@param self UICustomLobbyConfigInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyConfigInterface
Create = function(parent)
    return CustomLobbyConfigInterface(parent)
end
