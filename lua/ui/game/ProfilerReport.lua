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

---@param text string
---@param width integer
---@param alignLeft boolean
---@return string
local function Pad(text, width, alignLeft)
    local fill = string.rep(" ", width - string.len(text))
    if alignLeft then
        return text .. fill
    end
    return fill .. text
end

---@class BenchmarkReportRow
---@field name string
---@field summary? BenchmarkSummary missing for benchmarks that have not been run
---@field params? integer parameter count

--- Writes summaries as a pipe table with a row per benchmark and the baselines in rows below.
--- Baselines are always raw times. Mode and parameter count columns are only added when the
--- benchmarks differ in them, otherwise they are noted below the table. Benchmarks that have not
--- been run get a blank row with 0 samples.
---@param rows BenchmarkReportRow[]
---@param baselines? BenchmarkReportRow[]
---@return string[]
function FormatTable(rows, baselines)
    local rowCount = table.getn(rows)
    if rowCount == 0 then
        return {}
    end
    baselines = baselines or {}

    local ranRows = {}
    for _, row in ipairs(rows) do
        if row.summary then
            table.insert(ranRows, row)
        end
    end
    if not ranRows[1] then
        return {}
    end

    local firstMode = ranRows[1].summary.mode
    local mixedModes = false
    local allRaw = true
    for _, row in ipairs(ranRows) do
        mixedModes = mixedModes or row.summary.mode ~= firstMode
        allRaw = allRaw and row.summary.mode == "none"
    end

    local firstParams = ranRows[1].params
    local mixedParams = false
    for _, row in ipairs(ranRows) do
        mixedParams = mixedParams or row.params ~= firstParams
    end

    local entries = {}
    for _, row in ipairs(rows) do
        local summary = row.summary
        table.insert(entries, {name = row.name, summary = summary, scale = summary and GetUnit(summary) or 1,
            mode = summary and summary.mode or "", params = row.params})
    end
    for _, row in ipairs(baselines) do
        table.insert(entries, {name = row.name, summary = row.summary, scale = 1000, mode = "-", params = row.params})
    end

    -- rows in the same unit share their decimal places
    local decimalsByScale = {}
    for _, scale in ipairs({1, 1000}) do
        local group = {}
        for _, entry in ipairs(entries) do
            if entry.summary and entry.scale == scale then
                table.insert(group, entry.summary)
            end
        end
        decimalsByScale[scale] = GetValueDecimals(group, scale)
    end

    local unit = allRaw and " ms" or ""
    local headers = {
        "Name", "Samples", "Mean" .. unit, "+/- 95%" .. unit, "+/- 95% %", "Dev" .. unit, "CV %",
        "Median" .. unit, "Min" .. unit, "Max" .. unit, "Skew",
    }
    local paramsColumn = mixedParams and (mixedModes and 3 or 2)
    if mixedModes then
        table.insert(headers, 2, "Mode")
    end
    if paramsColumn then
        table.insert(headers, paramsColumn, "Params")
    end

    local cells = {}
    for i, entry in ipairs(entries) do
        local summary = entry.summary
        local scale = entry.scale
        local decimals = decimalsByScale[scale]
        local function Value(x)
            return x and Fixed(x * scale, decimals) or "-"
        end
        local function Percent(x)
            return x and Fixed(x * 100, 2) or "-"
        end

        if summary then
            cells[i] = {
                string.format('"%s"', entry.name),
                tostring(summary.n),
                Value(summary.mean),
                Value(summary.margin),
                Percent(summary.relativeMargin),
                Value(summary.deviation),
                Percent(summary.cv),
                Value(summary.median),
                Value(summary.min),
                Value(summary.max),
                Fixed(summary.skewness, 2),
            }
        else
            cells[i] = {string.format('"%s"', entry.name), "0", "", "", "", "", "", "", "", "", ""}
        end
        if mixedModes then
            table.insert(cells[i], 2, entry.mode)
        end
        if paramsColumn then
            table.insert(cells[i], paramsColumn, entry.params and tostring(entry.params) or "")
        end
    end

    local columns = table.getn(headers)
    local widths = {}
    for c = 1, columns do
        local width = string.len(headers[c])
        for i = 1, table.getn(cells) do
            width = MathMax(width, string.len(cells[i][c]))
        end
        widths[c] = width
    end

    local rule = "|"
    for c = 1, columns do
        rule = rule .. string.rep("-", widths[c] + 2) .. "|"
    end
    local function Row(texts)
        local line = "|"
        for c = 1, columns do
            local alignLeft = c == 1 or (mixedModes and c == 2)
            line = line .. " " .. Pad(texts[c], widths[c], alignLeft) .. " |"
        end
        return line
    end

    local lines = {rule, Row(headers), rule}
    for i = 1, rowCount do
        table.insert(lines, Row(cells[i]))
    end
    if baselines[1] then
        table.insert(lines, rule)
        for i = rowCount + 1, table.getn(cells) do
            table.insert(lines, Row(cells[i]))
        end
    end
    table.insert(lines, rule)

    if not mixedModes then
        table.insert(lines, "Mode: " .. ModeDescriptions[firstMode] .. (allRaw and ", in ms" or ""))
    end
    if not mixedParams and firstParams then
        table.insert(lines, "Parameter count: " .. firstParams)
    end
    if baselines[1] and not allRaw then
        if mixedModes then
            table.insert(lines, "Baselines and rows with mode none are in ms, the other rows are ratios.")
        else
            table.insert(lines, "Baselines are in ms.")
        end
    end
    return lines
end
