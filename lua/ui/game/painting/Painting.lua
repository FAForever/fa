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

---@class UIPaintingBoundingBox : number[]
---@field [1] number # min x
---@field [2] number # min y
---@field [3] number # min z
---@field [4] number # max x
---@field [5] number # max y
---@field [6] number # max z

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
---@field Decay? UIPaintingDecay
---@field Samples UIPaintingSamples
---@field Trash TrashBag
---@field Author? string        # peer that made the painting.
---@field ShareId? number
Painting = Class(DebugComponent) {

    ---@param self UIPainting
    ---@param samples UIPaintingSamples
    ---@param color Color
    __init = function(self, samples, color)
        -- store parameters
        self.Samples = samples
        self.Color = color
        self.Trash = TrashBag()
    end,

    ---@param self UIPainting
    Destroy = function(self)
        self.Trash:Destroy()
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
        return 1 - math.sqrt(value)
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
        a = self:ComputeDecayInterpolation(progress)

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
            ThreadInstance = self.Trash:Add(ForkThread(self.DecayThread, self, duration))
        }
    end,

    --- Destroys the painting after the specified duration.
    ---@param self UIPainting
    ---@param duration number
    DecayThread = function(self, duration)
        WaitSeconds(duration)
        self:Destroy()
    end,

    ---------------------------------------------------------------------------
    --#region Collision detection for interactions

    --- Computes the bounding box of the painting and caches it.
    ---@param self UIPainting
    ---@return UIPaintingBoundingBox
    GetBoundingBox = function(self)
        if self.BoundingBox then
            return self.BoundingBox
        end

        local minX = 8192
        local minY = 8192
        local minZ = 8192

        local maxX = -8192
        local maxY = -8192
        local maxZ = -8192

        local coordinatesX = self.Samples.CoordinatesX
        local coordinatesY = self.Samples.CoordinatesY
        local coordinatesZ = self.Samples.CoordinatesZ

        for k = 1, table.getn(coordinatesX) do
            local sx = coordinatesX[k]
            local sy = coordinatesY[k]
            local sz = coordinatesZ[k]

            minX = math.min(minX, sx)
            minY = math.min(minY, sy)
            minZ = math.min(minZ, sz)

            maxX = math.max(maxX, sx)
            maxY = math.max(maxY, sy)
            maxZ = math.max(maxZ, sz)
        end

        self.BoundingBox = { minX, minY, minZ, maxX, maxY, maxZ }
        return self.BoundingBox
    end,

    --- Computes the distance to the bounding box of the painting.
    ---@param self UIPainting
    ---@param px number
    ---@param py number
    ---@param pz number
    ---@return number   # nearest distance to the bounding box of the painting.
    DistanceToBoundingBoxXYZ = function(self, px, py, pz)
        local box = self:GetBoundingBox()

        local dx = 0.0
        local dy = 0.0
        local dz = 0.0

        local minX = box[1]
        local minY = box[2]
        local minZ = box[3]
        local maxX = box[4]
        local maxY = box[5]
        local maxZ = box[6]

        -- X axis
        if px < minX then
            dx = minX - px
        elseif px > maxX then
            dx = px - maxX
        end

        -- Y axis
        if py < minY then
            dy = minY - py
        elseif py > maxY then
            dy = py - maxY
        end

        -- Z axis
        if pz < minZ then
            dz = minZ - pz
        elseif pz > maxZ then
            dz = pz - maxZ
        end

        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end,

    --- Computes the distance to the bounding box of the painting.
    ---@param self UIPainting
    ---@param point Vector
    ---@return number   # nearest distance to the bounding box of the painting.
    DistanceToBoundingBox = function(self, point)
        return self:DistanceToBoundingBoxXYZ(point[1], point[2], point[3])
    end,

    --- Computes a precise distance to the painting. It considers all successive
    --- pairs of samples to be a line segment. It computes the shortest distance
    --- over all line segments. This scales over the number of samples. 
    ---
    --- It's better to first compute the distance to the bounding box to determine
    --- whether this precision is necessary.
    ---@param self UIPainting
    ---@param px number
    ---@param py number
    ---@param pz number
    ---@return number   # nearest distance to the painting
    DistanceToXYZ = function(self, px, py, pz)
        local distance = 8192

        local coordinatesX = self.Samples.CoordinatesX
        local coordinatesY = self.Samples.CoordinatesY
        local coordinatesZ = self.Samples.CoordinatesZ

        for k = 2, table.getn(coordinatesX) do
            local x1 = coordinatesX[k - 1]
            local y1 = coordinatesY[k - 1]
            local z1 = coordinatesZ[k - 1]

            local x2 = coordinatesX[k]
            local y2 = coordinatesY[k]
            local z2 = coordinatesZ[k]

            local dx = x2 - x1
            local dy = y2 - y1
            local dz = z2 - z1

            local vx = px - x1
            local vy = py - y1
            local vz = pz - z1

            local dot = vx * dx + vy * dy + vz * dz
            local lenSq = dx * dx + dy * dy + dz * dz

            local t = 0.0
            if lenSq > 0.0 then
                t = dot / lenSq
                if t < 0.0 then
                    t = 0.0
                elseif t > 1.0 then
                    t = 1.0
                end
            end

            local cx = x1 + t * dx
            local cy = y1 + t * dy
            local cz = z1 + t * dz

            local dx2 = px - cx
            local dy2 = py - cy
            local dz2 = pz - cz

            local distanceToSegment = math.sqrt(dx2 * dx2 + dy2 * dy2 + dz2 * dz2)
            if distanceToSegment < distance then
                distance = distanceToSegment
            end
        end

        return distance
    end,

    --- Computes a precise distance to the painting. It considers all successive
    --- pairs of samples to be a line segment. It computes the shortest distance
    --- over all line segments. This scales over the number of samples. 
    ---
    --- It's better to first compute the distance to the bounding box to determine
    --- whether this precision is necessary.
    ---@param self UIPainting
    ---@param point Vector
    ---@return number   # nearest distance to the painting
    DistanceTo = function(self, point)
        return self:DistanceToXYZ(point[1], point[2], point[3])
    end,

    --#endregion

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
