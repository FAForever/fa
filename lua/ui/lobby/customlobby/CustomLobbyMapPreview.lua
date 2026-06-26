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

-- The map preview, as one whole: the chrome (a glow border + dark backdrop) wrapped around the
-- shared CustomLobbyScenarioPreview surface, plus the faction spawn icon (the local
-- `MapPreviewSpawn`). Both preview consumers use this one component, so they look identical:
--
--   * In the lobby — created with `Bound = true`. It subscribes to the derived scenario model
--     (CustomLobbyScenarioDerivedModel) and renders the resolved scenario automatically (hand info + markers
--     to the surface, show/hide). The model loads + dedups, so a launch-info rebroadcast of the same
--     map doesn't reload; per-slot faction-icon spawns refresh as players take/swap/recolour (no map
--     reload).
--
--   * In the map-select dialog — created unbound (the default). No model wiring, numbered-dot spawns
--     (the surface default); the owner drives the preview itself through `self.Surface`
--     (`SetScenario` / `SetSpawnData` / `SetOverlayVisible` / `Clear`) to show the browse candidate,
--     and anchors its own overlays (name bar, info, …) to `self.Surface` — the inner map rect.
--
-- Layout: this group is the OUTER rect (the glow fills it); the backdrop and the surface are inset
-- by `Padding`, so the map sits within and the glow frames it. The glow renders ON TOP of the map
-- (its depth is lifted above the surface), so the ring overlays the map's edges rather than hiding
-- behind them — the texture's centre is transparent, so the map shows through.
--
-- The texture / overlay / positioning work all lives in the surface — see CustomLobbyScenarioPreview.lua.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyScenarioPreview = import("/lua/ui/lobby/customlobby/customlobbyscenariopreview.lua")
local CustomLobbyScenarioDerivedModel = import("/lua/ui/lobby/customlobby/derived/customlobbyscenarioderivedmodel.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local GlowTexture = '/scx_menu/gameselect/map-panel-glow_bmp.dds'
local BackdropColor = 'ff000000'
local Padding = 14                  -- map inset from the outer edge; the glow ring lives in this margin
local SpawnIconSize = 32

--------------------------------------------------------------------------------------------------
--#region Faction spawn icon

-- A start-position marker: a faction icon placed at a spawn. Faction-only — no lobby coupling.
-- The surface calls `:Update(faction)` for a seated spot and `:Reset()` for an empty one (so empty
-- spots stay blank). Used only when the preview is `Bound`; unbound previews get numbered dots.

---@class UICustomLobbyMapPreviewSpawn : Bitmap
---@field Faction? number
local MapPreviewSpawn = ClassUI(Bitmap) {

    EmptyPath = "/textures/ui/common/dialogs/mapselect02/commander_alpha.dds",
    FactionIconPaths = {
        "/textures/ui/common/faction_icon-lg/uef_med.dds",
        "/textures/ui/common/faction_icon-lg/aeon_med.dds",
        "/textures/ui/common/faction_icon-lg/cybran_med.dds",
        "/textures/ui/common/faction_icon-lg/seraphim_med.dds",
    },

    ---@param self UICustomLobbyMapPreviewSpawn
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent, self.EmptyPath)

        self.Faction = nil
        self:Hide()
    end,

    ---@param self UICustomLobbyMapPreviewSpawn
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self):Width(SpawnIconSize):Height(SpawnIconSize):Over(parent, 32):End()
    end,

    ---@param self UICustomLobbyMapPreviewSpawn
    Reset = function(self)
        self.Faction = nil
        self:Hide()
    end,

    ---@param self Control
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetAlpha(0.25)
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(1.0)
        end
        return true
    end,

    ---@param self UICustomLobbyMapPreviewSpawn
    Show = function(self)
        if self.Faction then
            Bitmap.Show(self)
        else
            self:Hide()
        end
    end,

    ---@param self UICustomLobbyMapPreviewSpawn
    ---@param faction number
    Update = function(self, faction)
        local factionIcon = self.FactionIconPaths[faction]
        if factionIcon then
            self.Faction = faction
            self:SetTexture(UIUtil.UIFile(factionIcon))
            self:Show()
        end
    end,
}

--#endregion

--------------------------------------------------------------------------------------------------
--#region Map preview

---@class UICustomLobbyMapPreviewOptions
---@field Bound? boolean   # subscribe to the launch model + use faction-icon spawns (default false)

---@class UICustomLobbyMapPreview : Group
---@field Trash TrashBag
---@field Bound boolean
---@field Glow Bitmap
---@field Backdrop Bitmap
---@field Surface UICustomLobbyScenarioPreview
---@field ScenarioObserver? LazyVar
---@field PlayerObservers? LazyVar[]
local CustomLobbyMapPreview = ClassUI(Group) {

    ---@param self UICustomLobbyMapPreview
    ---@param parent Control
    ---@param options? UICustomLobbyMapPreviewOptions
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyMapPreview")

        options = options or {}
        self.Trash = TrashBag()
        self.Bound = options.Bound or false

        -- chrome: a dark backdrop behind the map (shows through letterboxing / before the texture
        -- loads); the glow ring is lifted on top of the map in __post_init to frame its edges
        self.Backdrop = Bitmap(self)
        self.Backdrop:SetSolidColor(BackdropColor)
        self.Backdrop:DisableHitTest()

        -- the shared surface; faction-icon spawns when bound, numbered dots (the default) otherwise
        self.Surface = CustomLobbyScenarioPreview.Create(self, {
            CreateSpawnIcon = self.Bound and function(surface, index)
                return MapPreviewSpawn(surface)
            end or nil,
        })

        self.Glow = UIUtil.CreateBitmap(self, GlowTexture)
        self.Glow:DisableHitTest()

        -- bound: the derived scenario model drives the preview. The resolved scenario renders the whole
        -- map; each slot drives only the spawn icons (against the already-loaded scenario, so take/swap/
        -- faction changes don't reload the map). The model dedups by file, so a launch-info rebroadcast
        -- of the same map doesn't re-fire here either. Unbound: the owner drives self.Surface directly.
        if self.Bound then
            self.ScenarioObserver = self.Trash:Add(
                LazyVarDerive(CustomLobbyScenarioDerivedModel.GetScenarioVar(), function(scenarioLazy)
                    self:OnScenarioChanged(scenarioLazy())
                end))

            local model = CustomLobbyLaunchModel.GetSingleton()
            self.PlayerObservers = {}
            for slot = 1, CustomLobbyLaunchModel.MaxSlots do
                self.PlayerObservers[slot] = self.Trash:Add(
                    LazyVarDerive(model.Players[slot], function(playerLazy)
                        playerLazy()
                        self:OnPlayersChanged()
                    end))
            end
        end
    end,

    ---@param self UICustomLobbyMapPreview
    __post_init = function(self)
        Layouter(self.Glow):Fill(self):End()
        Layouter(self.Backdrop):FillFixedBorder(self.Glow, Padding):End()
        Layouter(self.Surface):FillFixedBorder(self.Glow, Padding):End()

        -- render the glow above the surface and all its overlays (spawn icons sit at
        -- Preview.Depth()+10), so the ring frames the map's edges instead of hiding behind them
        self.Glow.Depth:Set(function() return self.Surface.Depth() + 100 end)
    end,

    ---@param self UICustomLobbyMapPreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    --- (Bound only) Hands the already-resolved scenario to the surface; hides the preview when there
    --- is none. The derived model did the loading + dedup, so this just renders what it's given.
    ---@param self UICustomLobbyMapPreview
    ---@param scenario UICustomLobbyScenario | false
    OnScenarioChanged = function(self, scenario)
        if not scenario then
            self.Surface:Clear()
            self:Hide()
            return
        end

        self.Surface:SetScenario(scenario.Info, scenario.Markers)
        self.Surface:SetSpawnData(self:GatherSpawnData())
        self:Show()
    end,

    --- (Bound only) A slot changed: refresh the surface's spawn data (faction by start spot).
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

--#endregion

---@param parent Control
---@param options? UICustomLobbyMapPreviewOptions
---@return UICustomLobbyMapPreview
Create = function(parent, options)
    return CustomLobbyMapPreview(parent, options)
end
