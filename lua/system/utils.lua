--=========================================================================================================
-- RandomIter(table) returns a function that when called, returns a pseudo-random element of the supplied table.
-- Each element of the table will be returned once. This is essentially for "shuffling" sets.
--=========================================================================================================
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


--==============================================================================
-- safecall(msg, fn, ...) calls the given function with the given
-- args, and catches any error and logs a warning including the given msg.
-- Returns nil if the function failed, otherwise returns the function's result.
--------------------------------------------------------------------------------
function safecall(msg, fn, ...)
    local ok, result = pcall(fn, unpack(arg))
    if ok then
        return result
    else
        WARN("Problem " .. tostring(msg) .. ":\n" .. result)
        return
    end
end


--==============================================================================
-- table.copy(t) returns a shallow copy of t.
--------------------------------------------------------------------------------
function table.copy(t)
    local r = {}
    for k,v in t do
        r[k] = v
    end
    return r
end

--==============================================================================
-- table.contains(t,val) returns the key for val if it is in t.
-- Otherwise, return nil
--------------------------------------------------------------------------------
function table.find(t,val)
    for k,v in t do
        if v == val then
            return k
        end
    end
    -- return nil by falling off the end
end

--==============================================================================
-- table.subset(t1,t2) returns true iff every key/value pair in t1 is also in t2
--------------------------------------------------------------------------------
function table.subset(t1,t2)
    for k,v in t1 do
        if t2[k] ~= v then return false end
    end
    return true
end

--==============================================================================
-- table.equal(t1,t2) returns true iff t1 and t2 contain the same key/value pairs.
--------------------------------------------------------------------------------
function table.equal(t1,t2)
    return table.subset(t1,t2) and table.subset(t2,t1)
end

--==============================================================================
-- table.removeByValue(t,val) remove a field by value instead of by index
--------------------------------------------------------------------------------
function table.removeByValue(t,val)
    for k,v in t do
        if v == val then
            table.remove(t,k)
            return
        end
    end
end

--==============================================================================
-- table.deepcopy(t) returns a copy of t with all sub-tables also copied.
--------------------------------------------------------------------------------
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


--==============================================================================
-- table.merged(t1,t2) returns a table in which fields from t2 overwrite
-- fields from t1. Neither t1 nor t2 is modified. The returned table may
-- share structure with either t1 or t2, so it is not safe to modify.
--
-- For example:
--       t1 = { x=1, y=2, sub1={z=3}, sub2={w=4} }
--       t2 = { y=5, sub1={a=6}, sub2="Fred" }
--
--       merged(t1,t2) ->
--           { x=1, y=5, sub1={a=6,z=3}, sub2="Fred" }
--
--       merged(t2, t1) ->
--           { x=1, y=2, sub1={a=6,z=3}, sub2={w=4} }
--------------------------------------------------------------------------------
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
    for k, v in t2 do
        if t1[k] == nil then
            t1[k] = v
        end
    end

    return t1
end

--- Remove all keys in t2 from t1.
function table.subtract(t1, t2)
    for k, v in t2 do
        t1[k] = nil
    end

    return t1
end

--==============================================================================
-- table.cat(t1, t2) performs a shallow "merge" of t1 and t2, where t1 and t2
-- are expected to be numerically keyed (existing keys are discarded).
--
-- Example:
--   table.cat({1, 2, 3}, {'A', 'House', 3.14})  ->  {1, 2, 3, 'A', 'House', 3.14}
--
--------------------------------------------------------------------------------
function table.cat(t1, t2)
    local tRet = {}

    for i,v in t1 do
        table.insert(tRet, v)
    end

    for i,v in t2 do
        table.insert(tRet, v)
    end

    return tRet
end

--- Concatenate arbitrarily-many tables (equivalent to table.cat, but varargs. Slightly more
-- overhead, but can constructvely concat *all* the things)
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
--
-- Appends the keys of t2 onto t1, returning it. The original t1 is destroyed, but this avoids the
-- need to copy the values in t1, saving some time.
function table.destructiveCat(t1, t2)
    for k, v in t2 do
        table.insert(t1, v)
    end
end

--==============================================================================
-- table.sorted(t, [comp]) is the same as table.sort(t, comp) except it returns
-- a sorted copy of t, leaving the original unchanged.
--
-- [comp] is an optional comparison function, defaulting to less-than.
--------------------------------------------------------------------------------
function table.sorted(t, comp)
    local r = table.copy(t)
    table.sort(r, comp)
    return r
end


--==============================================================================
-- sort_by(field) provides a handy comparison function for sorting
-- a list of tables by some field.
--
-- For example,
--       my_list={ {name="Fred", ...}, {name="Wilma", ...}, {name="Betty", ...} ... }
--
--       table.sort(my_list, sort_by 'name')
--           to get names in increasing order
--
--       table.sort(my_list, sort_down_by 'name')
--           to get names in decreasing order
--------------------------------------------------------------------------------
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


--==============================================================================
-- table.keys(t, [comp]) -- Return a list of the keys of t, sorted.
--
-- [comp] is an optional comparison function, defaulting to less-than.
--------------------------------------------------------------------------------
function table.keys(t, comp)
    local r = {}
    for k,v in t do
        table.insert(r,k)
    end
    table.sort(r, comp)
    return r
end


--==============================================================================
-- table.values(t) -- Return a list of the values of t, in unspecified order.
--------------------------------------------------------------------------------
function table.values(t)
    local r = {}
    for k,v in t do
        table.insert(r,v)
    end
    return r
end


--==============================================================================
-- sortedpairs(t, [comp]) -- Iterate over a table in key-sorted order:
--   for k,v in sortedpairs(t) do
--       print(k,v)
--   end
--
-- [comp] is an optional comparison function, defaulting to less-than.
--------------------------------------------------------------------------------
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


--==============================================================================
-- table.getsize(t) returns actual size of a table, including string keys
--------------------------------------------------------------------------------
function table.getsize(t)
    if type(t) ~= 'table' then return end
    local size = 0
    for k, v in t do
        size = size + 1
    end
    return size
end



--==============================================================================
-- table.inverse(t) returns a table with keys and values from t reversed.
--
-- e.g. table.inverse {'one','two','three'} => {one=1, two=2, three=3}
--      table.inverse {foo=17, bar=100}     => {[17]=foo, [100]=bar}
--
-- If t contains duplicate values, it is unspecified which one will be returned.
--
-- e.g. table.inverse {foo='x', bar='x'} => possibly {x='bar'} or {x='foo'}
--------------------------------------------------------------------------------
function table.inverse(t)
    r = {}
    for k,v in t do
        r[v] = k
    end
    return r
end


--==============================================================================
-- table.map(fn,t) returns a table with the same keys as t but with
-- fn applied to each value.
--------------------------------------------------------------------------------
function table.map(fn, t)
    r = {}
    for k,v in t do
        r[k] = fn(v)
    end
    return r
end



--==============================================================================
-- table.empty(t) returns true iff t has no keys/values.
--------------------------------------------------------------------------------
function table.empty(t)
    for k,v in t do
        return false
    end
    return true
end

--==============================================================================
-- table.shuffle(t) returns a shuffled table
--------------------------------------------------------------------------------
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

-- Pretty-print a table. Depressingly large amount of wheel-reinvention were required, thanks to
-- SC's Lua being a bit weird and the existing solutions to this problem being aggressively optimised
-- for some stupid reason. :/
function printField(k, v, prefix)
    if "string" == type(v) then
        WARN(prefix .. k .. " = " .. "\"" .. v .. "\"")
    elseif "table" == type(v) then
        WARN(prefix .. k .. " = ")
        table.print(v, prefix .. "    ", WARN)
    else
        WARN(prefix .. k .. " = " .. tostring(v))
    end
end

function table.print(tbl, prefix)
    if not prefix then prefix = "" end
    if not tbl then
        WARN("nil")
        return
    end

    WARN(prefix.."{")
    for k, v in pairs(tbl) do
        printField(k, v, prefix .. "    ", WARN)
    end

    WARN(prefix.."}")
end

--- Filter a table using a function.
--
-- @param t Table to filter
-- @param filterFunc Decision function to use to filter the table.
-- @return A new table containing every mapping from t for which filterFunc returns `true` when
--         passed the value.
function table.filter(t, filterFunc)
    local newTable = {}
    for k, v in t do
        if filterFunc(v) then
            newTable[k] = v
        end
    end

    return newTable
end
