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

    DebounceTimeThreshold = 0.016,
    DebounceDistanceThreshold = 1.0,

    ---@param self UIActivePainting
    ---@param color Color
    __init = function(self, color)
        Painting.__init(self, { CoordinatesX = {}, CoordinatesY = {}, CoordinatesZ = {} }, color, 0)

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = GetMouseWorldPos()
    end,

    --- Responsible for debouncing samples. This is to reduce the
    --- bandwidth it requires to share the art once it is finished.
    ---@param self UIActivePainting
    ---@return boolean
    DebounceSample = function(self, sample)

        -- feature: debounce samples that are too close to each other
        -- feature: debounce samples that are in too quick succession

        local shouldDebounce = false

        -- debounce samples that happen too soon
        local now = GetGameTimeSeconds()
        if now - self.LastEdited < self.DebounceTimeThreshold then
            shouldDebounce = true
        end

        -- debounce samples that are too close
        if VDist3(self.LastSample, sample) < self.DebounceDistanceThreshold then
            shouldDebounce = true
        end

        return shouldDebounce
    end,

    --- Adds a sample to the painting.
    ---@param self UIActivePainting
    ---@param position Vector
    AddSample = function(self, position)
        -- basic debouncing to reduce bandwidth requirements
        if self:DebounceSample(position) then
            return
        end

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = position

        local samples = self.Samples
        table.insert(samples.CoordinatesX, position[1])
        table.insert(samples.CoordinatesY, position[2])
        table.insert(samples.CoordinatesZ, position[3])
    end,
}

---@param color Color
---@return UIActivePainting
CreateActivePainting = function(color)
    local instance = ActivePainting(color) --[[@as UIActivePainting]]

    return instance
end
