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

-- The lobby's right-hand **config panel**: a tab strip (Map / Options / Mods / Units) over a
-- content area. Extracted from CustomLobbyInterface so the interface stays a composition root —
-- this component owns the tabs and self-subscribes to `IsHost` for its host-only buttons (the same
-- "each child subscribes itself" rule the slot rows follow).
--
-- The tabs are a read/launch surface: the **Map** tab shows the live map preview (it is NOT
-- pinned — switching tabs hides it); **Options** / **Mods** / **Units** show a one-line summary and
-- a button into the corresponding popup dialog. Editing happens in those dialogs; only the host's
-- buttons (change map / options / reset) are shown to the host.
--
-- Laid out by its parent (filled into the lobby's right column); internally it splits into a tab
-- strip area + a content area — flip the module `Debug` flag to tint them.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
local CustomLobbyMapSelect = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapselect.lua")
local CustomLobbyModSelect = import("/lua/ui/lobby/customlobby/modselect/customlobbymodselect.lua")
local CustomLobbyOptionSelect = import("/lua/ui/lobby/customlobby/optionselect/customlobbyoptionselect.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint the tab strip / content areas while iterating
local Debug = false

local TabHeight = 28
local TabWidth = 88
local PreviewWidth = 320
local PreviewHeight = 300

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

---@class UICustomLobbyTab
---@field Button Group
---@field Panel Group

---@class UICustomLobbyConfigInterface : Group
---@field Trash TrashBag
---@field TabStripArea Group
---@field TabContentArea Group
---@field Tabs UICustomLobbyTab[]
---@field ActiveTab number
---@field MapPanel Group
---@field MapPreview UICustomLobbyMapPreview
---@field MapButton Button
---@field OptionsPanel Group
---@field OptionsInfo Text
---@field EditOptionsButton Button
---@field ResetOptionsButton Button
---@field ModsPanel Group
---@field ModsInfo Text
---@field ModsButton Button
---@field UnitsPanel Group
---@field UnitsInfo Text
---@field IsHost boolean
---@field IsHostObserver LazyVar
local CustomLobbyConfigInterface = ClassUI(Group) {

    ---@param self UICustomLobbyConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyConfigInterface")

        self.Trash = TrashBag()
        self.IsHost = false
        self.ActiveTab = TabMap

        self.TabStripArea = CreateArea(self, "TabStripArea", 'ffcc8040')
        self.TabContentArea = CreateArea(self, "TabContentArea", 'ff8040cc')

        self:BuildTabs()

        local localModel = CustomLobbyLocalModel.GetSingleton()
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(localModel.IsHost, function(isHostLazy)
                self:OnIsHostChanged(isHostLazy())
            end))
    end,

    ---@param self UICustomLobbyConfigInterface
    __post_init = function(self)
        Layouter(self.TabStripArea):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(TabHeight):End()
        Layouter(self.TabContentArea)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.TabStripArea, 6):AtBottomIn(self)
            :End()

        self:LayoutTabs()
        self:SelectTab(self.ActiveTab)
    end,

    ---------------------------------------------------------------------------
    --#region Tabs

    --- Builds the four tabs (buttons + content panels). Private.
    ---@param self UICustomLobbyConfigInterface
    BuildTabs = function(self)
        --#region map tab
        self.MapPanel = Group(self.TabContentArea, "CustomLobbyMapPanel")
        self.MapPreview = CustomLobbyMapPreview.Create(self.MapPanel)
        self.MapButton = UIUtil.CreateButtonWithDropshadow(self.MapPanel, '/BUTTON/medium/', "Change map")
        self.MapButton.OnClick = function(button, modifiers)
            CustomLobbyMapSelect.Open(GetFrame(0))
        end
        --#endregion

        --#region options tab
        self.OptionsPanel = Group(self.TabContentArea, "CustomLobbyOptionsPanel")
        self.OptionsInfo = UIUtil.CreateText(self.OptionsPanel, "Game, scenario and mod options.", 14, UIUtil.bodyFont)
        self.OptionsInfo:SetColor('ffc8ccd0')
        self.OptionsInfo:DisableHitTest()
        self.EditOptionsButton = UIUtil.CreateButtonWithDropshadow(self.OptionsPanel, '/BUTTON/medium/', "Options")
        self.EditOptionsButton.OnClick = function(button, modifiers)
            CustomLobbyOptionSelect.Open(GetFrame(0))
        end
        self.ResetOptionsButton = UIUtil.CreateButtonWithDropshadow(self.OptionsPanel, '/BUTTON/medium/', "Reset options")
        self.ResetOptionsButton.OnClick = function(button, modifiers)
            CustomLobbyController.RequestResetGameOptions()
        end
        Tooltip.AddControlTooltipManual(self.ResetOptionsButton, "Reset options", "Reset every option to its default value.")
        --#endregion

        --#region mods tab
        self.ModsPanel = Group(self.TabContentArea, "CustomLobbyModsPanel")
        self.ModsInfo = UIUtil.CreateText(self.ModsPanel, "Sim mods are shared; UI mods are yours.", 14, UIUtil.bodyFont)
        self.ModsInfo:SetColor('ffc8ccd0')
        self.ModsInfo:DisableHitTest()
        self.ModsButton = UIUtil.CreateButtonWithDropshadow(self.ModsPanel, '/BUTTON/medium/', "Manage mods")
        self.ModsButton.OnClick = function(button, modifiers)
            CustomLobbyModSelect.Open(GetFrame(0))
        end
        --#endregion

        --#region units tab
        self.UnitsPanel = Group(self.TabContentArea, "CustomLobbyUnitsPanel")
        self.UnitsInfo = UIUtil.CreateText(self.UnitsPanel, "Unit restrictions — coming soon.", 14, UIUtil.bodyFont)
        self.UnitsInfo:SetColor('ff8a909a')
        self.UnitsInfo:DisableHitTest()
        --#endregion

        self.Tabs = {
            [TabMap]     = { Button = self:CreateTabButton("Map", TabMap),         Panel = self.MapPanel },
            [TabOptions] = { Button = self:CreateTabButton("Options", TabOptions),  Panel = self.OptionsPanel },
            [TabMods]    = { Button = self:CreateTabButton("Mods", TabMods),        Panel = self.ModsPanel },
            [TabUnits]   = { Button = self:CreateTabButton("Units", TabUnits),      Panel = self.UnitsPanel },
        }
    end,

    --- Builds one clickable tab button (a tinted group + label). Private.
    ---@param self UICustomLobbyConfigInterface
    ---@param label string
    ---@param index number
    ---@return Group
    CreateTabButton = function(self, label, index)
        local tab = Group(self.TabStripArea, "CustomLobbyTab")

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

    --- Lays out the tab buttons across the strip + fills each content panel. Private.
    ---@param self UICustomLobbyConfigInterface
    LayoutTabs = function(self)
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
        end

        -- map tab content
        Layouter(self.MapPreview)
            :AtHorizontalCenterIn(self.MapPanel):AtTopIn(self.MapPanel, 8)
            :Width(PreviewWidth):Height(PreviewHeight)
            :End()
        Layouter(self.MapButton):AtHorizontalCenterIn(self.MapPanel):AnchorToBottom(self.MapPreview, 12):End()

        -- options tab content
        Layouter(self.OptionsInfo):AtHorizontalCenterIn(self.OptionsPanel):AtTopIn(self.OptionsPanel, 16):End()
        Layouter(self.EditOptionsButton):AtHorizontalCenterIn(self.OptionsPanel):AnchorToBottom(self.OptionsInfo, 16):End()
        Layouter(self.ResetOptionsButton):AtHorizontalCenterIn(self.OptionsPanel):AnchorToBottom(self.EditOptionsButton, 10):End()

        -- mods tab content
        Layouter(self.ModsInfo):AtHorizontalCenterIn(self.ModsPanel):AtTopIn(self.ModsPanel, 16):End()
        Layouter(self.ModsButton):AtHorizontalCenterIn(self.ModsPanel):AnchorToBottom(self.ModsInfo, 16):End()

        -- units tab content
        Layouter(self.UnitsInfo):AtHorizontalCenterIn(self.UnitsPanel):AtTopIn(self.UnitsPanel, 16):End()
    end,

    --- Shows the selected tab's panel, hides the rest, recolours the buttons, and re-applies the
    --- host-only button visibility (a panel `Show()` cascades to its children, so host-gated
    --- buttons must be re-hidden after).
    ---@param self UICustomLobbyConfigInterface
    ---@param index number
    SelectTab = function(self, index)
        self.ActiveTab = index
        for i = 1, table.getn(self.Tabs) do
            local tab = self.Tabs[i]
            if i == index then
                tab.Button.Bg:SetSolidColor(TabActiveColor)
                tab.Panel:Show()
            else
                tab.Button.Bg:SetSolidColor(TabIdleColor)
                tab.Panel:Hide()
            end
        end
        self:ApplyHostVisibility()
    end,

    --#endregion

    --- Tracks host status and re-applies the host-only button visibility.
    ---@param self UICustomLobbyConfigInterface
    ---@param isHost boolean
    OnIsHostChanged = function(self, isHost)
        self.IsHost = isHost
        self:ApplyHostVisibility()
    end,

    --- Host-only buttons (change map / edit + reset options) are shown only to the host. Called
    --- after both an is-host change and a tab switch (a panel Show() cascades visibility).
    ---@param self UICustomLobbyConfigInterface
    ApplyHostVisibility = function(self)
        local show = self.IsHost
        for _, button in { self.MapButton, self.EditOptionsButton, self.ResetOptionsButton } do
            if show then
                button:Show()
            else
                button:Hide()
            end
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
