---@class LazyCacheClass

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

---@class LazyCache
local LazyCacheBase = {}
setmetatable(LazyCacheBase, LazyCacheFactory)

LazyCacheBase.__lazy = {}
LazyCacheBase.Class = LazyCacheBase
LazyCacheBase.Clear = function(self)
    for field, _ in self.__lazy do
        self[field] = nil
    end
end;

local excludedKeys = {
    __index = true,
    __lazy = true,
    Class = true,
}

--- Forms a lazy cache class
---@param ... table `bases: LazyCacheClass`... `fields: table<string, function>`, `methods: table<string, function>`
---@return LazyCacheClass
function LazyCacheClass(...)
    local bases = {LazyCacheBase}
    local fieldGenerators, members

    -- read varargs into variables
    local args = arg.n
    for i = 1, args do
        local val = arg[i]
        if type(val) ~= "table" then
            break
        end
        if getmetatable(val) == LazyCacheFactory then
            bases[i + 1] = val
        else
            fieldGenerators = val
            i = i + 1
            if i <= args then
                members = args[i]
            end
            break
        end
    end

    fieldGenerators = fieldGenerators or {}
    members = members or {}

    -- create new table to ensure there's no backreferences that can create a cycle
    local lazycache = {}
    setmetatable(lazycache, LazyCacheFactory)

    local __lazy = {}
    lazycache.__lazy = __lazy
    lazycache.Class = lazycache

    lazycache.__index = function(self, member)
        local lazycache = lazycache -- upvalue to local
        -- look for class members
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
