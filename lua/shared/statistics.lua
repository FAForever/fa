local MathMod = math.mod
local MathFloor = math.floor
local TableGetn = table.getn


function Factorial(num)
    if num < 0 then
        error("arithmetic error: factorial operand is negative")
    end
    local fac = 1
    for i = 2, num do
        fac = fac * i
    end
    return fac
end

-- this one allows half-integers (including -0.5) thanks to the gamma function
local factorialNegHalf = -2 * math.sqrt(math.pi)
function Factorial2(num)
    if num <= -1 then
        error("arithmetic error: factorial2 operand+1 is non-positive")
    end
    local frac = num - MathFloor(num)
    if frac == 0.0 then
        local fac = 1
        for i = 2, num do
            fac = fac * i
        end
        return fac
    elseif frac == 0.5 then
        local fac = factorialNegHalf * 0.5
        local i = 1.5
        while i <= num do
            fac = fac * i
        end
        return fac
    elseif frac == -0.5 then
        return factorialNegHalf
    else
        error("arithmetic error: factorial2 operand is not half-integer or integer")
    end
end

function DoubleFactorial(value)
    if value == 0 or value == 1 then
        return 1
    end
    local dfac = 1
    local remainder = MathMod(value, 2)
    if value <= -1 then
        if remainder == 0 then
            error("arithmetic error: double factorial operand is negative even integer")
        end
        -- using a double factorial allows us to use negative odds, since we don't have to
        -- divide by zero to go backwards
        for i = -3, value, -2 do
            dfac = dfac * i
        end
        return -1 / dfac
    else
        for i = 2 - remainder, value, 2 do
            dfac = dfac * i
        end
    end
    return dfac
end

function Permutations(n, k)
    local fac = 1
    for i = k + 1, n do
        fac = fac * i
    end
    return fac
end

function Combinations(n, k)
    local fac = 1
    local lower, upper = n - k
    -- start at the one that cancels out more terms
    if k < lower then
        upper, lower = lower, k
    else
        upper = k
    end
    for i = upper + 1, n do
        fac = fac * i
    end
    -- calculate numerator and denomenator separately to save divisions and precision
    local div = lower
    for i = 2, lower - 1 do
        div = div * i
    end
    fac = fac / div
    return fac
end

local partitions = {[0] = 1, 1, 2, 3, 5, 7, 11, 15, 22, 30, 42, 56, 77, 101}
function Partitions(n)
    local part = partitions[n]
    if part then
        return part
    end
    if n < 0 then
        return 0
    end
    -- generalized pentagonal numbers form a recurrence relation with partitions
    -- partition(n) = sum((-1)^(k-1) * partition(n - g(k))) for k = 1 to whenever the partitions become 0 
    -- (i.e. the index is negative)
    -- where g(n) is the nth generalized pentagonal number: 1,2, 5,7, 12,15 ... (3k^2±k)/2 
    -- (incrementing n for alternating signs of the same k)
    -- rather than recalculate the index each time, we'll simply subtract the delta of the function from
    -- the index, spread over both generalized alternations
    --    (3(k-1)^2 + (k-1))/2 - (3k^2 - k)/2 = (-6k+3 + 2k-1)/2 = -2k + 1
    --    (3 k   ^2 -  k   )/2 - (3k^2 + k)/2 = (        2k  )/2 = -k
    -- interestingly, the math requires size zero to have one partition
    part = 0
    local k = 0
    local index = n
    -- this only checks the first of the four indexes (it's a little faster at high partition sizes)
    -- undershooting the partition is fine, since all negative partitions are 0 anyway
    while index > 0 do
        -- unroll both alternations
        k = k + 1
        index = index - 2 * k + 1
        part = part + Partitions(index)
        index = index - k
        part = part + Partitions(index)

        k = k + 1
        index = index - 2 * k + 1
        part = part - Partitions(index)
        index = index - k
        part = part - Partitions(index)
    end
    partitions[n] = part
    return part
end



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