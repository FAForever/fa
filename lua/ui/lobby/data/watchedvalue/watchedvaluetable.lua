local WatchedValue = import("/lua/ui/lobby/data/watchedvalue/watchedvalue.lua")

-- A version of the builtin "next" function that unboxes WatchedValues. Useful for making iteration
-- over WatchedValueTables work.
local nextUnbox = function(t, k)
    -- Get the next boxed value.
    local nextKey, nextValue = next(t, k)

    -- Skip over "gaps"
    while nextValue and nextValue() == nil do
        nextKey, nextValue = next(t, nextKey)
    end

    -- No more keys in _store.
    if nextValue == nil then
        return nextKey, nil
    end

    -- Unbox the value.
    return nextKey, nextValue()
end

LoggingEnabled = false
LoggedChanges = {}

--- A flat, fixed-keyset table eagerly populated with WatchedValues
---@class WatchedValueTable
WatchedValueTable = ClassSimple {
    __init = function(self, initialMapping)
        -- Where the values are really stored (__index and friends only apply if the keys are absent)
        -- We hide this away in the closure of the metatable.
        local _store = {}
        if LoggingEnabled then
            table.print(initialMapping, 'WatchedValueTable initialMapping')
        end

        -- Explicitly track the keyset so we can iterate our keys without having to worry about
        -- iterating over closures. Also hidden away in closures to avoid changing the keyset
        -- of the real table.
        local _keyset = {}

        local WatchedMetaTable = {
            -- Get a value from a WatchedValueTable
            __index = function(wvt, key)
                -- limit logging only to changes of the WatchedValueTable
                local value = _store[key]
                if LoggingEnabled then
                    local msg = 'WatchedValueTable __index function(wvt, ' .. repr(key) .. ') '  .. tostring(value)
                    if not LoggedChanges[msg] then
                        LoggedChanges[msg] = true
                        LOG(msg)
                    end
                end
                return value()
            end,

            -- Insert to a wvt. Triggers the event listener on the WatchedValue.
            __newindex = function(wvt, key, value)
                _store[key]:Set(value)
            end,

            __keyset = function()
                return _keyset
            end
        }

        -- Prepare a table with the keyset and default values given by the default mapping.
        for k, value in pairs(initialMapping) do
            _store[k] = WatchedValue.Create(value)
            table.insert(_keyset, k)
        end

        -- Create instance methods that depend on _store and _keyset

        -- Provide an iterator equivalent to pairs(), but hiding the Watched-Value-ness.
        self.pairs = function(this)
            return nextUnbox, _store, nil
        end

        self.isEmpty = function(this)
            return table.empty(_store)
        end

        -- Return a boring normal table containing the same mappings as this lazy table.
        self.AsTable = function(this)
            local result = {}

            local keyset = _keyset
            for k, v in pairs(keyset) do
                result[v] = this[v]
            end

            return result
        end

        self.print = function(this)
            local keyset = _keyset
            for k, v in pairs(keyset) do
                if "table" == type(v) then
                    WARN(k .. "=")
                    table.print(v)
                else
                    WARN(k .. "=" .. tostring(v))
                end
            end
        end

        setmetatable(self, WatchedMetaTable)
    end,
}
