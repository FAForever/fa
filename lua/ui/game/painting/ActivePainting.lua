--******************************************************************************************************
--** Copyright (c) 2025 FAForever
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

local Painting = import('/lua/ui/game/painting/Painting.lua').Painting

--- Responsible for managing a painting that is actively being worked on.
---@class UIActivePainting : UIPainting
---@field LastEdited number
---@field LastSample Vector
ActivePainting = ClassUI(Painting) {

    DebounceTimeThreshold = 0.016, -- About 60 fps

    ---@param self UIActivePainting
    ---@param color Color
    __init = function(self, color)
        Painting.__init(self, { CoordinatesX = {}, CoordinatesY = {}, CoordinatesZ = {} }, color)

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = { -10, -10, -10 }
    end,

    ---------------------------------------------------------------------------
    --#region Creation of samples interface

    --- Computes the debounce distance based on the current zoom level.
    ---@param self UIActivePainting
    ---@return number
    GetDebounceDistance = function(self)
        local worldViewManager = import("/lua/ui/game/worldview.lua")

        local distance = 1

        -- feature: zoom sensitivity for debounce distance
        local mouseScreenCoordinates = GetMouseScreenPos()
        local worldView = worldViewManager.GetTopmostWorldViewAt(mouseScreenCoordinates[1], mouseScreenCoordinates[2])
        if worldView then
            local camera = GetCamera(worldView._cameraName)
            if camera then
                local zoom = camera:GetZoom()
                distance = math.max(1, zoom * 0.01)
            end
        end

        return distance
    end,

    --- Responsible for debouncing samples. This is to reduce the
    --- bandwidth it requires to share the art once it is finished.
    ---@param self UIActivePainting
    ---@return boolean
    DebounceSample = function(self, sample)
        -- feature: debounce samples that are in too quick succession
        local now = GetGameTimeSeconds()
        if now - self.LastEdited < self.DebounceTimeThreshold then
            return true
        end

        -- feature: debounce samples that are too close to each other
        local debounceDistance = self:GetDebounceDistance()
        if VDist3(self.LastSample, sample) < debounceDistance then
            return true
        end

        return false
    end,

    --- Adds a sample to the painting.
    ---@param self UIActivePainting
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
        -- By naturally limiting the size of a painting we not only overcome the
        -- issue with chat messages but we also prevent players from creating
        -- gigantic paintings that have relatively high... entropy :).
        --
        -- The value is intentionally hard coded!

        if table.getn(samples.CoordinatesX) > 100 then
            return
        end

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = coordinates

        table.insert(samples.CoordinatesX, coordinates[1])
        table.insert(samples.CoordinatesY, coordinates[2])
        table.insert(samples.CoordinatesZ, coordinates[3])
    end,

    --#endregion
}

---@param color Color
---@return UIActivePainting
CreateActivePainting = function(color)
    local instance = ActivePainting(color) --[[@as UIActivePainting]]

    return instance
end
