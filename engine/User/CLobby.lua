---@meta



---@class moho.lobby_methods : Destroyable, InternalObject
local CLobby = {}

--- "0", "1", "2", but also "32254" and the like.
---@alias UILobbyPeerId string

---@alias GPGNetAddress string | number

---@alias UILobbyProtocol 'UDP' | 'TCP'

---@alias UIPeerConnectionStatus 'None' | 'Pending' | 'Connecting' | 'Answering' | 'Established' | 'TimedOut' | 'Errored'

---@class Peer
---@field establishedPeers UILobbyPeerId[]
---@field id UILobbyPeerId          # Is -1 when the status is pending
---@field ping number
---@field name string
---@field quiet number
---@field status UIPeerConnectionStatus

--- A piece of data that is one can send with `BroadcastData` or `SendData` to other player(s) in the lobby.
---@class UILobbyReceivedMessage : table
---@field SenderID UILobbyPeerId  # Set by the engine, allows us to identify the source.
---@field SenderName string         # Set by the engine, nickname of the source.
---@field Type string               # Type of message

--- A piece of data that is one can send with `BroadcastData` or `SendData` to other player(s) in the lobby.
---@class UILobbyData : table
---@field Type string               # Type of message

--- All the following fields are read by the engine upon launching the lobby to setup the scenario.
---@class UILobbyLaunchGameOptionsConfiguration
---@field UnitCap any           # Read by the engine to determine the initial unit cap. See also the globals `GetArmyUnitCap`, `GetArmyUnitCostTotal` and `SetArmyUnitCap` to manipulate it throughout the scenario.
---@field CheatsEnabled any     # Read by the engine to determine whether cheats are enabled.
---@field FogOfWar any          # Read by the engine to determine how to manage the fog of war.
---@field NoRushOption any      # Read by the engine to create the anti-rush mechanic.
---@field PrebuiltUnits any     # Read by the engine to create initial, prebuilt units.
---@field ScenarioFile any      # Read by the engine to load the scenario of the game.
---@field Timeouts any          # Read by the engine to determine the behavior of time outs.
---@field CivilianAlliance any  # Read by the engine to determine the alliance towards civilians.
---@field GameSpeed any         # Read by the engine to determine the behavior of game speed (adjustments).
---@field Ratings table<string, number>
---@field Divisions table<string, string>

---@class UILobbyLaunchGameModsConfiguration
---@field name string           # Read by the engine, TODO
---@field uid string            # Read by the engine, TODO

---@class UILobbyLaunchObserverConfiguration
---@field OwnerID UILobbyPeerId   # Read by the engine, TODO
---@field PlayerName string         # Read by the engine, TODO

---@class UILobbyLaunchPlayerConfiguration
---@field StartSpot number          # Read by Lua code to determine start locations
---@field ArmyName string           # Read by the engine, TODO
---@field PlayerName string         # Read by the engine, TODO
---@field Civilian boolean          # Read by the engine, TODO
---@field Human boolean             # Read by the engine, TODO
---@field AIPersonality string      # Read by the engine iff Human is false
---@field ArmyColor number          # Read by the engine, is mapped to a color by reading the values of `lua\GameColors.lua`.
---@field PlayerColor number        # Read by the engine, is mapped to a color by reading the values of `lua\GameColors.lua`
---@field Faction number            # Read by the engine to determine the faction of the player.
---@field OwnerID UILobbyPeerId   # Read by the engine, TODO

--- All the following fields are read by the engine upon launching the lobby.
---@class UILobbyLaunchConfiguration
---@field GameMods UILobbyLaunchGameModsConfiguration[] # ModInfo[]
---@field GameOptions UILobbyLaunchGameOptionsConfiguration #  GameOptions
---@field Observers UILobbyLaunchObserverConfiguration # PlayerData[]
---@field PlayerOptions UILobbyLaunchPlayerConfiguration[] # PlayerData[]

--- Broadcasts information to all peers. See `SendData` for sending to a specific peer.
---@param data UILobbyData
function CLobby:BroadcastData(data)
end

--- Connect to a new peer. The peer will now show up in `GetPeer` and `GetPeers`
---@param address GPGNetAddress # includes the port
---@param name string
---@param peerId UILobbyPeerId
function CLobby:ConnectToPeer(address, name, peerId)
end

---
function CLobby:DebugDump()
end

--- Destroys the lobby, disconnecting all peers and the lobby can no longer be discovered.
function CLobby:Destroy()
end

--- Disconnect from a peer. The peer will no longer show in `GetPeer` and `GetPeers`.
---@param peerId UILobbyPeerId
function CLobby:DisconnectFromPeer(peerId)
end

--- Eject a peer from the lobby. The peer will no longer show in `GetPeer` and `GetPeers`.
---@param peerId UILobbyPeerId
---@param reason string
function CLobby:EjectPeer(peerId, reason)
end

--- Retrieves the local client identifier.
---@return UILobbyPeerId
function CLobby:GetLocalPlayerID()
end

--- Retrieves the local player name
---@return string
function CLobby:GetLocalPlayerName()
end

--- Retrieves the local port
---@return number | nil
function CLobby:GetLocalPort()
end

--- Retrieves a specific peer
---@param peerId UILobbyPeerId
---@return Peer
function CLobby:GetPeer(peerId)
end

--- Retrieves all peers
---@return Peer[]
function CLobby:GetPeers()
end

--- Once hosted the lobby can be found by the discovery service. See `JoinGame` to join a hosted game.
function CLobby:HostGame()
end

--- Retrieves the flag indicating if the local client is the host
---@return boolean
function CLobby:IsHost()
end

--- Joins a lobby hosted by another peer. See `HostGame` to host a game.
---
--- Is not idempotent - joining twice will generate an error.
---@param address GPGNetAddress
---@param remotePlayerName? string | nil
---@param remotePlayerPeerId? UILobbyPeerId
function CLobby:JoinGame(address, remotePlayerName, remotePlayerPeerId)
end

---
---@param gameConfig UILobbyLaunchConfiguration
function CLobby:LaunchGame(gameConfig)
end

--- Creates a unique, alternative game name if that is required
---@param origName string
---@return string
function CLobby:MakeValidGameName(origName)
end

--- Creates a unique, alternative player name if that is required
---@param peerId UILobbyPeerId
---@param origName string
---@return string
function CLobby:MakeValidPlayerName(peerId, origName)
end

--- Sends data to a specific peer. See `BroadcastData` for sending to all peers.
---@param peerId UILobbyPeerId
---@param data UILobbyData
function CLobby:SendData(peerId, data)
end

return CLobby
