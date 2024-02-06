--**********************************************************************************
--** Copyright (c) 2022 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local LayoutHelpersScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

local Group = import("/lua/maui/group.lua").Group
local Group__init = Group.__init
local CreateLazyVar = import("/lua/lazyvar.lua").Create

-- upvalue scope for performance
local WARN = WARN
local StringFormat = string.format

--- The matrix is fixed in terms of columns, rows and item size. The width and height of the matrix is pre-defined, just like a bitmap.
---@class UIMatrix : Group
---@field _Columns number       # number of columns (horizontal/width)
---@field _Rows number          # number of rows (vertical/height)
---@field _ItemWidth number     # width of item
---@field _ItemHeight number    # height of item
---@field _ItemGap number       # gap between items
---@field _Grid Control[][]
Matrix = ClassUI(Group) {

    ---@param self UIMatrix
    ---@param parent Control
    ---@param columns number        # will be corrected for ui scale
    ---@param rows number           # will be corrected for ui scale
    ---@param itemWidth number      # will be corrected for ui scale
    ---@param itemHeight number     # will be corrected for ui scale
    ---@param itemGap number        # will be corrected for ui scale
    __init = function(self, parent, columns, rows, itemWidth, itemHeight, itemGap, debugName)
        Group__init(self, parent, debugName or (StringFormat("Matrix (%s)", tostring(self))))

        self._Columns = CreateLazyVar(columns)
        self._Rows = CreateLazyVar(rows)
        self._ItemWidth = CreateLazyVar(itemWidth)
        self._ItemHeight = CreateLazyVar(itemHeight)
        self._ItemGap = CreateLazyVar(itemGap)

        local grid = {}
        for k = 1, columns do
            grid[k] = {}
        end

        self._Grid = grid
    end,

    ---@param self UIMatrix
    ---@param parent Control
    __post_init = function(self, parent)
        self.Width:Set(function()
            local columns = self._Columns()
            local width = self._ItemWidth()
            local gap = self._ItemGap()

            if columns == 0 then
                return 0
            else
                return LayoutHelpersScaleNumber(columns * width + (columns - 1) * gap)
            end
        end)

        self.Height:Set(function()
            local rows = self._Columns()
            local height = self._ItemWidth()
            local gap = self._ItemGap()

            if rows == 0 then
                return 0
            else
                return LayoutHelpersScaleNumber(rows * height + (rows - 1) * gap)
            end
        end)
    end,

    ---@param self UIMatrix
    ---@param x number
    ---@param y number
    _ValidateIndices = function(self, x, y)
        if x < 0 then
            self:Warning(StringFormat("Invalid column: %d", x))
            return false
        elseif x > self._Columns() then
            self:Warning(StringFormat("Invalid column: %d", x))
            return false
        end

        if y < 0 then
            self:Warning(StringFormat("Invalid row: %d", y))
            return false
        elseif y > self._Rows() then
            self:Warning(StringFormat("Invalid row: %d", y))
            return false
        end

        return true
    end,

    ---------------------------------------------------------------------------
    --#region Interface

    --- Retrieve the item at the given indices. Returns nil if it is not set.
    ---@param self UIMatrix
    ---@param x number
    ---@param y number
    ---@return Control?
    GetItem = function(self, x, y)
        if not self:_ValidateIndices(x, y) then
            return
        end

        return self._Grid[x][y]
    end,

    --- Set the item at the given indices. Adjusts the width/height of the item to match the width/height of the matrix.
    ---@param self UIMatrix
    ---@param item Control
    ---@param x number
    ---@param y number
    SetItem = function(self, item, x, y)
        if not self:_ValidateIndices(x, y) then
            return
        end

        local existingItem = self._Grid[x][y]
        if existingItem then
            self:Warning(StringFormat("Overwriting existing item at (%d, %d)", x, y))
        end

        -- position the item
        LayoutHelpers.LayoutFor(item)
            :Width(self._ItemWidth)
            :Height(self._ItemHeight)
            :Top(function()
                local top = self.Top()
                local height = self._ItemHeight()
                local gap = self._ItemGap()
                if y == 0 then
                    return top
                else
                    return top + LayoutHelpersScaleNumber((y - 1) * height + (y - 1) * gap)
                end
            end)
            :Left(function()
                local left = self.Left()
                local width = self._ItemWidth()
                local gap = self._ItemGap()
                if x == 0 then
                    return left
                else
                    return left + LayoutHelpersScaleNumber((x - 1) * width + (x - 1) * gap)
                end
            end)

        -- update the parent
        item:SetParent(self)
        self._Grid[x][y] = item
    end,

    --- Destroys the item at the given indices.
    ---@param self UIMatrix
    ---@param x number
    ---@param y number
    DestroyItem = function(self, x, y)
        local item = self:GetItem(x, y)
        if item then
            item:Destroy()
            self._Grid[x][y] = nil
        end

    end,

    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    --#region Properties

    --- Set the columns of the matrix. Destroys all controls that are outside of the new dimensions of the matrix.
    ---@param self UIMatrix
    ---@param columns number
    SetColumns = function(self, columns)
        local oldColumns = self._Columns()
        if oldColumns > columns then

            local rows = self._Rows()
            for x = columns + 1, oldColumns do
                for y = 1, rows do
                    self:DestroyItem(x, y)
                end
            end
        end

        self._Columns:SetValue(columns)
    end,

    --- Set the rows of the matrix. Destroys all controls that are outside of the new dimensions of the matrix.
    ---@param self UIMatrix
    ---@param rows number
    SetRows = function(self, rows)
        local oldRows = self._Rows()
        if oldRows > rows then

            local columns = self._Columns()
            for x = 1, columns do
                for y = rows + 1, oldRows do
                    self:DestroyItem(x, y)
                end
            end
        end


        self._Rows:SetValue(rows)
    end,

    ---@param self UIMatrix
    ---@param itemWidth number
    SetItemWidth = function(self, itemWidth)
        self._ItemWidth:SetValue(itemWidth)
    end,

    ---@param self UIMatrix
    ---@param itemHeight number
    SetItemHeight = function(self, itemHeight)
        self._ItemHeight:SetValue(itemHeight)
    end,

    ---@param self UIMatrix
    ---@param itemGap number
    SetItemGap = function(self, itemGap)
        self._ItemGap:SetValue(itemGap)
    end,

    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    --#region Debugging

    ---@param self UIMatrix
    ---@param message string
    Warning = function(self, message)
        WARN(StringFormat("%s - %s", self:GetName(), message))
    end,

    ---------------------------------------------------------------------------
}
