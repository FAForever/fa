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

-- Measures the sim cost per tick of each unit class, to calibrate the unit cap cost (`General.CapCost`).
--
-- For each case it measures the sim time per tick without the units (baseline), spawns `count` units at
-- the mouse position, lets them settle, measures again and reports `(case - baseline) / count` as the
-- cost of one unit, in microseconds per tick and relative to an idle T1 tank.
--
-- Sim time comes from the engine stats `Sim_Dispatch` (the beat itself) and `Sim_Sync` (copying the
-- sim state to the UI), which hold the duration of the most recent beat, so how fast the sim runs does
-- not affect them. The benchmark turns on `wld_RunWithTheWind` so that the sim runs as fast as it can,
-- which also makes the wall clock time per tick (logged as well) close to the sim time.
--
-- Requires cheats (the sim half runs through `SimLua`), an empty area of roughly 150x150 ogrids around
-- the mouse with about 200 ogrids of room on one side along the x axis for the `move` cases, and an
-- enemy army for the `engage` cases. Results are written to the log.
--
-- Usage, from the console or the paste buffer:
--
--     import("/lua/debug/unitcostbenchmark.lua").Run()          -- all cases
--     import("/lua/debug/unitcostbenchmark.lua").Run(0.5)       -- all cases, with half the unit counts
--     import("/lua/debug/unitcostbenchmark.lua").Run(1, "PD")   -- only cases whose name contains "pd", ignoring case
--     import("/lua/debug/unitcostbenchmark.lua").Stop()
--     import("/lua/debug/unitcostbenchmark.lua").Probe(30)      -- log the raw stats of 30 ticks

local SimModule = "/lua/debug/unitcostbenchmarksim.lua"

--- Name of the case that the relative cost is based on
local ReferenceCase = "T1 tank (idle)"

---@class UnitCostBenchmarkCase
---@field name string
---@field bp UnitId
---@field count number
---@field mode 'idle' | 'move' | 'build' | 'engage'
---@field target? UnitId           # what to build (`build`) or shoot at (`engage`)
---@field targetCount? number      # targets to spawn (`engage`), defaults to `count`; not scaled by `Run`
---@field targetDistance? number   # put the targets in a grid this far along the x axis (`engage`), instead of next to each unit
---@field settle? number           # ticks to wait after spawning, before measuring

---@type UnitCostBenchmarkCase[]
Cases = {
    -- structures without production or weapons
    { name = "Wall", bp = "UEB5101", count = 500, mode = 'idle' },
    { name = "Mass storage", bp = "UEB1106", count = 300, mode = 'idle' },

    -- production
    { name = "T1 mass extractor", bp = "UEB1103", count = 300, mode = 'idle' },
    { name = "T1 power generator", bp = "UEB1101", count = 300, mode = 'idle' },
    { name = "T2 mass fabricator", bp = "UEB1104", count = 300, mode = 'idle' },

    -- intel
    { name = "T1 radar", bp = "UEB3101", count = 200, mode = 'idle' },
    { name = "T3 omni", bp = "UEB3104", count = 100, mode = 'idle' },

    -- factories and shields
    { name = "T1 land factory (idle)", bp = "UEB0101", count = 100, mode = 'idle' },
    { name = "T2 shield (idle)", bp = "UEB4202", count = 100, mode = 'idle' },

    -- weapon structures; idle weapons scan for targets over their range, so cost depends on range
    { name = "T1 PD (idle)", bp = "UEB2101", count = 200, mode = 'idle' },
    { name = "T2 PD (idle)", bp = "UEB2301", count = 200, mode = 'idle' },
    { name = "T1 AA (idle)", bp = "UEB2104", count = 200, mode = 'idle' },
    { name = "TMD (idle)", bp = "UEB4201", count = 200, mode = 'idle' },
    { name = "T2 artillery (idle)", bp = "UEB2303", count = 100, mode = 'idle' },
    { name = "T2 artillery (idle, 25)", bp = "UEB2303", count = 25, mode = 'idle' },
    { name = "T3 artillery (idle)", bp = "UEB2302", count = 30, mode = 'idle' },
    -- the same number of artillery pieces firing, with few and many enemies in range: the difference is
    -- the target checking, which artillery repeats every check interval as it has `AlwaysRecheckTarget`
    { name = "T2 artillery (20 enemies in range)", bp = "UEB2303", count = 25, mode = 'engage', target = "UEB1106", targetCount = 20, targetDistance = 80 },
    { name = "T2 artillery (200 enemies in range)", bp = "UEB2303", count = 25, mode = 'engage', target = "UEB1106", targetCount = 200, targetDistance = 80 },
    -- walls are BENIGN, which the engine rejects early in target selection: the artillery does not fire
    { name = "T2 artillery (200 walls in range)", bp = "UEB2303", count = 25, mode = 'engage', target = "UEB5101", targetCount = 200, targetDistance = 80 },
    -- walls are never fired at but are still checked; the T1 PD checks every 0.4 s, artillery every 3 s
    { name = "T1 PD (200 walls in range)", bp = "UEB2101", count = 25, mode = 'engage', target = "UEB5101", targetCount = 200, targetDistance = 16 },
    { name = "T1 PD (engaged)", bp = "UEB2101", count = 100, mode = 'engage', target = "UEB1106" },

    -- land units
    { name = "T1 land scout (idle)", bp = "UEL0101", count = 300, mode = 'idle' },
    { name = "T1 engineer (idle)", bp = "UEL0105", count = 300, mode = 'idle' },
    { name = "T1 tank (idle)", bp = "UEL0201", count = 300, mode = 'idle' },
    { name = "T1 tank (moving)", bp = "UEL0201", count = 300, mode = 'move' },
    { name = "T1 tank (engaged)", bp = "UEL0201", count = 100, mode = 'engage', target = "UEB1106" },
    { name = "T1 bot (moving)", bp = "URL0106", count = 300, mode = 'move' },
    { name = "T2 MML (idle)", bp = "UEL0111", count = 200, mode = 'idle' },
    { name = "T2 mobile shield (idle)", bp = "UEL0307", count = 100, mode = 'idle' },
    { name = "T3 tank (idle)", bp = "XSL0303", count = 200, mode = 'idle' },
    { name = "T3 tank (moving)", bp = "XSL0303", count = 200, mode = 'move' },
    { name = "T3 bot, Percival (idle)", bp = "XEL0305", count = 200, mode = 'idle' },
    { name = "T3 bot, Percival (moving)", bp = "XEL0305", count = 200, mode = 'move' },
    { name = "T3 bot, personal shield (idle)", bp = "UEL0303", count = 200, mode = 'idle' },
    { name = "T3 bot, personal shield (moving)", bp = "UEL0303", count = 200, mode = 'move' },
    { name = "T3 engineer (building)", bp = "UEL0309", count = 100, mode = 'build', target = "UEB2401", settle = 150 },

    -- air units fly in circles once they reach their destination
    { name = "T1 air scout (flying)", bp = "UEA0101", count = 200, mode = 'move' },
    { name = "T1 interceptor (flying)", bp = "UEA0102", count = 200, mode = 'move' },
    { name = "T1 interceptor (landed)", bp = "UEA0102", count = 200, mode = 'idle' },
    { name = "T2 transport (flying)", bp = "UEA0104", count = 100, mode = 'move' },
    { name = "T3 spy plane (flying)", bp = "UEA0302", count = 100, mode = 'move' },

    -- experimentals
    { name = "Fatboy (idle)", bp = "UEL0401", count = 10, mode = 'idle' },
    { name = "Galactic Colossus (idle)", bp = "UAL0401", count = 10, mode = 'idle' },
}

--- Ticks to wait after spawning or clearing, before measuring
local SettleTicks = 60
--- Ticks per measurement window; a multiple of 70, as the engine runs a full Lua GC every 70 ticks
local WindowTicks = 140
--- Fraction of the slowest beats of a window that is left out, to drop GC and other spikes
local TrimFraction = 0.05
--- Measurement windows per measurement, of which the median is used
local Windows = 3

local benchmarkThread = nil

--- Whether `Sim_Dispatch` was ever non-zero; if not, only wall clock time is available
local statsAvailable = false

--- The engine adds integer microseconds to the bits of these float stats, so Lua sees denormal floats
--- such as 7.68e-43 for 548 us. Multiplying by 2^149 recovers the integer; it is split in two because
--- 2^149 does not fit in a float.
---@param value number
---@return number
local function DecodeStat(value)
    if value > 0 and value < 1e-30 then
        return value * 1.2676506002282294e30 * 562949953421312 -- 2^100 * 2^49
    end
    return value
end

--- Returns the `Sim_Dispatch` and `Sim_Sync` engine stats, in microseconds.
---@return number dispatch
---@return number sync
local function ReadSimStats()
    local dispatch, sync = 0, 0
    -- their order is not set in stone, hence the search
    for _, stat in __EngineStats.Children or {} do
        if stat.Name == 'Sim' then
            for _, entry in stat.Children or {} do
                if entry.Name == 'Dispatch' then
                    dispatch = DecodeStat(entry.Value or 0)
                elseif entry.Name == 'Sync' then
                    sync = DecodeStat(entry.Value or 0)
                end
            end
        end
    end
    return dispatch, sync
end

--- Waits until the sim advanced `ticks` ticks.
---@param ticks number
local function WaitTicks(ticks)
    local target = GameTick() + ticks
    while GameTick() < target do
        WaitFrames(1)
    end
end

--- Samples the engine stats every frame until the sim advanced `ticks` ticks.
---@param ticks number
---@return { tick: number, dispatch: number, sync: number }[]
---@return number wallSeconds
---@return number ticksElapsed
local function Sample(ticks)
    local startTick = GameTick()
    local startWall = GetSystemTimeSeconds()
    local dispatch, sync = ReadSimStats()
    local samples = { { tick = startTick, dispatch = dispatch, sync = sync } }

    while GameTick() < startTick + ticks do
        WaitFrames(1)
        dispatch, sync = ReadSimStats()
        table.insert(samples, { tick = GameTick(), dispatch = dispatch, sync = sync })
    end

    return samples, GetSystemTimeSeconds() - startWall, GameTick() - startTick
end

--- Logs a short sample of the stats, so that what they hold can be checked against the wall clock.
local function CheckStats()
    local samples = Sample(50)

    local raw = {}
    for k = 1, table.getn(samples) do
        if samples[k].dispatch ~= 0 then
            statsAvailable = true
        end
        if k <= 10 then
            table.insert(raw, string.format("%d:%.0f/%.0f", samples[k].tick, samples[k].dispatch, samples[k].sync))
        end
    end

    LOG(string.format("UnitCostBenchmark: first samples, tick:dispatch/sync in us: %s", table.concat(raw, " ")))
    if not statsAvailable then
        WARN("UnitCostBenchmark: Sim_Dispatch is always 0, only wall clock time is available")
    end
end

--- Returns the mean of `values` without the highest `TrimFraction` of them.
---@param values number[]
---@return number
local function TrimmedMean(values)
    table.sort(values)
    local count = table.getn(values) - math.floor(TrimFraction * table.getn(values))
    local sum = 0
    for k = 1, count do
        sum = sum + values[k]
    end
    return sum / math.max(1, count)
end

--- Measures the sim time per tick, as the median of several windows. `Sim_Dispatch` and `Sim_Sync`
--- hold the duration of the most recent beat. They are read on the first frame of each new tick, and
--- only when the sim advanced exactly one tick since the previous sample, so that each sample is a
--- different beat. Within a window, the slowest beats are left out (see `TrimFraction`).
---@return number dispatch    # microseconds per tick
---@return number sync        # microseconds per tick
---@return number wall        # microseconds per tick
---@return number untrimmed   # dispatch plus sync in microseconds per tick, including the slowest beats
local function Measure()
    local dispatches, syncs, walls, untrimmeds = {}, {}, {}, {}
    for _ = 1, Windows do
        local samples, wallSeconds, ticks = Sample(WindowTicks)

        local beatDispatches, beatSyncs, total = {}, {}, 0
        for k = 2, table.getn(samples) do
            if samples[k].tick == samples[k - 1].tick + 1 then
                table.insert(beatDispatches, samples[k].dispatch)
                table.insert(beatSyncs, samples[k].sync)
                total = total + samples[k].dispatch + samples[k].sync
            end
        end
        table.insert(untrimmeds, total / math.max(1, table.getn(beatDispatches)))

        table.insert(dispatches, TrimmedMean(beatDispatches))
        table.insert(syncs, TrimmedMean(beatSyncs))
        table.insert(walls, 1e6 * wallSeconds / ticks)
    end

    table.sort(dispatches)
    table.sort(syncs)
    table.sort(walls)
    table.sort(untrimmeds)
    local median = math.ceil(Windows / 2)
    return dispatches[median], syncs[median], walls[median], untrimmeds[median]
end

---@param code string
local function SimLua(code)
    -- the space after `SimLua` is required, and strings in `code` must use single quotes: the console
    -- escapes double quotes incorrectly when there is more than one pair
    ConExecute("SimLua " .. code)
end

---@param case UnitCostBenchmarkCase
---@param mode string
---@param army number
---@param position Vector
local function SpawnCase(case, mode, army, position)
    SimLua(string.format(
        "import('%s').Spawn('%s', %d, %d, %f, %f, '%s', %s, %f, %s, %s)",
        SimModule, case.bp, case.count, army, position[1], position[3], mode,
        case.target and ("'" .. case.target .. "'") or "nil",
        ((case.settle or SettleTicks) + Windows * WindowTicks) / 10,
        tostring(case.targetCount or "nil"),
        tostring(case.targetDistance or "nil")
    ))
end

---@param position Vector
local function ReportUnits(position)
    SimLua(string.format("import('%s').Report(%f, %f)", SimModule, position[1], position[3]))
end

local function ClearUnits()
    SimLua(string.format("import('%s').Clear()", SimModule))
end

---@param scale number
---@param filter? string
local function BenchmarkThread(scale, filter)
    local army = GetFocusArmy()
    local position = GetMouseWorldPos()
    -- run as fast as possible; a game speed setting holds it back, so it is left alone
    ConExecute("wld_RunWithTheWind true")
    -- one beat per frame at most, so that each frame with a new tick reads a different beat
    ConExecute("sim_Interlocked true")

    LOG(string.format("UnitCostBenchmark: starting at (%.0f, %.0f) for army %d, scale %.2f", position[1], position[3], army, scale))

    ClearUnits()
    WaitTicks(SettleTicks)
    CheckStats()

    local results = {}
    for _, template in Cases do
        if not filter or string.find(string.lower(template.name), string.lower(filter), 1, true) then
            local case = table.copy(template)
            case.count = math.max(1, math.floor(case.count * scale))
            local settle = case.settle or SettleTicks

            -- baseline without the units; the `engage` cases include the targets in the baseline
            ClearUnits()
            if case.mode == 'engage' then
                SpawnCase(case, 'targets', army, position)
            end
            WaitTicks(settle)
            ReportUnits(position)
            local baseDispatch, baseSync, baseWall, baseUntrimmed = Measure()

            ClearUnits()
            SpawnCase(case, case.mode, army, position)
            WaitTicks(settle)
            local dispatch, sync, wall, untrimmed = Measure()
            -- after measuring, so that it shows the units were still busy at the end
            ReportUnits(position)
            WaitTicks(1)
            ClearUnits()

            local result = {
                name = case.name,
                bp = case.bp,
                count = case.count,
                dispatch = (dispatch - baseDispatch) / case.count,
                sync = (sync - baseSync) / case.count,
                wall = (wall - baseWall) / case.count,
                -- includes the GC beats, whose duration grows with the Lua memory of the units
                untrimmed = (untrimmed - baseUntrimmed) / case.count,
            }
            table.insert(results, result)

            -- as the sim runs as fast as it can, the wall clock time with units should be close to the sim
            -- time with units plus rendering; that checks what the stats hold
            LOG(string.format(
                "UnitCostBenchmark: %-28s %4d units: baseline %8.0f us/tick, with units %8.0f us/tick (wall %8.0f), %6.2f us/tick/unit (sync %5.2f, untrimmed %6.2f, wall %6.2f)",
                result.name, result.count, baseDispatch + baseSync, dispatch + sync, wall, result.dispatch + result.sync, result.sync, result.untrimmed, result.wall
            ))
        end
    end

    ClearUnits()
    ConExecute("wld_RunWithTheWind false")
    ConExecute("sim_Interlocked false")

    -- relative to the reference case, using wall clock time when the stats are unavailable
    local function Cost(result)
        if not statsAvailable then
            return result.wall
        end
        return result.dispatch + result.sync
    end

    local reference = nil
    for _, result in results do
        if result.name == ReferenceCase then
            reference = Cost(result)
        end
    end

    LOG("UnitCostBenchmark: results (us/tick/unit; relative to '" .. ReferenceCase .. "')")
    LOG("UnitCostBenchmark: name,blueprint,count,dispatch,sync,untrimmed,wall,relative")
    for _, result in results do
        local relative = reference and reference > 0 and string.format("%.2f", Cost(result) / reference) or "n/a"
        LOG(string.format("UnitCostBenchmark: %s,%s,%d,%.3f,%.3f,%.3f,%.3f,%s",
            result.name, result.bp, result.count, result.dispatch, result.sync, result.untrimmed, result.wall, relative
        ))
    end

    print("Unit cost benchmark finished, see the log")
    benchmarkThread = nil
end

--- Runs the benchmark at the mouse position.
---@param scale? number     # multiplier for the unit count of every case, defaults to 1
---@param filter? string    # only run cases whose name contains this text, ignoring case
function Run(scale, filter)
    if benchmarkThread then
        WARN("UnitCostBenchmark: already running")
        return
    end
    benchmarkThread = ForkThread(BenchmarkThread, scale or 1, filter)
end

--- Logs the decoded stats on every frame for `ticks` ticks, with the wall clock, to check what they
--- hold: the time of the last beat, a sum since the last frame, or something updated less often.
--- Run it once with nothing spawned and once with a load that makes the sim slower than real time.
---@param ticks? number     # defaults to 30
function Probe(ticks)
    ForkThread(function()
        local startWall = GetSystemTimeSeconds()
        local samples = Sample(ticks or 30)
        local wallPerTick = 1e6 * (GetSystemTimeSeconds() - startWall) / math.max(1, samples[table.getn(samples)].tick - samples[1].tick)
        LOG(string.format("UnitCostBenchmark: probe, %d frames, %.0f us/tick wall clock at game speed %d", table.getn(samples), wallPerTick, GetGameSpeed()))
        for _, sample in samples do
            LOG(string.format("UnitCostBenchmark: probe tick %d dispatch %.0f sync %.0f", sample.tick, sample.dispatch, sample.sync))
        end
    end)
end

--- Stops the benchmark and removes its units.
function Stop()
    if benchmarkThread then
        KillThread(benchmarkThread)
        benchmarkThread = nil
        ConExecute("wld_RunWithTheWind false")
        ConExecute("sim_Interlocked false")
    end
    ClearUnits()
end
