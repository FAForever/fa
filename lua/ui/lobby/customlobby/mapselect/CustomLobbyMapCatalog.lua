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
-- This is the custom lobby's OWN scenario layer — it does **not** depend on MapUtil at all. It
-- neither calls `EnumerateSkirmishScenarios` (which eagerly loads each map's options + strings and
-- blocks while it reads the whole `/maps` tree) nor borrows MapUtil's file loaders: the `doscript`
-- loaders for `_scenario.lua` / `_save.lua` and the start-spot derivation are re-implemented below
-- (they are tiny), so the catalog is the lobby's single source of truth for what a scenario is.
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
--
-- LIFETIME. The catalog is a `ClassSimple` singleton implementing `Destroyable`, registered in the
-- session trash bag (see CustomLobbySession) the moment it is created. So one `CustomLobbySession
-- .Teardown()` kills its streaming load thread and drops its cached map list / save cache, instead
-- of pinning them in the persistent front-end Lua state for the whole match. The module-level
-- functions below are thin facades over the singleton, so callers are unaffected by the object
-- shape. This is the worked example for the broader singleton rework — the models and the other
-- catalog follow the same pattern.

local Create = import("/lua/lazyvar.lua").Create
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")

--- The *interesting* bits extracted from a scenario's save — what the preview overlays and the
--- rules read, so nothing downstream has to know the raw save's shape. Points are 2-element `{x, z}`
--- map coordinates (ogrids). Produced by `LoadMarkers`.
---@class UICustomLobbyScenarioMarkers
---@field Spawns      Vector2[]   # start spots, one {x, z} per army (army order)
---@field MassPoints  Vector2[]   # mass deposit positions
---@field HydroPoints Vector2[]   # hydrocarbon deposit positions
---@field Wrecks      Vector2[]   # prebuilt-wreckage positions (maps that define any)

-- maps loaded per frame-slice before yielding — keeps the open responsive on big vaults
local BatchSize = 5

-- save files memoised before the FIFO bound kicks in — the save `doscript` is expensive and
-- browsing re-loads the same maps
local SaveCacheMax = 24

-- The catalog singleton. Forward-declared here (before the class) so the class methods capture it
-- as an upvalue rather than resolving it as a global. Assigned in `GetSingleton`, cleared in
-- `Destroy`.
---@type UICustomLobbyMapCatalog | nil
local Instance = nil

-------------------------------------------------------------------------------
--#region Scenario file loaders (pure; no instance state)
--
-- Our own `doscript` loaders, so the catalog doesn't depend on MapUtil. A scenario's files are Lua
-- scripts that, when run, populate globals (`ScenarioInfo`, `Scenario`, …); we run them into a fresh
-- sandbox table seeded with `dataInit` rather than into `_G`.

--- Runs a scenario-family file (`_scenario.lua` / `_save.lua`) into a fresh sandbox table, so its
--- globals land there instead of polluting `_G`. Returns the populated table, or nil if the file is
--- absent. The `doscript`s are the expensive part — callers cache the results.
---@param path FileName
---@return table | nil
local function LoadScenarioFile(path)
    if not DiskGetFileInfo(path) then
        return nil
    end
    local data = {}
    doscript('/lua/dataInit.lua', data)
    doscript(path, data)
    return data
end

--- Loads a scenario's info from its `_scenario.lua` (the `ScenarioInfo` table), handling the legacy
--- v1 shape where the info lived at the top level. nil if the file is missing.
---@param path FileName
---@return UIScenarioInfoFile | nil
local function LoadScenarioInfoFile(path)
    local data = LoadScenarioFile(path)
    if not data then
        return nil
    end
    if data.version == 1 then       -- legacy: the info table WAS the top-level data
        return data --[[@as UIScenarioInfoFile]]
    end
    return data.ScenarioInfo
end

--- Loads a scenario's save (the `Scenario` table) from its `_save.lua`. nil if the file is missing.
--- Expensive (`doscript`) — `LoadSave` memoises the result.
---@param path FileName
---@return UIScenarioSaveFile | nil
local function LoadScenarioSaveFile(path)
    local data = LoadScenarioFile(path)
    return data and data.Scenario
end

--- The playable armies of a scenario (`{ 'ARMY_1', 'ARMY_2', … }`), or nil when malformed. Reads the
--- `standard` FFA team config — the same shape `IsPlayableSkirmish` requires for a map to be listed.
---@param scenarioInfo UIScenarioInfoFile
---@return string[] | nil
local function GetArmies(scenarioInfo)
    local standard = scenarioInfo.Configurations and scenarioInfo.Configurations.standard
    local teams = standard and standard.teams
    if not teams then
        return nil
    end
    for _, teamConfig in teams do
        if teamConfig.name == 'FFA' then
            return teamConfig.armies
        end
    end
    return nil
end

--- The start spots of a scenario as `{x, z}` per army (army order), read from the save's master-chain
--- markers (each army has a like-named marker). nil when armies / markers are missing; a `{0, 0}`
--- placeholder keeps the array aligned with the army list for any army that lacks a marker.
---@param scenarioInfo UIScenarioInfoFile
---@param scenarioSave UIScenarioSaveFile
---@return Vector2[] | nil
local function GetStartPositions(scenarioInfo, scenarioSave)
    local armies = GetArmies(scenarioInfo)
    if not armies then
        return nil
    end
    local masterChain = scenarioSave.MasterChain and scenarioSave.MasterChain['_MASTERCHAIN_']
    local markers = masterChain and masterChain.Markers
    if not markers then
        return nil
    end
    local output = {}
    for _, army in armies do
        local marker = markers[army]
        if marker and marker.position then
            table.insert(output, { marker.position[1], marker.position[3] })
        else
            table.insert(output, { 0, 0 })
        end
    end
    return output
end

--#endregion

-------------------------------------------------------------------------------
--#region Enumeration helpers (pure; no instance state)

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

--#endregion

-------------------------------------------------------------------------------
--#region Catalog class

--- The lobby's map catalog. One per lobby session, owned by the session trash bag.
---@class UICustomLobbyMapCatalog : Destroyable
---@field Trash          TrashBag                        # owns the Scenarios LazyVar (freed on Destroy)
---@field Scenarios      LazyVar<UILobbyScenarioInfo[]>  # growing list; re-fired (new table ref) as batches land
---@field Worker         thread | nil                    # the in-flight enumeration thread, if any
---@field Loading        boolean                         # a load thread is currently running
---@field Loaded         boolean                         # the disk has been fully enumerated
---@field SaveCache      table<string, UIScenarioSaveFile | false>  # memoised saves keyed by lowercased path; false = known-missing
---@field SaveCacheOrder string[]                         # FIFO order of SaveCache keys, bounded by SaveCacheMax
---@field Destroyed      boolean
local Catalog = ClassSimple {

    ---@param self UICustomLobbyMapCatalog
    __init = function(self)
        self.Trash = TrashBag()
        self.Scenarios = self.Trash:Add(Create({}))
        self.Worker = nil
        self.Loading = false
        self.Loaded = false
        self.SaveCache = {}
        self.SaveCacheOrder = {}
        self.Destroyed = false
    end,

    --- Publishes a fresh (sorted) copy of the accumulator so dependents go dirty.
    ---@param self UICustomLobbyMapCatalog
    ---@param accumulator UILobbyScenarioInfo[]
    Publish = function(self, accumulator)
        local snapshot = table.copy(accumulator)
        table.sort(snapshot, SortByName)
        self.Scenarios:Set(snapshot)
    end,

    --- Enumerates `/maps` across frames, loading each map's info and streaming the playable
    --- skirmish maps into the `Scenarios` LazyVar in batches.
    --- TODO: mod maps (legacy also scanned `mods.AllSelectableMods()`); skipped for now.
    ---@param self UICustomLobbyMapCatalog
    LoadThread = function(self)
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
                self:Publish(accumulator)
                WaitFrames(5)
            end
        end

        self.Loaded = true
        self.Loading = false
        self.Worker = nil
        self:Publish(accumulator)
    end,

    --- Kicks off the async enumeration if it hasn't run yet. Idempotent — safe to call on every
    --- dialog open; once loaded it's a no-op and the cached list stays.
    ---@param self UICustomLobbyMapCatalog
    EnsureLoaded = function(self)
        if self.Loading or self.Loaded then
            return
        end
        self.Loading = true
        self.Scenarios:Set({})
        -- tracked on `self` (not the trash) so Refresh can kill it without dropping the LazyVar
        self.Worker = ForkThread(self.LoadThread, self)
    end,

    --- The current (possibly partial) list of maps.
    ---@param self UICustomLobbyMapCatalog
    ---@return UILobbyScenarioInfo[]
    GetScenarios = function(self)
        return self.Scenarios()
    end,

    --- How many maps are currently loaded.
    ---@param self UICustomLobbyMapCatalog
    ---@return number
    GetCount = function(self)
        return table.getn(self.Scenarios())
    end,

    --- Whether the disk has been fully enumerated (vs. still streaming).
    ---@param self UICustomLobbyMapCatalog
    ---@return boolean
    IsLoaded = function(self)
        return self.Loaded
    end,

    --- Finds the loaded map whose file path matches `scenarioFile` (case-insensitive), or nil.
    ---@param self UICustomLobbyMapCatalog
    ---@param scenarioFile FileName | false
    ---@return UILobbyScenarioInfo | nil
    FindByFile = function(self, scenarioFile)
        if not scenarioFile then
            return nil
        end
        local target = string.lower(scenarioFile)
        for _, scenario in self.Scenarios() do
            if string.lower(scenario.file) == target then
                return scenario
            end
        end
        return nil
    end,

    --- Loads a scenario's info for `scenarioFile`. Returns the already-enumerated entry if we have
    --- it (the streamed list is the info cache), else reads it from disk. nil if unreadable.
    ---@param self UICustomLobbyMapCatalog
    ---@param scenarioFile FileName | false
    ---@return UILobbyScenarioInfo | nil
    LoadInfo = function(self, scenarioFile)
        if not scenarioFile then
            return nil
        end
        local cached = self:FindByFile(scenarioFile)
        if cached then
            return cached
        end
        local info = LoadScenarioInfoFile(scenarioFile)
        if not info then
            return nil
        end
        info.file = scenarioFile
        return info --[[@as UILobbyScenarioInfo]]
    end,

    --- Loads (and caches) a scenario's save file — the marker data the preview overlays need.
    --- The save `doscript` is expensive, and both the in-lobby preview and the picker re-load the
    --- same maps repeatedly, so results are memoised by save path with a small FIFO bound. Returns
    --- nil if the save is missing / unreadable (cached as a negative so we don't retry the disk).
    ---@param self UICustomLobbyMapCatalog
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@return UIScenarioSaveFile | nil
    LoadSave = function(self, scenarioInfo)
        if not (scenarioInfo and scenarioInfo.save) then
            return nil
        end

        local key = string.lower(scenarioInfo.save)
        local cached = self.SaveCache[key]
        if cached ~= nil then
            return cached or nil               -- `false` = known-missing
        end

        ---@type UIScenarioSaveFile | false
        local save = LoadScenarioSaveFile(scenarioInfo.save) or false

        self.SaveCache[key] = save
        table.insert(self.SaveCacheOrder, key)
        if table.getn(self.SaveCacheOrder) > SaveCacheMax then
            local oldest = table.remove(self.SaveCacheOrder, 1)
            self.SaveCache[oldest] = nil
        end

        return save or nil
    end,

    --- Extracts the *interesting* bits of a scenario's save — the things the preview overlays and the
    --- rules actually read — so callers never touch the raw save shape. Loads the (memoised) save once
    --- and returns the start spots plus mass / hydrocarbon / wreck point lists, each normalised to a
    --- 2-element `{x, z}` (the save's resource markers carry a 3D `position`, so we take `[1]` and
    --- `[3]`). Always returns a table — empty lists when the save is missing / unreadable — so callers
    --- can read its fields unguarded.
    ---@param self UICustomLobbyMapCatalog
    ---@param scenarioInfo UILobbyScenarioInfo
    ---@return UICustomLobbyScenarioMarkers
    LoadMarkers = function(self, scenarioInfo)
        ---@type UICustomLobbyScenarioMarkers
        local markers = { Spawns = {}, MassPoints = {}, HydroPoints = {}, Wrecks = {} }

        local save = self:LoadSave(scenarioInfo)
        if not save then
            return markers
        end

        -- start spots: one {x, z} per army, in army order
        markers.Spawns = GetStartPositions(scenarioInfo, save) or {}

        -- resource + wreck deposits: walk the master-chain markers once, bucket by type
        local masterChain = save.MasterChain and save.MasterChain['_MASTERCHAIN_']
        local raw = (masterChain and masterChain.Markers) or {}
        for _, marker in raw do
            local position = marker.position
            if position then
                if marker.type == "Mass" then
                    table.insert(markers.MassPoints, { position[1], position[3] })
                elseif marker.type == "Hydrocarbon" then
                    table.insert(markers.HydroPoints, { position[1], position[3] })
                elseif marker.type and string.find(string.lower(marker.type), 'wreck') then
                    table.insert(markers.Wrecks, { position[1], position[3] })
                end
            end
        end

        return markers
    end,

    --- Drops everything so the next `EnsureLoaded` re-reads from disk (e.g. maps changed on disk).
    --- Kills any in-flight load thread and resets the cached list *in place* (same LazyVar) so
    --- existing subscribers stay valid — this is a reset, not a teardown.
    ---@param self UICustomLobbyMapCatalog
    Refresh = function(self)
        if self.Worker then
            KillThread(self.Worker)
            self.Worker = nil
        end
        self.Loaded = false
        self.Loading = false
        self.Scenarios:Set({})
        self.SaveCache = {}
        self.SaveCacheOrder = {}
    end,

    --- `Destroyable`: kill the load thread and drop the cached list + save cache. Called by the
    --- session trash on `Teardown()`. Idempotent. Clears the module singleton so the next access
    --- rebuilds a fresh catalog (and re-registers it in the next session's trash).
    ---@param self UICustomLobbyMapCatalog
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        if self.Worker then
            KillThread(self.Worker)
            self.Worker = nil
        end
        self.Loaded = false
        self.Loading = false
        self.SaveCache = {}
        self.SaveCacheOrder = {}
        self.Trash:Destroy()   -- frees the Scenarios LazyVar
        if Instance == self then
            Instance = nil
        end
    end,
}

--#endregion

-------------------------------------------------------------------------------
--#region Singleton + facade
--
-- The catalog data outlives any single map-select dialog (it's cached across opens) but dies with
-- the lobby session. So the singleton is created on first use and registered in the session trash;
-- `CustomLobbySession.Teardown()` destroys it. The module functions are thin facades so the five
-- call sites keep using `CustomLobbyMapCatalog.LoadInfo(file)` etc. unchanged.

--- Returns the catalog singleton, creating (and registering it in the session trash) on first
--- access — including after a teardown, so the registry is reusable across lobby sessions.
---@return UICustomLobbyMapCatalog
function GetSingleton()
    if not Instance then
        Instance = Catalog()
        CustomLobbySession.GetTrash():Add(Instance)
    end
    return Instance
end

--- Kicks off the async enumeration if it hasn't run yet.
function EnsureLoaded()
    GetSingleton():EnsureLoaded()
end

--- The maps LazyVar — subscribe to it (via `Derive`) to react as the list streams in.
---@return LazyVar<UILobbyScenarioInfo[]>
function GetScenariosVar()
    return GetSingleton().Scenarios
end

--- The current (possibly partial) list of maps.
---@return UILobbyScenarioInfo[]
function GetScenarios()
    return GetSingleton():GetScenarios()
end

--- How many maps are currently loaded.
---@return number
function GetCount()
    return GetSingleton():GetCount()
end

--- Whether the disk has been fully enumerated (vs. still streaming).
---@return boolean
function IsLoaded()
    return GetSingleton():IsLoaded()
end

--- Finds the loaded map whose file path matches `scenarioFile` (case-insensitive), or nil.
---@param scenarioFile FileName | false
---@return UILobbyScenarioInfo | nil
function FindByFile(scenarioFile)
    return GetSingleton():FindByFile(scenarioFile)
end

--- Loads a scenario's info for `scenarioFile`.
---@param scenarioFile FileName | false
---@return UILobbyScenarioInfo | nil
function LoadInfo(scenarioFile)
    return GetSingleton():LoadInfo(scenarioFile)
end

--- Loads (and caches) a scenario's save file — the marker data the preview overlays need.
---@param scenarioInfo UILobbyScenarioInfo
---@return UIScenarioSaveFile | nil
function LoadSave(scenarioInfo)
    return GetSingleton():LoadSave(scenarioInfo)
end

--- Extracts a scenario's interesting save markers (spawns + mass / hydro / wreck points) so callers
--- read structured points instead of fishing through the raw save. See the method.
---@param scenarioInfo UILobbyScenarioInfo
---@return UICustomLobbyScenarioMarkers
function LoadMarkers(scenarioInfo)
    return GetSingleton():LoadMarkers(scenarioInfo)
end

--- Drops everything so the next `EnsureLoaded` re-reads from disk (e.g. maps changed on disk).
function Refresh()
    GetSingleton():Refresh()
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
