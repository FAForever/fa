--******************************************************************************************************
--** Copyright (c) 2025  Willem 'Jip' Wijnia
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
local Layouter = import("/lua/maui/layouthelpers.lua").Layouter

local Button = import("/lua/maui/button.lua").Button
local AnimatedGlow = import("/lua/ui/game/common/AnimatedGlow.lua")

---@alias UIOffScreenIndicatorDirection 'OnScreen' | 'North' | 'West' | 'East' | 'South'

---@class UIOffScreenIndicatorTextureStates
---@field Up FileName
---@field Over FileName
---@field Down FileName

---@class UIOffScreenIndicatorTextureSet
---@field North UIOffScreenIndicatorTextureStates
---@field NorthWest UIOffScreenIndicatorTextureStates
---@field West UIOffScreenIndicatorTextureStates
---@field WestSouth UIOffScreenIndicatorTextureStates
---@field South UIOffScreenIndicatorTextureStates
---@field SouthEast UIOffScreenIndicatorTextureStates
---@field East UIOffScreenIndicatorTextureStates
---@field EastNorth UIOffScreenIndicatorTextureStates
---@field Glow FileName

--- A preset set of textures for UIOffScreenIndicator that match the blue ping.
---@type UIOffScreenIndicatorTextureSet
local TexturesBlue = {
    North = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_b_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_b_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_b_down.dds' },
    NorthWest = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_bl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_bl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_bl_down.dds' },
    West = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_l_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_l_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_l_down.dds' },
    WestSouth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_tl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_tl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_tl_down.dds' },
    South = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_t_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_t_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_t_down.dds' },
    SouthEast = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_tr_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_tr_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_tr_down.dds' },
    East = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_r_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_r_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_r_down.dds' },
    EastNorth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_blue_br_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_blue_br_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_blue_br_down.dds' },
    Glow = '/textures/ui/common/game/ping_edge/ping_edge_blue_glow.dds'
}

--- A preset set of textures for UIOffScreenIndicator that match the yellow ping.
---@type UIOffScreenIndicatorTextureSet
local TexturesYellow = {
    North = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_b_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_b_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_b_down.dds' },
    NorthWest = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_bl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_bl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_bl_down.dds' },
    West = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_l_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_l_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_l_down.dds' },
    WestSouth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tl_down.dds' },
    South = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_t_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_t_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_t_down.dds' },
    SouthEast = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tr_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tr_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_tr_down.dds' },
    East = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_r_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_r_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_r_down.dds' },
    EastNorth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_yellow_br_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_yellow_br_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_yellow_br_down.dds' },
    Glow = '/textures/ui/common/game/ping_edge/ping_edge_yellow_glow.dds'
}

--- A preset set of textures for UIOffScreenIndicator that match the red ping.
---@type UIOffScreenIndicatorTextureSet
local TexturesRed = {
    North = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_b_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_b_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_b_down.dds' },
    NorthWest = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_bl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_bl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_bl_down.dds' },
    West = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_l_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_l_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_l_down.dds' },
    WestSouth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_tl_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_tl_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_tl_down.dds' },
    South = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_t_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_t_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_t_down.dds' },
    SouthEast = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_tr_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_tr_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_tr_down.dds' },
    East = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_r_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_r_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_r_down.dds' },
    EastNorth = { Up = '/textures/ui/common/game/ping_edge/ping_edge_red_br_up.dds', Over = '/textures/ui/common/game/ping_edge/ping_edge_red_br_over.dds', Down = '/textures/ui/common/game/ping_edge/ping_edge_red_br_down.dds' },
    Glow = '/textures/ui/common/game/ping_edge/ping_edge_red_glow.dds'
}

--- A utility class to help you point to events that happen off screen.
---@class UIOffScreenIndicator : Button
---@field TextureSet UIOffScreenIndicatorTextureSet
---@field Target Vector     # in world coordinates
---@field WorldView WorldView
---@field AnimatedGlow UIAnimatedGlow
OffScreenIndicator = Class(Button) {

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    ---@param worldView WorldView
    ---@param textures UIOffScreenIndicatorTextureSet
    __init = function(self, parent, worldView, textures, target)
        Button.__init(
            self, parent,
            UIUtil.UIFile(textures.North.Up),
            UIUtil.UIFile(textures.North.Down),
            UIUtil.UIFile(textures.North.Over),
            UIUtil.UIFile(textures.North.Up)
        )

        self.WorldView = worldView
        self.TextureSet = textures
        self.Target = target
        self.AnimatedGlow = AnimatedGlow.CreateAnimatedGlow(self, textures.Glow)
    end,

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self)
            :NeedsFrameUpdate(true)
            :Fill(parent)
            :End()
    end,

    --- Updates the set of textures to use for the button.
    ---@param self UIOffScreenIndicator
    ---@param textureStates UIOffScreenIndicatorTextureStates
    UpdateTextures = function(self, textureStates)
        self:SetNewTextures(
            UIUtil.UIFile(textureStates.Up),
            UIUtil.UIFile(textureStates.Down),
            UIUtil.UIFile(textureStates.Over),
            UIUtil.UIFile(textureStates.Up)
        )
    end,

    ---@param self UIOffScreenIndicator
    ---@param worldView WorldView
    ---@param screenCoordinates Vector2
    ---@return UIOffScreenIndicatorDirection    # horizontal axis
    ---@return UIOffScreenIndicatorDirection    # vertical axis
    GetDirectionToTarget = function(self, worldView, screenCoordinates)
        local horizontal = "OnScreen"
        if worldView.Left() + screenCoordinates.x < worldView.Left() then
            horizontal = "West"
        elseif screenCoordinates.x > worldView.Right() then
            horizontal = "East"
        end

        local vertical = "OnScreen"
        if worldView.Top() + screenCoordinates.y < worldView.Top() then
            vertical = "North"
        elseif screenCoordinates.y > worldView.Bottom() then
            vertical = "South"
        end

        return horizontal, vertical
    end,

    ---@param self UIOffScreenIndicator
    OnPointingOnScreen = function(self)
        -- on screen, hide it
        self:Hide()
        self:Disable()
    end,

    ---@param self UIOffScreenIndicator
    OnPointingOffScreen = function(self)
        -- off screen, show it
        self:Show()
        self:Enable()
    end,

    --- Clamps the indicator to the top of the world view, following the target horizontally.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointNorth = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.North)

        Layouter(self)
            :Top(self.WorldView.Top)
            :Left(function() return screenCoordinatesOfTarget.x - self.Width() / 2 end)
            :ResetBottom()
            :ResetRight()
            :End()

        Layouter(self.AnimatedGlow)
            :AtHorizontalCenterIn(self)
            :AtTopIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the bottom of the world view, following the target horizontally.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointSouth = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.South)

        Layouter(self)
            :Left(function() return screenCoordinatesOfTarget.x - self.Width() / 2 end)
            :Bottom(self.WorldView.Bottom)
            :ResetTop()
            :ResetRight()
            :End()

        Layouter(self.AnimatedGlow)
            :AtHorizontalCenterIn(self)
            :AtBottomIn(self, -10)
            :ResetTop()
            :ResetRight()
            :End()
    end,

    --- Clamps the indicator to the right of the world view, following the target vertically.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointEast = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.East)

        Layouter(self)
            :Right(self.WorldView.Right)
            :Top(function() return screenCoordinatesOfTarget.y - self.Height() / 2 end)
            :ResetBottom()
            :ResetLeft()
            :End()

        Layouter(self.AnimatedGlow)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, -10)
            :ResetLeft()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the left of the world view, following the target vertically.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointWest = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.West)

        Layouter(self)
            :Left(self.WorldView.Left)
            :Top(function() return screenCoordinatesOfTarget.y - self.Height() / 2 end)
            :ResetBottom()
            :ResetRight()
            :End()

        Layouter(self.AnimatedGlow)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the top left corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointNorthWest = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.NorthWest)

        Layouter(self)
            :Top(self.WorldView.Top)
            :Left(self.WorldView.Left)
            :ResetBottom()
            :ResetRight()
            :End()

        Layouter(self.AnimatedGlow)
            :AtTopIn(self, -10)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the top right corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointNorthEast = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.EastNorth)

        Layouter(self)
            :Top(self.WorldView.Top)
            :Right(self.WorldView.Right)
            :ResetBottom()
            :ResetLeft()
            :End()

        Layouter(self.AnimatedGlow)
            :AtTopIn(self, -10)
            :AtRightIn(self, -10)
            :ResetLeft()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the bottom left corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointSouthWest = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.WestSouth)

        Layouter(self)
            :Bottom(self.WorldView.Bottom)
            :Left(self.WorldView.Left)
            :ResetTop()
            :ResetRight()
            :End()

        Layouter(self.AnimatedGlow)
            :AtBottomIn(self, -10)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetTop()
            :End()
    end,

    --- Clamps the indicator to the bottom right corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param screenCoordinatesOfTarget Vector2
    PointSouthEast = function(self, screenCoordinatesOfTarget)
        self:UpdateTextures(self.TextureSet.SouthEast)

        Layouter(self)
            :Bottom(self.WorldView.Bottom)
            :Right(self.WorldView.Right)
            :ResetTop()
            :ResetLeft()
            :End()

        Layouter(self.AnimatedGlow)
            :AtBottomIn(self, -10)
            :AtRightIn(self, -10)
            :ResetLeft()
            :ResetTop()
            :End()
    end,

    --- Updates the direction of the off screen indicator. If the target is on screen, the indicator is hidden.
    ---@param self UIOffScreenIndicator
    UpdateDirection = function(self)
        local screenCoordinatesOfTarget = self.WorldView:Project(self.Target)
        local dirHorizontal, dirVertical = self:GetDirectionToTarget(self.WorldView, screenCoordinatesOfTarget)
        if dirHorizontal == 'OnScreen' and dirVertical == 'OnScreen' then
            self:OnPointingOnScreen()
        else
            self:OnPointingOffScreen()
            -- determine what textures to show
            if dirHorizontal == 'OnScreen' and dirVertical == 'North' then
                self:PointNorth(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'OnScreen' and dirVertical == 'South' then
                self:PointSouth(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'West' and dirVertical == 'OnScreen' then
                self:PointWest(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'East' and dirVertical == 'OnScreen' then
                self:PointEast(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'West' and dirVertical == 'North' then
                self:PointNorthWest(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'East' and dirVertical == 'North' then
                self:PointNorthEast(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'West' and dirVertical == 'South' then
                self:PointSouthWest(screenCoordinatesOfTarget)
            elseif dirHorizontal == 'East' and dirVertical == 'South' then
                self:PointSouthEast(screenCoordinatesOfTarget)
            end
        end
    end,

    ---@param self UIOffScreenIndicator
    OnFrame = function(self, delta)
        self:UpdateDirection()
    end,

    ---@param self UIOffScreenIndicator
    OnClick = function(self)
        local currentCamSettings = GetCamera('WorldCamera'):SaveSettings()
        currentCamSettings.Focus = self.Target
        GetCamera(self.WorldView._cameraName):RestoreSettings(currentCamSettings)
    end,
}

---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffScreenIndicator
CreateYellowOffScreenIndicator = function(parent, worldView, target)
    local indicator = OffScreenIndicator(parent, worldView, TexturesYellow, target) --[[@as UIOffScreenIndicator]]
    return indicator
end

---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffScreenIndicator
CreateBlueOffScreenIndicator = function(parent, worldView, target)
    local indicator = OffScreenIndicator(parent, worldView, TexturesBlue, target) --[[@as UIOffScreenIndicator]]
    return indicator
end

---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffScreenIndicator
CreateRedOffScreenIndicator = function(parent, worldView, target)
    local indicator = OffScreenIndicator(parent, worldView, TexturesRed, target) --[[@as UIOffScreenIndicator]]
    return indicator
end

---@param parent Control
---@param worldView WorldView
---@param textures UIOffScreenIndicatorTextureSet
---@param target Vector # in world coordinates
---@return UIOffScreenIndicator
CreateOffScreenIndicator = function(parent, worldView, textures, target)
    local indicator = OffScreenIndicator(parent, worldView, textures, target) --[[@as UIOffScreenIndicator]]
    return indicator
end
