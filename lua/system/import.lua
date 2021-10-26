-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- Implement import()

--- Table of all loaded modules, indexed by name.
__modules = {}

--- Common metatable used by all modules, which forwards global references to _G
__module_metatable = {
    __index = _G
}

-- upvalue globals for performance
local LOG = LOG
local SPEW = SPEW
local WARN = WARN
local error = error
local setmetatable = setmetatable
local pcall = pcall
local FileCollapsePath = FileCollapsePath

-- upvalue string functions for performance
local StringLower = string.lower
local StringSub = string.sub

-- upvalue table operations for performance
local TableInsert = table.insert 

-- these values can be adjusted by hooking into this file
local informDevOfLoad = false

--- The global import function used to keep track of modules.
-- @param name The path to the module to load.
function import(name)

    -- caching: if it exists then we return the previous version
    name = StringLower(name)
    local existing = __modules[name]
    if existing then
        return existing
    end

    -- inform the devs that we're loading this module (todo: remove?)
    if informDevOfLoad then 
        SPEW("Loading module '", name, "'")
    end
    
    -- set up an environment for the new module
    local env
    env = {
        __moduleinfo = { name = name, used_by = {}, track_imports = true },

        -- Define a new 'import' function customized for the module, to track import dependencies.
        import = function(name2)
            if StringSub(name2,1,1)!='/' then
                name2 = FileCollapsePath(name .. '/../' .. name2)
            end
            local m2 = import(name2) -- this will use the global import
            if env.__moduleinfo.track_imports then
                m2.__moduleinfo.used_by[name] = true
            end
            return m2
        end,
    }

    -- set the meta table so that if it can't find an index it searches in _G
    setmetatable(env, __module_metatable)

    -- add ourselves to prevent loops
    __modules[name] = env

    -- try to add content to the environment
    local ok, msg = pcall(doscript, name, env)
    if not ok then
        -- we failed: report back
        __modules[name] = nil
        WARN(msg)
        error("Error importing '" .. name .. "'", 2)
    end

    -- Once we've imported successfully, stop tracking dependencies. This means that importing from
    -- within a function will not create a dependency, which is usually what you want. (You can
    -- explicitly set __moduleinfo.track_imports = true to switch tracking back on.)
    env.__moduleinfo.track_imports = false
    return env
end


-- Clear out a module from the table of loaded modules, so that on the next import attempt it will
-- get reloaded from scratch.
function dirty_module(name, why)
    local m = __modules[name]
    if m then
        if why then LOG("Module '", name, "' changed on disk") end
        LOG("  marking '",name,"' for reload")
        __modules[name] = nil
        local deps = m.__moduleinfo.used_by
        if deps then
            for k,_ in deps do
                dirty_module(k)
            end
        end
    end
end

TableInsert(__diskwatch, dirty_module)
