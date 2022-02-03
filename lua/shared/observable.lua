
-- upvalue for performance
local TableInsert = table.insert


-- setup for a basic meta table
local ObservableMeta = {}
ObservableMeta.__index = ObservableMeta

function ObservableMeta:AddObserver(callback)
    TableInsert(self.Listeners, callback)
end

--- Sets the value of the subject and notifies all observers with the updated value.
function ObservableMeta:Set(value)
    for k, callback in self.Listeners do 
        callback(value)
    end
end

--- Constructs an observable as described by the observable pattern
function Create()
    local observable = {}
    setmetatable(observable, ObservableMeta)

    observable.Listeners = { }

    return observable
end
