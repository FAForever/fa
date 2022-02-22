
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

    return mean * (1 / n)
end

--- Computes the deviation of an array of values
-- @param t Table to compute values over, only array elements are used.
-- @param n Number of elements, defaults to table.getn(t)
-- @param m Mean of table, defaults to Mean(t, n)
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