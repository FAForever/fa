local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

---@class AIPlatoonEngineer : AIPlatoon
AIPlatoonEngineer = Class(AIPlatoon) {

    AIBehaviorBuild = State {
        ---@param self AIPlatoonEngineer
        Main = function(self)

            -- local scope for performance
            local IsDestroyed = IsDestroyed

            -- ease of access
            local engineers = self:GetPlatoonUnits()
            local engineer = engineers[1]
            local engineerManager = self.Base.EngineerManager

            -- main loop
            while not IsDestroyed(engineer) do



            end
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
