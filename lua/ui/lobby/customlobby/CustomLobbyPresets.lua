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

-- Named setup presets for the custom lobby — the customlobby-native rebuild of the legacy
-- `/lua/ui/lobby/presets.lua` (which keyed `LobbyPresets`). Pure persistence: this module only
-- reads and writes the prefs; it never touches the lobby models or the network. Capturing the
-- current setup into a snapshot and applying a snapshot back are host-authoritative and live in
-- the controller (`CustomLobbyController.BuildSetupSnapshot` / `ApplySetup`).
--
-- A preset is `{ Name = string, Setup = UICustomLobbySetupSnapshot }`, stored as an ordered array
-- under one prefs key so the user's creation order is preserved — mirroring the mod presets in
-- `/lua/ui/modutilities.lua`. A reserved `LastGamePresetName` entry is auto-saved at launch so a
-- rehost can restore the last game (see USER_STORIES.md § O).

local Prefs = import("/lua/user/prefs.lua")

--- The prefs key holding the ordered array of setup presets (the host's machine only).
local PrefsKey = "customlobby_setup_presets"

--- The reserved preset name auto-saved at launch (the rehost source). Shown to the user as a
--- pinned "Last game" entry rather than a normal named preset.
LastGamePresetName = "lastGame"

--- A serializable snapshot of the launch setup (written to disk). **Setup-only** — players,
--- observers and auto-teams / spawn-mex are deliberately not stored (a preset reconfigures a lobby,
--- it doesn't restore a roster).
---@class UICustomLobbySetupSnapshot
---@field ScenarioFile FileName | false
---@field GameOptions  table                 # the host's option values, minus per-player Ratings/ClanTags
---@field GameMods      table<string, true>   # sim-mod uid set
---@field Restrictions  string[]              # unit-restriction preset keys

--- All saved presets, in creation order (the `lastGame` entry included).
---@return { Name: string, Setup: UICustomLobbySetupSnapshot }[]
function GetPresets()
    return Prefs.GetFromCurrentProfile(PrefsKey) or {}
end

--- Finds a preset's setup snapshot by name, or nil.
---@param name string
---@return UICustomLobbySetupSnapshot | nil
function GetPreset(name)
    for _, preset in GetPresets() do
        if preset.Name == name then
            return preset.Setup
        end
    end
    return nil
end

--- Saves `setup` under `name`, overwriting an existing preset with the same name. The caller owns
--- the snapshot (it is stored by reference — pass a fresh `BuildSetupSnapshot()` result).
---@param name string
---@param setup UICustomLobbySetupSnapshot
function SavePreset(name, setup)
    local presets = GetPresets()
    for _, preset in presets do
        if preset.Name == name then
            preset.Setup = setup
            Prefs.SetToCurrentProfile(PrefsKey, presets)
            SavePreferences()
            return
        end
    end
    table.insert(presets, { Name = name, Setup = setup })
    Prefs.SetToCurrentProfile(PrefsKey, presets)
    SavePreferences()
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
    Prefs.SetToCurrentProfile(PrefsKey, kept)
    SavePreferences()
end

--- Renames a preset, preserving its position. Rejects a blank name or a collision with another
--- existing preset (returns false); returns true on success.
---@param oldName string
---@param newName string
---@return boolean
function RenamePreset(oldName, newName)
    if not newName or newName == "" or newName == oldName then
        return false
    end
    local presets = GetPresets()
    local target
    for _, preset in presets do
        if preset.Name == newName then
            return false                     -- collision with a different preset
        end
        if preset.Name == oldName then
            target = preset
        end
    end
    if not target then
        return false
    end
    target.Name = newName
    Prefs.SetToCurrentProfile(PrefsKey, presets)
    SavePreferences()
    return true
end
