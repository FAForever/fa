local getn = table.getn

#
# TrashBag is a class to help manage objects that need destruction. You add objects to it with Add().
# When TrashBag:Destroy() is called, it calls Destroy() in turn on all its contained objects.
#
# If an object in a TrashBag is destroyed through other means, it automatically disappears from the TrashBag.
# This doesn't necessarily happen instantly, so it's possible in this case that Destroy() will be called twice.
# So Destroy() should always be idempotent.
#
TrashBag = Class {

    __mode = 'v',

    #
    # Add an object to the TrashBag.
    #
    Add = function(self, obj)
        if obj == nil then return end

        assert(obj.Destroy, 'Attempted to add an object with no Destroy() method to a TrashBag')

        local i = getn(self)+1
        self[i] = obj
    end,

    #
    # Call Destroy() for all objects in this bag.
    #
    Destroy = function(self)
        # loop over all values in self. ipairs() won't work correctly because we may have holes in our ordering.
        for i,v in self do
            if type(i)=='number' then
                self[i]:Destroy()
                self[i] = nil
            end
        end
    end
}
