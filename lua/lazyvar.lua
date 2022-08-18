--
-- LazyVar module
--

local TableInsert = table.insert

local iscallable = iscallable
local pcall = pcall
local setmetatable = setmetatable


-- Set this true to get tracebacks in error messages. It slows down lazyvars a lot,
-- so don't use except when debugging.
ExtendedErrorMessages = true

local EvalContext = nil
local WeakKeyMeta = { __mode = 'k' }


---@class LazyVar<T> : {[1]: T, compute: fun(): T}
---@field busy? boolean
---@field trace? string
---@field used_by LazyVar[]
---@field uses LazyVar[]
---@field OnDirty? function
local LazyVarMetaTable = {}
LazyVarMetaTable.__index = LazyVarMetaTable

function LazyVarMetaTable:__call()
    local value = self[1]
    local currentContext = EvalContext
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
        for use in self.uses do
            use.used_by[self] = nil
        end
        self.uses = {}

        self.busy = true
        EvalContext = self

        local okay
        okay, value = pcall(self.compute)

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
    end
    if currentContext then
        currentContext.uses[self] = true
        self.used_by[currentContext] = true
    end
    return value
end



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

function LazyVarMetaTable:SetFunction(func)
    if func == nil then
        error("You are attempting to set a LazyVar's evaluation function to nil, don't do that!")
    end
    local dirtyList = {}
    self:SetDirty(dirtyList)
    self.compute = func
    if ExtendedErrorMessages then
        self.trace = debug.traceback('set from:')
    end

    for _, listener in dirtyList do
        listener:OnDirty()
    end
end

function LazyVarMetaTable:SetValue(value)
    if value == nil then
        error("You are attempting to set a LazyVar's value to nil, don't do that!")
    end
    local dirtyList = {}
    self:SetDirty(dirtyList)
    self.compute = nil
    self.trace = nil
    self[1] = value
    -- now remove us from the `used_by`` lists for any lazy vars we used to use
    for use in self.uses do
        use.used_by[self] = nil
    end
    self.uses = {}

    for _, listener in dirtyList do
        listener:OnDirty()
    end
end

function LazyVarMetaTable:Set(value)
    if value == nil then
        error("You are attempting to set a LazyVar to nil, don't do that!")
    end
    if iscallable(value) then
        self:SetFunction(value)
    else
        self:SetValue(value)
    end
end




function LazyVarMetaTable:SelfCleanSetDirty(onDirtyList)
    if self[1] ~= nil then
        self[1] = nil
        for use in self.used_by do
            use:SetDirty(onDirtyList)
        end
    end
end

function LazyVarMetaTable:SelfCleanSetFunction(func)
    if func == nil then
        error("You are attempting to set a LazyVar's evaluation function to nil, don't do that!")
    end
    local dirtyList = {}
    self:SelfCleanSetDirty(dirtyList)
    self.compute = func
    if ExtendedErrorMessages then
        self.trace = debug.traceback('set from:')
    end

    for _, listener in dirtyList do
        listener:OnDirty()
    end
end

function LazyVarMetaTable:SelfCleanSetValue(value)
    if value == nil then
        error("You are attempting to set a LazyVar's value to nil, don't do that!")
    end
    local dirtyList = {}
    self:SelfCleanSetDirty(dirtyList)
    self.compute = nil
    self.trace = nil
    self[1] = value
    -- now remove us from the `used_by` lists for any lazy vars we used to use
    for use in self.uses do
        use.used_by[self] = nil
    end
    self.uses = {}

    for _, listener in dirtyList do
        listener:OnDirty()
    end
end

function LazyVarMetaTable:SelfCleanSet(value)
    if value == nil then
        error("You are attempting to set a LazyVar to nil, don't do that!")
    end
    if iscallable(value) then
        self:SelfCleanSetFunction(value)
    else
        self:SelfCleanSetValue(value)
    end
end



function LazyVarMetaTable:Destroy()
    self.OnDirty = nil
    self.compute = nil
    self[1] = nil
end

---@param initial? any
---@return LazyVar
function Create(initial)
    if initial == nil then
        initial = 0
    end
    local result = {&4 initial} -- preallocate table with hashsize=4, arraysize=1
    setmetatable(result, LazyVarMetaTable)
    local used_by = {}
    setmetatable(used_by, WeakKeyMeta)
    result.used_by = used_by
    result.uses = {}
    return result
end
