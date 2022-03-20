-- EXPERIMENTS

-- A class is called using:
-- Class { bases = ( Base1, Base2, Base3, ...) , spec = { spec } }

-- That means there are two functions calls in a row:
--  - The first is taken care of SimplifiedClassMeta.__call, attaching a meta table to the bases of the class
--  - The second is taken care of IntermediateSimplifiedClassMeta.__call, populating the actual table, taking elements from the bases



--- Class structure

-- A typical class is defined as:

--  - Unit = Class(base1, base2, base3) { k1 = v1, k2 = v2 }

-- A couple of examples:

--  - Unit = Class(moho.unit_methods) { ... }
--  - DefaultProjectileWeapon = Class(Weapon) { ... }
--  - Projectile = Class(moho.projectile_methods, Entity) { ... }

-- This means we have a series of function calls:
--  - First function call receives (and stores) the bases, returning a function 
--  - Second function call receives (and processes) the class-specific specifications, returning a meta table 

--- State structure

-- A typical state is defined as:

--  IdleState = State {
--      Main = function(self)
--      end,
--  },

-- A state is a bit of a beast. It is a concept that we can't get rid of anymore. Each state
-- introduces a separate meta table. That meta table is self sufficient, e.g., it contains all
-- the logic of the class it takes part of. That is what makes a state expensive: each state
-- is a deep copy of the class. And each class that inherits from it needs the same deep copy
-- of the inheriting class, accordingly. 

local debug = false 


-- upvalue for performance
local next = next 
local unpack = unpack
local getmetatable = getmetatable
local setmetatable = setmetatable
local ForkThread = ForkThread

local Exclusions = { 
    __index = true,
    n = true,
}

local function Deepcopy(other)
    local copy = { }
    local type = type 
    for k, v in other do 
        if not Exclusions[k] then 
            if type(v) == "table" then 
                copy[k] = Deepcopy(v)
            else 
                copy[k] = v 
            end
        end
    end

    return copy 
end

-- Procedure
-- 



--- Determines whether we have a simple class: one that has no base classes
local emptyMetaTable = getmetatable { }
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end

local StateIdentifier = 0
local StateMetatable = { }
StateMetatable.__index = StateMetatable  

function State(...)

    -- State ({ field=value, field=value, ... })
    if IsSimpleClass(arg) then 
        -- LOG("Created a simple state!")
        local state = ConstructClass(nil, Deepcopy (arg[1]) )
        state.__State = true 
        state.__StateIdentifier = StateIdentifier
        StateIdentifier = StateIdentifier + 1
        return state 

    -- State (Base1, Base2, ...) ({field = value, field = value, ...})
    else 
        -- LOG("Created a state with a basis")
        local bases = { unpack (arg) }
        return function(specs)
            local state = ConstructClass(bases, specs)
            state.__State = true 
            state.__StateIdentifier = StateIdentifier
            StateIdentifier = StateIdentifier + 1
            return state 
        end
    end
end

function Class(...)

    -- arg = { 
    --     { 
    --         -- { table with information of base 1 } OR { specifications }
    --         -- { table with information of base 2 }
    --         -- ...
    --         -- { table with information of base n }
    --     }, 
    --     n=1 -- number of bases
    -- }

    -- Class ({ field=value, field=value, ... })
    if IsSimpleClass(arg) then 
        -- LOG("Creating a simple class")
        local class = ConstructClass(nil, Deepcopy (arg[1]) )

        -- set the meta table and return it
        setmetatable(class, ClassFactory)
        return class

    -- Class(Base1, Base2, ...) ({field = value, field = value, ...})
    else 
        -- LOG("Creating a class with bases")
        local bases = { unpack (arg) }
        return function(specs)
            local class = ConstructClass(bases, specs)

            -- set the meta table and return it
            setmetatable(class, ClassFactory)
            return class
        end
    end
end

local CachedTypes = { }
local Hierarchy = { }
local HierarchyDebugLookup = { }
local HierarchyDebugLookupCFunctions = { }
local HierarchyDebugLookupCount = { }

local ChainStack = { }
local ChainCacheA, ChainCacheB = { }, { }
local function ComputeHierarchyChain(a, cache)

    -- clear out the cache
    for k, v in cache do 
        cache[k] = nil 
    end

    -- populate the cache
    local stack = ChainStack 
    stack[1] = a
    local stackHead = 2 

    local count = 0
    while stackHead > 1 do 
        stackHead = stackHead - 1
        local elem = stack[stackHead]
        cache[elem] = true 
        count = count + 1 

        local overrides = Hierarchy[elem]
        if overrides then 
            for k = 1, overrides.h - 1 do 
                stack[stackHead] = overrides[k] 
                stackHead = stackHead + 1 
            end
        end
    end

    if debug then 
        LOG("Chain for: " .. tostring(a) .. " (" .. tostring(HierarchyDebugLookup[a].func)  .. ", id = " .. tostring(HierarchyDebugLookup[a].identity) .. ")")
        LOG(repr(ca))
    end

    return count
end

local function CheckHierarchy(a, b)

    local ca = ChainCacheA
    local cb = ChainCacheB

    -- populate the hierarchy chains
    local sa = ComputeHierarchyChain(a, ca)

    -- if the head of chain b is part of ca, then ca is longer
    if ca[b] then 
        return a
    end

    local sb = ComputeHierarchyChain(b, cb)

    -- if the head of chain a is part of cb, then cb is longer
    if cb[a] then 
        return b
    end 

    -- not part of a hierarchy
    return false
end

local function PrintHierarchy()

    -- cache for performance
    local LOG = LOG 
    local tostring = tostring 

    local function Format(key)
        if HierarchyDebugLookupCFunctions[key] then 
            return "base instance (cfunction)"
        elseif HierarchyDebugLookup[key] then 
            return tostring(key) .. " (" .. tostring(HierarchyDebugLookup[key].func)  .. ", id = " .. tostring(HierarchyDebugLookup[key].identity) .. ")"
        else 
            return "base instance (lua function)"
        end
    end

    -- write out the hierarchy
    LOG("{ ")
    for k, v in Hierarchy do 

        local intermediate = ""
        for l = 1, v.h - 1 do 
            intermediate = intermediate .. " " .. Format(v[l])
        end

        LOG( Format(k) .. " = {" .. intermediate .. " }")
    end
    LOG("} ")
end

local Seen = { }
function ConstructClass(bases, specs)

    -- cache as locals for performance
    local type = type 
    local exclusions = Exclusions
    local hierarchy = Hierarchy
    local seen = Seen 
    local class = specs

    if bases then 
        -- keep track of hierarchy chains
        for ks, s in specs do 
            local t = type(s)
            if t == "function" or t == "cfunction" then 
                for kb, base in bases do 
                    -- we're trying to override something here
                    if base[ks] then 

                        -- keep track of the names and give them some unique identifier
                        if debug then 
                            HierarchyDebugLookupCount[ks] = HierarchyDebugLookupCount[ks] or 0
                            HierarchyDebugLookupCount[ks] = HierarchyDebugLookupCount[ks] + 1
                            HierarchyDebugLookup[s] = { func = ks, identity = HierarchyDebugLookupCount[ks] }  
                        end

                        -- link to or create a table
                        hierarchy[s] = hierarchy[s] or { h = 1 }

                        -- put table into a local scope and append the thing we're inheriting from
                        local elem = hierarchy[s]
                        elem[elem.h] = base[ks] 
                        elem.h = elem.h + 1 
                    end
                end
            end
        end

        -- check for collisions 
        for k, base in bases do 
            for l, element in base do 
                -- todo, refine this a bit
                if not exclusions[l] then 
                    -- first time we've seen this key, keep track of it
                    if not seen[l] then 
                        seen[l] = element 

                    -- we've seen this key before and it has the same matching element: we're good
                    elseif seen[l] == element then
                        -- do nothing 

                    -- we've got two elements with the same key but different values, but our specs has a function to merge them: we're good
                    elseif specs[l] then
                        -- do nothing

                    -- we've got two elements with the same key but different values, check if they're not secretly a state with matching identifiers
                    elseif type(element) == "table" and (seen[l].__StateIdentifier == element.__StateIdentifier) then
                        -- do nothing 

                    else 
                        -- check if one is part of the hierarchy of the other
                        local hierarchy = CheckHierarchy(seen[l], element)
                        if hierarchy then 
                            class[l] = hierarchy 
                            seen[l] = hierarchy 

                        -- we've got two elements with the same key but they're not part of each others hierarchy chain: ambigious!
                        else    
                            error("Class initialisation: field '" .. tostring(l).. "' is ambigious between the bases. They use the same field for different values. You need to create a field in the specifications that defines the behavior.")
                            LOG(repr(debug.traceback()))
                        end
                    end
                end
            end
        end

        -- clean up seen
        for k, element in seen do 
            seen[k] = false 
        end

        -- populate class 
        for k, base in bases do 
            for l, element in base do 
                if not class[l] then 
                    class[l] = element 
                end
            end
        end

        -- post-process the states to make sure that they're unique and have the correct meta table set
        for k, v in class do 
            -- any member that has a meta table set is by definition a state
            if type(v) == "table" and v.__State then 

                -- copy the content into a new table
                local d = Deepcopy(v) 

                -- set meta table information
                d.__index = d 
                setmetatable(d, class)

                -- override previous entry
                class[k] = d
            end
        end
    end

    class.__index = class

    return class
end

ClassFactory = { }
function ClassFactory:__call(...)

    -- LOG("Creating a class instance")

    -- create the new entity with us as its meta table
    local instance = { }
    setmetatable(instance, self)

    -- call class initialisation functions, if they exist
    local initfn = self.__init
    local postinitfn = self.__post_init
    if initfn or postinitfn then
        -- LOG("initfn or postinitfn")
        if initfn then 
            initfn(instance, unpack(arg))
        end

        if postinitfn then 
            postinitfn(instance, unpack(arg))
        end
    end

    return instance
end

--- Switches up the sate of a class instance by inserting the new state between the instance and its class
-- @param instance The current instance we want to switch states for
-- @param newState the state we want to insert between the instance and its base class
function ChangeState(instance, newstate)

    -- LOG("Changing state!")

    -- call on-exit function
    if instance.OnExitState then
        instance.OnExitState(instance)
    end

    -- keep track of the original thread and forget about it inside the object
    local old_main_thread = instance.__mainthread
    instance.__mainthread = nil

    -- change the state accordingly by switching up the meta tables:
    -- - entity
    -- - state      <-- introduced as an intermediate, prevents a lot of duplicated values and tables
    -- - class
    setmetatable(instance, newstate)

    -- call on-enter function
    if instance.OnEnterState then
        instance.OnEnterState(instance)
    end

    -- start the new main thread if it wasn't already created during an OnEnterState
    if instance.Main and not instance.__mainthread then
        instance.__mainthread = ForkThread(instance.Main, instance)
    end

    -- remove the old main thread, threads are de-allocated when they've completed their computation chain
    if old_main_thread then
        old_main_thread:Destroy()
    end
end

local function Flatten (flattee, hierarchy, seen)
    -- cache for performance
    local type = type 

    for k, entry in hierarchy do 
        if type(entry) == "table"  then 
            if not seen[entry] then 
                seen[entry] = true 
                Flatten(flattee, entry, seen)
            end
        else 
            flattee[k] = entry 
        end
    end
end

function ConvertCClassToLuaSimplifiedClass(cclass)

    if getmetatable(cclass) == ClassFactory then
        LOG("Already populated class: " .. tostring(cclass))
        return
    end

    local seen = { }
    local flatten = { }
    Flatten(flatten, cclass, seen )

    -- the reference to the table is hardcoded in the engine, therefore we need to re-populate the cclass or functions
    -- such as CreateAimManipulator that return a table with the metatable attached won't work properly :sad_cowboy:

    -- remove all entries in the class
    for k, val in cclass do 
        cclass[k] = nil 
    end

    -- re-populate it
    for k, val in flatten do 
        cclass[k] = val 

        -- allow us to print it out
        HierarchyDebugLookupCFunctions[val] = true
    end

    -- allow tables to search the meta table
    cclass.__index = cclass 

    setmetatable(cclass, ClassFactory)
end