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

local BrushStroke = import('/lua/ui/game/painting/BrushStroke.lua').BrushStroke

--- Responsible for managing a painting that is actively being worked on.
---@class UIActiveBrushStroke : UIBrushStroke
---@field LastEdited number
---@field LastSample Vector
ActiveBrushStroke = ClassUI(BrushStroke) {

    DebounceTimeThreshold = 0.016, -- About 60 fps

    ---@param self UIActiveBrushStroke
    ---@param color Color
    __init = function(self, color)
        BrushStroke.__init(self, { CoordinatesX = {}, CoordinatesY = {}, CoordinatesZ = {} }, color)

        self.LastEdited = CurrentTime()
        self.LastSample = { 0, 0, 0 }
    end,

    ---------------------------------------------------------------------------
    --#region Creation of samples interface

    --- Computes the debounce distance based on the current zoom level.
    ---@param self UIActiveBrushStroke
    ---@param sample Vector
    ---@return number
    GetDebounceDistance = function(self, sample)
        local worldViewManager = import("/lua/ui/game/worldview.lua")

        local zoomDebounceDistance = 1

        -- feature: increase debounce distance as we zoom out
        local mouseScreenCoordinates = GetMouseScreenPos()
        local worldView = worldViewManager.GetTopmostWorldViewAt(mouseScreenCoordinates[1], mouseScreenCoordinates[2])
        if worldView then
            local camera = GetCamera(worldView._cameraName)
            if camera then
                local zoom = camera:GetZoom()
                zoomDebounceDistance = math.max(1, 0.020 * zoom)
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
            return factor * zoomDebounceDistance
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
        local debounceDistance = self:GetDebounceDistance(sample)
        if VDist3(self.LastSample, sample) < debounceDistance then
            return true
        end

        return false
    end,

    --- Adds a sample to the brush stroke.
    ---@param self UIActiveBrushStroke
    ---@param coordinates Vector
    AddSample = function(self, coordinates)
        -- basic debouncing to reduce bandwidth requirements
        if self:DebounceSample(coordinates) then
            return
        end

        local samples = self.Samples

        -- limitation: chat messages have a limited amount of space per
        -- message. It is difficult to overcome this limit.
        --
        -- By naturally limiting the size of a brush stroke we not only overcome
        -- the issue with chat messages but we also prevent players from creating
        -- gigantic brush strokes that have relatively high... entropy :).
        --
        -- The value is intentionally hard coded!

        if table.getn(samples.CoordinatesX) > 127 then
            return
        end

        self.LastEdited = CurrentTime()
        self.LastSample = coordinates

        table.insert(samples.CoordinatesX, coordinates[1])
        table.insert(samples.CoordinatesY, coordinates[2])
        table.insert(samples.CoordinatesZ, coordinates[3])
    end,

    --#endregion
}

---@param color Color
---@return UIActiveBrushStroke
CreateActiveBrushStroke = function(color)
    local instance = ActiveBrushStroke(color) --[[@as UIActiveBrushStroke]]
    return instance
end
