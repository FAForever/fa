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

--- A structure of arrays that stores samples.
---@class UIPaintingSamples
---@field CoordinatesX number[]
---@field CoordinatesY number[]
---@field CoordinatesZ number[]

---@class UIPaintingDecay
---@field Duration number       # in seconds
---@field StartTime number      # in seconds
---@field ThreadInstance thread

--- Responsible for drawing the painting to a world view.
---@class UIPainting : Renderable, DebugComponent
---@field Color Color
---@field Thickness number
---@field Decay? UIPaintingDecay
---@field Samples UIPaintingSamples
Painting = Class(DebugComponent) {

    ---@param self UIPainting
    ---@param samples UIPaintingSamples
    ---@param color Color
    __init = function(self, samples, color, identifier)
        -- store parameters
        self.Samples = samples
        self.Color = color
    end,

    ---@param self UIPainting
    Destroy = function(self)
        -- do nothing

        -- this function exists to allow a painting to become part of a trashbag. 
    end,

    --- Renders the painting to the world view.
    ---@param self UIPainting
    ---@param delta number
    OnRender = function(self, delta)
        local decayProgress = 0
        if self.Decay then
            decayProgress = math.clamp((GetGameTimeSeconds() - self.Decay.StartTime) / self.Decay.Duration, 0, 1)
        end

        local decayedColor = self:ComputeDecayedColor(self.Color, decayProgress)

        local position1 = {}
        local position2 = {}

        local coordinatesX = self.Samples.CoordinatesX
        local coordinatesY = self.Samples.CoordinatesY
        local coordinatesZ = self.Samples.CoordinatesZ

        for k = 2, table.getn(coordinatesX) do
            position1[1] = coordinatesX[k - 1]
            position1[2] = coordinatesY[k - 1]
            position1[3] = coordinatesZ[k - 1]

            position2[1] = coordinatesX[k]
            position2[2] = coordinatesY[k]
            position2[3] = coordinatesZ[k]

            UI_DrawLine(position1, position2, decayedColor, 0)
        end
    end,

    --- Computes the alpha value based on the decay progress of the painting. Defaults to a square root curve.
    ---@param self UIPainting
    ---@param value number  # number between 0 and 1.0
    ---@return number
    ComputeDecayInterpolation = function(self, value)
        return math.sqrt(value)
    end,

    ---@param self UIPainting
    ---@param color Color
    ---@param progress number   # number between 0 and 1.0
    ---@return Color
    ComputeDecayedColor = function(self, color, progress)
        -- defensive programming
        progress = math.clamp(progress, 0, 1)

        -- get color channel values, default to white
        local r, g, b, a = ColorUtils.ParseColor(color)
        if not (r and g and b) then
            r = 1.0
            g = 1.0
            b = 1.0
        end

        -- compute transparency
        a = self:ComputeDecayCurve(progress)

        return ColorUtils.ColorRGB(r, g, b, a)
    end,

    --- Starts a thread that will destroy the painting after the specified duration. If the painting is already decaying then the decay duration is reset.
    ---@param self UIPainting
    ---@param duration number
    StartDecay = function(self, duration)
        if self.Decay then
            KillThread(self.Decay.ThreadInstance)
        end

        self.Decay = {
            Duration = duration,
            StartTime = GetGameTimeSeconds(),
            ThreadInstance = ForkThread(self.DecayThread, self, duration)
        }
    end,

    --- Destroys the painting after the specified duration.
    ---@param self UIPainting
    ---@param duration number
    DecayThread = function(self, duration)
        WaitSeconds(duration)
        self:Destroy()
    end,

    ComputeBoundingBox = function(self)


    end,

    ---------------------------------------------------------------------------
    --#region Debug functionality

    --- Computes the allocated bytes by this painting.
    ---@param self UIPainting
    ---@return number
    ComputeAllocatedBytes = function(self)
        local allocatedBytesForSamples = debug.allocatedsize(self.Samples) +
            debug.allocatedsize(self.Samples.CoordinatesX) +
            debug.allocatedsize(self.Samples.CoordinatesY) +
            debug.allocatedsize(self.Samples.CoordinatesZ)

        local allocatedBytesForDecay = 0
        if self.Decay then
            allocatedBytesForDecay = debug.allocatedsize(self.Decay)
        end

        return debug.allocatedsize(self) + allocatedBytesForSamples + allocatedBytesForDecay
    end,

    --#endregion
}

--- Creates a painting that can be drawn to a world view.
---@param samples UIPaintingSamples
---@param color Color
---@return UIPainting
CreatePainting = function(samples, color)
    local instance = Painting(samples, color) --[[@as UIPainting]]
    return instance
end
