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

---@class NavPathToHeap
---@field Heap CompressedLabelTreeLeaf[]
---@field HeapSize number
NavPathToHeap = ClassSimple {

    ---@param self NavPathToHeap
    __init = function(self)
        self.Heap = {}
        self.HeapSize = 0
    end,

    ---@param self NavPathToHeap
    ---@return boolean
    IsEmpty = function(self)
        return self.HeapSize == 0
    end,

    ---@param self NavPathToHeap
    Clear = function(self)
        for k = 1, self.HeapSize do
            self.Heap[k] = nil
        end
        self.HeapSize = 0
    end,

    ---@param self NavPathToHeap
    ---@return CompressedLabelTreeLeaf?
    ExtractMin = function(self)
        -- if the Heap is empty, we got nothing to return!
        if self.HeapSize == 0 then
            return nil
        end

        -- keep a reference to the top value.
        local value = self.Heap[1]

        -- put our highest value at the top.
        self.Heap[1] = self.Heap[self.HeapSize]
        self.Heap[self.HeapSize] = nil
        self.HeapSize = self.HeapSize - 1

        -- fix its position.
        self:Heapify()

        return value
    end,

    ---@param self NavPathToHeap
    Heapify = function(self)
        local index = 1
        -- find the left / right child
        local left = self:ToLeftChild(index)
        local right = self:ToRightChild(index)
        -- if there is no left child it means we restored heap properties
        while self.Heap[left] do
            local min = left

            -- if there is a right child, compare its value with the left one
            -- if right is smaller, then assign min = right. Else, keep min on left.
            if self.Heap[right] and (self.Heap[right].TotalCosts < self.Heap[left].TotalCosts) then
                min = right
            end
            
            -- if min has higher value than the index it means we restored heap properties 
            -- and can break the loop
            if self.Heap[min].TotalCosts > self.Heap[index].TotalCosts then
                return
            end
            -- otherwise, swap the two values.
            self:Swap(index, min)
            -- and update index, left and right indexes.
            index = min
            left = self:ToLeftChild(index)
            right = self:ToRightChild(index)
        end
    end,

    ---@param self NavPathToHeap
    Rootify = function(self)
        local index = self.HeapSize
        local parent = self:ToParent(index)
        while parent >= 1 do
            -- if parent value is smaller than index value it means we restored correct order of the elements
            if self.Heap[parent].TotalCosts < self.Heap[index].TotalCosts then
                return
            end
            -- otherwise, swap the values
            self:Swap(parent, index)
            -- and update index and parend indexes
            index = parent
            parent = self:ToParent(index)
        end
    end,

    ---@param self NavPathToHeap
    ---@param a number
    ---@param b number
    Swap = function(self, a, b)
        local l = self.Heap[a]
        self.Heap[a] = self.Heap[b]
        self.Heap[b] = l
    end,

    ---@param self NavPathToHeap
    ---@param element CompressedLabelTreeLeaf
    Insert = function(self, element)
        if element then
            self.HeapSize = self.HeapSize + 1
            self.Heap[self.HeapSize] = element
            self:Rootify()
        else
            WARN("given object to Heap was nil!")
        end
    end,

    ---@param self NavPathToHeap
    ---@param index number
    ---@return number
    ToParent = function(self, index)
        -- index / 2
        return index >> 1
    end,

    ---@param self NavPathToHeap
    ---@param index number
    ---@return number
    ToRightChild = function(self, index)
        -- 2 * index + 1
        return 2 * index + 1
    end,

    ---@param self NavPathToHeap
    ---@param index number
    ---@return number
    ToLeftChild = function(self, index)
        -- 2 * index
        return 2 * index
    end,
}
