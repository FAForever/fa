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
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")

-------------------------------------------------------------------------------
--#region Reactive model
--
-- LIFETIME. A `ClassSimple` implementing `Destroyable`, registered in the session trash bag (see
-- CustomLobbySession) on first access, so one `CustomLobbySession.Teardown()` resets it. Per the
-- teardown design's decision #3 the write helpers stay **free functions** (below) and `Destroy` is
-- **thin** — it just nils the module singleton so the next session rebuilds; the LazyVars are freed by
-- GC once the views observing them are torn down (we don't proactively destroy them, since the
-- interface that subscribes to them isn't in the bag yet). See design/session-trashbag-teardown.md.

-- The singleton, forward-declared above the class so `Destroy` captures it as an upvalue. Assigned in
-- `SetupSingleton`, cleared in `Destroy`.
---@type UICustomLobbyLocalModel | nil
local Instance = nil

--- Reactive local-state singleton (per-peer, never synced).
---@class UICustomLobbyLocalModel : Destroyable
---@field LocalPeerId   LazyVar<UILobbyPeerId>                                      # this client's peer id
---@field HostID        LazyVar<UILobbyPeerId>                                      # the host's peer id
---@field IsHost        LazyVar<boolean>                                            # whether this client is the host
---@field CpuBenchmarks LazyVar<table<UILobbyPeerId, UIPerformanceMetrics>>         # peer id -> in-game sim-performance history (see /lua/system/performance.lua)
---@field Destroyed     boolean
local LocalModel = ClassSimple {

    ---@param self UICustomLobbyLocalModel
    __init = function(self)
        self.LocalPeerId   = Create("-1")
        self.HostID        = Create("-1")
        self.IsHost        = Create(false)
        self.CpuBenchmarks = Create({})
        self.Destroyed     = false
    end,

    --- `Destroyable`: thin teardown — drop the module singleton so the next session rebuilds (and
    --- re-registers). The LazyVars GC once the views observing them are gone. Idempotent.
    ---@param self UICustomLobbyLocalModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh local-model singleton and registers it in the session trash.
---@return UICustomLobbyLocalModel
function SetupSingleton()
    Instance = LocalModel()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- Returns the local-model singleton, creating (and registering) it on first access.
---@return UICustomLobbyLocalModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyLocalModel]]
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

--- Hot-reload hook: rebuilds the singleton (registering the new one) and copies the values across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        local handle = newModule.SetupSingleton()
        handle.LocalPeerId:Set(Instance.LocalPeerId())
        handle.HostID:Set(Instance.HostID())
        handle.IsHost:Set(Instance.IsHost())
        handle.CpuBenchmarks:Set(Instance.CpuBenchmarks())
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
