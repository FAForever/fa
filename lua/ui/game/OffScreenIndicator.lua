--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Button = import("/lua/maui/button.lua").Button
local AnimatedGlow = import("/lua/ui/game/common/AnimatedGlow.lua")

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
        LayoutHelpers.LayoutFor(self)
            :NeedsFrameUpdate(true)
            :Fill(parent)
            :End()
    end,

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
    OnFrame = function(self, delta)
        local worldView = self.WorldView
        local coords = worldView:Project(self.Target)

        -- figure out horizontal positioning
        local horizontal = "None"
        if worldView.Left() + coords.x < worldView.Left() then
            horizontal = "West"
            self.Left:Set(worldView.Left)
            LayoutHelpers.AtLeftIn(self.AnimatedGlow, self, -10)
            LayoutHelpers.ResetRight(self.AnimatedGlow)
            LayoutHelpers.ResetRight(self)
        elseif coords.x > worldView.Right() then
            horizontal = "East"
            self.Right:Set(worldView.Right)
            LayoutHelpers.AtRightIn(self.AnimatedGlow, self, -10)
            LayoutHelpers.ResetLeft(self.AnimatedGlow)
            LayoutHelpers.ResetLeft(self)
        else
            horizontal = "None"
            self.Left:Set(function() return coords.x - self.Width() / 2 end)
            LayoutHelpers.AtHorizontalCenterIn(self.AnimatedGlow, self)
            LayoutHelpers.ResetRight(self.AnimatedGlow)
            LayoutHelpers.ResetRight(self)
        end

        -- figure out vertical positioning
        local vertical = 'None'
        if worldView.Top() + coords.y > worldView.Bottom() then
            vertical = 'South'
            self.Bottom:Set(worldView.Bottom)
            LayoutHelpers.AtBottomIn(self.AnimatedGlow, self, -10)
            LayoutHelpers.ResetTop(self.AnimatedGlow)
            LayoutHelpers.ResetTop(self)
        elseif coords.y < worldView.Top() then
            vertical = 'North'
            self.Top:Set(worldView.Top)
            LayoutHelpers.AtTopIn(self.AnimatedGlow, self, -10)
            LayoutHelpers.ResetBottom(self.AnimatedGlow)
            LayoutHelpers.ResetBottom(self)
        else
            vertical = 'None'
            self.Top:Set(function() return coords.y - self.Height() / 2 end)
            LayoutHelpers.AtVerticalCenterIn(self.AnimatedGlow, self)
            LayoutHelpers.ResetBottom(self.AnimatedGlow)
            LayoutHelpers.ResetBottom(self)
        end

        if horizontal == 'None' and vertical == 'None' then
            -- on screen, hide it
            self:Hide()
            self:Disable()

        else
            -- off screen, show it
            self:Show()
            self:Enable()

            -- determine what textures to show
            if horizontal == 'None' and vertical == 'North' then
                self:UpdateTextures(self.TextureSet.North)
            elseif horizontal == 'None' and vertical == 'South' then
                self:UpdateTextures(self.TextureSet.South)
            elseif horizontal == 'West' and vertical == 'None' then
                self:UpdateTextures(self.TextureSet.West)
            elseif horizontal == 'East' and vertical == 'None' then
                self:UpdateTextures(self.TextureSet.East)
            elseif horizontal == 'West' and vertical == 'North' then
                self:UpdateTextures(self.TextureSet.NorthWest)
            elseif horizontal == 'East' and vertical == 'North' then
                self:UpdateTextures(self.TextureSet.EastNorth)
            elseif horizontal == 'West' and vertical == 'South' then
                self:UpdateTextures(self.TextureSet.WestSouth)
            elseif horizontal == 'East' and vertical == 'South' then
                self:UpdateTextures(self.TextureSet.SouthEast)
            end
        end
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
