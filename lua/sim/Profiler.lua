
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
local benchmarkRuns = 30
local benchmarkModules
-- The target time for how we adjust to how many samples of a benchmark we run
local benchmarkTargetTime = 0.5
-- A list of functions that set the baseline loop time for function's that have the same number of
-- parameters as the index 
local benchmarkBaselines

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
---@field descriptions table<string, string>
---@field excludeFunctions table<string, true>
---@field file string
---@field moduleDescription string
---@field moduleName string
---@field moduleSort number
---@field path string
---@field sort table<string, number>
---@field titles table<string, string>

---@class BenchmarkModuleLoader
---@field benchmarkSorter fun(a: {name: string}, a: {name: string}): boolean
---@field benchmarkSort table<string, number>
---@field loopBaseline function[]
---@field moduleCount number
---@field modulesSim table[]
---@field modulesUser table[]
---@field moduleSort table<string, number>
---@field moduleSorter fun(a: {file: string, path: string}, a: {file: string, path: string}): boolean
---@field path string
BenchmarkModuleLoader = Class() {
    excludeFunctions = {
        import = true,
        __moduleinfo = true,
    };

    __init = function(self, path)
        self.path = path
        self.modulesUser = {}
        self.modulesSim = {}
        self.moduleCount = 0
        self.moduleSort = {}
        self.moduleSorter = self:NewModuleSorter "moduleSort"
        self.benchmarkSorter = self:NewBenchmarkSorter "benchmarkSort"
        -- loop baselines to subtract the time from
        self.loopBaseline = {}
    end;

    -- sorts by the `name` field, but first it groups by the `sort` field
    -- (1) Positive sorts (closer to zero first)
    -- (2) Zero sorts (the default)
    -- (3) Negative sorts (closer to zero first)
    ---@param self BenchmarkModuleLoader
    ---@param sortTableName string field in the class to pull sort values out by name
    ---@return fun(a: {name: string}, b: {name: string}): boolean
    NewBenchmarkSorter = function(self, sortTableName)
        return function(a, b)
            local aname = a.name
            local bname = b.name
            local benchmarkSort = self[sortTableName]
            if benchmarkSort then
                local asort = benchmarkSort[aname] or 0
                local bsort = benchmarkSort[bname] or 0
                if asort ~= bsort then
                    if asort > 0 then
                        return bsort <= 0 or asort < bsort
                    else
                        return bsort < 0 and asort > bsort
                    end
                end
            end
            return aname:lower() < bname:lower()
        end
    end;

    -- same as benchmark sorter, but groups by `path` first, then `sort`, then `file`
    ---@param self BenchmarkModuleLoader
    ---@param sortTableName string field in the class to pull sort values out by file
    ---@return fun(a: {file: string, path: string}, b: {file: string, path: string}): boolean
    NewModuleSorter = function(self, sortTableName)
        return function(a, b)
            local apath = a.path
            local bpath = b.path
            if apath ~= bpath then
                return apath < bpath
            end
            local afile = a.file
            local bfile = b.file
            local moduleSort = self[sortTableName]
                if moduleSort then
                local asort = moduleSort[afile] or 0
                local bsort = moduleSort[bfile] or 0
                if asort ~= bsort then
                    if asort > 0 then
                        return bsort <= 0 or asort < bsort
                    else
                        return bsort < 0 and asort > bsort
                    end
                end
            end
            return afile:lower() < bfile:lower()
        end
    end;

    FormatBenchmarkData = function(self, metadata, funName, fn)
        -- exclude these functions
        if self.excludeFunctions[funName] or metadata.excludeFunctions[funName] then
            return
        end
        return {
            name = funName,
            title = metadata.titles[funName] or "",
            description = metadata.descriptions[funName] or "",
        }, {
            name = funName,
            fn = fn,
            parameters = debug.listcode(fn).numparams
        }
    end;

    ---@overload fun(self: BenchmarkModuleLoader, module: Module, metadata: BenchmarkModuleMetadata, error: string)
    ---@param self BenchmarkModuleLoader
    ---@param module Module
    ---@param metadata BenchmarkModuleMetadata
    ---@param benchmarksUser table
    ---@param benchmarksSim table
    ---@return table moduleUser
    ---@return table moduleSim
    FormatModuleData = function(self, module, metadata, benchmarksUser, benchmarksSim)
        local path, file = metadata.path, metadata.file
        if not benchmarksSim then
            return {
                benchmarks = {},
                description = benchmarksUser, -- hold the error message
                file = file,
                path = path,
                faulty = true,
                name = metadata.moduleName,
            }, {
                file = file,
                path = path,
                benchmarks = {},
            }
        end
        return {
            benchmarks = benchmarksUser,
            description = metadata.moduleDescription,
            file = file,
            path = path,
            faulty = false,
            name = metadata.moduleName,
        }, {
            benchmarks = benchmarksSim,
            file = file,
            path = path,
        }
    end;

    ---@param module Module
    ---@return BenchmarkModuleMetadata?
    PullBenchmarkModuleMetadata = function(self, module)
        local descriptions = {}
        local excludeFunctions = {}
        local moduleName = ""
        local moduleDesc = ""
        local moduleSort = 0
        local sortOrder = {}
        local titles = {}
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
            if k == "ModuleSort" then
                if type(val) == "number" then
                    moduleSort = val
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
                        titles[funName] = funData
                    -- otherwise, it's a table of metdata on the benchmark 
                    elseif type(funData) == "table" then
                        local funTitle = funData.name
                        if funTitle and type(funTitle) == "string" then
                            titles[funName] = funTitle
                        end
                        local funDesc = funData.desc
                        if funDesc and type(funDesc) == "string" then
                            descriptions[funName] = funDesc
                        end
                        local funExc = funData.exclude
                        if funExc and type(funExc) == "boolean" then
                            excludeFunctions[funName] = true
                        end
                        local funSort = funData.sort
                        if funSort and type(funSort) == "number" then
                            sortOrder[funName] = funSort
                        end

                        local funLoop = funData.__loop_baseline
                        if funLoop and math.ceil(funLoop) >= 0 then
                            self.loopBaseline[math.ceil(funLoop)] = module[funName]
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
                        excludeFunctions[excludeName] = true
                    end
                end
                continue
            end
        end
        return {
            descriptions = descriptions,
            excludeFunctions = excludeFunctions,
            moduleName = moduleName,
            moduleDescription = moduleDesc,
            moduleSort = moduleSort,
            sort = sortOrder,
            titles = titles,
        }
    end;

    ---@param file string
    ---@return Module? module
    ---@return BenchmarkModuleMetadata? metadata
    ---@return string? error
    LoadBenchmarkModule = function(self, path, file)
        -- **le sigh**   this doesn't catch any errors inside `doscript`, only explicit Lua errors
        local ok, obj = pcall(import, file)
        if ok then
            -- we can still check to see if the module is empty, which only probably means that it failed
            local notEmpty = table.getsize(obj) > table.getsize(self.excludeFunctions)
            if notEmpty or true then
                local metadata = self:PullBenchmarkModuleMetadata(obj)
                metadata.path = path
                metadata.file = file
                return obj, metadata
            end
            WARN("Skipping empty benchmark module \"" .. file .. "\"; there's likely a 'WARNING: SCR_LuaDoFileConcat' right above me'")
            return obj, nil
        end
        WARN("Couldn't load benchmark module \"" .. file .. "\": " .. obj)
        return nil, {}, obj
    end;

    AddBenchmarkModule = function(self, path, file)
        -- retrieve benchmark module
        local module, metadata, error = self:LoadBenchmarkModule(path, file)
        if not metadata then
            return -- the file isn't a benchmark
        end
        self.moduleSort[file] = metadata.moduleSort
        local moduleCount = self.moduleCount + 1
        self.moduleCount = moduleCount

        if error then
            -- add faulty category
            local modulesUser, modulesSim = self.modulesUser, self.modulesSim
            modulesUser[moduleCount], modulesSim[moduleCount] = self:FormatModuleData(module, metadata, error)
            return
        end

        local benchmarksUser = {}
        local benchmarksSim = {}
        local benchmarkCount = 0

        for funName, fn in module do
            -- only look at functions
            if type(fn) == "function" then
                local benchmarkUser, benchmarkSim = self:FormatBenchmarkData(metadata, funName, fn)
                -- add correct entry
                if benchmarkUser and benchmarkSim then
                    benchmarkCount = benchmarkCount + 1
                    benchmarksUser[benchmarkCount] = benchmarkUser
                    benchmarksSim[benchmarkCount] = benchmarkSim
                end
            end
        end

        self.benchmarkSort = metadata.sort -- load sorting data into `BenchmarkSorter`
        local benchmarkSorter = self.benchmarkSorter
        table.sort(benchmarksUser, benchmarkSorter)
        table.sort(benchmarksSim, benchmarkSorter)

        local modulesUser, modulesSim = self.modulesUser, self.modulesSim
        modulesUser[moduleCount], modulesSim[moduleCount] = self:FormatModuleData(module, metadata, benchmarksUser, benchmarksSim)
    end;

    FindBenchmarkModules = function(self, location)
        local path = (location or "") .. self.path
        for _, file in DiskFindFiles(path, "*.lua") do
            self:AddBenchmarkModule(path, file)
        end
    end;

    SortModules = function(self)
        table.sort(self.modulesUser, self.moduleSorter)
        table.sort(self.modulesSim, self.moduleSorter)
    end;
}

function FindBenchmarks(army)
    SPEW("Benchmarks have been searched for by army: " .. tostring(army))

    local loader = BenchmarkModuleLoader("/lua/benchmarks")

    -- add benchmarks from base game
    loader:FindBenchmarkModules()

    -- add benchmarks from mods
    for _, mod in __active_mods do
        loader:FindBenchmarkModules(mod.location)
    end

    loader:SortModules()

    -- sync it over
    Sync.BenchmarkModules = loader.modulesUser
    benchmarkModules = loader.modulesSim
    benchmarkBaselines = loader.loopBaseline
end

function RunBenchmark(fileIndex, benchmarkIndex, parameters)
    if not benchmarkThread then
        local moduleData = benchmarkModules[fileIndex]
        LOG("Running benchmark \"" .. tostring(moduleData.benchmarks[benchmarkIndex].name) .. "\" in file " .. tostring(moduleData.file))
        benchmarkThread = ForkThread(RunBenchmarkThread, fileIndex, benchmarkIndex, parameters)
    else
        SPEW("Already running benchmark")
    end
end

function StopBenchmark()
    SPEW("Stopping benchmark")
    benchmarkThread = false
end

function RunBenchmarkThread(fileIndex, benchmarkIndex, parameters)
    -- the threshold time for a benchmark to start running more than once a tick
    local tickThreshold = 0.09

    local benchmark = benchmarkModules[fileIndex].benchmarks[benchmarkIndex]
    if benchmark == nil then
        WARN("Can't run benchmark " .. tostring(fileIndex) .. "," .. tostring(benchmarkIndex))
        Sync.BenchmarkOutput = {success = false}
        return
    end
    local test = benchmark.fn
    local parameterCount = benchmark.parameters
    if table.getn(parameters) ~= parameterCount then
        WARN("Running benchmark with fewer parameters than expected")
    end

    -- baseline loop adjustment
    local baselineLoop = benchmarkBaselines[parameterCount]
    if baselineLoop == test then -- don't test ourself!
        baselineLoop = nil
    end

    -- initial benchmark sample time to scale sample rate based on
    -- we'll also use the sample as output
    local output = test(unpack(parameters))
    local time = output
    local adjust = 0
    if baselineLoop then
        adjust = baselineLoop(unpack(parameters))
        output = output - adjust
    end

    -- calculate how many at a time and for how many ticks we should sample the benchmark
    local ticks = benchmarkRuns
    local atATime = 1

    local targetTime = benchmarkTargetTime
    if time > targetTime then
        ticks = 1
    else
        if time < tickThreshold then
            atATime = math.min(ticks, math.floor(tickThreshold / time))
            ticks = math.ceil(ticks / atATime)
        else
            ticks = math.ceil(ticks / time)
        end
    end

    -- run the rest of the samples this tick
    output = {output}
    local testNumber = 1
    for _ = 2, atATime do
        testNumber = testNumber + 1
        output[testNumber] = test(unpack(parameters)) - adjust
    end

    SPEW("Syncing " .. atATime .. "  " .. ticks)

    -- send over how many samples we're going to run
    Sync.BenchmarkProgress = {complete = atATime, runs = ticks * atATime}

    -- check to make sure we haven't been stopped
    if benchmarkThread then
        -- run benchmark multiple times (remember, we've already done the first tick)
        for _ = 2, ticks do
            WaitTicks(1)
            -- if we've been stopped, return early
            if not benchmarkThread then
                break
            end

            -- recalculate each tick in case the system strain changes
            if baselineLoop then
                adjust = baselineLoop(unpack(parameters))
            end
            for _ = 1, atATime do
                testNumber = testNumber + 1
                output[testNumber] = test(unpack(parameters)) - adjust
            end

            Sync.BenchmarkProgress = {complete = atATime}
        end
    end

    -- outliers are created by the garbage collector kicking in
    local trimmed, size = Statistics.StatObject(output):RemoveOutliers()

    -- sync to UI
    Sync.BenchmarkOutput = { samples = size, data = trimmed, success = true }
    benchmarkThread = false
    SPEW("Done with benchmark")
end
