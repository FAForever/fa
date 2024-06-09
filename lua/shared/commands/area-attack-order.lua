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

local MathRound = math.round
local MathSqrt = math.sqrt
local MathCos = math.cos
local MathSin = math.sin
local MathPi = math.pi

---@type number
MaximumRadius = 24

---@param k number
---@param n number
---@param b number
---@return number
local function ComputeRadius(k, n, b)
    if k > n - b then
        return 1 -- put on the boundary
    else
        return MathSqrt(k - 1 / 2) / MathSqrt(n - (b + 1) / 2) -- apply square root
    end
end

---@param count number
---@param radius number
---@param cx number
---@param cy number
---@param cz number
---@param cache? Vector[]
---@return Vector[]
function ComputeAttackLocations(count, radius, cx, cy, cz, cache)

    -- Originates from:
    -- https://stackoverflow.com/questions/28567166/uniformly-distribute-x-points-inside-a-circle

    cache = cache or {}

    local b = 0

    phi = (MathSqrt(5) + 1) / 2 -- golden ratio

    for k = 1, count do
        r = ComputeRadius(k, count, b)

        theta = (2 * MathPi * k) / (phi * phi)

        local target = cache[k] or {}
        cache[k] = target

        target[1] = cx + radius * r * MathCos(theta)
        target[2] = cy
        target[3] = cz + radius * r * MathSin(theta)
    end

    return cache
end
