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

local ColorUtils = import("/lua/shared/color.lua")
local LayoutHelper = import('/lua/maui/layouthelpers.lua')
local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

---@class UIBrushStrokeBoundingBox : number[]
---@field [1] number # min x
---@field [2] number # min y
---@field [3] number # min z
---@field [4] number # max x
---@field [5] number # max y
---@field [6] number # max z

--- A structure of arrays that stores samples.
---@class UIBrushStrokeSamples
---@field CoordinatesX number[]
---@field CoordinatesY number[]
---@field CoordinatesZ number[]

---@class UIBrushStrokeDecay
---@field Duration number       # in seconds
---@field StartTime number      # in seconds
---@field ThreadInstance thread

--- A brush stroke of a painting.
---@class UIBrushStroke : DebugComponent, Destroyable
---@field Color Color                           # Color of the brush stroke.
---@field Decay? UIBrushStrokeDecay     # Decay of the brush stroke.
---@field Samples UIBrushStrokeSamples  # Samples of the brush stroke. All samples are in world coordinates.
---@field Trash TrashBag
---@field Author? string                        # peer that made the brush stroke.
---@field ShareId? number
---@field BoundingBox? UIBrushStrokeBoundingBox # Do not access directly, use `GetBoundingBox`
BrushStroke = Class(DebugComponent) {

    ---@param self UIBrushStroke
    ---@param samples UIBrushStrokeSamples
    ---@param color Color
    __init = function(self, samples, color)
        self.Samples = samples
        self.Color = color
        self.Trash = TrashBag()
    end,

    ---@param self UIBrushStroke
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIBrushStroke
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,

    --- Renders the brush stroke.
    ---@param self UIBrushStroke
    ---@param delta number
    OnRender = function(self, delta)
        local brushWidth = self:GetBrushWidth()
        local decayProgress = self:GetDecayProgress()
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

            UI_DrawLine(position1, position2, decayedColor, brushWidth)
        end
    end,

    ---@param self UIBrushStroke
    ---@return number
    GetBrushWidth = function(self)
        local pixelScaleFactor = LayoutHelper.GetPixelScaleFactor()

        -- we want the multiplier to start at 0, hence the -1
        local multiplier = 0.5 * (1 + pixelScaleFactor) - 1

        -- clamp it to make sure we don't get anything crazy
        return math.clamp(multiplier, 0, 1)
    end,

    --- Computes the decay progression of the brush stroke.
    ---@param self UIBrushStroke
    ---@return number   # a number between 0 and 1, where 1 means the brush stroke is completely decayed.
    GetDecayProgress = function(self)
        local decay = self.Decay
        if not decay then
            return 0
        end

        return math.clamp((CurrentTime() - self.Decay.StartTime) / self.Decay.Duration, 0, 1)
    end,

    --- Computes the number of samples in this brush stroke.
    ---@param self UIBrushStroke
    GetSampleCount = function(self)
        return table.getn(self.Samples.CoordinatesX)
    end,

    --- Computes the alpha value based on the decay progress of the brush stroke. Defaults to a square root curve.
    ---@param self UIBrushStroke
    ---@param value number  # number between 0 and 1.0
    ---@return number
    ComputeDecayInterpolation = function(self, value)
        return math.sqrt(1 - value)
    end,

    ---@param self UIBrushStroke
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

    --- Starts a thread that will destroy the brush stroke after the specified duration. If the brush stroke is already decaying then the decay duration is reset.
    ---@param self UIBrushStroke
    ---@param duration number
    StartDecay = function(self, duration)
        if self.Decay then
            KillThread(self.Decay.ThreadInstance)
        end

        self.Decay = {
            Duration = duration,
            StartTime = CurrentTime(),
            ThreadInstance = self.Trash:Add(ForkThread(self.DecayThread, self, duration))
        }
    end,

    --- Destroys the brush stroke after the specified duration.
    ---@param self UIBrushStroke
    ---@param duration number
    DecayThread = function(self, duration)
        while self:GetDecayProgress() < 1.0 do
            WaitFrames(10)
        end

        self:Destroy()
    end,

    ---------------------------------------------------------------------------
    --#region Collision detection for interactions

    --- Computes the bounding box of the brush stroke and caches it.
    ---@param self UIBrushStroke
    ---@return UIBrushStrokeBoundingBox
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

    --- Computes the distance to the bounding box of the brush stroke.
    ---@param self UIBrushStroke
    ---@param px number
    ---@param py number
    ---@param pz number
    ---@return number   # nearest distance to the bounding box of the brush stroke.
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

    --- Computes the distance to the bounding box of the brush stroke.
    ---@param self UIBrushStroke
    ---@param point Vector
    ---@return number   # nearest distance to the bounding box of the brush stroke.
    DistanceToBoundingBox = function(self, point)
        return self:DistanceToBoundingBoxXYZ(point[1], point[2], point[3])
    end,

    --- Computes a precise distance to the brush stroke. It considers all successive
    --- pairs of samples to be a line segment. It computes the shortest distance
    --- over all line segments. This scales over the number of samples.
    ---
    --- It's better to first compute the distance to the bounding box to determine
    --- whether this precision is necessary.
    ---@param self UIBrushStroke
    ---@param px number
    ---@param py number
    ---@param pz number
    ---@return number   # nearest distance to the brush stroke
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

    --- Computes a precise distance to the brush stroke. It considers all successive
    --- pairs of samples to be a line segment. It computes the shortest distance
    --- over all line segments. This scales over the number of samples.
    ---
    --- It's better to first compute the distance to the bounding box to determine
    --- whether this precision is necessary.
    ---@param self UIBrushStroke
    ---@param point Vector
    ---@return number   # nearest distance to the brush stroke
    DistanceTo = function(self, point)
        return self:DistanceToXYZ(point[1], point[2], point[3])
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Simplification

    --- Computes the angle in radians of the bend of a line with two consecutive segments.
    ---@param self UIBrushStroke
    ---@param x0 number
    ---@param y0 number
    ---@param z0 number
    ---@param x1 number
    ---@param y1 number
    ---@param z1 number
    ---@param x2 number
    ---@param y2 number
    ---@param z2 number
    ---@return number?
    CurvatureOfSegments = function(self, x0, y0, z0, x1, y1, z1, x2, y2, z2)
        local dx1 = x1 - x0
        local dy1 = y1 - y0
        local dz1 = z1 - z0

        local dx2 = x2 - x1
        local dy2 = y2 - y1
        local dz2 = z2 - z1

        local len1Sq = dx1 * dx1 + dy1 * dy1 + dz1 * dz1
        local len2Sq = dx2 * dx2 + dy2 * dy2 + dz2 * dz2

        if len1Sq > 0.0 and len2Sq > 0.0 then
            local len1Inv = 1.0 / math.sqrt(len1Sq)
            local len2Inv = 1.0 / math.sqrt(len2Sq)
            local dot = (dx1 * dx2 + dy1 * dy2 + dz1 * dz2) * len1Inv * len2Inv
            return dot
        end
    end,

    --- Simplifies the brush stroke.
    ---@param self UIBrushStroke
    Simplify = function(self)

        local samples = self.Samples
        local coordinatesX = samples.CoordinatesX
        local coordinatesY = samples.CoordinatesY
        local coordinatesZ = samples.CoordinatesZ

        local count = table.getn(coordinatesX)
        if count < 3 then
            return
        end

        -- Tune between 0.98 (looser) and 0.9999 (stricter)
        local DotThreshold = 0.995

        -- Always keep the first sample
        local newIndex = 2

        for i = 2, count - 1 do
            -- use the most recent sample in the new list
            local x0 = coordinatesX[newIndex - 1]
            local y0 = coordinatesY[newIndex - 1]
            local z0 = coordinatesZ[newIndex - 1]

            -- use the samples in the old list
            local x1 = coordinatesX[i]
            local y1 = coordinatesY[i]
            local z1 = coordinatesZ[i]

            local x2 = coordinatesX[i + 1]
            local y2 = coordinatesY[i + 1]
            local z2 = coordinatesZ[i + 1]

            local dot = self:CurvatureOfSegments(x0, y0, z0, x1, y1, z1, x2, y2, z2)
            local keep = dot and dot < DotThreshold

            if keep then
                coordinatesX[newIndex] = x1
                coordinatesY[newIndex] = y1
                coordinatesZ[newIndex] = z1
                newIndex = newIndex + 1
            end
        end

        -- Always keep the last sample
        coordinatesX[newIndex] = coordinatesX[count]
        coordinatesY[newIndex] = coordinatesY[count]
        coordinatesZ[newIndex] = coordinatesZ[count]

        -- remove all other samples
        for k = newIndex + 1, table.getn(coordinatesX) do
            coordinatesX[k] = nil
            coordinatesY[k] = nil
            coordinatesZ[k] = nil
        end

        table.setn(coordinatesX, newIndex)
        table.setn(coordinatesY, newIndex)
        table.setn(coordinatesZ, newIndex)
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Debug functionality

    --- Computes the allocated bytes by this brush stroke.
    ---@param self UIBrushStroke
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

--- Creates a brush stroke that can be drawn to a world view.
---@param samples UIBrushStrokeSamples
---@param color Color
---@return UIBrushStroke
CreateBrushStroke = function(samples, color)
    local instance = BrushStroke(samples, color) --[[@as UIBrushStroke]]
    return instance
end
