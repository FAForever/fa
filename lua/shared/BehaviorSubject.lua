
-- inspired by:
--  - https://rxjs.dev/api/index/class/BehaviorSubject

---@class BehaviorSubject
---@field Value any
---@field Subscribers table<string, func>
BehaviorSubject = ClassSimple {

    __init = function(self, value)
        self.Value = value
        self.Subscribers = { }
    end,

    Next = function(self, value)
        self.Value = value

        for _, subscriber in self.Subscribers do
            subscriber(value)
        end
    end,

    Subscribe = function(self, id)

    end,

}