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

--- Maximum number of player slots the engine supports.
MaxSlots = 16

-------------------------------------------------------------------------------
--#region Shapes

--- A player (human or AI) occupying a slot. Mirrors the fields the legacy lobby's
--- PlayerData carries; trimmed to what the UI reads.
---@class UICustomLobbyPlayer
---@field PlayerName string
---@field OwnerID UILobbyPeerId
---@field Human boolean
---@field Faction number          # 1=UEF 2=Aeon 3=Cybran 4=Seraphim 5=Random
---@field PlayerColor number
---@field ArmyColor number
---@field Team number             # 1 = no team (FFA), 2..9 = teams 1..8
---@field StartSpot number
---@field Ready boolean
---@field PL? number              # rating
---@field MEAN? number
---@field DEV? number
---@field NG? number              # number of games
---@field PlayerClan? string
---@field Country? string
---@field AIPersonality? string

--#endregion

-------------------------------------------------------------------------------
--#region Reactive model

--- Reactive launch-state singleton (shared, host-dictated, part of the launch).
---@class UICustomLobbyLaunchModel
---@field Players      LazyVar<UICustomLobbyPlayer | false>[]           # one LazyVar per slot (1..MaxSlots); false = empty
---@field Observers    LazyVar<UICustomLobbyPlayer[]>                   # observer list
---@field SpawnMex     LazyVar<table<number, boolean>>                  # adaptive-map spawn-mex flags (embedded into the scenario at launch)
---@field AutoTeams    LazyVar<table<number, number>>
---@field GameOptions  LazyVar<table>
---@field GameMods     LazyVar<table>
---@field ScenarioFile LazyVar<FileName | false>

---@type UICustomLobbyLaunchModel | nil
local ModelInstance = nil

--- Allocates a fresh launch-model singleton, replacing any existing instance.
---@return UICustomLobbyLaunchModel
function SetupSingleton()
    local players = {}
    for slot = 1, MaxSlots do
        players[slot] = Create(false)
    end

    ---@type UICustomLobbyLaunchModel
    local model = {
        Players      = players,
        Observers    = Create({}),
        SpawnMex     = Create({}),
        AutoTeams    = Create({}),
        GameOptions  = Create({}),
        GameMods     = Create({}),
        ScenarioFile = Create(false),
    }

    ModelInstance = model
    return model
end

--- Returns the launch-model singleton, creating it on first access.
---@return UICustomLobbyLaunchModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbyLaunchModel]]
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
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        for slot = 1, MaxSlots do
            handle.Players[slot]:Set(ModelInstance.Players[slot]())
        end
        handle.Observers:Set(ModelInstance.Observers())
        handle.SpawnMex:Set(ModelInstance.SpawnMex())
        handle.AutoTeams:Set(ModelInstance.AutoTeams())
        handle.GameOptions:Set(ModelInstance.GameOptions())
        handle.GameMods:Set(ModelInstance.GameMods())
        handle.ScenarioFile:Set(ModelInstance.ScenarioFile())
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
