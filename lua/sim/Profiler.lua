
-- Useful sources to read: 
-- - https://www.lua.org/pil/23.1.html

local Statistics = import("/lua/shared/statistics.lua")
local CollapseDebugInfo = import("/lua/shared/Profiler.lua").CollapseDebugInfo
local CreateEmptyProfilerTable = import("/lua/shared/Profiler.lua").CreateEmptyProfilerTable
local PlayerIsDev = import("/lua/shared/Profiler.lua").PlayerIsDev

-- upvalue for performance
local sethook = debug.sethook
local getinfo = debug.getinfo

local SPEW = SPEW
local WaitTicks = WaitTicks

--- Keeps track of whether profiling has been toggled or not
local isProfiling = false
--- Thread to keep the simulation synced with the UI
local profilingThread
local benchmarkThread
--- Data that we send over to the UI
local data = CreateEmptyProfilerTable()
--- How many times each benchmark is run by default
local defaultBenchmarkRuns = 30
local benchmarkPath = "/lua/benchmarks"
local benchmarkModules

local benchmarkExcludeFunctions = {
    import = true,
    __moduleinfo = true,
}

local function CanUseProfiler()
    if ScenarioInfo.GameHasAIs then
        SPEW("Profiler can be toggled: game has AIs")
        return true
    end
    if CheatsEnabled() then
        SPEW("Profiler can be toggled: game has cheats enabled")
        return true
    end
    if SessionIsReplay() then
        SPEW("Profiler can be toggled: session is a replay")
        return true
    end

    -- exception to allow toggling the profiler
    for _, brain in ArmyBrains do
        if PlayerIsDev(brain) then
            SPEW("Profiler can be toggled: a game developer is in the game")
            return true
        end
    end
    return false
end

--- Toggles the profiler on / off
function ToggleProfiler(army, forceEnable)
    if  not CanUseProfiler() or       -- game currently isn't in a state that would use the profiler
        GetFocusArmy() ~= army or     -- if we're not the ones that initiated this call, get out
        (forceEnable and isProfiling) -- let the profiler be on if we are trying to force it on 
    then
        return
    end

    if not isProfiling then
        -- Inform us in case of abuse
        SPEW("Profiler has been toggled on by army: " .. tostring(army))
        isProfiling = true

        -- Thread to sync information gathered to the UI
        if not profilingThread then
            profilingThread = ForkThread(SyncThread)
        end

        -- Add a function to track
        sethook(FunctionHook, "c") -- only track on function calls
    else
        isProfiling = false
        if profilingThread then
            profilingThread = KillThread(profilingThread)
        end

        -- Inform us in case of abuse
        SPEW("Profiler has been toggled off by army: " .. tostring(army))

        sethook(nil) -- remove tracking
    end
end

function FunctionHook(event)
    -- quite expensive, returns a table
    local info = getinfo(2, "Sn")
    -- because of "n"
    -- i.name           = A reasonable name for the function
    -- i.namewhat       = What the previous field means. This field may be "global", "local", "method", "field", or "" (the empty string). The empty string means that Lua did not find a name for the function

    -- because of "S"
    -- i.source         = Where the function was defined. If the function was defined in a string (through loadstring), source is that string. If the function was defined in a file, source is the file name prefixed with a `@´
    -- i.short_src      = A short version of source (up to 60 characters), useful for error messages
    -- i.what           = What this function is. Options are "Lua" if foo is a regular Lua function, "C" if it is a C function, or "main" if it is the main part of a Lua chunk
    -- i.linedefined    = The line of the source where the function was defined

    local source, scope, name = CollapseDebugInfo(info)

    -- keep track 
    scopeData = data[source][scope]
    local count = scopeData[name]
    if not count then
        scopeData[name] = 1
    else
        scopeData[name] = count + 1
    end
end

function SyncThread()
    while true do
        -- pass along the profiler information
        Sync.ProfilerData = data

        -- reset data collection
        data = CreateEmptyProfilerTable()

        -- hold up a frame
        WaitTicks(1)
    end
end

---@class BenchmarkModuleMetadata
---@field moduleName string
---@field moduleDesc string
---@field titles table<string, string>
---@field descs table<string, string>
---@field runs table<string, number>
---@field excludes table<string, true>
---@field sort table<string, number>

---@param module Module
---@return BenchmarkModuleMetadata?
function PullBenchmarkModuleMetadata(module)
    local moduleName = ""
    local moduleDesc = ""
    local benchmarkTitles = {}
    local benchmarkDescs = {}
    local benchmarkRuns = {}
    local localExclude = {}
    local sortOrder = {}
    -- can't just pull these values because it'll throw an error if they don't exist
    -- so we get to iterate over everything!
    for k, val in module do
        if k == "NotBenchmarkModule" then
            if val and type(val) == "boolean" then
                -- indicate that this module, inside of the `/benchmarks/` folder, isn't for benchmarking
                SPEW("Module " .. module.__moduleinfo.name .. " excluded from benchmarking list")
                return nil
            end
        end
        if k == "ModuleName" then
            if type(val) == "string" then
                moduleName = val
            end
            continue
        end
        if k == "ModuleDescription" then
            if type(val) == "string" then
                moduleDesc = val
            end
            continue
        end
        if type(val) ~= "table" then
            continue
        end
        if k == "BenchmarkData" then
            for funName, funData in val do
                if type(funName) ~= "string" then
                    continue
                end
                -- a string indicates the benchmarks display name
                if type(funData) == "string" then
                    benchmarkTitles[funName] = funData
                -- otherwise, it's a table of metdata on the benchmark 
                elseif type(funData) == "table" then
                    local funTitle = funData.name
                    if funTitle and type(funTitle) == "string" then
                        benchmarkTitles[funName] = funTitle
                    end
                    local funDesc = funData.desc
                    if funDesc and type(funDesc) == "string" then
                        benchmarkDescs[funName] = funDesc
                    end
                    local funRuns = funData.runs
                    if funRuns and type(funRuns) == "number" then
                        benchmarkRuns[funName] = funRuns
                    end
                    local funExc = funData.exclude
                    if funExc and type(funExc) == "boolean" then
                        localExclude[funName] = true
                    end
                    local funSort = funData.sort
                    if funSort and type(funSort) == "number" then
                        sortOrder[funName] = funSort
                    end
                end
            end
            continue
        end
        if k == "Exclude" then
            -- yes, it's possible to use the `BenchmarkData[x].exclude` field, but can be unwieldly in
            -- some applications, so a separate `Exclude` table is also supported
            for excludeName, doExclude in val do
                if type(excludeName) == "string" and doExclude then
                    localExclude[excludeName] = true
                end
            end
            continue
        end
    end
    return {
        moduleName = moduleName,
        moduleDesc = moduleDesc,
        titles = benchmarkTitles,
        descs = benchmarkDescs,
        runs = benchmarkRuns,
        excludes = localExclude,
        sort = sortOrder,
    }
end

---@param name string
---@return Module? module
---@return BenchmarkModuleMetadata? metadata
---@return string? error
function LoadBenchmarkModule(name)
    -- **le sigh**   this doesn't catch any errors inside `doscript`, only explicit Lua errors
    local ok, obj = pcall(import, name)
    if ok then
        -- we can still check to see if the module is empty, which only probably means that it failed
        local notEmpty = table.getsize(obj) > table.getsize(benchmarkExcludeFunctions)
        if notEmpty or true then
            return obj, PullBenchmarkModuleMetadata(obj)
        end
        WARN("Skipping empty benchmark module \"" .. name .. "\"; there's likely a 'WARNING: SCR_LuaDoFileConcat' right above me'")
        return obj, nil
    end
    WARN("Couldn't load benchmark module \"" .. name .. "\": " .. obj)
    return nil, {}, obj
end

function FindBenchmarks(army)
    SPEW("Benchmarks have been searched for by army: " .. tostring(army))

    local modulesUser = {}
    local modulesSim = {}
    local moduleCount = 0
    local sortOrder

    -- sorts by the `name` field, but first it groups by the `sort` field
    -- (1) Positive sorts (closer to zero first)
    -- (2) Zero sorts (the default)
    -- (3) Negative sorts (closer to zero first)
    local function BenchmarkSorter(a, b)
        local aname = a.name
        local bname = b.name
        local asort = sortOrder[aname] or 0
        local bsort = sortOrder[bname] or 0
        if asort ~= bsort then
            if asort > 0 then
                return bsort <= 0 or asort < bsort
            else
                return bsort < 0 and asort > bsort
            end
        end
        return a.name:lower() < b.name:lower()
    end

    local function AddBenchmarkModulesFromFolder(path)
        local files = DiskFindFiles(path, "*.lua")
        local TableSort = table.sort

        for _, file in files do
            -- retrieve benchmark module
            local module, metadata, error = LoadBenchmarkModule(file)
            if not metadata then
                continue -- the file isn't a benchmark
            end

            moduleCount = moduleCount + 1
            if error then
                -- add faulty category
                modulesUser[moduleCount] = {
                    folder = path,
                    file = file,
                    benchmarks = {},
                    faulty = true,
                    name = metadata.moduleName,
                    desc = error,
                }
                modulesSim[moduleCount] = {
                    file = file,
                    benchmarks = {},
                }
                continue
            end
            local benchmarkTitles = metadata.titles
            local benchmarkDescs = metadata.descs
            local benchmarkRuns = metadata.runs
            local localExclude = metadata.excludes
            sortOrder = metadata.sort -- upvalue into the sorter

            local userBenchmarkData = {}
            local simBenchmarkData = {}
            local benchmarkCount = 0

            for funName, benchmark in module do
                -- exclude these functions
                if benchmarkExcludeFunctions[funName] or localExclude[funName] then
                    continue
                end

                -- only look at functions
                if type(benchmark) == "function" then
                    -- add correct entry
                    benchmarkCount = benchmarkCount + 1
                    userBenchmarkData[benchmarkCount] = {
                        name = funName,
                        title = benchmarkTitles[funName] or "",
                        desc = benchmarkDescs[funName] or "",
                    }
                    simBenchmarkData[benchmarkCount] = {
                        name = funName,
                        func = benchmark,
                        runs = benchmarkRuns[funName] or defaultBenchmarkRuns,
                    }
                end
            end

            TableSort(userBenchmarkData, BenchmarkSorter)
            TableSort(simBenchmarkData, BenchmarkSorter)

            -- add correct category
            modulesUser[moduleCount] = {
                folder = path,
                file = file,
                benchmarks = userBenchmarkData,
                faulty = false,
                name = metadata.moduleName,
                desc = metadata.moduleDesc,
            }
            modulesSim[moduleCount] = {
                file = file,
                benchmarks = simBenchmarkData,
            }
        end
    end

    -- add benchmarks from base game
    AddBenchmarkModulesFromFolder(benchmarkPath)

    -- add benchmarks from mods
    for _, mod in __active_mods do
        AddBenchmarkModulesFromFolder(mod.location .. benchmarkPath)
    end

    -- sync it over
    Sync.Benchmarks = modulesUser
    benchmarkModules = modulesSim
end

function RunBenchmark(fileIndex, benchmarkIndex)
    if not benchmarkThread then
        local moduleData = benchmarkModules[fileIndex]
        LOG("Running benchmark \"" .. tostring(moduleData.benchmarks[benchmarkIndex].name) .. "\" in file " .. tostring(moduleData.file))
        benchmarkThread = ForkThread(RunBenchmarkThread, fileIndex, benchmarkIndex)
    else
        SPEW("Already running benchmark")
    end
end

function StopBenchmark()
    SPEW("Stopping benchmark")
    benchmarkThread = false
end

function RunBenchmarkThread(fileIndex, benchmarkIndex)
    -- keep track of all output
    local output = {}
    local benchmark = benchmarkModules[fileIndex].benchmarks[benchmarkIndex]
    if benchmark == nil then
        WARN("Can't run benchmark " .. tostring(fileIndex) .. "," .. tostring(benchmarkIndex))
        Sync.BenchmarkOutput = {success = false}
        return
    end

    local test = benchmark.func
    local runs = benchmark.runs
    Sync.BenchmarkProgress = {runs = runs}
    WaitTicks(1)

    -- run benchmark multiple times
    for k = 1, runs do
        output[k] = test()
        Sync.BenchmarkProgress = {complete = k}
        WaitTicks(1)
        if not benchmarkThread then
            break
        end
    end

    -- outliers are created by the garbage collector kicking in
    local trimmed, size = Statistics.StatObject(output):RemoveOutliers()

    -- sync to UI
    Sync.BenchmarkOutput = { samples = size, data = trimmed, success = true }
    benchmarkThread = false
    SPEW("Done with benchmark")
end
