local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

---@class AIPlatoonEngineer : AIPlatoon
---@field Base AIBase
---@field Brain AIBrain
AIPlatoonEngineer = Class(AIPlatoon) {

    AIBehaviorRaid = State {
        ---@param self AIPlatoonEngineer
        Main = function(self)
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
