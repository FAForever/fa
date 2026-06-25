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

-- The unit catalog: the custom lobby's per-faction unit blueprints for the restriction dialog —
-- the unit-side counterpart to CustomLobbyModCatalog. *Reference data*, NOT a model: it is built
-- from the player's own game files + the lobby's sim mods and never goes on the wire (only the
-- host's restriction *choice* — the launch model's `Restrictions` — syncs).
--
-- It wraps the heavy `UnitsAnalyzer` blueprint pipeline (the same one the legacy UnitsManager uses)
-- behind a small reactive surface: `EnsureLoaded(activeMods)` kicks off the async fetch, `Progress`
-- / `ProgressText` stream the load progress, and `Factions` fires once with the grouped result —
-- a list of `{ Name, Order, Blueprints, Units }` per faction, where `Units` is the type grouping
-- (ACU / SCU / AIR / LAND / NAVAL / CONSTRUCT / ECONOMIC / SUPPORT / CIVILIAN / DEFENSES) from
-- `UnitsAnalyzer.GetUnitsGroups`. The dialog renders one faction tab per entry.

local Create = import("/lua/lazyvar.lua").Create
local UnitsAnalyzer = import("/lua/ui/lobby/unitsanalyzer.lua")

-- left-to-right tab order; an unknown faction is appended after these
local FactionOrder = { SERAPHIM = 1, UEF = 2, CYBRAN = 3, AEON = 4, NOMADS = 5 }

---@class UICustomLobbyFaction
---@field Name string
---@field Order number
---@field Blueprints table[]                 # the faction's blueprints (list)
---@field Units table<string, table>         # type group -> { [unitId] = blueprint }

--- The grouped factions, fired once when the load completes (empty until then).
---@type LazyVar<UICustomLobbyFaction[]>
local Factions = Create({})

--- Load progress in [0, 1] and the current task label, streamed while loading.
local Progress = Create(0)
local ProgressText = Create("")

local Loading = false
local Loaded = false

-------------------------------------------------------------------------------
--#region Build

--- Groups the analyzer's flat blueprint list into per-faction entries (each with its type groups),
--- sorted by `FactionOrder`, and publishes them on the `Factions` LazyVar.
local function PublishFactions()
    local blueprints = UnitsAnalyzer.GetBlueprintsList()
    local byName = {}
    for _, bp in blueprints.All do
        if bp.Faction then
            local faction = byName[bp.Faction]
            if not faction then
                faction = { Name = bp.Faction, Blueprints = {}, Units = {} }
                byName[bp.Faction] = faction
            end
            table.insert(faction.Blueprints, bp)
        end
    end

    local list = {}
    for name, faction in byName do
        UnitsAnalyzer.GetUnitsGroups(faction.Blueprints, faction)
        faction.Order = FactionOrder[name] or (table.getsize(FactionOrder) + table.getn(list) + 1)
        table.insert(list, faction)
    end
    table.sort(list, function(a, b) return a.Order < b.Order end)

    Factions:Set(list)
end

--#endregion

-------------------------------------------------------------------------------
--#region Public API

--- Kicks off the async blueprint fetch for the given sim mods if it hasn't run yet. Idempotent —
--- safe to call on every open; once loaded it's a no-op and the cached factions stay.
---@param activeMods table[]      # resolved sim-mod list (e.g. `Mods.GetGameMods(launch.GameMods())`)
function EnsureLoaded(activeMods)
    if Loading or Loaded then
        return
    end
    Loading = true
    Progress:Set(0)
    ProgressText:Set("Loading blueprints…")
    Factions:Set({})

    local notifier = import("/lua/ui/lobby/tasknotifier.lua").Create()
    notifier:Reset()
    notifier.OnProgressCallback = function(task)
        Progress:Set(notifier.totalProgress or 0)
        if task and task.name then
            ProgressText:Set(task.name .. " …")
        end
    end
    notifier.OnCompleteCallback = function()
        PublishFactions()
        Progress:Set(1)
        ProgressText:Set("")
        Loaded = true
        Loading = false
    end

    UnitsAnalyzer.FetchBlueprints(activeMods or {}, false, notifier)
end

--- The factions LazyVar — subscribe (via `Derive`) to react when the load completes.
---@return LazyVar<UICustomLobbyFaction[]>
function GetFactionsVar()
    return Factions
end

--- The current (possibly empty, until loaded) list of factions.
---@return UICustomLobbyFaction[]
function GetFactions()
    return Factions()
end

--- The load-progress LazyVar in [0, 1].
---@return LazyVar<number>
function GetProgressVar()
    return Progress
end

--- The current load-task label LazyVar.
---@return LazyVar<string>
function GetProgressTextVar()
    return ProgressText
end

--- Whether the blueprints have finished loading.
---@return boolean
function IsLoaded()
    return Loaded
end

--- Drops the cache so the next `EnsureLoaded` re-fetches (e.g. the sim mods changed).
function Refresh()
    UnitsAnalyzer.StopBlueprints()
    Loaded = false
    Loading = false
    Factions:Set({})
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module after a couple of frames. The factions rebuild on the
--- next access, so dropping the cache is harmless.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
