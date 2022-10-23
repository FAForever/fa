---@type fun(data:table?) : Dict
local _Dict
---@class Dict
---@field _data table<any,any>
---@overload fun(data:table?):Dict
Dict = ClassSimple
{
    ---Creates dict from given table
    ---@param self Dict
    ---@param data? table
    __init = function(self, data)
        self._data = {}
        if data then
            local d = self._data
            for k, v in data do
                d[k] = v
            end
        end
    end,

    ---Returns value by key
    ---@generic K
    ---@generic V
    ---@param self Dict
    ---@param key K
    ---@return V
    Get = function(self, key)
        return self._data[key]
    end,

    ---Checks whether dict contains value
    ---@param self Dict
    ---@param value any
    ---@return boolean
    Contains = function(self, value)
        for _, v in self._data do
            if v == value then
                return true
            end
        end
        return false
    end,

    ---Creates array of values from Dict
    ---@param self Dict
    ---@return table
    Values = function(self)
        local arr = {}
        for _, v in self._data do
            table.insert(arr, v)
        end
        return arr
    end,

    ---Creates array of keys from Dict
    ---@param self Dict
    ---@return table
    Keys = function(self)
        local arr = {}
        for k, _ in self._data do
            table.insert(arr, k)
        end
        return arr
    end,


    ---Adds key, value to a dict
    ---@param self Dict
    ---@param key any
    ---@param value any
    Add = function(self, key, value)
        self._data[key] = value
    end,

    ---Removes key from a dict
    ---@param self Dict
    ---@param key any
    Remove = function(self, key)
        self._data[key] = nil
    end,

    ---Clears dict
    ---@param self Dict
    Clear = function(self)
        self._data = {}
    end,

    ---Returns size of dict
    ---@param self Dict
    ---@return integer
    Size = function(self)
        return table.getsize(self._data)
    end,

    ---Checks whether dict is empty
    ---@param self Dict
    ---@return boolean
    IsEmpty = function(self)
        return table.empty(self._data)
    end,

    ---Returns copy of a dict
    ---@param self Dict
    ---@return Dict
    Copy = function(self)
        return _Dict(self._data)
    end,

    ---Returns true if any element of dict satisfies condition
    ---@param self Dict
    ---@param condition? fun(key:any, value:any):boolean
    ---@return boolean
    Any = function(self, condition)
        for k, v in self._data do
            if not condition or condition(k, v) then
                return true
            end
        end
        return false
    end,

    ---Returns true if all elements of dict satisfy condition or dict is empty
    ---@param self Dict
    ---@param condition fun(key:any, value:any):boolean
    ---@return boolean
    All = function(self, condition)
        for k, v in self._data do
            if not condition(k, v) then
                return false
            end
        end
        return true
    end,

    ---Returns new Dict where each element satisfies condition
    ---@param self Dict
    ---@param condition fun(key:any, value:any):boolean
    ---@return Dict
    Where = function(self, condition)
        local result = _Dict()
        for k, v in self._data do
            if condition(k, v) then
                result:Add(k, v)
            end
        end
        return result
    end,

    ---Dict Iterator
    ---@param self Dict
    ---@return fun(tbl: table<any,any>, key:any):any,any
    ---@return table<any,any>
    Iter = function(self)
        return self.Next, self._data
    end,

    ---Next function for dict data
    Next = next,

    ---Returns first pair satisfying condition
    ---@generic K
    ---@generic V
    ---@param self Dict
    ---@param condition fun(key:K, value:V):boolean
    ---@return K?
    ---@return V?
    First = function(self, condition)
        for k, v in self._data do
            if not condition or condition(k, v) then
                return k, v
            end
        end
        return nil, nil
    end,

    ---Returns last pair satisfying condition
    ---@generic K
    ---@generic V
    ---@param self Dict
    ---@param condition fun(key:K, value:V):boolean
    ---@return K?
    ---@return V?
    Last = function(self, condition)
        local l = nil
        for k, v in self._data do
            if not condition or condition(k, v) then
                l = k
            end
        end
        if l ~= nil then
            return l, self._data[l]
        end
        return nil, nil
    end,

    ---Maps dict through callback
    ---@param self Dict
    ---@param callback fun(key, value):any
    ---@return Dict
    Map = function(self, callback)
        local result = _Dict()
        local value
        for k, v in self._data do
            value = callback(k, v)
            if value ~= nil then
                result:Add(k, value)
            end
        end
        return result
    end,

    ---Reduces dict to a single value
    ---@generic K
    ---@generic V
    ---@generic R
    ---@param self Dict
    ---@param reducer fun(prev:R, key:K, value:V):R
    ---@param initalValue? R
    ---@return R
    Reduce = function(self, reducer, initalValue)
        local result = initalValue or 0
        for k, v in self._data do
            result = reducer(result, k, v)
        end
        return result
    end

}
---@diagnostic disable-next-line
_Dict = Dict
