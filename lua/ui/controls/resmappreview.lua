local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button
local TexturePool = import('/lua/ui/texturepool.lua').TexturePool

-- The default size of the mass/hydrocarbon icons
local DEFAULT_HYDROCARBON_ICON_SIZE = 14
local DEFAULT_MASS_ICON_SIZE = 10

-- UI control to show a preview image of a map.
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

        self.Width:Set(size)
        self.Height:Set(size)

        self.mapPreview = MapPreview(self)
        self.mapPreview.Width:Set(size)
        self.mapPreview.Height:Set(size)
        LayoutHelpers.AtLeftTopIn(self.mapPreview, self)
    end,

    -- Discard all resource markers
    DestroyResourceMarkers = function(self)
        for k, v in pairs(self.massmarkers) do
            self.massIconPool:Dispose(v)
        end

        for k, v in pairs(self.hydromarkers) do
            self.hydroIconPool:Dispose(v)
        end

        for k, v in pairs(self.startPositions) do
            v:Destroy()
        end

        self.massmarkers = nil
        self.hydromarkers = nil
        self.startPositions = nil
    end,

    Clear = function(self)
        self:DestroyResourceMarkers()
        self.mapPreview:Destroy()
    end,

    -- Update the control with a named scenario file.
    SetScenarioFromFile = function(self, scenarioFile)
        self:SetScenario(MapUtil.LoadScenario(scenarioFile))
    end,

    -- Update the control to reflect a new Scenario.
    SetScenario = function(self, scenarioInfo)
        if self.massmarkers then
            self:DestroyResourceMarkers()
        end

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

local teamIcons = {
    '/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
    '/lobby/team_icons/team_5_icon.dds',
    '/lobby/team_icons/team_6_icon.dds',
}

-- A small button representing an ACU, with support for showing colour and team affiliation.
ACUButton = Class(Group) {
    __init = function(self, parent, enabled)
        Group.__init(self, parent)
        self.Height:Set(10)
        self.Width:Set(8)

        self.enabled = enabled

        -- Provides the solid-colour filling of the little ACU. Default transparent.
        local colourBmp = Bitmap(self)
        colourBmp.Height:Set(10)
        colourBmp.Width:Set(8)
        colourBmp:SetSolidColor('00777777')
        LayoutHelpers.AtLeftTopIn(colourBmp, self)

        self.marker = colourBmp

        -- Team number display, if any. Defaults to invisible.
        local teamIndicator = Bitmap(colourBmp)
        LayoutHelpers.AnchorToRight(teamIndicator, colourBmp, 1)
        LayoutHelpers.AtTopIn(teamIndicator, colourBmp, 5)
        teamIndicator:DisableHitTest()
        self.teamIndicator = teamIndicator

        -- The little ACU image.
        local buttonImage = UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds')
        local markerOverlay = Button(colourBmp, buttonImage, buttonImage, buttonImage, buttonImage)
        LayoutHelpers.AtCenterIn(markerOverlay, colourBmp)
        markerOverlay.OnClick = function(this, modifiers)
            if not self:IsEnabled() then
                return
            end

            if modifiers.Left then
                self:OnClick()
            elseif modifiers.Right then
                self:OnRightClick()
            end
        end

        markerOverlay.OnRolloverEvent = function(this, state)
            -- Don't respond to events if the control is disabled.
            if not self:IsEnabled() then
                return
            end

            if state == "enter" then
                self.indicator:Play()
            elseif state == "exit" then
                self.indicator:Stop()
            end
        end
        self.markerOverlay = markerOverlay

        -- The exciting blue "Quantum gate" mouse-over graphic thing. That *pulsates*.
        local indicator = Bitmap(self, UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
        LayoutHelpers.AtCenterIn(indicator, colourBmp)
        indicator.Height:Set(function() return indicator.BitmapHeight() * .3 end)
        indicator.Width:Set(function() return indicator.BitmapWidth() * .3 end)
        indicator.Depth:Set(function() return colourBmp.Depth() - 1 end)
        indicator:Hide()
        indicator:DisableHitTest()
        indicator.Play = function(self)
            self:SetAlpha(1)
            self:Show()
            self:SetNeedsFrameUpdate(true)
            self.time = 0
            self.OnFrame = function(control, time)
                control.time = control.time + (time*4)
                control:SetAlpha(MATH_Lerp(math.sin(control.time), -.5, .5, 0.3, 0.5))
            end
        end
        indicator.Stop = function(self)
            self:SetAlpha(0)
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end

        self.indicator = indicator

        self.OnHide = function(self, hidden)
            self.markerOverlay:SetHidden(hidden)
            self.marker:SetHidden(hidden)
            self.teamIndicator:SetHidden(hidden)
            return true
        end
    end,

    IsEnabled = function(self)
        return self.enabled
    end,

    SetEnabled = function(self, enabled)
        self.enabled = enabled
    end,

    SetColor = function(self, color)
        self.marker:SetSolidColor(color)
    end,

    Clear = function(self)
        self:SetColor('00777777')
        self:SetTeam(1)
    end,

    SetTeam = function(self, team)
        if team == 1 then
            self.teamIndicator:SetSolidColor("00000000")
        else
            self.teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[team]))
        end
    end,

    SetClosed = function(self, closed)
        -- Opening the slot is a simple matter of deleting the "X".
        if not closed then
            if self.textOverlay then
                self.textOverlay:Destroy()
                self.textOverlay = nil
            end

            return
        end

        -- Closing the slot requires clearing other data set on this button.
        -- Remove any assigned colour and team.
        self:Clear()

        -- Put the little red "X" over the little ACU.
        local textOverlay = Text(self)
        textOverlay:SetFont(UIUtil.bodyFont, 14)
        textOverlay:SetColor("Crimson")
        textOverlay:SetText("X")
        LayoutHelpers.AtCenterIn(textOverlay, self)

        self.textOverlay = textOverlay
    end,

    -- Override for events...
    OnClick = function(self) end,
    OnRightClick = function(self) end
}
