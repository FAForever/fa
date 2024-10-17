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

---@class UIAutolobbyMessageHandler
---@field Accept fun(lobby: UIAutolobbyCommunications, data: UILobbyReceivedMessage): boolean   # Responsible for filtering out non-sense
---@field Handler fun(lobby: UIAutolobbyCommunications, data: UILobbyReceivedMessage)           # Responsible for handling the message

---@param lobby UIAutolobbyCommunications
---@param data UILobbyReceivedMessage
local function IsFromHost(lobby, data)
    return data.SenderID == lobby.HostID
end

---@param lobby UIAutolobbyCommunications
---@param data UILobbyReceivedMessage
local function IsHost(lobby, data)
    return lobby:IsHost()
end

--- Represents all valid message types that can be sent between peers.
---@type table<string, UIAutolobbyMessageHandler>
AutolobbyMessageHandlers = {
    IsAlive = {
        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        ---@return boolean
        Accept = function(lobby, data)
            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        Handler = function(lobby, data)
            lobby:DebugSpew("IsAlive handler")

            -- TODO: process the alive tick
        end
    },

    AddPlayer = {
        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        ---@return boolean
        Accept = function(lobby, data)
            if not IsHost(lobby, data) then
                lobby:DebugWarn("Received message for the host peer of type ", data.Type)
                return false
            end

            -- verify integrity of the message
            ---@type UIAutolobbyPlayer
            local playerOptions = data.PlayerOptions
            if not playerOptions then
                lobby:DebugWarn("Received malformed message of type ", data.Type)
                return false
            end

            -- verify that the player is not already in the lobby
            for _, otherPlayerOptions in lobby.PlayerOptions do
                if otherPlayerOptions.OwnerID == data.SenderID then
                    lobby:DebugWarn("Received duplicate message of type ", data.Type)
                    return false
                end
            end

            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        Handler = function(lobby, data)

            ---@type UIAutolobbyPlayer
            local playerOptions = data.PlayerOptions

            -- override some data
            playerOptions.OwnerID = data.SenderID
            playerOptions.PlayerName = lobby:MakeValidPlayerName(playerOptions.OwnerID, playerOptions.PlayerName)

            -- TODO: verify that the StartSpot is not occupied
            -- put the player where it belongs
            lobby.PlayerOptions[playerOptions.StartSpot] = playerOptions

            -- sync game options with the connected peer
            lobby:SendData(data.SenderID, { Type = "UpdateGameOptions", GameOptions = lobby.GameOptions })

            -- sync player options to all connected peers
            lobby:BroadcastData({ Type = "UpdatePlayerOptions", GameOptions = lobby.PlayerOptions })
        end
    },

    UpdatePlayerOptions = {
        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        ---@return boolean
        Accept = function(lobby, data)
            if not IsFromHost(lobby, data) then
                lobby:DebugWarn("Received message from non-host peer of type ", data.Type)
                return false
            end

            -- TODO: verify integrity of the message

            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        Handler = function(lobby, data)
            lobby.PlayerOptions = data.PlayerOptions

            -- update UI for player options
            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdatePlayerOptions(lobby.PlayerOptions)
        end
    },

    UpdateGameOptions = {
        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        ---@return boolean
        Accept = function(lobby, data)
            if not IsFromHost(lobby, data) then
                lobby:DebugWarn("Received message from non-host peer of type ", data.Type)
                return false
            end

            -- TODO: verify integrity of the message

            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        Handler = function(lobby, data)
            lobby.GameOptions = data.GameOptions

            PrefetchSession(lobby.GameOptions.ScenarioFile, {}, true)

            -- update UI for game options
            import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
                :UpdateGameOptions(lobby.GameOptions)
        end
    },

    Launch = {
        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        ---@return boolean
        Accept = function(lobby, data)
            if not IsFromHost(lobby, data) then
                lobby:DebugWarn("Received message from non-host peer of type ", data.Type)
                return false
            end

            -- TODO: verify integrity of the message

            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UILobbyReceivedMessage
        Handler = function(lobby, data)
            lobby:LaunchGame(data.GameConfig)
        end
    }
}
