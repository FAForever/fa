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

-- The lobby's bottom-right config panel: a generic CustomLobbyTabs over the four config tabs —
-- Map / Mods / Options / Restrictions. This module is just the tab-list definition; the strip +
-- create-on-select / destroy-on-switch machinery lives in CustomLobbyTabs.
--
-- The Map tab owns its own preview now (it's a normal churned tab — see CustomLobbyMapPanel): the
-- lobby only ever shows ONE current map, and the engine caches map textures by name, so building
-- the preview anew each time you open the Map tab just re-binds the cached texture (no leak). That
-- replaced the earlier pinned-preview-with-a-cover design — the texture-leak rule that motivated it
-- only bites the *map-select dialog*, which browses hundreds of different maps (see mapselect/).

local CustomLobbyTabs = import("/lua/ui/lobby/customlobby/customlobbytabs.lua")
local CustomLobbyMapPanel = import("/lua/ui/lobby/customlobby/config/customlobbymappanel.lua")
local CustomLobbyModsPanel = import("/lua/ui/lobby/customlobby/config/customlobbymodspanel.lua")
local CustomLobbyOptionsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyoptionspanel.lua")
local CustomLobbyUnitsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyunitspanel.lua")

local Tabs = {
    { Label = "Map",          Create = CustomLobbyMapPanel.Create },
    { Label = "Mods",         Create = CustomLobbyModsPanel.Create },
    { Label = "Options",      Create = CustomLobbyOptionsPanel.Create },
    { Label = "Restrictions", Create = CustomLobbyUnitsPanel.Create },
}

--- Builds the config tab panel (a CustomLobbyTabs). The parent sizes it and calls `Initialize()`
--- after mounting (forwarded to the tabs container — three-phase init).
---@param parent Control
---@return UICustomLobbyTabs
Create = function(parent)
    return CustomLobbyTabs.Create(parent, { Tabs = Tabs })
end
