
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
---@field Builder AIBuilder | nil
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
                self:ChangeState('Error')
                return
            end

            local unit = units[1]

            if not IsDestroyed(unit) then
                local builder = self.Base.StructureManager:GetHighestBuilder(self, unit)
                if builder then
                    self.Builder = builder
                    self:ChangeState('Upgrading')
                else
                    self:ChangeState('Waiting')
                end
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
        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)

            local builder = self.Builder
            if not builder then
                WARN(string.format("AI simple structure behavior error: no builder defined"))
                self:ChangeState('Waiting')
                return
            end

            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                WARN("AI simple structure behavior warning: multiple units in platoon is unsupported")
                self:ChangeState('Error')
                return
            end

            local builderData = builder.BuilderData
            if builderData.UseUpgradeToBlueprintField then
                local unit = units[1]
                local upgradeId = unit.Blueprint.General.UpgradesTo
                if not upgradeId then
                    WARN("AI simple structure behavior warning: unit has no upgrade to field")
                    self:ChangeState('Error')
                    return
                end

                IssueUpgrade(units, upgradeId)
            end
        end,
    },

    -----------------------------------------------------------------
    -- brain events

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToAttackSquad = function(self, units)
        WARN("AI simple structure behavior error: attack squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToScoutSquad = function(self, units)
        WARN("AI simple structure behavior error: scout squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToArtillerySquad = function(self, units)
        WARN("AI simple structure behavior error: artillery squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToSupportSquad = function(self, units)
        WARN("AI simple structure behavior error: support squad is unsupported")
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToGuardSquad = function(self, units)
        WARN("AI simple structure behavior error: guard squad is unsupported")
    end,
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        -- trigger the on stop being built event of the brain
        for k = 1, table.getn(units) do
            local unit = units[k]
            unit.Brain:OnUnitStopBeingBuilt(unit, nil, unit.Layer)
        end
    end
end



