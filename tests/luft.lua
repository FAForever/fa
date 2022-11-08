-- lust v0.1.0 - Lua test framework
-- https://github.com/bjornbytes/lust
-- MIT LICENSE
--
-- Modified by Askaholic for lua 5.0
-- Extended by Hdt80bro

-- Useful for better test output
require "../lua/system/repr.lua"

---@class Luft
---@field print fun(...)      printer used by the `out` function family
---@field tab string          tab string used by the indentation system
---@field environment string  name of the loaded environment
---@field strings table<string, string> set of strings used for printing or formatting; change these for localization or environment needs
---@field total_module_passes number
---@field total_module_errors number
---@field total_module_assertions number
---
---@field befores? fun(name: string)[]  list of functions to run before each test
---@field afters? fun(name: string)[]   list of functions to run after each test
---@field indentation string        current indentation prepended to output
---@field indentation_level number  current indentation level
---@field level number              current test description level
---@field sublevel any              current subtest name
---@field expectation_number number current assertion number
---@field passes number             current number of passed tests
---@field errors number             current number of failed tests
---@field assertions number         current number of assertions
local Luft = {}

---@class LuftAssertion
---@field values any[]    starting values to form expectation under
---@field head   LuftPathNode
---@field negate boolean
---@field support? any[]  support values for the expectation
local Assertion = {}

---@class LuftPathNode
---@field Name string
---@field Alias? string
---@field NotName? string
---@field NotAlias? string
---@field Chain?  fun(a: LuftAssertion)  called after simple chaining e.g. a`.b`.c
---@field ChainCall?  fun(a: LuftAssertion, ...)  called after chained calling e.g. a`.b()`.c
---@field Test?  fun(...): boolean        function to test with all arguments (from the starting values, calling arguments, and support values); expects both `FailString` formatters to be defined
---@field Parameters number               number of parameters the test function has
---@field FailString?      string   formatter for unnegated tests, where `$x` indicates the `x`th argument to replace. auto genertes `NotFailString` if that one is absent by replacing "to " with "to not "
---@field NotFailString?  string    formatter for negated tests, where `$x` indicates the `x`th argument to replace
---@field RequiresSupport? boolean  if the node action test requires support values to be previously set
local PathNode = {}

---@class LuftSpy
---@field capture function
local Spy = {}


----------------------------------------
-- Environment setup
----------------------------------------

Luft.environment = ""
Luft.tab = '\t'
Luft.print = print
Luft.strings = {
    pass = "PASS",
    fail = "FAIL",
    bad_argument_count = "expected %s arguments, but got %s", -- expected args, actual args
    subtest_fail = "%s %s, subtest %s, assertion %s:", -- result indicator, test name, subtest name, expect number
    test_fail = "%s %s, assertion %s:",                -- result indicator, test name, expect number
    test_success = "%s %s",                           -- result indicator, test name
    unknown_error = "unknown error",
    support_required = "expected support values",
    condition_unnegated = "to",
    condition_negated =   "to not",
    type_nil =      "nil",
    type_nonnil =   "non-nil",
    type_truthy =   "truthy",
    type_falsy =    "falsy",
    type_boolean =  "a boolean",
    type_number =   "a number",
    type_integer =  "an integer",
    type_float =    "a float",
    type_string =   "a string",
    type_function = "a function",
    type_userdata = "userdata",
    type_table =    "a table",
    type_positive =    "positive",
    type_nonpositive = "non-positive",
    type_negative =    "negative",
    type_nonnegative = "non-negative",
    cond_exist = "exist",
    cond_an = "an %s",  -- type
    cond_equal = "equal",
    cond_unequal = "unequal",
    cond_succeed = "succeed",
    cond_fail = "fail",
    cond_strict_eq = "exactly equal",
    cond_contains = "contain %s",    -- contained
    cond_within = "within %s of %s", -- error, target
    expectation1 =   "expected %s %s %s",            -- value, state condition, expected
    expectation1be = "expected %s %s be %s",         -- value, state condition, expected
    expectation2 =   "expected %s and %s %s %s",     -- value1, value2, state condition, expected
    expectation2be = "expected %s and %s %s be %s",  -- value1, value2, state condition, expected
}
Luft.modules_ran = 0
Luft.total_module_errors = 0
Luft.total_module_passes = 0
Luft.total_module_assertions = 0

local environments = {
    ------------------------------
    --- FA init file environment
    ------------------------------
    FA = {
        tab = (' '):rep(4),
        print = LOG, -- pipe everything to the LOG instead of the invisible commandline
        finish = function()
            if Luft.errors ~= 0 then
                -- each test is run from the same process in the init file, so we can't exit yet
                Luft.out("Test module finished with errors!")
            end
            return Luft
        end;
        OnLoad = function()
            -- Moho still differentiates function from cfunctions, which throws some tests
            local oldType = type
            function type(x)
                local tt = oldType(x)
                if tt == "cfunction" then
                    return "function"
                end
                return tt
            end
        end;
    },
    ------------------------------
    --- Github workflow environment
    ------------------------------
    GH = {
        -- ANSI CSI SGR supported; use that for colors
        string_color = function(col, str)
            local colors = Luft.colors
            col = colors[col]
            if col then
                -- make sure to replace color resets already in the string to be the color we're
                -- setting it to (so that nesting works)
                return col .. str:gsub(colors.reset, col) .. colors.reset
            end
            return str
        end;
        OnLoad = function()
            local esc = string.char(27)
            Luft.colors = {
                red = esc .. "[31m",
                green = esc .. "[32m",
                reset = esc .. "[0m",
            }
        end;
    },
}

-- primitive check for FA environment
if LOG ~= nil then
    Luft.environment = "FA"
else
    Luft.environment = "GH"
end

-- load environment
local env = environments[Luft.environment]
if env.OnLoad then
    env:OnLoad()
end
local function addTo(augend, addand, merge)
    for key, val in addand do
        -- ignore meta-type fields (like "_merge")
        if tostring(key):sub(1, 1) == "_" then continue end
        if type(val) == "table" then
            local existing = augend[key]
            if type(existing) == "table" and (merge or val._merge) then
                addTo(existing, val, true)
                continue
            end
        end
        augend[key] = val
    end
end
addTo(Luft, env)


--- Formats a string to be printed a certain color, if the environment supports it
---@param col string
---@param str string
---@return string
Luft.string_color = Luft.string_color or function(col, str)
    return str
end

-- if a global called `test_path` is provided, update relative paths to use it
if test_path then
    local _dofile = dofile
    -- modify `dofile` to be relative to the test directory
    function dofile(file)
        _dofile(test_path .. file)
    end
end


----------------------------------------
-- Unit Test IO Setup
----------------------------------------


--- Resets the testing state. Automatically called when a 0-level test description encounters
--- garbage.
---@return Luft
Luft.start = Luft.start or function()
    if Luft.passes then
        Luft.total_module_passes = Luft.total_module_passes + Luft.passes
    end
    if Luft.errors then
        Luft.total_module_errors = Luft.total_module_errors + Luft.errors
    end
    if Luft.assertions then
        Luft.total_module_assertions = Luft.total_module_assertions + Luft.assertions
    end
    Luft.margin_of_error = 0.01
    Luft.indentation = ""
    Luft.indentation_level = 0
    Luft.level = 0
    Luft.passes = 0
    Luft.errors = 0
    Luft.assertions = 0
    Luft.modules_ran = Luft.modules_ran + 1
    return Luft
end

--- Exits if there are errors
---@return Luft
Luft.finish = Luft.finish or function()
    if Luft.errors ~= 0 then
        os.exit(-1)
    end
    return Luft
end

--------------------
-- indentation system
--------------------

---@overload fun(fn: function, ...)
--- Indents a level for the function
---@param amt number defaults to `1`
---@param fn function
---@param ... any
function Luft.indent(amt, fn, ...)
    local indentlvl = Luft.indentation_level
    local indent = Luft.indentation
    if type(amt) == "number" then
        local newindent = indent

        local tab = Luft.tab
        if amt > 0 then
            for _ = 1, amt do
                newindent = newindent .. tab
            end
        else
            local len = tab:len()
            for _ = -1, amt, -1 do
                -- check for tabs to remove on the ends of the indentation
                if newindent:sub(1, len) == tab then
                    newindent = newindent:sub(len + 1)
                elseif newindent:sub(-len) == tab then
                    newindent = newindent:sub(-len)
                else -- couldn't remove a tab; construct the new indentation level
                    newindent = tab:rep(indentlvl + amt)
                    break
                end
            end
        end
        Luft.indentation_level = indentlvl + amt
        Luft.indentation = newindent
        fn(unpack(arg))
    else
        Luft.indentation_level = indentlvl + 1
        Luft.indentation = indent .. Luft.tab
        amt(fn, unpack(arg))
    end
    Luft.indentation = indent
    Luft.indentation_level = indentlvl
end

--------------------
-- output system & convenience functions
--------------------

--- Prints to the testing unit's printer using its indentation system
---@param ... any
function Luft.out(...)
    return Luft.print(Luft.indentation .. table.concat(arg, '\t'))
end
--- Formats arguments and prints them to the testing unit's printer using its indentation system.
--- Convenience for `Luft.out(formatter:format(...))`
---@param formatter string
---@param ... any
function Luft.outf(formatter, ...)
    return Luft.out(formatter:format(unpack(arg)))
end


--- Prints to the testing unit's printer using its indentation system in a specified color.
--- Convenience for `Luft.out(Luft.string_color(col, str))`.
---@param col string
---@param str string
function Luft.outc(col, str)
    return Luft.out(Luft.string_color(col, str))
end
--- Formats arguments and prints them to the testing unit's printer using its indentation system in
--- a specified color.
--- Convenience for `Luft.out(Luft.string_color(col, formatter:format(...)))`.
---@param col string
---@param formatter string
---@param ... any
function Luft.outcf(col, formatter, ...)
    return Luft.out(Luft.string_color(col, formatter:format(unpack(arg))))
end


---@overload fun(...)
--- Prints to the testing unit's printer using its indentation system with a specified indentation
--- change (defaulting to `1`).
--- Convenience for `Luft.indent(amt, function() Luft.out(...) end)`
---@param amt number
---@param ... any
function Luft.indent_out(amt, ...)
    if type(amt) == "number" then
        return Luft.indent(amt, Luft.out, unpack(arg))
    else
        return Luft.indent(1, Luft.out, amt, unpack(arg))
    end
end
---@overload fun(formatter: string, ...)
--- Formats arguments and prints them to the testing unit's printer using its indentation system
--- with a specified indentation change (defaulting to `1`).
--- Convenience for `Luft.indent_out(amt, formatter:formatter(...))`
---@param amt number
---@param formatter string
---@param ... any
function Luft.indent_outf(amt, formatter, ...)
    if type(amt) == "number" then
        return Luft.indent_out(amt, formatter:format(unpack(arg)))
    else
        return Luft.indent_out(1, amt:format(formatter, unpack(arg)))
    end
end


---@overload fun(col: string, str: string)
--- Prints to the testing unit's printer using its indentation system with a specified indentation
--- change (defaulting to `1`) and col.
--- Convenience function for `Luft.indent_out(amt, Luft.string_color(col, str))`
---@param amt number
---@param col string
---@param str string
function Luft.indent_outc(amt, col, str)
    if type(amt) == "number" then
        return Luft.indent_out(amt, Luft.string_color(col, str))
    else
        return Luft.indent_out(1, Luft.string_color(amt, col))
    end
end
---@overload fun(col: string, formatter: string, ...)
--- Formats arguments and prints them to the testing unit's printer using its indentation system
--- with a specified indentation change (defaulting to `1`).
--- Convenience for `Luft.indent_outc(amt, col, formatter:formatter(...))`
---@param amt number
---@param formatter string
---@param ... any
function Luft.indent_outcf(amt, col, formatter, ...)
    if type(amt) == "number" then
        return Luft.indent_outc(amt, col, formatter:format(unpack(arg)))
    else
        return Luft.indent_outc(1, amt, amt:format(formatter, unpack(arg)))
    end
end


---@param name string
---@param expect number
---@param success boolean
---@param err? string
Luft.PrintTestResult = Luft.PrintTestResult or function(name, expect, success, err)
    local strings = Luft.strings
    if success then
        Luft.outf(strings.test_success, Luft.string_color("green", strings.pass), name)
    else
        local sublvl = Luft.sublevel
        if not sublvl then
            Luft.outf(strings.test_fail, Luft.string_color("red", strings.fail), name, expect)
        else
            Luft.outf(strings.subtest_fail, Luft.string_color("red", strings.fail), name, sublvl, expect)
        end
    end
    if err then
        Luft.indent_outc("red", err)
    end
end


----------------------------------------
-- Lua Unit Tester
----------------------------------------

--- Starts a new test description, scoping new `before` and `after` functions added inside
--- the function
---@param name string
---@param fn fun(...)
---@param ... any
---@return Luft
function Luft.describe(name, fn, ...)
    local level = Luft.level
    if level == 0 then
        -- check for previous state
        if Luft.assertions ~= 0 then
            Luft.start()
        end
    end
    local befores, afters = Luft.befores, Luft.afters
    local restore_befores_n, restore_afters_n

    if befores then
        restore_befores_n = table.getn(befores)
    end
    if afters then
        restore_afters_n = table.getn(afters)
    end

    Luft.out(name)
    Luft.level = level + 1
    Luft.indent(fn, unpack(arg))
    Luft.level = level

    if befores then
        table.setn(befores, restore_befores_n)
    end
    if afters then
        table.setn(afters, restore_afters_n)
    end
    return Luft
end

--- Starts a new test description for each item in a list
---@param pattern string
---@param list table
---@param fn fun(item: any)
---@return Luft
function Luft.describe_each(pattern, list, fn)
    for name, item in pairs(list) do
        Luft.describe(pattern:format(name), fn, name, item)
    end
    return Luft
end

--- Runs a unit test, running all `before` and `after` functions of all described test levels,
--- and then prints the test results.
---@param name string
---@param fn any
---@param ... any
---@return Luft
function Luft.test(name, fn, ...)
    Luft.sublevel = nil
    Luft.expectation_number = 0
    local befores = Luft.befores
    if befores then
        for i = 1, table.getn(befores) do
            befores[i](name)
        end
    end

    local success, err = pcall(fn, unpack(arg))
    if success then
        Luft.passes = Luft.passes + 1
    else
        Luft.errors = Luft.errors + 1
    end
    Luft.PrintTestResult(name, Luft.expectation_number, success, err)

    local afters = Luft.afters
    if afters then
        for i = 1, table.getn(afters) do
            afters[i](name)
        end
    end
    return Luft
end

--- Runs a new test over each item in a list
---@param pattern string
---@param list table
---@param fn fun(item: any)
---@return Luft
function Luft.test_each(pattern, list, fn)
    for key, item in pairs(list) do
        Luft.test(pattern:format(key), fn, item)
    end
    return Luft
end

--- Runs a test function over each item in a list as a single test, each item as a subtest
---@param name string
---@param list table
---@param fn fun(item: any)
---@return Luft
function Luft.test_all(name, list, fn)
    Luft.test(name, function()
        for key, item in pairs(list) do
            Luft.subtest(key)
            fn(item)
        end
    end)
    return Luft
end

--- Indicates that the following assertions are under a subtest group. This will be printed out
--- with the failed test if it failed due to one of these.
---@param name any
---@return Luft
function Luft.subtest(name)
    Luft.sublevel = name
    Luft.expectation_number = 0
    return Luft
end

--- Registers a function to run before each test in the current test scope
---@param fn fun(name: string)
---@return Luft
function Luft.before(fn)
    local befores = Luft.befores
    if not befores then
        befores = {}
        Luft.befores = befores
    end
    table.insert(befores, fn)
    return Luft
end

--- Registers a function to run after each test in the current test scope
---@param fn fun(name: string)
---@return Luft
function Luft.after(fn)
    local afters = Luft.afters
    if not afters then
        afters = {}
        Luft.afters = afters
    end
    table.insert(afters, fn)
    return Luft
end


------------------------------
-- Assertions
------------------------------

--------------------
-- Assertion class
--------------------

--- Starts an assertion statement
---@param ... any
---@return LuftAssertion
function Luft.expect(...)
    Luft.expectation_number = Luft.expectation_number + 1
    local assertion = {
        values = arg,
        head = false,
        negate = false,
    }
    setmetatable(assertion, Assertion)
    Luft.assertions = Luft.assertions + 1
    return assertion
end

Assertion.__index = function(self, word)
    if word:lower() ~= word then
        return Assertion[word]
    end
    local node = Assertion.GetCurrentNode(self)
    local next_node, process_next = node:GetNext(word)
    if next_node then
        while process_next do
            local chain = next_node.Chain
            if chain then
                chain(self)
            end
            self.head = next_node
            next_node, process_next = node:GetNext(process_next)
        end
        local chain = next_node.Chain
        if chain then
            chain(self)
        end
        self.head = next_node
        return self
    end
    return Assertion[word]
end

Assertion.__call = function(self, ...)
    local node = self:GetCurrentNode()
    local Test = node.Test
    if Test then
        local argCount = self:CallEach(Test, arg)
        if argCount > node.Parameters then
            error(Luft.strings.bad_argument_count:format(node.Parameters, argCount), 2)
        end
    else
        local ChainCall = node.ChainCall
        if ChainCall then
            ChainCall(self, unpack(arg))
            return self
        end
    end
end

---@return LuftPathNode
function Assertion:GetCurrentNode()
    return self.head or PathNode.Nodes.root
end


---@param test fun(...): boolean, string
---@param args? any[]
---@return number numArgs
function Assertion:CallEach(test, args)
    local node = self:GetCurrentNode()
    local support = self.support
    if node.RequiresSupport and not support then
        error(Luft.strings.support_required, 2)
    end
    local values = self.values

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
        local err = self:GetError(node, pcall(test))
        if err then
            error(err, 2)
        end
        return argCount
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
        local err = self:GetError(node, pcall(test, unpack(arguments)))
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
    return argCount
end

---@param node LuftPathNode
---@param okay boolean
---@param err boolean | string
---@return string?
function Assertion:GetError(node, okay, err)
    if okay then
        -- function was called with no errors; `err` is the return value to compare
        if (not err) ~= self.negate then
            if not self.negate then
                return node.FailString or Luft.strings.unknown_error
            else
                return node.NotFailString or Luft.strings.unknown_error
            end
        else
            return nil
        end
    else
        -- function had errors; `err` is the actual Lua error
        if self.negate then
            return nil
        else
            return err
        end
    end
end

--------------------
-- Path Node class
--------------------

PathNode.__index = PathNode
PathNode.Nodes = {}

---@param word string
---@return LuftPathNode
---@return string? next_word
function PathNode:GetNext(word)
    local pos = word:find('_', 1, true)
    local next_word
    if pos then
        next_word = word:sub(pos + 1)
        word = word:sub(1, pos - 1)
    end
    local node = self[word]
    if node then
        return node, next_word
    end
    node = self['!' .. word]
    if node then
        local not_node = self.Nodes["not"]
        if next_word then
            return not_node, self.Name .. '_' .. next_word
        end
        return not_node, self.Name
    end
    return self.Nodes[word]
end


do
    local nodes = PathNode.Nodes
    local strings = Luft.strings

    ---@param self LuftAssertion
    local function negate(self)
        self.negate = not self.negate
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

    nodes["root"] = {
        To = {"not", "to"},
    }
    nodes["not"] = {
        To = "to",
        Chain = negate,
    }
    nodes["to"] = {
        NotName = "not_to",
        To = {"to.not", "succeed", "to.equal", "be", "have"},
    }
    nodes["to.not"] = {
        To = {"succeed", "to.equal", "be", "have"},
        Chain = negate,
    }
    nodes["succeed"] = {
        Alias = "pass",
        NotName = "fail",
        NotAlias = "error",
        Test = function(v)
            return pcall(v)
        end;
        Parameters = 1,
        FailString = strings.expectation1:format("$1", strings.condition_unnegated, strings.cond_succeed),
        NotFailString = strings.expectation1:format("$1", strings.condition_unnegated, strings.cond_fail),
    }
    nodes["to.equal"] = {
        Test = strict_eq,
        Parameters = 2,
        FailFormat = strings.expectation2be:format("$1", "$2", "%s", strings.cond_strict_eq),
    }
    nodes["have"] = {
        ---@param t any
        ---@param x any
        ---@return boolean
        Test = function(t, x)
            if type(t) ~= "table" then
                error(strings.expectation1be:format(repr(t), strings.condition_unnegated, "a table"))
            end
            for _, v in pairs(t) do
                if v == x then return true end
            end
            return false
        end;
        Parameters = 2,
        FailFormat = strings.expectation1:format("$1", "%s", strings.cond_contains:format("$1")),
    }
    nodes["exist"] = {
        ---@param v any
        ---@return boolean
        Test = function(v)
            return v ~= nil
        end;
        Parameters = 1,
        FailFormat = strings.expectation1:format("$1", "%s", strings.cond_exist),
    }
    nodes["be"] = {
        To = {
            "equal", "unequal",
            "greater", "less",
            "positive", "negative",
            "falsy",
            "nil", "userdata",
            "within", "close",
            "an",
        },
        Test = function(v, x)
            return v == x
        end;
        Parameters = 2,
        FailString = strings.expectation2be:format("$1", "$2", strings.condition_unnegated, strings.cond_equal),
        NotFailString = strings.expectation2be:format("$1", "$2", strings.condition_unnegated, strings.cond_unequal),
    }
    nodes["equal"] = {
        To = "equal.to",
    }
    nodes["equal.to"] = {
        test = strict_eq,
        Parameters = 2,
        FailFormat = nodes["to.equal"].FailFormat,
    }
    nodes["greater"] = {
        To = "than",
        Chain = function(sert)
            sert.support = {true}
        end;
    }
    nodes["less"] = {
        To = "than",
        Chain = function(sert)
            sert.support = {false}
        end;
    }
    nodes["than"] = {
        Test = function(v, x, t)
            if t then
                return v > x
            else
                return v < x
            end
        end;
        Parameters = 3,
        RequiresSupport = true,
    }
    nodes["falsy"] = {
        NotName = "truthy",
        ---@param v any
        ---@return boolean
        Test = function(v)
            return not v
        end;
        Parameters = 1,
        FailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_falsy),
        NotFailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_truthy),
    }
    nodes["within"] = {
        To = "of",
        ChainCall = function(sert, ...)
            sert.support = arg
        end;
    }
    nodes["of"] = {
        ---@param v1 number
        ---@param v2 number
        ---@param scale number
        ---@return boolean
        Test = function(v1, v2, scale)
            return math.abs(v1 - v2) < math.abs(scale)
        end;
        Parameters = 3,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.cond_within:format("$3", "$2")),
        RequiresSupport = true,
    }
    nodes["close"] = {
        To = "close.to",
        Chain = function(sert)
            sert.support = {Luft.margin_of_error, n = 1}
        end;
    }
    nodes["close.to"] = {
        Test = nodes["of"].Test,
        Parameters = nodes["of"].Parameters,
        FailFormat = nodes["of"].FailFormat,
        RequiresSupport = nodes["of"].RequiresSupport
    }
    nodes["negative"] = {
        NotName = "nonnegative",
        Test = function(v)
            return type(v) == "number" and v < 0
        end;
        Parameters = 1,
        FailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_negative),
        NotFailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_nonnegative),
    }
    nodes["positive"] = {
        NotName = "nonpositive",
        Test = function(v)
            return type(v) == "number" and v > 0
        end;
        Parameters = 1,
        FailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_positive),
        NotFailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_nonpositive),
    }
    nodes["nil"] = {
        Test = function(v)
            return v == nil
        end;
        Parameters = 1,
        FailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_nil),
        NotFailString = strings.expectation1be:format("$1", strings.condition_unnegated, strings.type_nonnil),
    }
    nodes["userdata"] = {
        Test = function(v)
            return type(v) == "userdata"
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_userdata)
    }
    nodes["an"] = {
        Alias = "a",
        ---@param v any
        ---@param x any
        ---@return boolean
        Test = function(v, x)
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
        end;
        Parameters = 2,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.cond_an:format("$2"))
    }
    nodes["boolean"] = {
        Alias = "bool",
        Test = function(v)
            return v == true or v == false
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_boolean)
    }
    nodes["number"] = {
        Test = function(v)
            return type(v) == "number"
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_number)
    }
    nodes["integer"] = {
        Alias = "int",
        Test = function(v)
            if type(v) == "number" then
                if v > 0 then
                    return math.floor(v) == v
                end
                return math.ceil(v) == v
            end
            return false
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_integer)
    }
    nodes["float"] = {
        Alias = "decimal",
        Test = function(v)
            if type(v) == "number" then
                if v > 0 then
                    return math.floor(v) ~= v
                end
                return math.ceil(v) ~= v
            end
            return false
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_float)
    }
    nodes["string"] = {
        Test = function(v)
            return type(v) == "string"
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_string)
    }
    nodes["function"] = {
        Alias = "func",
        Test = function(v)
            return type(v) == "function"
        end;
        Parameters = 1,
        FailFormat = strings.expectation1be:format("$1", "%s", strings.type_function),
    }

    local function connectVia(from, to, route, invert)
        if not route then return end
        -- remove relation markers so the local reference words connect
        local pos = route:find('.', 1, true)
        if pos then
            route = route:sub(pos + 1)
        end
        if invert then
            route = '!' .. route
        end
        from[route] = to
    end
    local function connectTo(from, to)
        if not to then return end
        connectVia(from, to, to.Name)
        connectVia(from, to, to.Alias)
        connectVia(from, to, to.NotName, true)
        connectVia(from, to, to.NotAlias, true)
    end

    for name, node in pairs(nodes) do
        node.Name = name
        -- auto generate missing negative fail strings
        local format = node.FailFormat
        if format then
            node.FailFormat = nil
            node.FailString = format:format(strings.condition_unnegated)
            node.NotFailString = format:format(strings.condition_negated)
        end
    end
    for _, node in pairs(nodes) do
        -- connect them
        local to = node.To
        if to then
            if type(to) == "string" then
                connectTo(node, nodes[to])
            else
                for _, t in ipairs(to) do
                    connectTo(node, nodes[t])
                end
            end
        end
    end
    for _, node in pairs(nodes) do
        -- now set their class
        setmetatable(node, PathNode)
    end
end


------------------------------
-- Spying
------------------------------

Spy.__index = Spy

---@overload fun(target: function, run?: fun(spy: LuftSpy)): LuftSpy
--- Returns a transparent callable object for a function target that collects all arguments
---@param target table
---@param name any
---@param run? fun(spy: LuftSpy) run after the spy is created
---@return LuftSpy
function Luft.spy(target, name, run)
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


return Luft.start()
