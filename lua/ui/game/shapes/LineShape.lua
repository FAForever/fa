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

local Shape = import("/lua/ui/game/shapes/shape.lua").Shape

---@class UILineShape : UIShape
---@field Position1 Vector
---@field Position2 Vector
---@field Color Color
---@field Thickness number
---@field WorldView WorldView
LineShape = Class(Shape) {

    ---@param self UILineShape
    ---@param worldview WorldView
    ---@param p1 Vector   # in world coordinates
    ---@param p2 Vector   # in world coordinates
    ---@param size number
    ---@param color Color
    ---@param thickness number
    __init = function(self, worldview, p1, p2, size, color, thickness)
        Shape.__init(self, worldview)

        self.Size = size
        self.Color = color
        self.Thickness = thickness
        self.Position1 = p1
        self.Position2 = p2
    end,

    ---@param self UILineShape
    ---@param delta number
    OnRender = function(self, delta)
        UI_DrawLine(self.Position1, self.Position2, self.Color, self.Thickness)
    end,
}

--- Creates a line segment with the given properties.
---@param worldview WorldView
---@param p1 Vector   # in world coordinates
---@param p2 Vector   # in world coordinates
---@param color Color
---@param thickness number
---@return UILineShape
CreateLineShape = function(worldview, p1, p2, color, thickness)
    return LineShape(worldview, p1, p2, color, thickness) --[[@as UILineShape]]
end
