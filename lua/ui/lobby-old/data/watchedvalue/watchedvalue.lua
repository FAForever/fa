--- A value which dispatches an event when it is changed.
--- Similar to a LazyVar, but without the lazy-evaluation (so we don't need to store closures all
--- the time)
--- This also destroys the dependency system used by LazyVar. A WatchedValue cannot induce an `OnDirty`
--- on another WatchedValue (except explicitly in the caller's `OnDirty` handler).
---@class WatchedValue : Destroyable, OnDirtyListener
---@operator call: any
local WatchedValueMetaTable = {}

WatchedValueMetaTable.__index = WatchedValueMetaTable

function WatchedValueMetaTable:__call()
    return self.value
end

function WatchedValueMetaTable:Set(v)
    self.value = v
    local onDirty = self.OnDirty
    if onDirty then
        onDirty(self)
    end
end

function WatchedValueMetaTable:Destroy()
    self.OnDirty = nil
    self.value = nil
    local onDestroy = self.OnDestroy
    if onDestroy then
        onDestroy(self)
        self.OnDestroy = nil
    end
end

---@param initial any
---@return WatchedValue
function Create(initial)
    local result = { value = initial }
    setmetatable(result, WatchedValueMetaTable)
    return result
end
