
-- implementation of the observable pattern as described on:
--  - https://en.wikipedia.org/wiki/Observer_pattern

-- upvalue for performance
local TableInsert = table.insert

-- setup for a basic meta table
local ObservableMeta = {}
ObservableMeta.__index = ObservableMeta

--- Adds an observer that is updated when the value is subject is set.
-- @param callback A function that receives the value as its first argument.
function ObservableMeta:AddObserver(callback)
    TableInsert(self.Listeners, callback)
end

--- Sets the value of the subject and notifies all observers with the updated value.
function ObservableMeta:Set(value)
    for k, callback in self.Listeners do 
        callback(value)
    end
end



-- setup for a basic meta table
local ClassObservableMeta = {}
ClassObservableMeta.__index = ClassObservableMeta

--- Adds an observer that is updated when the value is subject is set
---@param methodName string name of method that receives the value
function ClassObservableMeta:AddObserver(methodName)
    TableInsert(self.Methods, methodName)
end

--- Sets the value of the subject and notifies all observer methods with the updated value
function ClassObservableMeta:Set(value)
    local object = self.Object
    for _, methodName in self.Methods do
        object[methodName](object, value)
    end
end


--- Constructs an observable as described by the observable pattern
function Create(obj)
    if obj then
        local observable = {
            Methods = {},
            Object = obj,
        }
        setmetatable(observable, ClassObservableMeta)

        return observable
    else
        local observable = {
            Listeners = {},
        }
        setmetatable(observable, ObservableMeta)

        return observable
    end
end