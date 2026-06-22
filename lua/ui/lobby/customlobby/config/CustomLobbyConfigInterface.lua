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

-- The lobby's right-hand config panel:
--
--   ┌───────────────────────────┐
--   │      map preview          │  ← pinned, persistent
--   │   Name   ·   20km · 8p     │
--   ├───────────────────────────┤
--   │ Map | Options | Mods | Un │  ← tab strip
--   ├───────────────────────────┤
--   │   active tab's content    │  ← created on select, destroyed on switch
--   └───────────────────────────┘
--
-- The **map block is pinned** at the top — the preview plus the scenario name, size and player
-- count — and built exactly once: the engine never frees the textures the preview loads (see
-- mapselect/CLAUDE.md), so it must NOT be destroyed/recreated. Everything below is a **tab** whose
-- content component (CustomLobby*Panel in this folder) is **created when its tab is selected and
-- destroyed when you switch away** — only one tab panel exists at a time. Their content is
-- text/grids (no leaking textures), so churning them is cheap, and because only the live panel
-- exists there's no hidden-panel bleed to manage.
--
-- Laid out by its parent (filled into the lobby's right column); flip the module `Debug` flag to
-- tint the areas.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyMapPanel = import("/lua/ui/lobby/customlobby/config/customlobbymappanel.lua")
local CustomLobbyOptionsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyoptionspanel.lua")
local CustomLobbyModsPanel = import("/lua/ui/lobby/customlobby/config/customlobbymodspanel.lua")
local CustomLobbyUnitsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyunitspanel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint the areas while iterating
local Debug = true

local PreviewSize = 225                          -- the preview is square (FAF maps are square)
local PreviewBlockHeight = PreviewSize + 46      -- preview + name + size/players line
local TabHeight = 28
local TabWidth = 88
local NameMaxChars = 32

local TabIdleColor = 'ff141a20'
local TabHoverColor = 'ff1f262e'
local TabActiveColor = 'ff2c3e48'

-- the four tabs, in order, each with the factory that builds its content component on demand
local Tabs = {
    { Label = "Map",     Create = CustomLobbyMapPanel.Create },
    { Label = "Options", Create = CustomLobbyOptionsPanel.Create },
    { Label = "Mods",    Create = CustomLobbyModsPanel.Create },
    { Label = "Units",   Create = CustomLobbyUnitsPanel.Create },
}

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

--- Number of start spots a scenario declares, or 0.
---@param scenario UILobbyScenarioInfo
---@return number
local function ArmyCount(scenario)
    local armies = scenario.Configurations
        and scenario.Configurations.standard
        and scenario.Configurations.standard.teams
        and scenario.Configurations.standard.teams[1]
        and scenario.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
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
    area.Bg = bg
    return area
end

---@class UICustomLobbyConfigInterface : Group
---@field Trash TrashBag
---@field PreviewArea Group
---@field Preview UICustomLobbyMapPreview
---@field Name Text
---@field Info Text
---@field TabStripArea Group
---@field TabContentArea Group
---@field TabButtons Group[]
---@field ActiveTab number
---@field CurrentPanel Control | false   # the live tab content component (others are destroyed)
---@field ScenarioObserver LazyVar
local CustomLobbyConfigInterface = ClassUI(Group) {

    ---@param self UICustomLobbyConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyConfigInterface")

        self.Trash = TrashBag()
        self.ActiveTab = 1
        self.CurrentPanel = false

        self.PreviewArea = CreateArea(self, "PreviewArea", 'ffcc40cc')
        self.TabStripArea = CreateArea(self, "TabStripArea", 'ffcc8040')
        self.TabContentArea = CreateArea(self, "TabContentArea", 'ff8040cc')

        -- pinned, persistent map block — never destroyed (the preview's textures aren't freed)
        self.Preview = CustomLobbyMapPreview.Create(self.PreviewArea)
        self.Name = UIUtil.CreateText(self.PreviewArea, "", 16, UIUtil.titleFont)
        self.Name:DisableHitTest()
        self.Info = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.Info:SetColor('ff9aa0a8')
        self.Info:DisableHitTest()

        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().ScenarioFile, function(scenarioFileLazy)
                self:RefreshMapInfo(scenarioFileLazy())
            end))

        self.TabButtons = {}
        for index = 1, table.getn(Tabs) do
            self.TabButtons[index] = self:CreateTabButton(Tabs[index].Label, index)
        end
    end,

    ---@param self UICustomLobbyConfigInterface
    __post_init = function(self)
        Layouter(self.PreviewArea):AtLeftIn(self):AtRightIn(self):AtTopIn(self):Height(PreviewBlockHeight):End()
        Layouter(self.TabStripArea):AtLeftIn(self):AtRightIn(self):AnchorToBottom(self.PreviewArea, 8):Height(TabHeight):End()
        Layouter(self.TabContentArea)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.TabStripArea, 6):AtBottomIn(self)
            :End()

        Layouter(self.Preview)
            :AtHorizontalCenterIn(self.PreviewArea):AtTopIn(self.PreviewArea, 4)
            :Width(PreviewSize):Height(PreviewSize)
            :End()
        Layouter(self.Name):AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.Preview, 6):End()
        Layouter(self.Info):AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.Name, 2):End()

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

    --- Opens the initial tab. Called by the parent after it has laid this component out — the tab
    --- content (grids) needs a concrete height, which it now has.
    ---@param self UICustomLobbyConfigInterface
    Initialize = function(self)
        self:RefreshMapInfo(CustomLobbyLaunchModel.GetSingleton().ScenarioFile())
        self:SelectTab(self.ActiveTab)
    end,

    --- Updates the pinned name + size/players line (the preview self-updates from the model).
    ---@param self UICustomLobbyConfigInterface
    ---@param scenarioFile FileName | false
    RefreshMapInfo = function(self, scenarioFile)
        if not scenarioFile then
            self.Name:SetText("No map selected")
            self.Info:SetText("")
            return
        end
        local info = CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        if not info then
            self.Name:SetText("Unknown map")
            self.Info:SetText("")
            return
        end
        self.Name:SetText(Truncate(LOC(info.name) or "?", NameMaxChars))

        local parts = {}
        if info.size then
            table.insert(parts, string.format("%dkm", math.floor(info.size[1] / 50)))
        end
        local players = ArmyCount(info)
        if players > 0 then
            table.insert(parts, players .. " players")
        end
        if info.map_version then
            table.insert(parts, "v" .. tostring(info.map_version))
        end
        self.Info:SetText(table.concat(parts, "   ·   "))
    end,

    --- Builds one clickable tab button (a tinted group + label). Private.
    ---@param self UICustomLobbyConfigInterface
    ---@param label string
    ---@param index number
    ---@return Group
    CreateTabButton = function(self, label, index)
        local button = Group(self.TabStripArea, "CustomLobbyConfigTabButton")

        -- the background catches the click; the label is hit-disabled so it doesn't block it
        button.Bg = Bitmap(button)
        button.Bg:SetSolidColor(TabIdleColor)

        button.Label = UIUtil.CreateText(button, label, 14, UIUtil.titleFont)
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

    --- Switches tabs: destroys the current content component, builds the chosen one into the
    --- content area, and recolours the buttons. Clicking the active tab again is a no-op.
    ---@param self UICustomLobbyConfigInterface
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

        -- build the new tab's content, size it, then let it read its (now concrete) geometry
        local panel = Tabs[index].Create(self.TabContentArea)
        Layouter(panel):Fill(self.TabContentArea):End()
        panel:Initialize()
        self.CurrentPanel = panel
    end,

    ---@param self UICustomLobbyConfigInterface
    OnDestroy = function(self)
        if self.CurrentPanel then
            self.CurrentPanel:Destroy()
            self.CurrentPanel = false
        end
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyConfigInterface
Create = function(parent)
    return CustomLobbyConfigInterface(parent)
end
