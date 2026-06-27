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

-- The **local** state: this peer's own state, NOT shared and NOT broadcast. Two kinds:
--   * identity — who this client is in the lobby (`LocalPeerId`, `HostID`, `IsHost`),
--     established by the connection handshake (OnHosting / OnConnectionToHostEstablished).
--     These are per-peer: the host's `IsHost` is true, a client's is false — broadcasting
--     them would corrupt the receiver's sense of itself, so they never go on the wire.
--   * connectivity — high-frequency local data (CPU benchmarks now; ping / connection
--     status later) whose churn must not dirty the synced launch/session snapshots.
--
-- One of three lobby models — see /lua/ui/lobby/customlobby/CLAUDE.md:
--   * LaunchModel   — shared, launched.
--   * SessionModel  — shared, lobby-room only.
--   * LocalModel    (this) — per-peer, never synced.

local Create = import("/lua/lazyvar.lua").Create

-------------------------------------------------------------------------------
--#region Reactive model

--- Reactive local-state singleton (per-peer, never synced).
---@class UICustomLobbyLocalModel
---@field LocalPeerId   LazyVar<UILobbyPeerId>                                      # this client's peer id
---@field HostID        LazyVar<UILobbyPeerId>                                      # the host's peer id
---@field IsHost        LazyVar<boolean>                                            # whether this client is the host
---@field CpuBenchmarks LazyVar<table<UILobbyPeerId, UIPerformanceMetrics>>         # peer id -> in-game sim-performance history (see /lua/system/performance.lua)
local ModelInstance = nil

--- Allocates a fresh local-model singleton, replacing any existing one.
---@return UICustomLobbyLocalModel
function SetupSingleton()
    ---@type UICustomLobbyLocalModel
    local model = {
        LocalPeerId   = Create("-1"),
        HostID        = Create("-1"),
        IsHost        = Create(false),
        CpuBenchmarks = Create({}),
    }
    ModelInstance = model
    return model
end

--- Returns the local-model singleton, creating it on first access.
---@return UICustomLobbyLocalModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbyLocalModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Write helpers

--- Records a peer's in-game sim-performance history / benchmark (copy-then-Set).
---@param model UICustomLobbyLocalModel
---@param ownerId UILobbyPeerId
---@param benchmark UIPerformanceMetrics
function SetCpuBenchmark(model, ownerId, benchmark)
    local all = table.copy(model.CpuBenchmarks())
    all[ownerId] = benchmark
    model.CpuBenchmarks:Set(all)
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the values across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.LocalPeerId:Set(ModelInstance.LocalPeerId())
        handle.HostID:Set(ModelInstance.HostID())
        handle.IsHost:Set(ModelInstance.IsHost())
        handle.CpuBenchmarks:Set(ModelInstance.CpuBenchmarks())
    end
end

--- Hot-reload hook: re-imports this module after a couple of frames.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
