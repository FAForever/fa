local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

---@class AIPlatoonEngineer : AIPlatoon
---@field Base AIBase
---@field Brain AIBrain
AIPlatoonEngineer = Class(AIPlatoon) {

    AIBehaviorBuild = State {
        ---@param self AIPlatoonEngineer
        Main = function(self)
            if not self.Base then
                error("AI Build behavior requires an AI base reference")
            end

            if not self.Brain then
                error("AI Build behavior requires an AI brain reference")
            end

            if not self.Base.EngineerManager then
                error("AI Build behavior requires an engineer manager reference")
            end
        end,

        --- Called as a unit of this platoon starts building
        ---@param self AIPlatoon
        ---@param unit Unit
        ---@param target Unit
        ---@param order string
        OnStartBuild = function(self, unit, target, order)

        end,

        --- Called as a unit of this platoon stops building
        ---@param self AIPlatoon
        ---@param unit Unit
        ---@param target Unit
        OnStopBuild = function(self, unit, target)
            
        end,
    },


    ---@param self AIPlatoonEngineer
    AIBehaviorAssist = function(self)

    end,

    ---@param self AIPlatoonEngineer
    AIBehaviorRepair = function(self)

    end,

    ---@param self AIPlatoonEngineer
    AIBehaviorReclaim = function(self)

    end,
}
