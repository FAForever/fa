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

local Layouter = import("/lua/maui/layouthelpers.lua").Layouter

local OffScreenIndicator = import("/lua/ui/game/OffScreenIndicator.lua").OffScreenIndicator

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

--- An off screen indicator for markers to help users be aware of them.
---@class UIOffscreenMarkerIndicator : UIOffScreenIndicator
---@field Target Vector     # in world coordinates
OffscreenMarkerIndicator = Class(OffScreenIndicator) {

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    ---@param worldView WorldView
    ---@param textures UIOffScreenIndicatorTextureSet
    __init = function(self, parent, worldView, textures, target)
        OffScreenIndicator.__init(
            self, parent, worldView, textures
        )

        self.Target = target
    end,

    ---@param self UIOffScreenIndicator
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self)
            :NeedsFrameUpdate(true)
            :Fill(parent)
            :End()
    end,

    --- Returns the world position of the marker.
    ---@param self UIOffscreenMarkerIndicator
    ---@return Vector
    GetTarget = function(self)
        return self.Target
    end,

    ---@param self UIOffScreenIndicator
    OnFrame = function(self, delta)
        self:UpdateDirection()
    end,

    ---@param self UIOffScreenIndicator
    OnClick = function(self)
        local currentCamSettings = GetCamera('WorldCamera'):SaveSettings()
        currentCamSettings.Focus = self:GetTarget()
        GetCamera(self.WorldView._cameraName):RestoreSettings(currentCamSettings)
    end,
}

--- Creates an off screen marker for the target position. Uses a texture preset that matches with the yellow ping.
---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffScreenIndicator
CreateYellowOffScreenMarkerIndicator = function(parent, worldView, target)
    local indicator = OffscreenMarkerIndicator(parent, worldView, TexturesYellow, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end

--- Creates an off screen marker for the target position. Uses a texture preset that matches with the blue ping.
---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffscreenMarkerIndicator
CreateBlueOffScreenMarkerIndicator = function(parent, worldView, target)
    local indicator = OffscreenMarkerIndicator(parent, worldView, TexturesBlue, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end

--- Creates an off screen marker for the target position. Uses a texture preset that matches with the red ping.
---@param parent Control
---@param worldView WorldView
---@param target Vector # in world coordinates
---@return UIOffscreenMarkerIndicator
CreateRedOffScreenMarkerIndicator = function(parent, worldView, target)
    local indicator = OffscreenMarkerIndicator(parent, worldView, TexturesRed, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end

--- Creates an off screen marker for the target position.
---@param parent Control
---@param worldView WorldView
---@param textures UIOffScreenIndicatorTextureSet
---@param target Vector # in world coordinates
---@return UIOffscreenMarkerIndicator
CreateOffScreenMarkerIndicator = function(parent, worldView, textures, target)
    local indicator = OffscreenMarkerIndicator(parent, worldView, TexturesRed, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end