
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

---@class AIPlatoonFactoryBehavior : AIPlatoon
---@field RetreatCount number 
---@field ThreatToEvade Vector | nil
---@field LocationToRaid Vector | nil
---@field OpportunityToRaid Vector | nil
AIPlatoonFactoryBehavior = Class(AIPlatoon) {

    Start = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonFactoryBehavior
        Main = function(self)


        end,
    },

    SearchingForTask = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonFactoryBehavior
        Main = function(self)

            

        end,
    },

    Constructing = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonFactoryBehavior
        Main = function(self)



        end,
    },

    Upgrading = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonFactoryBehavior
        Main = function(self)



        end,
    },

    -----------------------------------------------------------------
    -- unit events

    --- Called as a unit of this platoon gains or loses health, fixed at intervals of 25%
    ---@param self AIPlatoon
    ---@param unit Unit
    ---@param new number
    ---@param old number
    OnHealthChanged = function(self, unit, new, old)
        if new >= 1.0 then

        end

        if new <= 0.75 then

        end
    end,

}

---@param data { Behavior: 'AIBehaviorTacticalSimple' }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonFactoryBehavior]]
        setmetatable(platoon, AIPlatoonSimpleRaidBehavior)

        -- assign units to squads
        local factories = EntityCategoryFilterDown(categories.FACTORY, units)
        brain:AssignUnitsToPlatoon(platoon, factories, 'None', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end



