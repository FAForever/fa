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

-- The map catalog: the custom lobby's list of playable skirmish maps.
--
-- This is the custom lobby's OWN enumeration — it does not call MapUtil's
-- `EnumerateSkirmishScenarios` (which eagerly loads each map's options + strings and blocks
-- while it reads the whole `/maps` tree). We're slowly moving off MapUtil: the only thing we
-- still borrow is `LoadScenarioInfoFile` — the `doscript` loader for one `_scenario.lua` — and
-- even that is a candidate to inline later.
--
-- Two differences from the legacy enumerator:
--   * **lighter** — we load only the scenario *info* (name / map / preview / size /
--     Configurations), not its `_options.lua` / `_strings.lua`. The list, preview and info
--     panel need nothing more; the options schema is loaded separately by the options slice.
--   * **async** — maps stream in across frames rather than blocking the UI on open. The list
--     is a `LazyVar` that re-fires as each batch lands, so the dialog can show a live
--     "N maps loaded" count and fill in progressively.
--
-- This stays *reference data*, never on the wire: the LazyVar gives local reactivity (progress),
-- not host-dictated sync. Only the host's *choice* (`ScenarioFile`, in the launch model) syncs;
-- every peer enumerates its own disk. See CLAUDE.md and the `customlobby-model-choice` skill.

local Create = import("/lua/lazyvar.lua").Create

-- The catalog is the lobby's single point of contact with MapUtil's `doscript` file loaders
-- (info + save) — so no other custom-lobby module imports MapUtil. Everything above that
-- (enumeration, filtering, caching) is ours.
local MapUtil = import("/lua/ui/maputil.lua")
local LoadScenarioInfoFile = MapUtil.LoadScenarioInfoFile

-- maps loaded per frame-slice before yielding — keeps the open responsive on big vaults
local BatchSize = 5

--- The growing list of playable skirmish maps. Re-fired (new table ref) as batches land.
---@type LazyVar<UILobbyScenarioInfo[]>
local Scenarios = Create({})

local Loading = false   -- a load thread is currently running
local Loaded = false    -- the disk has been fully enumerated

-- memoised save files (the expensive `doscript`), keyed by lowercased save path; `false` = a
-- known-missing/unreadable save. FIFO-bounded so browsing a big vault doesn't grow unbounded.
local SaveCache = {}
local SaveCacheOrder = {}
local SaveCacheMax = 24

-------------------------------------------------------------------------------
--#region Enumeration

--- A scenario is listable if it's a skirmish map with at least one start spot.
---@param scenario UIScenarioInfoFile
---@return boolean
local function IsPlayableSkirmish(scenario)
    if scenario.type ~= "skirmish" then
        return false
    end
    local standard = scenario.Configurations and scenario.Configurations.standard
    local teams = standard and standard.teams
    local first = teams and teams[1]
    return first ~= nil and first.armies ~= nil
end

---@param a UILobbyScenarioInfo
---@param b UILobbyScenarioInfo
---@return boolean
local function SortByName(a, b)
    return string.upper(a.name or "") < string.upper(b.name or "")
end

--- Publishes a fresh (sorted) copy of the accumulator so dependents go dirty.
---@param accumulator UILobbyScenarioInfo[]
local function Publish(accumulator)
    local snapshot = table.copy(accumulator)
    table.sort(snapshot, SortByName)
    Scenarios:Set(snapshot)
end

--- Enumerates `/maps` across frames, loading each map's info and streaming the playable
--- skirmish maps into the `Scenarios` LazyVar in batches.
--- TODO: mod maps (legacy also scanned `mods.AllSelectableMods()`); skipped for now.
local function LoadThread()
    local files = DiskFindFiles('/maps', '*_scenario.lua')

    local accumulator = {}
    local seen = 0
    for _, file in files do
        local scenario = LoadScenarioInfoFile(file)
        if scenario and IsPlayableSkirmish(scenario) then
            scenario.file = file
            table.insert(accumulator, scenario)
        end

        seen = seen + 1
        if math.mod(seen, BatchSize) == 0 then
            Publish(accumulator)
            WaitFrames(5)
        end
    end

    Loaded = true
    Loading = false
    Publish(accumulator)
end

--#endregion

-------------------------------------------------------------------------------
--#region Public API

--- Kicks off the async enumeration if it hasn't run yet. Idempotent — safe to call on every
--- dialog open; once loaded it's a no-op and the cached list stays.
function EnsureLoaded()
    if Loading or Loaded then
        return
    end
    Loading = true
    Scenarios:Set({})
    ForkThread(LoadThread)
end

--- The maps LazyVar — subscribe to it (via `Derive`) to react as the list streams in.
---@return LazyVar<UILobbyScenarioInfo[]>
function GetScenariosVar()
    return Scenarios
end

--- The current (possibly partial) list of maps.
---@return UILobbyScenarioInfo[]
function GetScenarios()
    return Scenarios()
end

--- How many maps are currently loaded.
---@return number
function GetCount()
    return table.getn(Scenarios())
end

--- Whether the disk has been fully enumerated (vs. still streaming).
---@return boolean
function IsLoaded()
    return Loaded
end

--- Finds the loaded map whose file path matches `scenarioFile` (case-insensitive), or nil.
---@param scenarioFile FileName | false
---@return UILobbyScenarioInfo | nil
function FindByFile(scenarioFile)
    if not scenarioFile then
        return nil
    end
    local target = string.lower(scenarioFile)
    for _, scenario in Scenarios() do
        if string.lower(scenario.file) == target then
            return scenario
        end
    end
    return nil
end

--- Loads a scenario's info for `scenarioFile`. Returns the already-enumerated entry if we have
--- it (the streamed list is the info cache), else reads it from disk. nil if unreadable.
---@param scenarioFile FileName | false
---@return UILobbyScenarioInfo | nil
function LoadInfo(scenarioFile)
    if not scenarioFile then
        return nil
    end
    local cached = FindByFile(scenarioFile)
    if cached then
        return cached
    end
    local info = LoadScenarioInfoFile(scenarioFile)
    if not info then
        return nil
    end
    info.file = scenarioFile
    return info --[[@as UILobbyScenarioInfo]]
end

--- Loads (and caches) a scenario's save file — the marker data the preview overlays need.
--- The save `doscript` is expensive, and both the in-lobby preview and the picker re-load the
--- same maps repeatedly, so results are memoised by save path with a small FIFO bound. Returns
--- nil if the save is missing / unreadable (cached as a negative so we don't retry the disk).
---@param scenarioInfo UILobbyScenarioInfo
---@return UIScenarioSaveFile | nil
function LoadSave(scenarioInfo)
    if not (scenarioInfo and scenarioInfo.save) then
        return nil
    end

    local key = string.lower(scenarioInfo.save)
    local cached = SaveCache[key]
    if cached ~= nil then
        return cached or nil               -- `false` = known-missing
    end

    local save = false
    if DiskGetFileInfo(scenarioInfo.save) then
        save = MapUtil.LoadScenarioSaveFile(scenarioInfo.save) or false
    end

    SaveCache[key] = save
    table.insert(SaveCacheOrder, key)
    if table.getn(SaveCacheOrder) > SaveCacheMax then
        local oldest = table.remove(SaveCacheOrder, 1)
        SaveCache[oldest] = nil
    end

    return save or nil
end

--- Drops everything so the next `EnsureLoaded` re-reads from disk (e.g. maps changed on disk).
function Refresh()
    Loaded = false
    Loading = false
    Scenarios:Set({})
    SaveCache = {}
    SaveCacheOrder = {}
end

--#endregion

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
