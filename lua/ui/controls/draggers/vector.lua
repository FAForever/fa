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

local UIRenderableCircle = import('/lua/ui/game/renderable/circle.lua').UIRenderableCircle

local Dragger = import('/lua/maui/dragger.lua').Dragger
local DraggerInit = Dragger.__init

---@class LineDrag : Dragger
---@field Origin Vector
---@field Destination Vector
---@field ShapeStart table
---@field ShapeEnd table
---@field ShapeStart1 table
---@field ShapeStart2 table
---@field ShapeEnd1 table
---@field ShapeEnd2 table
---@field Width number
---@field WorldView WorldView
---@field Callback fun(origin: Vector, destination: Vector)
RectangleDragger = Class(Dragger) {

    Size = 0.2,
    Thickness = 0.05,
    Color = 'ffffff',

    ---@param self LineDrag
    ---@param view WorldView
    ---@param callback fun(origin: Vector, destination: Vector)
    ---@param width number
    __init = function(self, view, callback, width)
        DraggerInit(self)

        -- store parameters
        self.Width = width
        self.WorldView = view
        self.Callback = callback

        -- prepare visuals
        local mouseWorldPosition = GetMouseWorldPos()

        local size = self.Size
        local trash = self.Trash
        local thickness = self.Thickness
        self.ShapeStart = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-start', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))
        self.ShapeEnd = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-start-01', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))
        self.ShapeStart1 = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-start-02', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))
        self.ShapeStart2 = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-end', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))
        self.ShapeEnd1 = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-end-01', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))
        self.ShapeEnd2 = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-end-02', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))

        self.Origin = mouseWorldPosition

        -- register the dragger
        PostDragger(view:GetRootFrame(), 'LBUTTON', self)
    end,

    --- Called by the engine when the mouse is moved
    ---@param self LineDrag
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnMove = function(self, x, y)
        local width = self.Width
        local view = self.WorldView

        local ps = self.Origin
        local pe = UnProject(view, { x, y })

        local dx = ps[1] - pe[1]
        local dz = ps[3] - pe[3]
        local distance = math.sqrt(dx * dx + dz * dz)

        local nx = (1 / distance) * dx
        local nz = (1 / distance) * dz

        local ox = nz
        local oz = -nx

        -- update locations
        self.ShapeStart1:SetPosition(ps[1] + width * ox, ps[2], ps[3] + width * oz)
        self.ShapeStart2:SetPosition(ps[1] - width * ox, ps[2], ps[3] - width * oz)

        self.ShapeEnd1:SetPosition(pe[1] + width * ox, pe[2], pe[3] + width * oz)
        self.ShapeEnd2:SetPosition(pe[1] - width * ox, pe[2], pe[3] - width * oz)

        self.ShapeEnd:SetPosition(pe[1], pe[2], pe[3])
    end,

    --- Called by the engine when the button we're tracking is released
    ---@param self LineDrag
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnRelease = function(self, x, y)
        -- do the callback
        local origin = self.Origin
        local destination = UnProject(self.WorldView, { x, y })
        local ok, err = pcall(self.Callback, origin, destination)
        if not ok then
            WARN(err)
        end

        self:Destroy()
    end,

    --- Called by the engine when the dragger is cancelled
    ---@param self LineDrag
    OnCancel = function(self)
        self:Destroy()
    end,
}
