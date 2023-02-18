-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- Configuration file to globally control how Lua behaves

---@declare-global
---@diagnostic disable:lowercase-global
--====================================================================================
-- Disable the LuaPlus bit where you can add attributes to nil, booleans, numbers, and strings.
--------------------------------------------------------------------------------------
local function metacleanup(obj)
    local name = type(obj)
    local mmt = {
        __newindex = function(_, key, _)
            error(("Attempt to set attribute '%s' on %s"):format(tostring(key), name), 2)
        end,
        --__index = function(table,key)
        --    error(string.format("Attempt to get attribute '%s' on %s", tostring(key), name), 2)
        --end
    }
    setmetatable(getmetatable(obj), mmt)
end

metacleanup(nil)
metacleanup(false)
metacleanup(0)
metacleanup('')

--====================================================================================
-- Set up a metatable for coroutines (a.k.a. threads)
--------------------------------------------------------------------------------------
local thread_mt = {Destroy = KillThread}
thread_mt.__index = thread_mt
function thread_mt.__newindex(_, _, _)
    error('Attempt to set an attribute on a thread', 2)
end
setmetatable(getmetatable(coroutine.create(function()end)), thread_mt)


--====================================================================================
-- Replace math.random with our custom random.  On the sim side, this is
-- a rng with consistent state across all clients.
--------------------------------------------------------------------------------------
if Random then
    math.random = Random
end


--====================================================================================
-- Give globals an __index() with an error function. This causes an error message
-- when a nonexistent global is accessed, instead of just quietly returning nil.
--------------------------------------------------------------------------------------
local globalsmeta = {
    __index = function(_, key)
        error("access to nonexistent global variable " .. repr(key), 2)
    end
}
setmetatable(_G, globalsmeta)


-- If the item is callable like a function, it is returned. Otherwise, nil is returned.
---@generic T
---@param f T
---@return T?
function iscallable(f)
    local tt = type(f)
    if tt == 'function' or tt == 'cfunction' then
        return f
    end
    if tt == 'table' and getmetatable(f).__call then
        return f
    end
end
