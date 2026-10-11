--- Plain-text reports of benchmark statistics, meant for the log

local MathAbs = math.abs
local MathFloor = math.floor
local MathMax = math.max
local MathMin = math.min

local maxDecimals = 6

local ModeDescriptions = {
    none = "raw times",
    paired = "ratio to each sample's baseline",
    ratio = "ratio to the baseline mean",
}

--- Decimal places needed to keep `sig` significant figures of a value
---@param value number
---@param sig integer
---@return integer
local function Decimals(value, sig)
    if value == 0 then
        return 0
    end
    return MathMin(maxDecimals, MathMax(0, sig - 1 - MathFloor(math.log10(MathAbs(value)))))
end

---@param value number
---@param decimals integer
---@return string
local function Fixed(value, decimals)
    return string.format("%." .. decimals .. "f", value)
end

---@param value number
---@param sig integer
---@return string
local function Sig(value, sig)
    return Fixed(value, Decimals(value, sig))
end

--- Times are shown in milliseconds, baseline ratios are unitless
---@param summary BenchmarkSummary
---@return number scale
---@return string unit
local function GetUnit(summary)
    if summary.mode == "none" then
        return 1000, " ms"
    end
    return 1, ""
end

--- Decimal places that keep two significant figures of the smallest margin
---@param summaries BenchmarkSummary[]
---@param scale number
---@return integer
local function GetValueDecimals(summaries, scale)
    local decimals
    for _, summary in ipairs(summaries) do
        local margin = summary.margin
        if margin and margin > 0 then
            local d = Decimals(margin * scale, 2)
            decimals = decimals and MathMax(decimals, d) or d
        end
    end
    return decimals or 2
end

--- Writes a summary as one line per statistic
---@param name string
---@param summary BenchmarkSummary
---@param parameters? string[]
---@param baseline? BenchmarkSummary raw baseline times
---@return string[]
function FormatSummary(name, summary, parameters, baseline)
    local scale, unit = GetUnit(summary)
    local decimals = GetValueDecimals({summary}, scale)
    local function Value(x)
        return Fixed(x * scale, decimals)
    end

    local lines = {
        string.format('"%s"', name),
        "Mode: " .. ModeDescriptions[summary.mode] .. (unit ~= "" and ", in" .. unit or ""),
    }
    if parameters then
        table.insert(lines, "Parameters: " .. table.concat(parameters, ", "))
    end

    local samples = "Samples: " .. summary.n
    if summary.total ~= summary.n then
        samples = samples .. " of " .. summary.total .. " (" .. (summary.total - summary.n) .. " outliers removed)"
    end
    table.insert(lines, samples)

    local margin = summary.margin
    if margin then
        local mean = "Mean: " .. Value(summary.mean) .. " +/- " .. Value(margin) .. unit
        if summary.relativeMargin then
            mean = mean .. " (+/-" .. Sig(summary.relativeMargin * 100, 2) .. "%, 95% confidence)"
        end
        table.insert(lines, mean)
        table.insert(lines, "95% interval: [" .. Value(summary.mean - margin) .. ", " .. Value(summary.mean + margin) .. "]" .. unit)
    else
        table.insert(lines, "Mean: " .. Value(summary.mean) .. unit .. " (too few samples for an interval)")
    end

    local deviation = "Deviation: " .. Value(summary.deviation) .. unit
    if summary.cv then
        deviation = deviation .. " (" .. Sig(summary.cv * 100, 2) .. "% of the mean)"
    end
    table.insert(lines, deviation)
    if summary.n > 0 then
        table.insert(lines, "Standard error: " .. Sig(summary.deviation * scale / math.sqrt(summary.n), 2) .. unit)
    end

    if summary.median then
        table.insert(lines, "Median: " .. Value(summary.median) .. unit)
        table.insert(lines, "Quartiles: " .. Value(summary.q1) .. " / " .. Value(summary.median) .. " / " .. Value(summary.q3) ..
            unit .. " (IQR " .. Value(summary.q3 - summary.q1) .. ")")
        table.insert(lines, "Range: " .. Value(summary.min) .. " to " .. Value(summary.max) .. unit)
    end
    table.insert(lines, "Skewness: " .. Sig(summary.skewness, 2))

    if baseline then
        local baselineDecimals = GetValueDecimals({baseline}, 1000)
        local count = parameters and table.getn(parameters) or 0
        local text = "Baseline (" .. count .. " parameter" .. (count == 1 and "" or "s") .. "): " ..
            Fixed(baseline.mean * 1000, baselineDecimals)
        if baseline.margin then
            text = text .. " +/- " .. Fixed(baseline.margin * 1000, baselineDecimals)
        end
        text = text .. " ms (" .. baseline.n .. " samples"
        if baseline.relativeMargin then
            text = text .. ", +/-" .. Sig(baseline.relativeMargin * 100, 2) .. "%"
        end
        table.insert(lines, text .. ")")
    end
    return lines
end
