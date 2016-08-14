local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local TexturePool = import('/lua/ui/texturepool.lua').TexturePool
local ACUButton = import('/lua/ui/controls/acubutton.lua').ACUButton
local gameColors = import('/lua/gameColors.lua').GameColors
local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
local ColumnLayout = import('/lua/ui/controls/columnlayout.lua').ColumnLayout
local FactionData = import('/lua/factions.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
--local Button = import('/lua/maui/button.lua').Button

-- The default size of the mass/hydrocarbon icons
local DEFAULT_HYDROCARBON_ICON_SIZE = 14
local DEFAULT_MASS_ICON_SIZE = 10

--- UI control to show a preview image of a map, with optional resource markers.
ResourceMapPreview = Class(Group) {
    __init = function(self, parent, size, massIconSize, hydroIconSize, buttonsDisabled, showAdvancedPlayerStats)
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

        self.ratingLabel = {}
        self.gamesPlayedLabel = {}
        self.playerNameLabel = {}
        self.factionBitmap = {}
        self.slotInfoBG = {}
        self.slotInfoBGHead = {}

        self.mapPreview = MapPreview(self)
        self.mapPreview.Width:Set(size)
        self.mapPreview.Height:Set(size)
        LayoutHelpers.AtLeftTopIn(self.mapPreview, self)

        self.showAdvancedPlayerStats = showAdvancedPlayerStats or false
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

        for k, v in pairs(self.ratingLabel) do
            v:Destroy()
        end

        for k, v in pairs(self.gamesPlayedLabel) do
            v:Destroy()
        end

        for k, v in pairs(self.playerNameLabel) do
            v:Destroy()
        end

        for k, v in pairs(self.factionBitmap) do
            v:Destroy()
        end

        for k, v in pairs(self.slotInfoBG) do
            v:Destroy()
        end

        for k, v in pairs(self.slotInfoBGHead) do
            v:Destroy()
        end

        self.massmarkers = {}
        self.hydromarkers = {}
        self.startPositions = {}

        self.ratingLabel = {}
        self.gamesPlayedLabel = {}
        self.playerNameLabel = {}
        self.factionBitmap = {}
        self.slotInfoBG = {}
        self.slotInfoBGHead = {}
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
                            marker:Show()

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
            masses[i]:Show()

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
            hydros[i]:Show()

            LayoutHelpers.AtLeftTopIn(hydros[i], self.mapPreview,
                xOffset + (hydromarkers[i].position[1] / mWidth) * (self.size * xFactor)  - halfHydroIconSize,
                yOffset + (hydromarkers[i].position[3] / mHeight) * (self.size * yFactor) - halfHydroIconSize)
        end
        self.hydromarkers = hydros

        -- Add the start positions.
        local startPos = MapUtil.GetStartPositions(scenarioInfo)

        local playerArmyArray = MapUtil.GetArmies(scenarioInfo)

        local startPositions = {}


        -- get faction icons
        local factionBmps = {}
        local factionTooltips = {}

        for index, tbl in FactionData.Factions do
            factionBmps[index] = tbl.SmallIcon
            factionTooltips[index] = tbl.TooltipID
        end
        table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
        table.insert(factionTooltips, 'lob_random')

        for inSlot, army in playerArmyArray do
            local pos = startPos[army]
            local slot = inSlot

            -- Create an ACUButton for each start position.
            local marker = ACUButton(self.mapPreview, not self.buttonsDisabled)
            local markerWidth = xOffset + ((pos[1] / mWidth) * self.size * xFactor) - (marker.Width() / 2)
            local markerHeight = yOffset + ((pos[2] / mHeight) * self.size * yFactor) - (marker.Height() / 2)
            LayoutHelpers.AtLeftTopIn(marker, self.mapPreview, markerWidth, markerHeight)

            startPositions[slot] = marker

            -- TODO: Create a text box for the rating label, and position it relative to the ACUButton.
            -- The ACUButton we just made is the little icon representing the player.

            -- Create various Labels
            self.ratingLabel[slot] = UIUtil.CreateText(self.mapPreview, '', 10, 'Arial Gras', true)

            if self.showAdvancedPlayerStats == true then
                self.slotInfoBG[slot] = Bitmap(self)
                self.slotInfoBG[slot]:SetSolidColor('FF212123')
                self.slotInfoBG[slot].Width:Set(75)
                self.slotInfoBG[slot].Height:Set(50)
                self.slotInfoBG[slot]:SetAlpha(0.75)
                LayoutHelpers.AtLeftTopIn(self.slotInfoBG[slot], marker, -45, -20)
                LayoutHelpers.DepthOverParent(self.slotInfoBG[slot],self, 1)

                self.slotInfoBGHead[slot] = Bitmap(self)
                self.slotInfoBGHead[slot]:SetSolidColor('FF212123')
                self.slotInfoBGHead[slot].Width:Set(75)
                self.slotInfoBGHead[slot].Height:Set(19)
                self.slotInfoBGHead[slot]:SetAlpha(0.95)
                LayoutHelpers.AtLeftTopIn(self.slotInfoBGHead[slot], self.slotInfoBG[slot], 0, 0)
                LayoutHelpers.DepthOverParent(self.slotInfoBGHead[slot],self, 1)

                self.gamesPlayedLabel[slot] = UIUtil.CreateText(self.mapPreview, '', 10, 'Arial Gras', true)
                self.playerNameLabel[slot] = UIUtil.CreateText(self.mapPreview, '', 12, 'Arial Gras', true)
                LayoutHelpers.AtLeftTopIn(self.playerNameLabel[slot], self.slotInfoBG[slot], 20, 1)
                LayoutHelpers.AtLeftTopIn(self.gamesPlayedLabel[slot], self.slotInfoBG[slot], 2, 20)
                LayoutHelpers.AtLeftTopIn(self.ratingLabel[slot], self.slotInfoBG[slot], 2, 35)

                local bmp = Bitmap(self, UIUtil.UIFile(factionBmps[table.getn(factionBmps)]))
                self.factionBitmap[slot] = bmp
                LayoutHelpers.AtLeftTopIn(self.factionBitmap[slot], self.slotInfoBG[slot], 2, 2)
                LayoutHelpers.DepthOverParent(self.factionBitmap[slot],self, 13)

                self.slotInfoBG[slot]:Hide()
                self.slotInfoBGHead[slot]:Hide()
                self.gamesPlayedLabel[slot]:Hide()
                self.playerNameLabel[slot]:Hide()
                self.factionBitmap[slot]:Hide()
            else
                LayoutHelpers.CenteredAbove(self.ratingLabel[slot], marker, 5)
            end
        end
        self.startPositions = startPositions
    end,

    --- Update the representation of a particular player.
    -- @param slot The slot index of the player to update.
    -- @param playerInfo The player's PlayerInfo object.
    -- @param hideColours A flag indicating if the player's colour should be shown or now.
    UpdatePlayer = function(self, slot, playerInfo, hideColours)
        -- The ACUButton instance representing this slot, if any.
        local marker = self.startPositions[slot]
        
        if not marker then return end -- Marker is nil when the map slot count shrunk

        if hideColours then
            marker:SetColor("00777777")
        else
            -- If spawns are fixed, show the colour/team of the person in this slot.
            if playerInfo then
                marker:SetColor(gameColors.PlayerColors[playerInfo.PlayerColor])
                marker:SetTeam(playerInfo.Team)
            else
                marker:Clear()
            end
        end

        local rating
        local numGames
        local playerName

        playerName = playerInfo.PlayerName or ""

        local factionBmps = {}
        local factionTooltips = {}

        for index, tbl in FactionData.Factions do
            factionBmps[index] = tbl.SmallIcon
            factionTooltips[index] = tbl.TooltipID
        end

        table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
        table.insert(factionTooltips, 'lob_random')

        -- if a slot is occupied and playerstats on the preview are enabled, update stats, rating is always shown (little preview)
        if playerInfo then
            if self.showAdvancedPlayerStats == true then
                if playerInfo.Human then
                    rating = "R " .. playerInfo.PL
                    numGames = "G " .. playerInfo.NG
                else
                    rating = ""
                    numGames = ""
                end
                self.factionBitmap[slot]:SetTexture(UIUtil.UIFile(factionBmps[playerInfo.Faction], 0))
                self.playerNameLabel[slot]:SetText(playerName)
                self.gamesPlayedLabel[slot]:SetText(numGames)

                self.slotInfoBG[slot].Width:Set(self.playerNameLabel[slot].Width() + 30)
                self.slotInfoBGHead[slot].Width:Set(self.playerNameLabel[slot].Width() + 30)

                -- depending on the type of player this sets the height of the label and background according to the labels we show
                if playerInfo.Human then
                    self.slotInfoBG[slot].Height:Set(self.playerNameLabel[slot].Height()+ (self.gamesPlayedLabel[slot].Height() * 2 + 10))
                    LayoutHelpers.AtLeftTopIn(self.slotInfoBG[slot], marker, -(self.playerNameLabel[slot].Width()+10), -50)
                else
                    self.slotInfoBG[slot].Height:Set(self.playerNameLabel[slot].Height()+ 2)
                    LayoutHelpers.AtLeftTopIn(self.slotInfoBG[slot], marker, -(self.playerNameLabel[slot].Width()-10), -(self.playerNameLabel[slot].Height()+5))
                end

                self.slotInfoBG[slot]:Show()
                self.slotInfoBGHead[slot]:Show()
                self.gamesPlayedLabel[slot]:Show()
                self.playerNameLabel[slot]:Show()
                self.factionBitmap[slot]:Show()
            else
                if playerInfo.Human then
                    rating = playerInfo.PL
                else
                    rating = playerInfo.PlayerName or ""
                end
            end
        else -- if no player is present, hide all labels. Since the rating label is shown on the little preview, it doesn't get really hidden
            rating = ""
            if self.showAdvancedPlayerStats == true then
                self.slotInfoBG[slot]:Hide()
                self.slotInfoBGHead[slot]:Hide()
                self.gamesPlayedLabel[slot]:Hide()
                self.playerNameLabel[slot]:Hide()
                self.factionBitmap[slot]:Hide()
            end
        end
        self.ratingLabel[slot]:SetText(rating)
    end,

    OnDestroy = function(self)
        self.massIconPool:Destroy()
        self.hydroIconPool:Destroy()
        self.wreckageIconPool:Destroy()
        Group.OnDestroy(self)
    end,

    HideLabels = function(self, scenarioInfo)
        local startPos = MapUtil.GetStartPositions(scenarioInfo)
        local playerArmyArray = MapUtil.GetArmies(scenarioInfo)
        local startPositions = {}

        for inSlot, army in playerArmyArray do
            local slot = inSlot

            self.slotInfoBG[slot]:Hide()
            self.slotInfoBGHead[slot]:Hide()
            self.gamesPlayedLabel[slot]:Hide()
            self.playerNameLabel[slot]:Hide()
            self.factionBitmap[slot]:Hide()
            self.ratingLabel[slot]:Hide()
        end
    end,

    ShowLabels = function(self, scenarioInfo, playerOptions)
        local startPos = MapUtil.GetStartPositions(scenarioInfo)
        local playerArmyArray = MapUtil.GetArmies(scenarioInfo)
        local startPositions = {}

        for inSlot, army in playerArmyArray do
            local slot = inSlot
            if playerOptions[slot] then
                self.slotInfoBG[slot]:Show()
                self.slotInfoBGHead[slot]:Show()
                self.gamesPlayedLabel[slot]:Show()
                self.playerNameLabel[slot]:Show()
                self.factionBitmap[slot]:Show()
                self.ratingLabel[slot]:Show()
            end
        end

    end
}
