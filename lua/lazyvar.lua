--
-- LazyVar module
--


local EvalContext = nil

local LazyVarMetaTable = { }

LazyVarMetaTable.__index = LazyVarMetaTable

local WeakKeyMeta = { __mode = 'k' }

-- Set this true to get tracebacks in error messages. It slows down lazyvars a lot,
-- so don't use except when debugging.
ExtendedErrorMessages = false

function LazyVarMetaTable:__call()
    if not self[1] then
        if self.busy then
            error("circular dependency in lazy evaluation for variable " .. (self.trace or ''), 2)
        end
        self.busy = true
        local u
        for u in self.uses do
            u.used_by[self] = nil
        end
        self.uses = {}
        local oldContext = EvalContext
        EvalContext = self
        local okay, value = pcall(self.compute)
        EvalContext = oldContext
        self.busy = nil
        if okay then
            self[1] = value
        else
            error("error evaluating lazy variable: " .. value .. "\nStack trace from definition: " .. (self.trace or '') .. '\n', 2)
        end
    end
    if EvalContext then
        EvalContext.uses[self] = true
        self.used_by[EvalContext] = true
    end
    return self[1]
end

function LazyVarMetaTable:SetDirty(onDirtyList)
    if self[1] then
        if self.OnDirty then
            table.insert(onDirtyList, self)
        end
        self[1] = nil
        local u for u in self.used_by do 
            u:SetDirty(onDirtyList)
        end
    end
end 

function LazyVarMetaTable:SetFunction(func)
    local dirtyList = {}
    self:SetDirty(dirtyList)
    self.compute = func
    if ExtendedErrorMessages then
        self.trace = debug.traceback('set from:')
    else
        self.trace = '[Set lazyvar.ExtendedErrorMessages for extra trace info]'
    end

    for i,v in ipairs(dirtyList) do
        v:OnDirty()
    end
end

function LazyVarMetaTable:SetValue(value)
    local dirtyList = {}
    self:SetDirty(dirtyList)
    self.compute = nil
    self.trace = nil
    self[1] = value
    -- Now remove us from the used_by lists for any lazy vars we used to use.
    for u in self.uses do
        u.used_by[self] = nil
    end
    self.uses = {}
    for i,v in ipairs(dirtyList) do
        v:OnDirty()
    end
end

function LazyVarMetaTable:Set(v)
    if v == nil then
        error("You are attempting to set a LazyVar's evaluation function to nil, don't do that!")    
    end
    if iscallable(v) then
        self:SetFunction(v)
    else
        self:SetValue(v)
    end
end

function LazyVarMetaTable:Destroy()
    self.OnDirty = nil
    self.compute = nil
    self.value = nil
end

function Create(initial)
    result = {&1&4}
    setmetatable(result, LazyVarMetaTable)
    result[1] = initial or 0
    result.used_by = {}
    setmetatable(result.used_by, WeakKeyMeta)
    result.uses = {}
    return result
end
