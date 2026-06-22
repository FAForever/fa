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

-- The Map tab panel of the config interface: the live map preview + the scenario's name and
-- size/players, and a host-only "Change map" button.
--
-- It is one of the config interface's tab panels (see CustomLobbyConfigInterface). The host drives
-- it through `SetActive` — a panel only shows + refreshes while it's the active tab, and stays
-- hidden otherwise, which is what keeps a hidden tab's content from rendering over the active one
-- (MAUI's `Hide()` only cascades to children that exist at call time). `Initialize` exists for
-- uniformity with the grid panels (this one has nothing deferred).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyMapSelect = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapselect.lua")

local Group = import("/lua/maui/group.lua").Group
local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local PreviewWidth = 320
local PreviewHeight = 280
local ValueColor = 'ff9aa0a8'

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

---@class UICustomLobbyMapPanel : Group
---@field Trash TrashBag
---@field Active boolean
---@field IsHost boolean
---@field Preview UICustomLobbyMapPreview
---@field Name Text
---@field Info Text
---@field ChangeButton Button
---@field ScenarioObserver LazyVar
---@field IsHostObserver LazyVar
local CustomLobbyMapPanel = ClassUI(Group) {

    ---@param self UICustomLobbyMapPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyMapPanel")

        self.Trash = TrashBag()
        self.Active = false
        self.IsHost = false

        self.Preview = CustomLobbyMapPreview.Create(self)

        self.Name = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        self.Name:DisableHitTest()
        self.Info = UIUtil.CreateText(self, "", 13, UIUtil.bodyFont)
        self.Info:SetColor(ValueColor)
        self.Info:DisableHitTest()

        self.ChangeButton = UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Change map")
        self.ChangeButton.OnClick = function(button, modifiers)
            CustomLobbyMapSelect.Open(GetFrame(0))
        end

        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(launch.ScenarioFile, function(scenarioFileLazy)
                scenarioFileLazy()
                self:Refresh()
                -- the preview self-updates from the model; if we're hidden, re-hide so its newly
                -- built markers don't render over the active tab
                if not self.Active then
                    self:Hide()
                end
            end))

        local localModel = CustomLobbyLocalModel.GetSingleton()
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(localModel.IsHost, function(isHostLazy)
                self.IsHost = isHostLazy()
                self:ApplyHostVisibility()
                if not self.Active then
                    self:Hide()
                end
            end))
    end,

    ---@param self UICustomLobbyMapPanel
    __post_init = function(self)
        Layouter(self.Preview)
            :AtHorizontalCenterIn(self):AtTopIn(self, 8)
            :Width(PreviewWidth):Height(PreviewHeight)
            :End()
        Layouter(self.Name):AtHorizontalCenterIn(self):AnchorToBottom(self.Preview, 8):End()
        Layouter(self.Info):AtHorizontalCenterIn(self):AnchorToBottom(self.Name, 4):End()
        Layouter(self.ChangeButton):AtHorizontalCenterIn(self):AtBottomIn(self, 6):End()
    end,

    --- No deferred work (no grid); kept for a uniform panel interface.
    ---@param self UICustomLobbyMapPanel
    Initialize = function(self)
    end,

    --- Shows + refreshes the panel when it becomes the active tab; hides it otherwise.
    ---@param self UICustomLobbyMapPanel
    ---@param active boolean
    SetActive = function(self, active)
        self.Active = active
        if active then
            self:Show()
            self:Refresh()
            self:ApplyHostVisibility()
        else
            self:Hide()
        end
    end,

    --- Updates the name + size/players line from the current scenario.
    ---@param self UICustomLobbyMapPanel
    Refresh = function(self)
        local scenarioFile = CustomLobbyLaunchModel.GetSingleton().ScenarioFile()
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
        self.Name:SetText(LOC(info.name) or "?")

        local parts = {}
        if info.size then
            table.insert(parts, string.format("%dkm", math.floor(info.size[1] / 50)))
        end
        local players = ArmyCount(info)
        if players > 0 then
            table.insert(parts, players .. " players")
        end
        self.Info:SetText(table.concat(parts, "   ·   "))
    end,

    --- The change-map button is host-only.
    ---@param self UICustomLobbyMapPanel
    ApplyHostVisibility = function(self)
        if self.IsHost then
            self.ChangeButton:Show()
        else
            self.ChangeButton:Hide()
        end
    end,

    ---@param self UICustomLobbyMapPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyMapPanel
Create = function(parent)
    return CustomLobbyMapPanel(parent)
end
