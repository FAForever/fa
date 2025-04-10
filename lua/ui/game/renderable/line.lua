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

---@class UIRenderableLine : Renderable
---@field Identifier string
---@field Hidden boolean
---@field Position1 Vector
---@field Position2 Vector
---@field Size number
---@field Color Color
---@field Thickness number
---@field WorldView WorldView
UIRenderableLine = ClassSimple {

    ---@param self UIRenderableLine
    ---@param worldview WorldView
    ---@param id string
    ---@param x1 number     # in world coordinates
    ---@param y1 number     # in world coordinates
    ---@param z1 number     # in world coordinates
    ---@param x2 number     # in world coordinates
    ---@param y2 number     # in world coordinates
    ---@param z2 number     # in world coordinates
    ---@param color Color
    ---@param thickness number
    __init = function(self, worldview, id, x1, y1, z1, x2, y2, z2, size, color, thickness)
        self.WorldView = worldview
        self.Identifier = id
        self.Position1 = { x1, y1, z1 }
        self.Position2 = { x2, y2, z2 }
        self.Color = color
        self.Thickness = thickness

        worldview:RegisterRenderable(self, id)
    end,

    ---@param self UIRenderableLine
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIRenderableLine
    OnDestroy = function(self)
        self.WorldView:UnregisterRenderable(self.Identifier)
    end,

    ---@param self UIRenderableLine
    ---@param delta number
    OnRender = function(self, delta)
        if not self.Hidden then
            UI_DrawLine(self.Position1, self.Position2, self.Color, self.Thickness)
        end
    end,

    ---@param self UIRenderableLine
    Hide = function(self)
        self.Hidden = true
    end,

    ---@param self UIRenderableLine
    Show = function(self)
        self.Hidden = false
    end,

    ---@param self UIRenderableLine
    SetHidden = function(self, hide)
        self.Hidden = hide
    end,

    ---@param self UIRenderableLine
    IsHidden = function(self)
        return self.Hidden
    end,

    --#region Properties

    ---@param self UIRenderableLine
    ---@param px number     # in world coordinates
    ---@param py number     # in world coordinates
    ---@param pz number     # in world coordinates
    SetPosition1 = function(self, px, py, pz)
        local position = self.Position1
        position[1] = px
        position[2] = py
        position[3] = pz
    end,

    ---@param self UIRenderableLine
    ---@param px number     # in world coordinates
    ---@param py number     # in world coordinates
    ---@param pz number     # in world coordinates
    SetPosition2 = function(self, px, py, pz)
        local position = self.Position2
        position[1] = px
        position[2] = py
        position[3] = pz
    end,

    ---@param self UIRenderableLine
    ---@return number
    ---@return number
    ---@return number
    GetPosition1 = function(self)
        return unpack(self.Position1)
    end,

    ---@param self UIRenderableLine
    ---@return number
    ---@return number
    ---@return number
    GetPosition2 = function(self)
        return unpack(self.Position2)
    end

    --#endregion

}
