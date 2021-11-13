
-- TrashBag is a class to help manage objects that need destruction. You add objects to it with Add().
-- When TrashBag:Destroy() is called, it calls Destroy() in turn on all its contained objects.
--
-- If an object in a TrashBag is destroyed through other means, it automatically disappears from the TrashBag.
-- This doesn't necessarily happen instantly, so it's possible in this case that Destroy() will be called twice.
-- So Destroy() should always be idempotent.

-- The Trashbag is a global entity. You can use these upvalued versions to improve
-- the performance of functions using the trashbag. According to the function-scope
-- benchmark the performance is increased by about 10%.

-- START COPY HERE --

-- Upvalued for performance (function-scope benchmark)
-- local TrashBag = TrashBag
-- local TrashAdd = TrashBag.Add
-- local TrashDestroy = TrashBag.Destroy

-- END COPY HERE --

local ipairs = ipairs
local next = next

TrashBag = Class {

    -- Tell the garbage collector that we're a weak table for our values. If an element is ready to be collected
    -- then we're not a reason for it to remain alive. E.g., we don't care if it got cleaned up earlier.
    -- http://lua-users.org/wiki/GarbageCollectionTutorial
    -- http://lua-users.org/wiki/WeakTablesTutorial
    __mode = 'v',

    -- Keep track of the number of elements in the trash bag
    Next = 1,

    --- Add an entity to the trash bag.
    Add = function(self, entity)

        -- -- Uncomment for performance testing
        -- if entity == nil then 
        --     WARN("Attempted to add a nil to a TrashBag: " .. repr(debug.getinfo(2)))
        --     return 
        -- end

        -- -- Uncomment for performance testing
        -- if not entity.Destroy then 
        --     WARN("Attempted to add an entity with no Destroy() method to a TrashBag: "  .. repr(debug.getinfo(2)))
        --     return 
        -- end

        -- Keeping track of separate counter for performance (table-loops benchmark). The 
        -- counter is updated _after_ the table has been set, this is faster because the table
        -- operation depends on the counter value and doesn't have to wait for it in this case.

        self[self.Next] = entity
        self.Next = self.Next + 1
    end,

    --- Destroy all (remaining) entities in the trash bag.
    Destroy = function(self)

        -- -- Uncomment for performance testing
        -- if not self then 
        --     WARN("Attempted to trash non-existing trash bag: "  .. repr(debug.getinfo(2)))
        --     return 
        -- end

        -- Check if values are still relevant
        for k = 1, self.Next - 1 do 
            if self[k] then 
                self[k]:Destroy()
                self[k] = nil
            end
        end 

        -- allow us to be re-used, useful for effects
        self.Next = 1
    end
}
