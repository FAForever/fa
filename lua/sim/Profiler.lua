
--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

-- Useful sources to read: 
-- https://www.lua.org/pil/23.1.html

local Statistics = import("/lua/shared/statistics.lua")
local CreateEmptyProfilerTable = import("/lua/shared/profiler.lua").CreateEmptyProfilerTable

-- upvalue for performance
local SPEW = SPEW
local sethook = debug.sethook
local getinfo = debug.getinfo

--- Keeps track of whether profiling has been toggled or not
local isProfiling = false

--- Thread to keep the simulation synced with the UI
local thread = false

--- Data that we send over to the UI
local data = CreateEmptyProfilerTable()

--- Toggles the profiler on / off
---@param army integer
---@param forceEnable boolean
function ToggleProfiler(army, forceEnable)

    -- Inform us in case of abuse
    SPEW("Profiler has been toggled on by army: " .. tostring(army))

    -- allows us to remain enabled
    if forceEnable and isProfiling then
        return
    end

    if not isProfiling then

        isProfiling = true

        -- Thread to sync information gathered to the UI
        if not thread then 
            thread = ForkThread(SyncThread)
        end

        -- Add a function to track
        sethook(function(event)

                -- quite expensive, returns a table
                local i = getinfo(2, "Sn")

                -- because of "n"
                -- i.name           = A reasonable name for the function
                -- i.namewhat       = What the previous field means. This field may be "global", "local", "method", "field", or "" (the empty string). The empty string means that Lua did not find a name for the function

                -- because of "S"
                -- i.source         = Where the function was defined. If the function was defined in a string (through loadstring), source is that string. If the function was defined in a file, source is the file name prefixed with a `@´
                -- i.short_src      = A short version of source (up to 60 characters), useful for error messages
                -- i.what           = What this function is. Options are "Lua" if foo is a regular Lua function, "C" if it is a C function, or "main" if it is the main part of a Lua chunk
                -- i.linedefined    = The line of the source where the function was defined

                -- count the function call
                local source = i.what or "unknown"
                local scope = i.namewhat or "other"
                local name = i.name or "lambda"

                -- prevent an empty scope
                if scope == "" then 
                    scope = "other"
                end

                -- if name == "lambda" then 
                --     local trace = repr(debug.traceback())
                --     if not traces[trace] or traces[trace] == 500 then
                --         traces[trace] = traces[trace] or 0  
                --         LOG(tostring(traces[trace]) .. ": " .. trace)
                --     end

                --     traces[trace] = traces[trace] + 1
                -- end

                -- keep track 
                local count = data[source][scope][name]
                if not count then 
                    data[source][scope][name] = 1
                else 
                    data[source][scope][name] = count + 1
                end

            end
            -- only track on function calls
            , "c")

    else
        isProfiling = false

        -- Inform us in case of abuse
        SPEW("Profiler has been toggled off by army: " .. tostring(army))

        -- nil removes tracking
        sethook(nil)
    end
end

local yield = coroutine.yield

function SyncThread()
    while true do

        if isProfiling then
            -- pass along the profiler information
            Sync.ProfilerData = data

            -- reset data collection
            data = CreateEmptyProfilerTable()
        end

        -- hold up a frame
        yield(1)
    end
end

local FunctionsToExclude = {
    ["import"] = true,
    ["__moduleinfo"] = true
}

---@param army integer
function FindBenchmarks(army)

    SPEW("Benchmarks have been searched for by army: " .. tostring(army))

    local categories = { }
    local head = 1

    local function AddBenchmarksFromFolder(path)
        local files = DiskFindFiles(path, "*.lua")

        for k, file in files do

            -- retrieve category file
            local category
            local ok, msg = pcall(
                function()
                    category = import(file)
                end
            )

            if ok then

                -- retrieve benchmarks in category file
                local benchmarks = { }
                local bHead = 1

                for k, benchmark in category do

                        -- exclude these functions
                        if FunctionsToExclude[k] then
                            continue
                        end

                    -- only look at functions
                    if type(benchmark) == "function" then

                        local code = debug.listcode(benchmark)
                        local maxstack = code.maxstack

                        -- add correct entry
                        benchmarks[bHead] = {
                                name = k
                            , code = code 
                            , maxstack = maxstack
                            , faulty = false
                            , message = ""
                        }

                        bHead = bHead + 1
                    else

                        -- add faulty entry
                        benchmarks[bHead] = {
                            name = k
                            , code = false 
                            , maxstack = false
                            , faulty = true
                            , message = "Not a Lua function"
                        }

                        bHead = bHead + 1
                    end
                end

                -- add correct category
                categories[head] = { folder = path, file = file, benchmarks = benchmarks, faulty = false, message = "" }
                head = head + 1
            else
                -- add faulty category
                categories[head] = { folder = path, file = file, benchmarks = { }, faulty = true, message = msg }
                head = head + 1
            end
        end
    end

    -- add benchmarks from base game
    AddBenchmarksFromFolder("/lua/benchmarking/benchmarks")

    -- TODO: add mod support
    -- - scan active mods for a 'benchmarks' folder
    -- - add benchmarks from that folder

    -- sync it over
    Sync.Benchmarks = categories
end

local benchmarkOutput = { }
local benchmarkRuns = 30

---@param info any
function RunBenchmarks(info)

    -- localize for performance
    local abs = math.abs

    -- keep track of all output
    local output = { }

    for k, element in info do

        -- import the benchmark
        local benchmark = import(element.file)[element.benchmark]

        -- run benchmark multiple times
        for k = 1, benchmarkRuns do
            benchmarkOutput[k] = benchmark()
        end

        -- compute deviation and filter outliers
        -- outliers are created by the garbage collector kicking in
        local mean = Statistics.Mean(benchmarkOutput, 30)
        local deviation = Statistics.Deviation(benchmarkOutput, 30, mean)

        local o = { }
        local c = 1 
        for k = 1, benchmarkRuns do 
            if abs(benchmarkOutput[k] - mean) < 2 * devation then
                o[c] = benchmarkOutput[k]
                c = c + 1
            end
        end

        -- store it
        output[element.file] = output[element.file] or { }
        output[element.file][element.benchmark] = { samples = c, data = o }
    end

    -- sync to UI
    Sync.BenchmarkOutput = output
end