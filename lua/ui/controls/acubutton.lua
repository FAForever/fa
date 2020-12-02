local UIUtil = import('/lua/ui/uiutil.lua')
local Group = import('/lua/maui/group.lua').Group
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Text = import('/lua/maui/text.lua').Text
local Button = import('/lua/maui/button.lua').Button

local teamIcons = {
    '/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
    '/lobby/team_icons/team_5_icon.dds',
    '/lobby/team_icons/team_6_icon.dds',
}

--- A small button representing an ACU, with support for showing colour and team affiliation, with
-- an exciting pulsating blue mouse-over effect.
ACUButton = Class(Group) {
    __init = function(self, parent, enabled)
        Group.__init(self, parent)
        LayoutHelpers.SetDimensions(self, 8, 10)

        self.enabled = enabled

        -- Provides the solid-colour filling of the little ACU. Default transparent.
        local colourBmp = Bitmap(self)
        LayoutHelpers.SetDimensions(colourBmp, 8, 10)
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

            self:OnRollover(state)
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
        indicator.Play = function(this)
            if not self:IsEnabled() then
                return
            end
            this:SetAlpha(1)
            this:Show()
            this:SetNeedsFrameUpdate(true)
            this.time = 0
            this.OnFrame = function(control, time)
                control.time = control.time + (time*4)
                control:SetAlpha(MATH_Lerp(math.sin(control.time), -.5, .5, 0.3, 0.5))
            end
        end
        indicator.Stop = function(this)
            if not self:IsEnabled() then
                return
            end
            this:SetAlpha(0)
            this:Hide()
            this:SetNeedsFrameUpdate(false)
        end

        self.indicator = indicator

        self.OnHide = function(self, hidden)
            self.markerOverlay:SetHidden(hidden)
            self.marker:SetHidden(hidden)
            self.teamIndicator:SetHidden(hidden)
            if self.textOverlay then
                self.textOverlay:SetHidden(hidden)
            end
            return true
        end
    end,

    --- Returns true if the control is enabled.
    IsEnabled = function(self)
        return self.enabled
    end,

    --- Set the enabledness of the control to the given value.
    --
    -- @param enabled Should the control be enabled?
    SetEnabled = function(self, enabled)
        self.enabled = enabled
    end,

    --- Set the colour of the control to the given value.
    --
    -- @param color New colour for the ACU icon.
    SetColor = function(self, color)
        self.marker:SetSolidColor(color)
    end,

    --- Clear all data from the control, returning it to the "teamless, translucent" state.
    Clear = function(self)
        self:SetColor('00777777')
        self:SetTeam(1)
    end,

    --- Set the team for the control: team is displayed as a small white number to the bottom right
    -- of the ACU icon
    --
    -- @param team A value one greater than the team value to display. A value of 1 represents "no
    --             team".
    SetTeam = function(self, team)
        if team == 1 then
            self.teamIndicator:SetSolidColor("00000000")
        else
            self.teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[team]))
        end
    end,

    --- Set if the control should represent a "closed" slot. A closed slot is represented with a red
    -- X drawn over the ACU icon
    --
    -- @param Should this UI element represent a closed slot?
    SetClosed = function(self, closed)
        -- Opening the slot is a simple matter of deleting the "X".
        self:RemoveTextOverlay()

        if not closed then
            return
        end

        -- Closing the slot requires clearing other data set on this button.
        -- Remove any assigned colour and team.
        self:Clear()

        -- Put the little red "X" over the little ACU.
        self:draw("Crimson","X")
    end,

    --- Set if the control should represent a "closed - spawn mex" slot. A closed - spawn mex slot is represented with a green
    -- X drawn over the ACU icon
    SetClosedSpawnMex = function(self)
        self:RemoveTextOverlay()

        -- Closing the slot requires clearing other data set on this button.
        -- Remove any assigned colour and team.
        self:Clear()

        -- Put the little green "X" over the little ACU.
        self:draw("2c7f33", "O")
    end,

    draw = function(self, color, text)
        local textOverlay = Text(self)
        textOverlay:SetFont(UIUtil.bodyFont, 20)
        textOverlay:SetColor(color)
        textOverlay:SetText(text)
        LayoutHelpers.AtCenterIn(textOverlay, self)

        self.textOverlay = textOverlay
    end,

    RemoveTextOverlay = function(self)
        if self.textOverlay then
            self.textOverlay:Destroy()
            self.textOverlay = nil
        end
    end,

    -- Override for events...
    --- Called when the button is clicked.
    OnClick = function(self) end,

    --- Called when the button is right-clicked.
    OnRightClick = function(self) end,

    OnRollover = function(self, state) end,
}
