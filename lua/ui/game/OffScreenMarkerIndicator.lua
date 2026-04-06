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

local OffScreenIndicatorModule = import("/lua/ui/game/offscreenindicator.lua")
local OffScreenIndicator = import("/lua/ui/game/offscreenindicator.lua").OffScreenIndicator

--- A preset set of textures for UIOffScreenIndicator that match the blue ping.
---@type UIOffScreenIndicatorTextureSet
local PresetForBluePing = OffScreenIndicatorModule.GeneratePreset('/textures/ui/common/game/ping_edge/ping_edge_blue_')

--- A preset set of textures for UIOffScreenIndicator that match the yellow ping.
---@type UIOffScreenIndicatorTextureSet
local PresetForYellowPing = OffScreenIndicatorModule.GeneratePreset('/textures/ui/common/game/ping_edge/ping_edge_yellow_')

--- A preset set of textures for UIOffScreenIndicator that match the red ping.
---@type UIOffScreenIndicatorTextureSet
local PresetForRedPing = OffScreenIndicatorModule.GeneratePreset('/textures/ui/common/game/ping_edge/ping_edge_red_')

--- All available texture presets. To register a new preset you can add an entry to this table.
local TexturePresets = {
    Blue = PresetForBluePing,
    Red = PresetForRedPing,
    Yellow = PresetForYellowPing
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
        -- feature: click to navigate to the ping
        local currentCamSettings = GetCamera('WorldCamera'):SaveSettings()
        currentCamSettings.Focus = self:GetTarget()
        GetCamera(self.WorldView._cameraName):RestoreSettings(currentCamSettings)
    end,
}

--- Creates an off screen marker for the target position. Textures originate from a preset.
---@param parent Control
---@param worldView WorldView
---@param preset 'Yellow' | 'Blue' | 'Red'
---@param target Vector     # in world coordinates
---@return UIOffscreenMarkerIndicator
CreateOffScreenMarkerIndicatorFromPreset = function(parent, worldView, target, preset)
    local texturePreset = TexturePresets[preset]
    if not texturePreset then
        WARN(string.format("Invalid texture preset for off screen marker indicator: %s. Defaulting to the yellow preset", preset))
        texturePreset = TexturePresets.Yellow
    end

    local indicator = OffscreenMarkerIndicator(parent, worldView, texturePreset, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end

--- Creates an off screen marker for the target position.
---@param parent Control
---@param worldView WorldView
---@param textures UIOffScreenIndicatorTextureSet
---@param target Vector     # in world coordinates
---@return UIOffscreenMarkerIndicator
CreateOffScreenMarkerIndicator = function(parent, worldView, textures, target)
    local indicator = OffscreenMarkerIndicator(parent, worldView, TexturesRed, target) --[[@as UIOffscreenMarkerIndicator]]
    return indicator
end
