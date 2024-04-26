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

---@class UIRadialDragger : Dragger
---@field Origin Vector
---@field Destination Vector
---@field ShapeStart UIRenderableCircle
---@field MinimumDistance number
---@field MaximumDistance number
---@field Width number
---@field WorldView WorldView
---@field Callback fun(origin: Vector, radius: number)
RadialDragger = Class(Dragger) {

    Size = 0.2,
    Thickness = 0.05,
    Color = 'ffffff',

    ---@param self UIRadialDragger
    ---@param view WorldView
    ---@param callback fun(origin: Vector, radius: number)
    ---@param keycode 'LBUTTON' | 'MBUTTON' | 'RBUTTON'
    ---@param maximumWidth number
    ---@param minimumDistance number
    ---@param maximumDistance number
    __init = function(self, view, callback, keycode, maximumWidth, minimumDistance, maximumDistance)
        DraggerInit(self)

        -- store parameters
        self.Width = maximumWidth
        self.MinimumDistance = minimumDistance
        self.MaximumDistance = maximumDistance
        self.WorldView = view
        self.Callback = callback

        -- prepare visuals
        local mouseWorldPosition = GetMouseWorldPos()

        local size = self.Size
        local trash = self.Trash
        local thickness = self.Thickness
        self.ShapeStart = trash:Add(UIRenderableCircle(view, 'rectangle-dragger-start', mouseWorldPosition[1],
            mouseWorldPosition[2], mouseWorldPosition[3], size, 'ffffff', thickness))

        self.Origin = mouseWorldPosition

        -- register the dragger
        PostDragger(view:GetRootFrame(), keycode, self)
    end,

    --- Called by the engine when the mouse is moved
    ---@param self UIRadialDragger
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

        if distance > self.MinimumDistance then
            self.ShapeStart:Show()
            self.ShapeStart.Size = distance
        else
            -- try to hide it
            self.ShapeStart:Hide()
        end
    end,

    --- Called by the engine when the button we're tracking is released
    ---@param self UIRadialDragger
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnRelease = function(self, x, y)
        -- do the callback
        local origin = self.Origin
        local destination = UnProject(self.WorldView, { x, y })
        local radius = VDist3(origin, destination)
        local ok, err = pcall(self.Callback, origin, radius)
        if not ok then
            WARN(err)
        end

        self:Destroy()
    end,

    --- Called by the engine when the dragger is cancelled
    ---@param self UIRadialDragger
    OnCancel = function(self)
        self:Destroy()
    end,
}
