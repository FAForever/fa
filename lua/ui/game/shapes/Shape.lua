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

--- The abstract class of a shape that can be rendered to a world view. Do not create an instance of this class, it won't do anything.
---@class UIShape : Destroyable
---@field WorldView WorldView
---@field Hidden boolean
Shape = ClassSimple {

    ---@param self UIShape
    ---@param worldview WorldView
    __init = function(self, worldview, id)
        self.WorldView = worldview
        self.Hidden = false

        -- register the shape to the world view to be rendered
        self.WorldView:AddShape(self, tostring(self))
    end,

    ---@param self UIShape
    Destroy = function(self)

        -- remove the shape from the world view, it will no longer be rendered
        self.WorldView:RemoveShape(tostring(self))
    end,

    --- Renders the shape if it is not hidden.
    ---@param self UIShape
    ---@param delta number
    Render = function(self, delta)
        if self.Hidden then
            return
        end

        self:OnRender(delta)
    end,

    --- The logic to render the shape.
    ---@param self UIShape
    ---@param delta number
    OnRender = function(self, delta)
        -- to be defined by the subclass
        error("OnRender must be overridden by subclass")
    end,

    --- Hides the shape, it will no longer be rendered until unhidden.
    ---@param self UICircleShape
    Hide = function(self)
        self.Hidden = true
    end,

    --- Shows the shape. It will be rendered again.
    ---@param self UICircleShape
    Show = function(self)
        self.Hidden = false
    end,

    ---@param self UICircleShape
    SetHidden = function(self, hide)
        self.Hidden = hide
    end,

    ---@param self UICircleShape
    IsHidden = function(self)
        return self.Hidden
    end,
}
