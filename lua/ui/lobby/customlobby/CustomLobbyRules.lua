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

-- Game-rule derivations — the pure kernel behind the lobby's display hints and (eventually) the
-- host's launch-time team assignment. These are **pure functions**: every input is passed in (the map
-- size, the seated count, the AutoTeams mode, the resolved scenario), so this module reads no models
-- and holds no state. Callers own reading the state — the slots derived model applies these reactively
-- to publish `Side` / `Teams`, and the controller can apply the same kernel at launch with its own
-- inputs (without depending on a view-facing derived model). The model stays the source of truth.

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

--- The recommended total-unit ceiling for `seatedCount` players on a map of `maxDimension` ogrids
--- (0 = unknown → top tier). Returns nil when there are no players to scale by.
---@param seatedCount number
---@param maxDimension number
---@return number | nil
function RecommendedUnitCap(seatedCount, maxDimension)
    if not seatedCount or seatedCount < 1 then
        return nil
    end
    return UnitsPerPlayer(maxDimension or 0) * seatedCount
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

--- The AutoTeams mode in `gameOptions` when it forms two sides (tvsb / lvsr / pvsi), else nil.
---@param gameOptions table | nil
---@return string | nil
function AutoTeamMode(gameOptions)
    local mode = (gameOptions or {}).AutoTeams
    return BinaryModeLabels[mode] and mode or nil
end

--- The two side labels for a binary mode (e.g. `{ "Left", "Right" }`), or nil for a non-binary mode.
---@param mode string | nil
---@return string[] | nil
function SideLabels(mode)
    return mode and BinaryModeLabels[mode] or nil
end

--- Builds a side resolver for a binary AutoTeams `mode` over a resolved `scenario`: a function
--- `startSpot -> 1|2|nil` (nil = "unresolved", i.e. a positional mode whose map/start positions
--- aren't loaded yet). Returns `resolver, resolved`:
---   * `resolver` is nil only when there is no binary mode (`mode` is nil);
---   * `resolved` is false when the mode is positional but positions are unavailable — callers that
---     need a definite split (e.g. the team score) hide in that case, while the two-column slot
---     layout still renders both columns and just withholds the side labels until it flips true.
--- The caller passes the resolved scenario bundle (e.g. from the scenario derived model, or the one
--- the controller is launching with), so this does no reading itself.
---@param mode string | nil                            # a binary mode (tvsb/lvsr/pvsi), or nil
---@param scenario UICustomLobbyScenario | false       # the resolved scenario (for the positional modes)
---@return (fun(startSpot: number): number | nil) | nil resolver
---@return boolean resolved
function BuildSideResolver(mode, scenario)
    if not mode then
        return nil, false
    end

    if mode == 'pvsi' then
        return function(spot)
            if not spot then return nil end
            return (math.mod(spot, 2) == 1) and 1 or 2
        end, true
    end

    -- positional: resolve each spot against the map centre, from the passed scenario's start spots
    if not (scenario and scenario.Size) then
        return function(spot) return nil end, false        -- mode set, positions unknown → unresolved
    end

    local positions = scenario.Markers.Spawns
    if not positions or table.empty(positions) then
        return function(spot) return nil end, false
    end
    local centreX, centreZ = scenario.Size[1] / 2, scenario.Size[2] / 2
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
