local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local TexturePool = import('/lua/ui/texturepool.lua').TexturePool
local ACUButton = import('/lua/ui/controls/acubutton.lua').ACUButton

-- The default size of the mass/hydrocarbon icons
local DEFAULT_HYDROCARBON_ICON_SIZE = 14
local DEFAULT_MASS_ICON_SIZE = 10

--- UI control to show a preview image of a map, with optional resource markers.
ResourceMapPreview = Class(Group) {
    __init = function(self, parent, size, massIconSize, hydroIconSize, buttonsDisabled)
        Group.__init(self, parent)
        self.size = size
        self.buttonsDisabled = buttonsDisabled or false
        self.massIconSize = massIconSize or DEFAULT_MASS_ICON_SIZE
        self.hydroIconSize = hydroIconSize or DEFAULT_HYDROCARBON_ICON_SIZE

        -- Bitmap pools for icons.
        self.massIconPool = TexturePool(UIUtil.SkinnableFile("/game/build-ui/icon-mass_bmp.dds"), self, massIconSize, massIconSize)
        self.hydroIconPool = TexturePool(UIUtil.SkinnableFile("/game/build-ui/icon-energy_bmp.dds"), self, hydroIconSize, hydroIconSize)
        self.wreckageIconPool = TexturePool(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/mappreview/wreckage.dds"), self, 6, 6)

        self.Width:Set(size)
        self.Height:Set(size)

        self.massmarkers = {}
        self.hydromarkers = {}
        self.wreckagemarkers = {}
        self.startPositions = {}

        self.mapPreview = MapPreview(self)
        self.mapPreview.Width:Set(size)
        self.mapPreview.Height:Set(size)
        LayoutHelpers.AtLeftTopIn(self.mapPreview, self)
    end,

    --- Discard all resource markers
    DestroyResourceMarkers = function(self)
        for k, v in pairs(self.massmarkers) do
            self.massIconPool:Dispose(v)
        end

        for k, v in pairs(self.hydromarkers) do
            self.hydroIconPool:Dispose(v)
        end

        for k, v in pairs(self.wreckagemarkers) do
            self.wreckageIconPool:Dispose(v)
        end

        for k, v in pairs(self.startPositions) do
            v:Destroy()
        end

        self.massmarkers = {}
        self.hydromarkers = {}
        self.startPositions = {}
    end,

    --- Delete all resource markers and clear the map preview.
    Clear = function(self)
        self:DestroyResourceMarkers()
        self.mapPreview:ClearTexture()
    end,

    --- Update the control to display the map given by a specified scenario file.
    --
    -- @param scenarioFile Path to the scenario file from which to load map data to display.
    SetScenarioFromFile = function(self, scenarioFile)
        self:SetScenario(MapUtil.LoadScenario(scenarioFile))
    end,

    --- Update the control to display the map given by a specific scenario object.
    --
    -- @param scenarioInfo Scenario info object from which to extract map data.
    SetScenario = function(self, scenarioInfo, enableWreckage)
        self:DestroyResourceMarkers()

        if not scenarioInfo then
            self.mapPreview:ClearTexture()
            return
        end

        -- Load the image of the map.
        if not self.mapPreview:SetTexture(scenarioInfo.preview) then
            self.mapPreview:SetTextureFromMap(scenarioInfo.map)
        end

        -- Load mass and hydrocarbon points for the map and display them.
        local mapdata = {}
        doscript('/lua/dataInit.lua', mapdata) -- needed for the format of _save files
        doscript(scenarioInfo.save, mapdata)

        local allmarkers = mapdata.Scenario.MasterChain['_MASTERCHAIN_'].Markers -- get the markers from the save file
        local massmarkers = {}
        local hydromarkers = {}

        for markname in allmarkers do
            if allmarkers[markname]['type'] == "Mass" then
                table.insert(massmarkers, allmarkers[markname])
            elseif allmarkers[markname]['type'] == "Hydrocarbon" then
                table.insert(hydromarkers, allmarkers[markname])
            end
        end

        -- The width and height of the map.
        local mWidth = scenarioInfo.size[1]
        local mHeight = scenarioInfo.size[2]

        -- Add the wreckage, if activated. (done first so the important things appear on top)
        local wreckagemarkers = {}
        if enableWreckage then
            local armies = mapdata.Scenario.Armies

            for _, army in armies do
                -- This is so spectacularly brittle it's magnificent.
                if army.Units and army.Units.Units and army.Units.Units.WRECKAGE and army.Units.Units.WRECKAGE.Units then
                    for k, v in army.Units.Units.WRECKAGE.Units do
                        -- Some maps have extra entities in the Units list, representing groups.
                        -- Very annoying, so let's check for the fields we care about.
                        if v.Position then
                            local marker = self.wreckageIconPool:Get()
                            table.insert(wreckagemarkers, marker)
                            marker:Show()

                            -- Yes, these ones have a capital Position, but the others have a lowercase.
                            LayoutHelpers.AtLeftTopIn(marker, self.mapPreview,
                                (v.Position[1] / mWidth) * self.size - 2,
                                (v.Position[3] / mHeight) *  self.size - 2)
                        end
                    end
                end
            end
        end
        self.wreckagemarkers = wreckagemarkers

        -- Add the mass points.
        local masses = {}
        for i = 1, table.getn(massmarkers) do
            masses[i] = self.massIconPool:Get()
            masses[i]:Show()

            LayoutHelpers.AtLeftTopIn(masses[i], self.mapPreview,
                massmarkers[i].position[1] / mWidth * self.size - self.massIconSize / 2,
                massmarkers[i].position[3] / mHeight * self.size - self.massIconSize / 2)
        end
        self.massmarkers = masses

        -- Add the hydrocarbon points.
        local hydros = {}
        for i = 1, table.getn(hydromarkers) do
            hydros[i] = self.hydroIconPool:Get()
            hydros[i]:Show()

            LayoutHelpers.AtLeftTopIn(hydros[i], self.mapPreview,
                hydromarkers[i].position[1] / mWidth * self.size - self.hydroIconSize / 2,
                hydromarkers[i].position[3] / mHeight*  self.size - self.hydroIconSize / 2)
        end
        self.hydromarkers = hydros

        -- Add the start positions.
        local startPos = MapUtil.GetStartPositions(scenarioInfo)

        local playerArmyArray = MapUtil.GetArmies(scenarioInfo)

        local startPositions = {}
        for inSlot, army in playerArmyArray do
            local pos = startPos[army]
            local slot = inSlot

            -- Create an ACUButton for each start position.
            local marker = ACUButton(self.mapPreview, not self.buttonsDisabled)

            LayoutHelpers.AtLeftTopIn(marker, self.mapPreview,
                ((pos[1] / mWidth) * self.size) - (marker.Width() / 2),
                ((pos[2] / mHeight) * self.size) - (marker.Height() / 2))

            startPositions[slot] = marker
        end

        self.startPositions = startPositions
    end,

    OnDestroy = function(self)
        self.massIconPool:Destroy()
        self.hydroIconPool:Destroy()
        Group.OnDestroy(self)
    end
}
