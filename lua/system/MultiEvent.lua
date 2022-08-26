--
-- Call MultiEvent:AddCallback(fun,arg) to set a trigger function which is called when the event is set.
-- You can add as many callbacks as you want.
--
-- You can't remove a callback once you've added it.
---@class MultiEvent
MultiEvent = ClassSimple {
    __init = function(self)
        self.EventCallbacks = {n=0}
        self.EventIsSet = false
    end,

    --
    -- Add a function to be called when this event is set. If the event is already set, the function is called
    -- immediately.
    --
    AddCallback = function(self, fn, arg)
        if not fn then
            return
        end
        if self.EventIsSet then
            fn(arg)
            return
        end
        local n = self.EventCallbacks.n
        self.EventCallbacks[n+1] = fn
        self.EventCallbacks[n+2] = arg
        self.EventCallbacks.n = n+2
    end,

    --
    -- Set the event, calling all triggers waiting on it
    --
    EventSet = function(self)
        --LOG('*DEBUG: *** EVENT SET ***')
        self.EventIsSet = true

        local cb = self.EventCallbacks
        for i = 1,cb.n,2 do
            local fn = cb[i]
            local arg = cb[i+1]
            if fn then
                fn(arg)
            end
            cb[i] = nil
            cb[i+1] = nil
        end
        cb.n = 0
    end,

    --
    -- Reset the event
    --
    EventReset = function(self)
        --LOG('*DEBUG: ..EventReset..')
        self.EventIsSet = false
    end,

    --
    -- Destroy the event. Any triggers waiting for it are abandoned.
    --
    Destroy = function(self)
        local cb = self.EventCallbacks
        for i = 1,cb.n do
            cb[i] = nil
        end
        cb.n = 0
    end,

    WaitFor = function(self)
        if not self.EventIsSet then
            --LOG('*DEBUG: me AddCallback ',ResumeThread,CurrentThread())
            self:AddCallback(ResumeThread, CurrentThread())
            SuspendCurrentThread()
--        else
--            LOG('*DEBUG: No WaitFor For You')
        end
    end,
}
