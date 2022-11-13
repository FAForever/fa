

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


---@class TrashForkThreadable
---@field Trash TrashBag
TrashForkThreadable = ClassSimple
{

    ---@param self TrashForkThreadable
    InitTrash = function (self)
        self.Trash = TrashBag()
    end, 

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
}



