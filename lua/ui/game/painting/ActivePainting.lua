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

    ---@param self UIActivePainting
    ---@param worldview WorldView
    ---@param color Color
    __init = function(self, worldview, color)
        Painting.__init(self, worldview, { CoordinatesX = {}, CoordinatesY = {}, CoordinatesZ = {} }, color, 0)

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = GetMouseWorldPos()
    end,

    --- Responsible for debouncing samples. This is to reduce the
    --- bandwidth it requires to share the art once it is finished.
    ---@param self UIActivePainting
    ---@return boolean
    ShouldDebounceSample = function(self)
        local now = GetGameTimeSeconds()
        if now - self.LastEdited > 0.025 then
            return false
        end

        return true
    end,

    --- Adds a sample to the painting.
    ---@param self UIActivePainting
    ---@param position Vector
    AddSample = function(self, position)
        if self:ShouldDebounceSample() then
            return
        end

        ---@type UIPaintingSample
        local sample = {
            Position = position
        }

        self.LastEdited = GetGameTimeSeconds()
        self.LastSample = position

        local samples = self.Samples
        table.insert(samples.CoordinatesX, position[1])
        table.insert(samples.CoordinatesY, position[2])
        table.insert(samples.CoordinatesZ, position[3])
    end,
}

---@param worldview WorldView
---@param color Color
---@return UIActivePainting
CreateActivePainting = function(worldview, color)
    local instance = ActivePainting(worldview, color) --[[@as UIActivePainting]]

    return instance
end
