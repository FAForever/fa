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

-------------------------------------------------------------------------------
--#region Game <-> Server communications

-- All the following logic is tightly coupled with functionality on either the
-- lobby server, the ice adapter, the java server and/or the client. For more
-- context you can search for the various keywords in the following repositories:
-- - Lobby server: https://github.com/FAForever/server
-- - Java Ice adapter: https://github.com/FAForever/java-ice-adapter
-- - Kotlin Ice adapter: https://github.com/FAForever/kotlin-ice-adapter
--
-- Specifically, the following file processes these messages on the server:
-- - https://github.com/FAForever/server/blob/98271c421412467fa387f3a6530fe8d24e360fa4/server/gameconnection.py

-- upvalue scope for performance
local GpgNetSend = GpgNetSend

--- Interpretation of the lobby status of a single peer.
---@alias UILobbyState
---| 'None'
---| 'Idle'
---| 'Lobby'
---| 'Launching'
---| 'Ended'

--- Interpretation of the lobby launch status of a single peer.
---@alias UIPeerLaunchStatus
--- | 'Unknown'                 # Initial value, is never send.
--- | 'Connecting'              # Send when the local peer is connecting to the lobby
--- | 'Missing local peers'     # Send when the local peer is missing other peers
--- | 'Rejoining'               # Send when the local peer is rejoining
--- | 'Ready'                   # Send when the local peer is ready to launch
--- | 'Ejected'                 # Send when the local peer is ejected
--- | 'Rejected'                # Send when there is a game version missmatch
--- | 'Failed'                  # Send when the game fails to launch

--- A component that represent all the supported lobby <-> server communications.
---@class UIAutolobbyServerCommunicationsComponent
AutolobbyServerCommunicationsComponent = ClassSimple {

    --- Sends a message to the server to update relevant army options of a player.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param key 'Team' | 'Army' | 'StartSpot' | 'Faction'
    ---@param value any
    SendPlayerOptionToServer = function(self, peerId, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            self:DebugWarn("Ignoring server message of type `PlayerOption` since that is only accepted when it originates from the host.")
            return
        end

        GpgNetSend('PlayerOption', peerId, key, value)
    end,

    --- Sends a message to the server to update relevant army options of an AI.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param aiName string
    ---@param key 'Team' | 'Army' | 'StartSpot' | 'Faction'
    ---@param value any
    SendAIOptionToServer = function(self, aiName, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            self:DebugWarn("Ignoring server message of type `AIOption` since that is only accepted when it originates from the host.")
            return
        end

        GpgNetSend('AIOption', aiName, key, value)
    end,

    --- Sends a message to the server to update relevant game options.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param key 'Slots' | any
    ---@param value any
    SendGameOptionToServer = function(self, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            self:DebugWarn("Ignoring server message of type `GameOption` since that is only accepted when it originates from the host.")
            return
        end

        GpgNetSend('GameOption', key, value)
    end,

    --- Sends a message to the server indicating what the status of the lobby as a whole.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param value UILobbyState
    SendGameStateToServer = function(self, value)
        GpgNetSend('GameState', value)
    end,

    --- sends a message to the server about the status of the local peer.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param value UIPeerLaunchStatus
    SendLaunchStatusToServer = function(self, value)
        GpgNetSend('LaunchStatus', value)
    end,

    --- Sends a message to the server that we established a connection to a peer. This message can be send multiple times for the same peer and the server should be idempotent to it.
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    SendEstablishedPeer = function(self, peerId)
        GpgNetSend('EstablishedPeer', peerId)
    end,

    --- Sends a message to the server that we disconnected from a peer. Note that a peer may be trying to rejoin. See also the launch status of the given peer. 
    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    SendDisconnectedPeer = function(self, peerId)
        GpgNetSend('DisconnectedPeer', peerId)
    end,
}
