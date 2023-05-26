
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

---@class AIPlatoonSimpleStructure : AIPlatoon
---@field Base AIBase
---@field Brain EasyAIBrain
AIPlatoonSimpleStructure = Class(AIPlatoon) {

    Start = State {
        --- Initial state of any state machine
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            LOG("AIPlatoonSimpleStructure - Start")
            if not self.Base then
                error("AI simple structure behavior requires an AI base reference")
            end

            if not self.Brain then
                error("AI simple structure behavior requires an AI brain reference")
            end

            if not self.Base.StructureManager then
                error("AI simple structure behavior requires an engineer manager reference")
            end

            self:ChangeState('SearchingForTask')
            return
        end,
    },

    SearchingForTask = State {
        --- The platoon searches for a target
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                WARN("AI simple structure behavior warning: multiple units in platoon is unsupported")
            end

            local unit = units[1]

            if not IsDestroyed(unit) then
                local type = unit.Blueprint.TechCategory
                local task = self.Base.StructureManager:GetHighestBuilder(type, self, unit)
                if task then
                    reprsl(task)
                    self:ChangeState('Waiting')
                else
                    self:ChangeState('Waiting')
                end
            else
                WARN("Unit is destroyed?")
            end
        end,
    },

    Waiting = State {
        --- 
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            WaitTicks(10)
            self:ChangeState('SearchingForTask')
        end,
    },

    Upgrading = State {
        --- The platoon raids the target
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
        end,
    },

    -----------------------------------------------------------------
    -- brain events

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToAttackSquad = function(self, units)
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToScoutSquad = function(self, units)
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToArtillerySquad = function(self, units)
        WARN("AI simple raid behavior error: artillery squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToSupportSquad = function(self, units)
        WARN("AI simple raid behavior error: support squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToGuardSquad = function(self, units)
        WARN("AI simple raid behavior error: guard squad is unsupported")
    end,
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        -- trigger the on stop being built event of the brain
        for k = 1, table.getn(units) do
            local unit = units[k]
            LOG(unit.Blueprint.BlueprintId)
            LOG(unit.Brain)
            LOG(unit.Brain:GetArmyIndex())
            LOG(unit.Brain.Nickname)
            unit.Brain:OnUnitStopBeingBuilt(unit, nil, unit.Layer)
        end
    end
end



