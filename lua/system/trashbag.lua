local assert = assert

--
-- TrashBag is a class to help manage objects that need destruction. You add objects to it with Add().
-- When TrashBag:Destroy() is called, it calls Destroy() in turn on all its contained objects.
--
-- If an object in a TrashBag is destroyed through other means, it automatically disappears from the TrashBag.
-- This doesn't necessarily happen instantly, so it's possible in this case that Destroy() will be called twice.
-- So Destroy() should always be idempotent.
--
TrashBag = Class {

    -- tell the garbage collector that we're a weak table. If an element is destroyed pre-maturely then
    -- we're not a reason for it to remain alive. E.g., we don't care if it got cleaned up before.
    -- http://lua-users.org/wiki/GarbageCollectionTutorial
    -- http://lua-users.org/wiki/WeakTablesTutorial
    __mode = 'v',

    -- keep track of the number of elements in the trash bag
    Count = 1,

    --- Add an entity to the trash bag.
    Add = function(self, entity)

        -- -- uncomment for performance testing
        -- if entity == nil then 
        --     WARN("Attempted to add a nil to a TrashBag: " .. repr(debug.getinfo(2)))
        --     return 
        -- end

        -- -- uncomment for performance testing
        -- if not entity.Destroy then 
        --     WARN("Attempted to add an entity with no Destroy() method to a TrashBag: "  .. repr(debug.getinfo(2)))
        --     return 
        -- end

        self[self.Count] = entity
        self.Count = self.Count + 1
    end,

    --- Destroy all (remaining) entities in the trash bag.
    Destroy = function(self)

        -- -- uncomment for performance testing
        -- if not self then 
        --     WARN("Attempted to trash non-existing trash bag: "  .. repr(debug.getinfo(2)))
        --     return 
        -- end

        -- check if values are still relevant
        for k = 1, self.Count - 1 do 
            if self[k] then 
                self[k]:Destroy()
                self[k] = nil
            end
        end 
    end
}
