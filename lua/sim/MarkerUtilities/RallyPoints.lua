
--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
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

---@class MarkerRallyPoint : MarkerData
---@field ClaimedBy MarkerExpansion

local Generated = false

function IsGenerated()
    return Generated
end

---@param expansion MarkerExpansion
local function GenerateForExpansion(expansion)
    
end

function Generate()

    -- verify that we have what we need
    if not import("/lua/sim/MarkerUtilities/Expansions.lua").IsGenerated() then
        WARN("Unable to generate rally point markers without expansion markers")
    end

    if not import("/lua/sim/NavUtils.lua").IsGenerated() then
        WARN("Unable to generate rally point markers without navigational mesh")
    end

    local largeExpansions = import("/lua/sim/MarkerUtilities.lua").GetMarkersByType('Large Expansion Area') --[[@as (MarkerExpansion[])]]
    local largeExpansionCount = table.getn(largeExpansions)

    local smallExpansions = import("/lua/sim/MarkerUtilities.lua").GetMarkersByType('Expansion Area') --[[@as (MarkerExpansion[])]]
    local smallExpansionCount = table.getn(smallExpansions)

    if largeExpansionCount == 0 and smallExpansionCount == 0 then
        WARN("Unable to generate rally point markers without expansion markers")
    end

    -- verify that we didn't generate already
    if Generated then
        return
    end

    Generated = true

    for k = 1, largeExpansionCount do
        GenerateForExpansion(largeExpansions[k])
    end

    for k = 1, largeExpansionCount do
        GenerateForExpansion(largeExpansions[k])
    end
end
