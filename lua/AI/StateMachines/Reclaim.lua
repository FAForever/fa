
---@class AIReclaimStateMachine : AIStateMachine
---@field Rectangle Rectangle
ReclaimStateMachine = Class(import("/lua/ai/statemachine.lua").StateMachine) {

    ---@param self AIReclaimStateMachine
    ---@param cx number
    ---@param cz number
    ---@param radius number
    Create = function(self, cx, cz, radius)
        self.Rectangle = {
            x0 = cx - radius, y0 = cz - radius, x1 = cx + radius,  y1 = cz + radius
        }

        self:ToState('Scan')
    end,

    Scan = State {
        ---@param self AIReclaimStateMachine
        Main = function(self)

            local rectangle = self.Rectangle

            -- if there are no reclaimables at all, then we're done and enter the blank state
            local reclaimables = GetReclaimablesInRect(rectangle)
            if not reclaimables or table.empty(reclaimables) then
                self:ToState('Blank')
            end

            -- there are some reclaimables, so let's find them!
            self:ToState('ReclaimArea')
        end,
    },

    ReclaimArea = State {
        ---@param self AIReclaimStateMachine
        Main = function(self)
            -- if there are no reclaimables at all, then we're done and enter the blank state
            local rectangle = self.Rectangle
            local reclaimables = GetReclaimablesInRect(rectangle)
            if not reclaimables or table.empty(reclaimables) then
                self:ToState('Blank')
            end

            for k, reclaimable in reclaimables do
                IssueReclaim(self.Units, reclaimable)
            end
        end,
    }
}