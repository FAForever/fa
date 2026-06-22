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

-- Local, high-frequency lobby state that is NOT part of the host's authoritative
-- game snapshot: CPU benchmarks (and later ping / connection status). Kept separate
-- from CustomLobbyAuthoritativeModel so its churn doesn't dirty the synced game state. See
-- /lua/ui/lobby/TARGET_ARCHITECTURE.md § 3 (LobbyConnectivityModel).

local Create = import("/lua/lazyvar.lua").Create

--- Reactive connectivity-state singleton.
---@class UICustomLobbyModel
---@field CpuBenchmarks LazyVar<table<UILobbyPeerId, UIPerformanceMetrics>>        # peer id -> in-game sim-performance history (see /lua/system/performance.lua)
local ModelInstance = nil

--- Allocates a fresh connectivity-model singleton, replacing any existing one.
---@return UICustomLobbyModel
function SetupSingleton()
    ---@type UICustomLobbyModel
    local model = {
        CpuBenchmarks = Create({}),
    }
    ModelInstance = model
    return model
end

--- Returns the connectivity-model singleton, creating it on first access.
---@return UICustomLobbyModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbyModel]]
end

--- Records a peer's in-game sim-performance history / benchmark (copy-then-Set).
---@param model UICustomLobbyModel
---@param ownerId UILobbyPeerId
---@param benchmark UIPerformanceMetrics
function SetCpuBenchmark(model, ownerId, benchmark)
    local all = table.copy(model.CpuBenchmarks())
    all[ownerId] = benchmark
    model.CpuBenchmarks:Set(all)
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the values across.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
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
