-- lust v0.1.0 - Lua test framework
-- https://github.com/bjornbytes/lust
-- MIT LICENSE
-- Modified by Askaholic for lua 5.0
-- Extended by Hdt80bro

-- Useful for better test output
require "../lua/system/repr.lua"


---@class Lust
---@field befores? fun(name: string)[]
---@field afters? fun(name: string)[]
local Lust = {}

---@class LustAssertion
---@field values any[]    starting values to form expectation under
---@field action string   current action path
---@field negate boolean
---@field support? any[]  support values for the expectation
local Assertion = {}

---@class LustSpy
---@field capture function
local Spy = {}



----------------------------------------
---  Environment setup
----------------------------------------

local environmentName
local tab = '\t'
local printTestResult
local printer = print

do
    local oldenv = {}
    for k, v in _G do
        oldenv[k] = v
    end

    local environments = {
        ------------------------------
        --- FA init file environment
        ------------------------------
        FA = function()
            tab = (' '):rep(4)
            printer = LOG -- `print` won't work in FA
            printTestResult = function(name, success, err)
                if success then
                    print("PASS " .. name)
                else
                    local sublvl = Lust.sublevel
                    if sublvl then
                        name = name .. ":" .. sublvl
                    end
                    print("FAIL " .. name)
                end
                if err then
                    print(tab .. err)
                end
            end
        end;
        ------------------------------
        --- Github workflow environment
        ------------------------------
        GH = function()
            local esc = string.char(27)
            local red = esc .. "[31m"
            local green = esc .. "[32m"
            local normal = esc .. "[0m"

            printTestResult = function(name, success, err)
                if success then
                    print(green .. "PASS" .. normal .. " " .. name)
                else
                    local sublvl = Lust.sublevel
                    if sublvl then
                        name = name .. ":" .. sublvl
                    end
                    print(red .. "FAIL" .. normal .. " " .. name)
                end
                if err then
                    print(tab .. red .. err .. normal)
                end
            end
        end;
    }

    -- primitive check for FA environment
    if LOG ~= nil then
        environmentName = "FA"
    else
        environmentName = "GH"
    end
    environments[environmentName]() -- load environment

    -- make printing functions use relative indentation
    function print(...)
        printer(Lust.indent .. table.concat(arg, '\t'))
    end

    -- if a global called `test_path` is provided, update relative paths to use it
    if test_path then
        local _dofile = oldenv.dofile
        -- modify `dofile` to be relative to the test directory
        function dofile(file)
            _dofile(test_path .. file)
        end
    end
end



----------------------------------------
---  Lua Unit Tester
----------------------------------------

Lust.level = 0
Lust.passes = 0
Lust.errors = 0
Lust.indent = ""

--- Starts a new test description, scoping new `before` and `after` functions added inside
--- the function
---@param name string
---@param fn fun(...)
---@param ... any
---@return Lust
function Lust.describe(name, fn, ...)
    local level = Lust.level
    local indent = Lust.indent
    local befores, afters = Lust.befores, Lust.afters
    local restore_befores_n, restore_afters_n

    if befores then
        restore_befores_n = table.getn(befores)
    end
    if afters then
        restore_afters_n = table.getn(afters)
    end

    print(name)
    Lust.level = level + 1
    Lust.indent = indent .. tab
    fn(unpack(arg))
    Lust.indent = indent
    Lust.level = level

    if befores then
        table.setn(befores, restore_befores_n)
    end
    if afters then
        table.setn(afters, restore_afters_n)
    end
    return Lust
end

--- Starts a new test description for each item in a list
---@param pattern string
---@param list table
---@param fn fun(item: any)
---@return Lust
function Lust.describe_each(pattern, list, fn)
    for name, item in pairs(list) do
        Lust.describe(pattern:format(name), fn, name, item)
    end
    return Lust
end

--- Runs a unit test, running all `before` and `after` functions of all described test levels,
--- and then prints the test results.
---@param name string
---@param fn any
---@param ... any
---@return Lust
function Lust.it(name, fn, ...)
    local befores = Lust.befores
    if befores then
        for i = 1, table.getn(befores) do
            befores[i](name)
        end
    end

    local success, err = pcall(fn, unpack(arg))
    if success then
        Lust.passes = Lust.passes + 1
    else
        Lust.errors = Lust.errors + 1
    end
    printTestResult(name, success, err)

    local afters = Lust.afters
    if afters then
        for i = 1, table.getn(afters) do
            afters[i](name)
        end
    end
    return Lust
end
Lust.test = Lust.it

--- Runs a new test over each item in a list
---@param pattern string
---@param list table
---@param fn fun(item: any)
---@return Lust
function Lust.test_each(pattern, list, fn)
    for key, item in pairs(list) do
        Lust.test(pattern:format(key), fn, item)
    end
    return Lust
end

--- Runs a test function over each item in a list as a single test, each item as a subtest
---@param name string
---@param list table
---@param fn fun(item: any)
---@return Lust
function Lust.test_all(name, list, fn)
    Lust.test(name, function()
        for key, item in pairs(list) do
            Lust.subtest(key)
            fn(item)
        end
    end)
    return Lust
end

--- Indicates that the following assertions are under a subtest group
---@param num any
---@return Lust
function Lust.subtest(num)
    Lust.sublevel = num
    return Lust
end

--- Registers a function to run before each test in the current test scope
---@param fn fun(name: string)
---@return Lust
function Lust.before(fn)
    local befores = Lust.befores
    if not befores then
        befores = {}
        Lust.befores = befores
    end
    table.insert(befores, fn)
    return Lust
end

--- Registers a function to run after each test in the current test scope
---@param fn fun(name: string)
---@return Lust
function Lust.after(fn)
    local afters = Lust.afters
    if not afters then
        afters = {}
        Lust.afters = afters
    end
    table.insert(afters, fn)
    return Lust
end

--- Exits if there are errors
---@return Lust
function Lust.finish()
    if Lust.errors ~= 0 then
        os.exit(-1)
    end
    return Lust
end


------------------------------
--- Assertions
------------------------------

----------
-- test functions
----------

---@param v any
---@param x any
---@return boolean
local function isa(v, x)
    if type(x) == "string" then
        return type(v) == x
    elseif type(x) == "table" then
        if type(v) ~= "table" then
            return false
        end
        local seen = {}
        local meta = v
        while meta and not seen[meta] do
            if meta == x then return true end
            seen[meta] = true
            meta = getmetatable(meta).__index
        end
        return false
    end
    error("invalid type " .. repr(x))
end

---@param t any
---@param x any
---@return boolean
local function has(t, x)
    for _, v in pairs(t) do
        if v == x then return true end
    end
    return false
end

---@param t1 any
---@param t2 any
---@return boolean
local function strict_eq(t1, t2)
    if type(t1) ~= type(t2) then
        return false
    end
    if type(t1) ~= "table" then
        return t1 == t2
    end
    for k, _ in pairs(t1) do
        if not strict_eq(t1[k], t2[k]) then return false end
    end
    for k, _ in pairs(t2) do
        if not strict_eq(t2[k], t1[k]) then return false end
    end
    return true
end

---@param v1 number
---@param v2 number
---@param scale number
---@return boolean
local function fpoint_within(v1, v2, scale)
    return math.abs(v1 - v2) < math.abs(scale)
end


--------------------
-- Assertion class
--------------------

local paths, aliases, callEach

--- Starts an assertion statement
---@param ... any
---@return LustAssertion
function Lust.expect(...)
    local assertion = {
        values = arg,
        action = "",
        negate = false,
    }
    setmetatable(assertion, Assertion)

    return assertion
end

Assertion.__index = function(self, k)
    local alias = aliases[k]
    if alias then
        k = alias
    end
    if has(paths[rawget(self, "action")], k) then
        rawset(self, "action", k)
        local chain = paths[k].chain
        if chain then
            chain(self)
        end
        return self
    end
    return rawget(self, k)
end

Assertion.__call = function(t, ...)
    local path = paths[t.action]
    local test = path.test
    if test then
        local errMsg = t.negate and path.not_fail_string or path.fail_string
        local support = t.support
        if path.requires_support and not support then
            error("expected support values")
        end
        callEach(test, t.negate, errMsg, t.values, arg, support)
    else
        local chain_call = path.chain_call
        if chain_call then
            chain_call(t, unpack(arg))
            return t
        end
    end
end

----------
-- path parsing
----------

---@class LustSemanticPath
---@field chain?  fun(a: LustAssertion)  called after simple chaining e.g. a`.b`.c 
---@field chain_call?  fun(a: LustAssertion, ...)  called after chained calling e.g. a`.b()`.c
---@field test?  fun(...): boolean   function to test with all arguments (from the starting values, calling arguments, and support values); expects both `fail_string` formatters to be defined
---@field fail_string?      string   formatter for unnegated tests, where `$x` indicates the `x`th argument to replace
---@field not_fail_string?  string   formatter for negated tests, where `$x` indicates the `x`th argument to replace
---@field requires_support?  boolean if the path action test requires support values to be previously set

---@type table<string, LustSemanticPath>
paths = {
    [""] = { "to", "to_not" },
    to = { "have", "equal", "be", "exist", "fail" },
    to_not = { "have", "equal", "be", "exist", "fail",
        chain = function(a)
            a.negate = not a.negate
        end;
    },
    within = { "of",
        chain_call = function(a, ...)
            a.support = arg
        end;
    },
    an = {
        test = isa,
        fail_string = "expected $1 to be a $2",
        not_fail_string = "expected $1 to not be a $2",
    },
    be = { "an", "truthy", "within",
        test = function(v, x)
            return v == x
        end;
        fail_string = "expected $1 and $2 to be equal",
        not_fail_string = "expected $1 and $2 to not be equal",
    },
    exist = {
        test = function(v)
            return v ~= nil
        end;
        fail_string = "expected $1 to exist",
        not_fail_string = "expected $1 to not exist",
    },
    truthy = {
        test = function(v)
            if v then
                return true
            end
            return false
        end;
        fail_string = "expected $1 to be truthy",
        not_fail_string = "expected $1 to be falsy",
    },
    equal = {
        test = strict_eq,
        fail_string = "expected $1 and $2 to be exactly equal",
        not_fail_string = "expected $1 and $2 to not be exactly equal",
    },
    have = {
        test = function(v, x)
            if type(v) ~= "table" then
                error("expected " .. repr(v) .. " to be a table")
            end
            return has(v, x)
        end;
        fail_string = "expected $1 to contain $2",
        not_fail_string = "expected $1 to not contain $2",
    },
    fail = {
        test = function(v)
            return not pcall(v)
        end;
        fail_string = "expected $1 to fail",
        not_fail_string = "expected $1 to succeed",
    },
    of = {
        test = fpoint_within,
        fail_string = "expected $1 to be within $3 of $2",
        not_fail_string = "expected $1 to not be within $3 of $2",
        requires_support = true,
    },
}
Lust.paths = paths

aliases = {
    a = "an",
}
Lust.aliases = aliases

----------
-- iterative tester
----------

---@param negate boolean
---@param errMsg string
---@param okay boolean
---@param err boolean | string
---@return string?
local function getError(negate, errMsg, okay, err)
    if okay then
        -- function was called with no errors; `err` is the return value to compare
        if (not err) ~= negate then
            return errMsg
        else
            return nil
        end
    else
        -- function had errors; `err` is the actual Lua error
        if negate then
            return nil
        else
            return err
        end
    end
end

---@param test fun(...): boolean, string
---@param negate boolean
---@param errMsg string?
---@param values? any[]
---@param args? any[]
---@param support? any[]
callEach = function(test, negate, errMsg, values, args, support)
    errMsg = errMsg or "unknown failure"
    local arguments = {}
    local argCount = 0

    local lists, iterators = {}, {}
    if values then   table.insert(lists, values)   end
    if args then     table.insert(lists, args)     end
    if support then  table.insert(lists, support)  end

    local eachn
    -- find the number of times we will be iterating
    for _, list in ipairs(lists) do
        local n = list.n
        if n > 0 then
            eachn = n
            break
        end
    end
    if not eachn then
        -- there must not be *any* arguments
        local err = getError(negate, errMsg, pcall(test))
        if err then
            error(err, 2)
        end
        return
    end

    -- reserve one argument for each iterating argument
    for k, list in ipairs(lists) do
        if list.n >= eachn then
            argCount = argCount + 1
            iterators[k] = argCount
        end
    end

    -- the rest of the non-iterating values in each list will be added as extra arguments
    for k, list in ipairs(lists) do
        local start = 1
        if iterators[k] then
            start = eachn + 1
        end
        for i = start, list.n do
            argCount = argCount + 1
            arguments[argCount] = list[i]
        end
    end

    -- now do the actual iteration
    for i = 1, eachn do
        -- set the iterating arguments
        for k, list in ipairs(lists) do
            local iter = iterators[k]
            if iter then
                arguments[iter] = list[i]
            end
        end

        -- then run the test with the argument list
        local err = getError(negate, errMsg, pcall(test, unpack(arguments)))
        if err then
            if eachn > 1 then
                -- in order to produce more meaningful error messages, all of the iterating lists
                -- are displayed in the error instead of only the current value of each iterator
                for k, list in ipairs(lists) do
                    if not iterators[k] then continue end
                    local rep = repr(list[1])
                    for j = 2, list.n do
                        rep = rep .. ", " .. repr(list[j])
                    end
                    arguments[iterators[k]] = '{' .. rep .. '}'
                end
            end
            for j = 1, argCount do
                err = err:gsub("$" .. j, repr(arguments[j]))
            end
            error(err, 3)
        end
    end
end


------------------------------
--- Spying
------------------------------

---@overload fun(target: function, run?: fun(spy: LustSpy)): LustSpy
--- Returns a transparent callable object for a function target that collects all arguments
---@param target table
---@param name any
---@param run? fun(spy: LustSpy) run after the spy is created
---@return LustSpy
function Lust.spy(target, name, run)
    local spy = {}
    setmetatable(spy, Spy)

    local function capture(...)
        table.insert(spy, arg)
        local tar = target
        if tar then
            return tar(unpack(arg))
        end
    end
    spy.capture = capture

    if type(target) == "table" then
        local intercept = target[name]
        target[name] = capture
        target = intercept
    else
        run = name
    end

    if run then run(spy) end

    return spy
end

Spy.__call = function(self, ...)
    return self.capture(unpack(arg))
end


return Lust
