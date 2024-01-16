--******************************************************************************************************
--** Copyright (c) 2024  FAForever
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

local TableGetn = table.getn

--- Computes the sum of an array of values
---@param t number[] Array to compute values over, only array elements are used.
---@param n number Count of elements, defaults to table.getn(t)
---@return number
function Sum(t, n)
    -- allow for optionals
    n = n or TableGetn(t)

    local sum = 0
    for k = 1, n do
        sum = sum + t[k]
    end

    return sum
end

--- Computes the mean of an array of values
---@param t number[] Array to compute values over, only array elements are used.
---@param n number Count of elements, defaults to table.getn(t)
---@return number
function Mean(t, n)
    -- allow for optionals
    n = n or TableGetn(t)

    -- compute mean
    local mean = 0
    for k = 1, n do
        mean = mean + t[k]
    end

    return mean * (1 / n)
end

--- Computes the standard deviation of an array of values
---@param t number[] Array to compute values over, only array elements are used.
---@param n number Count of elements, defaults to table.getn(t)
---@param m number Mean of table, defaults to Mean(t, n)
---@return number
function Deviation(t, n, m)
    -- allow for optionals
    n = n or TableGetn(t)
    m = m or Mean(t, n)

    -- compute deviation
    local i = 0
    local deviation = 0
    for k = 1, n do
        i = t[k] - m
        deviation = deviation + i * i
    end

    return deviation * (1 / n)
end
