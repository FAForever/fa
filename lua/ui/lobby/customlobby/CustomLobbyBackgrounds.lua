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

-- Lobby background discovery + the per-peer background selection. Purely cosmetic and never synced
-- (like a skin choice): it scans textures/ui/common/lobby/backgrounds for *.png, exposes the list,
-- and persists the chosen path in this machine's prefs. The reactive `Selected` handle lets the
-- background surface (CustomLobbyBackground) and the picker (CustomLobbyInterface's combo) stay in
-- sync without polling.
--
-- Pure data + prefs: no models, no network. The chosen image is drawn to cover the whole window
-- while keeping its aspect ratio — that cover math lives in CustomLobbyBackground.

local Prefs = import("/lua/user/prefs.lua")
local LazyVarCreate = import("/lua/lazyvar.lua").Create

--- The directory scanned for background images (repo-root absolute).
BackgroundsDir = '/textures/ui/common/lobby/backgrounds'

--- The prefs key the chosen background path is stored under (this machine only).
local PrefsKey = "customlobby_background"

--- Reactive handle to the selected background path, or false for "no background" (the solid
--- backdrop). Lazily created + seeded from prefs on first access (see GetSelectedLazy).
---@type LazyVar | false
local SelectedLazy = false

--- A human label for a background file: the bare filename without dir/extension, separators turned
--- to spaces and Title Cased (`aeon-omen.png` -> `Aeon Omen`).
---@param path string
---@return string
local function DisplayName(path)
    local name = string.gsub(path, "^.*/", "")     -- strip directory
    name = string.gsub(name, "%.%w+$", "")          -- strip extension
    name = string.gsub(name, "[-_]", " ")           -- separators -> spaces
    name = string.gsub(name, "(%a)([%w]*)", function(first, rest)
        return string.upper(first) .. rest
    end)
    return name
end

--- All background images on disk as `{ Path, Name }`, sorted by path. Empty when the folder holds
--- none. Re-scanned on each call (cheap — a handful of files).
---@return { Path: FileName, Name: string }[]
function Discover()
    local backgrounds = {}
    for _, path in DiskFindFiles(BackgroundsDir, '*.png') do
        table.insert(backgrounds, { Path = path, Name = DisplayName(path) })
    end
    table.sort(backgrounds, function(a, b) return a.Path < b.Path end)
    return backgrounds
end

--- The selected-path LazyVar, created + seeded on first call. Subscribe with `Derive` to react to
--- background changes. Seeding rule: an explicit stored value (a path, or `false` for "None") is
--- honoured; with nothing stored yet we default to the first discovered image so a fresh lobby
--- shows a backdrop rather than a black frame.
---@return LazyVar
function GetSelectedLazy()
    if not SelectedLazy then
        local stored = Prefs.GetFromCurrentProfile(PrefsKey)
        if stored == nil then
            local all = Discover()
            stored = all[1] and all[1].Path or false
        end
        SelectedLazy = LazyVarCreate(stored or false)
    end
    return SelectedLazy
end

--- The currently selected background path, or false when none is chosen.
---@return FileName | false
function GetSelected()
    return GetSelectedLazy()()
end

--- Chooses `path` as the background (pass false to clear it): updates the reactive handle and
--- persists the choice to prefs.
---@param path FileName | false
function Select(path)
    GetSelectedLazy():Set(path or false)
    Prefs.SetToCurrentProfile(PrefsKey, path or false)
    SavePreferences()
end
