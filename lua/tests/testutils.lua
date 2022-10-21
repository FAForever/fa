-- testutils.lua
--
-- Contains simple unit test support.

require '../system/repr.lua'

local insert = table.insert
local getn = table.getn
local setn = table.setn
local concat = table.concat

--==============================================================================
-- expect_equal(a,b) raises an error if its args are not equal, with equality
-- defined by having the same type and repr() representation.
--------------------------------------------------------------------------------
function expect_equal(a,b)
    assert(type(a) == type(b), 'different types: '..type(a)..' != '..type(b)..'\na='..repr(a)..'\nb='..repr(b))
    if a!=b then
        local ra = repr(a)
        local rb = repr(b)
        assert(ra==rb, ra..' == '..rb)
    end
end


--==============================================================================
-- expect_identical(a,b) raises an error if its args are not the same.
--------------------------------------------------------------------------------
function expect_identical(a,b)
    if a!=b then
        local ra = repr(a)
        local rb = repr(b)
        error('objects should be identical:\n' .. repr(a) .. '\n' .. repr(b))
    end
end


--==============================================================================
-- expect_error(wantmsg, fun, ...) calls fun(...), expecting it to raise an
-- error containing 'wantmsg'. If it does not, expect_error raises its own
-- error.
--------------------------------------------------------------------------------
function expect_error(wantmsg, fun, ...)
    local ok,msg = pcall(fun, unpack(arg))
    if ok then
        error('expected an error')
    end
    local junk,reps = string.gsub(msg, wantmsg, '', 1)
    if not string.find(msg, wantmsg, 1, true) then
        error('unexpected message on error: got '..repr(msg)..'\nInstead of '..repr(wantmsg))
    end
end


--==============================================================================
-- dir_recursive(path) -> list
--   return a list of files under path
--------------------------------------------------------------------------------
function dir_recursive(path, result)
    local r = result or {}
    for i,f in io.dir(path.."/*") do
        if f=="." or f==".." then continue end
        local sub = path.."/"..f
        table.insert(r,sub)
        dir_recursive(sub,r)
    end
    return r
end


--==============================================================================
-- The LogBuffer class provides a simple stream buffer idiom. A complicated
-- test can create a LogBuffer and append text to it like this:
--       log = LogBuffer(' ',';') -- args are field separator and line separator
--       log('foo',100)
--       log(1,2,3)
--       log()
--       log('the end')
--
-- now log:Get() will return
--       "foo 100;1 2 3;;the end;"
--
-- Which you can compare to an expected result string. This is a handy way to
-- create tests that involve the timing of interacting calls, e.g. coroutines
-- etc.
--------------------------------------------------------------------------------
local LogBufferMeta = { }
LogBufferMeta.__index=LogBufferMeta

function LogBuffer(sep, newline)
    local t = { sep=sep or ' ', newline=newline or '\n' }
    setmetatable(t, LogBufferMeta)
    return t
end

function LogBufferMeta:__call(...)
    for i,v in ipairs(arg) do
        arg[i] = tostring(v)
    end
    insert(self,concat(arg,self.sep))
    if self.newline then
        insert(self,self.newline)
    end
end

function LogBufferMeta:Clear()
    for i=1,getn(self) do
        self[i] = nil
    end
    setn(self,-1)
end

function LogBufferMeta:Get()
    local n = getn(self)
    if n==0 then
        return ''
    elseif n==1 then
        return self[1]
    else
        local r = concat(self)
        self:Clear()
        self[1] = r
        return r
    end
end


--==============================================================================
-- auto_run_unit_tests()
--
-- Looks inside its calling module for any functions starting with "test_",
-- then calls them in alphabetical order and reports on the results.
--
-- Test functions should throw an error to fail, or just return to succeed.
-- The return value, if any, is ignored. Typically a test will set up a bit
-- of data, then call assert(), expect_equal(), and expect_error() to perform
-- the tests.
--------------------------------------------------------------------------------
function auto_run_unit_tests()
    -- Check LuaPlus cmd line for verbose option
    local verbose = (arg[1] == "-v")

    -- Get our caller's environment to look for tests in
    local env = getfenv(2)
    local t = {}
    for name,fun in env do
        if type(name)=='string' and type(fun)=='function' and string.sub(name,1,5)=='test_' then
            table.insert(t,name)
        end
    end
    table.sort(t)

    local passed = 0
    local failed = 0

    for i,name in ipairs(t) do
        if verbose then print(name) end

        local ok,msg = pcall(env[name])
        if ok then
            passed = passed+1
        else
            failed = failed+1
            print(name .. ' FAILED')
            print(msg)
        end
    end

    print(passed .. " tests passed")
    if failed>0 then
        print(failed .. " tests failed")
    end
end
