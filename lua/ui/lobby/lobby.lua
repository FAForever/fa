
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Window = import("/lua/maui/window.lua").Window
local GameMain = import("/lua/ui/game/gamemain.lua")
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Combo = import("/lua/ui/controls/combo.lua").Combo
local ItemList = import("/lua/maui/itemlist.lua").ItemList



---@class UILobby
Lobby = Class(Group) {

    LobbyCommunications = nil,
    LobbyCommStrings = nil, 

    ConnectedTo = {},
    ConnectedToStatus = {},

    CreateLobbyCommunications = function(self, port, localPlayerName, localPlayerUID)
        self.LobbyCommunications = InternalCreateLobby (
            UILobbyCommunication,
            "UDP",
            port,
            8,
            localPlayerName,
            localPlayerUID,
            nil
        )
    end,

}

-- Create a new unconnected lobby.
---@param protocol 'UDP' | 'TCP' | 'None'
---@param localPort number
---@param desiredPlayerName string
---@param localPlayerUID string
---@param natTraversalProvider any
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    LOG("CreateLobby")
end

-- create the lobby as a host
---@param desiredGameName string
---@param scenarioFileName string
---@param inSinglePlayer boolean
function HostGame(desiredGameName, scenarioFileName, inSinglePlayer)
    LOG("HostGame")
end

---@param address string
---@param asObserver boolean
---@param playerName string
---@param uid string
function JoinGame(address, asObserver, playerName, playerUID)
    LOG("JoinGame")
end

function ConnectToPeer(addressAndPort,name,uid)
    LOG("ConnectToPeer")

    if not string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
    else
        DisconnectFromPeer(uid)
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
        table.insert(ConnectedWithProxy, uid)
    end
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    LOG("DisconnectFromPeer")
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if wasConnected(uid) then
        table.remove(connectedTo, uid)
    end
    GpgNetSend('Disconnected', string.format("%d", uid))
    lobbyComm:DisconnectFromPeer(uid)
end