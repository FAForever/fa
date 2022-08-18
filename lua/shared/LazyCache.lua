-- There are four forms you can use to create a LazyCache:
--    `Class = LazyCache { <fieldgenerators> }`
--    `Class = LazyCache { <fieldgenerators> } { <methods> }`
--    `Class = LazyCache(<bases>) { <fieldgenerators> }`
--    `Class = LazyCache(<bases>) { <fieldgenerators> } { <methods> }`
-- 
-- Note that due to being a function, you cannot access class members from the methodless versions.
-- If you need to access them, append `{}` to the end of the class definition, or, if unavailable,
-- look up the fully formed version using `FullyFormedLazyCache(partiallyFormed)`

---@class LazyCacheClass

---@class LazyCache
local LazyCacheBase = {__lazy = {}}

LazyCacheBase.Class = LazyCacheBase
LazyCacheBase.Clear = function(self)
    for field, _ in self.__lazy do
        self[field] = nil
    end
end;

local PartialClasses = {}


local emptyMetaTable = getmetatable{}
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end


local LazyCacheFactory = {
    __call = function(self, ...)
        -- create the new entity with us as its metatable
        local cache = {}
        setmetatable(cache, self)

        -- call initialization function, if it exists
        local initfn = self.__init
        if initfn then
            initfn(cache, unpack(arg))
        end

        return cache
    end;
}

local excludedKeys = {
    __index = true,
    __lazy = true,
    Class = true,
}

local function ConstructLazyCache(bases, fieldGenerators, members)
    -- create new table to ensure there's no backreferences that can create a cycle
    local __lazy = {}
    local lazycache; lazycache = {
        Class = lazycache;
        __lazy = __lazy;

        __index = function(self, member)
            -- look for class members
            local lazycache = lazycache
            local memberValue = lazycache[member]
            if memberValue then
                return memberValue
            end
            -- look for lazy fields
            local fun = lazycache.__lazy[member]
            if fun then
                local val = fun(self)
                self[member] = val
                return val
            end
        end
    }
    setmetatable(lazycache, LazyCacheFactory)

    for _, base in bases do
        -- inherit base members
        for member, memberValue in base do
            if excludedKeys[member] then
                continue
            end
            local existing = lazycache[member]
            if existing then
                if memberValue ~= existing and not members[member] then
                    error("LazyCache initialization: inherited member '" .. member .. "' is ambiguous", 2)
                end
                continue
            end
            lazycache[member] = memberValue
        end
        -- inherit base lazy fields
        for field, fieldGenerator in base.__lazy do
            if excludedKeys[field] then
                continue
            end
            local existing = __lazy[field]
            if existing then
                if fieldGenerator ~= existing and not fieldGenerators[field] then
                    error("LazyCache initialization: inherited field generator '" .. field .. "' is ambiguous", 2)
                end
                continue
            end
            __lazy[field] = fieldGenerator
        end
    end

    for member, memberValue in members do
        lazycache[member] = memberValue
    end
    for field, fieldGenerator in fieldGenerators do
        __lazy[field] = fieldGenerator
    end

    return lazycache
end

---@param partiallyFormed function
---@return LazyCacheClass
function FullyFormedLazyCache(partiallyFormed)
    if type(partiallyFormed) == "function" then -- is actually partially formed
        local fullyFormedClass = PartialClasses[partiallyFormed]
        if not fullyFormedClass then
            fullyFormedClass = partiallyFormed {}
            PartialClasses[partiallyFormed] = fullyFormedClass
        end
        return fullyFormedClass
    end
    return partiallyFormed
end

local function PartiallyCreateLazyCache(bases, fieldGenerators)
    local partiallyFormed; partiallyFormed = function(members)
        if PartialClasses[partiallyFormed] then
            error("Attempting to recreate a partially formed class", 2)
        end
        local lazycache = ConstructLazyCache(bases, fieldGenerators, members)
        PartialClasses[partiallyFormed] = lazycache
        return lazycache
    end
    PartialClasses[partiallyFormed] = false
    return partiallyFormed
end


---@overload fun(fieldGenerators: function[]): fun(members: any[]): LazyCacheClass
---@param ... LazyCacheClass bases
---@return fun(fieldGenerators: function[]): fun(members: any[]): LazyCacheClass
function LazyCache(...)
    if IsSimpleClass(arg) then
        return PartiallyCreateLazyCache({LazyCacheBase}, arg[1])
    else
        return function(fieldGenerators)
            local bases = {LazyCacheBase}
            -- replace any partially formed lazy caches with their fully formed versions
            for i = 1, arg.n do
                bases[i + 1] = FullyFormedLazyCache(bases[i])
            end
            return PartiallyCreateLazyCache(bases, fieldGenerators)
        end
    end
end
