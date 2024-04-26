
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

local RadialDragger = import("/lua/ui/controls/draggers/radial.lua").RadialDragger
local MaximumWidth = import("/lua/shared/commands/area-reclaim-order.lua").MaximumWidth
local MaximumDistance = import("/lua/shared/commands/area-reclaim-order.lua").MaximumDistance

---@type number
local MinimumDistance = 4

---@param value number
SetMinimumDistance = function(value)
    if type(value) != 'number' then
        error('Expected a number, got ' .. type(value))
    end

    MinimumDistance = value
end

---@type Keycode
local DragKeycode = 'LBUTTON'

---@param value Keycode
SetDragKeyCode = function(value)
    if type(value) != 'string' then
        error('Expected a string, got ' .. type(value))
    end

    DragKeycode = value
end

---@param origin Vector
---@param radius number
local AreaReclaimOrderCallback = function(origin, radius)
    if radius < MinimumDistance then
        return
    end

    SimCallback({ Func = 'ExtendAttackOrder', Args = { Origin = origin, Radius = radius } }, true)
end

---@param command UserCommand
AreaAttackOrder = function(command)

    local worldView = import("/lua/ui/game/worldview.lua").viewLeft

    RadialDragger(
        worldView,
        AreaReclaimOrderCallback,
        DragKeycode,
        MinimumDistance,
        MaximumWidth,
        MaximumDistance
    )

end
