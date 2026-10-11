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
        if d == 0 then
            return 0
        end
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            skewness = skewness + residual * residual * residual
        end
        return skewness / (n * d * d * d)
    else
        local stddev = 0
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            local residualSq = residual * residual
            stddev = stddev + residualSq
            skewness = skewness + residualSq * residual
        end
        if stddev == 0 then
            return 0
        end
        stddev = math.sqrt(stddev / (n - 1))
        skewness = skewness / n
        return skewness / (stddev * stddev * stddev)
    end
end

-- Two-sided 95% critical values of Student's t, indexed by degrees of freedom
local TCritical95Table = {
    12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228,
    2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101, 2.093, 2.086,
    2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042,
}

--- Gets the two-sided 95% critical value of Student's t distribution. Rounds up to the next
--- tabulated degrees of freedom, so it never understates the interval.
---@param df integer
---@return number
function TCritical95(df)
    if df < 1 then
        return TCritical95Table[1]
    elseif df <= 30 then
        return TCritical95Table[df]
    elseif df <= 40 then
        return 2.021
    elseif df <= 60 then
        return 2.000
    elseif df <= 120 then
        return 1.980
    end
    return 1.960
end

--- Computes the half-width of the 95% confidence interval of a mean, or nil when there are not
--- enough samples
---@param deviation number
---@param n integer
---@return number?
function ConfidenceMargin95(deviation, n)
    if n < 2 then
        return nil
    end
    return TCritical95(n - 1) * deviation / math.sqrt(n)
end

--- Computes the quartiles of a data set (needs at least 5 elements)
---@param t number[]
---@param n? integer
---@return number minimum
---@return number q1
---@return number median
---@return number q2
---@return number maximum
function GetQuartiles(t, n)
    n = n or TableGetn(t)
    if n < 5 then
        return
    end

    local sorted = {}
    for i = 1, n do
        sorted[i] = t[i]
    end
    table.sort(sorted)

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
    return sorted[1], q1, q2, q3, sorted[n]
end

--- Removes items that are more than 1.5 times the interquartile range away from
--- the median into a new table
---@param t number[]
---@param n? integer
---@return number[] trimmed
---@return integer newSize
function RemoveOutliers(t, n)
    n = n or TableGetn(t)

    local trimmed = {}
    if n < 5 then
        for i = 1, n do
            trimmed[i] = t[i]
        end
        return trimmed, n
    else
        local _, q1, q2, q3, _ = GetQuartiles(t, n)
        local iqr15 = (q3 - q1) * 1.5

        local size = 0
        for i = 1, n do
            local result = t[i]
            if math.abs(result - q2) <= iqr15 then
                size = size + 1
                trimmed[size] = result
            end
        end
        return trimmed, size
    end
end