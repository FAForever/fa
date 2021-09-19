
local directory = "/lua/profiler/benchmarks"

local FunctionsToExclude = {
      "import"
    , "ComputePoint"
}

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

                    LOG("Done running " .. func .. " of file " .. file)
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
        LOG(repr(results))
    end
end

function RunIndividualBenchmark(file, func)

    local results = { }
    results[file] = { }

    LOG("Running " .. func .. " of file " .. file)

    -- import the benchmark
    local benchmark = import(file)[func]

    -- retrieve code and information
    local code = debug.listcode(benchmark)
    local numparams = code.numparams
    local maxstack = code.maxstack

    -- keep byte code clean
    code.numparams = nil 
    code.maxstack = nil

    -- add information for UI / interaction
    results[file][func] = {
          Time = benchmark()
        , Code = code
        , NumParams = numparams
        , MaxStack = maxstack
        , File = file
        , Function = func
    }

    LOG("Done running " .. func .. " of file " .. file)

    -- send it to the ui
    Sync.Profiler = Sync.Profiler or { }
    Sync.Profiler.Benchmarks = results

    -- if we do not have the profiler enabled
    if log then 
        LOG(repr(results))
    end
end