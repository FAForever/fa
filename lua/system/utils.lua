-- ==========================================================================================
-- * File       : lua/system/utils.lua 
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains global functions for working with tables and strings
-- ==========================================================================================

--- RandomIter(table) returns a function that when called, returns a pseudo-random element of the supplied table.
--- Each element of the table will be returned once. This is essentially for "shuffling" sets.
function RandomIter(someSet)
    local keyList = {}
    for key, val in someSet do
        table.insert(keyList, key)
    end

    return function()
        local size = table.getn(keyList)

        if size > 0 then
            local key = table.remove(keyList, Random(1, size))
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

--- table.copy(t) returns a shallow copy of t.
function table.copy(t)
    if not t then return end -- prevents looping over nil table 
    local r = {}
    for k,v in t do
        r[k] = v
    end
    return r
end

--- table.contains(t,val) returns the key for val if it is in t table.
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
            table.remove(t,k)
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
function table.cat(t1, t2)
    -- handling nil tables before lopping
    if not t1 then return table.copy(t2) end
    if not t2 then return table.copy(t1) end
    local r = {}
    for i,v in t1 do
        table.insert(r, v)
    end

    for i,v in t2 do
        table.insert(r, v)
    end

    return r
end

--- Concatenate arbitrarily-many tables (equivalent to table.cat, but varargs. 
--- Slightly more overhead, but can constructively concat *all* the things)
function table.concatenate(...)
    local ret = {}

    for index = 1, table.getn(arg) do
        if arg[index] then
            for k, v in arg[index] do
                table.insert(ret, v)
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
        table.insert(t1, v)
    end
end

--- table.sorted(t, [comp]) is the same as table.sort(t, comp) except it returns
--- a sorted copy of t, leaving the original unchanged.
--- [comp] is an optional comparison function, defaulting to less-than.
function table.sorted(t, comp)
    local r = table.copy(t)
    table.sort(r, comp)
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

--- table.keys(t, [comp], [skip]) returns a list of the keys of t, sorted.
--- [comp] is an optional comparison function, defaulting to less-than.
--- [skip] is an optional boolean that specifies if sorting is needed, defaulting to true
function table.keys(t, comp, skip)
    local r = {}
    if not t then return r end -- prevents looping over nil table
    local n = 1
    for k,v in t do
        r[n] = k -- faster than table.insert(r,k)
        n = n + 1
    end
    if not skip then table.sort(r, comp) end
    return r
end

--- table.keysfast(t) returns a list of the keys of t, in unspecified order.
--- this function is about 3 times faster than table.keys(t, [comp], [skip])
function table.keysfast(t)
    return table.keys(t, nil, true)
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

--- Returns actual size of a table, including string keys
function table.getsize(t)
    -- handling nil table like empty tables so that no need to check 
    -- for nil table and then size of table:
    -- if t and table.getsize(t) > 0 then 
    -- do some thing 
    -- end 
    if type(t) ~= 'table' then return 0 end 
    local size = 0
    for k, v in t do
        size = size + 1
    end
    return size
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

--- Converts a table to a new table with values as keys and values equal to true
--- it is useful for quickly looking up values in tables instead of looping over it 
--- table.hash { [1] = 'A',  [2] = 'B',  [3] = 'C' } => 
--             { [A] = true, [B] = true, [C] = true } 
function table.hash(t)
    if not t then return {} end -- prevents looping over nil table
    local r = {}
    for k, v in t do
        r[v] = true
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

--- Concatenate keys of hash table if their values equal to specified boolean value, defaults to true
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

--- table.empty(t) returns true iff t has no keys/values.
function table.empty(t)
    return table.getsize(t) == 0 
end

--- table.shuffle(t) returns a shuffled table
function table.shuffle(t)
    local r = {}
    for key, val in RandomIter(t) do
        if type(key) == 'number' then
            table.insert(r, val)
        else
            r[key] = val
        end
    end
    return r
end

-- table.binsert(t, value, cmp) binary insert value into table using cmp-func
function table.binsert(t, value, cmp)
      local cmp = cmp or (function( a,b ) return a < b end)
      local start, stop, mid, state = 1, table.getsize(t), 1, 0
      while start <= stop do
         mid = math.floor((start + stop) / 2)
         if cmp(value, t[mid]) then
            stop, state = mid - 1, 0
         else
            start, state = mid + 1, 1
         end
      end

      table.insert(t, mid + state, value)
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
--- @param tbl specifies a table to print
--- @param tblPrefix specifies optional table prefix/name
--- @param printer specifies optional message printer: LOG, WARN, error, etc.
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
    if table.getsize(tbl) == 0 then
        printer(tblPrefix .." { }")
        return
    end
    printer(tblPrefix.." {")
    for k, v in pairs(tbl) do
        printField(k, v, tblPrefix .. "    ", printer)
    end

    printer(tblPrefix.." }")
end

--- Filter a table using a function.
--- @param t is a table to filter
--- @param fn is decision function to use to filter the table.
--- @return A new table containing every mapping from t for which fn function returns `true` when passed the value.
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

--- Returns a new table with unique values
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
    return string.sub(stringToMatch, 1, valueToSeek:len()) == valueToSeek
end

--- Extracts a string between two specified strings  
--- e.g. StringExtract('/path/name_end.lua', '/', '_end', true) --> name
function StringExtract(str, str1, str2, fromEnd)
    local pattern = str1 .. '(.*)' .. str2
    if fromEnd then pattern = '.*' .. pattern end
    local i, ii, m = string.find(str, pattern)
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
--- Splits a string with camel cast to a string with separate words
--- e.g. StringSplitCamel('SupportCommanderUnit') -> 'Support Commander Unit'
function StringSplitCamel(str)
   return (str:gsub("[A-Z]", StringPrepend):gsub("^.", string.upper))
end

--- Reverses order of letters for specified string
--- e.g. StringCapitalize('abc123') --> 321cba
function StringReverse(str)
    local tbl =  {}
    str:gsub(".",function(c) table.insert(tbl,c) end)  
    tbl = table.reverse(tbl)
    return table.concat(tbl) 
end
--- Capitalizes each word in specified string 
--- e.g. StringCapitalize('hello supreme commander') --> Hello Supreme Commander
function StringCapitalize(str)
    return string.gsub(" "..str, "%W%l", string.upper):sub(2) 
end

--- Sorts two variables based on their numeric value or alpha order (strings)
function Sort(itemA, itemB)
    if not itemA or not itemB then return 0 end
    
    if type(itemA) == "string" or 
       type(itemB) == "string" then
        if string.lower(itemA) == string.lower(itemB) then
            return 0
        else
            -- sort string using alpha order
            return string.lower(itemA) < string.lower(itemB) 
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
function math.round(num, idp)
    if not idp then
        return math.floor(num+.5)
    else
        return tonumber(string.format("%." .. (idp or 0) .. "f", num))
    end
end

--- Clamps numeric value to specified Min and Max range
function math.clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

--- Creates a new, started timer
function StartedTimer()
    return {
        startTime = CurrentTime(),
        endTime = nil,
        Stop = function(self)
            self.endTime = CurrentTime()
            return self:ToString()
        end,
        GetDuration = function(self)
            return self.endTime - self.startTime
        end,
        ToString = function(self)
            return string.format("%0.3fms", self:GetDuration() * 1000)
        end
    }
end
