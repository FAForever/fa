---@declare-global
--- Class structure

-- Simple class

-- A less common type of class that solely consists of a list of specifications. Common examples are:
-- - TrashBag
-- - BaseManager
-- - OpAI

-- Inheriting class

-- The most often used class type. A class that inherits properties from other classes while being able 
-- to define its own specifications. Common examples are:
-- - Unit = Class(moho.unit_methods) { ... }
-- - DefaultProjectileWeapon = Class(Weapon) { ... }
-- - Projectile = Class(moho.projectile_methods, Entity) { ... }

-- Because of the structure chosen we have three function calls:
-- - First function call receives (and stores) the base classes, returning a new function 
-- - Second function call receives (and processes) the class-specific specifications, returning a meta table that can be called
-- - Third function call creates an instance of the class, this is done by the engine

--- State

-- A state shares the same principle as a class: there is a simple state and a state that inherits from other states. A state is an 'intermediate' class
-- with a few (typically one or two) changed values or functions. By default the metatable hierarchy of an instance is:
-- - instance
-- - class

-- A state can put itself 'in between', like so:
-- - instance
-- - state
-- - class 

--- look up hierarchy to help determine the relationships between classes. 

-- function: 1E0F3E00 (OnDestroy, id = 1) = { base instance }
-- function: 1F45AA80 (OnGotTarget, id = 1) = { base instance }
-- function: 1F3902D8 (OnCreate, id = 1) = { function: 1F37B500 (OnCreate, id = 1) }
-- function: 1F40F0E0 (OnKilled, id = 1) = { function: 1F3D3EE0 (OnKilled, id = 1) }
-- function: 1DE7E1C0 (BuilderParamCheck, id = 1) = { base instance }

-- It allows us to track a function back to the base instance.
Hierarchy = {}

--- Debug utilities

local enableDebugging = false

HierarchyDebugLookup = {}
HierarchyDebugLookupCFunctions = {}
HierarchyDebugLookupCount = {}

local function PrintHierarchy()
    -- cache for performance
    local LOG = LOG
    local tostring = tostring

    local function Format(key)
        if HierarchyDebugLookupCFunctions[key] then
            return "base instance (cfunction)"
        elseif HierarchyDebugLookup[key] then
            return tostring(key) .. " (" .. tostring(HierarchyDebugLookup[key].func)  .. ", id = " .. tostring(HierarchyDebugLookup[key].identity) .. ", type = " .. tostring(HierarchyDebugLookup[key].type) .. ")"
        else
            return "base instance (lua function or table)"
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

--- Class functionality

-- upvalue for performance
local unpack = unpack
local getmetatable = getmetatable
local setmetatable = setmetatable

local TableEmpty = table.empty 
local TableGetn = table.getn

local Exclusions = {
    __base = true,
    __index = true,
    n = true,
    __name = true,
}

local function Deepcopy(other)
    local copy = {}
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

--- Determines whether we have a simple class: one that has no base classes
local emptyMetaTable = getmetatable { }
local function IsSimpleClass(arg)
    return arg.n == 1 and getmetatable(arg[1]) == emptyMetaTable
end

---@class fa-class : function
---@operator call(...): table
---@field __init? fun(self, ...)
---@field __post_init? fun(self, ...)

---@class State

---@class fa-class-state : fa-class
---@field __State true
---@field __StateIdentifier number

--- Prepares the construction of a state, , referring to the paragraphs of text at the top of this file.
local StateIdentifier = 0
---@generic T: fa-class-state
---@param ... T
---@return T
function State(...)
    -- arg = { 
    --     { 
    --         -- { table with information of base 1 } OR { specifications }
    --         -- { table with information of base 2 }
    --         -- ...
    --         -- { table with information of base n }
    --     }, 
    --     n=1 -- number of bases
    -- }

    -- State ({ field=value, field=value, ... })
    if IsSimpleClass(arg) then
        local state = ConstructClass(nil, arg[1] )
        state.__State = true
        state.__StateIdentifier = StateIdentifier
        StateIdentifier = StateIdentifier + 1
        return state
    else -- State (Base1, Base2, ...) ({field = value, field = value, ...})
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

--- Prepares the construction of a class, referring to the paragraphs of text at the top of this file.
---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
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
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, ClassFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    -- Class(Base1, Base2, ...) ({field = value, field = value, ...})
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, ClassFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassUI(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, UIFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, UIFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassShield(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, ShieldFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, ShieldFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassProjectile(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, ProjectileFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, ProjectileFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassDummyProjectile(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, DummyProjectileFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, DummyProjectileFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassUnit(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, UnitFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, UnitFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassDummyUnit(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, DummyUnitFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, DummyUnitFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T: fa-class
---@generic T_Base: fa-class
---@param ... T_Base
---@return fun(specs: T): T|T_Base
function ClassWeapon(...)
    if IsSimpleClass(arg) then
        local class = arg[1] --[[@as fa-class]]
        setmetatable(class, WeaponFactory)
        return ConstructClass(nil, class) --[[@as unknown]]
    else
        local bases = { unpack (arg) }
        return function(specs)
            local class = specs
            setmetatable(class, WeaponFactory)
            return ConstructClass(bases, class)
        end
    end
end

---@generic T
---@param specs T
---@return T
function ClassTrashBag(specs)
    setmetatable(specs, TrashBagFactory)
    return ConstructClass(nil, specs)
end

---@generic T
---@param specs T
---@return T
function ClassSimple(specs)
    return Class(specs)
end

local ChainStack = {}
local ChainCache = {}
--- Computes the hierarchy chain of a function: determine the path from the current function back to 
--- the base instance. Note that this assumes that the base is always called, which is not always the case.
local function ComputeHierarchyChain(a, cache)
    -- clear out the cache
    for k, _ in cache do
        cache[k] = nil
    end

    -- populate the cache
    local stack = ChainStack
    stack[1] = a
    local stackHead = 2

    while stackHead > 1 do
        -- retrieve an element from the stack
        stackHead = stackHead - 1
        local elem = stack[stackHead]

        -- add it to the hierarchy chain lookup table
        cache[elem] = true

        -- extend the stack until we're at a base instance
        local overrides = Hierarchy[elem]
        if overrides then
            for k = 1, overrides.h - 1 do
                stack[stackHead] = overrides[k]
                stackHead = stackHead + 1
            end
        end
    end

    if enableDebugging then
        LOG("Chain for: " .. tostring(a) .. " (" .. tostring(HierarchyDebugLookup[a].func)  .. ", id = " .. tostring(HierarchyDebugLookup[a].identity) .. ")")
        for k, v in cache do
            LOG(tostring(k) .. ": " .. tostring(v))
        end
    end
end

--- Checks whether a is part of the hierarchy of b, or b being part of the hierarchy of a
local function CheckHierarchy(a, b)
    local c = ChainCache

    -- populate the hierarchy chains
    ComputeHierarchyChain(a, c)
    -- if the head of chain b is part of ca, then ca is longer
    if c[b] then
        return a
    end

    ComputeHierarchyChain(b, c)
    -- if the head of chain a is part of cb, then cb is longer
    if c[a] then
        return b
    end

    -- not part of a hierarchy
    return false
end

local Seen = { }

--- Constructs a class or state, referring to the paragraphs of text at the top of this file
---@generic Base: table, T:table
---@param bases Base
---@param specs T
---@return T
function ConstructClass(bases, specs)
    -- cache as locals for performance
    local type = type
    local exclusions = Exclusions
    local hierarchy = Hierarchy
    local seen = Seen
    local class = specs

    if bases then
        -- special case: we have only one base and an empty specification: just return the base. There are a lot of empty classes
        -- being created, an example is: 

        -- UEL0001 = Class(ACUUnit) {
        --     Weapons = {
        --         DeathWeapon = Class(DeathNukeWeapon) {},
        --         RightZephyr = Class(TDFZephyrCannonWeapon) {},
        --         OverCharge = Class(TDFOverchargeWeapon) {},
        --         AutoOverCharge = Class(TDFOverchargeWeapon) {},
        --         TacMissile = Class(TIFCruiseMissileLauncher) {},
        --         TacNukeMissile = Class(TIFCruiseMissileLauncher) {},
        --     },
        --     (...)
        -- }

        -- there is no need to allocate a unique table for all those sub classes that have no specifications!
        if TableEmpty(specs) and TableGetn(bases) == 1 then
            return bases[1]
        end

        -- regular case: we have a specification or multiple bases: work to do!

        -- keep track of hierarchy chains
        for ks, s in specs do
            local t = type(s)
            if t == "function" or t == "cfunction" or t == "table" then
                for _, base in bases do
                    -- we're trying to override something here
                    if base[ks] ~= nil then
                        -- keep track of the names and give them some unique identifier
                        if enableDebugging then
                            HierarchyDebugLookupCount[ks] = HierarchyDebugLookupCount[ks] or 0
                            HierarchyDebugLookupCount[ks] = HierarchyDebugLookupCount[ks] + 1

                            -- allow us to track states specifically
                            local ts = t
                            if t == "table" and s.__State then
                                ts = "state"
                            end

                            HierarchyDebugLookup[s] = { func = ks, identity = HierarchyDebugLookupCount[ks], type = ts }  
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
        for _, base in bases do
            for l, element in base do
                if not exclusions[l] then
                    -- first time we've seen this key, keep track of it
                    if seen[l] == nil then
                        seen[l] = element

                    -- we've seen this key before and it has the same matching element: we're good
                    elseif seen[l] == element then
                        -- do nothing 

                    -- we've got two elements with the same key but different values, but our specs has a function to define the behavior: we're good
                    elseif specs[l] ~= nil then
                        -- do nothing
                    else
                        local t = type(element)

                        -- we've got two elements with the same key but different values that are states, check if their state identifiers match
                        if t == "table" and element.__State and (element.__StateIdentifier == seen[l].__StateIdentifier) then
                            -- do nothing, it is the same state

                        -- the following two statements are TECHNICALLY wrong, and should be fixed by manually determining the state

                        -- we've got two elements with the same key but different values that are states - oh no!
                        elseif t == "table" and element.__State and (element.__StateIdentifier < seen[l].__StateIdentifier) then 
                            WARN("ambiguous state with identifier: " .. tostring(l) .. ", behavior is unpredictable. Solution is to choose the desired state of the basis in the specifications - this needs to be done by the author of the mod.")
                            WARN(debug.traceback())
                            -- do nothing

                        -- we've got two elements with the same key but different values that are states - oh no!
                        elseif t == "table" and element.__State and (element.__StateIdentifier > seen[l].__StateIdentifier) then 
                            WARN("ambiguous state with identifier: " .. tostring(l) .. ", behavior is unpredictable. Solution is to choose the desired state of the basis in the specifications - this needs to be done by the author of the mod.")                           
                            WARN(debug.traceback())

                            -- switch them up, use the state made last
                            class[l] = element
                            seen[l] = element
                        else
                            -- check if one is part of the hierarchy of the other
                            local hierarchy = CheckHierarchy(seen[l], element)
                            if hierarchy then
                                class[l] = hierarchy
                                seen[l] = hierarchy
                            else -- we've got two elements with the same key but they're not part of each others hierarchy chain: ambigious!
                                error("Class initialisation: field '" .. tostring(l).. "' is ambigious between the bases. They use the same field for different values. You need to create a field in the specifications that defines the behavior.")
                            end
                        end
                    end
                end
            end
        end

        -- clean up seen
        for k, _ in seen do
            seen[k] = nil
        end

        -- populate class 
        for _, base in bases do
            for l, element in base do
                if class[l] == nil then
                    class[l] = element
                end
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
            d.__base = class
            d.__index = d
            setmetatable(d, class)

            -- override previous entry
            class[k] = d
        end
    end

    class.__index = class

    return class
end

--- Instantiation of a class, referring to the paragraphs of text at the top of this file
ClassFactory = {
    __call = function(self, ...)

        -- LOG(string.format("%s -> %s", "ClassFactory", tostring(self.__name)))

        -- create the new entity with us as its meta table
        local instance = {&1 &0}
        setmetatable(instance, self)

        -- call class initialisation functions, if they exist
        local initfn = self.__init
        if initfn then
            initfn(instance, unpack(arg))
        end
        local postinitfn = self.__post_init
        if postinitfn then
            postinitfn(instance, unpack(arg))
        end

        return instance
    end
}

UIFactory = {
    ---@param self any
    ---@param ... any
    ---@return table
    __call = function (self, ...)
        -- LOG(string.format("%s -> %s", "UIFactory", tostring(self.__name)))

        local instance = {&15 &0}
        setmetatable(instance, self)

        local initfn = self.__init
        if initfn then
            initfn(instance, unpack(arg))
        end
        local postinitfn = self.__post_init
        if postinitfn then
            postinitfn(instance, unpack(arg))
        end

        return instance
    end
}

CFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "CFactory", tostring(self.__name)))
        local instance = {&1 &0}
        return setmetatable(instance, self)
    end
}

TrashBagFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "PropFactory", tostring(self.__name)))
        local instance = {&0 &2}
        return setmetatable(instance, self)
    end
}

PropFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "PropFactory", tostring(self.__name)))
        local instance = {&7 &0}
        return setmetatable(instance, self)
    end
}

EntityFactory = {
    ---@param self any
    ---@return table
    __call = function (self, ...)
        -- LOG(string.format("%s -> %s", "EntityFactory", tostring(self.__name)))

        local instance = {&1 &0}
        setmetatable(instance, self)

        -- call class initialisation functions, if they exist
        local initfn = self.__init
        if initfn then
            initfn(instance, unpack(arg))
        end
        local postinitfn = self.__post_init
        if postinitfn then
            postinitfn(instance, unpack(arg))
        end

        return instance
    end
}

ProjectileFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "ProjectileFactory", tostring(self.__name)))
        local instance = {&7 &0}
        return setmetatable(instance, self)
    end
}

DummyProjectileFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "ProjectileFactory", tostring(self.__name)))
        -- needs a hash part of one for the _c_object field
        local instance = {&3 &0}
        return setmetatable(instance, self)
    end
}


UnitFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "UnitFactory", tostring(self.__name)))
        local instance = {&31 &0}
        setmetatable(instance, self)

        -- ACUs use this function
        local initfn = self.__init
        if initfn then
            initfn(instance)
        end

        local postinitfn = self.__post_init
        if postinitfn then
            postinitfn(instance)
        end

        return instance
    end
}

DummyUnitFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "UnitFactory", tostring(self.__name)))
        local instance = {&15 &0}
        return setmetatable(instance, self)
    end
}

WeaponFactory = {
    ---@param self any
    ---@return table
    __call = function (self, owner)
        -- LOG(string.format("%s -> %s", "WeaponFactory", tostring(self.__name)))
        local instance = {&15 &0}
        setmetatable(instance, self)

        local initfn = self.__init
        if initfn then
            initfn(instance, owner)
        end

        return instance
    end
}

ShieldFactory = {
    ---@param self any
    ---@return table
    __call = function (self, spec, owner)
        -- LOG(string.format("%s -> %s", "ShieldFactory", tostring(self.__name)))
        local instance = {&63 &0}
        setmetatable(instance, self)

        local initfn = self.__init
        if initfn then
            initfn(instance, spec, owner)
        end
        local postinitfn = self.__post_init
        if postinitfn then
            postinitfn(instance, spec, owner)
        end

        return instance
    end
}

BlipFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "BlipFactory", tostring(self.__name)))
        local instance = {&1 &0}
        return setmetatable(instance, self)
    end
}

EffectFactory = {
    ---@param self any
    ---@return table
    __call = function (self)
        -- LOG(string.format("%s -> %s", "EffectFactory", tostring(self.__name)))
        local instance = {&1 &0}
        return setmetatable(instance, self)
    end 
}

--- Switches up the sate of a class instance by inserting the new state between the instance and its class
---@param instance table The current instance we want to switch states for
---@param newState State the state we want to insert between the instance and its base class
function ChangeState(instance, newState)

    -- call on-exit function
    if instance.OnExitState then
        instance:OnExitState()
    end

    -- keep track of the original thread and forget about it inside the object
    local old_main_thread = instance.__mainthread
    instance.__mainthread = nil

    -- change the state accordingly by switching up the meta tables:
    -- - entity
    -- - state      <-- introduced as an intermediate, prevents a lot of duplicated values and tables
    -- - class
    setmetatable(instance, newState)

    -- call on-enter function
    if instance.OnEnterState then
        instance:OnEnterState()
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

--- Flattens a list of elements
---@param flattee table output table
---@param hierarchy table to be flattened
---@param seen table to prevents duplications
local function Flatten(flattee, hierarchy, seen)
    -- cache for performance
    local type = type

    for k, entry in hierarchy do
        if type(entry) == "table" then
            if not seen[entry] then
                seen[entry] = true
                Flatten(flattee, entry, seen)
            end
        else
            flattee[k] = entry
        end
    end
end

Factory = {

    -- are created via a (c) function, they either have no Lua 
    SlaveManipulator = CFactory,
    ThrustManipulator = CFactory,
    BoneEntityManipulator = CFactory,
    SlideManipulator = CFactory,
    BuilderArmManipulator = CFactory,
    RotateManipulator = CFactory,
    StorageManipulator = CFactory,
    FootPlantManipulator = CFactory,
    CollisionManipulator = CFactory,
    AnimationManipulator = CFactory,
    AimManipulator = CFactory,
    manipulator_methods = CFactory,

    CDamage = CFactory,
    sound_methods = CFactory,
    CPrefetchSet = CFactory,
    CDecalHandle = CFactory,
    EconomyEvent = CFactory,
    EntityCategory = CFactory,
    navigator_methods = CFactory,
    MotorFallDown = CFactory,
    ScriptTask_Methods = CFactory,
    aipersonality_methods = CFactory,
    userDecal_methods = CFactory,

    -- are instantiated by calling the class
    scrollbar_methods = UIFactory,
    cursor_methods = UIFactory,
    bitmap_methods = UIFactory,
    dragger_methods = UIFactory,
    control_methods = UIFactory,
    item_list_methods = UIFactory,
    movie_methods = UIFactory,
    border_methods = UIFactory,
    edit_methods = UIFactory,
    histogram_methods = UIFactory,
    frame_methods = UIFactory,
    group_methods = UIFactory,
    ui_map_preview_methods = UIFactory,
    UIWorldView = UIFactory,
    text_methods = UIFactory,

    -- are created via a (c) function,
    IEffect = EffectFactory,
    platoon_methods = nil,
    projectile_methods = ProjectileFactory,
    blip_methods = BlipFactory,
    entity_methods = EntityFactory,
    weapon_methods = WeaponFactory,
    unit_methods = UnitFactory,
    shield_methods = ShieldFactory,
    prop_methods = PropFactory,
    CollisionBeamEntity = nil,

    -- other classes that are not that relevant as they are not instantiated frequently during gameplay
    aibrain_methods = nil,
    discovery_service_methods = nil,
    WldUIProvider_methods = nil,
    lobby_methods = nil,
    mesh_methods = nil,
    world_mesh_methods = nil,
    PathDebugger_methods = nil,

    -- unused
    CAiAttackerImpl_methods = nil,
}

--- Converts a C class into a simplified Lua class with no bases. This must adjust the cclass in place as the reference
-- to the table appears to be hardcoded in the engine.
function ConvertCClassToLuaSimplifiedClass(cclass, name)
    local seen = {}
    local flatten = {}
    Flatten(flatten, cclass, seen)

    -- the reference to the table is hardcoded in the engine, therefore we need to re-populate the cclass or functions
    -- such as CreateAimManipulator that return a table with the metatable attached won't work properly :sad_cowboy:

    -- remove all entries in the class
    for k, _ in cclass do
        cclass[k] = nil
    end

    -- re-populate it
    for k, val in flatten do
        cclass[k] = val
        cclass.__name = name

        -- allow us to print it out
        if enableDebugging then
            HierarchyDebugLookupCFunctions[val] = true
        end
    end

    -- allow tables to search the meta table
    cclass.__index = cclass
    setmetatable(cclass, Factory[name] or ClassFactory)
end
