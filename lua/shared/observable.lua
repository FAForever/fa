
-- implementation of the observable pattern as described on:
--  - https://en.wikipedia.org/wiki/Observer_pattern

-- upvalue for performance
local TableInsert = table.insert

-- setup for a basic meta table

--- Object that connects callbacks with data updates
---@class Observer<T>
---@field Listeners table<string|integer, fun(val: T)>
local ObservableMeta = {}
ObservableMeta.__index = ObservableMeta

--- Adds an observer that is updated when the value is subject is set.
---@generic T
---@param self Observer<T>
---@param callback fun(val: T) | nil A function that receives the value as its first argument.
---@param name? string Optional name to be able to reference the callback later on
function ObservableMeta:AddObserver(callback, name)
    if name then
        self.Listeners[name] = callback
    else
        TableInsert(self.Listeners, callback)
    end
end

--- Sets the value of the subject and notifies all observers with the updated value.
---@generic T
---@param self Observer<T>
---@param value T
function ObservableMeta:Set(value)
    for k, callback in self.Listeners do
        callback(value)
    end
end

--- Constructs an observable as described by the observable pattern
---@return Observer
function Create()
    local observable = {
        Listeners = {},
    }
    setmetatable(observable, ObservableMeta)

    return observable
end