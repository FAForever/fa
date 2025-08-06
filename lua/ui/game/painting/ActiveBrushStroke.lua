--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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

local ColorUtils = import("/lua/shared/color.lua")
local BrushStroke = import('/lua/ui/game/painting/BrushStroke.lua').BrushStroke

--- Responsible for managing a painting that is actively being worked on.
---@class UIActiveBrushStroke : UIBrushStroke
---@field LastEdited number
---@field LastSample? Vector
---@field CurrentSample? Vector
ActiveBrushStroke = ClassUI(BrushStroke) {

    DebounceTimeThreshold = 0.016, -- About 60 fps

    ---@param self UIActiveBrushStroke
    ---@param color Color
    __init = function(self, color)
        BrushStroke.__init(self, { CoordinatesX = {}, CoordinatesY = {}, CoordinatesZ = {} }, color)

        self.LastEdited = CurrentTime()
    end,

    ---@param self UIBrushStroke
    ---@param color Color
    ---@return Color
    ComputePreviewColor = function(self, color)
        -- get color channel values, default to white
        local r, g, b, a = ColorUtils.ParseColor(color)
        if not (r and g and b) then
            r = 1.0
            g = 1.0
            b = 1.0
        end

        -- compute transparency
        a = 0.4

        return ColorUtils.ColorRGB(r, g, b, a)
    end,

    --- Renders the brush stroke.
    ---@param self UIActiveBrushStroke
    ---@param delta number
    OnRender = function (self, delta)
        BrushStroke.OnRender(self, delta)

        local brushWidth = self:GetBrushWidth()

        -- feature: draw a line between the last sample and the current sample
        if self.LastSample and self.CurrentSample then
            local previewColor = self:ComputePreviewColor(self.Color)
            UI_DrawLine(self.LastSample, self.CurrentSample, previewColor, brushWidth)
        end
    end,

    ---@param self UIBrushStroke
    ---@param color Color
    ---@param progress number   # number between 0 and 1.0
    ---@return Color
    ComputeDecayedColor = function(self, color, progress)
        -- The active brush stroke does not decay.

        return color
    end,

    ---------------------------------------------------------------------------
    --#region Creation of samples interface

    --- Computes the debounce distance based on the current zoom level.
    ---@param self UIActiveBrushStroke
    ---@param sample Vector
    ---@return number
    GetDebounceDistance = function(self, sample)
        local worldViewManager = import("/lua/ui/game/worldview.lua")

        local minimumDistance = 1

        -- feature: increase debounce distance as we zoom out
        local mouseScreenCoordinates = GetMouseScreenPos()
        local worldView = worldViewManager.GetTopmostWorldViewAt(mouseScreenCoordinates[1], mouseScreenCoordinates[2])
        if worldView then
            local camera = GetCamera(worldView._cameraName)
            if camera then
                local zoom = camera:GetZoom()
                minimumDistance = math.max(1, 0.020 * zoom)
            end
        end

        -- feature: decrease debounce distance as we bend the curve
        -- reduce the debounce distance based on the angle between the last segment and the
        -- current segment that we're trying to make. This provides more resolution on a curvy
        -- line then on a straight line.
        local count = table.getn(self.Samples.CoordinatesX)
        if count > 2 then
            local samples = self.Samples
            local x0 = samples.CoordinatesX[count - 1]
            local y0 = samples.CoordinatesY[count - 1]
            local z0 = samples.CoordinatesZ[count - 1]
            local x1 = samples.CoordinatesX[count - 0]
            local y1 = samples.CoordinatesY[count - 0]
            local z1 = samples.CoordinatesZ[count - 0]

            -- a number between 0.1 and 1.0
            local radians = math.max(0.1, self:CurvatureOfSegments(x0, y0, z0, x1, y1, z1, sample[1], sample[2], sample[3]))

            -- triple square root curve allows us to quickly adjust 
            -- the debounce distance when we try and make curves
            local factor = 1 - math.sqrt(math.sqrt(math.sqrt(1 - radians)))
            return factor * minimumDistance
        else
            -- quickly get us two samples to help determine accurate debounce distance
            return 1
        end
    end,

    --- Responsible for debouncing samples. This is to reduce the
    --- bandwidth it requires to share the brush stroke once it is finished.
    ---@param self UIActiveBrushStroke
    ---@return boolean
    DebounceSample = function(self, sample)
        -- feature: debounce samples that are in too quick succession
        local now = CurrentTime()
        if now - self.LastEdited < self.DebounceTimeThreshold then
            return true
        end

        -- feature: debounce samples that are too close to each other
        local lastSample = self.LastSample
        if lastSample then
            local minimumDistance = self:GetDebounceDistance(sample)
            if VDist3(lastSample, sample) < minimumDistance then
                return true
            end
        end

        return false
    end,

    --- Attempts to add a sample to the brush stroke.
    ---@param self UIActiveBrushStroke
    ---@param coordinates Vector
    ProcessSample = function(self, coordinates)

        -- limitation: chat messages have a limited amount of space per
        -- message. It is difficult to overcome this limit.
        --
        -- By naturally limiting the size of a brush stroke we not only overcome
        -- the issue with chat messages but we also prevent players from creating
        -- gigantic brush strokes that have relatively high... entropy :).
        --
        -- The value is intentionally hard coded!

        if self:GetSampleCount() > 127 then
            self.CurrentSample = nil
            return
        end

        -- enables us to visualize it
        self.CurrentSample = coordinates

        -- basic debouncing to reduce bandwidth requirements
        if self:DebounceSample(coordinates) then
            return
        end

        self:AddSample(coordinates)
    end,

    --- Adds a sample to the brush stroke.
    ---@param self UIActiveBrushStroke
    ---@param coordinates Vector
    AddSample = function(self, coordinates)
        self.LastEdited = CurrentTime()
        self.LastSample = coordinates

        local samples = self.Samples
        table.insert(samples.CoordinatesX, coordinates[1])
        table.insert(samples.CoordinatesY, coordinates[2])
        table.insert(samples.CoordinatesZ, coordinates[3])
    end,

    --- Adds the last known sample to the brush stroke.
    ---@param self UIActiveBrushStroke
    AddLastSample = function(self)
        local currentSample = self.CurrentSample
        if currentSample then
            local samples = self.Samples
            table.insert(samples.CoordinatesX, currentSample[1])
            table.insert(samples.CoordinatesY, currentSample[2])
            table.insert(samples.CoordinatesZ, currentSample[3])
        end
    end,

    --#endregion
}

---@param color Color
---@return UIActiveBrushStroke
CreateActiveBrushStroke = function(color)
    local instance = ActiveBrushStroke(color) --[[@as UIActiveBrushStroke]]
    return instance
end
