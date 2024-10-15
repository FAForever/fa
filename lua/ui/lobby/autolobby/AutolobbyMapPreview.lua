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
local Group = import("/lua/maui/group.lua").Group
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local TexturePool = import("/lua/ui/texturepool.lua").TexturePool
local ACUButton = import("/lua/ui/controls/acubutton.lua").ACUButton
local gameColors = import("/lua/gamecolors.lua").GameColors

local MapUtil = import("/lua/ui/maputil.lua")

---@class UIAutolobbyMapPreview : Group
---@field Preview MapPreview
---@field Border Control
---@field Scenario? string
---@field ScenarioInfo? UIScenarioInfo
---@field EnergyIcon Bitmap     # Acts as a pool
---@field MassIcon Bitmap       # Acts as a pool
---@field WreckageIcon Bitmap   # Acts as a pool
---@field IconTrash TrashBag    # Trashbag that contains all icons
---@field MassIcons Bitmap[]
---@field EnergyIcons Bitmap[]
---@field WreckageIcons Bitmap[]
AutolobbyMapPreview = ClassUI(Group) {

    ---@param self UIAutolobbyMapPreview
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent)

        self.Preview = MapPreview(self)
        self.Border = UIUtil.SurroundWithBorder(self.Preview, '/scx_menu/lan-game-lobby/frame/')

        self.EnergyIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-energy_bmp.dds")
        self.MassIcon = UIUtil.CreateBitmap(self, "/game/build-ui/icon-mass_bmp.dds")
        self.WreckageIcon = UIUtil.CreateBitmap(self, "/scx_menu/lan-game-lobby/mappreview/wreckage.dds")

        self.IconTrash = TrashBag()
        self.EnergyIcons = {}
        self.MassIcons = {}
        self.WreckageIcons = {}
    end,

    ---@param self UIAutolobbyMapPreview
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self.Preview)
            :Fill(self)
            :End()

        LayoutHelpers.LayoutFor(self.EnergyIcon)
            :Hide()
            :End()

        LayoutHelpers.LayoutFor(self.MassIcon)
            :Hide()
            :End()

        LayoutHelpers.LayoutFor(self.WreckageIcon)
            :Hide()
            :End()
    end,

    --- Creates an icon that shares the texture with a source.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioWidth number
    ---@param scenarioHeight number
    ---@param px number
    ---@param pz number
    ---@param source Bitmap
    ---@return Bitmap
    _CreateIcon = function(self, scenarioWidth, scenarioHeight, px, pz, source)
        local size = self.Width()

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

        -- create an icon
        local icon = UIUtil.CreateBitmapColor(self, 'ffffff')

        -- share the texture
        icon:ShareTextures(source)

        local x = xOffset + (px / scenarioWidth) * (size - 2) * xFactor - 4
        local z = yOffset + (pz / scenarioHeight) * (size - 2) * yFactor - 4

        -- position it
        LayoutHelpers.LayoutFor(icon)
            :Width(14)
            :Height(14)
            :AtLeftTopIn(self, x, z)

        -- make it disposable
        self.IconTrash:Add(icon)

        return icon
    end,

    --- Creates the map preview.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UIScenarioInfo
    _UpdatePreview = function(self, scenarioInfo)
        if not self.Preview:SetTexture(scenarioInfo.preview) then
            self.Preview:SetTextureFromMap(scenarioInfo.map)
        end
    end,

    --- Creates icons for resource markers.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UIScenarioInfo
    _UpdateMarkers = function(self, scenarioInfo)
        local scenarioWidth = scenarioInfo.size[1]
        local scenarioHeight = scenarioInfo.size[2]

        -- load in the save file
        self.ScenarioSave = {}
        doscript('/lua/dataInit.lua', self.ScenarioSave)
        doscript(scenarioInfo.save, self.ScenarioSave)

        local allmarkers = self.ScenarioSave.Scenario.MasterChain['_MASTERCHAIN_'].Markers
        if not allmarkers then
            return
        end
        for key, marker in allmarkers do
            if marker['type'] == "Mass" then
                table.insert(self.MassIcons,
                    self:_CreateIcon(
                        scenarioWidth, scenarioHeight,
                        marker.position[1], marker.position[3],
                        self.MassIcon
                    )
                )
            elseif marker['type'] == "Hydrocarbon" then
                table.insert(self.EnergyIcons,
                    self:_CreateIcon(
                        scenarioWidth, scenarioHeight,
                        marker.position[1], marker.position[3],
                        self.EnergyIcon
                    )
                )
            end
        end
    end,

    --- Creates icons for wreckages.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UIScenarioInfo
    _UpdateWreckages = function(self, scenarioInfo)
        -- TODO
    end,

    --- Creates icons for spawn locations.
    ---
    --- This function is private and should not be called from outside the class.
    ---@param self UIAutolobbyMapPreview
    ---@param scenarioInfo UIScenarioInfo
    _UpdateSpawnLocations = function(self, scenarioInfo)
        -- TODO
    end,

    ---@param self UIAutolobbyMapPreview
    ---@param scenario string   # a reference to a _scenario.lua file
    UpdateScenario = function(self, scenario)
        -- clear up previous iteration
        self.IconTrash:Destroy()
        self.Preview:ClearTexture()

        self.Scenario = scenario
        self.ScenarioInfo = MapUtil.LoadScenario(scenario)
        if self.ScenarioInfo then
            self:_UpdatePreview(self.ScenarioInfo)
            self:_UpdateMarkers(self.ScenarioInfo)
            self:_UpdateWreckages(self.ScenarioInfo)
            self:_UpdateSpawnLocations(self.ScenarioInfo)
        end
    end,
}
