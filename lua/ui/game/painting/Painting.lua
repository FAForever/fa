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

local ColorUtils = import("/lua/shared/color.lua")
local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

---@class UIPaintingSample
---@field Position Vector

--- Responsible for drawing the painting to a world view.
---@class UIPainting : Renderable, DebugComponent
---@field Identifier string
---@field WorldView WorldView
---@field Color Color
---@field Thickness number
---@field Duration number   # in seconds
---@field CreatedAt number  # in seconds
---@field Samples UIPaintingSample[]
Painting = Class(DebugComponent) {

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
        self.CreatedAt = GetGameTimeSeconds()
        self.Duration = duration

        -- register ourselves so that we get drawn
        worldview:RegisterRenderable(self, self.Identifier)

        if duration > 0 then
            ForkThread(self.DecayThread, self, duration)
        end
    end,

    --- Destroys the painting and deregisters it from the world view.
    ---@param self UIPainting
    Destroy = function(self)
        if self.EnabledLogging then
            print("Destroyed a painting")
        end

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
        local decayProgress = 0
        if self.Duration > 0 then
            decayProgress = math.clamp((GetGameTimeSeconds() - self.CreatedAt) / self.Duration, 0, 1)
        end

        local decayedColor = self:ComputeDecayedColor(self.Color, decayProgress)

        local samples = self.Samples
        local sampleCount = table.getn(samples)
        for k = 2, sampleCount do
            local s1 = samples[k - 1]
            local s2 = samples[k]

            UI_DrawLine(s1.Position, s2.Position, decayedColor, self.Thickness)
        end
    end,

    --- Destroys the painting after the specified duration.
    ---@param self UIPainting
    ---@param duration number
    DecayThread = function(self, duration)
        WaitSeconds(duration)
        self:Destroy()
    end,

    ---@param self UIPainting
    ---@param color Color
    ---@param progress number   # number between 0 and 1.0
    ---@return Color
    ComputeDecayedColor = function(self, color, progress)
        -- guardrail
        progress = math.clamp(progress, 0, 1)

        -- get color channel values, default to white
        local r, g, b, a = ColorUtils.ParseColor(color)
        if not (r and g and b) then
            r = 1.0
            g = 1.0
            b = 1.0
        end

        -- compute transparency
        a = math.sqrt(1 - progress)

        return ColorUtils.ColorRGB(r, g, b, a)
    end,
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
