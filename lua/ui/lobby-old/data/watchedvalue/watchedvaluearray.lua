local WatchedValueTable = import("/lua/ui/lobby/data/watchedvalue/watchedvaluetable.lua").WatchedValueTable

--- A WatchedValueTable with integral keys. Note that `false` is indistinguishable from `nil` in this
-- structure, because Lua.
---@class WatchedValueArray : WatchedValueTable
WatchedValueArray = Class(WatchedValueTable) {
    __init = function(self, size)
        local initialMapping = {}
        for i = 1, size do
            initialMapping[i] = false
        end

        WatchedValueTable.__init(self, initialMapping)

        -- Set all the keys to nil. This secretly calls the magic underlying WatchedValue metatable
        -- function and sets the isNull flags, so we can all go home and stop thinking about these
        -- retarded null semantics now.
        for i = 1, size do
            self[i] = nil
        end
    end
}
