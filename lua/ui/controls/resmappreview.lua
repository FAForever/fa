local UIUtil = import("/lua/ui/uiutil.lua")
local Group = import("/lua/maui/group.lua").Group
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local TexturePool = import("/lua/ui/texturepool.lua").TexturePool
local ACUButton = import("/lua/ui/controls/acubutton.lua").ACUButton
local gameColors = import("/lua/gamecolors.lua").GameColors

-- The default size of the mass/hydrocarbon icons
local DEFAULT_HYDROCARBON_ICON_SIZE = 14
local DEFAULT_MASS_ICON_SIZE = 10

--- UI control to show a preview image of a map, with optional resource markers.
---@class ResourceMapPreview : Group
ResourceMapPreview = ClassUI(Group) {

    ---@param self ResourceMapPreview
    ---@param parent Control
    ---@param size number
    ---@param massIconSize number
    ---@param hydroIconSize number
    ---@param buttonsDisabled boolean
    __init = function(self, parent, size, massIconSize, hydroIconSize, buttonsDisabled)
        Group.__init(self, parent)
        self.size = size
        self.buttonsDisabled = buttonsDisabled or false
        self.massIconSize = LayoutHelpers.ScaleNumber(massIconSize or DEFAULT_MASS_ICON_SIZE)
        self.hydroIconSize = LayoutHelpers.ScaleNumber(hydroIconSize or DEFAULT_HYDROCARBON_ICON_SIZE)
        self.wreckageIconSize = LayoutHelpers.ScaleNumber(6)

        -- Bitmap pools for icons.
        self.massIconPool = TexturePool(UIUtil.SkinnableFile("/game/build-ui/icon-mass_bmp.dds"), self, self.massIconSize, self.massIconSize)
        self.hydroIconPool = TexturePool(UIUtil.SkinnableFile("/game/build-ui/icon-energy_bmp.dds"), self, self.hydroIconSize, self.hydroIconSize)
        self.wreckageIconPool = TexturePool(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/mappreview/wreckage.dds"), self, self.wreckageIconSize, self.wreckageIconSize)

        LayoutHelpers.SetDimensions(self, self.size, self.size)

        self.massmarkers = {}
        self.hydromarkers = {}
        self.wreckagemarkers = {}
        self.startPositions = {}
        self.ratingLabel = {}

        self.mapPreview = MapPreview(self)
        LayoutHelpers.SetDimensions(self.mapPreview, self.size, self.size)
        LayoutHelpers.AtLeftTopIn(self.mapPreview, self)
    end,

    --- Discard all resource markers
    ---@param self ResourceMapPreview
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

        for k, v in pairs(self.ratingLabel) do
            v:Destroy()
        end

        self.massmarkers = {}
        self.hydromarkers = {}
        self.startPositions = {}
        self.ratingLabel = {}
    end,

    --- Delete all resource markers and clear the map preview.
    ---@param self ResourceMapPreview
    Clear = function(self)
        self:DestroyResourceMarkers()
        self.mapPreview:ClearTexture()
    end,

    --- Update the control to display the map given by a specified scenario file.
    --
    -- @param scenarioFile Path to the scenario file from which to load map data to display.
    ---@param self ResourceMapPreview
    ---@param scenarioFile FileName
    SetScenarioFromFile = function(self, scenarioFile)
        self:SetScenario(MapUtil.LoadScenario(scenarioFile))
    end,

    --- Update the control to display the map given by a specific scenario object.
    ---@param self ResourceMapPreview
    ---@param scenarioInfo string
    ---@param enableWreckage boolean
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

        -- Ratio of width to height: map previews are always sqaures, but maps are not.
        -- It appears nonsquare maps always provide preview images with the map centered (and we're
        -- unable to either check if this is true or do anything about it if it's not anyway), so we
        -- assume it.

        local xOffset = 0
        local xFactor = 1
        local yOffset = 0
        local yFactor = 1

        local longEdge
        local shortEdge
        if mWidth > mHeight then
            local ratio = mHeight/mWidth   -- 1/2
            yOffset = ((self.size / ratio) - self.size) / 4
            yFactor = ratio
        else
            local ratio = mWidth/mHeight
            xOffset = ((self.size / ratio) - self.size) / 4
            xFactor = ratio
        end

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
                            if scenarioInfo.hidePreviewMarkers then
                                marker:Hide()
                            else
                                marker:Show()
                            end

                            -- Yes, these ones have a capital Position, but the others have a lowercase.
                            LayoutHelpers.AtLeftTopIn(marker, self.mapPreview,
                                xOffset + (v.Position[1] / mWidth) * (self.size - 2) * xFactor,
                                yOffset + (v.Position[3] / mHeight) * (self.size - 2) * yFactor)
                        end
                    end
                end
            end
        end
        self.wreckagemarkers = wreckagemarkers

        -- Add the mass points.
        local halfMassIconSize = self.massIconSize / 2
        local masses = {}
        for i = 1, table.getn(massmarkers) do
            masses[i] = self.massIconPool:Get()
            if scenarioInfo.hidePreviewMarkers then
                masses[i]:Hide()
            else
                masses[i]:Show()
            end

            LayoutHelpers.AtLeftTopIn(masses[i], self.mapPreview,
                xOffset + (massmarkers[i].position[1] / mWidth) * (self.size * xFactor)  - halfMassIconSize,
                yOffset + (massmarkers[i].position[3] / mHeight) * (self.size * yFactor) - halfMassIconSize)
        end
        self.massmarkers = masses

        -- Add the hydrocarbon points.
        local hydros = {}
        local halfHydroIconSize = self.hydroIconSize / 2
        for i = 1, table.getn(hydromarkers) do
            hydros[i] = self.hydroIconPool:Get()
            if scenarioInfo.hidePreviewMarkers then
                hydros[i]:Hide()
            else
                hydros[i]:Show()
            end

            LayoutHelpers.AtLeftTopIn(hydros[i], self.mapPreview,
                xOffset + (hydromarkers[i].position[1] / mWidth) * (self.size * xFactor)  - halfHydroIconSize,
                yOffset + (hydromarkers[i].position[3] / mHeight) * (self.size * yFactor) - halfHydroIconSize)
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
            local marker = ACUButton(self.mapPreview, not self.buttonsDisabled and not scenarioInfo.hidePreviewMarkers)
            local markerWidth = xOffset + ((pos[1] / mWidth) * self.size * xFactor) - (marker.Width() / 2)
            local markerHeight = yOffset + ((pos[2] / mHeight) * self.size * yFactor) - (marker.Height() / 2)
            LayoutHelpers.AtLeftTopIn(marker, self.mapPreview, markerWidth, markerHeight)

            -- TODO: Create a text box for the rating label, and position it relative to the ACUButton.
            -- The ACUButton we just made is the little icon representing the player.

            -- Create Labels above markers to show rating of player or AI names
            self.ratingLabel[slot] = UIUtil.CreateText(self.mapPreview, '', 10, 'Arial Gras', true)
            LayoutHelpers.CenteredAbove(self.ratingLabel[slot], marker, 5)

            if scenarioInfo.hidePreviewMarkers then
                marker:Hide()
                self.ratingLabel[slot]:Hide()
            end

            startPositions[slot] = marker
        end

        self.startPositions = startPositions
    end,

    --- Update the representation of a particular player.
    ---@param self ResourceMapPreview
    ---@param slot number The slot index of the player to update.
    ---@param playerInfo PlayerData The player's PlayerInfo object.
    ---@param hideColours boolean A flag indicating if the player's colour should be shown or now.
    UpdatePlayer = function(self, slot, playerInfo, hideColours)
        -- The ACUButton instance representing this slot, if any.
        local marker = self.startPositions[slot]

        if not marker then return end -- Marker is nil when the map slot count shrunk

        if hideColours then
            marker:SetColor("00777777")
            self.ratingLabel[slot]:Hide()
            self.ratingLabel[slot].isHidden = true
        else
            -- If spawns are fixed, show the colour/team of the person in this slot.
            if playerInfo then
                marker:SetColor(gameColors.PlayerColors[playerInfo.PlayerColor])
                marker:SetTeam(playerInfo.Team)
            else
                marker:Clear()
            end

            -- Set text to rating, or name if AI, or empty if nil playerInfo (Emptying slot)
            local text
            if playerInfo.Human then
                text = playerInfo.PL
            else
                text = playerInfo.PlayerName or ""
            end

            self.ratingLabel[slot]:SetText(text)
        end
    end,

    ---@param self ResourceMapPreview
    OnDestroy = function(self)
        self.massIconPool:Destroy()
        self.hydroIconPool:Destroy()
        self.wreckageIconPool:Destroy()
        Group.OnDestroy(self)
    end
}
