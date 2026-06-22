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

-- Map preview for the custom lobby. Copied from the autolobby's AutolobbyMapPreview and
-- adapted to this lobby's model: the autolobby observes one `Scenario` bundle, but here
-- the scenario file and the players live separately (`ScenarioFile` + per-slot `Players`),
-- so we observe the file (full re-render) and each slot (cheap spawn-icon refresh against
-- the cached scenario). The rendering itself (preview texture, resource markers, spawn
-- icons) is unchanged from the autolobby and uses the shared MapPreview control.

local UIUtil = import("/lua/ui/uiutil.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local CustomLobbyMapPreviewSpawn = import("/lua/ui/lobby/customlobby/customlobbymappreviewspawn.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

---@class UICustomLobbyMapPreview : Group
---@field Trash TrashBag
---@field Ready boolean         # true once laid out by the parent; gates geometry-reading renders
---@field Preview MapPreview
---@field Overlay Bitmap
---@field PathToScenarioFile? FileName
---@field ScenarioInfo? UILobbyScenarioInfo
---@field ScenarioSave? UIScenarioSaveFile
---@field PlayerOptions? table<number, UICustomLobbyPlayer>
---@field EnergyIcon Bitmap     # Acts as a pool
---@field MassIcon Bitmap       # Acts as a pool
---@field WreckageIcon Bitmap   # Acts as a pool
---@field IconTrash TrashBag    # Trashbag that contains all icons
---@field SpawnIcons UICustomLobbyMapPreviewSpawn[]
---@field ScenarioObserver LazyVar
---@field PlayerObservers LazyVar[]
local CustomLobbyMapPreview = ClassUI(Group) {

    ---@param self UICustomLobbyMapPreview
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.Trash = TrashBag()

        self.Preview = MapPreview(self)

        self.Overlay = UIUtil.CreateBitmap(self, '/scx_menu/gameselect/map-panel-glow_bmp.dds')

        self.EnergyIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-energy_bmp.dds")
        self.MassIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-mass_bmp.dds")
        self.WreckageIcon = UIUtil.CreateBitmap(self, "/scx_menu/lan-game-lobby/mappreview/wreckage.dds")
        self.SpawnIcons = {}

        UIUtil.CreateDialogBrackets(self, 30, 24, 30, 24)

        self.IconTrash = TrashBag()

        -- Geometry-reading renders (spawn-icon placement reads self.Preview.Width()) are gated
        -- until we've been laid out by our parent — see __post_init. The Derive observers below
        -- fire immediately on creation; without this gate, a reload with a scenario already set
        -- would position icons against a not-yet-sized preview and trip the circular guard.
        self.Ready = false

        local model = CustomLobbyLaunchModel.GetSingleton()

        -- the scenario file drives the whole preview: render on change, hide when unset
        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(model.ScenarioFile, function(scenarioFileLazy)
                local scenarioFile = scenarioFileLazy()
                if self.Ready then
                    self:OnScenarioFileChanged(scenarioFile)
                end
            end))

        -- each slot drives only the spawn icons (faction / position) — refreshed against
        -- the already-loaded scenario, so a take/swap/faction change doesn't reload the map
        self.PlayerObservers = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.PlayerObservers[slot] = self.Trash:Add(
                LazyVarDerive(model.Players[slot], function(playerLazy)
                    playerLazy()
                    if self.Ready then
                        self:OnPlayersChanged()
                    end
                end))
        end
    end,

    ---@param self UICustomLobbyMapPreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    --- Show + render the preview once a scenario file is set, hide it otherwise.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioFile FileName | false
    OnScenarioFileChanged = function(self, scenarioFile)
        if scenarioFile then
            self:Show()
            self:UpdateScenario(scenarioFile, self:_GatherPlayerOptions())
        else
            self:Hide()
        end
    end,

    --- A slot changed: refresh just the spawn icons, reusing the loaded scenario.
    ---@param self UICustomLobbyMapPreview
    OnPlayersChanged = function(self)
        if self.ScenarioInfo and self.ScenarioSave then
            self.PlayerOptions = self:_GatherPlayerOptions()
            self:_UpdateSpawnLocations(self.ScenarioInfo, self.ScenarioSave, self.PlayerOptions)
        end
    end,

    --- Collects the seated players keyed by start spot (the spawn id the preview uses).
    ---@param self UICustomLobbyMapPreview
    ---@return table<number, UICustomLobbyPlayer>
    _GatherPlayerOptions = function(self)
        local model = CustomLobbyLaunchModel.GetSingleton()
        local options = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local player = model.Players[slot]()
            if player then
                options[player.StartSpot or slot] = player
            end
        end
        return options
    end,

    ---@param self UICustomLobbyMapPreview
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self.Overlay)
            :Fill(self)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Preview)
            :FillFixedBorder(self.Overlay, 24)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.EnergyIcon):Hide():End()
        LayoutHelpers.ReusedLayoutFor(self.MassIcon):Hide():End()
        LayoutHelpers.ReusedLayoutFor(self.WreckageIcon):Hide():End()

        -- our PARENT lays us out after this __post_init returns, so self.Preview.Width() isn't
        -- concrete yet. Defer the first render one frame, then mark ready so the observers drive
        -- subsequent updates. (Without this, a reload with a scenario already set renders here —
        -- against an unsized preview — and trips the circular-dependency guard.)
        self.Trash:Add(ForkThread(
            function()
                WaitFrames(1)
                if IsDestroyed(self) then
                    return
                end
                self.Ready = true
                self:OnScenarioFileChanged(CustomLobbyLaunchModel.GetSingleton().ScenarioFile())
            end
        ))
    end,

    --- Places an icon at a map coordinate. Private.
    ---@param self UICustomLobbyMapPreview
    ---@param icon Control
    ---@param scenarioWidth number
    ---@param scenarioHeight number
    ---@param px number
    ---@param pz number
    PositionIcon = function(self, icon, scenarioWidth, scenarioHeight, px, pz)
        local size = self.Preview.Width()
        local xOffset = 0
        local xFactor = 1
        local yOffset = 0
        local yFactor = 1
        if scenarioWidth > scenarioHeight then
            local ratio = scenarioHeight / scenarioWidth
            yOffset = ((size / ratio) - size) / 4
            yFactor = ratio
        else
            local ratio = scenarioWidth / scenarioHeight
            xOffset = ((size / ratio) - size) / 4
            xFactor = ratio
        end

        local x = xOffset + (px / scenarioWidth) * (size - 2) * xFactor
        local z = yOffset + (pz / scenarioHeight) * (size - 2) * yFactor

        icon.Left:Set(function() return self.Preview.Left() + x - 0.5 * icon.Width() end)
        icon.Top:Set(function() return self.Preview.Top() + z - 0.5 * icon.Height() end)

        return icon
    end,

    --- Sets the preview texture. Private.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    _UpdatePreview = function(self, scenarioInfo)
        if not self.Preview:SetTexture(scenarioInfo.preview) then
            self.Preview:SetTextureFromMap(scenarioInfo.map)
        end
    end,

    --- Creates icons for resource markers. Private.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@param scenarioSave UIScenarioSaveFile
    _UpdateMarkers = function(self, scenarioInfo, scenarioSave)
        local scenarioWidth = scenarioInfo.size[1]
        local scenarioHeight = scenarioInfo.size[2]

        local allmarkers = scenarioSave.MasterChain['_MASTERCHAIN_'].Markers
        if not allmarkers then
            return
        end

        for _, marker in allmarkers do
            if marker['type'] == "Mass" then
                ---@type Bitmap
                local icon = LayoutHelpers.ReusedLayoutFor(self.IconTrash:Add(UIUtil.CreateBitmapColor(self, 'ffffff')))
                    :Width(12)
                    :Height(12)
                    :End()

                icon:ShareTextures(self.MassIcon)
                self:PositionIcon(
                    icon, scenarioWidth, scenarioHeight,
                    marker.position[1], marker.position[3]
                )

            elseif marker['type'] == "Hydrocarbon" then
                ---@type Bitmap
                local icon = LayoutHelpers.ReusedLayoutFor(self.IconTrash:Add(UIUtil.CreateBitmapColor(self, 'ffffff')))
                    :Width(12)
                    :Height(12)
                    :End()
                icon:ShareTextures(self.EnergyIcon)
                self:PositionIcon(
                    icon, scenarioWidth, scenarioHeight,
                    marker.position[1], marker.position[3]
                )
            end
        end
    end,

    --- Creates icons for wreckages. Private.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@param scenarioSave UIScenarioSaveFile
    _UpdateWreckages = function(self, scenarioInfo, scenarioSave)
        -- TODO
    end,

    --- Creates/updates spawn-location icons. Private.
    ---@param self UICustomLobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@param scenarioSave UIScenarioSaveFile
    ---@param playerOptions table<number, UICustomLobbyPlayer>
    _UpdateSpawnLocations = function(self, scenarioInfo, scenarioSave, playerOptions)
        local spawnIcons = self.SpawnIcons
        local positions = MapUtil.GetStartPositionsFromScenario(scenarioInfo, scenarioSave)
        if not positions then
            for id, icon in spawnIcons do
                icon:Destroy()
            end
            return
        end

        -- clean up icons whose position no longer exists
        for id, icon in spawnIcons do
            if not positions[id] then
                icon:Destroy()
            end
        end

        for id, position in positions do
            local icon = spawnIcons[id]
            if not icon then
                icon = CustomLobbyMapPreviewSpawn.Create(self)
            end

            spawnIcons[id] = icon

            self:PositionIcon(
                icon, scenarioInfo.size[1], scenarioInfo.size[2],
                position[1], position[2]
            )

            local options = playerOptions[id]
            if options then
                icon:Update(options.Faction)
            else
                icon:Reset()
            end
        end
    end,

    --- Renders the preview for a scenario, including resource and spawn icons.
    ---@param self UICustomLobbyMapPreview
    ---@param pathToScenarioInfo FileName   # a reference to a _scenario.lua file
    ---@param playerOptions table<number, UICustomLobbyPlayer>
    UpdateScenario = function(self, pathToScenarioInfo, playerOptions)
        self.IconTrash:Destroy()
        self.Preview:ClearTexture()
        self.PathToScenarioFile = pathToScenarioInfo

        local scenarioInfo = MapUtil.LoadScenario(pathToScenarioInfo)
        if not scenarioInfo then
            -- TODO: show a default image that indicates something is off
            self.ScenarioInfo = nil
            self.ScenarioSave = nil
            return
        end

        self.ScenarioInfo = scenarioInfo
        self:_UpdatePreview(scenarioInfo)

        local scenarioSave = MapUtil.LoadScenarioSaveFile(scenarioInfo.save)
        if not scenarioSave then
            self.ScenarioSave = nil
            return
        end

        self.ScenarioSave = scenarioSave
        self:_UpdateMarkers(scenarioInfo, scenarioSave)
        self:_UpdateWreckages(scenarioInfo, scenarioSave)

        self.PlayerOptions = playerOptions
        self:_UpdateSpawnLocations(scenarioInfo, scenarioSave, playerOptions)
    end,

    ---------------------------------------------------------------------------
    --#region Engine hooks

    ---@param self UICustomLobbyMapPreview
    Show = function(self)
        Group.Show(self)

        -- do not show the pooled icons
        self.EnergyIcon:Hide()
        self.MassIcon:Hide()
        self.WreckageIcon:Hide()
    end,

    --#endregion
}

---@param parent Control
---@return UICustomLobbyMapPreview
Create = function(parent)
    return CustomLobbyMapPreview(parent)
end
