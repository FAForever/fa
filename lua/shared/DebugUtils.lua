--- Resolve timer function to the sim or UI version
local GetTime = GetSystemTimeSecondsOnlyForProfileUse or GetSystemTimeSeconds

local function DebugLog(...)
    LOG('DebugUtils - ', unpack(arg))
end

local function mergeMetatables(mt1, mt2)
    mt1.__index = mt2.__index
end

local once
---@type metatable
local trackerMeta
trackerMeta = {
    __index = function(t, k)
        ---@type proxyTable.Tracker
        local tracker = t.__tracker
        local ret = tracker.target[k]
        table.insert(tracker.accesses, string.format('[%0f] Access "%s" and ret "%s" from %s'
        , GetTime()
        , tostring(k), tostring(ret), debug.traceback()
        ))
        -- if tracker == once or not once then
        --     if not once then
        --         once = tracker
        --     end
        --     DebugLog(string.format('[%0f] Access "%s" and ret "%s" from %s'
        --         , GetTime()
        --         , tostring(k), tostring(ret), debug.traceback()
        --     ))
        -- end
        return ret
    end,
    __newindex = function(t, k, v)
        ---@type proxyTable.Tracker
        local tracker = t.__tracker
        table.insert(tracker.assignments,
            string.format('[%0f] Assign "%s" as "%s" from %s'
            , GetTime()
            , tostring(k)
            , tostring(v)
            , debug.traceback()
        ))
        -- if tracker == once or not once then
        --     if not once then
        --         once = tracker
        --     end
        --     DebugLog(string.format('[%0f] %s: Assign "%s" as "%s" from %s'
        --         , GetTime()
        --         , tostring(t)
        --         , tostring(k)
        --         , tostring(v)
        --         , debug.traceback()
        --     ))
        --     -- DebugLog(repr(t))
        --     -- DebugLog('tracker', tracker)
        --     -- DebugLog('tracker.target', tracker.target)
        --     -- DebugLog('tracker.target[k]', tracker.target[k])
        -- end
        if type(v) == 'userdata' then
            -- user data needs to be set to tracker because 
            -- cscriptobject code rawgets the _c_object
            rawset(t, k, v)
        end
        tracker.target[k] = v
    end,
    __call = function (t, ...)
        local target = t.__tracker.target
        if iscallable(target) then
            local ret = t.__tracker.target(t, unpack(arg))
            if type(ret) == "table" then
                ReplaceTableWithTrackedTable(ret)
            end
            DebugLog(string.format('[%0f] %s: Call with args from %s'
                , GetTime()
                , tostring(t)
                , repr(arg)
                , debug.traceback()
            ))
            return ret
        else
            error(tostring(t) .. 'tried to call table ' .. tostring(t.__tracker.target))
        end
    end
}

local mtCache = {} ---@type table<table, metatable>

function ReplaceTableWithTrackedTable(t)
    local t2 = {}
    for k, v in t do
        t2[k] = v
        if type(v) ~= 'userdata' then --engine rawgets
            t[k] = nil
        end
    end
    ---@class proxyTable.Tracker
    t.__tracker = {
        accesses = {},
        assignments = {},
        target = t2,
    }
    t.__ProxyPrintAllData = function(self)
        local tracker = self.__tracker
        _ALERT(string.format('==== __ProxyPrintAllData ====\nTARGET: %s\nACCESSES: %s\nASSIGNMENTS: %s'
            , repr(tracker.target, {meta = true, depth = 2})
            , repr(tracker.accesses)
            , repr(tracker.assignments)
        ))
    end
    local mt = getmetatable(t)
    local newMt = mtCache[mt]
    if not newMt then
        newMt = table.copy(mt)
        newMt.__index = trackerMeta.__index
        newMt.__newindex = trackerMeta.__newindex
        newMt.__call = trackerMeta.__call
        mtCache[mt] = newMt
    end
    _setmetatable(t, newMt)
    _setmetatable(t2, mt)
    -- DebugLog('Replaced table ' .. tostring(t) .. ' with target ' .. tostring(t2))
    return t
end
