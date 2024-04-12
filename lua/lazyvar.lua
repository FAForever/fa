
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
---@field OnDirty? function
---@field [1] any                           # Cached result of what we represent
---@field [2] boolean                       # Flag whether the lazy var is busy
---@field [3] string                        # Optional trace when `ExtendedErrorMessages` is set
---@field [4] function                      # Optional compute value when lazy var represents a function
---@field [5] table<LazyVar, boolean>       # Table of lazy vars that we use
---@field [6] table<LazyVar, boolean>       # Table of lazy vars that use us
---@field [7] LazyVar?       # Lazy var that is dirty
---@field [8] LazyVar?       # Lazy var that is dirty
---@field [9] LazyVar?       # Lazy var that is dirty
---@field [10] LazyVar?      # Lazy var that is dirty
---@field [11] LazyVar?      # Lazy var that is dirty
---@field [12] LazyVar?      # Lazy var that is dirty
---@field [13] LazyVar?      # Lazy var that is dirty
---@field [14] LazyVar?      # Lazy var that is dirty
---@field [15] LazyVar?      # Lazy var that is dirty
---@field [16] LazyVar?      # Lazy var that is dirty
---@field [17] LazyVar?      # Lazy var that is dirty
---@field [18] LazyVar?      # Lazy var that is dirty
---@field [19] LazyVar?      # Lazy var that is dirty
---@field [20] LazyVar?      # Lazy var that is dirty
LazyVarMetaTable = {
    __call = function(self)
        local value = self[1]
        if value == nil then

            -- track circular dependencies and error them out
            if self[2] then
                local trace = self[3]
                if self[4] then
                    trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
                else
                    trace = trace or ""
                end
                error("circular dependency in lazy evaluation for variable " .. trace, 2)
            end

            -- clean up where we're used and what we use
            local uses = self[5]
            if not TableEmpty(uses) then
                for use in uses do
                    use[6][self] = nil
                end

                for k, v in uses do
                    uses[k] = nil
                end
            end

            -- compute the value of this lazy var, this populates the `uses` and `user_by` fields again
            local currentContext = EvalContext
            self[2] = true
            EvalContext = self
            local okay, value = pcall(self[4])
            EvalContext = currentContext
            self[2] = nil

            -- check if it worked out
            if okay then
                self[1] = value
            else
                local trace = self[3]
                if iscallable(self[4]) then
                    trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
                else
                    trace = trace or ""
                end
                error("error evaluating lazy variable: " .. value .. "\nStack trace from definition: " .. trace .. '\n', 2)
            end

            -- keep track of who is using us
            if currentContext then
                currentContext[5][self] = true
                self[6][currentContext] = true
            end

            return value
        end

        -- keep track of who is using us
        local currentContext = EvalContext
        if currentContext then
            currentContext[5][self] = true
            self[6][currentContext] = true
        end

        return value
    end,

    --- Gather all lazy variables that respond to being re-evaluated
    ---@param self LazyVar
    ---@param onDirtyList LazyVar[]
    ---@return number
    SetDirty = function(self, onDirtyList, head)
        if self[1] ~= nil then

            if self.OnDirty then
                onDirtyList[head] = self
                head = head + 1
            end

            self[1] = nil
            for use in self[6] do
                head = use:SetDirty(onDirtyList, head)
            end
        end

        return head
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
        local head = 7
        if self[1] ~= nil then
            self[1] = nil
            for use in self[6] do
                head = use:SetDirty(self, head)
            end
        end

        -- setup internal state for a function
        self[4] = func
        if ExtendedErrorMessages then
            self[3] = debug.traceback('set from:')
        end

        -- tell ourself that we have a new value
        local onDirty = self.OnDirty
        if onDirty then
            onDirty(self)
        end

        -- tell those that use us that we have a new value
        for k = 7, head - 1 do
            self[k]:OnDirty()
            self[k] = nil
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
        local head = 7
        if self[1] ~= nil then
            self[1] = nil
            for use in self[6] do
                head = use:SetDirty(self, head)
            end
        end

        -- setup internal state for a value
        self[4] = nil
        self[3] = nil
        self[1] = value

        -- now remove us from the `used_by` lists for any lazy vars we used to compute our value
        local uses = self[5]
        if not TableEmpty(uses) then
            for use in uses do
                use[6][self] = nil
            end
            self[5] = {}
        end

        -- tell ourself that we have a new value
        local onDirty = self.OnDirty
        if onDirty then
            onDirty(self)
        end

        -- tell those that use us that we have a new value
        for k = 7, head - 1 do
            self[k]:OnDirty()
            self[k] = nil
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

    ---@param self LazyVar
    Destroy = function(self)
        self.OnDirty = nil
        self[4] = nil
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

    ---@param self LazyVar
    ---@return boolean?
    GetBusy = function(self)
        return self[2]
    end,

    ---@see This value is empty when `ExtendedErrorMessages` is set to false
    ---@param self LazyVar
    ---@return string
    GetTrace = function(self)
        return self[3]
    end,

    ---@param self LazyVar
    ---@return function?
    GetCompute = function(self)
        return self[4]
    end,

    ---@param self LazyVar
    ---@return table<LazyVar, boolean>
    GetUses = function(self)
        return self[5]
    end,

    ---@param self LazyVar
    ---@return table<LazyVar, boolean>
    GetUsedBy = function(self)
        return self[6]
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
    local result = {&1 &8} -- preallocate table with hashsize=1, arraysize=8
    setmetatable(result, LazyVarMetaTable)
    result[1] = initial
    result[5] = setmetatable({ }, WeakKeyMeta)
    result[6] = setmetatable({ }, WeakKeyMeta)

    return result
end
