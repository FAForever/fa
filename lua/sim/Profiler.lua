
-- Useful sources to read: 
-- - https://www.lua.org/pil/23.1.html

local Statistics = import("/lua/shared/statistics.lua")
local CollapseDebugInfo = import("/lua/shared/Profiler.lua").CollapseDebugInfo
local CreateEmptyProfilerTable = import("/lua/shared/Profiler.lua").CreateEmptyProfilerTable
local DebugFunction = import("/lua/shared/Profiler.lua").DebugFunction
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
local benchmarkThread = false
--- Data that we send over to the UI
local data = CreateEmptyProfilerTable()
--- How many times each benchmark is run
local benchmarkRuns = 30
local tests = {}

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

function FindBenchmarks(army)
    SPEW("Benchmarks have been searched for by army: " .. tostring(army))

    local categories = {}
    local categoryCount = 0

    local function AddBenchmarksFromFolder(path)
        local files = DiskFindFiles(path, "*.lua")

        for _, file in files do
            -- retrieve category file
            local category = import(file)

            categoryCount = categoryCount + 1
            if table.empty(category) then
                -- add faulty category
                categories[categoryCount] = {
                    folder = path,
                    file = file,
                    benchmarks = {},
                    faulty = true,
                    name = "",
                    desc = "Error opening file",
                }
                continue
            end
            -- retrieve benchmarks in category file
            local benchmarks = {}
            local benchmarkCount = 0
            local catName = ""
            local catDesc = ""
            local localExclude = {}
            local benchmarkTitles = {}
            local benchmarkDescs = {}
            -- can't just pull these values because it'll throw an error if they don't exist
            for k, val in category do
                if k == "CategoryDisplayName" then
                    if type(val) == "string" then
                        catName = val
                    end
                    continue
                end
                if k == "CategoryDescription" then
                    if type(val) == "string" then
                        catDesc = val
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
                        if type(funData) == "string" then
                            benchmarkTitles[funName] = funData
                        elseif type(funData) == "table" then
                            local funTitle = funData.name
                            if funTitle and type(funTitle) == "string" then
                                benchmarkTitles[funName] = funTitle
                            end
                            local funDesc = funData.desc
                            if funDesc and type(funDesc) == "string" then
                                benchmarkDescs[funName] = funDesc
                            end
                        end
                    end
                    continue
                end
                if k == "Exclude" then
                    for excludeName, doExclude in val do
                        if type(excludeName) == "string" and doExclude then
                            localExclude[excludeName] = true
                        end
                    end
                    continue
                end
            end

            local functions = {}
            for funName, benchmark in category do
                -- exclude these functions
                if benchmarkExcludeFunctions[funName] or localExclude[funName] then
                    continue
                end

                -- only look at functions
                if type(benchmark) == "function" then
                    -- add correct entry
                    benchmarkCount = benchmarkCount + 1
                    benchmarks[benchmarkCount] = {
                        name = funName,
                        title = benchmarkTitles[funName] or "",
                        desc = benchmarkDescs[funName] or "",
                    }
                    functions[benchmarkCount] = benchmark
                end
            end

            -- add correct category
            categories[categoryCount] = {
                folder = path,
                file = file,
                benchmarks = benchmarks,
                faulty = false,
                name = catName,
                desc = catDesc,
            }
            tests[categoryCount] = functions
        end
    end

    -- add benchmarks from base game
    AddBenchmarksFromFolder("/lua/benchmarking/benchmarks")

    -- TODO: add mod support
    -- - scan active mods for a 'benchmarks' folder
    -- - add benchmarks from that folder

    -- sync it over
    Sync.Benchmarks = categories
    benchmarkThread = false
end

function RunBenchmark(fileIndex, benchmarkIndex)
    if not benchmarkThread then
        benchmarkThread = ForkThread(RunBenchmarkThread, fileIndex, benchmarkIndex)
    else
        SPEW("Already running benchmark")
    end
end

function RunBenchmarkThread(fileIndex, benchmarkIndex)
    -- keep track of all output
    local output = {}
    local test = tests[fileIndex][benchmarkIndex]

    if test == nil then
        WARN("Can't run benchmark " .. fileIndex .. "," .. benchmarkIndex)
        Sync.BenchmarkOutput = {success = false}
        return
    end

    -- run benchmark multiple times
    for k = 1, benchmarkRuns do
        output[k] = test()
    end

    -- outliers are created by the garbage collector kicking in
    local trimmed, size = Statistics.StatObject(output, benchmarkRuns):RemoveOutliers()

    output = { samples = size, data = trimmed, success = true }

    -- sync to UI
    Sync.BenchmarkOutput = output
    benchmarkThread = false
    SPEW("Done with benchmark")
end
