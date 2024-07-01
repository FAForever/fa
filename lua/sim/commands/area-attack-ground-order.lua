--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

-- upvalue scope for performance
local TableGetn = table.getn

local IssueAttack = IssueAttack

local MathRound = math.round
local MathSqrt = math.sqrt
local MathCos = math.cos
local MathSin = math.sin
local MathPi = math.pi

---@param k number
---@param n number
---@param b number
---@return number
function ComputeRadius(k, n, b)
    if k > n - b then
        return 1 -- put on the boundary
    else
        return MathSqrt(k - 1 / 2) / MathSqrt(n - (b + 1) / 2) -- apply square root
    end
end

---@param units Unit[]
---@param target Vector
---@param radius number
function AreaAttackOrder(units, target, radius)
    local unitCount = TableGetn(units)
    if unitCount == 0 then
        return
    end

    local b = MathRound(2 *MathSqrt(unitCount))

    phi = (MathSqrt(5) + 1) / 2 -- golden ratio
    for k = 1, unitCount do
        r = ComputeRadius(k, unitCount, b)

        theta = (2 * MathPi * k) / (phi * phi)

        local tx = target[1] + radius * r * MathCos(theta)
        local tz = target[3] + radius * r * MathSin(theta)
        local ty = GetSurfaceHeight(tx, tz)
        IssueAttack(units, { tx, ty, tz })
    end
end
