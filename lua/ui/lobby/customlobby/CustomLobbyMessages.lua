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
-- This is intentionally a SMALL set for the barebones lobby: enough to see players
-- join and to round-trip one interactive change (ready).

local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

---@param lobby UICustomLobbyInstance
---@return boolean
local function AmHost(lobby)
    return lobby:IsHost()
end

---@param lobby UICustomLobbyInstance
---@param data table
---@return boolean
local function IsFromHost(lobby, data)
    return data.SenderID == CustomLobbyAuthoritativeModel.GetSingleton().HostID()
end

---@class UICustomLobbyMessageHandler
---@field Validate fun(lobby: UICustomLobbyInstance, data: table): boolean
---@field Accept fun(lobby: UICustomLobbyInstance, data: table): boolean
---@field Handler fun(lobby: UICustomLobbyInstance, data: table)

---@type table<string, UICustomLobbyMessageHandler>
CustomLobbyMessages = {

    -- A connecting client announces itself to the host.
    AddPlayer = {
        Validate = function(lobby, data)
            return data.PlayerOptions ~= nil
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        Handler = function(lobby, data)
            CustomLobbyController.ProcessAddPlayer(lobby, data)
        end,
    },

    -- The host's authoritative snapshot of all slots, broadcast on any change.
    SetPlayers = {
        Validate = function(lobby, data)
            return type(data.Players) == 'table'
        end,
        Accept = function(lobby, data)
            return IsFromHost(lobby, data)
        end,
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetPlayers(lobby, data)
        end,
    },

    -- A client asks the host to flip its ready flag.
    SetReady = {
        Validate = function(lobby, data)
            return type(data.Ready) == 'boolean'
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetReady(lobby, data)
        end,
    },

    -- A client reports its CPU benchmark to the host. The host owns the table.
    CPUBenchmark = {
        Validate = function(lobby, data)
            return type(data.Benchmark) == 'number'
        end,
        Accept = function(lobby, data)
            return AmHost(lobby)
        end,
        Handler = function(lobby, data)
            CustomLobbyController.ProcessCpuBenchmark(lobby, data)
        end,
    },

    -- The host's authoritative snapshot of everyone's CPU benchmarks.
    SetCpuBenchmarks = {
        Validate = function(lobby, data)
            return type(data.Benchmarks) == 'table'
        end,
        Accept = function(lobby, data)
            return IsFromHost(lobby, data)
        end,
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetCpuBenchmarks(lobby, data)
        end,
    },
}
