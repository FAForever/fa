
--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

---@alias ProfilerSource "C" | "Lua" | "main" | "unknown"

---@class ProfilerData
---@field C ProfilerSourceData
---@field Lua ProfilerSourceData
---@field main ProfilerSourceData
---@field unknown ProfilerSourceData

---@alias ProfilerScope "field" | "global" | "local" | "method" | "other" | "upvalue"

---@class ProfilerSourceData
---@field global ProfilerScopeData
---@field upval  ProfilerScopeData
---@field local  ProfilerScopeData
---@field method ProfilerScopeData
---@field field  ProfilerScopeData
---@field other  ProfilerScopeData

---@alias ProfilerScopeData ProfilerFunctionData[]

---@alias ProfilerField "growth" | "name" | "nameLower" | "scope" | "source" | "value"

---@class ProfilerFunctionData
---@field growth number
---@field name string
---@field nameLower string
---@field scope string
---@field source string
---@field value number

---@class ProfilerGrowth
---@field C table<string, number>
---@field Lua table<string, number>
---@field main table<string, number>
---@field unknown table<string, number>

---@class BenchmarkModuleMetadataFormat
---@field BenchmarkData? table<string, BenchmarkMetadataFormat | string>
---@field Exclude? table<string, boolean>
---@field ModuleDescription? string
---@field ModuleName? string defaults to the file name
---@field ModuleSort? number defaults to `0`
---@field NotBenchmarkModule? boolean

---@class BenchmarkMetadataFormat
---@field desc? string
---@field exclude? boolean
---@field name? string defaults to the function name
---@field sort? number defaults to `0`


--- Constructs an empty table that the profiler can populate
---@return ProfilerData
function CreateEmptyProfilerTable() 
    return {
        Lua = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        C = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        main = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        unknown = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
    }
end

-- the profiler benchmarks must be guarded so that players can't maliciously send requests
local devs = {"jip", "hdt80bro"}
---@param player Army | AIBrain | string
---@return boolean
function PlayerIsDev(player)
    local t = type(player)
    if t == "number" then -- army
        player = ArmyBrains[player].Nickname:lower()
    elseif t ~= "string" then -- AIBrain
        player = player.Nickname:lower()
    end
    for _, dev in devs do
        if player == dev then
            return true
        end
    end
    return false
end
