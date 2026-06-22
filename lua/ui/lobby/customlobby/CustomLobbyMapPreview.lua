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

-- The in-lobby map preview: the shared scenario-preview surface (CustomLobbyScenarioPreview)
-- with the lobby's chrome — a glow border (no dialog brackets; they don't suit a preview this
-- small) — wrapped around it, bound to the
-- launch model.
--
-- It owns the model wiring only: it subscribes to `ScenarioFile` (load the scenario, hand it to
-- the surface, show/hide) and to each slot's player (refresh the surface's spawn data, no map
-- reload). The texture / overlay / positioning work all lives in the surface, which the
-- map-select dialog reuses too — see CustomLobbyScenarioPreview.lua.
--
-- Spawns render as faction icons (CustomLobbyMapPreviewSpawn): the surface calls each icon's
-- :Update(faction) for a seated spot and :Reset() for an empty one, so empty spots stay blank.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local CustomLobbyScenarioPreview = import("/lua/ui/lobby/customlobby/customlobbyscenariopreview.lua")
local CustomLobbyMapPreviewSpawn = import("/lua/ui/lobby/customlobby/customlobbymappreviewspawn.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

---@class UICustomLobbyMapPreview : Group
---@field Trash TrashBag
---@field Overlay Bitmap
---@field Surface UICustomLobbyScenarioPreview
---@field ScenarioObserver LazyVar
---@field PlayerObservers LazyVar[]
local CustomLobbyMapPreview = ClassUI(Group) {

    ---@param self UICustomLobbyMapPreview
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.Trash = TrashBag()

        self.Overlay = UIUtil.CreateBitmap(self, '/scx_menu/gameselect/map-panel-glow_bmp.dds')

        -- the shared surface, with faction icons for spawns
        self.Surface = CustomLobbyScenarioPreview.Create(self, {
            CreateSpawnIcon = function(surface, index)
                return CustomLobbyMapPreviewSpawn.Create(surface)
            end,
        })

        local model = CustomLobbyLaunchModel.GetSingleton()

        -- the scenario file drives the whole preview: render on change, hide when unset
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(model.ScenarioFile, function(scenarioFileLazy)
                self:OnScenarioFileChanged(scenarioFileLazy())
            end))

        -- each slot drives only the spawn icons (faction / position) — refreshed against the
        -- already-loaded scenario, so a take/swap/faction change doesn't reload the map
        self.PlayerObservers = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.PlayerObservers[slot] = self.Trash:Add(
                LazyVarDerive(model.Players[slot], function(playerLazy)
                    playerLazy()
                    self:OnPlayersChanged()
                end))
        end
    end,

    ---@param self UICustomLobbyMapPreview
    __post_init = function(self)
        LayoutHelpers.ReusedLayoutFor(self.Overlay)
            :Fill(self)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Surface)
            :FillFixedBorder(self.Overlay, 24)
            :End()
    end,

    ---@param self UICustomLobbyMapPreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    --- Loads the scenario and hands it to the surface; hides the preview when unset.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioFile FileName | false
    OnScenarioFileChanged = function(self, scenarioFile)
        if not scenarioFile then
            self.Surface:Clear()
            self:Hide()
            return
        end

        local scenarioInfo = CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        if not scenarioInfo then
            self.Surface:Clear()
            self:Hide()
            return
        end

        self.Surface:SetScenario(scenarioInfo, CustomLobbyMapCatalog.LoadSave(scenarioInfo))
        self.Surface:SetSpawnData(self:GatherSpawnData())
        self:Show()
    end,

    --- A slot changed: refresh the surface's spawn data (faction by start spot).
    ---@param self UICustomLobbyMapPreview
    OnPlayersChanged = function(self)
        self.Surface:SetSpawnData(self:GatherSpawnData())
    end,

    --- The seated factions keyed by start spot (the spawn id the surface positions by).
    ---@param self UICustomLobbyMapPreview
    ---@return table<number, number>
    GatherSpawnData = function(self)
        local model = CustomLobbyLaunchModel.GetSingleton()
        local data = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local player = model.Players[slot]()
            if player then
                data[player.StartSpot or slot] = player.Faction
            end
        end
        return data
    end,
}

---@param parent Control
---@return UICustomLobbyMapPreview
Create = function(parent)
    return CustomLobbyMapPreview(parent)
end
