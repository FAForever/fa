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

-- The valid peer-to-peer messages for the custom lobby. Mirrors the autolobby's
-- AutolobbyMessages registry: each entry has Validate (drop nonsense), Accept (drop
-- unauthorised) and Handler (route to the controller). The instance's DataReceived /
-- BroadcastData / SendData run these before anything happens.
--
-- Each message's payload is typed via a `---@class … : UILobbyReceivedMessage` so the
-- handlers (and any future tooling) know its exact shape.

local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

---@param lobby UICustomLobbyInstance
---@return boolean
local function AmHost(lobby)
    return lobby:IsHost()
end

---@param lobby UICustomLobbyInstance
---@param data UILobbyReceivedMessage
---@return boolean
local function IsFromHost(lobby, data)
    return data.SenderID == CustomLobbyAuthoritativeModel.GetSingleton().HostID()
end

---@class UICustomLobbyMessageHandler
---@field Validate fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage): boolean
---@field Accept fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage): boolean
---@field Handler fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage)

---@type table<string, UICustomLobbyMessageHandler>
CustomLobbyMessages = {

    -- A connecting client announces itself to the host.
    AddPlayer = {
        ---@class UICustomLobbyAddPlayerMessage : UILobbyReceivedMessage
        ---@field PlayerOptions UICustomLobbyPlayer

        ---@param data UICustomLobbyAddPlayerMessage
        Validate = function(lobby, data)
            return data.PlayerOptions ~= nil
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        ---@param data UICustomLobbyAddPlayerMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessAddPlayer(lobby, data)
        end,
    },

    -- The host's authoritative snapshot of all slots, broadcast on any change.
    SetPlayers = {
        ---@class UICustomLobbySetPlayersMessage : UILobbyReceivedMessage
        ---@field Players (UICustomLobbyPlayer | false)[]
        ---@field Observers? UICustomLobbyPlayer[]

        ---@param data UICustomLobbySetPlayersMessage
        Validate = function(lobby, data)
            return type(data.Players) == 'table'
        end,
        Accept = function(lobby, data)
            return IsFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySetPlayersMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetPlayers(lobby, data)
        end,
    },

    -- A client asks the host to flip its ready flag.
    SetReady = {
        ---@class UICustomLobbySetReadyMessage : UILobbyReceivedMessage
        ---@field Ready boolean

        ---@param data UICustomLobbySetReadyMessage
        Validate = function(lobby, data)
            return type(data.Ready) == 'boolean'
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        ---@param data UICustomLobbySetReadyMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetReady(lobby, data)
        end,
    },

    -- A client asks the host to move it into an open slot (also reachable via a
    -- `/take <slot>` chat command). The host validates the seat and re-broadcasts.
    TakeSlot = {
        ---@class UICustomLobbyTakeSlotMessage : UILobbyReceivedMessage
        ---@field Slot number

        ---@param data UICustomLobbyTakeSlotMessage
        Validate = function(lobby, data)
            return type(data.Slot) == 'number'
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        ---@param data UICustomLobbyTakeSlotMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessTakeSlot(lobby, data)
        end,
    },

    -- The host tells everyone still connected to drop their direct link to a peer
    -- that left, so the mesh is cleaned up (the player state follows via SetPlayers).
    DisconnectPeer = {
        ---@class UICustomLobbyDisconnectPeerMessage : UILobbyReceivedMessage
        ---@field PeerID UILobbyPeerId

        ---@param data UICustomLobbyDisconnectPeerMessage
        Validate = function(lobby, data)
            return data.PeerID ~= nil
        end,
        Accept = function(lobby, data)
            return IsFromHost(lobby, data)
        end,
        ---@param data UICustomLobbyDisconnectPeerMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessDisconnectPeer(lobby, data)
        end,
    },

    -- A client reports its in-game sim-performance history (the rich benchmark).
    ReportCpuBenchmark = {
        ---@class UICustomLobbyReportCpuBenchmarkMessage : UILobbyReceivedMessage
        ---@field CpuBenchmark UIPerformanceMetrics

        ---@param data UICustomLobbyReportCpuBenchmarkMessage
        Validate = function(lobby, data)
            return type(data.CpuBenchmark) == 'table'
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        ---@param data UICustomLobbyReportCpuBenchmarkMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessReportCpuBenchmark(lobby, data)
        end,
    },

    -- The host's authoritative snapshot of everyone's benchmarks.
    SetCpuBenchmarks = {
        ---@class UICustomLobbySetCpuBenchmarksMessage : UILobbyReceivedMessage
        ---@field CpuBenchmarks table<UILobbyPeerId, UIPerformanceMetrics>

        ---@param data UICustomLobbySetCpuBenchmarksMessage
        Validate = function(lobby, data)
            return type(data.CpuBenchmarks) == 'table'
        end,
        Accept = function(lobby, data)
            return IsFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySetCpuBenchmarksMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetCpuBenchmarks(lobby, data)
        end,
    },
}
