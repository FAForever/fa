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

-- The **launch** state: everything the host dictates that becomes part of the launched
-- game (the gameInfo replacement from TARGET_ARCHITECTURE.md). This model IS the launch
-- payload — the host broadcasts it whole (see CustomLobbyController.BroadcastLaunchInfo /
-- BroadcastPlayers), and what the game launches with is exactly what's here.
--
-- It is one of three lobby models — see /lua/ui/lobby/customlobby/CLAUDE.md:
--   * LaunchModel  (this)        — shared, launched.
--   * SessionModel               — shared, lobby-room only (slot count / closed slots).
--   * LocalModel                 — per-peer, never synced (identity, CPU benchmarks).
--
-- Players live as an array of per-slot LazyVars so a change to one slot only re-fires
-- that slot's row. Write helpers keep the copy-then-`Set` discipline (see /lua/ui/CLAUDE.md
-- § 2 — never mutate a held table in place).

local Create = import("/lua/lazyvar.lua").Create
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")

--- Maximum number of player slots the engine supports.
MaxSlots = 16

--- The number of real (non-random) factions — the upper bound of the faction multi-select, and the
--- index just below the Random sentinel. Reads factions.lua so custom factions are counted too.
RealFactionCount = table.getn(import("/lua/factions.lua").Factions)

-------------------------------------------------------------------------------
--#region Shapes

--- A player (human or AI) occupying a slot. Mirrors the fields the legacy lobby's
--- PlayerData carries; trimmed to what the UI reads.
---@class UICustomLobbyPlayer
---@field PlayerName string
---@field OwnerID UILobbyPeerId
---@field Human boolean
---@field Faction number          # 1=UEF 2=Aeon 3=Cybran 4=Seraphim 5=Random — the representative (see Factions)
---@field Factions number[]       # the multi-select: the real-faction indices the player allows; >1 = random among them
---@field PlayerColor number
---@field ArmyColor number
---@field Team number             # 1 = no team (FFA), 2..9 = teams 1..8
---@field StartSpot number
---@field Ready boolean
---@field PL? number              # rating
---@field MEAN? number
---@field DEV? number
---@field NG? number              # number of games
---@field DIV? string             # league division (e.g. "gold")
---@field SUBDIV? string          # league subdivision (e.g. "III")
---@field PlayerClan? string
---@field Country? string
---@field AIPersonality? string

--#endregion

-------------------------------------------------------------------------------
--#region Reactive model

-- LIFETIME. A `ClassSimple` implementing `Destroyable`, registered in the session trash bag (see
-- CustomLobbySession) on first access, so one `CustomLobbySession.Teardown()` resets it. Per the
-- teardown design's decision #3 the write helpers stay **free functions** (below) and `Destroy` is
-- **thin** (nil the module singleton; the LazyVars — the 16 per-slot vars + the rest — are freed by GC
-- once the views observing them are torn down, not proactively, since the interface that subscribes to
-- them isn't in the bag yet). See design/session-trashbag-teardown.md.

-- The singleton, forward-declared above the class so `Destroy` captures it as an upvalue. Assigned in
-- `SetupSingleton`, cleared in `Destroy`.
---@type UICustomLobbyLaunchModel | nil
local Instance = nil

--- Reactive launch-state singleton (shared, host-dictated, part of the launch).
---@class UICustomLobbyLaunchModel : Destroyable
---@field Players      LazyVar<UICustomLobbyPlayer | false>[]           # one LazyVar per slot (1..MaxSlots); false = empty
---@field Observers    LazyVar<UICustomLobbyPlayer[]>                   # observer list
---@field SpawnMex     LazyVar<table<number, boolean>>                  # adaptive-map spawn-mex flags (embedded into the scenario at launch)
---@field AutoTeams    LazyVar<table<number, number>>
---@field GameOptions  LazyVar<table>
---@field GameMods     LazyVar<table>
---@field Restrictions LazyVar<string[]>                                # unit-restriction preset keys (folded into GameOptions.RestrictedCategories at launch)
---@field ScenarioFile LazyVar<FileName | false>
---@field Destroyed    boolean
local LaunchModel = ClassSimple {

    ---@param self UICustomLobbyLaunchModel
    __init = function(self)
        local players = {}
        for slot = 1, MaxSlots do
            players[slot] = Create(false)
        end
        self.Players      = players
        self.Observers    = Create({})
        self.SpawnMex     = Create({})
        self.AutoTeams    = Create({})
        self.GameOptions  = Create({})
        self.GameMods     = Create({})
        self.Restrictions = Create({})
        self.ScenarioFile = Create(false)
        self.Destroyed    = false
    end,

    --- `Destroyable`: thin teardown — drop the module singleton so the next session rebuilds (and
    --- re-registers). The LazyVars GC once the views observing them are gone. Idempotent.
    ---@param self UICustomLobbyLaunchModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh launch-model singleton and registers it in the session trash.
---@return UICustomLobbyLaunchModel
function SetupSingleton()
    Instance = LaunchModel()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- Returns the launch-model singleton, creating (and registering) it on first access.
---@return UICustomLobbyLaunchModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyLaunchModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Write helpers
--
-- The synced tables are LazyVar values, so a write must build a NEW table/value and
-- `:Set` it — mutating in place never marks dependents dirty (see /lua/ui/CLAUDE.md
-- § 2). These helpers keep that discipline in one place.

--- Places (or replaces) a player at a slot.
---@param model UICustomLobbyLaunchModel
---@param slot number
---@param player UICustomLobbyPlayer
function SetPlayer(model, slot, player)
    model.Players[slot]:Set(player)
end

--- Empties a slot.
---@param model UICustomLobbyLaunchModel
---@param slot number
function ClearPlayer(model, slot)
    model.Players[slot]:Set(false)
end

--- Sets a single field on the player in a slot (copy-then-Set on that slot only).
---@param model UICustomLobbyLaunchModel
---@param slot number
---@param key string
---@param value any
function SetPlayerField(model, slot, key, value)
    local current = model.Players[slot]()
    if not current then
        return
    end
    local player = table.copy(current)
    player[key] = value
    model.Players[slot]:Set(player)
end

--- Merges several fields onto the player in a slot in one copy-then-Set (one re-render, not N).
--- Use when a change touches more than one field at once (e.g. the faction multi-select updates
--- both `Factions` and the representative `Faction`).
---@param model UICustomLobbyLaunchModel
---@param slot number
---@param fields table<string, any>
function SetPlayerFields(model, slot, fields)
    local current = model.Players[slot]()
    if not current then
        return
    end
    local player = table.copy(current)
    for key, value in fields do
        player[key] = value
    end
    model.Players[slot]:Set(player)
end

--- The single representative faction for a multi-select: the chosen one when exactly one faction is
--- picked, else the Random sentinel (`RealFactionCount + 1`). Keeps `player.Faction` coherent for the
--- readers that want one value (skin, the launch fallback) while `player.Factions` stays the source of
--- truth for the choice. An empty / nil set reads as full random.
---@param factions number[] | nil
---@return number
function RepresentativeFaction(factions)
    if factions and table.getn(factions) == 1 then
        return factions[1]
    end
    return RealFactionCount + 1
end

--- Normalises a faction multi-select: a sorted list of the in-range real-faction indices, de-duped.
--- An empty / nil / all-invalid set falls back to "all factions" (full random), so a player always
--- has at least one allowed faction.
---@param factions number[] | nil
---@return number[]
function NormalizeFactions(factions)
    local seen, out = {}, {}
    if factions then
        for _, index in factions do
            if type(index) == 'number' and index >= 1 and index <= RealFactionCount and not seen[index] then
                seen[index] = true
                table.insert(out, index)
            end
        end
    end
    if table.empty(out) then
        for index = 1, RealFactionCount do
            table.insert(out, index)
        end
        return out
    end
    table.sort(out)
    return out
end

--- Sets a single game option (copy-then-Set).
---@param model UICustomLobbyLaunchModel
---@param key string
---@param value any
function SetGameOption(model, key, value)
    local options = table.copy(model.GameOptions())
    options[key] = value
    model.GameOptions:Set(options)
end

--- Replaces the whole game-options value table (copy-then-Set).
---@param model UICustomLobbyLaunchModel
---@param options table
function SetGameOptions(model, options)
    model.GameOptions:Set(table.copy(options))
end

--- Sets the scenario file.
---@param model UICustomLobbyLaunchModel
---@param scenarioFile FileName | false
function SetScenario(model, scenarioFile)
    model.ScenarioFile:Set(scenarioFile)
end

--- Sets the active sim mods (a uid set). UI mods are per-peer and never live here — only sim
--- mods become part of the launch (and must agree across players).
---@param model UICustomLobbyLaunchModel
---@param gameMods table<string, true>
function SetGameMods(model, gameMods)
    model.GameMods:Set(table.copy(gameMods))
end

--- Sets the unit-restriction preset keys (a list of strings). Folded into the launch config's
--- `GameOptions.RestrictedCategories` at launch (the sim expands the keys — see simInit.lua).
---@param model UICustomLobbyLaunchModel
---@param keys string[]
function SetRestrictions(model, keys)
    model.Restrictions:Set(table.copy(keys))
end

--- Appends a player to the observer list (copy-then-Set).
---@param model UICustomLobbyLaunchModel
---@param player UICustomLobbyPlayer
function AddObserver(model, player)
    local observers = table.copy(model.Observers())
    table.insert(observers, player)
    model.Observers:Set(observers)
end

--- Removes the observer owned by `ownerId` (copy-then-Set) and returns it, or nil.
---@param model UICustomLobbyLaunchModel
---@param ownerId UILobbyPeerId
---@return UICustomLobbyPlayer | nil
function RemoveObserver(model, ownerId)
    local observers = model.Observers()
    local kept, removed = {}, nil
    for i = 1, table.getn(observers) do
        if observers[i].OwnerID == ownerId then
            removed = observers[i]
        else
            table.insert(kept, observers[i])
        end
    end
    if removed then
        model.Observers:Set(kept)
    end
    return removed
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the current values across.
---
--- NOTE: maintained by hand — add a field to the model, add a copy line here too, or
--- its value is lost on every hot-reload.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        local handle = newModule.SetupSingleton()
        for slot = 1, MaxSlots do
            handle.Players[slot]:Set(Instance.Players[slot]())
        end
        handle.Observers:Set(Instance.Observers())
        handle.SpawnMex:Set(Instance.SpawnMex())
        handle.AutoTeams:Set(Instance.AutoTeams())
        handle.GameOptions:Set(Instance.GameOptions())
        handle.GameMods:Set(Instance.GameMods())
        handle.Restrictions:Set(Instance.Restrictions())
        handle.ScenarioFile:Set(Instance.ScenarioFile())
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
