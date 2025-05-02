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
---@param t number[]
---@param n? integer
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
---@param t number[]
---@param n? integer
function Mean(t, n)
    -- allow for optionals
    n = n or TableGetn(t)
    if n == 0 then
        return 0
    end

    -- compute mean
    local mean = 0
    for k = 1, n do
        mean = mean + t[k]
    end

    return mean / n
end

--- Computes the deviation of an array of values
---@param t number[]
---@param n? integer
---@param m? number center of the data, defaults to the mean
function Deviation(t, n, m)
    -- allow for optionals
    n = n or TableGetn(t)
    if n < 2 then
        return 0
    end
    m = m or Mean(t, n)

    -- compute deviation
    local variance = 0
    for k = 1, n do
        local residual = t[k] - m
        variance = variance + residual * residual
    end

    return math.sqrt(variance / (n - 1)) -- Bessel's correction
end


--- Computes the skewness of an array of values
---@param t number[]
---@param n? integer
---@param m? number center of the data, defaults to the mean
---@param d? number deviation of the data, defaults to the standard deviation
function Skewness(t, n, m, d)
    n = n or TableGetn(t)
    if n < 2 then
        return 0
    end
    m = m or Mean(t, n)

    if d then
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            skewness = skewness + residual * residual * residual
        end
        return skewness / (n * d)
    else
        local stddev = 0
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            local residualSq = residual * residual
            stddev = stddev + residualSq
            skewness = skewness + residualSq * residual
        end
        stddev = math.sqrt(stddev / (n - 1))
        skewness = skewness / n
        return skewness / (stddev * stddev * stddev)
    end
end

--- Removes items that are more than 1.5 times the interquartile range away from
--- the median into a new table
---@param t number[]
---@param n? integer
---@return number[] trimmed
---@return integer newSize
function RemoveOutliers(t, n)
    n = n or TableGetn(t)

    local sorted = {}
    for i = 1, n do
        sorted[i] = t[i]
    end
    table.sort(sorted)
    if n < 5 then
        return sorted, n -- no quartiles
    end

    local rawHalf = n * 0.5
    local quart2 = math.ceil(rawHalf)

    local rawQuart = quart2 * 0.5
    local quart1 = math.floor(rawQuart)
    local quart3 = quart2 + quart1

    local q2 = sorted[quart2]
    if quart2 == rawHalf then
        q2 = (q2 + sorted[quart2 + 1]) * 0.5
        quart3 = quart3 + 1 -- exclude the median
    end

    local q1 = sorted[quart1]
    local q3 = sorted[quart3]
    if quart1 ~= rawQuart then
        q1 = (q1 + sorted[quart1 + 1]) * 0.5
        q3 = (q3 + sorted[quart3 + 1]) * 0.5
    end
    local iqr15 = (q3 - q1) * 1.5

    local trimmed = {}
    local size = 0
    for i = 1, n do
        local result = sorted[i]
        if math.abs(result - q2) < iqr15 then
            size = size + 1
            trimmed[size] = result
        end
    end

    return trimmed, size
end
