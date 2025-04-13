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

--- Represents a shared painting that is send across the network. The data structure is slightly different to reduce network bandwidth.
---@class UISharedPainting
---@field SamplesX number[]
---@field SamplesY number[]
---@field SamplesZ number[]
---@field PeerId? number
---@field PeerName? string

---@class UIPaintingSample
---@field Position Vector

--- Responsible for drawing the painting to a world view.
---@class UIPainting : Renderable, DebugComponent
---@field PaintingIdentifier string
---@field WorldView WorldView
---@field Color Color
---@field Thickness number
---@field DecayDuration number   # in seconds
---@field DecayStartedAt number  # in seconds
---@field DecayPaintingThreadInstance? thread
---@field Samples UIPaintingSample[]
Painting = Class(DebugComponent) {

    ---@param self UIPainting
    ---@param worldview WorldView
    ---@param samples UIPaintingSample[]
    ---@param color Color
    __init = function(self, worldview, samples, color, identifier)
        -- store parameters
        self.Samples = samples
        self.Color = color
        self.WorldView = worldview

        -- we use the memory address as our identifier - almost guaranteed to be unique.
        self.PaintingIdentifier = tostring(self)
    end,

    --- Destroys the painting and deregisters it from the world view.
    ---@param self UIPainting
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIPainting
    OnDestroy = function(self)
        self.WorldView:UnregisterRenderable(self.PaintingIdentifier)
    end,

    --- Renders the painting to the world view.
    ---@param self UIPainting
    ---@param delta number
    OnRender = function(self, delta)
        local decayProgress = 0
        if self.DecayDuration and self.DecayStartedAt then
            decayProgress = math.clamp((GetGameTimeSeconds() - self.DecayStartedAt) / self.DecayDuration, 0, 1)
        end

        local decayedColor = self:ComputeDecayedColor(self.Color, decayProgress)

        local samples = self.Samples
        local sampleCount = table.getn(samples)
        for k = 2, sampleCount do
            local s1 = samples[k - 1]
            local s2 = samples[k]

            UI_DrawLine(s1.Position, s2.Position, decayedColor, 0)
        end
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

    --- Starts a thread that will destroy the painting after the specified duration. If the painting is already decaying then the decay duration is reset.
    ---@param self UIPainting
    ---@param duration number
    StartDecay = function(self, duration)
        if self.DecayPaintingThreadInstance then
            KillThread(self.DecayPaintingThreadInstance)
        end

        self.DecayDuration = duration
        self.DecayStartedAt = GetGameTimeSeconds()
        self.DecayPaintingThreadInstance = ForkThread(self.DecayThread, self, duration)
    end,

    --- Destroys the painting after the specified duration.
    ---@param self UIPainting
    ---@param duration number
    DecayThread = function(self, duration)
        WaitSeconds(duration)
        self:Destroy()
    end,

    ---@param self UIPainting
    StartRendering = function(self)
        -- register ourselves so that we get drawn
        self.WorldView:RegisterRenderable(self, self.PaintingIdentifier)
    end,
}

--- Creates a painting that can be drawn to a world view.
---@param worldview WorldView
---@param samples UIPaintingSample[]
---@param color Color
---@return UIPainting
CreatePainting = function(worldview, samples, color)
    local instance = Painting(worldview, samples, color) --[[@as UIPainting]]
    return instance
end
