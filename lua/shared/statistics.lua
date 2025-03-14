
local TableGetn = table.getn

--- Computes the sum of an array of values
-- @param t Table to compute values over, only array elements are used.
-- @param n Number of elements, defaults to table.getn(t)
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
-- @param t Table to compute values over, only array elements are used.
-- @param n Number of elements, defaults to table.getn(t)
function Mean(t, n)
    -- allow for optionals
    n = n or TableGetn(t)

    -- compute mean
    local mean = 0
    for k = 1, n do
        mean = mean + t[k]
    end

    return mean / n
end

--- Computes the deviation of an array of values
---@param t number[] Table to compute values over, only array elements are used.
---@param n? integer Number of elements, defaults to table.getn(t)
---@param m? number Mean of table, defaults to Mean(t, n)
function Deviation(t, n, m)

    -- allow for optionals
    n = n or TableGetn(t)
    m = m or Mean(t, n)

    -- compute deviation
    local variance = 0
    for k = 1, n do
        local residual = t[k] - m
        variance = variance + residual * residual
    end

    return math.sqrt(variance / (n - 1)) -- Bessel's correction
end


---@param t number[]
---@param n? integer
---@param m? number
---@param d? number
function Skewness(t, n, m, d)
    n = n or TableGetn(t)
    m = m or Mean(t, n)

    if d then
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            skewness = skewness + residual * residual * residual
        end
        return skewness / d
    else
        local variance = 0
        local skewness = 0
        for k = 1, n do
            local residual = t[k] - m
            local residualSq = residual * residual
            variance = variance + residualSq
            skewness = skewness + residualSq * residual
        end
        variance = variance / (n - 1)
        return skewness / math.sqrt(variance)
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
    if n < 5 then
        return t, n -- no quartiles
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
