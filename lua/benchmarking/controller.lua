
local directory = "/lua/benchmarking/benchmarks"

local FunctionsToExclude = {
      "import"
    , "lazyimport"
    , "ComputePoint"
}

---@param log boolean # Log to the game log if the profiler isn't enabled
function RunAllBenchmarks(log)
    
    -- capture in local scope
    local import = import
    local type = type 

    -- find all benchmark files
    local files = DiskFindFiles(directory, "*.lua")
    
    local results = { }

    -- import them
    for k, file in files do 

        coroutine.yield(1)

        results[file] = { }

        -- load in the benchmark and run them
        local benchmark = import(file)
        for e, element in benchmark do 

            if not table.find(FunctionsToExclude, e) then 
                if type(element) == "function" then 
                    LOG("Running " .. e .. " of file " .. file)

                    -- retrieve code and information
                    local code = debug.listcode(element)
                    local numparams = code.numparams
                    local maxstack = code.maxstack

                    -- keep byte code clean
                    code.numparams = nil 
                    code.maxstack = nil

                    -- add information for UI / interaction
                    results[file][e] = {
                          Time = element()
                        , Code = code
                        , NumParams = numparams
                        , MaxStack = maxstack
                        , File = file
                        , Function = e
                    }

                    LOG("Done running " .. e .. " of file " .. file)
                end
            end
        end
    end

    LOG("Done running benchmarks")

    -- send it to the ui
    Sync.Profiler = Sync.Profiler or { }
    Sync.Profiler.Benchmarks = results

    -- if we do not have the profiler enabled
    if log then 
        LOG(repr(results, {depth = 4}))
    end
end

---@param pattern FileName # pattern inside "/lua/benchmarking/benchmarks" to look for and run 1 file
---@param log boolean # Log to the game log if the profiler isn't enabled
function RunIndividualBenchmark(pattern, log)

    local file = DiskFindFiles(directory, pattern)

    if not file[1] then
        error("Could not find any benchmark using the pattern " .. tostring(pattern))
    end

    local results = { }
    results[file] = { }
    -- load in the benchmark and run them
    local benchmark = import(file[1])
    for e, element in benchmark do
        if not table.find(FunctionsToExclude, e) then 
            if type(element) == "function" then 
                LOG("Running " .. e .. " of file " .. file[1])

                -- retrieve code and information
                local code = debug.listcode(element)
                local numparams = code.numparams
                local maxstack = code.maxstack

                -- keep byte code clean
                code.numparams = nil 
                code.maxstack = nil

                -- add information for UI / interaction
                results[file][e] = {
                      Time = element()
                    , Code = code
                    , NumParams = numparams
                    , MaxStack = maxstack
                    , File = file[1]
                    , Function = e
                }

                LOG("Done running " .. e .. " of file " .. file[1])
            end
        end
    end

    -- send it to the ui
    Sync.Profiler = Sync.Profiler or { }
    Sync.Profiler.Benchmarks = results

    -- if we do not have the profiler enabled
    if log then
        LOG(repr(results, {depth = 4}))
    end
end