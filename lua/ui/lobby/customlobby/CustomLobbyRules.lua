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

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

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
---@param model UICustomLobbyLaunchModel
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
    local model = CustomLobbyLaunchModel.GetSingleton()

    local players = 0
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
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
--#region Auto-team sides

-- The AutoTeams modes that resolve to exactly two sides; everything else (none / manual) has no
-- binary split. The labels mirror how the modes actually resolve at launch.
local BinaryModeLabels = {
    tvsb = { "Top", "Bottom" },     -- by start-position Y
    lvsr = { "Left", "Right" },     -- by start-position X
    pvsi = { "Odd", "Even" },       -- by start-spot parity (needs no map)
}

--- The current AutoTeams mode when it forms two sides (tvsb / lvsr / pvsi), else nil.
---@return string | nil
function AutoTeamMode()
    local mode = (CustomLobbyLaunchModel.GetSingleton().GameOptions() or {}).AutoTeams
    return BinaryModeLabels[mode] and mode or nil
end

--- The two side labels for a binary mode (e.g. `{ "Left", "Right" }`), or nil for a non-binary mode.
---@param mode string | nil
---@return string[] | nil
function SideLabels(mode)
    return mode and BinaryModeLabels[mode] or nil
end

--- Builds a side resolver for the current binary AutoTeams mode: a function `startSpot -> 1|2|nil`
--- (nil = "unresolved", i.e. a positional mode whose map/start positions aren't loaded yet). Returns
--- `resolver, resolved`:
---   * `resolver` is nil only when there is no binary mode;
---   * `resolved` is false when the mode is positional but positions are unavailable — callers that
---     need a definite split (e.g. the team score) hide in that case, while the two-column slot
---     layout still renders both columns and just withholds the side labels until it flips true.
--- Positional modes load the map start positions ONCE here, so a caller resolves all spots cheaply.
---@return (fun(startSpot: number): number | nil) | nil resolver
---@return boolean resolved
function BuildSideResolver()
    local mode = AutoTeamMode()
    if not mode then
        return nil, false
    end

    if mode == 'pvsi' then
        return function(spot)
            if not spot then return nil end
            return (math.mod(spot, 2) == 1) and 1 or 2
        end, true
    end

    -- positional: resolve each spot against the map centre (positions loaded once)
    local MapUtil = import("/lua/ui/maputil.lua")
    local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
    local model = CustomLobbyLaunchModel.GetSingleton()
    local scenarioFile = model.ScenarioFile()
    local info = scenarioFile and CustomLobbyMapCatalog.LoadInfo(scenarioFile)
    if type(info) ~= "table" or not info.size then
        return function(spot) return nil end, false        -- mode set, positions unknown → unresolved
    end

    local positions = MapUtil.GetStartPositionsFromScenario(info, CustomLobbyMapCatalog.LoadSave(info))
    if not positions then
        return function(spot) return nil end, false
    end
    local centreX, centreZ = info.size[1] / 2, info.size[2] / 2
    return function(spot)
        local pos = spot and positions[spot]
        if not pos then return nil end
        if mode == 'tvsb' then
            return (pos[2] < centreZ) and 1 or 2
        else -- lvsr
            return (pos[1] < centreX) and 1 or 2
        end
    end, true
end

--#endregion

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
