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

-- This module represents all valid messages that the autolobby accepts from other
-- peers. Messages can be send with `lobby:SendData` or with `lobby:BroadcastData`.
-- Messages are automatically checked to exist and then verified with the `Accept`
-- function. If the message is accepted the handler is called, which is just a
-- wrapper to another function in the autolobby.

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
AutolobbyMessages = {
    IsAlive = {

        ---@class UIAutolobbyIsAliveMessage : UILobbyReceivedMessage

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyIsAliveMessage
        ---@return boolean
        Accept = function(lobby, data)
            return true
        end,

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyIsAliveMessage
        Handler = function(lobby, data)
            -- do nothing, we're interested in the side effect
        end
    },

    AddPlayer = {

        ---@class UIAutolobbyAddPlayerMessage : UILobbyReceivedMessage
        ---@field PlayerOptions UIAutolobbyPlayer

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyAddPlayerMessage
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
        ---@param data UIAutolobbyAddPlayerMessage
        Handler = function(lobby, data)
            lobby:ProcessAddPlayerMessage(data)
        end
    },

    UpdatePlayerOptions = {

        ---@class UIAutolobbyUpdatePlayerOptionsMessage : UILobbyReceivedMessage
        ---@field PlayerOptions UIAutolobbyPlayer[]

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyUpdatePlayerOptionsMessage
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
        ---@param data UIAutolobbyUpdatePlayerOptionsMessage
        Handler = function(lobby, data)
            lobby:ProcessUpdatePlayerOptionsMessage(data)
        end
    },

    UpdateGameOptions = {

        ---@class UIAutolobbyUpdateGameOptionsMessage : UILobbyReceivedMessage
        ---@field GameOptions UILobbyLaunchGameOptionsConfiguration

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyUpdateGameOptionsMessage
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
        ---@param data UIAutolobbyUpdateGameOptionsMessage
        Handler = function(lobby, data)
            lobby:ProcessUpdateGameOptionsMessage(data)
        end
    },

    Launch = {

        ---@class UIAutolobbyLaunchMessage : UILobbyReceivedMessage
        ---@field GameConfig UILobbyLaunchConfiguration

        ---@param lobby UIAutolobbyCommunications
        ---@param data UIAutolobbyLaunchMessage
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
        ---@param data UIAutolobbyLaunchMessage
        Handler = function(lobby, data)
            lobby:ProcessLaunchMessage(data)
        end
    }
}