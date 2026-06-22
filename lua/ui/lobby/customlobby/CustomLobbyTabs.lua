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

-- A generic tabbed panel: a strip of tab buttons over a content area. The active tab's content
-- component is **created when its tab is selected and destroyed when you switch away** — only one
-- panel is alive at a time, so churn is cheap and there's no hidden-panel bleed (the same model the
-- config interface uses).
--
-- Construct with a tab list `{ { Label = "Chat", Create = fn }, … }`, where `Create(parent)` builds
-- the content component (which may expose an `Initialize()` the container calls after sizing it).
-- An optional `OnSelect(index, label)` fires on every switch — used when a persistent sibling (e.g.
-- the map preview, which can't be churned) must be shown/hidden alongside a tab.
--
-- The parent sizes this control and calls `Initialize()` after mounting (so the first panel reads a
-- concrete height — three-phase init, /lua/ui/CLAUDE.md § 1).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local Layouter = LayoutHelpers.ReusedLayoutFor

local TabHeight = 26
local TabWidth = 92

local TabIdleColor = 'ff141a20'
local TabHoverColor = 'ff1f262e'
local TabActiveColor = 'ff2c3e48'

---@class UICustomLobbyTabsOptions
---@field Tabs { Label: string, Create: fun(parent: Control): Control }[]
---@field OnSelect? fun(index: number, label: string)

---@class UICustomLobbyTabs : Group
---@field Trash TrashBag
---@field Tabs { Label: string, Create: fun(parent: Control): Control }[]
---@field OnSelectCb? fun(index: number, label: string)
---@field TabStripArea Group
---@field TabContentArea Group
---@field TabButtons Group[]
---@field ActiveTab number
---@field CurrentPanel Control | false
local CustomLobbyTabs = ClassUI(Group) {

    ---@param self UICustomLobbyTabs
    ---@param parent Control
    ---@param options UICustomLobbyTabsOptions
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyTabs")

        self.Trash = TrashBag()
        self.Tabs = options.Tabs
        self.OnSelectCb = options.OnSelect
        self.ActiveTab = 1
        self.CurrentPanel = false

        self.TabStripArea = Group(self, "CustomLobbyTabsStrip")
        self.TabContentArea = Group(self, "CustomLobbyTabsContent")

        self.TabButtons = {}
        for index = 1, table.getn(self.Tabs) do
            self.TabButtons[index] = self:CreateTabButton(self.Tabs[index].Label, index)
        end
    end,

    ---@param self UICustomLobbyTabs
    __post_init = function(self)
        Layouter(self.TabStripArea):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(TabHeight):End()
        Layouter(self.TabContentArea)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.TabStripArea, 6):AtBottomIn(self)
            :End()

        for index = 1, table.getn(self.TabButtons) do
            local button = self.TabButtons[index]
            local builder = Layouter(button):AtTopIn(self.TabStripArea):Width(TabWidth):Height(TabHeight)
            if index == 1 then
                builder:AtLeftIn(self.TabStripArea)
            else
                builder:AnchorToRight(self.TabButtons[index - 1], 2)
            end
            builder:End()
            Layouter(button.Bg):Fill(button):End()
            Layouter(button.Label):AtHorizontalCenterIn(button):AtVerticalCenterIn(button):End()
            button.Bg:SetSolidColor(index == self.ActiveTab and TabActiveColor or TabIdleColor)
        end
    end,

    --- Opens the initial tab. Called by the parent after it has sized this control (the content
    --- needs a concrete height — three-phase init).
    ---@param self UICustomLobbyTabs
    Initialize = function(self)
        self:SelectTab(self.ActiveTab)
    end,

    --- Switches tabs: destroys the current content, builds the chosen one into the content area,
    --- and recolours the buttons. Clicking the active tab again is a no-op.
    ---@param self UICustomLobbyTabs
    ---@param index number
    SelectTab = function(self, index)
        if self.ActiveTab == index and self.CurrentPanel then
            return
        end
        self.ActiveTab = index

        for i = 1, table.getn(self.TabButtons) do
            self.TabButtons[i].Bg:SetSolidColor(i == index and TabActiveColor or TabIdleColor)
        end

        if self.CurrentPanel then
            self.CurrentPanel:Destroy()
            self.CurrentPanel = false
        end

        local panel = self.Tabs[index].Create(self.TabContentArea)
        Layouter(panel):Fill(self.TabContentArea):End()
        if panel.Initialize then
            panel:Initialize()
        end
        self.CurrentPanel = panel

        if self.OnSelectCb then
            self.OnSelectCb(index, self.Tabs[index].Label)
        end
    end,

    --- Builds one clickable tab button (a tinted group + label). Private.
    ---@param self UICustomLobbyTabs
    ---@param label string
    ---@param index number
    ---@return Group
    CreateTabButton = function(self, label, index)
        local button = Group(self.TabStripArea, "CustomLobbyTabButton")

        button.Bg = Bitmap(button)
        button.Bg:SetSolidColor(TabIdleColor)

        button.Label = UIUtil.CreateText(button, label, 13, UIUtil.titleFont)
        button.Label:SetColor('ffc8ccd0')
        button.Label:DisableHitTest()

        button.Bg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                self:SelectTab(index)
                return true
            elseif event.Type == 'MouseEnter' then
                if self.ActiveTab ~= index then
                    button.Bg:SetSolidColor(TabHoverColor)
                end
                return true
            elseif event.Type == 'MouseExit' then
                if self.ActiveTab ~= index then
                    button.Bg:SetSolidColor(TabIdleColor)
                end
                return true
            end
            return false
        end

        return button
    end,

    ---@param self UICustomLobbyTabs
    OnDestroy = function(self)
        if self.CurrentPanel then
            self.CurrentPanel:Destroy()
            self.CurrentPanel = false
        end
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@param options UICustomLobbyTabsOptions
---@return UICustomLobbyTabs
Create = function(parent, options)
    return CustomLobbyTabs(parent, options)
end
