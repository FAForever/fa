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
local ReusedLayoutFor = import("/lua/maui/layouthelpers.lua").ReusedLayoutFor

local Button = import("/lua/maui/button.lua").Button
local AnimatedGlow = import("/lua/ui/game/common/animatedglow.lua")

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

--- A utility function to help create a preset. It assumes that all files end with:
---
--- - <direction>_<state>.dds
---
--- Where:
--- - <direction> is the direction of the image. It can be `b`, `bl`, `l`, `tl`, `t`, `tr`, `r` or `br`
--- - <state> is the button state. It can be `up`, `over` or `down`
--- 
--- As an example of a preset:
---
--- ```lua
--- GeneratePathForPreset('/textures/ui/common/game/ping_edge/ping_edge_blue_')
--- ```
--- 
--- Will generate the following paths:
---
--- - '/textures/ui/common/game/ping_edge/ping_edge_blue_b_up.dds', 
--- - '/textures/ui/common/game/ping_edge/ping_edge_blue_b_over.dds'
--- - '/textures/ui/common/game/ping_edge/ping_edge_blue_b_down.dds'
---
--- Which it will pack up so that a screen indicator can use them.
---@param filename FileName     # As an example, /textures/ui/common/game/ping_edge/ping_edge_blue_
---@return UIOffScreenIndicatorTextureSet
function GeneratePreset(filename)
    ---@type UIOffScreenIndicatorTextureSet
    local preset = {
        North = { Up = filename .. 'b_up.dds', Over = filename .. 'b_over.dds', Down = filename .. 'b_down.dds' },
        NorthWest = { Up = filename .. 'bl_up.dds', Over = filename .. 'bl_over.dds', Down = filename .. 'bl_down.dds' },
        West = { Up = filename .. 'l_up.dds', Over = filename .. 'l_over.dds', Down = filename .. 'l_down.dds' },
        WestSouth = { Up = filename .. 'tl_up.dds', Over = filename .. 'tl_over.dds', Down = filename .. 'tl_down.dds' },
        South = { Up = filename .. 't_up.dds', Over = filename .. 't_over.dds', Down = filename .. 't_down.dds' },
        SouthEast = { Up = filename .. 'tr_up.dds', Over = filename .. 'tr_over.dds', Down = filename .. 'tr_down.dds' },
        East = { Up = filename .. 'r_up.dds', Over = filename .. 'r_over.dds', Down = filename .. 'r_down.dds' },
        EastNorth = { Up = filename .. 'br_up.dds', Over = filename .. 'br_over.dds', Down = filename .. 'br_down.dds' },
        Glow = filename .. 'glow.dds'
    }

    return preset
end


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
        self.AnimatedGlow = AnimatedGlow.CreateAnimatedGlow(self, textures.Glow, 10)
    end,

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    __post_init = function(self, parent)

        -- to be overwritten by subclass
        ReusedLayoutFor(self)
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
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    ---@return UIOffScreenIndicatorDirection    # horizontal axis
    ---@return UIOffScreenIndicatorDirection    # vertical axis
    GetDirectionToTarget = function(self, worldView, controlSpaceCoordinates)
        local horizontal = "OnScreen"
        if controlSpaceCoordinates.x < 0.5 * self.Width() then
            horizontal = "West"
        elseif controlSpaceCoordinates.x > worldView.Width() - 0.5 * self.Width() then
            horizontal = "East"
        end

        local vertical = "OnScreen"
        if controlSpaceCoordinates.y < 0.5 * self.Height() then
            vertical = "North"
        elseif controlSpaceCoordinates.y > worldView.Height() - 0.5 * self.Height() then
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
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointNorth = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.North)

        ReusedLayoutFor(self)
            :Top(self.WorldView.Top)
            :Left(function() return self.WorldView.Left() + controlSpaceCoordinates.x - self.Width() * 0.5 end)
            :ResetBottom()
            :ResetRight()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtHorizontalCenterIn(self)
            :AtTopIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the bottom of the world view, following the target horizontally.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointSouth = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.South)

        ReusedLayoutFor(self)
            :Left(function() return self.WorldView.Left() + controlSpaceCoordinates.x - self.Width() / 2 end)
            :Bottom(self.WorldView.Bottom)
            :ResetTop()
            :ResetRight()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtHorizontalCenterIn(self)
            :AtBottomIn(self, -10)
            :ResetTop()
            :ResetRight()
            :End()
    end,

    --- Clamps the indicator to the right of the world view, following the target vertically.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointEast = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.East)

        ReusedLayoutFor(self)
            :AnchorToRight(self)
            :Top(function() return self.WorldView.Top() + controlSpaceCoordinates.y - self.Height() / 2 end)
            :ResetBottom()
            :ResetLeft()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtVerticalCenterIn(self)
            :AtRightIn(self, -10)
            :ResetLeft()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the left of the world view, following the target vertically.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointWest = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.West)

        ReusedLayoutFor(self)
            :Left(self.WorldView.Left)
            :Top(function() return self.WorldView.Top() + controlSpaceCoordinates.y - self.Height() / 2 end)
            :ResetBottom()
            :ResetRight()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtVerticalCenterIn(self)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the top left corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointNorthWest = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.NorthWest)

        ReusedLayoutFor(self)
            :Top(self.WorldView.Top)
            :Left(self.WorldView.Left)
            :ResetBottom()
            :ResetRight()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtTopIn(self, -10)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the top right corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointNorthEast = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.EastNorth)

        ReusedLayoutFor(self)
            :Top(self.WorldView.Top)
            :Right(self.WorldView.Right)
            :ResetBottom()
            :ResetLeft()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtTopIn(self, -10)
            :AtRightIn(self, -10)
            :ResetLeft()
            :ResetBottom()
            :End()
    end,

    --- Clamps the indicator to the bottom left corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointSouthWest = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.WestSouth)

        ReusedLayoutFor(self)
            :Bottom(self.WorldView.Bottom)
            :Left(self.WorldView.Left)
            :ResetTop()
            :ResetRight()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
            :AtBottomIn(self, -10)
            :AtLeftIn(self, -10)
            :ResetRight()
            :ResetTop()
            :End()
    end,

    --- Clamps the indicator to the bottom right corner of the world view.
    ---@param self UIOffScreenIndicator
    ---@param controlSpaceCoordinates Vector2   # control space coordinates
    PointSouthEast = function(self, controlSpaceCoordinates)
        self:UpdateTextures(self.TextureSet.SouthEast)

        ReusedLayoutFor(self)
            :Bottom(self.WorldView.Bottom)
            :Right(self.WorldView.Right)
            :ResetTop()
            :ResetLeft()
            :End()

        ReusedLayoutFor(self.AnimatedGlow)
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
        local controlSpaceCoordinates = self.WorldView:Project(target)
        local dirHorizontal, dirVertical = self:GetDirectionToTarget(self.WorldView, controlSpaceCoordinates)
        if dirHorizontal == 'OnScreen' and dirVertical == 'OnScreen' then
            self:OnPointingOnScreen()
        else
            self:OnPointingOffScreen()
            -- determine what textures to show
            if dirHorizontal == 'OnScreen' and dirVertical == 'North' then
                self:PointNorth(controlSpaceCoordinates)
            elseif dirHorizontal == 'OnScreen' and dirVertical == 'South' then
                self:PointSouth(controlSpaceCoordinates)
            elseif dirHorizontal == 'West' and dirVertical == 'OnScreen' then
                self:PointWest(controlSpaceCoordinates)
            elseif dirHorizontal == 'East' and dirVertical == 'OnScreen' then
                self:PointEast(controlSpaceCoordinates)
            elseif dirHorizontal == 'West' and dirVertical == 'North' then
                self:PointNorthWest(controlSpaceCoordinates)
            elseif dirHorizontal == 'East' and dirVertical == 'North' then
                self:PointNorthEast(controlSpaceCoordinates)
            elseif dirHorizontal == 'West' and dirVertical == 'South' then
                self:PointSouthWest(controlSpaceCoordinates)
            elseif dirHorizontal == 'East' and dirVertical == 'South' then
                self:PointSouthEast(controlSpaceCoordinates)
            end
        end
    end,
}
