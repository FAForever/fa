--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

local UIUtil = import("/lua/ui/uiutil.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local AutolobbyMapPreviewSpawn = import("/lua/ui/lobby/autolobby/autolobbymappreviewspawn.lua")

---@class UIAutolobbyMapPreview : Group
---@field Preview MapPreview
---@field Overlay Bitmap
---@field PathToScenarioFile? FileName
---@field ScenarioInfo? UILobbyScenarioInfo
---@field ScenarioSave? UIScenarioSaveFile
---@field EnergyIcon Bitmap     # Acts as a pool
---@field MassIcon Bitmap       # Acts as a pool
---@field WreckageIcon Bitmap   # Acts as a pool
---@field IconTrash TrashBag    # Trashbag that contains all icons
---@field SpawnIcons UIAutolobbyMapPreviewSpawn[]
local AutolobbyMapPreview = ClassUI(Group) {

    ---@param self UIAutolobbyMapPreview
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.Preview = MapPreview(self)

        -- D:\SteamLibrary\steamapps\common\Supreme Commander Forged Alliance\gamedata\textures\textures\ui\common\game\mini-map-glow-brd ?
        self.Overlay = UIUtil.CreateBitmap(self, '/scx_menu/gameselect/map-panel-glow_bmp.dds')

        self.EnergyIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-energy_bmp.dds")
        self.MassIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-mass_bmp.dds")
        self.WreckageIcon = UIUtil.CreateBitmap(self, "/scx_menu/lan-game-lobby/mappreview/wreckage.dds")
        self.SpawnIcons = {}

        UIUtil.CreateDialogBrackets(self, 30, 24, 30, 24)

        self.IconTrash = TrashBag()
    end,

    ---@param self UIAutolobbyMapPreview
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.ReusedLayoutFor(self.Overlay)
            :Fill(self)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.Preview)
            :FillFixedBorder(self.Overlay, 24)
            :End()

        LayoutHelpers.ReusedLayoutFor(self.EnergyIcon)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.MassIcon)
            :Hide()
            :End()

        LayoutHelpers.ReusedLayoutFor(self.WreckageIcon)
            :Hide()
            :End()
    end,

    --- Creates an icon that shares the texture with a source.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
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
            local ratio = scenarioHeight / scenarioWidth -- 1/2
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

    --- Creates the map preview.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    _UpdatePreview = function(self, scenarioInfo)
        if not self.Preview:SetTexture(scenarioInfo.preview) then
            self.Preview:SetTextureFromMap(scenarioInfo.map)
        end
    end,

    --- Creates icons for resource markers.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
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

    --- Creates icons for wreckages.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@param scenarioSave UIScenarioSaveFile
    _UpdateWreckages = function(self, scenarioInfo, scenarioSave)
        -- TODO
    end,

    --- Creates icons for spawn locations.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@param scenarioSave UIScenarioSaveFile
    ---@param playerOptions UIAutolobbyPlayer[]
    _UpdateSpawnLocations = function(self, scenarioInfo, scenarioSave, playerOptions)
        local spawnIcons = self.SpawnIcons
        local positions = MapUtil.GetStartPositionsFromScenario(scenarioInfo, scenarioSave)
        if not positions then
            -- clean up
            for id, icon in spawnIcons do
                icon:Destroy()
            end

            return
        end

        -- clean up
        for id, icon in spawnIcons do
            if not positions[id] then
                icon:Destroy()
            end
        end

        -- create/update icons
        for id, position in positions do
            local icon = spawnIcons[id]
            if not icon then
                icon = AutolobbyMapPreviewSpawn.Create(self)
            end

            spawnIcons[id] = icon

            self:PositionIcon(
                icon, scenarioInfo.size[1], scenarioInfo.size[2],
                position[1], position[2]
            )

            local playerOptions = playerOptions[id]
            if playerOptions then
                icon:Update(playerOptions.Faction)
            else
                icon:Reset()
            end
        end
    end,

    --- Updates the map preview, including the mass, energy and wreckage icons.
    ---@param self UIAutolobbyMapPreview
    ---@param pathToScenarioInfo FileName   # a reference to a _scenario.lua file
    ---@param playerOptions UIAutolobbyPlayer[]
    UpdateScenario = function(self, pathToScenarioInfo, playerOptions)
        -- -- make it idempotent
        -- if self.PathToScenarioFile ~= pathToScenarioInfo then
        --     return
        -- end

        -- clear up previous iteration
        self.IconTrash:Destroy()
        self.Preview:ClearTexture()
        self.PathToScenarioFile = pathToScenarioInfo

        -- try and load the scenario info
        local scenarioInfo = MapUtil.LoadScenario(pathToScenarioInfo)
        if not scenarioInfo then
            -- TODO: show default image that indicates something is off
            return
        end

        self.ScenarioInfo = scenarioInfo
        self:_UpdatePreview(scenarioInfo)

        -- try and load the scenario save
        local scenarioSave = MapUtil.LoadScenarioSaveFile(scenarioInfo.save)
        if not scenarioSave then
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

    ---@param self UIAutolobbyMapPreview
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
---@return UIAutolobbyMapPreview
GetInstance = function(parent)
    return AutolobbyMapPreview(parent)
end
