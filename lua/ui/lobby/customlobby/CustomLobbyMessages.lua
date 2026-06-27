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
-- **Validate / Accept return `true` when the message is fine, or `false, reason` when it is not** —
-- a human-readable reason string explaining why (never a bare `false` — always say *why*). The
-- instance logs that reason against the message (see CustomLobbyLog / the Logs tab) and the UI
-- surfaces it as a tooltip, so a bad or unauthorised message is explained rather than silently dropped.
--
-- Each message's payload is typed via a `---@class … : UILobbyReceivedMessage` so the
-- handlers (and any future tooling) know its exact shape.

local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")

--- Authorisation check: passes only for the host.
---@param lobby UICustomLobbyInstance
---@return boolean ok
---@return string? reason
local function RequireHost(lobby)
    if lobby:IsHost() then
        return true
    end
    return false, "only the host may act on this message"
end

--- Authorisation check: passes only when the message came from the host.
---@param lobby UICustomLobbyInstance
---@param data UILobbyReceivedMessage
---@return boolean ok
---@return string? reason
local function RequireFromHost(lobby, data)
    if data.SenderID == CustomLobbyLocalModel.GetSingleton().HostID() then
        return true
    end
    return false, "message did not come from the host"
end

---@class UICustomLobbyMessageHandler
---@field Validate fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage): boolean, string?
---@field Accept fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage): boolean, string?
---@field Handler fun(lobby: UICustomLobbyInstance, data: UILobbyReceivedMessage)

---@type table<string, UICustomLobbyMessageHandler>
CustomLobbyMessages = {

    -- A connecting client announces itself to the host.
    AddPlayer = {
        ---@class UICustomLobbyAddPlayerMessage : UILobbyReceivedMessage
        ---@field PlayerOptions UICustomLobbyPlayer

        ---@param data UICustomLobbyAddPlayerMessage
        Validate = function(lobby, data)
            if data.PlayerOptions == nil then
                return false, "AddPlayer is missing its PlayerOptions"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireHost(lobby)
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
            if type(data.Players) ~= 'table' then
                return false, "SetPlayers has no Players array"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySetPlayersMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetPlayers(lobby, data)
        end,
    },

    -- The host's launch configuration — the launch-state fields that aren't the player
    -- list (scenario, options, mods, teams, spawn mex, unit restrictions). Broadcast on any
    -- change and to each peer as it joins; the whole snapshot is sent rather than per-field deltas.
    SentLaunchInfo = {
        ---@class UICustomLobbySentLaunchInfoMessage : UILobbyReceivedMessage
        ---@field ScenarioFile FileName | false
        ---@field GameOptions table
        ---@field GameMods table
        ---@field AutoTeams table<number, number>
        ---@field SpawnMex table<number, boolean>
        ---@field Restrictions string[]

        ---@param data UICustomLobbySentLaunchInfoMessage
        Validate = function(lobby, data)
            if type(data.GameOptions) ~= 'table' or type(data.GameMods) ~= 'table' then
                return false, "SentLaunchInfo is missing its GameOptions / GameMods"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySentLaunchInfoMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSentLaunchInfo(lobby, data)
        end,
    },

    -- The host's session state — lobby-room management that is NOT launched (slot count,
    -- closed slots, locked slots). A separate snapshot from the launch config so each stays focused.
    SetSessionState = {
        ---@class UICustomLobbySetSessionStateMessage : UILobbyReceivedMessage
        ---@field SlotCount number
        ---@field ClosedSlots table<number, boolean>
        ---@field LockedSlots table<number, boolean>
        ---@field SlotsPinned boolean

        ---@param data UICustomLobbySetSessionStateMessage
        Validate = function(lobby, data)
            if type(data.SlotCount) ~= 'number' then
                return false, "SetSessionState has no SlotCount"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySetSessionStateMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetSessionState(lobby, data)
        end,
    },

    -- A client asks the host to flip its ready flag.
    SetReady = {
        ---@class UICustomLobbySetReadyMessage : UILobbyReceivedMessage
        ---@field Ready boolean

        ---@param data UICustomLobbySetReadyMessage
        Validate = function(lobby, data)
            if type(data.Ready) ~= 'boolean' then
                return false, "SetReady has no Ready flag"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireHost(lobby)
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
            if type(data.Slot) ~= 'number' then
                return false, "TakeSlot has no Slot number"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireHost(lobby)
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
            if data.PeerID == nil then
                return false, "DisconnectPeer is missing its PeerID"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbyDisconnectPeerMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessDisconnectPeer(lobby, data)
        end,
    },

    -- The host tells everyone to launch with the final game configuration (players, options,
    -- mods, scenario). On receipt each peer hands it straight to the engine.
    LaunchGame = {
        ---@class UICustomLobbyLaunchGameMessage : UILobbyReceivedMessage
        ---@field GameConfig UILobbyLaunchConfiguration

        ---@param data UICustomLobbyLaunchGameMessage
        Validate = function(lobby, data)
            if type(data.GameConfig) ~= 'table' then
                return false, "LaunchGame has no GameConfig"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbyLaunchGameMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessLaunchGame(lobby, data)
        end,
    },

    -- A client reports its in-game sim-performance history (the rich benchmark).
    ReportCpuBenchmark = {
        ---@class UICustomLobbyReportCpuBenchmarkMessage : UILobbyReceivedMessage
        ---@field CpuBenchmark UIPerformanceMetrics

        ---@param data UICustomLobbyReportCpuBenchmarkMessage
        Validate = function(lobby, data)
            if type(data.CpuBenchmark) ~= 'table' then
                return false, "ReportCpuBenchmark has no CpuBenchmark"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireHost(lobby)
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
            if type(data.CpuBenchmarks) ~= 'table' then
                return false, "SetCpuBenchmarks has no CpuBenchmarks table"
            end
            return true
        end,
        Accept = function(lobby, data)
            return RequireFromHost(lobby, data)
        end,
        ---@param data UICustomLobbySetCpuBenchmarksMessage
        Handler = function(lobby, data)
            CustomLobbyController.ProcessSetCpuBenchmarks(lobby, data)
        end,
    },
}
