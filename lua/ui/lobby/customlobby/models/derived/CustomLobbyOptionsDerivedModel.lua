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

-- ============================================================================================
-- DERIVED MODEL — read-only. See /lua/ui/lobby/customlobby/models/derived/CLAUDE.md.
--
-- A derived model is a pure function of the authoritative models: it resolves compact synced fields
-- into a rich, ready-to-read bundle and exposes it reactively. Views read it; the **controller never
-- writes it** (there are no write helpers) — to change what it holds, change the source fields it
-- derives from. That keeps the launch model the single source of truth and this a cache/projection.
-- ============================================================================================
--
-- The **derived game options**: the launch model stores options in their most compact form — a flat
-- `GameOptions` value table (`key -> chosen value-key`). On its own that says nothing about what an
-- option *is* (its label, help, possible values, which category it belongs to, what its default is).
-- That meaning lives in the option *schema*, gathered from three sources:
--   * **lobby**    — the static base options (lobbyOptions.lua), via `/lua/ui/optionutil.lua`;
--   * **scenario** — the selected map's `_options.lua`, via the map catalog's `LoadOptions`;
--   * **mods**     — each selected sim mod's lobby options, via `/lua/ui/optionutil.lua`.
--
-- This model joins the two: it splits the options into those three categories and **enriches** each
-- one with its localized text + help, its currently-chosen value (display + key) and whether that is
-- the default — so consumers (the Options panel, the Options tab badge) just read the field they need
-- instead of re-gathering the schema and re-interpreting values themselves.
--
-- **Schema caching.** Gathering the schema is disk work (the map's `_options.lua` is a `doscript`,
-- mod options are file reads), and it only changes when the scenario or the mod set changes — not when
-- a value changes. So the schema is cached and rebuilt only when its inputs change (keyed by scenario
-- file + mod set); a value edit just re-enriches the cached schema, which is cheap. (The old Options
-- panel re-read those files on *every* refresh — i.e. every option tweak.)
--
-- It reads the scenario from the scenario derived model (already deduped), and the mod set + values
-- from the launch model. Reference data, never on the wire — every peer derives its own.
--
-- LIFETIME. It is a `ClassSimple` implementing `Destroyable`, registered in the session trash bag (see
-- CustomLobbySession) on first access, so one `CustomLobbySession.Teardown()` frees its `Options`
-- LazyVar, severs its 3 subscriptions and drops the cached schema — instead of leaking them for the
-- whole match. The schema cache lives on the instance, so a new session re-gathers it fresh. See the
-- scenario / mods / restrictions / slots models for the pattern.

local Create = import("/lua/lazyvar.lua").Create
local Derive = import("/lua/lazyvar.lua").Derive
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbyScenarioDerivedModel = import("/lua/ui/lobby/customlobby/models/derived/customlobbyscenarioderivedmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")
local OptionUtil = import("/lua/ui/optionutil.lua")

-------------------------------------------------------------------------------
--#region Shape

--- Where an option comes from — `false` for the lobby base options, else the map / mod it belongs to.
---@class UICustomLobbyOptionOrigin
---@field Kind 'scenario' | 'mod'
---@field Name string                # the map name / the mod name

--- One enriched option: the schema entry joined with its current value.
---@class UICustomLobbyOption
---@field Key       string
---@field Label     string                          # LOC'd display text
---@field Help      string | false                  # LOC'd help/description, or false when none
---@field ValueKey  any                             # the chosen value-key in effect (stored, else default)
---@field ValueText string                          # the chosen value's display text (its `text`, not its key)
---@field ValueHelp string | false                  # LOC'd help for the chosen value, or false when none
---@field IsDefault boolean                          # whether the value in effect is the option's default
---@field Origin    UICustomLobbyOptionOrigin | false
---@field Option    ScenarioOption                  # the raw schema entry (escape hatch: value list, etc.)

--- A category of options (lobby / scenario / mods).
---@class UICustomLobbyOptionCategory
---@field Key     'lobby' | 'scenario' | 'mods'
---@field Title   string
---@field Options UICustomLobbyOption[]

--- The fully-derived options view: the three categories + the count changed from default.
---@class UICustomLobbyOptions
---@field Categories     UICustomLobbyOptionCategory[]  # always three, in order: lobby, scenario, mods
---@field NonDefaultCount number                        # options changed from their default (backs the badge)

--#endregion

-------------------------------------------------------------------------------
--#region Derived model

-- The singleton, forward-declared above the class so the class methods (`Destroy`) capture it as an
-- upvalue. Assigned in `SetupSingleton`, cleared in `Destroy`. The schema cache lives on the instance
-- (`self.Schema` / `self.SchemaKey`), so it resets with each new session's model.
---@type UICustomLobbyOptionsDerivedModel | nil
local Instance = nil

--- An empty (no-options) bundle — the initial value, before the first derivation runs.
---@return UICustomLobbyOptions
local function EmptyOptions()
    return {
        Categories = {
            { Key = 'lobby',    Title = "Lobby",    Options = {} },
            { Key = 'scenario', Title = "Scenario", Options = {} },
            { Key = 'mods',     Title = "Mods",     Options = {} },
        },
        NonDefaultCount = 0,
    }
end

--- A stable key for the schema inputs: scenario file + the sorted selected mod uids.
---@param scenarioFile FileName | false
---@param gameMods table<string, true>
---@return string
local function SchemaKeyFor(scenarioFile, gameMods)
    local uids = {}
    for uid in (gameMods or {}) do
        table.insert(uids, uid)
    end
    table.sort(uids)
    return tostring(scenarioFile) .. "|" .. table.concat(uids, ",")
end

--- (Re)gathers the option schema if the scenario / mod set changed since last time; otherwise keeps
--- the cache. This is the only disk-touching step, so it is deduped by `self.SchemaKey`.
---@param self UICustomLobbyOptionsDerivedModel
---@param scenario UICustomLobbyScenario | false
---@param gameMods table<string, true>
local function EnsureSchema(self, scenario, gameMods)
    local scenarioFile = scenario and scenario.File or false
    local key = SchemaKeyFor(scenarioFile, gameMods)
    if self.Schema and key == self.SchemaKey then
        return
    end
    self.SchemaKey = key
    self.Schema = {
        Lobby = OptionUtil.GetLobbyOptions(),
        Scenario = CustomLobbyMapCatalog.LoadOptions(scenarioFile),
        ScenarioName = scenario and scenario.Name or false,
        ModGroups = OptionUtil.GetModOptionsByMod(gameMods or {}),
    }
end

--- Joins one schema option with the current values into an enriched option.
---@param option ScenarioOption
---@param values table<string, any>
---@param origin UICustomLobbyOptionOrigin | false
---@return UICustomLobbyOption
local function EnrichOption(option, values, origin)
    local valueKey = OptionUtil.GetCurrentValueKey(option, values)
    -- the value *entry* in effect (a `{ key, text, help }` table, or a bare value) — resolve it from
    -- the key so we show its `text` (not the raw key) and can surface its `help`
    local valueEntry = option.values and option.values[OptionUtil.FindValueIndex(option, valueKey)]
    return {
        Key = option.key,
        Label = LOC(option.label) or option.key,
        Help = (option.help and LOC(option.help)) or false,
        ValueKey = valueKey,
        ValueText = OptionUtil.ValueDisplay(option, valueEntry),
        ValueHelp = (type(valueEntry) == 'table' and valueEntry.help and LOC(valueEntry.help)) or false,
        IsDefault = OptionUtil.IsDefault(option, values),
        Origin = origin,
        Option = option,
    }
end

--- Builds the full enriched, categorized options bundle for the current schema + values.
---@param self UICustomLobbyOptionsDerivedModel
---@param scenario UICustomLobbyScenario | false
---@param gameMods table<string, true>
---@param values table<string, any>
---@return UICustomLobbyOptions
local function BuildOptions(self, scenario, gameMods, values)
    EnsureSchema(self, scenario, gameMods)
    values = values or {}

    local lobby = {}
    for _, option in self.Schema.Lobby do
        table.insert(lobby, EnrichOption(option, values, false))
    end

    local scenarioOrigin = { Kind = 'scenario', Name = self.Schema.ScenarioName or "the map" }
    local scenarioOpts = {}
    for _, option in self.Schema.Scenario do
        table.insert(scenarioOpts, EnrichOption(option, values, scenarioOrigin))
    end

    local mods = {}
    for _, group in self.Schema.ModGroups do
        local origin = { Kind = 'mod', Name = group.name }
        for _, option in group.options do
            table.insert(mods, EnrichOption(option, values, origin))
        end
    end

    -- count changed-from-default (mirrors OptionUtil.CountNonDefault: lobby + scenario as-is, mods
    -- deduped by key so a key two mods both declare is counted once)
    local count = 0
    for _, e in lobby do if not e.IsDefault then count = count + 1 end end
    for _, e in scenarioOpts do if not e.IsDefault then count = count + 1 end end
    local seenMod = {}
    for _, e in mods do
        if not seenMod[e.Key] then
            seenMod[e.Key] = true
            if not e.IsDefault then count = count + 1 end
        end
    end

    return {
        Categories = {
            { Key = 'lobby',    Title = "Lobby",    Options = lobby },
            { Key = 'scenario', Title = "Scenario", Options = scenarioOpts },
            { Key = 'mods',     Title = "Mods",     Options = mods },
        },
        NonDefaultCount = count,
    }
end

--- Reactive derived-options singleton — a `ClassSimple` implementing `Destroyable`, registered in the
--- session trash so one `CustomLobbySession.Teardown()` frees it. **Read-only** — no write helpers; the
--- controller never touches it. It re-derives from the launch model's `GameOptions` / `GameMods` and
--- the scenario derived model, caching the disk-gathered option schema on the instance.
---@class UICustomLobbyOptionsDerivedModel : Destroyable
---@field Trash     TrashBag                       # owns the Options var + the 3 observers (freed on Destroy)
---@field Options   LazyVar<UICustomLobbyOptions>
---@field Observers LazyVar[]                       # internal: scenario/mods/options subscriptions (strong refs; also in Trash)
---@field Schema    table | false                   # cached option schema (lobby/scenario/mod), keyed by SchemaKey
---@field SchemaKey string | false                  # scenario file + sorted mod uids the Schema was gathered for
---@field Destroyed boolean
local OptionsModel = ClassSimple {

    ---@param self UICustomLobbyOptionsDerivedModel
    __init = function(self)
        self.Trash = TrashBag()
        self.Options = self.Trash:Add(Create(EmptyOptions()))
        self.Observers = {}
        self.Schema = false
        self.SchemaKey = false
        self.Destroyed = false

        -- re-derive on a scenario / mod-set / option-value change. Each observer is kept strongly on
        -- self.Observers (the trash is weak-valued) AND added to the trash, so it isn't GC'd and Destroy
        -- severs all three. `Derive` fires synchronously on creation → the options resolve now.
        local function subscribe(source)
            table.insert(self.Observers, self.Trash:Add(Derive(source, function(lazy)
                lazy()
                self:Recompute()
            end)))
        end

        local launch = CustomLobbyLaunchModel.GetSingleton()
        subscribe(CustomLobbyScenarioDerivedModel.GetScenarioVar())
        subscribe(launch.GameMods)
        subscribe(launch.GameOptions)
    end,

    --- Re-derives the options bundle from the current scenario + mods + values and publishes it. The
    --- schema is re-gathered (disk) only when the scenario / mod set changed (the `SchemaKey` cache);
    --- a value-only change just re-enriches the cached schema.
    ---@param self UICustomLobbyOptionsDerivedModel
    Recompute = function(self)
        local scenario = CustomLobbyScenarioDerivedModel.GetScenario()
        local launch = CustomLobbyLaunchModel.GetSingleton()
        self.Options:Set(BuildOptions(self, scenario, launch.GameMods(), launch.GameOptions()))
    end,

    --- `Destroyable`: frees the `Options` var + the 3 subscriptions (so they stop firing) and clears the
    --- module singleton, so the next access rebuilds and re-registers in the next session's trash. The
    --- cached schema dies with the instance. Idempotent.
    ---@param self UICustomLobbyOptionsDerivedModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Trash:Destroy()       -- frees the Options LazyVar + all observer subscriptions
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh options-model singleton and registers it in the session trash. (Because `Derive`
--- fires synchronously on creation, the options resolve immediately.)
---@return UICustomLobbyOptionsDerivedModel
function SetupSingleton()
    Instance = OptionsModel()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- Returns the options-model singleton, creating (and registering) it on first access — including
--- after a teardown, so it is reusable across lobby sessions.
---@return UICustomLobbyOptionsDerivedModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyOptionsDerivedModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Accessors

--- The reactive options var — subscribe to it (via `Derive`) to react when options/values change.
---@return LazyVar<UICustomLobbyOptions>
function GetOptionsVar()
    return GetSingleton().Options
end

--- The current enriched, categorized options bundle.
---@return UICustomLobbyOptions
function GetOptions()
    return GetSingleton().Options()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: destroy the old singleton (severing its subscriptions + dropping its schema cache)
--- and rebuild via the new module. The bundle is fully derived from the launch + scenario models, so
--- there is no state to copy across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        Instance:Destroy()
        newModule.SetupSingleton()
    end
end

--- Hot-reload hook: re-imports this module after a couple of frames.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
