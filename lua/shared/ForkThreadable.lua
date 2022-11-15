local ForkThread = ForkThread
local unpack = unpack

---Class allowing creation of forked tasks of its instance.
---
---Unrecommended to use due to high performance impact.
---@class ForkThreadable
ForkThreadable = ClassSimple
{

    ---@param self ForkThreadable
    ---@param fn function
    ---@param ... any
    ---@return thread?
    ForkThread = function(self, fn, ...)
        if fn then
            return ForkThread(fn, self, unpack(arg))
        end
    end,
}


---Class allowing creation of forked tasks of its instance. Provided with Trash bag.
---
---Unrecommended to use due to high performance impact.
---@class TrashForkThreadable
---@field Trash TrashBag
TrashForkThreadable = ClassSimple
{

    ---Initializes trah bag for fork threads
    ---@param self TrashForkThreadable
    InitTrash = function(self)
        self.Trash = TrashBag()
    end,

    ---ForkThreads task for the instance.
    ---@param self TrashForkThreadable
    ---@param fn function
    ---@param ... any
    ---@return thread?
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        end
    end,

    ---Cleans trash bag
    ---@param self TrashForkThreadable
    CleanTrash = function(self)
        self.Trash:Destroy()
    end
}
