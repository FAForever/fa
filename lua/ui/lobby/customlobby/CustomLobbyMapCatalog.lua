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

-- The map catalog: the custom lobby's cached list of playable skirmish scenarios.
--
-- `MapUtil.EnumerateSkirmishScenarios` is expensive — it `doscript`s every `_scenario.lua`
-- on disk plus all mod maps — so we read it once and cache it here, rather than re-enumerating
-- each time the map-select dialog opens.
--
-- This is deliberately NOT one of the three lobby models (Launch / Session / Local): it's
-- read-only *reference data*, identical on every peer, derived from disk rather than dictated
-- by the host. It never goes on the wire — only the host's *choice* (ScenarioFile, in the
-- launch model) is synced. See /lua/ui/lobby/customlobby/CLAUDE.md and the
-- `customlobby-model-choice` skill.
--
-- The enumerated entries are full `UILobbyScenarioInfo` tables (name / preview / map / size /
-- Configurations / options), so the dialog can render the list, preview and info without any
-- further disk reads.

local MapUtil = import("/lua/ui/maputil.lua")

---@type UILobbyScenarioInfo[] | nil
local Scenarios = nil

--- Returns all playable skirmish scenarios, enumerating + caching on first call.
---@param force? boolean   # re-read from disk even if cached (e.g. maps changed on disk)
---@return UILobbyScenarioInfo[]
function GetScenarios(force)
    if not Scenarios or force then
        Scenarios = MapUtil.EnumerateSkirmishScenarios()
    end
    return Scenarios
end

--- Finds the cached scenario whose file path matches `scenarioFile` (case-insensitive), or nil.
---@param scenarioFile FileName | false
---@return UILobbyScenarioInfo | nil
function FindByFile(scenarioFile)
    if not scenarioFile then
        return nil
    end
    local target = string.lower(scenarioFile)
    for _, scenario in GetScenarios() do
        if string.lower(scenario.file) == target then
            return scenario
        end
    end
    return nil
end

--- Drops the cache so the next `GetScenarios` re-reads from disk.
function Refresh()
    Scenarios = nil
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module after a couple of frames. The cache is just a
--- perf optimisation, so letting it rebuild on the next access is harmless.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
