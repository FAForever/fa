--
-- LazyVar module
--

local TableInsert = table.insert

local iscallable = iscallable
local pcall = pcall
local setmetatable = setmetatable


-- Set this true to get tracebacks in error messages. It slows down lazyvars a lot,
-- so don't use except when debugging.
ExtendedErrorMessages = false

local EvalContext = nil
local WeakKeyMeta = { __mode = 'k' }

---@class LazyVar : Destroyable, OnDirtyListener
---@operator call: fun(): any
---@field [1]? any
---@field busy? boolean
---@field compute function
---@field trace? string
---@field used_by table<LazyVar, boolean>
---@field uses table<LazyVar, boolean>
---@field OnDirty? function
local LazyVarMetaTable = {}
LazyVarMetaTable.__index = LazyVarMetaTable

---@return any
function LazyVarMetaTable:__call()
    local value = self[1]
    if value == nil then
        if self.busy then
            local trace = self.trace
            if self.compute then
                trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
            else
                trace = trace or ""
            end
            error("circular dependency in lazy evaluation for variable " .. trace, 2)
        end
        do
            local uses = self.uses
            if next(uses) then
                for use in self.uses do
                    use.used_by[self] = nil
                end
                self.uses = {}
            end
        end

        local currentContext = EvalContext
        self.busy = true
        EvalContext = self
        local okay, value = pcall(self.compute)
        EvalContext = currentContext
        self.busy = nil

        if okay then
            self[1] = value
        else
            local trace = self.trace
            if self.compute then
                trace = trace or "[Set lazyvar.ExtendedErrorMessages for extra trace info]"
            else
                trace = trace or ""
            end
            error("error evaluating lazy variable: " .. value .. "\nStack trace from definition: " .. trace .. '\n', 2)
        end
        if currentContext then
            currentContext.uses[self] = true
            self.used_by[currentContext] = true
        end
        return value
    end
    local currentContext = EvalContext
    if currentContext then
        currentContext.uses[self] = true
        self.used_by[currentContext] = true
    end
    return value
end

--- Resets this lazyvar's value and adds its `OnDirtyListener`s to the list
---@param onDirtyList OnDirtyListener[]
function LazyVarMetaTable:SetDirty(onDirtyList)
    if self[1] ~= nil then
        if self.OnDirty then
            TableInsert(onDirtyList, self)
        end
        self[1] = nil
        for use in self.used_by do
            use:SetDirty(onDirtyList)
        end
    end
end

---@param func function
function LazyVarMetaTable:SetFunction(func)
    if func == nil then
        error("You are attempting to set a LazyVar's evaluation function to nil, don't do that!")
        return
    end

    local onDirtyList
    if self[1] ~= nil then
        onDirtyList = {}
        self[1] = nil
        for use in self.used_by do
            use:SetDirty(onDirtyList)
        end
    end

    self.compute = func
    if ExtendedErrorMessages then
        self.trace = debug.traceback('set from:')
    end

    if onDirtyList then
        do
            local onDirty = self.OnDirty
            if onDirty then
                onDirty(self)
            end
        end
        for _, listener in onDirtyList do
            listener:OnDirty()
        end
    end
end

--- Sets the value
function LazyVarMetaTable:SetValue(value)
    if value == nil then
        error("You are attempting to set a LazyVar's value to nil, don't do that!")
        value = 0
    end

    local onDirtyList
    if self[1] ~= nil then
        onDirtyList = {}
        self[1] = nil
        for use in self.used_by do
            use:SetDirty(onDirtyList)
        end
    end

    self.compute = nil
    self.trace = nil
    self[1] = value
    -- now remove us from the `used_by` lists for any lazy vars we used to compute our value
    do
        local uses = self.uses
        if next(uses) then
            for use in uses do
                use.used_by[self] = nil
            end
            self.uses = {}
        end
    end

    if onDirtyList then
        do
            local onDirty = self.OnDirty
            if onDirty then
                onDirty(self)
            end
        end
        for _, listener in onDirtyList do
            listener:OnDirty()
        end
    end
end

function LazyVarMetaTable:Set(value)
    if value == nil then
        error("You are attempting to set a LazyVar to nil, don't do that!")
        return
    end
    if iscallable(value) then
        self:SetFunction(value)
    else
        self:SetValue(value)
    end
end

function LazyVarMetaTable:Destroy()
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
end

---@param initial? any defaults to `0`
---@return LazyVar
function Create(initial)
    if initial == nil then
        initial = 0
    end
    local setmetatable = setmetatable
    ---@type LazyVar
    ---@diagnostic disable-next-line:assign-type-mismatch,miss-symbol,exp-in-action,unknown-symbol
    local result = {&4 initial} -- preallocate table with hashsize=4, arraysize=1
    setmetatable(result, LazyVarMetaTable)
    local WeakKeyMeta = WeakKeyMeta
    do
        local used_by = {}
        setmetatable(used_by, WeakKeyMeta)
        result.used_by = used_by
    end
    local uses = {}
    setmetatable(uses, WeakKeyMeta)
    result.uses = uses
    return result
end
