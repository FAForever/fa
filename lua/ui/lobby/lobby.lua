--*****************************************************************************
--* FAF notes:
--* This file is the engine-facing entry point for the custom-game lobby. The
--* original (organically grown) implementation now lives in `lobby-old.lua`;
--* this thin wrapper drives the reactive-MVC rebuild under `customlobby/`.
--*
--* The engine and the menus call CreateLobby / HostGame / JoinGame /
--* ConnectToPeer / DisconnectFromPeer on this module, exactly as before, so no
--* caller needs to change. See `customlobby/CLAUDE.md` and
--* `TARGET_ARCHITECTURE.md`.
--*****************************************************************************

--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local CustomLobbyModel = import("/lua/ui/lobby/customlobby/customlobbymodel.lua")
local CustomLobbyInterface = import("/lua/ui/lobby/customlobby/customlobbyinterface.lua")

local maxConnections = 16

---@type UICustomLobbyInstance | false
local Instance = false

--- Called by the engine / menus to create a new (unconnected) lobby.
--- Matches the legacy signature so existing callers (uimain, gameselect,
--- gamecreate, onlineprovider) work unchanged.
---@param protocol UILobbyProtocol
---@param localPort number
---@param desiredPlayerName string
---@param localPlayerUID? UILobbyPeerId
---@param natTraversalProvider? userdata
---@param over Control
---@param exitBehavior fun()
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior)
    -- The FAF client pokes GPGNet messages in through here with localPort == -1.
    -- The barebones lobby doesn't handle those yet.
    if localPort == -1 then
        WARN("CustomLobby: GPGNet message path (localPort == -1) is not supported yet")
        return
    end

    -- Hand the front-end's escape handler back so ours can take over.
    MenuCommon.MenuCleanup()

    -- Models first, then the view (so its components subscribe to a live model),
    -- then the lobby object (whose callbacks write the model).
    -- TODO: derive SlotCount from the chosen map instead of a fixed default.
    CustomLobbyModel.SetupSingleton(8)
    CustomLobbyInterface.SetupSingleton()

    Instance = InternalCreateLobby(
        import("/lua/ui/lobby/customlobby/customlobbyinstance.lua").CustomLobbyInstance,
        protocol, localPort, maxConnections, desiredPlayerName, localPlayerUID, natTraversalProvider
    )

    -- Minimal leave handler so the user isn't trapped.
    EscapeHandler.PushEscapeHandler(function()
        EscapeHandler.PopEscapeHandler()
        if Instance then
            Instance:Destroy()
            Instance = false
        end
        CustomLobbyInterface.CloseDebug()
        if exitBehavior then
            exitBehavior()
        end
    end)
end

--- Hosts the lobby created by `CreateLobby`.
---@param desiredGameName string
---@param scenarioFileName FileName
---@param inSinglePlayer boolean
function HostGame(desiredGameName, scenarioFileName, inSinglePlayer)
    if not Instance then
        return
    end
    local scenario = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua") --[[@as FileName]]
    CustomLobbyModel.SetScenario(CustomLobbyModel.GetSingleton(), scenario)
    Instance:HostGame()
end

--- Joins the lobby created by `CreateLobby`.
---@param address GPGNetAddress
---@param asObserver boolean
---@param playerName? string
---@param uid? UILobbyPeerId
function JoinGame(address, asObserver, playerName, uid)
    if Instance then
        Instance:JoinGame(address, playerName, uid)
    end
end

--- Called by the engine.
function ConnectToPeer(addressAndPort, name, uid)
    if Instance then
        Instance:ConnectToPeer(addressAndPort, name, uid)
    end
end

--- Called by the engine.
function DisconnectFromPeer(uid)
    if Instance then
        Instance:DisconnectFromPeer(uid)
    end
end
