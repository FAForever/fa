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

-- Mod utilities: the UI-facing front door for working with mods, the sibling of `maputil.lua`
-- for maps. It is a thin, *pure* helper layer on top of `/lua/mods.lua` (the engine-facing
-- global that the sim, the blueprint loader and ~30 other modules use, so it stays put).
--
-- We're slowly moving UI mod logic here, the same way the map work moved off `MapUtil`:
--   * classification (`Classify`) and display formatting (`FormatName` / `FormatVersion` /
--     `FormatAuthor`) — lifted out of the legacy `ModsManager.lua`, which interleaved them
--     with its layout code;
--   * dependency-aware selection edits (`ResolveEnable` / `ResolveDisable`) — the bits of the
--     legacy `ActivateMod` / `DeactivateMod` that are *just set arithmetic*, with the UI side
--     effects removed;
--   * persistence: writing the selection back to the preference file (`SetSelectedMods` and the
--     UI-only / sim-only variants), so a dialog never touches prefs directly; and
--   * **presets** — named selection snapshots stored in prefs, replacing the old "favorites".
--
-- A picker (e.g. the custom lobby's mod-select dialog) decides *what* the selection is and hands
-- it here to persist; it never reads or writes prefs itself. See
-- `/lua/ui/lobby/customlobby/modselect/`.

local Mods = import("/lua/mods.lua")
local Prefs = import("/lua/user/prefs.lua")
local SetUtils = import("/lua/system/setutils.lua")
local Blacklist = import("/etc/faf/blacklist.lua").Blacklist

--- A mod uid set: `{ [uid] = true }`. The shape `mods.lua` and the launch model use.
---@alias UIModSelection table<string, true>

--- A normalized, display-ready view of a `ModInfo`. The catalog builds these from
--- `Mods.AllSelectableMods()` + the formatting / classification helpers below.
---@class UILobbyModInfo
---@field uid string
---@field name string             # raw mod name (unformatted)
---@field title string            # display name (version stripped, title-cased)
---@field versionText string      # e.g. "v4", or "" when unversioned
---@field author string           # cleaned author (first author, no underscores)
---@field description string
---@field copyright? string
---@field icon FileName
---@field location FileName
---@field ui_only boolean
---@field type ModType            # UI | GAME | BLACKLISTED | NO_DEPENDENCY | LOCAL
---@field blacklistReason? LocalizedString
---@field url? string
---@field github? string
---@field requires? UIModSelection # installed uids this mod pulls in
---@field missing? UIModSelection  # required uids that aren't installed
---@field conflicts? UIModSelection# installed uids that can't be active alongside this one

local PresetsPrefsKey = "customlobby_mod_presets"

-------------------------------------------------------------------------------
--#region Enumeration (thin pass-throughs to mods.lua)

--- All selectable mods on disk, keyed by uid. Cached by `mods.lua`.
---@return table<string, ModInfo>
function GetSelectableMods()
    return Mods.AllSelectableMods()
end

--- Forces the next `GetSelectableMods` to re-read the disk (mods changed while open).
function Refresh()
    Mods.ClearCache()
end

--- Whether a mod uid is on the FAF blacklist; returns the (localized) reason, or nil.
---@param uid string
---@return LocalizedString | nil
function GetBlacklistReason(uid)
    return Blacklist[uid]
end

--- The installed/missing/conflicting dependency sets for a mod. Pass-through to `mods.lua`.
---@param uid string
---@return {requires: UIModSelection?, missing: UIModSelection?, conflicts: UIModSelection?}
function GetDependencies(uid)
    return Mods.GetDependencies(uid)
end

--#endregion

-------------------------------------------------------------------------------
--#region Classification + formatting (lifted from ModsManager.lua)

--- Classifies a mod into the type the picker filters/badges by: BLACKLISTED (on the FAF
--- blacklist or disabled), NO_DEPENDENCY (requires a missing or blacklisted mod), else UI / GAME.
--- (The legacy LOCAL "players missing this mod" type needs host-side peer availability — left
--- for the host slice; this is per-peer reference data.)
---@param mod ModInfo
---@return ModType
function Classify(mod)
    if Blacklist[mod.uid] or mod.enabled == false then
        return "BLACKLISTED"
    end

    local dependencies = Mods.GetDependencies(mod.uid)
    if dependencies.missing then
        return "NO_DEPENDENCY"
    end
    if dependencies.requires then
        for required in dependencies.requires do
            if Blacklist[required] then
                return "NO_DEPENDENCY"
            end
        end
    end

    if mod.ui_only then
        return "UI"
    end
    return "GAME"
end

--- Strips an embedded version tag from a mod name and title-cases it — so "my-mod v2"
--- displays as "My Mod". Mirrors the legacy `GetModNameVersion` name handling.
---@param mod ModInfo
---@return string
function FormatName(mod)
    local name = mod.name or ""
    name = string.gsub(name, '[%[%<%{%(%s]+[vV]+%s*%d+[%.%d]*[%]%>%}%)%s]*', '')
    name = StringCapitalize(name)
    name = string.gsub(name, "-", "", 1)
    return name
end

--- A short version string ("v4"), or "" when the mod declares no integer version.
---@param mod ModInfo
---@return string
function FormatVersion(mod)
    if type(mod.version) == 'number' then
        return "v" .. tostring(mod.version)
    elseif type(mod.version) == 'string' and mod.version ~= "" then
        return "v" .. mod.version
    end
    return ""
end

--- The first credited author, cleaned up, or "UNKNOWN". Mirrors the legacy `GetModAuthor`.
---@param mod ModInfo
---@return string
function FormatAuthor(mod)
    local author = mod.author
    if not author or author == "" then
        return "UNKNOWN"
    end
    if string.len(author) >= 20 then
        if string.find(author, ",") then
            author = StringSplit(author, ',')[1]
        elseif string.find(author, " ") then
            author = StringSplit(author, ' ')[1]
        end
    end
    return (string.gsub(author, "_", "", 1))
end

--#endregion

-------------------------------------------------------------------------------
--#region Dependency-aware selection edits
--
-- Pure set arithmetic — given a selection and a uid, return the NEW selection. The legacy
-- ActivateMod/DeactivateMod did this inline with UI prompts and counters; the picker keeps the
-- UI concerns (a conflict confirmation, repaint) and calls these for the set maths.

--- Adds `uid` to a copy of `selection`, pulling in everything it requires (recursively) and
--- removing any installed mods it conflicts with. Returns the new selection and the conflicts
--- that were turned off (so the caller can surface them).
---@param selection UIModSelection
---@param uid string
---@return UIModSelection selection
---@return string[] disabledConflicts
function ResolveEnable(selection, uid)
    local next = table.copy(selection)
    local disabled = {}

    local function enable(target)
        if next[target] then
            return
        end
        next[target] = true

        local dependencies = Mods.GetDependencies(target)
        if dependencies.conflicts then
            for conflict in dependencies.conflicts do
                if next[conflict] then
                    next[conflict] = nil
                    table.insert(disabled, conflict)
                end
            end
        end
        if dependencies.requires then
            for required in dependencies.requires do
                enable(required)
            end
        end
    end

    enable(uid)
    return next, disabled
end

--- Removes `uid` from a copy of `selection`, and removes any selected mods that require it
--- (recursively). Returns the new selection.
---@param selection UIModSelection
---@param uid string
---@return UIModSelection
function ResolveDisable(selection, uid)
    local next = table.copy(selection)

    local function disable(target)
        if not next[target] then
            return
        end
        next[target] = nil
        -- drop anything still selected that requires the mod we're turning off
        for selected in next do
            local dependencies = Mods.GetDependencies(selected)
            if dependencies.requires and dependencies.requires[target] then
                disable(selected)
            end
        end
    end

    disable(uid)
    return next
end

--- Drops uids that aren't installed any more (e.g. loading an old preset after uninstalling).
---@param selection UIModSelection
---@return UIModSelection
function PruneMissing(selection)
    local installed = Mods.AllMods()
    return SetUtils.PredicateFilter(selection, function(uid)
        return installed[uid] ~= nil
    end)
end

--- The sim-mod (`not ui_only`) subset of a selection.
---@param selection UIModSelection
---@return UIModSelection
function FilterSimMods(selection)
    local installed = Mods.AllMods()
    return SetUtils.PredicateFilter(selection, function(uid)
        return installed[uid] ~= nil and not installed[uid].ui_only
    end)
end

--- The UI-mod (`ui_only`) subset of a selection.
---@param selection UIModSelection
---@return UIModSelection
function FilterUIMods(selection)
    local installed = Mods.AllMods()
    return SetUtils.PredicateFilter(selection, function(uid)
        return installed[uid] ~= nil and installed[uid].ui_only
    end)
end

--#endregion

-------------------------------------------------------------------------------
--#region Persistence (the "updates the preference file" responsibility)

--- The player's currently selected mods (sim + UI), from the preference file.
---@return UIModSelection
function GetSelectedMods()
    return Mods.GetSelectedMods()
end

--- The selected sim mods (the set that becomes the launch model's `GameMods`).
---@return UIModSelection
function GetSelectedSimMods()
    return Mods.GetSelectedSimMods()
end

--- The selected UI mods (applied per-player, never on the wire).
---@return UIModSelection
function GetSelectedUIMods()
    return Mods.GetSelectedUIMods()
end

--- Persists the full selection (sim + UI) to prefs and re-applies the active UI mods. Used by
--- the standalone (main-menu) path, where there's no host to dictate sim mods.
---@param selection UIModSelection
function SetSelectedMods(selection)
    Mods.SetSelectedMods(selection)
end

--- Persists only the UI-mod portion of `uiSelection`, keeping the existing sim selection in
--- prefs untouched, then re-applies active UI mods. Used by the lobby path, where sim mods are
--- host-dictated (synced separately) and only UI mods are this player's own choice.
---@param uiSelection UIModSelection
function SetSelectedUIMods(uiSelection)
    local merged = GetSelectedSimMods()                  -- keep my current sim mods as-is
    for uid in FilterUIMods(uiSelection) do
        merged[uid] = true
    end
    Mods.SetSelectedMods(merged)
end

--#endregion

-------------------------------------------------------------------------------
--#region Presets (named selection snapshots — replacing "favorites")
--
-- A preset is `{ Name = string, Mods = UIModSelection }`. Stored as an array under one prefs
-- key so the order the user created them in is preserved.

--- All saved presets, in creation order.
---@return { Name: string, Mods: UIModSelection }[]
function GetPresets()
    return Prefs.GetFromCurrentProfile(PresetsPrefsKey) or {}
end

--- Finds a preset's selection by name, or nil.
---@param name string
---@return UIModSelection | nil
function GetPreset(name)
    for _, preset in GetPresets() do
        if preset.Name == name then
            return preset.Mods
        end
    end
    return nil
end

--- Saves `selection` under `name`, overwriting an existing preset with the same name.
---@param name string
---@param selection UIModSelection
function SavePreset(name, selection)
    local presets = GetPresets()
    for _, preset in presets do
        if preset.Name == name then
            preset.Mods = table.copy(selection)
            Prefs.SetToCurrentProfile(PresetsPrefsKey, presets)
            return
        end
    end
    table.insert(presets, { Name = name, Mods = table.copy(selection) })
    Prefs.SetToCurrentProfile(PresetsPrefsKey, presets)
end

--- Removes the preset with the given name (no-op if absent).
---@param name string
function DeletePreset(name)
    local presets = GetPresets()
    local kept = {}
    for _, preset in presets do
        if preset.Name ~= name then
            table.insert(kept, preset)
        end
    end
    Prefs.SetToCurrentProfile(PresetsPrefsKey, kept)
end

--#endregion
