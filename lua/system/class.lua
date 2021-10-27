--[[
If class C1 defines 'x', and inherits from B1 and B2, then an 'x' coming from B1 or B2 is shadowed.
If we multiply inherit from C1 and C2, and C2 contains 'x', it's an error unless C2 got that x from B1 or B2.

Todo:
    Main() runs on a thread
    the main thread is auto-killed when we leave a state
    all kinds of manipulators need to get auto-killed when we leave a state too

    Units have a field self.StateObjects with weak keys and values
        Destroy() is called for each of those objects when changing state

    Unit:CreateThread() caches the thread in self.Threads

    changing states kills the threads?


Implementing classes in Lua

    Like almost everything in Lua, a class is represented by a table. Object instances have their metatable set
    to point to their class.

    A lua class table contains:

        key = value entries for all class members, including inherited ones

        __index points back to the class itself

        __bases is an indexed list of base classes

        __spec is the argument originally passed to Class(), which contains all the members defined for this class.

    For classes, __spec and __bases will be the same. For states they are different.


State machines

    States are declared inline within a class spec. A state acts like a class derived from its containing class,
    except that calling it changes the type of an object instead of creating a new object.
    Thus, in this example:

        A = Class {
            S1 = State { ...a1... },
            S2 = State { ...a2... },
            S3 = State { ...a3... },
        }

    We internally create three derived classes:
        A.S1 = Class(A) { ...a1... }
        A.S2 = Class(A) { ...a2... }
        A.S3 = Class(A) { ...a3... }

    Suppose class B derives from A, and overrides some of the states:

        B = Class(A) {
            S1 = State(A.S1) { ...b1... },
            S2 = State { ...b2... },
            S4 = State { ...b4... },
        }

    Note that B.S1 derives from its equivalent in A, while B.S2 does not.
    Four new classes will be created to represent the states in B:
        B.S1 = Class(A.S1, B) { ...b1... }
        B.S2 = Class(B) { ...b2... }
        B.S3 = Class(B) { ...a3... }
        B.S4 = Class(B) { ...b4... }

    Even though B's definition didn't redefine state S3, we need to create a new class to represent B.S3,
    because B.S3 is always derived from B.

'
]]


-- upvalue globals for performance
local getmetatable = getmetatable
local setmetatable = setmetatable
local ForkThread = ForkThread
local getfenv = getfenv
local type = type
local assert = assert
local unpack = unpack
local ipairs = ipairs

-- cached values
local emptyMetaTable = getmetatable {}

--
-- Class is a callable object for defining new classes, and the metatable for class objects.
--
Class = {}

--
-- ClassMeta is the metatable for Class.
--
local ClassMeta = {}
setmetatable(Class, ClassMeta)

--
-- StateProxyTag is the metaclass of temporary 'state' placeholders returned by State().
-- These get turned into class definitions when their containing class is defined.
--
StateProxyTag = {}
State = {}
local StateMeta = {}
setmetatable(State, StateMeta)


--
-- Returns true if class 'derived' is derived from class 'base'
--
local function IsDerived(derived, base)
    if base==derived then return true end
    if not derived.__bases then return false end
    for i,v in ipairs(derived.__bases) do
        if IsDerived(v, base) then
            return true
        end
    end
    return false
end


--
-- Returns true if object 'obj' is an instance of class 'class',
-- or of any of its subclasses.
--
function IsInstance(obj,class)
    return IsDerived(getmetatable(obj),class)
end


local function InsertIndexFields(c, index, wherefrom)
    local fakederived = nil
    for k,v in c.__spec do
        if type(k)=='string' then
            if not wherefrom[k] then
                wherefrom[k] = c
                index[k] = v
            elseif wherefrom[k]=='special' then
                -- ok - this is a special field which we never copy from base classes
            elseif IsDerived(wherefrom[k],c) then
                -- ok - our value was overridden by a derived class
            elseif IsDerived(c,wherefrom[k]) then
                -- ok - we are a derived class of whoever's there already
                -- fixme: this doesn't handle fakederived correctly
                wherefrom[k] = c
                index[k] = v
            elseif v==index[k] then
                -- ok - it's technically ambiguous, but both values are the same so it's not a problem
                fakederived = fakederived or {}
                fakederived[wherefrom[k]] = { __bases = { wherefrom[k], c }}
                wherefrom[k] = fakederived[wherefrom[k]]
            else
                error("field '"..tostring(k).."' is ambiguous in class definition")
            end
        end
    end

    if c.__bases then
        for i,base in ipairs(c.__bases) do
            InsertIndexFields(base, index, wherefrom)
        end
    end
end


local function SetupClassFields(c, bases, spec, meta)
    c.__index = c
    c.__spec = spec
    c.__bases = bases

    InsertIndexFields(c, c.__index, { __index='special', __spec='special', __bases='special' })

    setmetatable(c, meta)

    return c
end


local function StateProxiesToClasses(c)
    --
    -- States are handled specially. Each state is basically a class derived from the containing class.
    -- Switching states switches our metatable, i.e. changes the type of the object.
    --
    -- The State{} function is just a syntactic placeholder that marks the state spec as a proxy object.
    -- It can't actually create the state class, because the containing class hasn't been created yet.
    -- This function is used during the containing class creation to create real states in place of the proxy objects.
    --
    local new_states = {}
    assert(c.__index == c)
    for k,v in c do
        -- Class specs should never have actual states as fields coming into this function, because the behavior
        -- won't be what you expect.
        assert(getmetatable(v) ~= State)

        if getmetatable(v) == StateProxyTag then
            local s = SetupClassFields({}, {c,unpack(v.__bases or {})}, v.__spec, State)
            s.__state = k
            new_states[k] = s
        end
    end

    for k,s in new_states do
        assert(getmetatable(c[k])==StateProxyTag)
        assert(getmetatable(s)==State)
        c[k] = s
        for k2,s2 in new_states do
            assert(getmetatable(s[k2])==StateProxyTag)
            assert(getmetatable(s2)==State)
            s[k2] = s2
        end
    end
end

local function MakeClass(bases, spec)
    if spec[1] then
        error 'Class specification contains indexed elements; it should contain only name=value elements'
    end
    local c = SetupClassFields({}, bases, spec, Class)
    StateProxiesToClasses(c)
    return c
end
local IntermediateClassMeta = { __call = MakeClass }

--
-- Invoking Class() creates a new class.  The created class is used as
-- the metatable for instances of the class.
--
-- Class() can be called as:
--   Class { field=value, field=value, ... }     for a class with no bases
--   Class(Base1,Base2,...BaseN)                 for a class with base classes
--
function ClassMeta:__call(...)
    if arg.n==1 and getmetatable(arg[1])==getmetatable {} then
        return MakeClass(nil, arg[1])
    end

    for i,base in ipairs(arg) do
        if getmetatable(base) ~= Class and getmetatable(base) ~= State then
            error 'Something other than a Class or State was used for a base class'
        end
    end
    local temp = { unpack(arg) }
    setmetatable(temp, IntermediateClassMeta)
    return temp
end


--
-- Invoking a class (note: this is not the same as invoking Class itself)
-- creates a new instance of the class.
--
function Class:__call(...)
    --
    -- create the new object
    --
    local newobject = {}
    setmetatable(newobject, self)

    --
    -- call the class constructor, if one was defined
    --
    local initfn = self.__init
    if initfn then
        initfn(newobject,unpack(arg))
    end
    local postinitfn = self.__post_init
    if postinitfn then
        postinitfn(newobject,unpack(arg))
    end
    return newobject
end

--
-- Disallow setting fields on a class after the fact. Unfortunately we can't catch all changes here--if the
-- field already exists, Lua will allow it to be changed without triggering any hooks. But we can at least
-- catch attempts to add new fields.
--
function Class:__newindex(key,value)
    error('Attempted to add field "'..tostring(key)..'" after class was defined.')
end

--
-- Invoking State() creates a placeholder for a new state. It doesn't become
-- a "real" state until its containing class is created.
--
local function MakeStateProxy(bases, spec)
    if spec[1] then
        error 'State specification contains indexed elements; it should contain only name=value elements'
    end

    -- sanity check: a state's definition should not contain other states or state proxies, or things will break
    for k,v in spec do
        assert(getmetatable(v) ~= StateProxyTag)
        assert(getmetatable(v) ~= State)
    end
    local proxy = { __bases=bases, __spec=spec }
    setmetatable(proxy, StateProxyTag)
    return proxy
end
local IntermediateStateMeta = { __call = MakeStateProxy }


function StateMeta:__call(...)
    if arg.n==1 and getmetatable(arg[1])==getmetatable {} then
        return MakeStateProxy(nil, arg[1])
    end

    for i,base in ipairs(arg) do
        if getmetatable(base) ~= Class and getmetatable(base) ~= State then
            error 'Something other than a Class or State was used for a base class'
        end
    end
    local temp = { unpack(arg) }
    setmetatable(temp, IntermediateStateMeta)
    return temp
end

--
-- Invoking a state changes an object's type to the state and calls various trigger functions.
--
--   Changing states:
--
--       1. Kills the main thread if it was running
--
--       2. Calls obj:OnExitState() while still in the old state.
--
--       3. Changes the type of the object to the new state
--
--       4. Calls obj:OnEnterState(). OnEnterState() is allowed to immediately switch to a new state.
--
--       5. If obj:Main() is defined, starts it on a thread
--
function ChangeState(obj, newstate)
    --LOG('*DEBUG: CHANGESTATE: ', repr(obj), repr(newstate))
    if type(newstate)=='string' then
        newstate = obj[newstate]
    end

    -- Ignore redundant state changes.
    if getmetatable(obj)==newstate then
        debug.traceback(nil, "Ignoring no-op state change...")
        return
    end

    -- Call state on-exit function, if there is one
    local OnExitState = obj.OnExitState
    if OnExitState then
        OnExitState(obj)
    end

    local old_main_thread = obj.__mainthread
    obj.__mainthread = nil

    -- Actually change the state
    setmetatable(obj,newstate)

    -- Call the state on-enter function, if there is one
    local OnEnterState = obj.OnEnterState
    if OnEnterState then
        OnEnterState(obj)
    end

    -- Start the new main thread. Note that OnEnterState() might have switched states on us, in which case the main
    -- thread will already have been started by that state switch. We test for obj.__mainthread to avoid starting
    -- it twice.
    local Main = obj.Main
    if Main and not obj.__mainthread then
        obj.__mainthread = ForkThread(Main,obj)
    end

    -- Kill the old main thread. We do this AFTER calling OnEnterState and starting the new main thread,
    -- because the thread we destroy may be ourselves.
    if old_main_thread then
        old_main_thread:Destroy()
    end
end

function ConvertCClassToLuaClass(cclass)
    -- check if already done
    if getmetatable(cclass)==Class then
        return
    end

    for i,base in ipairs(cclass) do
        ConvertCClassToLuaClass(base)
    end

    -- copy the C class into a temp variable to use as the class spec, then turn the C class into an actual instance
    local spec = {}
    for k,v in cclass do
        spec[k] = v
    end
    for k,v in spec do
        cclass[k] = nil
    end
    SetupClassFields(cclass,spec,spec,Class)
end

function startClass(...)   ------added for shipwreck mod
    -- class prototype table
    local proto = {}
    -- original caller environment
    local env = getfenv(2)

    -- the default 'endClass' function
    -- the metamethod for __newindex above will override this if the user behaves
    -- if this gets called, they _aren't_ behaving, so error
    function proto.endClass()
        error("Attempted to create a class without assigning it to anything!")
    end

    -- metatable for prototype
    local mt = {}

    -- __index: retain access to global variables
    mt.__index = env

    -- __newindex: trap the first assignment so that MyClass = startClass(...) works
    function mt:__newindex(key, value)
        -- delete ourselves; we only want to trigger on the first assignment
        mt.__newindex = nil

        -- new endClass() function that does the real work
        function proto.endClass()
            -- restore original environment
            setfenv(2, env)
            -- tidy up
            proto.endClass = nil
            setmetatable(proto, nil)
            for k,v in pairs(proto) do
                if type(v) == 'function' then
                    setfenv(v, env)
                end
            end
            -- create class object and assign to caller's environment with the
            -- key they originally specified
            if arg.n == 0 then
                env[key] = Class(proto)
            else
                env[key] = Class(unpack(arg))(proto)
            end
        end
    end

    setmetatable(proto, mt)
    setfenv(2, proto)
end
