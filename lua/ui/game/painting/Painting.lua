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

---@class UIPaintingSample
---@field Position Vector

--- Responsible for drawing the painting to a world view.
---@class UIPainting : Renderable
---@field Identifier string
---@field WorldView WorldView
---@field Color Color
---@field Thickness number
---@field Samples UIPaintingSample[]
Painting = ClassSimple {

    ---@param self UIPainting
    ---@param worldview WorldView
    ---@param samples UIPaintingSample[]
    ---@param color Color
    ---@param thickness number
    ---@param duration number       # if duration <= 0, then duration is infinite
    __init = function(self, worldview, samples, color, thickness, duration)
        -- we use the memory address as our identifier - almost guaranteed to be unique.
        self.Identifier = tostring(self)

        -- store parameters
        self.Samples = samples
        self.Color = color
        self.Thickness = thickness
        self.WorldView = worldview

        -- register ourselves so that we get drawn
        worldview:RegisterRenderable(self, self.Identifier)

        if duration > 0 then
            ForkThread(self.DecayThread, self, duration)
        end
    end,

    --- Destroys the painting and deregisters it from the world view.
    ---@param self UIPainting
    Destroy = function(self)
        print("Destroyed a painting")
        self:OnDestroy()
    end,

    ---@param self UIPainting
    OnDestroy = function(self)
        self.WorldView:UnregisterRenderable(self.Identifier)
    end,

    --- Renders the painting to the world view.
    ---@param self UIPainting
    ---@param delta number
    OnRender = function(self, delta)
        local samples = self.Samples
        local sampleCount = table.getn(samples)
        for k = 2, sampleCount do
            local s1 = samples[k - 1]
            local s2 = samples[k]

            UI_DrawLine(s1.Position, s2.Position, self.Color, self.Thickness)
        end
    end,

    --- Destroys the painting after the specified duration.
    ---@param self UIPainting
    ---@param duration number
    DecayThread = function(self, duration)
        WaitSeconds(duration)
        self:Destroy()
    end
}

---@param worldview WorldView
---@param samples UIPaintingSample[]
---@param color Color
---@param thickness number
---@param duration number
---@return UIPainting
CreatePainting = function(worldview, samples, color, thickness, duration)
    local instance = Painting(worldview, samples, color, thickness, duration) --[[@as UIPainting]]
    return instance
end
