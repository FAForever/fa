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

-- Option utilities: the UI-facing helper for game options, the sibling of `maputil.lua` (maps)
-- and `modutilities.lua` (mods). Inspired by Penguin5's `optionutil.lua`.
--
-- A game option is a `ScenarioOption` (see lobbyOptions.lua): `{ key, label, help, default,
-- mponly?, values, value_text?, value_help? }`, where `values` is a list of either
-- `{ key, text, help }` tables or bare values formatted through `value_text`. `default` is a
-- 1-based index into `values`. The *selected* value of an option is stored, by its `key`, in the
-- game-options value table (the launch model's `GameOptions`) as the chosen value's `key`.
--
-- Options come from three sources — the three columns of the options dialog:
--   * **lobby**    — the static base options (team / global / AI) from `lobbyOptions.lua`;
--   * **scenario** — the selected map's `_options.lua` (loaded via MapUtil);
--   * **mods**     — each selected sim mod's `/lua/AI/LobbyOptions/lobbyoptions.lua` (`AIOpts`).
--
-- This module only *gathers and interprets* the schema + values (pure, no UI). Which option
-- value is live, the per-option default, and how a value reads on screen all come from here so the
-- dialog and the controller agree. The schema is reference data (each peer derives it from the
-- synced `ScenarioFile` + `GameMods`); only the *values* are synced.

local LobbyOptions = import("/lua/ui/lobby/lobbyOptions.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local Mods = import("/lua/mods.lua")

-- where a sim mod declares its lobby options, relative to the mod's location
local ModOptionsFile = "/lua/AI/LobbyOptions/lobbyoptions.lua"

-------------------------------------------------------------------------------
--#region Gathering the schema

--- Appends every entry of `source` to `target` whose `key` isn't already present, so later
--- sources can't silently shadow an earlier option. Returns `target`.
---@param target ScenarioOption[]
---@param source ScenarioOption[]
---@return ScenarioOption[]
local function AppendUniqueByKey(target, source)
    local seen = {}
    for _, option in target do
        seen[option.key] = true
    end
    for _, option in source do
        if option.key and not seen[option.key] then
            seen[option.key] = true
            table.insert(target, option)
        end
    end
    return target
end

--- The static lobby options (team + global + AI), as one fresh list.
---@return ScenarioOption[]
function GetLobbyOptions()
    local options = {}
    AppendUniqueByKey(options, LobbyOptions.teamOptions or {})
    AppendUniqueByKey(options, LobbyOptions.globalOpts or {})
    AppendUniqueByKey(options, LobbyOptions.AIOpts or {})
    return options
end

--- The selected scenario's own options (its `_options.lua`), validated, or an empty list.
---@param scenarioFile FileName | false
---@return ScenarioOption[]
function GetScenarioOptions(scenarioFile)
    if not scenarioFile then
        return {}
    end
    local path = MapUtil.GetPathToScenarioOptions(scenarioFile)
    local ok, options = pcall(MapUtil.LoadScenarioOptionsFile, path)
    if not ok or not options then
        return {}
    end
    -- ValidateScenarioOptions repairs bad `default` indices *in place* (and returns false when it
    -- had to), so we call it for that side-effect and keep the now-sane options either way. It's
    -- pcall'd because it indexes `option.values` — untrusted disk data may have a malformed option.
    pcall(MapUtil.ValidateScenarioOptions, options)
    return options
end

--- The options contributed by the selected sim mods — each mod's `lobbyoptions.lua` `AIOpts`,
--- merged and de-duplicated by key.
---@param gameMods table<string, true> # selected sim-mod uid set (the launch model's GameMods)
---@return ScenarioOption[]
function GetModOptions(gameMods)
    if not gameMods then
        return {}
    end
    local allMods = Mods.AllMods()
    local options = {}
    for uid in gameMods do
        local mod = allMods[uid]
        if mod and mod.location then
            local path = mod.location .. ModOptionsFile
            if DiskGetFileInfo(path) then
                local ok, module = pcall(import, path)
                if ok and module and module.AIOpts then
                    AppendUniqueByKey(options, module.AIOpts)
                end
            end
        end
    end
    -- repair any bad `default` indices in place (same contract as the scenario options); pcall'd
    -- because mod-supplied options are untrusted disk data
    pcall(MapUtil.ValidateScenarioOptions, options)
    return options
end

--#endregion

-------------------------------------------------------------------------------
--#region Interpreting options + values

--- The `key` an option value resolves to (a `{key=...}` table's key, or a bare value itself).
---@param value any | ScenarioOptionValue
---@return any
function ValueKeyOf(value)
    if type(value) == 'table' then
        return value.key
    end
    return value
end

--- How an option value reads on screen: a `{text=...}` value's localized text, else the bare
--- value run through the option's `value_text` formatter (defaulting to the value itself).
---@param option ScenarioOption
---@param value any | ScenarioOptionValue
---@return string
function ValueDisplay(option, value)
    if type(value) == 'table' then
        return LOC(value.text) or tostring(value.key)
    end
    if option.value_text then
        -- pcall: a malformed mod-supplied `value_text` (bad format spec) would otherwise throw
        local ok, formatted = pcall(string.format, LOC(option.value_text), tostring(value))
        return ok and formatted or tostring(value)
    end
    return tostring(value)
end

--- The default value-key of an option (`values[default]`, resolved through `ValueKeyOf`).
---@param option ScenarioOption
---@return any
function GetDefaultValueKey(option)
    -- clamp against a garbage `default` index (untrusted options that skipped validation)
    return ValueKeyOf(option.values[option.default] or option.values[1])
end

--- The currently selected value-key for an option: the stored value if present, else the default.
---@param option ScenarioOption
---@param values table<string, any> # key -> selected value-key
---@return any
function GetCurrentValueKey(option, values)
    local current = values[option.key]
    if current == nil then
        return GetDefaultValueKey(option)
    end
    return current
end

--- Whether an option is currently at its default value.
---@param option ScenarioOption
---@param values table<string, any>
---@return boolean
function IsDefault(option, values)
    return GetCurrentValueKey(option, values) == GetDefaultValueKey(option)
end

--- The 1-based index into `option.values` of the given value-key, or the option's default index
--- when it doesn't match any value.
---@param option ScenarioOption
---@param valueKey any
---@return number
function FindValueIndex(option, valueKey)
    for i, value in option.values do
        if ValueKeyOf(value) == valueKey then
            return i
        end
    end
    return option.default
end

--- The display labels for an option's values, in order (for a dropdown).
---@param option ScenarioOption
---@return string[]
function ValueLabels(option)
    local labels = {}
    for i, value in option.values do
        labels[i] = ValueDisplay(option, value)
    end
    return labels
end

--- Fills `values` (a copy) with the default for every option in `options` that has no value yet,
--- so the result is a complete set ready to launch with. Returns the copy.
---@param options ScenarioOption[]
---@param values table<string, any>
---@return table<string, any>
function SeedDefaults(options, values)
    local seeded = table.copy(values or {})
    for _, option in options do
        if seeded[option.key] == nil then
            seeded[option.key] = GetDefaultValueKey(option)
        end
    end
    return seeded
end

--#endregion
