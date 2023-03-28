---@declare-global
-- ==========================================================================================
-- * File       : lua/system/utils.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains global functions for working with tables and strings
-- ==========================================================================================


-- upvalue globals for performance
local type = type 
local pcall = pcall 
local unpack = unpack 
local next = next

-- local Random = Random

-- upvalue table operations for performance
local TableInsert = table.insert 
local TableGetn = table.getn 
local TableRemove = table.remove 
local TableSort = table.sort

--- Determines the size in bytes of the given element
---@param element any
---@param ignore table<string, boolean>     # List of key names to ignore of all (referenced) tables
---@return integer
function ToBytes(element, ignore)

    -- has no allocated bytes
    if element == nil then
        return 0
    end

    -- applies to tables and strings, to prevent counting them multiple times
    local seen = { }

    -- prepare stack to prevent recursion
    local allocatedSize = 0
    local stack = { element }
    local head = 2

    while head > 1 do

        head = head - 1
        local value = stack[head]
        stack[head] = nil

        local size = debug.allocatedsize(value)

        -- size of usual value
        if size == 0 then
            allocatedSize = allocatedSize + 8

        -- size of string
        elseif type(value) ~= 'table' then
            if not seen[value] then
                seen[value] = true
                allocatedSize = allocatedSize + size
            end

        -- size of table
        else
            if not seen[value] then
                allocatedSize = allocatedSize + size
                seen[value] = true
                for k, v in value do
                    if not ignore[k] then
                        stack[head] = v
                        head = head + 1
                    end
                end
            end
        end
    end

    return allocatedSize
end

--- RandomIter(table) returns a function that when called, returns a pseudo-random element of the supplied table.
--- Each element of the table will be returned once. This is essentially for "shuffling" sets.
function RandomIter(someSet)
    local keyList = {}
    for key, val in someSet do
        TableInsert(keyList, key)
    end

    return function()
        local size = TableGetn(keyList)

        if size > 0 then
            local key = TableRemove(keyList, Random(1, size))
            return key, someSet[key]
        else
            return
        end
    end
end

--- safecall(msg, fn, ...) calls the given function with the given args, and
--- catches any error and logs a warning including the given message.
--- Returns nil if the function failed, otherwise returns the function's result.
function safecall(msg, fn, ...)
    local ok, result = pcall(fn, unpack(arg))
    if ok then
        return result
    else
        WARN("Problem " .. tostring(msg) .. ":\n" .. result)
        return
    end
end

--- Returns actual size of a table, including string keys
table.getsize = table.getsize2
table.empty = table.empty2

--- table.copy(t) returns a shallow copy of t.
function table.copy(t)
    if not t then return end -- prevents looping over nil table
    local r = {}
    for k,v in t do
        r[k] = v
    end
    return r
end

--- table.find(t,val) returns the key for val if it is in t table.
--- Otherwise, return nil
function table.find(t,val)
    if not t then return end -- prevents looping over nil table
    for k,v in t do
        if v == val then
            return k
        end
    end
    -- return nil by falling off the end
end

--- table.subset(t1,t2) returns true iff every key/value pair in t1 is also in t2
function table.subset(t1,t2)
    if not t1 and not t2 then return true end  -- nothing is in nothing
    if not t1 then return true end  -- nothing is in something
    if not t2 then return false end -- something is not in nothing
    for k,v in t1 do
        if t2[k] ~= v then return false end
    end
    return true
end

--- table.equal(t1,t2) returns true iff t1 and t2 contain the same key/value pairs.
function table.equal(t1,t2)
    return table.subset(t1,t2) and table.subset(t2,t1)
end

--- table.removeByValue(t,val) remove a field by value instead of by index
function table.removeByValue(t,val)
    if not t then return end -- prevent looping over nil table
    for k,v in t do
        if v == val then
            TableRemove(t,k)
            return
        end
    end
end

--- table.deepcopy(t) returns a copy of t with all sub-tables also copied.
function table.deepcopy(t,backrefs)
    if type(t)=='table' then
        if backrefs==nil then backrefs = {} end

        local b = backrefs[t]
        if b then
            return b
        end

        local r = {}
        backrefs[t] = r
        for k,v in t do
            r[k] = table.deepcopy(v,backrefs)
        end
        return r
    else
        return t
    end
end

--- table.merged(t1,t2) returns a table in which fields from t2 overwrite
--- fields from t1. Neither t1 nor t2 is modified. The returned table may
--- share structure with either t1 or t2, so it is not safe to modify.
-- e.g.  t1 = { x=1, y=2, sub1={z=3}, sub2={w=4} }
--       t2 = { y=5, sub1={a=6}, sub2="Fred" }
--       merged(t1,t2) -> { x=1, y=5, sub1={a=6,z=3}, sub2="Fred" }
--       merged(t2,t1) -> { x=1, y=2, sub1={a=6,z=3}, sub2={w=4} }
function table.merged(t1, t2)

    if t1==t2 then
        return t1
    end

    if type(t1)~='table' or type(t2)~='table' then
        return t2
    end

    local copied = nil
    for k,v in t2 do
        if type(v)=='table' then
            v = table.merged(t1[k], v)
        end
        if t1[k] ~= v then
            copied = copied or table.copy(t1)
            t1 = copied
            t1[k] = v
        end
    end

    return t1
end

--- Write all undefined keys from t2 into t1.
function table.assimilate(t1, t2)
    if not t2 then return t1 end -- prevent looping over nil table
    for k, v in t2 do
        if t1[k] == nil then
            t1[k] = v
        end
    end

    return t1
end

--- Remove all keys in t2 from t1.
function table.subtract(t1, t2)
    if not t2 then return t1 end -- prevent looping over nil table
    for k, v in t2 do
        t1[k] = nil
    end

    return t1
end

--- table.cat(t1, t2) performs a shallow "merge" of t1 and t2, where t1 and t2
--- are expected to be numerically keyed (existing keys are discarded).
--- e.g. table.cat({1, 2, 3}, {'A', 'House', 3.14})  ->  {1, 2, 3, 'A', 'House', 3.14}
---@return table
function table.cat(t1, t2)
    -- handling nil tables before lopping
    if not t1 then return table.copy(t2) end
    if not t2 then return table.copy(t1) end
    local r = {}
    for i,v in t1 do
        TableInsert(r, v)
    end

    for i,v in t2 do
        TableInsert(r, v)
    end

    return r
end

--- Concatenate arbitrarily-many tables (equivalent to table.cat, but varargs.
--- Slightly more overhead, but can constructively concat *all* the things)
function table.concatenate(...)
    local ret = {}

    for index = 1, TableGetn(arg) do
        if arg[index] then
            for k, v in arg[index] do
                TableInsert(ret, v)
            end
        end
    end

    return ret
end

--- Destructively concatenate two tables. (numerical keys only)
--- Appends the keys of t2 onto t1, returning it. The original t1 is destroyed,
--- but this avoids the need to copy the values in t1, saving some time.
function table.destructiveCat(t1, t2)
    for k, v in t2 do
        TableInsert(t1, v)
    end
end

--- table.sorted(t, [comp]) is the same as table.sort(t, comp) except it returns
--- a sorted copy of t, leaving the original unchanged.
--- [comp] is an optional comparison function, defaulting to less-than.
function table.sorted(t, comp)
    local r = table.copy(t)
    TableSort(r, comp)
    return r
end

--- sort_by(field) provides a handy comparison function for sorting
--- a list of tables by some field.
---
--- For example,
---       my_list={ {name="Fred", ...}, {name="Wilma", ...}, {name="Betty", ...} ... }
---
---       table.sort(my_list, sort_by 'name')
---           to get names in increasing order
---
---       table.sort(my_list, sort_down_by 'name')
---           to get names in decreasing order
function sort_by(field)
    return function(t1,t2)
        return t1[field] < t2[field]
    end
end

function sort_down_by(field)
    return function(t1,t2)
        return t2[field] < t1[field]
    end
end

--- table.keys(t, [comp]) returns a list of the keys of t, sorted.
--- [comp] is an optional comparison function, defaulting to less-than, e.g.
-- table.keys(t) -- returns keys in increasing order (low performance with large tables)
-- table.keys(t, function(a, b) return a > b end) -- returns keys in decreasing order (low performance with large tables)
-- table.keys(t, false) -- returns keys without comparing/sorting (better performance with large tables)
function table.keys(t, comp)
    local r = {}
    if not t then return r end -- prevents looping over nil table
    local n = 1
    for k,v in t do
        r[n] = k -- faster than table.insert(r,k)
        n = n + 1
    end
    if comp ~= false then TableSort(r, comp) end
    return r
end

--- table.values(t) Return a list of the values of t, in unspecified order.
function table.values(t)
    local r = {}
    if not t then return r end -- prevents looping over nil table
    local n = 1
    for k,v in t do
        r[n] = v -- faster than table.insert(r,v)
        n = n + 1
    end
    return r
end

--- Concatenate keys of a table into a string and separates them by optional string.
function table.concatkeys(t, sep)
    sep = sep or ", "
    local tt = table.keys(t)
    return table.concat(tt,sep)
end

--- Iterates over a table in key-sorted order:
---   for k,v in sortedpairs(t) do
---       print(k,v)
---   end
--- @param comp is an optional comparison function, defaulting to less-than.
function sortedpairs(t, comp)
    local keys = table.keys(t, comp)
    local i=1
    return function()
        local k = keys[i]
        if k~=nil then
            i=i+1
            return k,t[k]
        end
    end
end

--- Returns a table with keys and values from t reversed.
--- e.g. table.inverse {'one','two','three'} => {one=1, two=2, three=3}
---      table.inverse {foo=17, bar=100}     => {[17]=foo, [100]=bar}
--- If t contains duplicate values, it is unspecified which one will be returned.
--- e.g. table.inverse {foo='x', bar='x'} => possibly {x='bar'} or {x='foo'}
function table.inverse(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    for k,v in t do
        r[v] = k
    end
    return r
end

--- Reverses order of values in a table using their index
--- table.reverse {'one','two','three'} => {'three', 'two', 'one'}
function table.reverse(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    local items = table.indexize(t) -- convert from hash table
    local itemsCount = table.getsize(t)
    for k, v in ipairs(items) do
        r[itemsCount + 1 - k] = v
    end
    return r
end

--- Converts hash table to a new table with keys from 1 to size of table and the same values
--- it is useful for preparing hash table before sorting its values
--- table.indexize { [a] = 'one', [b] = 'two', [c] = 'three' } =>
---                { [1] = 'one', [2] = 'two', [3] = 'three' }
function table.indexize(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    local n = 1
    for k, v in t do
        r[n] = v -- faster than table.insert(r, v)
        n = n + 1
    end
    return r
end

--- Converts a table to a new table with values as keys and values equal to true, duplicated table values are discarded
--- it is useful for quickly looking up values in tables instead of looping over them
--- table.hash { [1] = 'A',  [2] = 'B',  [3] = 'C',  [4] = 'C' } =>
---            { [A] = true, [B] = true, [C] = true }
function table.hash(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    for k, v in t do
        if type(v) ~= "string" and type(v) ~= 'number' then
            r[tostring(v)] = true
        else
            r[v] = true
        end
    end
    return r
end

--- Converts a table to a new table with values as keys only if their values are true
--- it is reverse logic of table.hash(t)
--- table.unhash { [A] = true, [B] = true, [C] = false }  =>
--               { [1] = 'A',  [2] = 'B', }
function table.unhash(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    local n = 1
    for k, v in t do
        if v then
            r[n] = k -- faster than table.insert(r, k)
            n = n + 1
        end
    end
    return r
end

--- Gets keys of hash table if their values equal to specified boolean value, defaults to true
--- it is useful to check which keys are present or not in a hash table
--- t = { [A] = true, [B] = true, [C] = false }
--- table.hashkeys(t, true)  =>  { 'A', 'B' }
--- table.hashkeys(t, false) =>  { 'C' }
function table.hashkeys(t, value)
    if value == nil then value = true end -- defaulting to true
    local r = table.filter(t, function(v) return v == value end)
    return table.keys(r)
end

--- table.map(fn,t) returns a table with the same keys as t but with
--- fn function applied to each value.
function table.map(fn, t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    for k,v in t do
        r[k] = fn(v)
    end
    return r
end

--- table.shuffle(t) returns a shuffled table
function table.shuffle(t)
    local r = {}
    for key, val in RandomIter(t) do
        if type(key) == 'number' then
            TableInsert(r, val)
        else
            r[key] = val
        end
    end
    return r
end

-- table.binsert(t, value, cmp) binary insert value into table using cmp-func
function table.binsert(t, value, cmp)
      local cmp = cmp or (function(a,b) return a < b end)
      local start, stop, mid, state = 1, table.getsize(t), 1, 0
      while start <= stop do
         mid = math.floor((start + stop) / 2)
         if cmp(value, t[mid]) then
            stop, state = mid - 1, 0
         else
            start, state = mid + 1, 1
         end
      end

      TableInsert(t, mid + state, value)
      return mid + state
   end

-- Pretty-print a table. Depressingly large amount of wheel-reinvention were required, thanks to
-- SC's LUA being a bit weird and the existing solutions to this problem being aggressively optimized
function printField(k, v, tblName, printer)
    if not printer then printer = WARN end
    if not tblName then tblName = "" end
    if "table" == type(k) then
        table.print(k, tblName .. " ", printer)
    else
        tblName = tblName .. '' .. tostring(k)
    end
    if "string" == type(v) then
        printer(tblName .. " = " .. "\"" .. v .. "\"")
    elseif "table" == type(v) then
        --printer(tblName .. k .. " = ")
        table.print(v, tblName .. "  ", printer)
    else
        printer(tblName .. " = " .. tostring(v))
    end
end

--- Prints keys and values of a table and sub-tables if present
--- @param tbl? table specifies a table to print
--- @param tblPrefix? string specifies optional table prefix/name
--- @param printer? function specifies optional message printer: LOG, WARN, error, etc.
--- e.g. table.print(categories)
---      table.print(categories, 'categories')
---      table.print(categories, 'categories', 'WARN')
function table.print(tbl, tblPrefix, printer)
    if not printer then printer = LOG end
    if not tblPrefix then tblPrefix = "" end
    if not tbl then
        printer(tblPrefix .." table is nil")
        return
    end
    if table.empty(tbl) then
        printer(tblPrefix .." { }")
        return
    end
    printer(tblPrefix.." {")
    for k, v in pairs(tbl) do
        printField(k, v, tblPrefix .. "    ", printer)
    end

    printer(tblPrefix.." }")
end

--- Return filtered table containing every mapping from table for which fn function returns true when passed the value.
--- @param t  - is a table to filter
--- @param fn - is decision function to use to filter the table, defaults checking if a value is true or exists in table
function table.filter(t, fn)
    local r = {}
    if not fn then fn = function(v) return v end end
    for k, v in t do
        if fn(v) then
            r[k] = v
        end
    end
    return r
end

--- Returns total count of values that match fn function or if values exist in table
--- @param fn is optional filtering function that is applied to each value of the table
function table.count(t, fn)
    if not t then return 0 end -- prevents looping over nil table
    if not fn then fn = function(v) return v end end
    local r = table.filter(t, fn)
    return table.getsize(r)
end

--- Returns a new table with unique values stored using numeric keys and it does not preserve keys of the original table
function table.unique(t)
    if not t then return end -- prevents looping over nil table
    local unique = {}
    local ins = {}
    local n = 0
    for k, v in t do
        if not ins[v] then
            n = n + 1
            unique[n] = v -- faster than table.insert(unique, v)
            ins[v] = true
        end
    end

    return unique
end


---Returns a random entry from an array
---@generic T
---@param array T[]
---@return T
function table.random(array)
    return array[Random(1, TableGetn(array))]
end


-- Lua 5.0 implementation of the Lua 5.1 function string.match
-- Returns a regex match
-- optional param init defines where to start searching. Can be negative to search from the end.
rawset(string, 'match', function(input, exp, init)
    local match
    string.gsub(input:sub(init or 1), exp, function(...) match = arg end, 1)
    if match then
        return unpack(match)
    end
end)

-- gfind was renamed to gmatch in Lua 5.1. added gmatch for additional compatibility
rawset(string, 'gmatch', string.gfind)

--- Returns items as a single string, separated by the delimiter
function StringJoin(items, delimiter)
    local str = "";
    for k,v in items do
        str = str .. v .. delimiter
    end
    return str
end

--- "explode" a string into a series of tokens, using a separator character `sep`
function StringSplit(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[table.getn(fields)+1] = c end)
    return fields
end

--- Returns true if the string starts with the specified value
function StringStartsWith(stringToMatch, valueToSeek)
    return stringToMatch:sub(1, valueToSeek:len()) == valueToSeek
end

--- Extracts a string between two specified strings
--- e.g. StringExtract('/path/name_end.lua', '/', '_end', true) --> name
function StringExtract(str, str1, str2, fromEnd)
    local pattern = str1 .. '(.*)' .. str2
    if fromEnd then pattern = '.*' .. pattern end
    local _, _, m = str:find(pattern)
    return m
end

--- Adds comma as thousands separator in specified value
--- e.g. StringComma(10000) --> 10,000
function StringComma(value)
    local str = value or 0
    while true do
      str, k = string.gsub(str, "^(-?%d+)(%d%d%d)", '%1,%2')
      if k == 0 then
        break
      end
    end
    return str
end

--- Prepends a string with specified symbol or one space
function StringPrepend(str, symbol)
    if not symbol then symbol = ' ' end
    return symbol .. str
end

--- Splits a string with camel case to a string with separate words
--- e.g. StringSplitCamel('SupportCommanderUnit') -> 'Support Commander Unit'
function StringSplitCamel(str)
    local first = str:sub(1, 1)
    local split = first .. str:sub(2):gsub("[A-Z]", StringPrepend)
    return (split:gsub("^.", string.upper))
end

--- Reverses order of letters for specified string
--- e.g. StringReverse('abc123') --> 321cba
function StringReverse(str)
    local tbl =  {}
    str:gsub(".", function(c) table.insert(tbl,c) end)
    tbl = table.reverse(tbl)
    return table.concat(tbl)
end

--- Capitalizes each word in specified string
--- e.g. StringCapitalize('hello supreme commander') --> Hello Supreme Commander
function StringCapitalize(str)
    return string.gsub(" "..str, "%W%l", string.upper):sub(2)
end

--- Check if a given string starts with specified string
function StringStarts(str, startString)
   return StringStartsWith(str, startString)
end

--- Check if a given string ends with specified string
function StringEnds(str, endString)
   return endString == '' or str:sub(-endString:len()) == endString
end

--- Sorts two variables based on their numeric value or alpha order (strings)
function Sort(itemA, itemB)
    if not itemA or not itemB then return 0 end

    if type(itemA) == "string" or
       type(itemB) == "string" then
        if itemA:lower() == itemB:lower() then
            return 0
        else
            -- sort string using alpha order
            return itemA:lower() < itemB:lower()
        end
    else
       if math.abs(itemA - itemB) < 0.0001 then
            return 0
       else
            -- sort numbers in decreasing order
            return itemA > itemB
       end
    end
end

-- Rounds a number to specified double precision
function math.round(num,idp)
    if not idp then
        return math.floor(num+.5)
    end

    idp = math.pow(10,idp)
    return math.floor(num*idp+.5)/idp
end

--- Clamps numeric value to specified Min and Max range
function math.clamp(v, min, max)
    if v <= min then return min end
    if v >= max then return max end
    return v
end

-- Return a table parsed from key:value pairs passed on the command line
-- Example:
--  command line args: /arg key1:value1 key2:value2
--  GetCommandLineArgTable("/arg") -> {key1="value1", key2="value2"}
function GetCommandLineArgTable(option)
    -- Find total number of args
    local next = 1
    local args, nextArgs = nil, nil
    repeat
        nextArgs, args = GetCommandLineArg(option, next), nextArgs
        next = next + 1
    until not nextArgs

    -- Construct result table
    local result = {}
    if args then
        for _, arg in args do
            local pair = StringSplit(arg, ":")
            local name, value = pair[1], pair[2]
            result[name] = value
        end
    end

    return result
end

--- Creates timer for profiling task(s) and calculating time delta between consecutive function calls, e.g.
--- local timer = CreateTimer()
--- timer:Start() -- then execute some LUA code
--- timer:Stop()
--- or
--- timer:Start('task1') -- then execute task --1
--- timer:Stop('task1')
--- timer:Start('task2') -- then execute task --2
--- timer:Stop('task2')
function CreateTimer()
    return {
        tasks = {},
        Reset = function(self)
            self.tasks = {}
        end,
        -- starts profiling timer for optional task name
        Start = function(self, name, useLogging)
            name = self:Verify(name)
            -- capture start time
            self.tasks[name].stop  = nil
            self.tasks[name].start = CurrentTime()
            self.tasks[name].calls = self.tasks[name].calls + 1

            if useLogging then
                LOG('Timing task: ' ..  name .. ' started')
            end
        end,
        -- stops profiling timer and calculates stats for optional task name
        Stop = function(self, name, useLogging)
            name = self:Verify(name)
            -- capture stop time
            self.tasks[name].stop  = CurrentTime()
            self.tasks[name].time  = self.tasks[name].stop - self.tasks[name].start
            self.tasks[name].total = self.tasks[name].total + self.tasks[name].time
            -- track improvements between consecutive profiling of the same task
            if self.tasks[name].last then
               self.tasks[name].delta = self.tasks[name].last - self.tasks[name].time
            end
            -- save current time for comparing with the next task profiling
            self.tasks[name].last = self.tasks[name].time

            if useLogging then
                LOG('Timing task: ' ..  name ..' completed in ' ..  self:ToString(name))
            end
            return self:ToString(name)
        end,
        -- verifies if profiling timer has stats for optional task name
        Verify = function(self, name)
            if not name then name = 'default-task' end
            if not self.tasks[name] then
                self.tasks[name] = {}
                self.tasks[name].name  = name
                self.tasks[name].start = nil
                self.tasks[name].stop  = nil
                self.tasks[name].delta = nil
                self.tasks[name].last  = nil
                self.tasks[name].calls = 0
                self.tasks[name].total = 0
                self.tasks[name].time  = 0
            end
            return name
        end,
        -- gets stats for optional task name
        GetStats = function(self, name)
            name = self:Verify(name)
            return self.tasks[name]
        end,
        -- gets time for optional task name
        GetTime = function(self, name)
            name = self:Verify(name)
            local ret = ''
            if not self.tasks[name].start then
                WARN('Timer cannot get time duration for not started task: ' ..  tostring(name))
            elseif not self.tasks[name].stop then
                WARN('Timer cannot get time duration for not stopped task: ' ..  tostring(name))
            else
                ret = string.format("%0.3f seconds", self.tasks[name].time)
            end
            return ret
        end,
        -- gets time delta between latest and previous profiling of named tasks
        GetDelta = function(self, name)
            name = self:Verify(name)
            local ret = ''
            if not self.tasks[name].delta then
                WARN('Timer cannot get time delta after just one profiling of task: ' ..  tostring(name))
            else
                ret = string.format("%0.3f seconds", self.tasks[name].delta)
                if self.tasks[name].delta > 0 then
                    ret = '+' .. ret
                end
            end
            return ret
        end,
        -- gets time total of all profiling calls of named tasks
        GetTotal = function(self, name)
            name = self:Verify(name)
            local ret = ''
            if not self.tasks[name].start then
                WARN('Timer cannot get time total for not started task: ' ..  tostring(name))
            else
                ret = string.format("%0.3f seconds", self.tasks[name].total)
            end
            return ret
        end,
        -- converts profiling stats for optional named task to string
        ToString = function(self, name)
            name = self:Verify(name)
            local ret = self:GetTime(name)
            if self.tasks[name].delta then
                ret = ret .. ', delta: ' .. self:GetDelta(name)
            end
            if self.tasks[name].calls > 1 then
                ret = ret .. ', calls: ' .. tostring(self.tasks[name].calls)
                ret = ret .. ', total: ' .. self:GetTotal(name)
            end
            return ret
         end,
        -- prints profiling stats of all tasks in increasing order of tasks
        -- @param key is optional sorting argument of tasks, e.g. 'stop', 'time', 'start'
         Print = function(self, key)
            key = key or 'stop'
            local sorted = table.indexize(self.tasks)
            sorted = table.sorted(sorted, sort_by(key))
            for _, task in sorted do
                if task.stop then
                    LOG('Timing task: ' ..  task.name ..' completed in ' ..  self:ToString(task.name))
                end
            end
         end
    }
end
