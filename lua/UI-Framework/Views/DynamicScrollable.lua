local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local StaticScrollable = import("StaticScrollable.lua").StaticScrollable


---@class DynamicScrollable : StaticScrollable
---@field _topLine  integer
---@field _dataSize integer
---@field _numLines integer
DynamicScrollable = Class(StaticScrollable) {

    Setup = function(self, topIndex, numLines)
        self._topLine = topIndex
        self._dataSize = self:GetDataSize()
        self._numLines = numLines
    end,

    ScrollSetTop = function(self, axis, top)
        self:GetDataSize()
        StaticScrollable.ScrollSetTop(self, axis, top)
    end,

    ---Returns data to iterate over
    ---@generic K, V
    ---@param self DynamicScrollable
    ---@return table<K,V>?
    GetData = function(self)
        return nil
    end,

    GetDataSize = function(self)
        local n = -1
        local data = self:GetData()
        local key = nil
        repeat
            key = self:DataIter(key, data)
            n = n + 1
        until key == nil
        self._dataSize = n
        return n
    end,
    ---Determines what controls should be visible or not
    ---@generic K, V
    ---@param self DynamicScrollable
    CalcVisible = function(self)
        local data = self:GetData()
        local lineIndex = 1
        local key, value = self:DataIter(nil, data)
        if key ~= nil then
            for i = 1, self._topLine - 1 do
                key, value = self:DataIter(key, data)
            end
        end
        for index = self._topLine, self._numLines + self._topLine - 1 do
            self:RenderLine(lineIndex, index, key, value)
            if key ~= nil then
                key, value = self:DataIter(key, data)
            end
            lineIndex = lineIndex + 1
        end
    end,

    ---Iterates over given data while CalcVisible, overload for more functions
    ---@generic K, V
    ---@param self DynamicScrollable
    ---@param key any
    ---@param data? table<K,V>
    ---@return K
    ---@return V
    DataIter = function(self, key, data)
        WARN(debug.traceback("Not implemented method!"))
        return nil, nil
    end,

    ---Overload for rendering lines
    ---@generic K, V
    ---@param self DynamicScrollable
    ---@param lineIndex integer
    ---@param scrollIndex integer
    ---@param key K
    ---@param value V
    RenderLine = function(self, lineIndex, scrollIndex, key, value)
        WARN(debug.traceback("Not implemented method!"))
    end,
}
