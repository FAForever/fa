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

-- The lobby's right column: the map preview pinned on top, three tabs below —
--
--   ┌ map preview (square, bound) ─┐
--   │                              │
--   └──────────────────────────────┘
--   Seton's Clutch
--   20km · 8 players · v3
--   [ Options | Mods | Restrictions ]
--   ┌ active tab's panel ──────────┐
--   │ …                            │
--   └──────────────────────────────┘
--
-- The preview is the shared bound `CustomLobbyMapPreview` (subscribes to `ScenarioFile`, renders
-- faction spawns; the engine caches the single current map's texture, so churn is free). It is
-- pinned above the tabs — only the panel below churns on tab switch — with a short name +
-- size/players/version facts line between them. The three tab panels are all read-only: their own
-- per-domain action buttons are gone (the interface's action-bar Settings button opens the options
-- editor); the change-map / mod-select entry points return when the config rework resumes.
--
-- This used to be a four-tab strip including a Map tab; the Map preview is now the pinned header.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
local CustomLobbyTabs = import("/lua/ui/lobby/customlobby/customlobbytabs.lua")
local CustomLobbyOptionsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyoptionspanel.lua")
local CustomLobbyModsPanel = import("/lua/ui/lobby/customlobby/config/customlobbymodspanel.lua")
local CustomLobbyUnitsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyunitspanel.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local Inset = 6
local PreviewMaxSize = 280           -- the square preview grows with the column width, capped here
local NameMaxChars = 30
local FactsColor = 'ff9aa0a8'

--- Truncates `text` to `maxChars`, appending "…" when it had to cut. (Local copy — drift-fine, see
--- ../CLAUDE.md "On sharing".)
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

---@class UICustomLobbyConfigInterface : Group
---@field Trash TrashBag
---@field Preview UICustomLobbyMapPreview
---@field Name Text
---@field Info Text
---@field Tabs UICustomLobbyTabs
---@field ScenarioObserver LazyVar
local CustomLobbyConfigInterface = ClassUI(Group) {

    ---@param self UICustomLobbyConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyConfigInterface")

        self.Trash = TrashBag()

        self.Preview = CustomLobbyMapPreview.Create(self, { Bound = true })

        self.Name = UIUtil.CreateText(self, "", 15, UIUtil.titleFont)
        self.Name:DisableHitTest()
        self.Info = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Info:SetColor(FactsColor)
        self.Info:DisableHitTest()

        -- the read-only config tabs below the preview (created-on-select / destroyed-on-switch)
        self.Tabs = CustomLobbyTabs.Create(self, {
            Tabs = {
                { Label = "Options",      Create = CustomLobbyOptionsPanel.Create },
                { Label = "Mods",         Create = CustomLobbyModsPanel.Create },
                { Label = "Restrictions", Create = CustomLobbyUnitsPanel.Create },
            },
        })

        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().ScenarioFile, function(scenarioFileLazy)
                scenarioFileLazy()
                self:RefreshFacts()
            end))
    end,

    ---@param self UICustomLobbyConfigInterface
    __post_init = function(self)
        -- a centred square preview at the top, capped so it never crowds the tabs out
        Layouter(self.Preview):AtHorizontalCenterIn(self):AtTopIn(self, Inset):End()
        self.Preview.Width:Set(function()
            return math.min(self.Width() - LayoutHelpers.ScaleNumber(2 * Inset), LayoutHelpers.ScaleNumber(PreviewMaxSize))
        end)
        self.Preview.Height:Set(function() return self.Preview.Width() end)

        Layouter(self.Name):AtHorizontalCenterIn(self):AnchorToBottom(self.Preview, 8):End()
        Layouter(self.Info):AtHorizontalCenterIn(self):AnchorToBottom(self.Name, 2):End()

        -- the tabs fill the rest of the column below the facts line
        Layouter(self.Tabs)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.Info, 8):AtBottomIn(self)
            :End()
    end,

    --- Three-phase init: the interface calls this after sizing the column. Forwards to the tabs
    --- container (its first panel's grid needs a concrete height) and renders the first facts line.
    ---@param self UICustomLobbyConfigInterface
    Initialize = function(self)
        self:RefreshFacts()
        self.Tabs:Initialize()
    end,

    --- Renders the map name + the size · players · version facts line for the current scenario.
    ---@param self UICustomLobbyConfigInterface
    RefreshFacts = function(self)
        local scenarioFile = CustomLobbyLaunchModel.GetSingleton().ScenarioFile()
        local info = scenarioFile and CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        if type(info) == "table" then
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
        else
            self.Name:SetText(scenarioFile and "Unknown map" or "No map selected")
            self.Info:SetText("")
        end
    end,

    ---@param self UICustomLobbyConfigInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- Builds the right-column config composition. The parent sizes it and calls `Initialize()` after
--- mounting (three-phase init).
---@param parent Control
---@return UICustomLobbyConfigInterface
Create = function(parent)
    return CustomLobbyConfigInterface(parent)
end
