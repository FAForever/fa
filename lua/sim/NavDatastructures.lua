
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

---@class NavPathToNode 
---@field Root LabelTree
---@field Target LabelTree
---@field At LabelTree
---@field AcquiredCosts number
---@field ExpectedCosts number 

---@class NavPathToHeap
---@field Heap NavPathToNode[]
---@field HeapSize number
NavPathToHeap = ClassSimple {

    __init = function(self)
        self.Heap = { }
        self.HeapSize = 0
    end,

    IsEmpty = function(self)
        return self.HeapSize == 0
    end,

    ExtractMin = function(self)
        -- if the Heap is empty, we got nothing to return!
        if self.HeapSize == 0 then
            return nil;
        end

        -- keep a reference to the top value.
        local value = self.Heap[1];

        -- put our highest value at the top.
        self.Heap[1] = self.Heap[self.HeapSize];
        self.Heap[self.HeapSize] = nil;
        self.HeapSize = self.HeapSize - 1;

        -- fix its position.
        self:Heapify(1);

        return value;
    end,

    Heapify = function(self, index)
        -- find the left / right child and the parent.
        local parent = index;
        local left = self:ToLeftChild(index);
        local right = self:ToRightChild(index);

        -- find the best of the two, we assume the left child is.
        local min = left;

        -- if there is a right child, then there always has to be a left child. Hence, we can now assume there's both a right and a left child.
        -- compare the two: if right is smaller, then assign min = right. Else, keep min on left.
        if self.Heap[right] then
            if (self.compare(self.Heap[right])) < (self.compare(self.Heap[left])) then
                min = right;
            end
        end

        -- if there is a child, compare the lowest child (is given due to code above) with our parent. 
        -- If it's smaller, switch the parent and the lowest child.
        if self.Heap[min] then
            if (self.compare(self.Heap[min])) < (self.compare(self.Heap[parent])) then
                -- swap the two values.
                self:Swap(parent, min);

                -- check if the (parent) value that is now at the child position is at the correct position within the Heap.
                self:Heapify(min);
            end
        end
    end,

    Rootify = function(self, index)
        local parent = self:ToParent(index);
        local current = index;
    
        if (current == 1) or self.compare(self.Heap[parent]) < self.compare(self.Heap[current]) then
            return;
        end
    
        self:Swap(parent, current);
        self:Rootify(parent);
    end,

    Swap = function(self, a, b)
        local l = self.Heap[a];
        self.Heap[a] = self.Heap[b];
        self.Heap[b] = l;
    end,

    Insert = function(self, element)
        if element then
            self.HeapSize = self.HeapSize + 1;
            self.Heap[self.HeapSize] = element;
            self:Rootify(self.HeapSize);
        else
            WARN("given object to Heap was nil!");
        end
    end,

    ToParent = function(self, index)
        -- index / 2
        return index >> 1;
    end,

    ToRightChild = function(self, index)
        -- 2 * index + 1
        return (index << 1) | 1;
    end,

    ToLeftChild = function (self, index)
        -- 2 * index
        return index << 1;
    end,
}

---@class NavNodePool
NavPathToNodePool = ClassSimple {

    __init = function(self)
        self.Pool = { }
    end,

    Acquire = function(self)

    end,

    Release = function(self)

    end,
}