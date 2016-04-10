--- A value which dispatches an event when it is changed.
-- Similar to a LazyValue, but without the lazy-evaluation (so we don't need to store closures all
-- the time)
-- This also destroys the dependency system used by LazyVar. A WatchedValue cannot induce an onDirty
-- on another WatchedValue (except explicitly in the caller's onDirty handler).
local WatchedValueMetaTable = {}

WatchedValueMetaTable.__index = WatchedValueMetaTable

function WatchedValueMetaTable:__call()
    if self.isNull then
        return nil
    end

    return self.value
end

function WatchedValueMetaTable:Set(v)
    self.isNull = v == nil
    self.value = v
    self:OnDirty(v)
end

function WatchedValueMetaTable:Destroy()
    self.OnDirty = nil
    self.value = nil
end

function Create(initial)
    -- For absurd reasons, nil is unrepresentable. We therefore have to use a flag to track nullity.
    local value
    if initial == nil then
        value = false
    else
        value = initial
    end

    local result = {}
    setmetatable(result, WatchedValueMetaTable)

    result.isNull = initial == nil
    result.value = value
    result.OnDirty = function(v) end
    return result
end
