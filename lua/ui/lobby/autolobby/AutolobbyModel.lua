--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

-- Reactive state singleton for the automated lobby. This is the single source
-- of truth that the controller (`AutolobbyController.lua`) writes to and the
-- view (`AutolobbyInterface.lua`) observes via `Derive`. It holds no UI
-- references and no networking; it can be constructed with neither present.
--
-- See `/lua/ui/game/chat/ChatModel.lua` for the pattern this mirrors, and
-- `/lua/ui/CLAUDE.md` for the reactivity rules (notably: never mutate a held
-- table in place — build a new table and `:Set` it).

local Create = import("/lua/lazyvar.lua").Create

-------------------------------------------------------------------------------
--#region Pure derivation helpers
--
-- These were methods on the controller class; they are stateless (they operate
-- only on their arguments), so they live here as free functions. They are used
-- both by the derived LazyVars below and by the controller's networking threads.

--- Maps a peer id to an index that can be used in the interface. In practice
--- the peer id can be all over the place, ranging from -1 to numbers such as
--- 35240. With this function we map it to a sane index.
---@param playerOptions UIAutolobbyPlayer[]
---@param peerId UILobbyPeerId
---@return number | false
function PeerIdToIndex(playerOptions, peerId)
    if type(peerId) ~= 'string' then
        WARN("Autolobby model: invalid peer id ", tostring(peerId))
        return false
    end

    if playerOptions then
        for k, options in playerOptions do
            if options.OwnerID == peerId then
                if options.StartSpot then
                    return options.StartSpot
                end
            end
        end
    end

    return false
end

---@param playerOptions UIAutolobbyPlayer[]
---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
---@param playerCount number
---@return UIAutolobbyConnections
function CreateConnectionsMatrix(playerOptions, connectionMatrix, playerCount)
    ---@type UIAutolobbyConnections
    local connections = {}

    -- initial setup
    for y = 1, playerCount do
        connections[y] = {}
        for x = 1, playerCount do
            connections[y][x] = false
        end
    end

    -- populate the matrix
    for peerId, establishedPeers in connectionMatrix do
        for _, peerConnectedToId in establishedPeers do
            local peerIdNumber = PeerIdToIndex(playerOptions, peerId)
            local peerConnectedToIdNumber = PeerIdToIndex(playerOptions, peerConnectedToId)

            -- connection works both ways
            if peerIdNumber and peerConnectedToIdNumber then
                if peerIdNumber > playerCount or peerConnectedToIdNumber > playerCount then
                    WARN("Autolobby model: invalid peer id ", peerIdNumber, peerConnectedToIdNumber)
                else
                    connections[peerIdNumber][peerConnectedToIdNumber] = true
                    connections[peerConnectedToIdNumber][peerIdNumber] = true
                end
            end
        end
    end

    return connections
end

---@param playerOptions UIAutolobbyPlayer[]
---@param statuses table<UILobbyPeerId, UIPeerLaunchStatus>
---@return UIAutolobbyStatus
function CreateConnectionStatuses(playerOptions, statuses)
    local output = {}
    for peerId, launchStatus in statuses do
        local peerIdNumber = PeerIdToIndex(playerOptions, peerId)
        if peerIdNumber then
            output[peerIdNumber] = launchStatus
        end
    end

    return output
end

---@param playerCount number
---@param localIndex number
---@return boolean[][]
function CreateOwnershipMatrix(playerCount, localIndex)
    local output = {}
    for y = 1, playerCount do
        output[y] = {}
        for x = 1, playerCount do
            output[y][x] = false
        end
    end

    for k = 1, playerCount do
        output[localIndex][k] = true
        output[k][localIndex] = true
    end
    return output
end

--- Determines the launch status of the local peer.
---@param connectionMatrix table<UILobbyPeerId, UILobbyPeerId[]>
---@param playerCount number
---@return UIPeerLaunchStatus
function CreateLaunchStatus(connectionMatrix, playerCount)
    -- check number of peers
    local validPeerCount = playerCount - 1
    if table.getsize(connectionMatrix) < validPeerCount then
        return 'Missing local peers'
    end

    return 'Ready'
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, number>
function CreateRatingsTable(playerOptions)
    ---@type table<string, number>
    local allRatings = {}

    for slot, options in pairs(playerOptions) do
        if options.Human and options.PL then
            allRatings[options.PlayerName] = options.PL
        end
    end

    return allRatings
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, string>
function CreateDivisionsTable(playerOptions)
    ---@type table<string, string>
    local allDivisions = {}

    for slot, options in pairs(playerOptions) do
        if options.Human and options.PL then
            if options.DIV ~= "unlisted" then
                local division = options.DIV
                if options.SUBDIV and options.SUBDIV ~= "" then
                    division = division .. ' ' .. options.SUBDIV
                end
                allDivisions[options.PlayerName] = division
            end
        end
    end

    return allDivisions
end

---@param playerOptions UIAutolobbyPlayer[]
---@return table<string, string>
function CreateClanTagsTable(playerOptions)
    local allClanTags = {}

    for slot, options in pairs(playerOptions) do
        if options.PlayerClan then
            allClanTags[options.PlayerName] = options.PlayerClan
        end
    end

    return allClanTags
end

--- Verifies whether we can launch the game.
---@param peerStatus UIAutolobbyStatus
---@param playerCount number
---@return boolean
function CanLaunch(peerStatus, playerCount)
    -- check if we know of all peers
    if table.getsize(peerStatus) ~= playerCount then
        return false
    end

    -- check if all peers are ready for launch
    for k, launchStatus in peerStatus do
        if launchStatus ~= 'Ready' then
            return false
        end
    end

    return true
end

--#endregion

-------------------------------------------------------------------------------
--#region Reactive model

--- Lightweight "we just heard from this peer" pulse. A fresh table is set on
--- every receive so the held value's identity always changes, which fires the
--- view observer even for repeated pulses from the same peer index.
---@class UIAutolobbyAliveStamp
---@field Index number
---@field Time number

--- Reactive autolobby-state singleton: the single source of truth shared by
--- the controller (writer) and the interface (reader).
---@class UIAutolobbyModel
---@field PlayerCount      LazyVar<number>                                            # originates from the command line; sizes the grid and every derivation
---@field LocalPeerId      LazyVar<UILobbyPeerId>                                      # local peer id; feeds the Ownership derivation
---@field PlayerOptions    LazyVar<UIAutolobbyPlayer[]>                                # synced player slots
---@field GameOptions      LazyVar<UILobbyLaunchGameOptionsConfiguration>             # synced game options (carries ScenarioFile)
---@field GameMods         LazyVar<UILobbyLaunchGameModsConfiguration[]>              # synced game mods
---@field ConnectionMatrix LazyVar<table<UILobbyPeerId, UILobbyPeerId[]>>             # raw established-peers map
---@field LaunchStatutes   LazyVar<table<UILobbyPeerId, UIPeerLaunchStatus>>          # raw per-peer launch status
---@field IsAliveStamp     LazyVar<UIAutolobbyAliveStamp | false>                     # alive pulse (see UIAutolobbyAliveStamp)
---@field Connections      LazyVar<UIAutolobbyConnections>                            # derived from PlayerOptions + ConnectionMatrix + PlayerCount
---@field Statuses         LazyVar<UIAutolobbyStatus>                                 # derived from PlayerOptions + LaunchStatutes
---@field Ownership        LazyVar<boolean[][] | false>                               # derived from PlayerCount + PeerIdToIndex(PlayerOptions, LocalPeerId)

--- Singleton handle; nil until `SetupSingleton` (or `GetSingleton`) builds the model.
---@type UIAutolobbyModel | nil
local ModelInstance = nil

--- Allocates a fresh model singleton, replacing any existing instance. Rejoin
--- relies on this resetting the state: a new lobby must not inherit stale
--- connection / launch state from the previous one.
---@param playerCount? number
---@return UIAutolobbyModel
function SetupSingleton(playerCount)
    playerCount = playerCount or 8

    ---@type UIAutolobbyModel
    local model = {
        PlayerCount      = Create(playerCount),
        LocalPeerId      = Create("-2"),
        PlayerOptions    = Create({}),
        GameOptions      = Create({}),
        GameMods         = Create({}),
        ConnectionMatrix = Create({}),
        LaunchStatutes   = Create({}),
        IsAliveStamp     = Create(false),
        Connections      = Create(),
        Statuses         = Create(),
        Ownership        = Create(),
    }

    -- Derived values. Reading the raw LazyVars inside these compute functions
    -- registers the dependency edges, so any `:Set` on a raw var re-fires the
    -- view observers subscribed to these derived vars.
    model.Connections:Set(function()
        return CreateConnectionsMatrix(model.PlayerOptions(), model.ConnectionMatrix(), model.PlayerCount())
    end)

    model.Statuses:Set(function()
        return CreateConnectionStatuses(model.PlayerOptions(), model.LaunchStatutes())
    end)

    model.Ownership:Set(function()
        local localIndex = PeerIdToIndex(model.PlayerOptions(), model.LocalPeerId())
        if not localIndex then
            return false
        end
        return CreateOwnershipMatrix(model.PlayerCount(), localIndex)
    end)

    ModelInstance = model
    return model
end

--- Returns the model singleton, creating it on first access.
---@return UIAutolobbyModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UIAutolobbyModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton on the new module and copies the
--- current raw LazyVar values across so observers don't see a state reset. The
--- derived vars (Connections / Statuses / Ownership) are rebuilt with their
--- compute functions by `SetupSingleton` and must not be copied. `IsAliveStamp`
--- is a transient pulse and is intentionally not carried over.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton(ModelInstance.PlayerCount())
        handle.LocalPeerId:Set(ModelInstance.LocalPeerId())
        handle.PlayerOptions:Set(ModelInstance.PlayerOptions())
        handle.GameOptions:Set(ModelInstance.GameOptions())
        handle.GameMods:Set(ModelInstance.GameMods())
        handle.ConnectionMatrix:Set(ModelInstance.ConnectionMatrix())
        handle.LaunchStatutes:Set(ModelInstance.LaunchStatutes())
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
