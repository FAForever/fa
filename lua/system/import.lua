-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- Implement import()


-- Table of all loaded modules, indexed by name.
__modules = {}


-- Common metatable used by all modules, which forwards global references to _G
__module_metatable = {
    __index = _G
}

function import(name)

    -- First check if the module already exists
    name = string.lower(name)
    local existing = __modules[name]
    if existing then
        return existing
    end

    SPEW("Loading module '", name, "'")
    
    -- Set up an environment for the new module
    local env
    env = {
        __moduleinfo = { name = name, used_by = {}, track_imports = true },

        -- Define a new 'import' function customized for the module, to track import dependencies.
        import = function(name2)
            if string.sub(name2,1,1)!='/' then
                name2 = FileCollapsePath(name .. '/../' .. name2)
            end
            local m2 = import(name2) -- this will use the global import
            if env.__moduleinfo.track_imports then
                m2.__moduleinfo.used_by[name] = true
            end
            return m2
        end,
    }
    setmetatable(env, __module_metatable)

    __modules[name] = env

    local ok, msg = pcall(doscript, name, env)
    if not ok then
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


table.insert(__diskwatch, dirty_module)
