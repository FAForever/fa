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

---@class UIRenderableCircle : Renderable
---@field Identifier string
---@field Hidden boolean
---@field Position Vector
---@field Size number
---@field Color Color
---@field Thickness number
---@field WorldView WorldView
UIRenderableCircle = ClassSimple {

    ---@param self UIRenderableCircle
    ---@param worldview WorldView
    ---@param id string
    ---@param ox number     # in world coordinates
    ---@param oy number     # in world coordinates
    ---@param oz number     # in world coordinates
    ---@param size number
    ---@param color Color
    ---@param thickness number
    __init = function(self, worldview, id, ox, oy, oz, size, color, thickness)
        self.WorldView = worldview
        self.Identifier = id
        self.Position = { ox, oy, oz }
        self.Size = size
        self.Color = color
        self.Thickness = thickness

        worldview:RegisterRenderable(self, id)
    end,

    ---@param self UIRenderableCircle
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIRenderableCircle
    OnDestroy = function(self)
        self.WorldView:UnregisterRenderable(self.Identifier)
    end,

    ---@param self UIRenderableCircle
    ---@param delta number
    OnRender = function(self, delta)
        if not self.Hidden then
            UI_DrawCircle(self.Position, self.Size, self.Color, self.Thickness)
        end
    end,

    ---@param self UIRenderableCircle
    Hide = function(self)
        self.Hidden = true
    end,

    ---@param self UIRenderableCircle
    Show = function(self)
        self.Hidden = false
    end,

    ---@param self UIRenderableCircle
    SetHidden = function(self, hide)
        self.Hidden = hide
    end,

    ---@param self UIRenderableCircle
    IsHidden = function(self)
        return self.Hidden
    end,

    --#region Properties

    ---@param self UIRenderableCircle
    ---@param px number     # in world coordinates
    ---@param py number     # in world coordinates
    ---@param pz number     # in world coordinates
    SetPosition = function(self, px, py, pz)
        local position = self.Position
        position[1] = px
        position[2] = py
        position[3] = pz
    end,

    ---@param self UIRenderableCircle
    ---@return number
    ---@return number
    ---@return number
    GetPosition = function(self)
        return unpack(self.Position)
    end

    --#endregion

}
