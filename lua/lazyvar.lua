
local TableInsert = table.insert
local TableEmpty = table.empty

local iscallable = iscallable
local pcall = pcall
local setmetatable = setmetatable


-- Set this true to get tracebacks in error messages. It slows down lazyvars a lot,
-- so don't use except when debugging.
local ExtendedErrorMessages = false
local EvalContext = nil
local WeakKeyMeta = { __mode = 'k' }

---@alias Lazy<T> T | LazyVar<T> | fun(): T

---@class LazyVar<T> : Destroyable, OnDirtyListener, function
---@field [1] any           # Cached result of what we represent
---@field busy? boolean
---@field trace string
---@field compute function
---@field uses table<LazyVar, boolean>
---@field used_by table<LazyVar, boolean>
---@field OnDirty? function
LazyVarMetaTable = {
    __call = function(self)
        local value = self[1]
        if value == nil then

            -- track circular dependencies and error them out
            if self.busy then
                local trace = self.trace
                if self.compute then
                    trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
                else
                    trace = trace or ""
                end
                error("circular dependency in lazy evaluation for variable " .. trace, 2)
            end

            -- clean up where we're used and what we use
            local uses = self.uses
            if not TableEmpty(uses) then
                for use in uses do
                    use.used_by[self] = nil
                end

                for k, v in uses do
                    uses[k] = nil
                end
            end

            -- compute the value of this lazy var, this populates the `uses` and `user_by` fields again
            local currentContext = EvalContext
            self.busy = true
            EvalContext = self
            local okay, value = pcall(self.compute)
            EvalContext = currentContext
            self.busy = nil

            -- check if it worked out
            if okay then
                self[1] = value
            else
                local trace = self.trace
                if iscallable(self.compute) then
                    trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
                else
                    trace = trace or ""
                end
                error("error evaluating lazy variable: " .. value .. "\nStack trace from definition: " .. trace .. '\n', 2)
            end

            -- keep track of who is using us
            if currentContext then
                currentContext.uses[self] = true
                self.used_by[currentContext] = true
            end

            return value
        end

        -- keep track of who is using us
        local currentContext = EvalContext
        if currentContext then
            currentContext.uses[self] = true
            self.used_by[currentContext] = true
        end

        return value
    end,

    --- Gather all lazy variables that respond to being re-evaluated
    ---@param self LazyVar
    ---@param onDirtyList LazyVar[]
    SetDirty = function(self, onDirtyList)
        if self[1] ~= nil then
            if self.OnDirty then
                TableInsert(onDirtyList, self)
            end
            self[1] = nil
            for use in self.used_by do
                use:SetDirty(onDirtyList)
            end
        end
    end,

    --- Lazy variable represents a function, the result is cached
    ---@param self LazyVar
    ---@param func function
    SetFunction = function(self, func)
        -- do not allow nils
        if func == nil then
            error("You are attempting to set a LazyVar's evaluation function to nil, don't do that!")
            return
        end

        -- gather all those that use us
        local onDirtyList
        if self[1] ~= nil then
            onDirtyList = {}
            self[1] = nil
            for use in self.used_by do
                use:SetDirty(onDirtyList)
            end
        end

        -- setup internal state for a function
        self.compute = func
        if ExtendedErrorMessages then
            self.trace = debug.traceback('set from:')
        end

        -- tell all those that use us that they're dirty and that they can re-compute their values
        if onDirtyList then
            local onDirty = self.OnDirty
            if onDirty then
                onDirty(self)
            end

            for _, listener in onDirtyList do
                listener:OnDirty()
            end
        end
    end,

    --- Lazy variable represents a value
    ---@param self LazyVar
    ---@param value any
    SetValue = function(self, value)
        if value == nil then
            error("You are attempting to set a LazyVar's value to nil, don't do that!")
            value = 0
        end

        -- gather all those that use us
        local onDirtyList
        if self[1] ~= nil then
            onDirtyList = {}
            self[1] = nil
            for use in self.used_by do
                use:SetDirty(onDirtyList)
            end
        end

        -- setup internal state for a value
        self.compute = nil
        self.trace = nil
        self[1] = value

        -- now remove us from the `used_by` lists for any lazy vars we used to compute our value
        local uses = self.uses
        if not TableEmpty(uses) then
            for use in uses do
                use.used_by[self] = nil
            end
            self.uses = {}
        end

        -- tell all those that use us that they're dirty and that they can re-compute their values
        if onDirtyList then
            local onDirty = self.OnDirty
            if onDirty then
                onDirty(self)
            end

            for _, listener in onDirtyList do
                listener:OnDirty()
            end
        end
    end,

    --- Lazy variable represents a value or a function
    ---@see SetFunction when the parameter is a function
    ---@see SetValue when the parameter is a value
    ---@param self LazyVar
    ---@param value any
    Set = function(self, value)
        if value == nil then
            error("You are attempting to set a LazyVar to nil, don't do that!")
            return
        end
        if iscallable(value) then
            self:SetFunction(value)
        else
            self:SetValue(value)
        end
    end,

    ---@param self any
    Destroy = function(self)
        self.OnDirty = nil
        self.compute = nil
        local val = self[1]
        self[1] = nil
        if val then
            local destroy = val.Destroy
            if destroy then
                destroy(val)
            end
        end
        local onDestroy = self.OnDestroy
        if onDestroy then
            onDestroy(self)
            self.OnDestroy = nil
        end
    end,
}

LazyVarMetaTable.__index = LazyVarMetaTable

---@generic T
---@param initial? T defaults to `0`
---@return LazyVar<T>
function Create(initial)
    local setmetatable = setmetatable
    local WeakKeyMeta = WeakKeyMeta

    if initial == nil then
        initial = 0
    end

    ---@type LazyVar
    ---@diagnostic disable-next-line:assign-type-mismatch,miss-symbol,exp-in-action,unknown-symbol
    local result = {&4 initial} -- preallocate table with hashsize=4, arraysize=1
    setmetatable(result, LazyVarMetaTable)
    result.used_by = setmetatable({ }, WeakKeyMeta)
    result.uses = setmetatable({ }, WeakKeyMeta)

    return result
end
