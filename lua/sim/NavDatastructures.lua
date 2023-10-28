--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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
--******************************************************************************************************

---@class Stack
---@field Size number
Stack = ClassSimple {

    ---@param self Stack
    __init = function(self)
        self.Size = 0
    end,

    ---@param self Stack
    ---@param element any
    Push = function(self, element)
        local size = self.Size
        self[size + 1] = element
        self.Size = size + 1
    end,

    ---@param self Stack
    ---@return any
    Pop = function(self)
        local size = self.Size
        if size > 0 then
            local element = self[size]
            self.Size = size - 1
            return element
        end
    end,

    ---@param self Stack
    ---@return boolean
    Empty = function(self)
        return self.Size == 0
    end,

    ---@param self Stack
    Clear = function(self)
        self.Size = 0
    end,
}

---@class NavHeap
---@field Heap NavSection[]
---@field HeapSize number
NavHeap = ClassSimple {

    ---@param self NavHeap
    __init = function(self)
        self.Heap = {}
        self.HeapSize = 0
    end,

    ---@param self NavHeap
    ---@return boolean
    IsEmpty = function(self)
        return self.HeapSize == 0
    end,

    ---@param self NavHeap
    Clear = function(self)
        self.HeapSize = 0
    end,

    ---@param self NavHeap
    ---@return NavSection?
    ExtractMin = function(self)
        local heap = self.Heap
        local heapSize = self.HeapSize

        -- if the Heap is empty, we got nothing to return!
        if heapSize == 0 then
            return nil
        end

        -- keep a reference to the top value.
        local value = heap[1]

        -- put our highest value at the top.
        heap[1] = heap[heapSize]
        heap[heapSize] = nil
        self.HeapSize = heapSize - 1

        -- fix its position.
        self:Heapify()

        -- DrawCircle(value.Center, 5, '9999ff')

        return value
    end,

    --- 'Bubble down' operation, applied when we extract an element from the heap
    ---@param self NavHeap
    Heapify = function(self)
        local heap = self.Heap
        local heapSize = self.HeapSize

        -- find the left / right child
        local index = 1
        local left = 2 * index
        local right = 2 * index + 1

        -- if there is no left child it means we restored heap properties
        while left <= heapSize do
            local min = left

            -- if there is a right child, compare its value with the left one
            -- if right is smaller, then assign min = right. Else, keep min on left.
            if right <= heapSize and (heap[right].HeapTotalCosts < heap[left].HeapTotalCosts) then
                min = right
            end

            -- if min has higher value than the index it means we restored heap properties
            -- and can break the loop
            if heap[min].HeapTotalCosts > heap[index].HeapTotalCosts then
                return
            end

            -- otherwise, swap the two values.
            local tmp = heap[min]
            heap[min] = heap[index]
            heap[index] = tmp

            -- and update index, left and right indexes.
            index = min
            left = 2 * index
            right = 2 * index + 1
        end
    end,

    --- 'Bubble up' operation, applied when we insert a new element into the heap
    ---@param self NavHeap
    Rootify = function(self)
        local heap = self.Heap
        local index = self.HeapSize

        local parent = math.floor(index / 2)
        while parent >= 1 do

            -- if parent value is smaller than index value it means we restored correct order of the elements
            if heap[parent].HeapTotalCosts < heap[index].HeapTotalCosts then
                return
            end

            -- otherwise, swap the values
            local tmp = heap[parent]
            heap[parent] = heap[index]
            heap[index] = tmp

            -- and update index and parent indexes
            index = parent

            parent = math.floor(parent / 2)
        end
    end,

    ---@param self NavHeap
    ---@param element NavSection
    Insert = function(self, element)
        self.HeapSize = self.HeapSize + 1
        self.Heap[self.HeapSize] = element
        self:Rootify()

        -- DrawCircle(element.Center, 5, '999999')

    end,
}
