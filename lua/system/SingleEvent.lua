--
-- Call SingleEvent:OnEvent(fun,arg) to set a trigger function which is called when the event is set.
-- Only one function can be set at a time, and it will only be called once.
--
-- You can clear the current trigger function by calling OnEvent(nil). If you want to change the trigger function
-- before it has been called, you must clear the old one before setting the new one.
---@class SingleEvent
---@field _EventSet boolean
---@field _EventFun? function
---@field _EventArg? any
SingleEvent = ClassSimple {
    ---@param self SingleEvent
    ---@param fun function
    ---@param arg any
    OnEvent = function(self, fun, arg)
        if fun and self._EventFun then
            error('SingleEvent: only one trigger can be set at a time')
        end
        self._EventFun = fun
        self._EventArg = arg
    end,

    ---@param self SingleEvent
    EventSet = function(self)
        if not self._EventSet then
            self._EventSet = true
            local fun = self._EventFun
            local arg = self._EventArg
            self._EventFun = nil
            self._EventArg = nil
            if fun then fun(arg) end
        end
        self._EventSet = true
    end,

    ---@param self SingleEvent
    EventReset = function(self)
        self._EventSet = false
    end,

    ---@param self SingleEvent
    WaitFor = function(self)
        if not self._EventSet then
            self:OnEvent(ResumeThread, CurrentThread())
            SuspendCurrentThread()
        end
    end,
}
