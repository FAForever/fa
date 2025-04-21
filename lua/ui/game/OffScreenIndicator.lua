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

--- A utility class to help you point to events that happen off screen. This is an abstract class, it won't do anything on its own.
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
    __init = function(self, parent, worldView, textures)
        Button.__init(
            self, parent,
            UIUtil.UIFile(textures.North.Up),
            UIUtil.UIFile(textures.North.Down),
            UIUtil.UIFile(textures.North.Over),
            UIUtil.UIFile(textures.North.Up)
        )

        self.WorldView = worldView
        self.TextureSet = textures
        self.AnimatedGlow = AnimatedGlow.CreateAnimatedGlow(self, textures.Glow)
    end,

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    __post_init = function(self, parent)

        -- to be overwritten by subclass
        Layouter(self)
            :Fill(parent)
            :End()
    end,

    --- Retrieves the target location of the indicator.
    ---@param self UIOffScreenIndicator
    ---@return Vector
    GetTarget = function(self)

        -- to be overwritten by subclass
        return { 0, 0, 0 }
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
        local target = self:GetTarget()
        local screenCoordinatesOfTarget = self.WorldView:Project(target)
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
}
