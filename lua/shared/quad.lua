
-- A weak table on its values, e.g., if this is the last reference
-- to that value then the garbage collector can grab it.
local WeakTable = { __mode = 'v' }

-- Oh no, a random quad tree appeared!
local QuadTree = { }

local function CreateNode(root, x, z, width, height, depth)

    -- attempt to retrieve a node from the cache
    local node = root.NodeCache[root.NodeCacheHead]
    root.NodeCacheHead = root.NodeCacheHead + 1

    if not node then 
        node = { }
        root.NodeCache[root.NodeCacheHead - 1] = node 
    end 

    -- retrieve element table from cache
    local elements = root.ElementCache[root.ElementCacheHead]
    root.ElementCacheHead = root.ElementCacheHead + 1

    if not elements then 
        elements = { }
        setmetatable(elements, WeakTable)
        root.ElementCache[root.ElementCacheHead - 1] = elements
    end

    -- set properties of node 
    node.Children = false 
    node.Depth = depth 
    node.Rectangle = { x, z, width, height }

    -- give it to us
    return node 
end

--- Constructs a quad tree that spans the provided area.
-- @param x The x coordinate of the top left corner of the rectangle that spans the area of the quad tree.
-- @param y The z coordinate of the top left corner of the rectangle that spans the area of the quad tree.
-- @param width The width of the rectangle that spans the area of the quad tree.
-- @param height The height of the rectangle that spans the area of the quad tree.
-- @param depth The maximum depth of the quad tree.
function CreateQuadTree(x, z, width, height)

    -- set up the meta table
    local tree = { }
    setmetatable(tree, QuadTree)

    --- A cache filled with previous quad trees to prevent de-allocation
    tree.NodeCache = { }
    tree.NodeCacheHead = 1

    --- A cache filled with previous element tables to prevent de-allocation
    tree.ElementCache = { }
    tree.ElementCacheHead = 1

    tree.ContainerCache = { }
    tree.ContainerCacheHEad = 1
    
    -- start with four children
    local depth = 1
    local halfWidth = 0.5 * width 
    local halfHeight = 0.5 * height
    tree.Children = {
        CreateNode(tree, x,             z,              halfWidth, halfHeight, depth),
        CreateNode(tree, x + halfWidth, z,              halfWidth, halfHeight, depth),
        CreateNode(tree, x,             z + halfHeight, halfWidth, halfHeight, depth),
        CreateNode(tree, x + halfWidth, z + halfHeight, halfWidth, halfHeight, depth)
    }  

    -- rectangle of the area that spans this tree
    tree.Rectangle = { x, z, width, height }
end

local function AddElementNode(root, node, container, depth)
    return false
end

--- Adds an element to the quad tree.
-- @param element The element to add to the quad tree. Assumes the element is a table. Uses 'element.qx' and 'element.qz' to determine its position in the quad tree.
-- @param depth The maximum depth for this element - if surpassed the quad tree will no longer subdivide.
function QuadTree:AddElement(element, depth, qx, qz)

    -- attempt to retrieve a container from the cache
    local container = self.ContainerCache[self.ContainerCacheHead]
    self.ContainerCacheHead = self.ContainerCacheHead + 1

    if not container then 
        container = { }
        self.ContainerCache[self.ContainerCacheHead - 1] = container 
    end 

    -- populate the container
    container.qx = qx 
    container.qz = qz 
    container.element = element

    -- add it to the tree
    for k, node in self.children do 
        if AddElementNode(root, node, container, depth) then 
            break 
        end
    end
end

local function SubdivideNode(root, node)

end

--- Subdivides the quad tree and passes all its elements to its children.
function QuadTree:Subdivide()

end

local function ClearNode(root, node)

end

--- Clears the entire quad tree, releasing its assets.
function QuadTree:Clear()
    if self.Children then 

    end
end