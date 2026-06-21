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

---@type UIAutolobbyInstance | false
local LobbyInstance = false

--- Creates the lobby communications, called (indirectly) by the engine to setup the module state.
---@param protocol UILobbyProtocol
---@param localPort number
---@param desiredPlayerName string
---@param localPlayerUID UILobbyPeerId
---@param natTraversalProvider any
---@return UIAutolobbyInstance
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    -- we intentionally do not log the 'natTraversalProvider' parameter as it can cause issues due to being an uninitialized C object
    LOG("CreateLobby", protocol, localPort, desiredPlayerName, localPlayerUID)

    -- create the model and interface, needs to be done before the lobby is.
    -- the model is set up first so the interface subscribes against it, and so
    -- a rejoin (which re-runs CreateLobby) starts from fresh, non-stale state.
    local playerCount = tonumber(GetCommandLineArg("/players", 1)[1]) or 8
    import("/lua/ui/lobby/autolobby/autolobbymodel.lua").SetupSingleton(playerCount)
    local interface = import("/lua/ui/lobby/autolobby/autolobbyinterface.lua").SetupSingleton(playerCount)

    -- create the lobby
    local maxConnections = 16
    LobbyInstance = InternalCreateLobby(
        import("/lua/ui/lobby/autolobby/autolobbyinstance.lua").AutolobbyInstance,
        protocol, localPort, maxConnections, desiredPlayerName,
        localPlayerUID, natTraversalProvider
    )

    LobbyInstance.LobbyParameters = LobbyInstance.LobbyParameters or {}
    LobbyInstance.LobbyParameters.Protocol = protocol
    LobbyInstance.LobbyParameters.LocalPort = localPort
    LobbyInstance.LobbyParameters.MaxConnections = maxConnections
    LobbyInstance.LobbyParameters.DesiredPlayerName = desiredPlayerName
    LobbyInstance.LobbyParameters.LocalPlayerPeerId = localPlayerUID
    LobbyInstance.LobbyParameters.NatTraversalProvider = natTraversalProvider

    return LobbyInstance
end

--- Instantiates a lobby instance by hosting one.
---
--- Assumes that the lobby communications is initialized by calling `CreateLobby`.
---@param gameName any
---@param scenarioFileName any
---@param singlePlayer any
function HostGame(gameName, scenarioFileName, singlePlayer)
    LOG("HostGame", gameName, scenarioFileName, singlePlayer)

    if LobbyInstance then

        LobbyInstance.HostParameters = LobbyInstance.HostParameters or {}
        LobbyInstance.HostParameters.GameName = gameName
        LobbyInstance.HostParameters.ScenarioFile = scenarioFileName
        LobbyInstance.HostParameters.SinglePlayer = singlePlayer

        -- the synced game options live on the model; the scenario observer
        -- reacts and the host sees the map preview
        local AutolobbyModel = import("/lua/ui/lobby/autolobby/autolobbymodel.lua")
        local scenarioFile = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua") --[[@as FileName]]
        AutolobbyModel.SetScenarioFile(AutolobbyModel.GetSingleton(), scenarioFile)
        LobbyInstance:HostGame()
    end
end

local rejoinTest = false

--- Joins an instantiated lobby instance.
---
--- Assumes that the lobby communications is initialized by calling `CreateLobby`.
---@param address GPGNetAddress
---@param asObserver boolean
---@param playerName string
---@param uid UILobbyPeerId
function JoinGame(address, asObserver, playerName, uid)
    LOG("JoinGame", address, asObserver, playerName, uid)

    if LobbyInstance then
        LobbyInstance.JoinParameters = LobbyInstance.JoinParameters or {}
        LobbyInstance.JoinParameters.Address = address
        LobbyInstance.JoinParameters.AsObserver = asObserver
        LobbyInstance.JoinParameters.DesiredPlayerName = playerName
        LobbyInstance.JoinParameters.DesiredPeerId = uid
        LobbyInstance:JoinGame(address, playerName, uid)
    end
end

--- Called by the engine.
---@param addressAndPort GPGNetAddress
---@param name any
---@param uid UILobbyPeerId
function ConnectToPeer(addressAndPort, name, uid)
    LOG("ConnectToPeer", addressAndPort, name, uid)

    if LobbyInstance then
        LobbyInstance:ConnectToPeer(addressAndPort, name, uid)
    end
end

--- Called by the engine.
---@param uid UILobbyPeerId
---@param doNotUpdateView any
function DisconnectFromPeer(uid, doNotUpdateView)
    LOG("DisconnectFromPeer", uid, doNotUpdateView)

    if LobbyInstance then
        LobbyInstance:DisconnectFromPeer(uid)
    end
end
