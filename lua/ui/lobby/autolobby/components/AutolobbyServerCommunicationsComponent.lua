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
-- If we do not send this information then the client is unaware of changes made
-- to the lobby after hosting. These messages are usually only accepted from the
-- host of the lobby.

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
--- | 'Missing local peers'     # Send when the local peer is missing other peers
--- | 'Rejoining'               # Send when the local peer is rejoining
--- | 'Ready'                   # Send when the local peer is ready to start
--- | 'Rejected'                # Send when there is a game version missmatch
--- | 'Failed'                  # Send when the game fails to launch

--- A component that represent all the supported lobby <-> server communications.
---@class UIAutolobbyServerCommunicationsComponent
AutolobbyServerCommunicationsComponent = ClassSimple {

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param key 'Team' | 'Army' | 'StartSpot' | 'Faction'
    ---@param value any
    SendPlayerOptionToServer = function(self, peerId, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            return
        end

        GpgNetSend('PlayerOption', peerId, key, value)
    end,

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param aiName string
    ---@param key 'Team' | 'Army' | 'StartSpot' | 'Faction'
    ---@param value any
    SendAIOptionToServer = function(self, aiName, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            return
        end

        GpgNetSend('AIOption', aiName, key, value)
    end,

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param key 'Slots' | any
    ---@param value any
    SendGameOptionToServer = function(self, key, value)
        -- message is only accepted by the server if it originates from the host
        if not self:IsHost() then
            return
        end

        GpgNetSend('GameOption', key, value)
    end,

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param value UILobbyState
    SendGameStateToServer = function(self, value)
        GpgNetSend('GameState', value)
    end,

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param value UIPeerLaunchStatus
    SendLaunchStatusToServer = function(self, value)
        GpgNetSend('LaunchStatus', value)
    end,

    ---@param self UIAutolobbyServerCommunicationsComponent | UIAutolobbyCommunications
    ---@param peerId UILobbyPeerId
    ---@param peers UILobbyPeerId[]
    SendEstablishedPeers = function(self, peerId, peers)
        local establishedPeers = ""

        local establishedPeersCount = table.getn(peers)
        if establishedPeersCount == 1 then
            establishedPeers = peers[1]
        elseif establishedPeersCount > 1 then
            establishedPeers = peers[1]

            for k = 2, establishedPeersCount do
                establishedPeers = establishedPeers .. " " .. peers[k]
            end
        end

        GpgNetSend('EstablishedPeers', peerId, establishedPeers)
    end,
}
