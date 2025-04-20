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

--- A component to encapsulate the logic used to render shapes in the world.
---@class UIRenderShapesComponent
---@field Renderables table<string, Renderable>
RenderShapesComponent = ClassSimple {

    -- Related binary patches that make this possible:
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/47
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/111
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/112

    ---@param self UIRenderShapesComponent | WorldView
    __post_init = function(self)
        self.Renderables = {}
    end,

    --- Register a renderable to render each frame
    ---@param self UIRenderShapesComponent | WorldView
    ---@param renderable Renderable
    ---@param id string
    RegisterRenderable = function(self, renderable, id)
        self.Trash:Add(renderable)
        self.Renderables[id] = renderable

        if not table.empty(self.Renderables) then
            self:SetCustomRender(true)
        end
    end,

    --- Unregister a renderable
    ---@param self UIRenderShapesComponent | WorldView
    ---@param id string
    UnregisterRenderable = function(self, id)
        self.Renderables[id] = nil

        if table.empty(self.Renderables) then
            self:SetCustomRender(false)
        end
    end,

    --- Is called each frame by the engine to render shapes when custom rendering is enabled.
    ---@param self UIRenderShapesComponent | WorldView
    ---@param delta number
    OnRenderWorld = function (self, delta)
        for id, renderable in self.Renderables do
            renderable:OnRender(delta, delta)
        end
    end,

}