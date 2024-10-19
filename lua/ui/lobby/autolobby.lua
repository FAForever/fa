--*****************************************************************************
--* FAF notes:
--* Automatch games are configured by the lobby server by sending parameters
--* to the FAF client which then relays that configuration to autolobby.lua
--* through command line arguments.
--*****************************************************************************

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

-- This module exists because the engine expects this particular file to exist with
-- the provided functionality. It now acts as a wrapper for the autolobby controller
-- that can be found at: lua\ui\lobby\autolobby\AutolobbyController.lua

---@type UIAutolobbyCommunications | false
local AutolobbyCommunicationsInstance = false

--- Creates the lobby communications, called (indirectly) by the engine to setup the module state.
---@param protocol any
---@param localPort any
---@param desiredPlayerName any
---@param localPlayerUID any
---@param natTraversalProvider any
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    LOG("CreateLobby", protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    local maxConnections = 16
    AutolobbyCommunicationsInstance = InternalCreateLobby(
        import("/lua/ui/lobby/autolobby/AutolobbyController.lua").AutolobbyCommunications,
        protocol, localPort, maxConnections, desiredPlayerName,
        localPlayerUID, natTraversalProvider
    )

    GpgNetSendGameState('Idle')

    -- create the singleton for the interface
    local interface = import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
    AutolobbyCommunicationsInstance.Trash:Add(interface)
end

--- Instantiates a lobby instance by hosting one.
---
--- Assumes that the lobby communications is initialized by calling `CreateLobby`.
---@param gameName any
---@param scenarioFileName any
---@param singlePlayer any
function HostGame(gameName, scenarioFileName, singlePlayer)
    LOG("HostGame", gameName, scenarioFileName, singlePlayer)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance.GameOptions.ScenarioFile = string.gsub(scenarioFileName,
            ".v%d%d%d%d_scenario.lua",
            "_scenario.lua")
        AutolobbyCommunicationsInstance:HostGame()
    end

    -- -- start with a loading dialog
    -- import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
    --     :CreateLoadingDialog()
end

--- Joins an instantiated lobby instance.
---
--- Assumes that the lobby communications is initialized by calling `CreateLobby`.
---@param address GPGNetAddress
---@param asObserver boolean
---@param playerName string
---@param uid UILobbyPeerId
function JoinGame(address, asObserver, playerName, uid)
    LOG("JoinGame", address, asObserver, playerName, uid)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:JoinGame(address, playerName, uid)
    end

    -- ForkThread(
    --     function()

    --         local seconds = tonumber(GetCommandLineArg("/startspot", 1)[1]) or 1
    --         WaitSeconds(seconds)
    --         if AutolobbyCommunicationsInstance then
    --             AutolobbyCommunicationsInstance:JoinGame(address, playerName, uid)

    --             if seconds == 2 then
    --             WaitSeconds(seconds)
    --             DisconnectFromPeer(AutolobbyCommunicationsInstance:GetPeers()[2].id, false)
    --             end
    --         end


    --     end
    -- )

    -- -- start with a loading dialog
    -- import("/lua/ui/lobby/autolobby/AutolobbyInterface.lua").GetSingleton()
    --     :CreateLoadingDialog()
end

--- Called by the engine.
---@param addressAndPort GPGNetAddress
---@param name any
---@param uid UILobbyPeerId
function ConnectToPeer(addressAndPort, name, uid)
    LOG("ConnectToPeer", addressAndPort, name, uid)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:ConnectToPeer(addressAndPort, name, uid)
    end
end

--- Called by the engine.
---@param uid UILobbyPeerId
---@param doNotUpdateView any
function DisconnectFromPeer(uid, doNotUpdateView)
    LOG("DisconnectFromPeer", uid, doNotUpdateView)

    -- inform the server of the event
    GpgNetSendDisconnected(uid)

    if AutolobbyCommunicationsInstance then
        AutolobbyCommunicationsInstance:DisconnectFromPeer(uid)
    end
end
