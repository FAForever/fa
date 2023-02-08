--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************
---@meta

-- This file annotates the differences that our distribution of the Lua standard libary has with
-- the VSC Lua Server intellisense extension, which are due to two sources of pain:
--  (1) The Moho engine made changes to the library
--  (2) The extension only supports versions down to Lua 5.1 and Moho was made in 5.0

-- New functions in this file appear to be built into the Lua environment, unlike the functions in
-- `/engine/User.lua`, `/engine/Sim.lua`, and `/engine/Core.lua` which are provided to the environment
-- depending on if it's a Sim or User state (or both for Core). This means that they show up even for
-- the init files run with the commandline--which also have access to the `io` and `os` interfaces
-- before they get removed from the game. The same goes for `Unsafe.lua`.

---@class Bytecode
---@field numparams number
---@field maxstack number

----------
-- Moho discrepancies
----------

-- variables set from the engine

LaunchDir = ""      -- filled with whatever directory the exe is in
__EngineStats = { } -- populated by the engine, each frame in the UI thread

--- Returns the bitwise XOR of a and b, coercing to integers. Returns `4294967296` (2^^32) if the
--- signs don't match.
---@param a number
---@param b number
---@return integer
function __pow(a, b)
end

---@param out any
---@param ... any
function _ALERT(out, ...)
end

---@param out any
---@param ... any
function _TRACEBACK(out, ...)
end

---@param path FileName
---@return Module
function import(path)
end

---@param path FileName
---@return Module
function lazyimport(path)
end

--- Print a message to the moho logger, this shouldn't be used in production code
---@param out any
---@param ... any
function LOG(out, ...)
end

function LuaDumpBinary()
end

---@return any[]
function debug.allobjects()
end

---@param obj any
---@return integer
function debug.allocatedsize(obj)
end

---@return table<any, string>
function debug.allocinfo()
end

--- Returns the bytecode for a function, a list of instructions in string form that the Lua
--- virtual machine uses plus the maximum stack size and number of parameters to the function.
---@param fn function
---@return Bytecode
function debug.listcode(fn)
end

--- Returns the constant pool of a function used by the Lua virtual machine
---@param fn function
---@return any[]
function debug.listk(fn)
end

--- Returns the variable name and value of local in the `n`th register of the current Lua State.
--- Note that this means that the function must currently be running to be useful (except to get
--- the name of the first parameter).
---@param fn function
---@param n integer
---@return string name
---@return any value
function debug.listlocals(fn, n)
end

--- The returned table's size is a multiple of 7, where every 7 entries correspond to the data for
--- one function:  
--- `[1]: function`  
--- `[2]: clocked`  
--- `[3]: here`  
--- `[4]: in_c_children`  
--- `[5]: in_lua_children`  
--- `[6]: yielded`  
--- `[7]: ncalls`  
---@return table
function debug.profiledata()
end

---@param doTrack boolean
function debug.trackallocations(doTrack)
end

-- these are available in the initfile, but are removed from the game
io = nil
os = nil

--- Returns if the table is empty
---@param table table
---@return boolean
function table.empty2(table)
end

--- Returns the size of a list
---@param list table
---@return integer
function table.getn2(list)
end

table.getsize = nil

--- Returns the total number of keys in a table
---@param table table
---@return integer
function table.getsize2(table)
end

serialize = {}

---@param str string
---@return any
function serialize.fromstring(str)
end

---@param val any
---@return string
function serialize.tostring(val)
end

--- A function that does its best to emulate Lua string lexing: backslashes become an escape
--- character for escape sequences, and newlines not preceded by one disappear. In the case of a bad
--- escape sequence the slash disappears too. Numeric escapes will always eat an extra character
--- after them and don't constrain the result. Lexing stops at any encountered embedded zeroes in
--- the source.
---@param str string
---@return string
function string.lualex(str)
end

----------
--- Version discrepancies
----------

_LOADED = {} -- used by `requires`
_VERSION = "Lua 5.0.1" -- override the version from the extension

---@param libname string
---@param funcname string
function loadlib(libname, funcname)
end

-- renamed in 5.1
math.mod = math.fmod
string.gfind = string.gmatch

-- added in 5.1
coroutine.close       = nil
coroutine.isyieldable = nil
debug.getfenv         = nil
debug.getmetatable    = nil
debug.getregistry     = nil
debug.setcstacklimit  = nil
debug.setfenv         = nil
debug.setmetatable    = nil
debug.upvalueid       = nil
debug.upvaluejoin     = nil
math.cosh             = nil
math.fmod             = nil
math.modf             = nil
math.sinh             = nil
math.tanh             = nil
math.tointeger        = nil
math.type             = nil
math.ult              = nil
table.empty           = nil
table.maxn            = nil
table.move            = nil
string.gmatch         = nil
string.match          = nil
string.pack           = nil
string.packsize       = nil
string.reverse        = nil
string.unpack         = nil
