
local WeakMetatable = {__mode = "v"}

---@class QuadTreeNode<T>: {[1]?: QuadTreeNode<T>, [2]?: QuadTreeNode<T>, [3]?: QuadTreeNode<T>, [4]?: QuadTreeNode<T>, Bucket?: T[], Tree: QuadTree<T>}
---@field Depth number
---@field MidX number | nil
---@field MidY number | nil
---@field Rectangle Rectangle
---@field Size number
---@field SplitDisabled boolean | nil
QuadTreeNode = Class {
    __init = function(self, tree, x, y, w, h, depth)
        self.Depth = depth
        self.Tree = tree
        self.Rectangle = {x, y, w, h}
        self.Bucket = true
        self.Size = 0
        if depth >= tree.MaxDepth then
            self.SplitDisabled = true
        else
            self[1] = nil -- lower left
            self[2] = nil -- upper left
            self[3] = nil -- lower right
            self[4] = nil -- upper right
        end
    end;

    GetQuadrant = function(self, x, y)
        local quadrant = 1
        if x > self.MidX then
            quadrant = quadrant + 1
        end
        if y > self.MidY then
            quadrant = quadrant + 2
        end
        return quadrant
    end;

    GetNode = function(self, x, y)
        local midX, midY = self.MidX, self.Midy
        if x < midX then
            if y < midY then
                return self[1]
            else
                return self[2]
            end
        else
            if y < midY then
                return self[3]
            else
                return self[4]
            end
        end
    end;

    ---@overload fun(self: QuadTreeNode>)
    ---@overload fun(self: QuadTreeNode, toAdd: any)
    ---@param self QuadTreeNode
    ---@param toAdd any[]
    ---@param toAddCount number
    Split = function(self, toAdd, toAddCount)
        if self[1] then return end
        local rect = self.Rectangle
        local tree = self.Tree
        local depth = self.Depth + 1
        local bucket = self.Bucket
        local x, y, w, h = rect[1], rect[2], rect[3], rect[4]
        local halfW, halfH = 0.5 * w, 0.5 * h
        local midX, midY = x + halfW, y + halfH

        local ll = QuadTreeNode(tree, x,    y,    halfW, halfH, depth)
        local ul = QuadTreeNode(tree, x,    midY, halfW, halfH, depth)
        local lr = QuadTreeNode(tree, midX, y,    halfW, halfH, depth)
        local ur = QuadTreeNode(tree, midX, midY, halfW, halfH, depth)
        local llBucket, ulBucket, lrBucket, urBucket = {}, {}, {}, {}
        local llSize, ulSize, lrSize, urSize = 0, 0, 0, 0
        for i = 1, self.Size do
            local element = bucket[i]
            local elX, elY = element.x, element.y
            if elX < midX then
                if elY < midY then
                    llSize = llSize + 1; llBucket[llSize] = element
                else
                    ulSize = ulSize + 1; ulBucket[ulSize] = element
                end
            else
                if elY < midY then
                    lrSize = lrSize + 1; lrBucket[lrSize] = element
                else
                    urSize = urSize + 1; urBucket[urSize] = element
                end
            end
        end

        if toAdd then
            if toAddCount then
                for i = 1, toAddCount do
                    local element = toAdd[i]
                    local elX, elY = element.x, element.y
                    if elX < midX then
                        if elY < midY then
                            llSize = llSize + 1; llBucket[llSize] = element
                        else
                            ulSize = ulSize + 1; ulBucket[ulSize] = element
                        end
                    else
                        if elY < midY then
                            lrSize = lrSize + 1; lrBucket[lrSize] = element
                        else
                            urSize = urSize + 1; urBucket[urSize] = element
                        end
                    end
                end
            else
                local elX, elY = toAdd.x, toAdd.y
                if elX < midX then
                    if elY < midY then
                        llSize = llSize + 1; llBucket[llSize] = toAdd
                    else
                        ulSize = ulSize + 1; ulBucket[ulSize] = toAdd
                    end
                else
                    if elY < midY then
                        lrSize = lrSize + 1; lrBucket[lrSize] = toAdd
                    else
                        urSize = urSize + 1; urBucket[urSize] = toAdd
                    end
                end
            end
        end

        if llSize > 0 then ll:AddElements(llBucket) end
        if ulSize > 0 then ul:AddElements(ulBucket) end
        if lrSize > 0 then lr:AddElements(lrBucket) end
        if urSize > 0 then ur:AddElements(urBucket) end
        self[1], self[2], self[3], self[4] = ll, ul, lr, ur
        self.MidX = midX
        self.MidY = midY
        self.Bucket = nil
        self.Size = nil
    end;

    Collapse = function(self)
        local bucket = self.Bucket
        if bucket then
            local move = 0
            local size = self.Size
            for i = 1, size do
                if not bucket[i] then
                    move = move + 1
                elseif move ~= 0 then
                    bucket[i - move] = bucket[i]
                end
            end
            if move ~= 0 then
                local newSize = size - move
                for i = size, newSize do
                    bucket[i] = nil
                end
                self.Size = newSize
            end
        else
            local ll, ul, lr, ur = self[1], self[2], self[3], self[4]
            ll:Collapse()
            ul:Collapse()
            lr:Collapse()
            ur:Collapse()
            local llSize, ulSize, lrSize, urSize = ll.Size, ul.Size, lr.Size, ur.Size
            -- there's been enough room made to merge our node
            if llSize + ulSize + lrSize + urSize < self.Tree.Capacity then
                bucket = {}
                setmetatable(bucket, WeakMetatable)
                local size = 0
                local bucketChild = ll.Bucket
                for i = 1, llSize do
                    size = size + 1
                    bucket[size] = bucketChild[i]
                end
                bucketChild = ul.Bucket
                for i = 1, ulSize do
                    size = size + 1
                    bucket[size] = bucketChild[i]
                end
                bucketChild = lr.Bucket
                for i = 1, lrSize do
                    size = size + 1
                    bucket[size] = bucketChild[i]
                end
                bucketChild = ur.Bucket
                for i = 1, urSize do
                    size = size + 1
                    bucket[size] = bucketChild[i]
                end
                self.Bucket = bucket
                self.Size = size
                self[1] = nil
                self[2] = nil
                self[3] = nil
                self[4] = nil
            end
        end
    end;

    AddElement = function(self, element)
        local bucket = self.Bucket
        if bucket then
            local size = self.Size
            size = size + 1
            if size <= self.Tree.Capacity or self.SplitDisabled then
                if size == 1 then
                    bucket = {element}
                    -- let the garbage collector take our elements so we don't have to remove them
                    setmetatable(bucket, WeakMetatable)
                    self.Bucket = bucket
                    self.Size = size
                else
                    bucket[size] = element
                end
                self.Size = size
            else
                self:Split(element)
            end
        else
            local midX, midY = self.MidX, self.MidY
            local elX, elY = element.x, element.y
            if elX < midX then
                if elY < midY then
                    self[1]:AddElement(element)
                else
                    self[2]:AddElement(element)
                end
            else
                if elY < midY then
                    self[3]:AddElement(element)
                else
                    self[4]:AddElement(element)
                end
            end
        end
    end;

    AddElements = function(self, elements)
        local bucket = self.Bucket
        local elementCount = table.getn(elements)
        if bucket then
            local size = self.Size
            if size + elementCount <= self.Tree.Capacity or self.SplitDisabled then
                if size == 0 then
                    bucket = {}
                    -- let the garbage collector take our elements so we don't have to remove them
                    setmetatable(bucket, WeakMetatable)
                    for i = 1, elementCount do
                        bucket[i] = elements[i]
                    end
                    self.Bucket = bucket
                else
                    for i = 1, elementCount do
                        bucket[size + i] = elements[i]
                    end
                end
                self.Size = size
            else
                self:Split(elements, elementCount)
            end
        else
            local midX, midY = self.MidX, self.MidY
            local llBucket, ulBucket, lrBucket, urBucket = {}, {}, {}, {}
            local llSize, ulSize, lrSize, urSize = 0, 0, 0, 0
            for i = 1, table.getn[elements] do
                local element = elements[i]
                local elX, elY = element.x, element.y
                if elX < midX then
                    if elY < midY then
                        llSize = llSize + 1; llBucket[llSize] = element
                    else
                        ulSize = ulSize + 1; ulBucket[ulSize] = element
                    end
                else
                    if elY < midY then
                        lrSize = lrSize + 1; lrBucket[lrSize] = element
                    else
                        urSize = urSize + 1; urBucket[urSize] = element
                    end
                end
            end
            if llSize > 0 then self[1]:AddElements(llBucket) end
            if ulSize > 0 then self[2]:AddElements(ulBucket) end
            if lrSize > 0 then self[3]:AddElements(lrBucket) end
            if urSize > 0 then self[4]:AddElements(urBucket) end
        end
    end;
}

-- Oh no, a random quad tree appeared!
---@class QuadTree<T>: QuadTreeNode<T>
---@field MaxDepth number
QuadTree = Class(QuadTreeNode) {
    --- Constructs a quad tree that spans the provided area
    ---@param x number The x coordinate of the top left corner of the rectangle that spans the area of the quad tree
    ---@param y number The z coordinate of the top left corner of the rectangle that spans the area of the quad tree
    ---@param width number The width of the rectangle that spans the area of the quad tree
    ---@param height number The height of the rectangle that spans the area of the quad tree
    ---@param maxDepth number The maximum depth of the quad tree
    ---@param bucketCapacity number
    __init = function(self, x, y, width, height, maxDepth, bucketCapacity)
        QuadTreeNode.__init(self, x, y, width, height, 1)
        -- start with four children
        self.Capacity = bucketCapacity or 10
        self.MaxDepth = maxDepth
    end;

    GetLeafNode = function(self, x, y)
        local node = self.Root
        while true do
            local testNode = node:GetNode(x, y)
            if testNode == nil then
                return node
            end
            node = testNode
        end
    end;

    NodesBreadthFirst = function(self)
        local list = {self.Node}
        local listHead = 1
        local listSize = 1
        repeat
            local head = list[listHead]
            listHead = listHead + 1
            local quad = head[1]
            if quad then
                list[listSize + 1] = quad
                list[listSize + 2] = head[2]
                list[listSize + 3] = head[3]
                listSize = listSize + 4
                list[listSize] = head[4]
            end
        until listHead > listSize
        return list
    end;

    NodesDepthFirst = function(self)
        local list = {self.Node}
        local listTop = 1
        local stack = {self.Node}
        local stackTop = 1
        repeat
            local top = stack[listTop]
            local quad1 = top[1]
            if quad1 then
                local quad2, quad3, quad4 = top[2], top[3], top[4]
                list[listTop + 1] = quad1
                list[listTop + 2] = quad2
                list[listTop + 3] = quad3
                listTop = listTop + 4
                list[listTop] = quad4

                stack[stackTop] = quad1
                stack[stackTop + 1] = quad2
                stack[stackTop + 2] = quad3
                stackTop = stackTop + 3
                stack[stackTop] = quad4
                continue
            end
            stackTop = stackTop - 1
        until stackTop == 0
        return list
    end;

    Traverse = function(self, list)
        list = list or self:NodesBreadthFirst()
        local listPos = 1
        local bucket = list[1].Bucket
        local bucketSize = list[1].Size
        local bucketHead = 1
        local done = false
        return function()
            if done then return end
            if bucketHead >= bucketSize then
                local head = list[listPos]
                if not head then
                    done = true
                    return
                end
                listPos = listPos + 1
                bucket = head.Bucket
                bucketSize = head.Size
                bucketHead = 1
            end
            local el = bucket[bucketHead]
            bucketHead = bucketHead + 1
            return el
        end
    end;
}
