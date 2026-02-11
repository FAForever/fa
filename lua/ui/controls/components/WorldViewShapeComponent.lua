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
---@class UIWorldViewShapeComponent
---@field Shapes table<string, UIShape> | TrashBag
WorldViewShapeComponent = ClassSimple {

    -- Related binary patches that make this possible:
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/47
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/111
    -- - https://github.com/FAForever/FA-Binary-Patches/pull/112

    ---@param self UIWorldViewShapeComponent | WorldView
    __post_init = function(self)
        self.Shapes = TrashBag()
    end,

    --- Adds a shape that we should render to the world view.
    ---
    --- The shape is stored in a weak table. If there's no other active
    --- reference to the shape then the garbage collector will clean it up.
    ---@param self UIWorldViewShapeComponent | WorldView
    ---@param shape UIShape
    ---@param id string
    AddShape = function(self, shape, id)
        self.Trash:Add(shape)
        self.Shapes[id] = shape

        if not table.empty(self.Shapes) then
            self:SetCustomRender(true)
        end
    end,

    --- Removes a shape. It will no longer be rendered to the world view.
    ---@param self UIWorldViewShapeComponent | WorldView
    ---@param id string
    RemoveShape = function(self, id)
        self.Shapes[id] = nil

        if table.empty(self.Shapes) then
            self:SetCustomRender(false)
        end
    end,

    --- Is called each frame by the engine to render shapes when custom rendering is enabled. All shapes that fail to render are removed.
    ---@param self UIWorldViewShapeComponent | WorldView
    ---@param delta number
    OnRenderWorld = function(self, delta)
        for id, shape in self.Shapes do
            local success = self:OnRenderShape(shape, delta)
            if not success then
                self.Shapes[id] = nil
            end
        end
    end,

    --- Is called each frame for each shape to render it. 
    ---@param self UIWorldViewShapeComponent | WorldView
    ---@param shape UIShape
    ---@param delta number
    ---@return boolean  # if false then some error happened during rendering. 
    OnRenderShape = function(self, shape, delta)
        -- sanity check on the data
        if not (shape and shape.OnRender) then
            WARN("Shape is nil or does not have an 'OnRender' function")
            return false
        end

        -- sanity check on the logic of the function
        local ok, msg = pcall(shape.Render, shape, delta)
        if not ok then
            WARN(msg)
            return false
        end

        return true
    end,

}
