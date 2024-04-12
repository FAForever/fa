-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- Implement import()

-- note that actual modules cannot upvalued because upvalues are not reset when we load a save file
local FileCollapsePath = FileCollapsePath
local doscript = doscript
local pcall = pcall
local setmetatable = setmetatable

local LOG = LOG
local SPEW = SPEW
local WARN = WARN
local error = error

--- Table of all loaded modules, indexed by name.
__modules = {}
-- temporary place to store reloading modules
local oldModules = {}

--- Common metatable used by all modules, which forwards global references to _G
---@class Module
---@field __moduleinfo ModuleInfo
__module_metatable = {
    __index = _G
}

---@class ModuleInfo
---@field name string
---@field used_by table<string, true>
---@field track_imports boolean
---@field OnDirty? fun()
---@field OnReload? fun(newmod: Module)

-- these values can be adjusted by hooking into this file
local informDevOfLoad = false

---Load a module
---@param module Module
---@return Module
local function LoadModule(module)
    local modules = __modules

    local moduleinfo = module.__moduleinfo
    local name = moduleinfo.name

    -- inform the devs that we're loading this module for the first time
    if informDevOfLoad then
        SPEW("Loading module '", name, "'")
    end

    -- make any old data available to the new one while it reloads
    local oldMod = oldModules[name]
    if oldMod then
        moduleinfo.old = oldMod
    end

    setmetatable(module, __module_metatable)

    -- try to add content to the environment
    local ok, msg = pcall(doscript, name, module)
    if oldMod then
        -- now clear the old module
        oldModules[name] = nil
        moduleinfo.old = nil
        -- let the old module load data into the new one, if they'd prefer to do it that way
        local onReload = oldMod.__moduleinfo.OnReload
        if onReload then
            onReload(module)
        end
    end

    if not ok then
        -- we failed: report back
        modules[name] = nil
        WARN(msg)
        error("Error importing '" .. name .. "'", 2)
    end

    -- Once we've imported successfully, stop tracking dependencies. This means that importing from
    -- within a function will not create a dependency, which is usually what you want. (You can
    -- explicitly set __moduleinfo.track_imports = true to switch tracking back on.)
    moduleinfo.track_imports = false
    return module

end

local __lazyimport_metatable = {
    __index = function(tbl, key)
        LoadModule(tbl)
        return tbl[key]
    end,

    __newindex = function(tbl, key, val)
        LoadModule(tbl)
         tbl[key]=val
    end,
}

local indent = 0

---The global import function used to keep track of modules
---@param name FileName path to the module to load
---@param isLazy boolean?
---@return Module
function import(name, isLazy)
    local modules = __modules -- global to local

    -- attempt to find the module without lowering the string
    local existing = modules[name]
    if existing then
        return existing
    end

    -- caching: if it exists then we return the previous version
    name = name:lower()
    existing = modules[name]
    if existing then
        return existing
    end

    SPEW(string.format("%sLoading module: %s", string.rep("-> ", indent) or "", name))
    indent = indent + 1

    ---@type ModuleInfo
    local moduleinfo = {
        name = name,
        used_by = {},
        track_imports = true,
    }

    -- Define a new 'import' function customized for the module, to track import dependencies
    local _import = function(name2, isLazy)
        if name2:sub(1, 1) != '/' then
            name2 = FileCollapsePath(name .. '/../' .. name2)
        end
        local module2 = import(name2, isLazy) -- this will use the global import
        if __modules[name].__moduleinfo.track_imports then
            module2.__moduleinfo.used_by[name] = true
        end
        return module2
    end

    -- set up an environment for the new module
    ---@type Module
    local module = {
        __moduleinfo = moduleinfo,
        import = _import,
        lazyimport = function (name2)
            return _import(name2, true)
        end
    }
    -- add ourselves to prevent loops
    modules[name] = module

    if isLazy then
        -- make lazy
        setmetatable(module, __lazyimport_metatable)
    else
        -- load immediately if said so
        LoadModule(module)
    end

    indent = indent - 1

    return module
end

---Returns the lazy module instance which is gonna be loaded when being indexed
---@param name FileName
---@return Module
function lazyimport(name)
    return import(name, true)
end

-- Clear out a module from the table of loaded modules, so that on the next import attempt it will
-- get reloaded from scratch
function dirty_module(name, why)
    local modules = __modules
    local module = modules[name]
    if module then
        if why then LOG("Module '", name, "' changed on disk") end
        LOG("  marking '", name, "' for reload")

        local moduleinfo = module.__moduleinfo
        -- allow us to run code when a module is ejected
        local onDirty = moduleinfo.OnDirty
        if onDirty then
            local ok, msg = pcall(onDirty)
            if not ok then
                WARN(msg)
            end
        end
        oldModules[name] = module

        modules[name] = nil
        local deps = moduleinfo.used_by
        if deps then
            for k, _ in deps do
                dirty_module(k)
            end
        end
    end
end

table.insert(__diskwatch, dirty_module)