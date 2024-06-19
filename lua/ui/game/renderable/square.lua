--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

---@class UIRenderableSquare : Renderable
---@field Position Vector
---@field Size number
---@field Color Color
---@field Thickness number
---@field WorldView WorldView
UIRenderableSquare = ClassSimple {

    ---@param self UIRenderableSquare
    ---@param worldview WorldView
    ---@param ox number     # in world coordinates
    ---@param oy number     # in world coordinates
    ---@param oz number     # in world coordinates
    ---@param size number
    ---@param color Color
    ---@param thickness number
    __init = function(self, worldview, ox, oy, oz, size, color, thickness)
        self.Position = { ox, oy, oz }
        self.Size = size
        self.Color = color
        self.Thickness = thickness
        self.WorldView = worldview

        worldview:RegisterRenderable(self)
    end,

    ---@param self UIRenderableSquare
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIRenderableSquare
    OnDestroy = function(self)
        self.WorldView:UnregisterRenderable(self)
    end,

    ---@param self UIRenderableSquare
    ---@param delta number
    OnRender = function(self, delta)
        UI_DrawRect(self.Position, self.Size, self.Color, self.Thickness)
    end,

    --#region Properties

    ---@param self UIRenderableSquare
    ---@param px number     # in world coordinates
    ---@param py number     # in world coordinates
    ---@param pz number     # in world coordinates
    SetPosition = function(self, px, py, pz)
        local position = self.Position
        position[1] = px
        position[2] = py
        position[3] = pz
    end,

    ---@param self UIRenderableSquare
    GetPosition = function(self)
        return unpack(self.Position)
    end

    --#endregion

}
