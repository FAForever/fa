--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

local SessionClientsOverride = import("/lua/ui/override/sessionclients.lua")
local StatisticsMean = import("/lua/shared/statistics.lua").Mean
local StatisticsStandardDeviation = import("/lua/shared/statistics.lua").Deviation

---@type number
local Samples = 30

---@type number
local Current = 1

---@type number[][]
local PingSamples = {}

---@type number[][]
local QuietSamples = {}

--- Allows for scripts to adjust the number of samples.
---@param requestedSamples number
function SetSamples(requestedSamples)

    -- clear out all exist samples and start over
    Current = 1
    for k = 1, table.getn(PingSamples) do
        local clientPingSamples = PingSamples[k]
        local clientQuietSamples = QuietSamples[k]
        for l = 1, Samples do
            clientPingSamples[l] = nil
            clientQuietSamples[l] = nil
        end
    end

    Samples = requestedSamples
end

--- Compute the mean and standard deviation of the ping value of all clients.
---@param mCache? number[]
---@param sCache? number[]
---@return number[] # mean
---@return number[] # standard deviation
function ComputeStatisticsPing(mCache, sCache)
    mCache = mCache or {}
    sCache = sCache or {}

    for k = 1, table.getn(PingSamples) do
        local samples = PingSamples[k]
        local sampleCount = table.getn(samples)
        local mean = StatisticsMean(samples, sampleCount)
        local deviation = StatisticsStandardDeviation(samples, sampleCount, mean)
        mCache[k] = mean
        sCache[k] = deviation
    end

    return mCache, sCache
end

--- Compute the mean and standard deviation of the quiet value of all clients.
---@param mCache? number[]
---@param sCache? number[]
---@return number[] # mean
---@return number[] # standard deviation
function ComputeStatisticsQuiet(mCache, sCache)
    mCache = mCache or {}
    sCache = sCache or {}

    for k = 1, table.getn(QuietSamples) do
        local samples = QuietSamples[k]
        local sampleCount = table.getn(samples)
        local mean = StatisticsMean(samples, sampleCount)
        local deviation = StatisticsStandardDeviation(samples, sampleCount, mean)
        mCache[k] = mean
        sCache[k] = deviation
    end

    return mCache, sCache
end

--- Automatically keep track of these values

SessionClientsOverride.Observable:AddObserver(
---@param clients Client[]
    function(clients)
        for k = 1, table.getn(clients) do
            local client = clients[k]

            local pingSamples = PingSamples[k] or {}
            PingSamples[k] = pingSamples

            local quietSamples = QuietSamples[k] or {}
            QuietSamples[k] = quietSamples

            if client.connected then
                pingSamples[Current] = client.ping
                quietSamples[Current] = client.quiet
            else
                pingSamples[Current] = -1
                quietSamples[Current] = -1
            end
        end

        Current = Current + 1
        if Current > Samples then
            Current = 1
        end
    end,
    "ConnectionDialogData.lua"
)
