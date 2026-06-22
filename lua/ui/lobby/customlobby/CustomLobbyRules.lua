--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- Game-rule derivations from the lobby state — neither view nor host-authority logic.
-- Views call these for display hints; the controller may call them at launch. Keep the
-- model the source of truth; this layer only derives.

local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")

-- Scenario file -> largest map dimension (ogrids). Loading a scenario is I/O, so the
-- result is memoised per file (a map rarely changes, and the key changes if it does).
local MapDimensionCache = {}

--- Units-per-player tier from the map's largest dimension (51.2 ogrids = 1 km), i.e.
--- 250 / 375 / 500 for 5x5 / 10x10 / 20x20-or-larger. Unknown size (0) → the top tier.
---@param maxDimension number
---@return number
local function UnitsPerPlayer(maxDimension)
    if maxDimension > 0 and maxDimension <= 256 then
        return 250                                  -- 5x5
    elseif maxDimension > 0 and maxDimension <= 512 then
        return 375                                  -- 10x10
    end
    return 500                                      -- 20x20 or larger / not yet known
end

--- Largest dimension (ogrids) of the current scenario, or 0 when no map is set.
---@param model UICustomLobbyAuthoritativeModel
---@return number
local function CurrentMapDimension(model)
    local scenarioFile = model.ScenarioFile()
    if not scenarioFile then
        return 0
    end

    local cached = MapDimensionCache[scenarioFile]
    if cached ~= nil then
        return cached
    end

    local dimension = 0
    local scenarioInfo = import("/lua/ui/maputil.lua").LoadScenario(scenarioFile)
    if scenarioInfo and scenarioInfo.size then
        dimension = math.max(scenarioInfo.size[1] or 0, scenarioInfo.size[2] or 0)
    end
    MapDimensionCache[scenarioFile] = dimension
    return dimension
end

--- The recommended total-unit ceiling for the current map and seated-player count.
--- Returns nil when there are no players to scale by.
---@return number | nil
function RecommendedUnitCap()
    local model = CustomLobbyAuthoritativeModel.GetSingleton()

    local players = 0
    for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
        if model.Players[slot]() then
            players = players + 1
        end
    end
    if players < 1 then
        return nil
    end

    return UnitsPerPlayer(CurrentMapDimension(model)) * players
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
