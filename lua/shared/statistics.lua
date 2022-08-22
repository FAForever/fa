local MathCeil = math.ceil
local MathFloor = math.floor
local MathSqrt = math.sqrt
local TableGetn = table.getn
local TableSort = table.sort
local rawget = rawget

-- Hyndman-Fan taxonomy
QuantileFunctions = {
    -- piecewise functions

    -- R1 returns the value above the quantile
    [1] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        return sorted[MathCeil(n * q)]
    end,
    -- R2 averages the two closest numbers
    [2] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = n * q
        local pos = MathCeil(h)
        local val = sorted[pos]
        if h == pos then
            return val
        end
        return (val + sorted[pos + 1]) * 0.5
    end,
    -- R3 picks closest number (using banker's rounding to remove cumulative error)
    [3] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        return sorted[MATH_IRound(n * q - 0.5)]
    end,

    -- interpolating functions

    -- R4 linearly interpolates between quantiles
    [4] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = n * q
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
    -- R5 linearly interpolates between midpoints of the quantiles
    [5] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = n * q + 0.5
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
    -- R6 linearly interpolates between quantiles, adjusting for the interval
    [6] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = (n + 1) * q
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
    -- R7 linearly interpolates between quantiles, adjusting for the interval using modes
    [7] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = (n + 1) * q + 1
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
    -- R8 linearly interpolates qunatiles, adjusting for the interval using medians;
    -- the Hyndman-Fan recommended default that nobody uses
    [8] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = (n + 0.3333333333333) * q + 0.3333333333333
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
    -- R9 linearly interpolates quantile; approximately unbaised for the normal distribution
    [9] = function(sorted, n, q)
        if q <= 0 then
            return sorted[1]
        elseif q >= 1 then
            return sorted[n]
        end
        local h = (n + 0.25) * q + 0.325
        local floor = MathFloor(h)
        local lower = sorted[floor]
        if h == floor then
            return lower
        end
        return lower + (h - floor)(sorted[h + 1] - lower)
    end,
}

QuartileFunctions = {
    -- Tukey: quartiles are medians of the resulting sets with the median included
    [1] = function(sorted, n)
        local rawHalf = n * 0.5
        local quart2 = MathCeil(rawHalf)

        local rawQuart = quart2 * 0.5
        local quart1 = MathCeil(rawQuart)
        local quart3 = quart2 + quart1

        local q2 = sorted[quart2]
        if quart2 == rawHalf then
            q2 = (q2 + sorted[quart2 + 1]) * 0.5
        else
            quart3 = quart3 - 1 -- include the median
        end

        local q1 = sorted[quart1]
        local q3 = sorted[quart3]
        if quart1 == rawQuart then
            q1 = (q1 + sorted[quart1 + 1]) * 0.5
            q3 = (q3 + sorted[quart3 + 1]) * 0.5
        end

        return q1, q2, q3
    end,
    -- Moore and McCabe: quartiles are medians of the resulting sets with the median excluded
    [2] = function(sorted, n)
        if n == 1 then
            local val = sorted[1]
            return val, val, val
        end
        local rawHalf = n * 0.5
        local quart2 = MathCeil(rawHalf)

        local rawQuart = quart2 * 0.5
        local quart1 = MathFloor(rawQuart)
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

        return q1, q2, q3
    end,
    -- Mendenhall and Sincich: quartiles are the closest interpolated values
    [3] = function(sorted, n)
        local rawHalf = n * 0.5
        local rawQuart = n * 0.25
        -- index(q1) = (n + 1) / 4
        -- index(q3) = (n + 1) 3/4
        local quart1 = MathFloor(rawQuart + 0.75) -- quarter round up
        local quart2 = MathCeil(rawHalf)
        local quart3 = MathCeil(rawHalf + rawQuart - 0.25) -- 3quarter round down

        local q1 = sorted[quart1]
        local q2 = sorted[quart2]
        local q3 = sorted[quart3]
        if quart2 == rawHalf then
            q2 = (q2 + sorted[quart2 + 1]) * 0.5
        end
        return q1, q2, q3
    end,
    -- Minitab: quartiles are interpolated between the nearest values, from the inside
    [4] = function(sorted, n)
        local rawHalf = n * 0.5
        local rawQuart = n * 0.25 + 0.25
        local raw3Quart = rawHalf + rawQuart + 0.5
        -- index(q1) = (n + 1) / 4
        -- index(q3) = (n + 1) 3/4
        local quart1 = MathCeil(rawQuart)
        local quart2 = MathCeil(rawHalf)
        local quart3 = MathCeil(raw3Quart)

        local q1 = sorted[quart1]
        local q2 = sorted[quart2]
        local q3 = sorted[quart3]
        if quart2 == rawHalf then
            q2 = (q2 + sorted[quart2 + 1]) * 0.5
        end
        if quart1 ~= rawQuart then
            local frac = quart1 - rawQuart
            q1 = q1 * (1 - frac) + sorted[quart1 + 1] * (frac)
            frac = quart3 - raw3Quart
            q3 = q3 * (1 - frac) + sorted[quart3 + 1] * (frac)
        end
        return q1, q2, q3
    end,
    -- Hyndman and Fan: quartiles are interpolated between the nearest values
    [5] = function(sorted, n)
        local rawHalf = n * 0.5
        local rawQuart = n * 0.25 + 0.25
        local raw3Quart = rawHalf + rawQuart + 0.5
        local quart1 = MathCeil(rawQuart)
        local quart2 = MathCeil(rawHalf)
        local quart3 = MathCeil(raw3Quart)

        local q1 = sorted[quart1]
        local q2 = sorted[quart2]
        local q3 = sorted[quart3]
        if quart2 == rawHalf then
            q2 = (q2 + sorted[quart2 + 1]) * 0.5
        end
        if quart1 ~= rawQuart then
            local frac = quart1 - rawQuart
            q1 = q1 * (1 - frac) + sorted[quart1 + 1] * (frac)
        end
        if quart3 ~= raw3Quart then
            local frac = quart3 - raw3Quart
            q3 = q3 * (1 - frac) + sorted[quart3 + 1] * (frac)
        end
        return q1, q2, q3
    end,
    -- van Freund and Perles: quartiles are reverse-interpolated between the nearest values
    [6] = function(sorted, n)
        local rawHalf = n * 0.5
        local rawQuart = n * 0.25 + 0.75
        local raw3Quart = rawHalf + rawQuart - 0.5
        -- index(q1) = (1n + 3) / 4
        -- index(q3) = (3n + 1) /4
        local quart1 = MathCeil(rawQuart)
        local quart2 = MathCeil(rawHalf)
        local quart3 = MathCeil(raw3Quart)

        local q1 = sorted[quart1]
        local q2 = sorted[quart2]
        local q3 = sorted[quart3]
        if quart2 == rawHalf then
            q2 = (q2 + sorted[quart2 + 1]) * 0.5
        end
        if quart1 ~= rawQuart then
            local frac = quart1 - rawQuart
            q1 = q1 * (1 - frac) + sorted[quart1 + 1] * (frac)
        end
        if quart3 ~= raw3Quart then
            local frac = quart3 - raw3Quart
            q3 = q3 * (1 - frac) + sorted[quart3 + 1] * (frac)
        end
        return q1, q2, q3
    end,
}


function Sort(data, n)
    n = n or TableGetn(data)
    sorted = {}
    for i = 1, n do
        sorted[i] = data[i]
    end
    TableSort(sorted)
    return sorted
end

---@param sorted number[]
---@param q number [0,1]
---@param n? number
---@param quantMode? number
---@return number
function Quantile(sorted, q, n, quantMode)
    n = n or TableGetn(sorted)
    quantMode = quantMode or 7
    return QuantileFunctions[quantMode](sorted, n, q)
end

---@param sorted number[]
---@param n number
---@param quartMode? number
---@return number q1
---@return number med
---@return number q3
function Quartiles(sorted, n, quartMode)
    n = n or TableGetn(sorted)
    quartMode = quartMode or 2
    return QuartileFunctions[quartMode](sorted, n)
end

---
---@param sorted number[]
---@param n? number
---@return number | number[]
function Mode(sorted, n)
    n = n or TableGetn(sorted)
    local tableMax = 1
    local mode = {1}
    local modeCount = 1
    local cur = sorted[1]
    local i = 1
    while i < n do
        i = i + 1
        local j = i
        local next = sorted[i]
        while next == cur do
            i = i + 1
            next = sorted[i]
        end
        cur = next
        local count = i - j
        if count > tableMax then
            tableMax = count
            modeCount = 1
            mode[modeCount] = cur
        elseif count == tableMax then
            modeCount = modeCount + 1
            mode[modeCount] = cur
        end
    end
    -- if there was only one value, flatten the table
    if modeCount == 1 then
        mode = mode[1]
    else
        -- trim dangling values, since we reused the table
        i = modeCount + 1
        local trim = mode[i]
        while trim do
            mode[i] = nil
            i = i + 1
            trim = mode[i]
        end
    end
    return mode
end

---@param data number[]
---@param n? number defaults to `table.getn(data)`
---@param quartMode? number defaults to `1`
---@return number mean
---@return number minimum
---@return number quartile1
---@return number median
---@return number quartile3
---@return number maximum
---@return number | number[] mode
function Summary(data, n, quartMode)
    n = n or TableGetn(data)
    quartMode = quartMode or 1

    local sorted = {}
    local total = 0
    for i = 1, n do
        local val = data[i]
        total = total + val
        sorted[i] = val
    end

    TableSort(sorted)

    local mean = total / n
    local min = sorted[1]
    local q1, med, q3 = Quartiles(sorted, n, quartMode)
    local max = sorted[n]
    local mode = Mode(sorted, n)
    return mean, min, q1, med, q3, max, mode
end

--- Computes the sum of an array of values
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number Number of elements
---@return number
function Sum(data, n)
    n = n or TableGetn(data)
    local sum = 0
    for k = 1, n do
        sum = sum + data[k]
    end
    return sum
end

--- Computes the mean of an array of values (the first raw moment)
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number
---@return number
function Mean(data, n)
    n = n or TableGetn(data)
    local mean = 0
    for k = 1, n do
        mean = mean + data[k]
    end
    return mean / n
end

function MeanAndSampVariance(data, n)
    n = n or TableGetn(data)
    local u1, u2 = 0, 0
    for k = 1, n do
        local value = data[k]
        u1 = u1 + value
        u2 = u2 + value*value
    end
    -- E(X)
    local mean = u1 / n
    -- E((X - E(X))^2) = E(X^2) - E(X)^2; reduce degrees of freedom by one due to calculating the
    -- center from the data, since it's an estimator and not the true population mean
    local var = (u2 - u1*u1) / (n - 1)
    return mean, var
end

function AdjustToSampVariance(popVariance, n)
    return popVariance * n / (n - 1)
end
function AdjustToPopVariance(sampVariance, n)
    return sampVariance * (n - 1) / n
end
--- Computes the variance of an array of values (the second central moment)
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number Number of elements
---@param center? number Center of measure
---@param biasCor? number Estimation bias adjustment, defaults to `1`
---@return number
function Variance(data, n, center, biasCor)
    n = n or TableGetn(data)
    center = center or Mean(data, n)
    biasCor = biasCor or 1

    local variance = 0
    for k = 1, n do
        local residual = data[k] - center
        variance = variance + residual*residual
    end
    return variance / (n - biasCor)
end
function PopVariance(data, n, center)
    return Variance(data, n, center, 0)
end



function SkewnessFromMoments(m3, m2)
    return m3 / MathSqrt(m2*m2*m2)
end
function StandardizeSkewness(m3, s)
    return m3 / (s*s*s)
end
function AdjustToSampSkewness(skewness, n)
    return n*n * skewness / ((n - 1) * (n - 2))
end
function NonparametericSkewness(mean, median, deviation)
    return (mean - median) / deviation
end
--- Computes the skewness of an array of values (the third standardized central moment)
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number Number of elements
---@param center? number Center of measure
---@param deviation? number Standardizing deviation, defaults to `StdDeviation(data, n, center, biasCor)`
---@param biasCor? number used if `deviation` is absent, defaults to `1`
---@return number skewness
---@return number deviation
function Skewness(data, n, center, deviation, biasCor)
    n = n or TableGetn(data)
    center = center or Mean(data, n)

    local m3 = 0
    if deviation then
        for k = 1, n do
            local residual = data[k] - center
            m3 = m3 + residual*residual*residual
        end
    else
        biasCor = biasCor or 1

        deviation = 0
        for k = 1, n do
            local residual = data[k] - center
            local sqrResidual = residual * residual
            deviation = deviation + sqrResidual
            m3 = m3 + sqrResidual * sqrResidual
        end
        deviation = MathSqrt(deviation / (n - biasCor))
    end
    m3 = m3 / n
    return StandardizeSkewness(m3, deviation), deviation
end
function PopSkewness(data, n, center, deviation)
    return Skewness(data, n, center, deviation, 0)
end
function SampSkewness(data, n, center, deviation)
    local skewness
    skewness, deviation = Skewness(data, n, center, deviation)
    return AdjustToSampSkewness(skewness, n), deviation
end

function KurtosisFromMoments(m4, m2)
    return m4 / (m2*m2)
end
function StandardizeKurtosis(m4, s)
    local sqr = s*s
    return m4 / (sqr*sqr)
end
function AdjustToExcessKurtosis(kurtosis)
    return kurtosis - 3
end
function AdjustToNormallyCorrectedExcessKurtosis(kurtosis, n)
    return (n - 1) * ((n + 1) * (kurtosis - 3) + 6) / ((n - 2) * (n - 3))
end
--- Computes the kurtosis of an array of values (the fourth standardized central moment)
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number Number of elements
---@param center? number Center of measure
---@param variance? number Standardizing variance, defaults to `PopVariance(data, n, center)`
---@return number kurtosis
---@return number variance
function Kurtosis(data, n, center, variance)
    n = n or TableGetn(data)
    center = center or Mean(data, n)

    local m4 = 0
    if variance then
        for k = 1, n do
            local residual = data[k] - center
            local sqrResidual = residual * residual
            m4 = m4 + sqrResidual * sqrResidual
        end
    else
        variance = 0
        for k = 1, n do
            local residual = data[k] - center
            local sqrResidual = residual * residual
            variance = variance + sqrResidual
            m4 = m4 + sqrResidual * sqrResidual
        end
        variance = variance / n
    end
    m4 = m4 / n
    return KurtosisFromMoments(m4, variance), variance
end
--- Computes the excess kurtosis of an array of values (the fourth standardized cumulant), which
--- is the kurtotic difference from the normal distribution
---@param data any
---@param n any
---@param center any
---@return number
---@return number
function ExcessKurtosis(data, n, center)
    local kurtosis, variance = Kurtosis(data, n, center)
    return kurtosis - 3, variance
end
function NormallyCorrectedExcessKurtosis(data, n, center)
    local kurtosis, variance = Kurtosis(data, n, center)
    return AdjustToNormallyCorrectedExcessKurtosis(kurtosis, n), variance
end

function AdjustToBasicCorrectedStdDeviation(deviation, n)
    return deviation * MathSqrt(n / (n - 1.5))
end
function AdjustToNormallyCorrectedStdDeviation(deviation, excessKurtosis, n)
    return deviation * MathSqrt(n / (n - 1.5 - 0.25 * excessKurtosis))
end
--- Computes the standard deviation of an array of values
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n number Number of elements
---@param center number Center of measure
---@param biasCor? number Estimation bias adjustment, defaults to `1`
---@return number
function StdDeviation(data, n, center, biasCor)
    return MathSqrt(Variance(data, n, center, biasCor))
end
function PopStdDeviation(data, n, center)
    return MathSqrt(Variance(data, n, center, 0))
end
function BasicCorrectedStdDeviation(data, n, center)
    return MathSqrt(Variance(data, n, center, 1.5))
end
function NormallyCorrectedStdDeviation(data, n, center)
    local excessKurt, biasedVar = NormallyCorrectedExcessKurtosis(data, n, center)
    return MathSqrt(n * biasedVar / (n - 1.5 - 0.25 * excessKurt))
end

--- Computes the mean absolute deviation of an array of values
---@param data number[] Table to compute values over, only array elements to `n` are used
---@param n? number Number of elements
---@param center? number Center of measure
---@return number
function AvgAbsDeviation(data, n, center)
    n = n or TableGetn(data)
    center = center or Mean(data, n)
    biasCor = biasCor or 1
    local variance = 0
    for k = 1, n do
        local residual = data[k] - center
        if residual < 0 then
            variance = variance - residual
        else
            variance = variance + residual
        end
    end
    return variance / n
end


function GenerateRawMoments(data, n)
    n = n or TableGetn(data)
    local u1, u2, u3, u4 = 0, 0, 0, 0
    for i = 1, n do
        local val = data[i]
        u1 = u1 + val
        local valP = val * val
        u2 = u2 + valP
        valP = valP * val
        u3 = u3 + valP
        valP = valP * val
        u4 = u4 + valP
    end
    return u1 / n, u2 / n, u3 / n, u4 / n
end
function GenerateRawMomentsUpTo(data, degree, n)
    n = n or TableGetn(data)
    local moments = {0}
    for i = 2, degree do
        moments[i] = 0
    end
    for i = 1, n do
        local val = data[i]
        moments[1] = moments[1] + val
        local valP = val
        for j = 2, degree do
            valP = valP * val
            moments[j] = moments[j] + valP
        end
    end
    for i = 1, degree do
        moments[i] = moments[i] / n
    end
    return moments
end

---@param data number[]
---@param n? number
---@param center? number
---@return number m1
---@return number m2
---@return number m3
---@return number m4
function GenerateCentralMoments(data, n, center)
    n = n or TableGetn(data)
    if center then
        -- adding up all differences from the mean should yield 0 for m1
        -- but maybe they aren't passing in the mean
        local m1, m2, m3, m4 = 0, 0, 0, 0
        for i = 1, n do
            local residual = data[i] - center
            m1 = m1 + residual
            local residualPow = residual * residual
            m2 = m2 + residualPow
            residualPow = residualPow * residual
            m3 = m3 + residualPow
            residualPow = residualPow * residual
            m4 = m4 + residualPow
        end
        return m1 / n, m2 / n, m3 / n, m4 / n
    end

    center = Mean(data, n)
    -- adding up all differences from the mean should yield 0 for m1
    -- but maybe they aren't passing in the mean
    local m2, m3, m4 = 0, 0, 0
    for i = 1, n do
        local residual = data[i] - center
        local residualPow = residual * residual
        m2 = m2 + residualPow
        residualPow = residualPow * residual
        m3 = m3 + residualPow
        residualPow = residualPow * residual
        m4 = m4 + residualPow
    end
    return 0, m2 / n, m3 / n, m4 / n
end

---@param data number[]
---@param degree? number defaults to 4
---@param n? number
---@param center? number
---@return number[]
function GenerateCentralMomentsUpTo(data, degree, n, center)
    n = n or TableGetn(data)
    if center then
        local moments = {}
        for i = 1, degree do
            moments[i] = 0
        end
        for i = 1, n do
            local residual = data[i] - center
            local residualPow = 1
            for j = 1, degree do
                residualPow = residualPow * residual
                moments[j] = moments[j] + residualPow
            end
        end
        for i = 1, degree do
            moments[i] = moments[i] / n
        end
        return moments
    end

    center = Mean(data, n)

    local moments = {0}
    for i = 2, degree do
        moments[i] = 0
    end
    for i = 1, n do
        local residual = data[i] - center
        local residualPow = residual
        for j = 2, degree do
            residualPow = residualPow * residual
            moments[j] = moments[j] + residualPow
        end
    end
    for i = 2, degree do
        moments[i] = moments[i] / n
    end
    return moments
end



doscript("/lua/shared/lazycache.lua")

---@class StatObject : LazyCache
---
---@field data number[]
---@field iqr? number
---@field m2? number
---@field m3? number
---@field m4? number
---@field max? number
---@field mean? number
---@field meanAbsDev? number
---@field median? number
---@field medianAbsDev? number
---@field min? number
---@field mode? number | number[]
---@field modeAbsDev? number
---@field n number
---@field q1? number
---@field q3? number
---@field quantileMode? number
---@field quartileMode? number
---@field sorted? number[]
---@field sum? number
---@field u2? number
---@field u3? number
---@field u4? number
---
---@field MinMax function
---@field RemoveOutliers function
---@field RecursivelyRemoveOutliers function
---@field Quantile function
---@field Quartiles function
---@field Summary function
StatObject = LazyCacheClass({
    sorted = function(self)
        return Sort(self.data)
    end;

    sum = function(self)
        return Sum(self.data, self.n)
    end;

    -- centers

    mean = function(self)
        return Mean(self.data, self.n)
    end;
    mode = function(self)
        return Mode(self.data, self.n)
    end;
    median = function(self)
        local q1, median, q3 = Quartiles(self.sorted, self.n, self.quartileMode)
        self.q1 = q1
        self.q3 = q3
        return median
    end;

    -- extrema

    min = function(self)
        local sorted = rawget(self, "sorted")
        if sorted then
            return sorted[1]
        end
        local data = self.data
        local min = data[1]
        for i = 2, self.n do
            local val = data[i]
            if val < min then
                min = val
            end
        end
        return min
    end;
    max = function(self)
        local sorted = rawget(self, "sorted")
        if sorted then
            return sorted[self.n]
        end
        local data = self.data
        local max = data[1]
        for i = 2, self.n do
            local val = data[i]
            if val > max then
                max = val
            end
        end
        return max
    end;
    range = function(self)
        local min, max = self:MinMax()
        return max - min
    end;

    -- quartiles

    q1 = function(self)
        local q1, median, q3 = Quartiles(self.sorted, self.n, self.quartileMode)
        self.median = median
        self.q3 = q3
        return q1
    end;
    q3 = function(self)
        local q1, median, q3 = Quartiles(self.sorted, self.n, self.quartileMode)
        self.q1 = q1
        self.median = median
        return q3
    end;
    iqr = function(self)
        return self.q3 - self.q1
    end;

    -- raw moments

    u2 = function(self)
        local u1, u2, u3, u4 = GenerateRawMoments(self.data, self.n)
        self.mean = u1
        self.u3 = u3
        self.u4 = u4
        return u2
    end;
    u3 = function(self)
        local u1, u2, u3, u4 = GenerateRawMoments(self.data, self.n)
        self.mean = u1
        self.u2 = u2
        self.u4 = u4
        return u3
    end;
    u4 = function(self)
        local u1, u2, u3, u4 = GenerateRawMoments(self.data, self.n)
        self.mean = u1
        self.u2 = u2
        self.u3 = u3
        return u4
    end;

    -- central moments

    m2 = function(self)
        local u2, u1 = self.u2, self.mean
        -- E((X - E(X))^2)
        -- = E(X^2  - 2 X E(X)    + E(X)^2)
        -- = E(X^2) - 2 E(X) E(X) + E(X)^2
        -- = E(X^2) - E(X)^2
        return u2 - u1*u1
    end;
    m3 = function(self)
        local u3, u2, u1 = self.u3, self.u2, self.mean
        -- E((X - E(X))^3)
        -- = E(X^3  - 3 X^2 E(X)    + 3 X E(X)^2    - E(X)^3)
        -- = E(X^3) - 3 E(X^2) E(X) + 3 E(X) E(X)^2 - E(X)^3
        -- = E(X^3) - 3 E(X^2) E(X) + 2 E(X)^3
        return u3 - 3 * u2 * u1 + 2 * u1*u1*u1
    end;
    m4 = function(self)
        local u4, u3, u2, u1 = self.u4, self.u3, self.u2, self.mean
        -- E((X - E(X))^4)
        -- = E(X^4  - 4 X^3 E(X)    + 6 X^2 E(X)^2    - 4 X E(X)^3    + E(X)^4)
        -- = E(X^4) - 4 E(X^3) E(X) + 6 E(X^2) E(X)^2 - 4 E(X) E(X)^3 + E(X)^4
        -- = E(X^4) - 4 E(X^3) E(X) + 6 E(X^2) E(X)^2 - 3 E(X)^4
        local u1Sqr = u1 * u1
        return u4 - 4 * u3 * u1 + 6 * u2 * u1Sqr - 3 * u1Sqr*u1Sqr
    end;

    -- absolute deviation

    meanAbsDev = function(self)
        return AvgAbsDeviation(self.data, self.n, self.mean)
    end;
    medianAbsDev = function(self)
        return AvgAbsDeviation(self.data, self.n, self.median)
    end;
    modeAbsDev = function(self)
        local center = self.mode
        if type(center) == "table" then
            center = Mean(center)
        end
        return AvgAbsDeviation(self.data, self.n, center)
    end;
}, {
    __init = function(self, data, n, doCopy, quantileMode, quartileMode)
        n = n or TableGetn(data)
        if doCopy then
            data = Sort(data, n)
        end
        self.data = data
        self.n = n
        if quantileMode then
            self.quantileMode = quantileMode
        end
        if quartileMode then
            self.quartileMode = quartileMode
        end
        if doCopy then
            self.sorted = data
        end
    end;

    MinMax = function(self)
        local min, max = rawget(self, "min"), rawget(self, "max")
        if not (min and max) then
            local sorted = rawget(self, "sorted")
            if sorted then
                min = sorted[1]
                max = sorted[self.n]
            else
                local data = self.data
                min = data[1]
                max = data[1]
                for i = 2, self.n do
                    local val = data[i]
                    if val < min then
                        min = val
                    elseif val > max then
                        max = val
                    end
                end
            end
            self.min = min
            self.max = max
        end
        return min, max
    end;

    RemoveOutliers = function(self, mult)
        mult = mult or 1.5
        local lower, upper = self.q1, self.q3
        local extent = (upper - lower) * mult
        lower = lower - extent
        upper = upper + extent
        local trimmed = {}
        local size = 0
        local data = self.data
        for i = 1, self.n do
            local val = data[i]
            if lower <= val and val <= upper then
                size = size + 1
                trimmed[size] = val
            end
        end
        return self.Class(trimmed, size)
    end;
    RecursivelyRemoveOutliers = function(self, mult)
        local iteration = self
        local pren = self.n
        repeat
            local lastn = pren
            iteration = iteration:RemoveOutliers(mult)
            pren = iteration.n
        until pren == lastn
        iteration.quantileMode = self.quantileMode
        iteration.quartileMode = self.quartileMode
        return iteration
    end;

    Quantile = function(self, q, quantileMode)
        local curQuantMode = self.quantileMode
        if curQuantMode then
            quantileMode = curQuantMode
        elseif quantileMode then
            self.quantileMode = quantileMode
        end
        return Quantile(self.sorted, q, self.n, quantileMode)
    end;
    Quartiles = function(self, quartileMode)
        local savedQ1 = rawget(self, "q1")
        if savedQ1 then
            return savedQ1, self.median, self.q3
        end
         -- catch it if it sets the quartiles so we can update the qunatile mode
        local curQuartMode = self.quartileMode
        if curQuartMode then
            quartileMode = curQuartMode
        elseif quartileMode then
            self.quartileMode = quartileMode
        end
        local q1, median, q3 = Quartiles(self.sorted, self.n, quartileMode)
        self.q1, self.median, self.q3 = q1, median, q3
        return q1, median, q3
    end;
    Summary = function(self, quartileMode)
        local mean = self.mean
        local q1, median, q3 = self:Quartiles(quartileMode)
        local min, max = self:MinMax() -- min & max are most efficient when `sorted` is already present
        return mean, min, q1, median, q3, max, self.mode
    end;
})

---@class StatObjectCommon
---@field nonparametericSkewness? number
local StatObjectCommon = LazyCacheClass {
    nonparametericSkewness = function(self)
        return NonparametericSkewness(self.mean, self.median, self.deviation)
    end;
}

---@class PopStatObject : StatObject, StatObjectCommon
---@field variance? number
---@field skewness? number
local PopStatObject = LazyCacheClass(StatObject, StatObjectCommon, {
    variance = function(self)
        return self.m2
    end;
    skewness = function(self)
        return StandardizeSkewness(self.m3, self.deviation)
    end;
})
---@class SampStatObject : StatObject, StatObjectCommon
---@field variance? number
---@field skewness? number
local SampStatObject = LazyCacheClass(StatObject, StatObjectCommon, {
    variance = function(self)
        return AdjustToSampVariance(self.m2, self.n)
    end;
    skewness = function(self)
        return AdjustToSampSkewness(StandardizeSkewness(self.m3, self.deviation), self.n)
    end;
})


---@class StatObjectNoCorrection
---@field excessKurtosis? number
---@field deviation? number
local StatObjectNoCorrection = LazyCacheClass {
    excessKurtosis = function(self)
        return AdjustToExcessKurtosis(self.kurtosis)
    end;
    deviation = function(self)
        return MathSqrt(self.variance)
    end;
}
---@class StatObjectBasicCorrection
---@field excessKurtosis? number
---@field deviation? number
local StatObjectBasicCorrection = LazyCacheClass {
    excessKurtosis = function(self)
        return AdjustToExcessKurtosis(self.kurtosis)
    end;
    deviation = function(self)
        return AdjustToBasicCorrectedStdDeviation(MathSqrt(self.m2))
    end;
}
---@class StatObjectNormalCorrection
---@field excessKurtosis? number
---@field deviation? number
local StatObjectNormalCorrection = LazyCacheClass {
    excessKurtosis = function(self)
        return AdjustToNormallyCorrectedExcessKurtosis(self.kurtosis, self.n)
    end;
    deviation = function(self)
        return AdjustToNormallyCorrectedStdDeviation(MathSqrt(self.m2))
    end;
}


---@class PopStatObjectNoCorrection : PopStatObject, StatObjectNoCorrection
PopStatObjectNoCorrection = LazyCacheClass(PopStatObject, StatObjectNoCorrection)
---@class SampStatObjectNoCorrection : SampStatObject, StatObjectNoCorrection
SampStatObjectNoCorrection = LazyCacheClass(SampStatObject, StatObjectNoCorrection)

---@class PopStatObjectNoCorrection : PopStatObject, StatObjectBasicCorrection
PopStatObjectBasicCorrection = LazyCacheClass(PopStatObject, StatObjectBasicCorrection)
---@class SampStatObjectNoCorrection : PopStatObject, StatObjectBasicCorrection
SampStatObjectBasicCorrection = LazyCacheClass(SampStatObject, StatObjectBasicCorrection)

---@class PopStatObjectNoCorrection : PopStatObject, StatObjectNormalCorrection
PopStatObjectNormalCorrection = LazyCacheClass(PopStatObject, StatObjectNormalCorrection)
---@class SampStatObjectNoCorrection : PopStatObject, StatObjectNormalCorrection
SampStatObjectNormalCorrection = LazyCacheClass(SampStatObject, StatObjectNormalCorrection)

