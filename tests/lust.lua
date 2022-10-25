-- lust v0.1.0 - Lua test framework
-- https://github.com/bjornbytes/lust
-- MIT LICENSE
-- Modified by Askaholic for lua 5.0
-- Extended by Hdt80bro

-- Useful for better test output
require "../lua/system/repr.lua"

local print, error = print, error
local red, green, normal, tab = "", "", "", (' '):rep(4)
if LOG then
    print = LOG -- `print` won't work in FA
    -- error = function(msg, lvl) -- we want sensical errors
    --     LOG(_TRACEBACK(lvl + 1, msg))
    --     os.exit(-1)
    -- end
else
    local esc = string.char(27)
    red = esc .. "[31m"
    green = esc .. "[32m"
    normal = esc .. "[0m"
    tab = '\t'
end

local lust = {
    level = 0,
    sublevel = 0,
    passes = 0,
    errors = 0,
    befores = {},
    afters = {},
    indent = "",
}

function lust.finish()
    if lust.errors ~= 0 then
        os.exit(-1)
    end
    return lust
end

function lust.describe(name, fn)
    lust.sublevel = 0
    local level = lust.level
    local indent = lust.indent
    lust.level = level + 1
    lust.indent = indent .. tab
    print(indent .. name)
    fn()
    lust.indent = indent
    lust.level = level
    lust.befores[level] = {}
    lust.afters[level] = {}
    return lust
end

function lust.testeach(name, list, fn, ...)

    return lust
end

function lust.it(name, fn)
    lust.sublevel = 0
    local befores = lust.befores
    for level = 1, lust.level do
        local beforeLevel = befores[level]
        if beforeLevel then
            for i = 1, table.getn(beforeLevel) do
                beforeLevel[i](name)
            end
        end
    end

    local success, err = pcall(fn)
    if success then
        lust.passes = lust.passes + 1
    else
        lust.errors = lust.errors + 1
    end
    local color = success and green or red
    local label = success and "PASS" or "FAIL"
    local displayName = name
    if lust.sublevel then
        displayName = displayName .. ':' .. lust.sublevel
    end
    print(lust.indent .. color .. label .. normal .. " " .. displayName)
    if err then
        print(lust.indent .. tab .. red .. err .. normal)
    end

    local afters = lust.afters
    for level = 1, lust.level do
        local afterLevel = afters[level]
        if afterLevel then
            for i = 1, table.getn(afterLevel) do
                afterLevel[i](name)
            end
        end
    end
    return lust
end

function lust.subtest(num)
    lust.sublevel = num
    return lust
end

function lust.before(fn)
    local befores, level = lust.befores, lust.level
    local beforeLevel = befores[level]
    if not befores then
        beforeLevel = {}
        befores[level] = beforeLevel
    end
    table.insert(beforeLevel, fn)
end

function lust.after(fn)
    local afters, level = lust.afters, lust.level
    local afterLevel = afters[level]
    if not afters then
        afterLevel = {}
        afters[level] = afterLevel
    end
    table.insert(afterLevel, fn)
end

-- Assertions
local function isa(v, x)
    if type(x) == "string" then
        LOG(type(v))
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

local function has(t, x)
    for _, v in pairs(t) do
        if v == x then return true end
    end
    return false
end

local function strict_eq(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    for k, _ in pairs(t1) do
        if not strict_eq(t1[k], t2[k]) then return false end
    end
    for k, _ in pairs(t2) do
        if not strict_eq(t2[k], t1[k]) then return false end
    end
    return true
end

local function fpoint_within(v1, v2, scale)
    return math.abs(v1 - v2) < math.abs(scale)
end

local paths
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
    a = {
        test = isa,
        fail_string = "expected $1 to be a $2",
        not_fail_string = "expected $1 to not be a $2",
    },
    an = paths.a,
    be = { "a", "an", "truthy", "within",
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
            return v
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

---@param test function
---@param negate boolean
---@param errMsg string?
---@param values? any[]
---@param args? any[]
---@param support? any[]
local function callEach(test, negate, errMsg, values, args, support)
    errMsg = errMsg or "unknown failure"
    local arguments = {}
    local argCount = 0

    local lists, iterator = {}, {}
    if values then   table.insert(lists, values)   end
    if args then     table.insert(lists, args)     end
    if support then  table.insert(lists, support)  end

    local eachn
    -- find the number of times we are iterating
    for _, list in ipairs(lists) do
        local n = list.n
        if n > 0 then
            eachn = n
            break
        end
    end
    if not eachn then
        -- there must not be *any* arguments
        local res, err = test()
        if (not res) ~= negate then
            err = err or errMsg
        end
        if err then
            error(err, 2)
        end
        return
    end

    -- reserve one argument for each iterating argument
    for k, list in ipairs(lists) do
        if list.n >= eachn then
            argCount = argCount + 1
            iterator[k] = argCount
        end
    end

    -- the rest of the non-iterating values in each list will be added as extra arguments
    for k, list in ipairs(lists) do
        local start = 1
        if iterator[k] then
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
            local iter = iterator[k]
            if iter then
                arguments[iter] = list[i]
            end
        end

        -- then run the test with the argument list
        local res, err = test(unpack(arguments))
        if (not res) ~= negate then
            err = err or errMsg
        end
        if err then
            if eachn > 1 then
                -- in order to produce more meaningful error messages, all of the iterating lists
                -- are displayed in the error instead of only the current value of each iterator
                for k, list in ipairs(lists) do
                    if not iterator[k] then continue end
                    local rep = repr(list[1])
                    for j = 2, list.n do
                        rep = rep .. ", " .. repr(list[j])
                    end
                    arguments[iterator[k]] = '{' .. rep .. '}'
                end
            end
            for j = 1, argCount do
                err = err:gsub("$" .. j, repr(arguments[j]))
            end
            error(err, 3)
        end
    end
end

local expectationMetatable = {
    __index = function(t, k)
        if has(paths[rawget(t, "action")], k) then
            rawset(t, "action", k)
            local chain = paths[k].chain
            if chain then
                chain(t)
            end
            return t
        end
        return rawget(t, k)
    end,
    __call = function(t, ...)
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
}

function lust.expect(...)
    local assertion = {
        values = arg,
        action = "",
        negate = false,
    }
    setmetatable(assertion, expectationMetatable)

    return assertion
end

function lust.spy(target, name, run)
    local spy = {}
    local subject

    local function capture(...)
        table.insert(spy, arg)
        return subject(unpack(arg))
    end

    if type(target) == "table" then
        subject = target[name]
        target[name] = capture
    else
        run = name
        subject = target or function() end
    end

    setmetatable(spy, {__call = function(_, ...) return capture(unpack(arg)) end})

    if run then run() end

    return spy
end

lust.test = lust.it
lust.paths = paths

if test_path then
    local oldDofile = dofile
    -- modify `dofile` to be relative to the test directory
    function dofile(file)
        oldDofile(test_path .. file)
    end
end

return lust
