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
---@field Team number               # Read by Lua code to determine teams
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
---@see moho.lobby_methods.DataReceived # Receives the data on the other peers
---@param data UILobbyData
function CLobby:BroadcastData(data)
end

--- Connect to a new peer. The peer will now show up in `GetPeer` and `GetPeers`
---@see moho.lobby_methods.SystemMessage # Receives `Engine0005` when connecting
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
---@see moho.lobby_methods.PeerDisconnected # Called on the local client
---@param peerId UILobbyPeerId
function CLobby:DisconnectFromPeer(peerId)
end

--- Eject a peer from the lobby. The peer will no longer show in `GetPeer` and `GetPeers`.
---@see moho.lobby_methods.Ejected # Receives `reason` on the ejected peer
---@see moho.lobby_methods.PeerDisconnected # Called on the local client
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
---@see moho.lobby_methods.Hosting # Called when hosting starts
---@see moho.lobby_methods.GameConfigRequested # Called for each discovery request
function CLobby:HostGame()
end

--- Retrieves the flag indicating if the local client is the host
---@return boolean
function CLobby:IsHost()
end

--- Joins a lobby hosted by another peer. See `HostGame` to host a game.
---
--- Is not idempotent - joining twice will generate an error.
---@see moho.lobby_methods.ConnectionToHostEstablished # Called when the host accepts the local client
---@see moho.lobby_methods.ConnectionFailed # Called when the connection to the host fails
---@see moho.lobby_methods.SystemMessage # Receives `Engine0001` when connecting, `Engine0004` when connected
---@param address GPGNetAddress
---@param remotePlayerName? string | nil
---@param remotePlayerPeerId? UILobbyPeerId
function CLobby:JoinGame(address, remotePlayerName, remotePlayerPeerId)
end

---
---@see moho.lobby_methods.GameLaunched # Called when the launch succeeds
---@see moho.lobby_methods.LaunchFailed # Called when the launch fails
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
---@see moho.lobby_methods.DataReceived # Receives the data on the other peer
---@param peerId UILobbyPeerId
---@param data UILobbyData
function CLobby:SendData(peerId, data)
end

--- Called by the engine when the connection to the host fails or the host leaves
---@see moho.lobby_methods.JoinGame # Connects to the host
---@type nil | fun(self: moho.lobby_methods, reason: "HostLeft")
CLobby.ConnectionFailed = nil

--- Called by the engine when the connection to the host is established, with the local peer id,
--- the local player name the host assigned, and the host peer id
---@see moho.lobby_methods.JoinGame # Connects to the host
---@type nil | fun(self: moho.lobby_methods, localPeerId: UILobbyPeerId, newLocalName: string, hostPeerId: UILobbyPeerId)
CLobby.ConnectionToHostEstablished = nil

--- Called by the engine when data from another peer arrives. The engine sets `SenderID` and
--- `SenderName`; the rest is whatever the sender passed to `SendData` or `BroadcastData`
---@see moho.lobby_methods.SendData # Sends data to one peer
---@see moho.lobby_methods.BroadcastData # Sends data to all peers
---@type nil | fun(self: moho.lobby_methods, data: UILobbyReceivedMessage)
CLobby.DataReceived = nil

--- Called by the engine when the local player is ejected from the lobby, with the reason:
--- `"LobbyFull"` when the host has no room, `"KickedByHost"` when the host removes the local
--- player from its peer list, or the `reason` the host passed to `EjectPeer`
---@see moho.lobby_methods.EjectPeer # Ejects a peer, on the host
---@type nil | fun(self: moho.lobby_methods, reason: "KickedByHost" | "LobbyFull" | string)
CLobby.Ejected = nil

--- Called by the engine when a peer reports the peers it is connected to
---@type nil | fun(self: moho.lobby_methods, peerId: UILobbyPeerId, peerConnectedTo: UILobbyPeerId[])
CLobby.EstablishedPeers = nil

--- Called by the engine on the host when a discovery request arrives. The engine sends the
--- returned table to the requester, which receives it in `GameFound` or `GameUpdated`
---@see moho.discovery_service_methods.GameFound # Receives a new lobby
---@see moho.discovery_service_methods.GameUpdated # Receives a known lobby
---@type nil | fun(self: moho.lobby_methods): UILobbydDiscoveryInfo?
CLobby.GameConfigRequested = nil

--- Called by the engine when `LaunchGame` succeeds
---@see moho.lobby_methods.LaunchGame # Launches the game
---@type nil | fun(self: moho.lobby_methods)
CLobby.GameLaunched = nil

--- Called by the engine when the lobby starts hosting
---@see moho.lobby_methods.HostGame # Starts hosting
---@type nil | fun(self: moho.lobby_methods)
CLobby.Hosting = nil

--- Called by the engine when `LaunchGame` fails, with the reason key `"NoConfig"` or
--- `"StartSpots"`, or an empty string when the scenario can't be loaded
---@see moho.lobby_methods.LaunchGame # Launches the game
---@type nil | fun(self: moho.lobby_methods, reasonKey: "NoConfig" | "StartSpots" | "")
CLobby.LaunchFailed = nil

--- Called by the engine when a peer is removed from the lobby: when the connection to it is lost
--- and not retried, or when the local client calls `DisconnectFromPeer` or `EjectPeer`
---@see moho.lobby_methods.DisconnectFromPeer # Disconnects from a peer
---@see moho.lobby_methods.EjectPeer # Ejects a peer
---@type nil | fun(self: moho.lobby_methods, peerName: string, peerId: UILobbyPeerId)
CLobby.PeerDisconnected = nil

--- Called by the engine with a localized status message about a connection, with `%s` replaced by
--- the peer name. The messages, by key in `loc/US/strings_db.lua`:
---
--- | Key | Message | Sent when |
--- | --- | ------- | --------- |
--- | `Engine0001` | `Connecting to game host...` | `JoinGame` starts connecting to the host |
--- | `Engine0002` | `%s disconnected.` | The connection to a peer is lost and the peer is ejected |
--- | `Engine0003` | `Lost connection to %s.` | The connection to a peer is lost and the engine waits for it to reconnect |
--- | `Engine0004` | `Connection to %s established.` | A peer joins the host, or the host accepts the local client |
--- | `Engine0005` | `Connecting to %s...` | `ConnectToPeer` starts connecting to a peer |
---@see moho.lobby_methods.JoinGame # Sends `Engine0001`
---@see moho.lobby_methods.ConnectToPeer # Sends `Engine0005`
---@type nil | fun(self: moho.lobby_methods, text: string)
CLobby.SystemMessage = nil

return CLobby
