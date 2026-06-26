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

-- A reusable map-preview *surface*: the scenario's map texture plus its overlays — start
-- spots, resource deposits (mass / hydrocarbon) and prebuilt wrecks — placed at the right
-- spots with aspect-correct maths. It is deliberately chrome-free: no title, border or glow.
-- Owners wrap it and add their own decoration — `CustomLobbyMapPreview` adds the glow + backdrop
-- frame (and the map-select dialog layers a title bar on top of that).
--
-- It exists so the two preview consumers share ONE implementation of the fiddly bits — the
-- texture-leak-safe icon sharing, the aspect-correct positioning, the three-phase init — rather
-- than each maintaining a copy that drifts (and re-learns the same engine gotchas).
--
-- Memory: the resource/wreck icons load their texture ONCE into hidden template bitmaps and
-- every marker shares it via `ShareTextures` (the engine never frees per-bitmap textures — see
-- mapselect/CLAUDE.md). The map texture itself is one `MapPreview`; don't instantiate this
-- control per list row.
--
-- Spawn appearance is the owner's choice via the `CreateSpawnIcon` option: a bound
-- `CustomLobbyMapPreview` passes faction icons, the picker passes numbered dots (the
-- default). A spawn icon may implement `:Update(data)` / `:Reset()`; the surface calls `Update`
-- with `SetSpawnData()[index]` when present, else `Reset` — so faction icons hide on empty
-- spots while numbered dots (no Update/Reset) stay shown.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview

local Layouter = LayoutHelpers.ReusedLayoutFor

local MassIcon = "/game/build-ui/icon-mass_bmp.dds"
local EnergyIcon = "/game/build-ui/icon-energy_bmp.dds"
local WreckIcon = "/scx_menu/lan-game-lobby/mappreview/wreckage.dds"

local ResourceIconSize = 10
local WreckIconSize = 11
local SpawnDotSize = 18

---@class UICustomLobbyScenarioPreviewOptions
---@field CreateSpawnIcon? fun(surface: Control, index: number): Control   # defaults to a numbered dot

---@class UICustomLobbyScenarioPreview : Group
---@field Trash TrashBag
---@field MarkerTrash TrashBag                  # resource + wreck icons (rebuilt on SetScenario)
---@field SpawnTrash TrashBag                   # spawn icons (rebuilt on SetScenario / SetSpawnData)
---@field Preview MapPreview
---@field MassTemplate Bitmap                   # hidden; resource markers share its texture
---@field EnergyTemplate Bitmap
---@field WreckTemplate Bitmap
---@field WaterMask Bitmap                       # DUMMY placeholder water tint (no real mask yet)
---@field SpawnIcons table<number, Control>
---@field ResourceIcons Control[]
---@field WreckIcons Control[]
---@field ShowSpawns boolean
---@field ShowResources boolean
---@field ShowWrecks boolean
---@field ShowWater boolean
---@field ScenarioInfo? UILobbyScenarioInfo
---@field Markers? UICustomLobbyScenarioMarkers  # extracted save bits (spawns + mass/hydro/wreck points)
---@field SpawnData table<number, any>          # per-start-spot data handed to spawn icons' :Update
---@field CreateSpawnIcon fun(surface: Control, index: number): Control
---@field Ready boolean                         # true once laid out by the parent; gates geometry reads
local CustomLobbyScenarioPreview = ClassUI(Group) {

    ---@param self UICustomLobbyScenarioPreview
    ---@param parent Control
    ---@param options? UICustomLobbyScenarioPreviewOptions
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyScenarioPreview")

        options = options or {}

        self.Trash = TrashBag()
        self.MarkerTrash = self.Trash:Add(TrashBag())
        self.SpawnTrash = self.Trash:Add(TrashBag())

        self.SpawnIcons = {}
        self.ResourceIcons = {}
        self.WreckIcons = {}

        self.ShowSpawns = true
        self.ShowResources = true
        self.ShowWrecks = true
        self.ShowWater = false

        self.ScenarioInfo = nil
        self.Markers = nil
        self.SpawnData = {}
        self.Ready = false

        self.CreateSpawnIcon = options.CreateSpawnIcon or function(surface, index)
            return self:CreateNumberedDot(index)
        end

        self.Preview = MapPreview(self)

        -- DUMMY water overlay: a translucent blue tint over the whole map until a real water mask
        -- exists. Sits above the map texture but below the resource/wreck/spawn markers. Hidden by
        -- default; the 'water' overlay toggle reveals it.
        self.WaterMask = Bitmap(self)
        self.WaterMask:SetSolidColor('66123a66')
        self.WaterMask:DisableHitTest()
        self.WaterMask:Hide()

        self.MassTemplate = self:CreateTemplateBitmap(MassIcon)
        self.EnergyTemplate = self:CreateTemplateBitmap(EnergyIcon)
        self.WreckTemplate = self:CreateTemplateBitmap(WreckIcon)
    end,

    ---@param self UICustomLobbyScenarioPreview
    __post_init = function(self)
        Layouter(self.Preview):Fill(self):End()
        Layouter(self.WaterMask):Fill(self.Preview):End()
        self.WaterMask.Depth:Set(function() return self.Preview.Depth() + 1 end)

        -- our PARENT sizes us after this returns, so self.Preview.Width() isn't concrete yet;
        -- defer the first render a frame, then let SetScenario/SetSpawnData drive updates
        self.Trash:Add(ForkThread(
            function()
                WaitFrames(1)
                if IsDestroyed(self) then
                    return
                end
                self.Ready = true
                self:Render()
            end
        ))
    end,

    ---@param self UICustomLobbyScenarioPreview
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    ---------------------------------------------------------------------------
    --#region Public API

    --- Renders a scenario: map texture + resource/wreck/spawn overlays. Pass the already-loaded info
    --- and the extracted markers (the owner gets them from the catalog / scenario model — the surface
    --- never touches the raw save). A nil info clears the surface.
    ---@param self UICustomLobbyScenarioPreview
    ---@param scenarioInfo? UILobbyScenarioInfo
    ---@param markers? UICustomLobbyScenarioMarkers
    SetScenario = function(self, scenarioInfo, markers)
        self.ScenarioInfo = scenarioInfo
        self.Markers = markers
        if self.Ready then
            self:Render()
        end
    end,

    --- Updates the per-start-spot spawn data (e.g. seated players' factions) and refreshes just
    --- the spawn icons against the already-loaded scenario — no map reload.
    ---@param self UICustomLobbyScenarioPreview
    ---@param spawnData table<number, any>
    SetSpawnData = function(self, spawnData)
        self.SpawnData = spawnData or {}
        if self.Ready and self.ScenarioInfo and self.Markers then
            self:RenderSpawns()
        end
    end,

    --- Shows/hides an overlay group: 'spawns' | 'resources' | 'wrecks' | 'water'.
    ---@param self UICustomLobbyScenarioPreview
    ---@param kind string
    ---@param visible boolean
    SetOverlayVisible = function(self, kind, visible)
        if kind == 'spawns' then
            self.ShowSpawns = visible
        elseif kind == 'resources' then
            self.ShowResources = visible
        elseif kind == 'wrecks' then
            self.ShowWrecks = visible
        elseif kind == 'water' then
            self.ShowWater = visible
        end
        self:ApplyVisibility()
    end,

    --- Clears the texture + all overlays (no scenario shown).
    ---@param self UICustomLobbyScenarioPreview
    Clear = function(self)
        self.ScenarioInfo = nil
        self.Markers = nil
        self.MarkerTrash:Destroy()
        self.SpawnTrash:Destroy()
        self.SpawnIcons = {}
        self.ResourceIcons = {}
        self.WreckIcons = {}
        self.Preview:ClearTexture()
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Rendering (private)

    ---@param self UICustomLobbyScenarioPreview
    Render = function(self)
        self.MarkerTrash:Destroy()
        self.ResourceIcons = {}
        self.WreckIcons = {}

        local info = self.ScenarioInfo
        if not info then
            self.SpawnTrash:Destroy()
            self.SpawnIcons = {}
            self.Preview:ClearTexture()
            return
        end

        if not self.Preview:SetTexture(info.preview) then
            self.Preview:SetTextureFromMap(info.map)
        end

        if self.Markers and info.size then
            self:BuildResources()
            self:BuildWrecks()
        end
        self:RenderSpawns()
        self:ApplyVisibility()
    end,

    --- Rebuilds only the spawn icons (resources/wrecks untouched).
    ---@param self UICustomLobbyScenarioPreview
    RenderSpawns = function(self)
        self.SpawnTrash:Destroy()
        self.SpawnIcons = {}

        local info = self.ScenarioInfo
        if not (info and self.Markers and info.size) then
            return
        end

        local positions = self.Markers.Spawns
        if not positions then
            return
        end

        for index, position in positions do
            local icon = self.SpawnTrash:Add(self.CreateSpawnIcon(self, index))
            icon.Depth:Set(function() return self.Preview.Depth() + 10 end)
            self:PlaceMarker(icon, info.size[1], info.size[2], position[1], position[2])

            local data = self.SpawnData[index]
            if data ~= nil and icon.Update then
                icon:Update(data)
            elseif icon.Reset then
                icon:Reset()
            end

            self.SpawnIcons[index] = icon
        end

        if not self.ShowSpawns then
            self:ApplyVisibility()
        end
    end,

    --- Places mass + hydrocarbon icons from the extracted resource points.
    ---@param self UICustomLobbyScenarioPreview
    BuildResources = function(self)
        local info = self.ScenarioInfo
        local function place(points, template)
            for _, point in points do
                local icon = self.MarkerTrash:Add(self:CreateMarkerIcon(template, ResourceIconSize))
                self:PlaceMarker(icon, info.size[1], info.size[2], point[1], point[2])
                table.insert(self.ResourceIcons, icon)
            end
        end
        place(self.Markers.MassPoints, self.MassTemplate)
        place(self.Markers.HydroPoints, self.EnergyTemplate)
    end,

    --- Best-effort wreck icons: maps that expose prebuilt wreckage (extracted as wreck points).
    ---@param self UICustomLobbyScenarioPreview
    BuildWrecks = function(self)
        local info = self.ScenarioInfo
        for _, point in self.Markers.Wrecks do
            local icon = self.MarkerTrash:Add(self:CreateMarkerIcon(self.WreckTemplate, WreckIconSize))
            self:PlaceMarker(icon, info.size[1], info.size[2], point[1], point[2])
            table.insert(self.WreckIcons, icon)
        end
    end,

    --- Shows/hides each overlay group per its flag. Spawn icons that override Show (e.g. the
    --- faction icon hides itself with no faction) keep their own logic.
    ---@param self UICustomLobbyScenarioPreview
    ApplyVisibility = function(self)
        local function setVisible(icons, visible)
            for _, icon in icons do
                if visible then
                    icon:Show()
                else
                    icon:Hide()
                end
            end
        end
        setVisible(self.SpawnIcons, self.ShowSpawns)
        setVisible(self.ResourceIcons, self.ShowResources)
        setVisible(self.WreckIcons, self.ShowWrecks)
        if self.ShowWater then
            self.WaterMask:Show()
        else
            self.WaterMask:Hide()
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Icon factories (private)

    --- The default spawn icon: a small numbered dot.
    ---@param self UICustomLobbyScenarioPreview
    ---@param index number
    ---@return Group
    CreateNumberedDot = function(self, index)
        local dot = Group(self)
        dot:DisableHitTest()

        local bg = Bitmap(dot)
        bg:SetSolidColor('cc1c2228')
        bg:DisableHitTest()

        local label = UIUtil.CreateText(dot, tostring(index), 12, UIUtil.bodyFont)
        label:DisableHitTest()

        Layouter(dot):Width(SpawnDotSize):Height(SpawnDotSize):End()
        Layouter(bg):Fill(dot):End()
        Layouter(label):AtCenterIn(dot):End()
        return dot
    end,

    --- Loads an overlay texture once into a hidden template bitmap that markers share from.
    --- Given a dummy position (unanchored Left/Right are circular) and locked hidden so a parent
    --- Show() can't reveal it.
    ---@param self UICustomLobbyScenarioPreview
    ---@param texture FileName
    ---@return Bitmap
    CreateTemplateBitmap = function(self, texture)
        local template = UIUtil.CreateBitmap(self, texture)
        template:DisableHitTest()
        Layouter(template):Left(0):Top(0):Width(8):Height(8):End()
        template:Hide()
        template.OnHide = function(control, hidden)
            return true
        end
        return template
    end,

    --- A small resource/wreck marker sharing its texture with a template (loaded once).
    ---@param self UICustomLobbyScenarioPreview
    ---@param template Bitmap
    ---@param size number
    ---@return Bitmap
    CreateMarkerIcon = function(self, template, size)
        local icon = UIUtil.CreateBitmapColor(self, 'ffffff')
        icon:DisableHitTest()
        Layouter(icon):Width(size):Height(size):End()
        icon:ShareTextures(template)
        icon.Depth:Set(function() return self.Preview.Depth() + 5 end)
        return icon
    end,

    --- Positions an overlay control over the preview at a map coordinate (aspect-correct).
    ---@param self UICustomLobbyScenarioPreview
    ---@param icon Control
    ---@param mapWidth number
    ---@param mapHeight number
    ---@param px number
    ---@param pz number
    PlaceMarker = function(self, icon, mapWidth, mapHeight, px, pz)
        local size = self.Preview.Width()
        local xOffset, xFactor, yOffset, yFactor = 0, 1, 0, 1
        if mapWidth > mapHeight then
            local ratio = mapHeight / mapWidth
            yOffset = ((size / ratio) - size) / 4
            yFactor = ratio
        else
            local ratio = mapWidth / mapHeight
            xOffset = ((size / ratio) - size) / 4
            xFactor = ratio
        end

        local x = xOffset + (px / mapWidth) * (size - 2) * xFactor
        local z = yOffset + (pz / mapHeight) * (size - 2) * yFactor

        icon.Left:Set(function() return self.Preview.Left() + x - 0.5 * icon.Width() end)
        icon.Top:Set(function() return self.Preview.Top() + z - 0.5 * icon.Height() end)
    end,

    --#endregion
}

---@param parent Control
---@param options? UICustomLobbyScenarioPreviewOptions
---@return UICustomLobbyScenarioPreview
Create = function(parent, options)
    return CustomLobbyScenarioPreview(parent, options)
end
