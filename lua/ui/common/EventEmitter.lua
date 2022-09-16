
-- inspired on: https://www.digitalocean.com/community/tutorials/using-event-emitters-in-node-js

---@class EventEmitter
---@field EventListeners table<string, table<Control, boolean>>
EventEmitter = ClassSimple {

    __init = function(self)
        self.EventListeners = { }
    end,

    --- Allows another control to listen to raised events that match the identifier
    ---@param self EventEmitter
    ---@param instance Control
    ---@param identifier string
    OnEvent = function(self, instance, identifier)

        -- sanity check
        if not instance[identifier] or not type(instance[identifier]) == 'function' then 
            WARN(string.format("Attempt to subscribe to an event (%s) with an instance (%s) that can not respond to it - skipping the subscribe", identifier, instance:GetName()))
            return
        end

        self.EventListeners[identifier] = self.EventListeners[identifier] or { }
        self.EventListeners[identifier][instance] = true
    end,

    --- Emits an event, passing a shallow copy of the data to all listeners
    ---@param self EventEmitter
    ---@param identifier string
    ---@param data any
    EmitEvent = function(self, identifier, data)
        if self.EventListeners[identifier] then
            for k, instance in self.EventListeners[identifier] do

                -- sanity check
                local ok, msg = pcall (instance[identifier], data)
                if not ok then
                    WARN(string.format("A subscriber (%s) crashed when processing an event (%s), removing the subscriber"))
                    WARN(msg)

                    self.EventListeners[identifier][instance] = nil
                end
            end
        end
    end,

}